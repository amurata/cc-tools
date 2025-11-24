# Temporal Python テスト用のローカル開発セットアップ

pytest統合とカバレッジ追跡を備えたローカルTemporal開発環境をセットアップするための包括的なガイド。

## Docker Compose による Temporal サーバーのセットアップ

### 基本的な Docker Compose 構成

```yaml
# docker-compose.yml
version: "3.8"

services:
  temporal:
    image: temporalio/auto-setup:latest
    container_name: temporal-dev
    ports:
      - "7233:7233" # Temporal サーバー
      - "8233:8233" # Web UI
    environment:
      - DB=postgresql
      - POSTGRES_USER=temporal
      - POSTGRES_PWD=temporal
      - POSTGRES_SEEDS=postgresql
      - DYNAMIC_CONFIG_FILE_PATH=config/dynamicconfig/development-sql.yaml
    depends_on:
      - postgresql

  postgresql:
    image: postgres:14-alpine
    container_name: temporal-postgres
    environment:
      - POSTGRES_USER=temporal
      - POSTGRES_PASSWORD=temporal
      - POSTGRES_DB=temporal
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  temporal-ui:
    image: temporalio/ui:latest
    container_name: temporal-ui
    depends_on:
      - temporal
    environment:
      - TEMPORAL_ADDRESS=temporal:7233
      - TEMPORAL_CORS_ORIGINS=http://localhost:3000
    ports:
      - "8080:8080"

volumes:
  postgres_data:
```

### ローカルサーバーの起動

```bash
# Temporal サーバーを起動
docker-compose up -d

# サーバーが実行中であることを確認
docker-compose ps

# ログを表示
docker-compose logs -f temporal

# Temporal Web UI にアクセス
open http://localhost:8080

# サーバーを停止
docker-compose down

# データをリセット（初期状態に戻す）
docker-compose down -v
```

### ヘルスチェック・スクリプト

```python
# scripts/health_check.py
import asyncio
from temporalio.client import Client

async def check_temporal_health():
    """Temporal サーバーにアクセス可能か確認する"""
    try:
        client = await Client.connect("localhost:7233")
        print("✓ Connected to Temporal server")

        # ワークフロー実行をテスト
        from temporalio.worker import Worker

        @workflow.defn
        class HealthCheckWorkflow:
            @workflow.run
            async def run(self) -> str:
                return "healthy"

        async with Worker(
            client,
            task_queue="health-check",
            workflows=[HealthCheckWorkflow],
        ):
            result = await client.execute_workflow(
                HealthCheckWorkflow.run,
                id="health-check",
                task_queue="health-check",
            )
            print(f"✓ Workflow execution successful: {result}")

        return True

    except Exception as e:
        print(f"✗ Health check failed: {e}")
        return False

if __name__ == "__main__":
    asyncio.run(check_temporal_health())
```

## pytest 構成

### プロジェクト構造

```
temporal-project/
├── docker-compose.yml
├── pyproject.toml
├── pytest.ini
├── requirements.txt
├── src/
│   ├── workflows/
│   │   ├── __init__.py
│   │   ├── order_workflow.py
│   │   └── payment_workflow.py
│   └── activities/
│       ├── __init__.py
│       ├── payment_activities.py
│       └── inventory_activities.py
├── tests/
│   ├── conftest.py
│   ├── unit/
│   │   ├── test_workflows.py
│   │   └── test_activities.py
│   ├── integration/
│   │   └── test_order_flow.py
│   └── replay/
│       └── test_workflow_replay.py
└── scripts/
    ├── health_check.py
    └── export_histories.py
```

### pytest 構成

```ini
# pytest.ini
[pytest]
asyncio_mode = auto
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*

# テスト分類用マーカー
markers =
    unit: Unit tests (fast, isolated)
    integration: Integration tests (require Temporal server)
    replay: Replay tests (require production histories)
    slow: Slow running tests

# カバレッジ設定
addopts =
    --verbose
    --strict-markers
    --cov=src
    --cov-report=term-missing
    --cov-report=html
    --cov-fail-under=80

# 非同期テストタイムアウト
asyncio_default_fixture_loop_scope = function
```

