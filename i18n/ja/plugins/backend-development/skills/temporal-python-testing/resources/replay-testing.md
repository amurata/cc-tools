# 決定論と互換性のためのリプレイテスト

リプレイテストを使用してワークフローの決定論を検証し、安全なコード変更を保証するための包括的なガイド。

## リプレイテストとは？

**目的**: ワークフローコードの変更が既存のワークフロー実行と後方互換性があることを検証する

**仕組み**:
1. Temporalはすべてのワークフロー決定をイベント履歴として記録する
2. リプレイテストは、記録された履歴に対してワークフローコードを再実行する
3. 新しいコードが同じ決定を下す場合 → 決定論的（デプロイしても安全）
4. 決定が異なる場合 → 非決定論的（破壊的変更）

**重要なユースケース**:
- ワークフローコード変更の本番環境へのデプロイ
- リファクタリングが実行中のワークフローを壊さないことの検証
- CI/CDによる自動互換性チェック
- バージョン移行の検証

## 基本的なリプレイテスト

### Replayer のセットアップ

```python
from temporalio.worker import Replayer
from temporalio.client import Client

async def test_workflow_replay():
    """本番履歴に対してワークフローをテストする"""

    # Temporalサーバーに接続
    client = await Client.connect("localhost:7233")

    # 現在のワークフローコードでReplayerを作成
    replayer = Replayer(
        workflows=[OrderWorkflow, PaymentWorkflow]
    )

    # 本番環境からワークフロー履歴を取得
    handle = client.get_workflow_handle("order-123")
    history = await handle.fetch_history()

    # 現在のコードで履歴をリプレイ
    await replayer.replay_workflow(history)
    # 成功 = 決定論的、例外 = 破壊的変更
```

### 複数の履歴に対するテスト

```python
import pytest
from temporalio.worker import Replayer

@pytest.mark.asyncio
async def test_replay_multiple_workflows():
    """複数の本番履歴に対してリプレイする"""

    replayer = Replayer(workflows=[OrderWorkflow])

    # 異なるワークフロー実行に対してテスト
    workflow_ids = [
        "order-success-123",
        "order-cancelled-456",
        "order-retry-789",
    ]

    for workflow_id in workflow_ids:
        handle = client.get_workflow_handle(workflow_id)
        history = await handle.fetch_history()

        # すべてのバリエーションでリプレイが成功するはず
        await replayer.replay_workflow(history)
```

## 決定論の検証

### 一般的な非決定論的パターン

**問題: 乱数生成**
```python
# ❌ 非決定論的（リプレイを壊す）
@workflow.defn
class BadWorkflow:
    @workflow.run
    async def run(self) -> int:
        return random.randint(1, 100)  # リプレイ時に異なる！

# ✅ 決定論的（リプレイに安全）
@workflow.defn
class GoodWorkflow:
    @workflow.run
    async def run(self) -> int:
        return workflow.random().randint(1, 100)  # 決定論的ランダム
```

**問題: 現在時刻**
```python
# ❌ 非決定論的
@workflow.defn
class BadWorkflow:
    @workflow.run
    async def run(self) -> str:
        now = datetime.now()  # リプレイ時に異なる！
        return now.isoformat()

# ✅ 決定論的
@workflow.defn
class GoodWorkflow:
    @workflow.run
    async def run(self) -> str:
        now = workflow.now()  # 決定論的時間
        return now.isoformat()
```

**問題: 直接的な外部呼び出し**
```python
# ❌ 非決定論的
@workflow.defn
class BadWorkflow:
    @workflow.run
    async def run(self) -> dict:
        response = requests.get("https://api.example.com/data")  # 外部呼び出し！
        return response.json()

# ✅ 決定論的
@workflow.defn
class GoodWorkflow:
    @workflow.run
    async def run(self) -> dict:
        # 外部呼び出しにはアクティビティを使用する
        return await workflow.execute_activity(
            fetch_external_data,
            start_to_close_timeout=timedelta(seconds=30),
        )
```

### 決定論のテスト

