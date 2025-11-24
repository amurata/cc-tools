# モック化されたアクティビティを使用した統合テスト

モック化された外部依存関係、エラー注入、および複雑なシナリオを使用してワークフローをテストするための包括的なパターン。

## アクティビティモック戦略

**目的**: 実際の外部サービスを呼び出すことなく、ワークフローオーケストレーションロジックをテストする

### 基本的なモックパターン

```python
import pytest
from temporalio.testing import WorkflowEnvironment
from temporalio.worker import Worker
from unittest.mock import Mock

@pytest.mark.asyncio
async def test_workflow_with_mocked_activity(workflow_env):
    """ワークフローロジックをテストするためにアクティビティをモックする"""

    # モックアクティビティを作成
    mock_activity = Mock(return_value="mocked-result")

    @workflow.defn
    class WorkflowWithActivity:
        @workflow.run
        async def run(self, input: str) -> str:
            result = await workflow.execute_activity(
                process_external_data,
                input,
                start_to_close_timeout=timedelta(seconds=10),
            )
            return f"processed: {result}"

    async with Worker(
        workflow_env.client,
        task_queue="test",
        workflows=[WorkflowWithActivity],
        activities=[mock_activity],  # 実際のアクティビティの代わりにモックを使用
    ):
        result = await workflow_env.client.execute_workflow(
            WorkflowWithActivity.run,
            "test-input",
            id="wf-mock",
            task_queue="test",
        )
        assert result == "processed: mocked-result"
        mock_activity.assert_called_once()
```

### 動的モックレスポンス

**シナリオベースのモック**:
```python
@pytest.mark.asyncio
async def test_workflow_multiple_mock_scenarios(workflow_env):
    """動的モックを使用して異なるワークフローパスをテストする"""

    # モックは入力に基づいて異なる値を返す
    def dynamic_activity(input: str) -> str:
        if input == "error-case":
            raise ApplicationError("Validation failed", non_retryable=True)
        return f"processed-{input}"

    @workflow.defn
    class DynamicWorkflow:
        @workflow.run
        async def run(self, input: str) -> str:
            try:
                result = await workflow.execute_activity(
                    dynamic_activity,
                    input,
                    start_to_close_timeout=timedelta(seconds=10),
                )
                return f"success: {result}"
            except ApplicationError as e:
                return f"error: {e.message}"

    async with Worker(
        workflow_env.client,
        task_queue="test",
        workflows=[DynamicWorkflow],
        activities=[dynamic_activity],
    ):
        # 成功パスをテスト
        result_success = await workflow_env.client.execute_workflow(
            DynamicWorkflow.run,
            "valid-input",
            id="wf-success",
            task_queue="test",
        )
        assert result_success == "success: processed-valid-input"

        # エラーパスをテスト
        result_error = await workflow_env.client.execute_workflow(
            DynamicWorkflow.run,
            "error-case",
            id="wf-error",
            task_queue="test",
        )
        assert "Validation failed" in result_error
```

## エラー注入パターン

### 一時的な障害のテスト

**リトライ動作**:
```python
@pytest.mark.asyncio
async def test_workflow_transient_errors(workflow_env):
    """制御された障害でリトライロジックをテストする"""

    attempt_count = 0

    @activity.defn
    async def transient_activity() -> str:
        nonlocal attempt_count
        attempt_count += 1

        if attempt_count < 3:
            raise Exception(f"Transient error {attempt_count}")
        return "success-after-retries"

    @workflow.defn
    class RetryWorkflow:
        @workflow.run
        async def run(self) -> str:
            return await workflow.execute_activity(
                transient_activity,
                start_to_close_timeout=timedelta(seconds=10),
                retry_policy=RetryPolicy(
                    initial_interval=timedelta(milliseconds=10),
                    maximum_attempts=5,
                    backoff_coefficient=1.0,
                ),
            )

    async with Worker(
        workflow_env.client,
        task_queue="test",
        workflows=[RetryWorkflow],
        activities=[transient_activity],
    ):
        result = await workflow_env.client.execute_workflow(
            RetryWorkflow.run,
            id="retry-wf",
            task_queue="test",
        )
        assert result == "success-after-retries"
        assert attempt_count == 3
```