### 共有テストフィクスチャ

```python
# tests/conftest.py
import pytest
from temporalio.testing import WorkflowEnvironment
from temporalio.client import Client

@pytest.fixture(scope="session")
def event_loop():
    """非同期フィクスチャ用のイベントループを提供する"""
    import asyncio
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()

@pytest.fixture(scope="session")
async def temporal_client():
    """ローカルサーバーに接続された Temporal クライアントを提供する"""
    client = await Client.connect("localhost:7233")
    yield client
    await client.close()

@pytest.fixture(scope="module")
async def workflow_env():
    """モジュールスコープのタイムスキップ環境"""
    env = await WorkflowEnvironment.start_time_skipping()
    yield env
    await env.shutdown()

@pytest.fixture
def activity_env():
    """関数スコープのアクティビティ環境"""
    from temporalio.testing import ActivityEnvironment
    return ActivityEnvironment()

@pytest.fixture
async def test_worker(temporal_client, workflow_env):
    """事前構成されたテストワーカー"""
    from temporalio.worker import Worker
    from src.workflows import OrderWorkflow, PaymentWorkflow
    from src.activities import process_payment, update_inventory

    return Worker(
        workflow_env.client,
        task_queue="test-queue",
        workflows=[OrderWorkflow, PaymentWorkflow],
        activities=[process_payment, update_inventory],
    )
```

### 依存関係

```txt
# requirements.txt
temporalio>=1.5.0
pytest>=7.4.0
pytest-asyncio>=0.21.0
pytest-cov>=4.1.0
pytest-xdist>=3.3.0  # 並列テスト実行
```

```toml
# pyproject.toml
[build-system]
requires = ["setuptools>=61.0"]
build-backend = "setuptools.build_backend"

[project]
name = "temporal-project"
version = "0.1.0"
requires-python = ">=3.10"
dependencies = [
    "temporalio>=1.5.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=7.4.0",
    "pytest-asyncio>=0.21.0",
    "pytest-cov>=4.1.0",
    "pytest-xdist>=3.3.0",
]

[tool.pytest.ini_options]
asyncio_mode = "auto"
testpaths = ["tests"]
```

## カバレッジ構成

### カバレッジ設定

```ini
# .coveragerc
[run]
source = src
omit =
    */tests/*
    */venv/*
    */__pycache__/*

[report]
exclude_lines =
    # 型チェックブロックを除外
    if TYPE_CHECKING:
    # デバッグコードを除外
    def __repr__
    # 抽象メソッドを除外
    @abstractmethod
    # pass ステートメントを除外
    pass

[html]
directory = htmlcov
```

### カバレッジ付きテストの実行

```bash
# カバレッジ付きですべてのテストを実行
pytest --cov=src --cov-report=term-missing

# HTML カバレッジレポートを生成
pytest --cov=src --cov-report=html
open htmlcov/index.html

# 特定のテストカテゴリを実行
pytest -m unit  # ユニットテストのみ
pytest -m integration  # 統合テストのみ
pytest -m "not slow"  # 遅いテストをスキップ

# 並列実行（高速化）
pytest -n auto  # すべてのCPUコアを使用

# カバレッジが閾値を下回った場合に失敗させる
pytest --cov=src --cov-fail-under=80
```

### カバレッジレポートの例

```
---------- coverage: platform darwin, python 3.11.5 -----------
Name                                Stmts   Miss  Cover   Missing
-----------------------------------------------------------------
src/__init__.py                         0      0   100%
src/activities/__init__.py              2      0   100%
src/activities/inventory.py            45      3    93%   78-80
src/activities/payment.py              38      0   100%
src/workflows/__init__.py               2      0   100%
src/workflows/order_workflow.py        67      5    93%   45-49
src/workflows/payment_workflow.py      52      0   100%
-----------------------------------------------------------------
TOTAL                                 206      8    96%

10 files skipped due to complete coverage.
```

## 開発ワークフロー

### 日々の開発フロー

