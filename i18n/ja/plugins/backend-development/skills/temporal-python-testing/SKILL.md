> **[English](../../../../../plugins/backend-development/skills/temporal-python-testing/SKILL.md)** | **日本語**

---
name: temporal-python-testing
description: pytest、タイムスキップ、およびモック戦略を使用してTemporalワークフローをテストします。ユニットテスト、統合テスト、リプレイテスト、およびローカル開発セットアップをカバーします。Temporalワークフローテストを実装する場合やテストの失敗をデバッグする場合に使用します。
---

# Temporal Python テスト戦略

pytestを使用したTemporalワークフローの包括的なテストアプローチ、特定のテストシナリオのための段階的なリソース。

## このスキルをいつ使用するか

- **ワークフローのユニットテスト** - タイムスキップを使用した高速なテスト
- **統合テスト** - モック化されたアクティビティを使用したワークフロー
- **リプレイテスト** - 本番履歴に対する決定論の検証
- **ローカル開発** - Temporalサーバーとpytestのセットアップ
- **CI/CD統合** - 自動テストパイプライン
- **カバレッジ戦略** - 80%以上のテストカバレッジの達成

## テスト哲学

**推奨されるアプローチ** (出典: docs.temporal.io/develop/python/testing-suite):
- 大部分を統合テストとして記述する
- 非同期フィクスチャを備えたpytestを使用する
- タイムスキップにより高速なフィードバックが可能（1か月のワークフロー → 数秒）
- アクティビティをモックしてワークフローロジックを分離する
- リプレイテストで決定論を検証する

**3つのテストタイプ**:
1. **ユニット**: タイムスキップを使用したワークフロー、ActivityEnvironmentを使用したアクティビティ
2. **統合**: モック化されたアクティビティを使用したワーカー
3. **エンドツーエンド**: 実際のアクティビティを使用した完全なTemporalサーバー（控えめに使用）

## 利用可能なリソース

このスキルは、段階的な開示を通じて詳細なガイダンスを提供します。テストのニーズに基づいて特定のリソースをロードしてください：

### ユニットテストリソース
**ファイル**: `resources/unit-testing.md`
**ロードするタイミング**: 個々のワークフローまたはアクティビティを分離してテストする場合
**内容**:
- タイムスキップ付き WorkflowEnvironment
- アクティビティテスト用の ActivityEnvironment
- 長時間実行ワークフローの高速実行
- 手動の時間進行パターン
- pytest フィクスチャとパターン

### 統合テストリソース
**ファイル**: `resources/integration-testing.md`
**ロードするタイミング**: モック化された外部依存関係を持つワークフローをテストする場合
**内容**:
- アクティビティモック戦略
- エラー注入パターン
- マルチアクティビティワークフローテスト
- シグナルとクエリのテスト
- カバレッジ戦略

### リプレイテストリソース
**ファイル**: `resources/replay-testing.md`
**ロードするタイミング**: 決定論の検証またはワークフロー変更のデプロイ時
**内容**:
- 決定論の検証
- 本番履歴リプレイ
- CI/CD 統合パターン
- バージョン互換性テスト

### ローカル開発リソース
**ファイル**: `resources/local-setup.md`
**ロードするタイミング**: 開発環境のセットアップ時
**内容**:
- Docker Compose 構成
- pytest セットアップと構成
- カバレッジツール統合
- 開発ワークフロー

## クイックスタートガイド

### 基本的なワークフローテスト

```python
import pytest
from temporalio.testing import WorkflowEnvironment
from temporalio.worker import Worker

@pytest.fixture
async def workflow_env():
    env = await WorkflowEnvironment.start_time_skipping()
    yield env
    await env.shutdown()

@pytest.mark.asyncio
async def test_workflow(workflow_env):
    async with Worker(
        workflow_env.client,
        task_queue="test-queue",
        workflows=[YourWorkflow],
        activities=[your_activity],
    ):
        result = await workflow_env.client.execute_workflow(
            YourWorkflow.run,
            args,
            id="test-wf-id",
            task_queue="test-queue",
        )
        assert result == expected
```

### 基本的なアクティビティテスト

```python
from temporalio.testing import ActivityEnvironment

async def test_activity():
    env = ActivityEnvironment()
    result = await env.run(your_activity, "test-input")
    assert result == expected_output
```

## カバレッジ目標

**推奨カバレッジ** (出典: docs.temporal.io ベストプラクティス):
- **ワークフロー**: ロジックカバレッジ 80%以上
- **アクティビティ**: ロジックカバレッジ 80%以上
- **統合**: モック化されたアクティビティを使用したクリティカルパス
- **リプレイ**: デプロイ前のすべてのワークフローバージョン

## 重要なテスト原則

1. **タイムスキップ** - 1か月のワークフローを数秒でテスト
2. **モックアクティビティ** - ワークフローロジックを外部依存関係から分離
3. **リプレイテスト** - デプロイ前に決定論を検証
4. **高カバレッジ** - 本番ワークフローの目標 80%以上
5. **高速フィードバック** - ユニットテストは数ミリ秒で実行

## リソースの使用方法

**必要に応じて特定のリソースをロードする**:
- "ユニットテストパターンを見せて" → `resources/unit-testing.md` をロード
- "アクティビティをモックするには？" → `resources/integration-testing.md` をロード
- "ローカルTemporalサーバーのセットアップ" → `resources/local-setup.md` をロード
- "決定論の検証" → `resources/replay-testing.md` をロード

## 追加リファレンス

- Python SDK テスト: docs.temporal.io/develop/python/testing-suite
- テストパターン: github.com/temporalio/temporal/blob/main/docs/development/testing.md
- Python サンプル: github.com/temporalio/samples-python
