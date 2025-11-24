# Temporal ワークフローとアクティビティのユニットテスト

WorkflowEnvironment と ActivityEnvironment を使用して、個々のワークフローとアクティビティを分離してテストするための集中ガイド。

## タイムスキップ機能付き WorkflowEnvironment

**目的**: 時間を即座に進めてワークフローを分離してテストする（1か月のワークフロー → 数秒）

### 基本的なセットアップパターン

```python
import pytest
from temporalio.testing import WorkflowEnvironment
from temporalio.worker import Worker

@pytest.fixture
async def workflow_env():
    """再利用可能なタイムスキップテスト環境"""
    env = await WorkflowEnvironment.start_time_skipping()
    yield env
    await env.shutdown()

@pytest.mark.asyncio
async def test_workflow_execution(workflow_env):
    """タイムスキップを使用したワークフローのテスト"""
    async with Worker(
        workflow_env.client,
        task_queue="test-queue",
        workflows=[YourWorkflow],
        activities=[your_activity],
    ):
        result = await workflow_env.client.execute_workflow(
            YourWorkflow.run,
            "test-input",
            id="test-wf-id",
            task_queue="test-queue",
        )
        assert result == "expected-output"
```

**主な利点**:
- `workflow.sleep(timedelta(days=30))` が即座に完了する
- 高速なフィードバックループ（数時間 vs 数ミリ秒）
- 決定論的なテスト実行

### タイムスキップの例

**スリープの進行**:
```python
@pytest.mark.asyncio
async def test_workflow_with_delays(workflow_env):
    """タイムスキップモードではワークフローのスリープは即時"""

    @workflow.defn
    class DelayedWorkflow:
        @workflow.run
        async def run(self) -> str:
            await workflow.sleep(timedelta(hours=24))  # テストでは即時
            return "completed"

    async with Worker(
        workflow_env.client,
        task_queue="test",
        workflows=[DelayedWorkflow],
    ):
        result = await workflow_env.client.execute_workflow(
            DelayedWorkflow.run,
            id="delayed-wf",
            task_queue="test",
        )
        assert result == "completed"
```

**手動の時間制御**:
```python
@pytest.mark.asyncio
async def test_workflow_manual_time(workflow_env):
    """正確な制御のために手動で時間を進める"""

    handle = await workflow_env.client.start_workflow(
        TimeBasedWorkflow.run,
        id="time-wf",
        task_queue="test",
    )

    # 特定の量だけ時間を進める
    await workflow_env.sleep(timedelta(hours=1))

    # クエリで中間状態を検証
    state = await handle.query(TimeBasedWorkflow.get_state)
    assert state == "processing"

    # 完了まで進める
    await workflow_env.sleep(timedelta(hours=23))
    result = await handle.result()
    assert result == "completed"
```

### ワークフローロジックのテスト

**分岐テスト**:
```python
@pytest.mark.asyncio
async def test_workflow_branching(workflow_env):
    """異なる実行パスをテストする"""

    @workflow.defn
    class ConditionalWorkflow:
        @workflow.run
        async def run(self, condition: bool) -> str:
            if condition:
                return "path-a"
            return "path-b"

    async with Worker(
        workflow_env.client,
        task_queue="test",
        workflows=[ConditionalWorkflow],
    ):
        # true パスをテスト
        result_a = await workflow_env.client.execute_workflow(
            ConditionalWorkflow.run,
            True,
            id="cond-wf-true",
            task_queue="test",
        )
        assert result_a == "path-a"

        # false パスをテスト
        result_b = await workflow_env.client.execute_workflow(
            ConditionalWorkflow.run,
            False,
            id="cond-wf-false",
            task_queue="test",
        )
        assert result_b == "path-b"
```

## ActivityEnvironment テスト

**目的**: ワークフローや Temporal サーバーなしでアクティビティを分離してテストする

### 基本的なアクティビティテスト

```python
from temporalio.testing import ActivityEnvironment

async def test_activity_basic():
    """ワークフローコンテキストなしでアクティビティをテストする"""

    @activity.defn
    async def process_data(input: str) -> str:
        return input.upper()

    env = ActivityEnvironment()
    result = await env.run(process_data, "test")
    assert result == "TEST"
```

### アクティビティコンテキストのテスト