### 再試行不可能なエラーのテスト

**ビジネス検証の失敗**:
```python
@pytest.mark.asyncio
async def test_workflow_non_retryable_error(workflow_env):
    """永続的な障害の処理をテストする"""

    @activity.defn
    async def validation_activity(input: dict) -> str:
        if not input.get("valid"):
            raise ApplicationError(
                "Invalid input",
                non_retryable=True,  # 検証エラーはリトライしない
            )
        return "validated"

    @workflow.defn
    class ValidationWorkflow:
        @workflow.run
        async def run(self, input: dict) -> str:
            try:
                return await workflow.execute_activity(
                    validation_activity,
                    input,
                    start_to_close_timeout=timedelta(seconds=10),
                )
            except ApplicationError as e:
                return f"validation-failed: {e.message}"

    async with Worker(
        workflow_env.client,
        task_queue="test",
        workflows=[ValidationWorkflow],
        activities=[validation_activity],
    ):
        result = await workflow_env.client.execute_workflow(
            ValidationWorkflow.run,
            {"valid": False},
            id="validation-wf",
            task_queue="test",
        )
        assert "validation-failed" in result
```

## マルチアクティビティワークフローテスト

### シーケンシャルアクティビティパターン

```python
@pytest.mark.asyncio
async def test_workflow_sequential_activities(workflow_env):
    """複数のアクティビティを調整するワークフローをテストする"""

    activity_calls = []

    @activity.defn
    async def step_1(input: str) -> str:
        activity_calls.append("step_1")
        return f"{input}-step1"

    @activity.defn
    async def step_2(input: str) -> str:
        activity_calls.append("step_2")
        return f"{input}-step2"

    @activity.defn
    async def step_3(input: str) -> str:
        activity_calls.append("step_3")
        return f"{input}-step3"

    @workflow.defn
    class SequentialWorkflow:
        @workflow.run
        async def run(self, input: str) -> str:
            result_1 = await workflow.execute_activity(
                step_1,
                input,
                start_to_close_timeout=timedelta(seconds=10),
            )
            result_2 = await workflow.execute_activity(
                step_2,
                result_1,
                start_to_close_timeout=timedelta(seconds=10),
            )
            result_3 = await workflow.execute_activity(
                step_3,
                result_2,
                start_to_close_timeout=timedelta(seconds=10),
            )
            return result_3

    async with Worker(
        workflow_env.client,
        task_queue="test",
        workflows=[SequentialWorkflow],
        activities=[step_1, step_2, step_3],
    ):
        result = await workflow_env.client.execute_workflow(
            SequentialWorkflow.run,
            "start",
            id="seq-wf",
            task_queue="test",
        )
        assert result == "start-step1-step2-step3"
        assert activity_calls == ["step_1", "step_2", "step_3"]
```

### パラレルアクティビティパターン

```python
@pytest.mark.asyncio
async def test_workflow_parallel_activities(workflow_env):
    """同時アクティビティ実行をテストする"""

    @activity.defn
    async def parallel_task(task_id: int) -> str:
        return f"task-{task_id}"

    @workflow.defn
    class ParallelWorkflow:
        @workflow.run
        async def run(self, task_count: int) -> list[str]:
            # アクティビティを並列に実行
            tasks = [
                workflow.execute_activity(
                    parallel_task,
                    i,
                    start_to_close_timeout=timedelta(seconds=10),
                )
                for i in range(task_count)
            ]
            return await asyncio.gather(*tasks)

    async with Worker(
        workflow_env.client,
        task_queue="test",
        workflows=[ParallelWorkflow],
        activities=[parallel_task],
    ):
        result = await workflow_env.client.execute_workflow(
            ParallelWorkflow.run,
            3,
            id="parallel-wf",
            task_queue="test",
        )
        assert result == ["task-0", "task-1", "task-2"]
```

## シグナルとクエリのテスト

### シグナルハンドラ