```python
@pytest.mark.asyncio
async def test_workflow_determinism():
    """ワークフローが複数回の実行で同じ出力を生成することを検証する"""

    @workflow.defn
    class DeterministicWorkflow:
        @workflow.run
        async def run(self, seed: int) -> list[int]:
            # 決定論のために workflow.random() を使用する
            rng = workflow.random()
            rng.seed(seed)
            return [rng.randint(1, 100) for _ in range(10)]

    env = await WorkflowEnvironment.start_time_skipping()

    # 同じ入力でワークフローを2回実行する
    results = []
    for i in range(2):
        async with Worker(
            env.client,
            task_queue="test",
            workflows=[DeterministicWorkflow],
        ):
            result = await env.client.execute_workflow(
                DeterministicWorkflow.run,
                42,  # 同じシード
                id=f"determinism-test-{i}",
                task_queue="test",
            )
            results.append(result)

    await env.shutdown()

    # 同一の出力を検証する
    assert results[0] == results[1]
```

## 本番履歴リプレイ

### ワークフロー履歴のエクスポート

```python
from temporalio.client import Client

async def export_workflow_history(workflow_id: str, output_file: str):
    """リプレイテスト用にワークフロー履歴をエクスポートする"""

    client = await Client.connect("production.temporal.io:7233")

    # ワークフロー履歴を取得
    handle = client.get_workflow_handle(workflow_id)
    history = await handle.fetch_history()

    # リプレイテスト用にファイルに保存
    with open(output_file, "wb") as f:
        f.write(history.SerializeToString())

    print(f"Exported history to {output_file}")
```

### ファイルからのリプレイ

```python
from temporalio.worker import Replayer
from temporalio.api.history.v1 import History

async def test_replay_from_file():
    """エクスポートされた履歴ファイルからワークフローをリプレイする"""

    # ファイルから履歴を読み込む
    with open("workflow_histories/order-123.pb", "rb") as f:
        history = History.FromString(f.read())

    # 現在のワークフローコードでリプレイ
    replayer = Replayer(workflows=[OrderWorkflow])
    await replayer.replay_workflow(history)
    # 成功 = デプロイしても安全
```

## CI/CD 統合パターン

### GitHub Actions の例

```yaml
# .github/workflows/replay-tests.yml
name: Replay Tests

on:
  pull_request:
    branches: [main]

jobs:
  replay-tests:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: "3.11"

      - name: Install dependencies
        run: |
          pip install -r requirements.txt
          pip install pytest pytest-asyncio

      - name: Download production histories
        run: |
          # 本番環境から最近のワークフロー履歴を取得
          python scripts/export_histories.py

      - name: Run replay tests
        run: |
          pytest tests/replay/ --verbose

      - name: Upload results
        if: failure()
        uses: actions/upload-artifact@v3
        with:
          name: replay-failures
          path: replay-failures/
```

### 自動履歴エクスポート

```python
# scripts/export_histories.py
import asyncio
from temporalio.client import Client
from datetime import datetime, timedelta

async def export_recent_histories():
    """最近の本番ワークフロー履歴をエクスポートする"""

    client = await Client.connect("production.temporal.io:7233")

    # 最近完了したワークフローをクエリ
    workflows = client.list_workflows(
        query="WorkflowType='OrderWorkflow' AND CloseTime > '7 days ago'"
    )

    count = 0
    async for workflow in workflows:
        # 履歴をエクスポート
        history = await workflow.fetch_history()

        # ファイルに保存
        filename = f"workflow_histories/{workflow.id}.pb"
        with open(filename, "wb") as f:
            f.write(history.SerializeToString())

        count += 1
        if count >= 100:  # 最新100件に制限
            break

    print(f"Exported {count} workflow histories")

if __name__ == "__main__":
    asyncio.run(export_recent_histories())
```

### リプレイテストスイート