```bash
# 1. Temporal サーバーを起動
docker-compose up -d

# 2. サーバーのヘルスチェックを確認
python scripts/health_check.py

# 3. 開発中にテストを実行
pytest tests/unit/ --verbose

# 4. コミット前に完全なテストスイートを実行
pytest --cov=src --cov-report=term-missing

# 5. カバレッジを確認
open htmlcov/index.html

# 6. サーバーを停止
docker-compose down
```

### Pre-Commit フック

```bash
# .git/hooks/pre-commit
#!/bin/bash

echo "Running tests..."
pytest --cov=src --cov-fail-under=80

if [ $? -ne 0 ]; then
    echo "Tests failed. Commit aborted."
    exit 1
fi

echo "All tests passed!"
```

### 一般的なタスク用の Makefile

```makefile
# Makefile
.PHONY: setup test test-unit test-integration coverage clean

setup:
	docker-compose up -d
	pip install -r requirements.txt
	python scripts/health_check.py

test:
	pytest --cov=src --cov-report=term-missing

test-unit:
	pytest -m unit --verbose

test-integration:
	pytest -m integration --verbose

test-replay:
	pytest -m replay --verbose

test-parallel:
	pytest -n auto --cov=src

coverage:
	pytest --cov=src --cov-report=html
	open htmlcov/index.html

clean:
	docker-compose down -v
	rm -rf .pytest_cache htmlcov .coverage

ci:
	docker-compose up -d
	sleep 10  # Temporal の起動を待つ
	pytest --cov=src --cov-fail-under=80
	docker-compose down
```

### CI/CD の例

```yaml
# .github/workflows/test.yml
name: Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: "3.11"

      - name: Start Temporal server
        run: docker-compose up -d

      - name: Wait for Temporal
        run: sleep 10

      - name: Install dependencies
        run: |
          pip install -r requirements.txt

      - name: Run tests with coverage
        run: |
          pytest --cov=src --cov-report=xml --cov-fail-under=80

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: ./coverage.xml

      - name: Cleanup
        if: always()
        run: docker-compose down
```

## デバッグのヒント

### Temporal SDK ログの有効化

```python
import logging

# Temporal SDK のデバッグログを有効化
logging.basicConfig(level=logging.DEBUG)
temporal_logger = logging.getLogger("temporalio")
temporal_logger.setLevel(logging.DEBUG)
```

### インタラクティブデバッグ

```python
# テストにブレークポイントを追加
@pytest.mark.asyncio
async def test_workflow_with_breakpoint(workflow_env):
    import pdb; pdb.set_trace()  # ここでデバッグ

    async with Worker(...):
        result = await workflow_env.client.execute_workflow(...)
```

### Temporal Web UI

```bash
# http://localhost:8080 で Web UI にアクセス
# - ワークフロー実行を表示
# - イベント履歴を検査
# - ワークフローをリプレイ
# - ワーカーを監視
```

## ベストプラクティス

1. **分離された環境**: 再現可能なローカルセットアップのために Docker Compose を使用する
2. **ヘルスチェック**: テストを実行する前に必ず Temporal サーバーを確認する
3. **高速なフィードバック**: pytest マーカーを使用してユニットテストを素早く実行する
4. **カバレッジ目標**: 80%以上のコードカバレッジを維持する
5. **並列テスト**: 高速なテスト実行のために pytest-xdist を使用する
6. **CI/CD 統合**: すべてのコミットで自動テストを行う
7. **クリーンアップ**: 必要に応じてテスト実行間に Docker ボリュームをクリアする

## トラブルシューティング

**問題: Temporal サーバーが起動しない**
```bash
# ログを確認
docker-compose logs temporal

# データベースをリセット
docker-compose down -v
docker-compose up -d
```

**問題: テストがタイムアウトする**
```python
# pytest.ini でタイムアウトを増やす
asyncio_default_timeout = 30
```

**問題: ポートが既に使用されている**
```bash
# ポート 7233 を使用しているプロセスを見つける
lsof -i :7233

# プロセスを強制終了するか、docker-compose.yml でポートを変更する
```

## 追加リソース

- Temporal ローカル開発: docs.temporal.io/develop/python/local-dev
- pytest ドキュメント: docs.pytest.org
- Docker Compose: docs.docker.com/compose
- pytest-asyncio: github.com/pytest-dev/pytest-asyncio