```python
@pytest.mark.asyncio
async def test_workflow_signals(workflow_env):
    """ワークフローシグナル処理をテストする"""

    @workflow.defn
    class SignalWorkflow:
        def __init__(self) -> None:
            self._status = "initialized"

        @workflow.run
        async def run(self) -> str:
            # 完了シグナルを待つ
            await workflow.wait_condition(lambda: self._status == "completed")
            return self._status

        @workflow.signal
        async def update_status(self, new_status: str) -> None:
            self._status = new_status

        @workflow.query
        def get_status(self) -> str:
            return self._status

    async with Worker(
        workflow_env.client,
        task_queue="test",
        workflows=[SignalWorkflow],
    ):
        # ワークフローを開始
        handle = await workflow_env.client.start_workflow(
            SignalWorkflow.run,
            id="signal-wf",
            task_queue="test",
        )

        # クエリで初期状態を検証
        initial_status = await handle.query(SignalWorkflow.get_status)
        assert initial_status == "initialized"

        # シグナルを送信
        await handle.signal(SignalWorkflow.update_status, "processing")

        # 更新された状態を検証
        updated_status = await handle.query(SignalWorkflow.get_status)
        assert updated_status == "processing"

        # ワークフローを完了
        await handle.signal(SignalWorkflow.update_status, "completed")
        result = await handle.result()
        assert result == "completed"
```

## カバレッジ戦略

### ワークフローロジックカバレッジ

**目標**: ワークフロー決定ロジックのカバレッジ 80%以上

```python
# すべての分岐をテスト
@pytest.mark.parametrize("condition,expected", [
    (True, "branch-a"),
    (False, "branch-b"),
])
async def test_workflow_branches(workflow_env, condition, expected):
    """すべてのコードパスがテストされることを確認する"""
    # テスト実装
    pass
```

### アクティビティカバレッジ

**目標**: アクティビティロジックのカバレッジ 80%以上

```python
# アクティビティのエッジケースをテスト
@pytest.mark.parametrize("input,expected", [
    ("valid", "success"),
    ("", "empty-input-error"),
    (None, "null-input-error"),
])
async def test_activity_edge_cases(activity_env, input, expected):
    """アクティビティのエラー処理をテストする"""
    # テスト実装
    pass
```

## 統合テストの構成

### テスト構造

```
tests/
├── integration/
│   ├── conftest.py              # 共有フィクスチャ
│   ├── test_order_workflow.py   # 注文処理テスト
│   ├── test_payment_workflow.py # 支払いテスト
│   └── test_fulfillment_workflow.py
├── unit/
│   ├── test_order_activities.py
│   └── test_payment_activities.py
└── fixtures/
    └── test_data.py             # テストデータビルダー
```

### 共有フィクスチャ

```python
# conftest.py
import pytest
from temporalio.testing import WorkflowEnvironment

@pytest.fixture(scope="session")
async def workflow_env():
    """統合テスト用のセッションスコープ環境"""
    env = await WorkflowEnvironment.start_time_skipping()
    yield env
    await env.shutdown()

@pytest.fixture
def mock_payment_service():
    """外部支払いサービスのモック"""
    return Mock()

@pytest.fixture
def mock_inventory_service():
    """外部在庫サービスのモック"""
    return Mock()
```

## ベストプラクティス

1. **外部依存関係をモックする**: テストで実際のAPIを決して呼び出さない
2. **エラーシナリオをテストする**: 補償とリトライロジックを検証する
3. **並列テスト**: 高速なテスト実行のために pytest-xdist を使用する
4. **分離されたテスト**: 各テストは独立している必要がある
5. **明確なアサーション**: 結果と副作用の両方を検証する
6. **カバレッジ目標**: 重要なワークフローに対して80%以上
7. **高速な実行**: タイムスキップを使用し、実際の遅延を避ける

## 追加リソース

- モック戦略: docs.temporal.io/develop/python/testing-suite
- pytest ベストプラクティス: docs.pytest.org/en/stable/goodpractices.html
- Python SDK サンプル: github.com/temporalio/samples-python