**ハートビートテスト**:
```python
async def test_activity_heartbeat():
    """ハートビート呼び出しを検証する"""

    @activity.defn
    async def long_running_activity(total_items: int) -> int:
        for i in range(total_items):
            activity.heartbeat(i)  # 進捗を報告
            await asyncio.sleep(0.1)
        return total_items

    env = ActivityEnvironment()
    result = await env.run(long_running_activity, 10)
    assert result == 10
```

**キャンセルテスト**:
```python
async def test_activity_cancellation():
    """アクティビティのキャンセル処理をテストする"""

    @activity.defn
    async def cancellable_activity() -> str:
        try:
            while True:
                if activity.is_cancelled():
                    return "cancelled"
                await asyncio.sleep(0.1)
        except asyncio.CancelledError:
            return "cancelled"

    env = ActivityEnvironment(cancellation_reason="test-cancel")
    result = await env.run(cancellable_activity)
    assert result == "cancelled"
```

### エラー処理のテスト

**例外の伝播**:
```python
async def test_activity_error():
    """アクティビティのエラー処理をテストする"""

    @activity.defn
    async def failing_activity(should_fail: bool) -> str:
        if should_fail:
            raise ApplicationError("Validation failed", non_retryable=True)
        return "success"

    env = ActivityEnvironment()

    # 成功パスをテスト
    result = await env.run(failing_activity, False)
    assert result == "success"

    # エラーパスをテスト
    with pytest.raises(ApplicationError) as exc_info:
        await env.run(failing_activity, True)
    assert "Validation failed" in str(exc_info.value)
```

## Pytest 統合パターン

### 共有フィクスチャ

```python
# conftest.py
import pytest
from temporalio.testing import WorkflowEnvironment

@pytest.fixture(scope="module")
async def workflow_env():
    """モジュールスコープの環境（テスト間で再利用）"""
    env = await WorkflowEnvironment.start_time_skipping()
    yield env
    await env.shutdown()

@pytest.fixture
def activity_env():
    """関数スコープの環境（テストごとに新規作成）"""
    return ActivityEnvironment()
```

### パラメータ化テスト

```python
@pytest.mark.parametrize("input,expected", [
    ("test", "TEST"),
    ("hello", "HELLO"),
    ("123", "123"),
])
async def test_activity_parameterized(activity_env, input, expected):
    """複数の入力シナリオをテストする"""
    result = await activity_env.run(process_data, input)
    assert result == expected
```

## ベストプラクティス

1. **高速な実行**: すべてのワークフローテストにタイムスキップを使用する
2. **分離**: ワークフローとアクティビティを別々にテストする
3. **共有フィクスチャ**: 関連するテスト間で WorkflowEnvironment を再利用する
4. **カバレッジ目標**: ワークフローロジックに対して80%以上
5. **モックアクティビティ**: アクティビティ固有のロジックには ActivityEnvironment を使用する
6. **決定論**: テスト結果が実行間で一貫していることを確認する
7. **エラーケース**: 成功と失敗の両方のシナリオをテストする

## 一般的なパターン

**リトライロジックのテスト**:
```python
@pytest.mark.asyncio
async def test_workflow_with_retries(workflow_env):
    """アクティビティのリトライ動作をテストする"""

    call_count = 0

    @activity.defn
    async def flaky_activity() -> str:
        nonlocal call_count
        call_count += 1
        if call_count < 3:
            raise Exception("Transient error")
        return "success"

    @workflow.defn
    class RetryWorkflow:
        @workflow.run
        async def run(self) -> str:
            return await workflow.execute_activity(
                flaky_activity,
                start_to_close_timeout=timedelta(seconds=10),
                retry_policy=RetryPolicy(
                    initial_interval=timedelta(milliseconds=1),
                    maximum_attempts=5,
                ),
            )

    async with Worker(
        workflow_env.client,
        task_queue="test",
        workflows=[RetryWorkflow],
        activities=[flaky_activity],
    ):
        result = await workflow_env.client.execute_workflow(
            RetryWorkflow.run,
            id="retry-wf",
            task_queue="test",
        )
        assert result == "success"
        assert call_count == 3  # リトライ試行回数を検証
```

## 追加リソース

- Python SDK テスト: docs.temporal.io/develop/python/testing-suite
- pytest ドキュメント: docs.pytest.org
- Temporal サンプル: github.com/temporalio/samples-python