```python
# tests/replay/test_workflow_replay.py
import pytest
import glob
from temporalio.worker import Replayer
from temporalio.api.history.v1 import History
from workflows import OrderWorkflow, PaymentWorkflow

@pytest.mark.asyncio
async def test_replay_all_histories():
    """すべての本番履歴をリプレイする"""

    replayer = Replayer(
        workflows=[OrderWorkflow, PaymentWorkflow]
    )

    # すべての履歴ファイルを読み込む
    history_files = glob.glob("workflow_histories/*.pb")

    failures = []
    for history_file in history_files:
        try:
            with open(history_file, "rb") as f:
                history = History.FromString(f.read())

            await replayer.replay_workflow(history)
            print(f"✓ {history_file}")

        except Exception as e:
            failures.append((history_file, str(e)))
            print(f"✗ {history_file}: {e}")

    # 失敗を報告
    if failures:
        pytest.fail(
            f"Replay failed for {len(failures)} workflows:\n"
            + "\n".join(f"  {file}: {error}" for file, error in failures)
        )
```

## バージョン互換性テスト

### コード進化のテスト

```python
@pytest.mark.asyncio
async def test_workflow_version_compatibility():
    """バージョン変更を伴うワークフローをテストする"""

    @workflow.defn
    class EvolvingWorkflow:
        @workflow.run
        async def run(self) -> str:
            # 安全なコード進化のためにバージョニングを使用する
            version = workflow.get_version("feature-flag", 1, 2)

            if version == 1:
                # 古い動作
                return "version-1"
            else:
                # 新しい動作
                return "version-2"

    env = await WorkflowEnvironment.start_time_skipping()

    # バージョン1の動作をテスト
    async with Worker(
        env.client,
        task_queue="test",
        workflows=[EvolvingWorkflow],
    ):
        result_v1 = await env.client.execute_workflow(
            EvolvingWorkflow.run,
            id="evolving-v1",
            task_queue="test",
        )
        assert result_v1 == "version-1"

        # バージョン2でワークフローが再度実行されることをシミュレート
        result_v2 = await env.client.execute_workflow(
            EvolvingWorkflow.run,
            id="evolving-v2",
            task_queue="test",
        )
        # 新しいワークフローはバージョン2を使用する
        assert result_v2 == "version-2"

    await env.shutdown()
```

### 移行戦略

```python
# フェーズ1: バージョンチェックを追加
@workflow.defn
class MigratingWorkflow:
    @workflow.run
    async def run(self) -> dict:
        version = workflow.get_version("new-logic", 1, 2)

        if version == 1:
            # 古いロジック（既存のワークフロー）
            return await self._old_implementation()
        else:
            # 新しいロジック（新しいワークフロー）
            return await self._new_implementation()

# フェーズ2: すべての古いワークフローが完了した後、古いコードを削除
@workflow.defn
class MigratedWorkflow:
    @workflow.run
    async def run(self) -> dict:
        # 新しいロジックのみが残る
        return await self._new_implementation()
```

## ベストプラクティス

1. **デプロイ前にリプレイ**: ワークフローの変更をデプロイする前に必ずリプレイテストを実行する
2. **定期的にエクスポート**: テスト用に本番履歴を継続的にエクスポートする
3. **CI/CD 統合**: プルリクエストチェックでの自動リプレイテスト
4. **バージョン追跡**: 安全なコード進化のために `workflow.get_version()` を使用する
5. **履歴の保持**: 回帰テスト用に代表的なワークフロー履歴を保持する
6. **決定論**: `random()`、`datetime.now()`、または直接的な外部呼び出しを決して使用しない
7. **包括的なテスト**: さまざまなワークフロー実行パスに対してテストする

## 一般的なリプレイエラー

**非決定論的エラー**:
```
WorkflowNonDeterministicError: Workflow command mismatch at position 5
Expected: ScheduleActivityTask(activity_id='activity-1')
Got: ScheduleActivityTask(activity_id='activity-2')
```

**解決策**: コード変更によりワークフローの決定順序が変更された

**バージョン不一致エラー**:
```
WorkflowVersionError: Workflow version changed from 1 to 2 without using get_version()
```

**解決策**: 後方互換性のある変更のために `workflow.get_version()` を使用する

## 追加リソース

- リプレイテスト: docs.temporal.io/develop/python/testing-suite#replay-testing
- ワークフローバージョニング: docs.temporal.io/workflows#versioning
- 決定論ガイド: docs.temporal.io/workflows#deterministic-constraints
- CI/CD 統合: github.com/temporalio/samples-python/tree/main/.github/workflows
