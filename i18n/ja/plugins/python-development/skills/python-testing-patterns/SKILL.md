---
name: python-testing-patterns
description: pytest、フィクスチャ、モッキング、テスト駆動開発を使用した包括的なテスト戦略を実装。Pythonテストの記述、テストスイートのセットアップ、テストベストプラクティスの実装時に使用。
---

> **[English](../../../../../../plugins/python-development/skills/python-testing-patterns/SKILL.md)** | **日本語**

# Pythonテストパターン

pytest、フィクスチャ、モッキング、パラメータ化、テスト駆動開発プラクティスを使用した堅牢なテスト戦略の実装に関する包括的なガイド。

## このスキルを使用するタイミング

- Pythonコードの単体テストの記述
- テストスイートとテストインフラのセットアップ
- テスト駆動開発（TDD）の実装
- APIとサービスの統合テストの作成
- 外部依存関係とサービスのモッキング
- 非同期コードと並行操作のテスト
- CI/CDでの継続的テストのセットアップ
- プロパティベーステストの実装
- データベース操作のテスト
- 失敗したテストのデバッグ

## コア概念

### 1. テストタイプ
- **単体テスト**: 個別の関数/クラスを分離してテスト
- **統合テスト**: コンポーネント間の相互作用をテスト
- **機能テスト**: 完全な機能をエンドツーエンドでテスト
- **パフォーマンステスト**: 速度とリソース使用量を測定

### 2. テスト構造（AAAパターン）
- **Arrange（準備）**: テストデータと前提条件をセットアップ
- **Act（実行）**: テスト対象のコードを実行
- **Assert（検証）**: 結果を検証

### 3. テストカバレッジ
- テストによって実行されるコードを測定
- テストされていないコードパスを特定
- 単に高いパーセンテージではなく、意味のあるカバレッジを目指す

### 4. テスト分離
- テストは独立している必要がある
- テスト間で状態を共有しない
- 各テストは後片付けをする必要がある

## クイックスタート

```python
# test_example.py
def add(a, b):
    return a + b

def test_add():
    """基本的なテスト例。"""
    result = add(2, 3)
    assert result == 5

def test_add_negative():
    """負の数でテスト。"""
    assert add(-1, 1) == 0

# 実行: pytest test_example.py
```

## 基本パターン

### パターン1: 基本的なpytestテスト

```python
# test_calculator.py
import pytest

class Calculator:
    """テスト用のシンプルな計算機。"""

    def add(self, a: float, b: float) -> float:
        return a + b

    def subtract(self, a: float, b: float) -> float:
        return a - b

    def multiply(self, a: float, b: float) -> float:
        return a * b

    def divide(self, a: float, b: float) -> float:
        if b == 0:
            raise ValueError("Cannot divide by zero")
        return a / b


def test_addition():
    """加算をテスト。"""
    calc = Calculator()
    assert calc.add(2, 3) == 5
    assert calc.add(-1, 1) == 0
    assert calc.add(0, 0) == 0


def test_subtraction():
    """減算をテスト。"""
    calc = Calculator()
    assert calc.subtract(5, 3) == 2
    assert calc.subtract(0, 5) == -5


def test_multiplication():
    """乗算をテスト。"""
    calc = Calculator()
    assert calc.multiply(3, 4) == 12
    assert calc.multiply(0, 5) == 0


def test_division():
    """除算をテスト。"""
    calc = Calculator()
    assert calc.divide(6, 3) == 2
    assert calc.divide(5, 2) == 2.5


def test_division_by_zero():
    """ゼロ除算がエラーを発生させることをテスト。"""
    calc = Calculator()
    with pytest.raises(ValueError, match="Cannot divide by zero"):
        calc.divide(5, 0)
```

### パターン2: セットアップとティアダウンのフィクスチャ

```python
# test_database.py
import pytest
from typing import Generator

class Database:
    """シンプルなデータベースクラス。"""

    def __init__(self, connection_string: str):
        self.connection_string = connection_string
        self.connected = False

    def connect(self):
        """データベースに接続。"""
        self.connected = True

    def disconnect(self):
        """データベースから切断。"""
        self.connected = False

    def query(self, sql: str) -> list:
        """クエリを実行。"""
        if not self.connected:
            raise RuntimeError("Not connected")
        return [{"id": 1, "name": "Test"}]


@pytest.fixture
def db() -> Generator[Database, None, None]:
    """接続されたデータベースを提供するフィクスチャ。"""
    # セットアップ
    database = Database("sqlite:///:memory:")
    database.connect()

    # テストに提供
    yield database

    # ティアダウン
    database.disconnect()


def test_database_query(db):
    """フィクスチャを使用したデータベースクエリのテスト。"""
    results = db.query("SELECT * FROM users")
    assert len(results) == 1
    assert results[0]["name"] == "Test"


@pytest.fixture(scope="session")
def app_config():
    """セッションスコープのフィクスチャ - テストセッションごとに1回作成。"""
    return {
        "database_url": "postgresql://localhost/test",
        "api_key": "test-key",
        "debug": True
    }


@pytest.fixture(scope="module")
def api_client(app_config):
    """モジュールスコープのフィクスチャ - テストモジュールごとに1回作成。"""
    # 高価なリソースをセットアップ
    client = {"config": app_config, "session": "active"}
    yield client
    # クリーンアップ
    client["session"] = "closed"


def test_api_client(api_client):
    """APIクライアントフィクスチャを使用したテスト。"""
    assert api_client["session"] == "active"
    assert api_client["config"]["debug"] is True
```

### パターン3: パラメータ化テスト

```python
# test_validation.py
import pytest

def is_valid_email(email: str) -> bool:
    """メールアドレスが有効かチェック。"""
    return "@" in email and "." in email.split("@")[1]


@pytest.mark.parametrize("email,expected", [
    ("user@example.com", True),
    ("test.user@domain.co.uk", True),
    ("invalid.email", False),
    ("@example.com", False),
    ("user@domain", False),
    ("", False),
])
def test_email_validation(email, expected):
    """さまざまな入力でメール検証をテスト。"""
    assert is_valid_email(email) == expected


@pytest.mark.parametrize("a,b,expected", [
    (2, 3, 5),
    (0, 0, 0),
    (-1, 1, 0),
    (100, 200, 300),
    (-5, -5, -10),
])
def test_addition_parameterized(a, b, expected):
    """複数のパラメータセットで加算をテスト。"""
    from test_calculator import Calculator
    calc = Calculator()
    assert calc.add(a, b) == expected


# 特殊ケースにpytest.paramを使用
@pytest.mark.parametrize("value,expected", [
    pytest.param(1, True, id="positive"),
    pytest.param(0, False, id="zero"),
    pytest.param(-1, False, id="negative"),
])
def test_is_positive(value, expected):
    """カスタムテストIDでテスト。"""
    assert (value > 0) == expected
```

### パターン4: unittest.mockによるモッキング

```python
# test_api_client.py
import pytest
from unittest.mock import Mock, patch, MagicMock
import requests

class APIClient:
    """シンプルなAPIクライアント。"""

    def __init__(self, base_url: str):
        self.base_url = base_url

    def get_user(self, user_id: int) -> dict:
        """APIからユーザーを取得。"""
        response = requests.get(f"{self.base_url}/users/{user_id}")
        response.raise_for_status()
        return response.json()

    def create_user(self, data: dict) -> dict:
        """新しいユーザーを作成。"""
        response = requests.post(f"{self.base_url}/users", json=data)
        response.raise_for_status()
        return response.json()


def test_get_user_success():
    """モックを使用した成功したAPI呼び出しのテスト。"""
    client = APIClient("https://api.example.com")

    mock_response = Mock()
    mock_response.json.return_value = {"id": 1, "name": "John Doe"}
    mock_response.raise_for_status.return_value = None

    with patch("requests.get", return_value=mock_response) as mock_get:
        user = client.get_user(1)

        assert user["id"] == 1
        assert user["name"] == "John Doe"
        mock_get.assert_called_once_with("https://api.example.com/users/1")


def test_get_user_not_found():
    """404エラーのAPI呼び出しのテスト。"""
    client = APIClient("https://api.example.com")

    mock_response = Mock()
    mock_response.raise_for_status.side_effect = requests.HTTPError("404 Not Found")

    with patch("requests.get", return_value=mock_response):
        with pytest.raises(requests.HTTPError):
            client.get_user(999)


@patch("requests.post")
def test_create_user(mock_post):
    """デコレータ構文でユーザー作成をテスト。"""
    client = APIClient("https://api.example.com")

    mock_post.return_value.json.return_value = {"id": 2, "name": "Jane Doe"}
    mock_post.return_value.raise_for_status.return_value = None

    user_data = {"name": "Jane Doe", "email": "jane@example.com"}
    result = client.create_user(user_data)

    assert result["id"] == 2
    mock_post.assert_called_once()
    call_args = mock_post.call_args
    assert call_args.kwargs["json"] == user_data
```

### パターン5: 例外のテスト

```python
# test_exceptions.py
import pytest

def divide(a: float, b: float) -> float:
    """aをbで除算。"""
    if b == 0:
        raise ZeroDivisionError("Division by zero")
    if not isinstance(a, (int, float)) or not isinstance(b, (int, float)):
        raise TypeError("Arguments must be numbers")
    return a / b


def test_zero_division():
    """ゼロ除算で例外が発生することをテスト。"""
    with pytest.raises(ZeroDivisionError):
        divide(10, 0)


def test_zero_division_with_message():
    """例外メッセージをテスト。"""
    with pytest.raises(ZeroDivisionError, match="Division by zero"):
        divide(5, 0)


def test_type_error():
    """型エラー例外をテスト。"""
    with pytest.raises(TypeError, match="must be numbers"):
        divide("10", 5)


def test_exception_info():
    """例外情報へのアクセスをテスト。"""
    with pytest.raises(ValueError) as exc_info:
        int("not a number")

    assert "invalid literal" in str(exc_info.value)
```

## 高度なパターン

### パターン6: 非同期コードのテスト

```python
# test_async.py
import pytest
import asyncio

async def fetch_data(url: str) -> dict:
    """データを非同期に取得。"""
    await asyncio.sleep(0.1)
    return {"url": url, "data": "result"}


@pytest.mark.asyncio
async def test_fetch_data():
    """非同期関数をテスト。"""
    result = await fetch_data("https://api.example.com")
    assert result["url"] == "https://api.example.com"
    assert "data" in result


@pytest.mark.asyncio
async def test_concurrent_fetches():
    """並行非同期操作をテスト。"""
    urls = ["url1", "url2", "url3"]
    tasks = [fetch_data(url) for url in urls]
    results = await asyncio.gather(*tasks)

    assert len(results) == 3
    assert all("data" in r for r in results)


@pytest.fixture
async def async_client():
    """非同期フィクスチャ。"""
    client = {"connected": True}
    yield client
    client["connected"] = False


@pytest.mark.asyncio
async def test_with_async_fixture(async_client):
    """非同期フィクスチャを使用したテスト。"""
    assert async_client["connected"] is True
```

### パターン7: テスト用のMonkeypatch

```python
# test_environment.py
import os
import pytest

def get_database_url() -> str:
    """環境からデータベースURLを取得。"""
    return os.environ.get("DATABASE_URL", "sqlite:///:memory:")


def test_database_url_default():
    """デフォルトのデータベースURLをテスト。"""
    # 設定されている場合は実際の環境変数を使用
    url = get_database_url()
    assert url


def test_database_url_custom(monkeypatch):
    """monkeypatchでカスタムデータベースURLをテスト。"""
    monkeypatch.setenv("DATABASE_URL", "postgresql://localhost/test")
    assert get_database_url() == "postgresql://localhost/test"


def test_database_url_not_set(monkeypatch):
    """環境変数が設定されていない場合をテスト。"""
    monkeypatch.delenv("DATABASE_URL", raising=False)
    assert get_database_url() == "sqlite:///:memory:"


class Config:
    """設定クラス。"""

    def __init__(self):
        self.api_key = "production-key"

    def get_api_key(self):
        return self.api_key


def test_monkeypatch_attribute(monkeypatch):
    """オブジェクト属性のmonkeypatchをテスト。"""
    config = Config()
    monkeypatch.setattr(config, "api_key", "test-key")
    assert config.get_api_key() == "test-key"
```

### パターン8: 一時ファイルとディレクトリ

```python
# test_file_operations.py
import pytest
from pathlib import Path

def save_data(filepath: Path, data: str):
    """データをファイルに保存。"""
    filepath.write_text(data)


def load_data(filepath: Path) -> str:
    """ファイルからデータをロード。"""
    return filepath.read_text()


def test_file_operations(tmp_path):
    """一時ディレクトリでファイル操作をテスト。"""
    # tmp_pathはpathlib.Pathオブジェクト
    test_file = tmp_path / "test_data.txt"

    # データを保存
    save_data(test_file, "Hello, World!")

    # ファイルが存在することを確認
    assert test_file.exists()

    # データをロードして検証
    data = load_data(test_file)
    assert data == "Hello, World!"


def test_multiple_files(tmp_path):
    """複数の一時ファイルでテスト。"""
    files = {
        "file1.txt": "Content 1",
        "file2.txt": "Content 2",
        "file3.txt": "Content 3"
    }

    for filename, content in files.items():
        filepath = tmp_path / filename
        save_data(filepath, content)

    # すべてのファイルが作成されたことを確認
    assert len(list(tmp_path.iterdir())) == 3

    # 内容を確認
    for filename, expected_content in files.items():
        filepath = tmp_path / filename
        assert load_data(filepath) == expected_content
```

### パターン9: カスタムフィクスチャとConftest

```python
# conftest.py
"""すべてのテスト用の共有フィクスチャ。"""
import pytest

@pytest.fixture(scope="session")
def database_url():
    """すべてのテストにデータベースURLを提供。"""
    return "postgresql://localhost/test_db"


@pytest.fixture(autouse=True)
def reset_database(database_url):
    """各テストの前に実行される自動使用フィクスチャ。"""
    # セットアップ: データベースをクリア
    print(f"Clearing database: {database_url}")
    yield
    # ティアダウン: クリーンアップ
    print("Test completed")


@pytest.fixture
def sample_user():
    """サンプルユーザーデータを提供。"""
    return {
        "id": 1,
        "name": "Test User",
        "email": "test@example.com"
    }


@pytest.fixture
def sample_users():
    """サンプルユーザーのリストを提供。"""
    return [
        {"id": 1, "name": "User 1"},
        {"id": 2, "name": "User 2"},
        {"id": 3, "name": "User 3"},
    ]


# パラメータ化フィクスチャ
@pytest.fixture(params=["sqlite", "postgresql", "mysql"])
def db_backend(request):
    """異なるデータベースバックエンドでテストを実行するフィクスチャ。"""
    return request.param


def test_with_db_backend(db_backend):
    """このテストは異なるバックエンドで3回実行される。"""
    print(f"Testing with {db_backend}")
    assert db_backend in ["sqlite", "postgresql", "mysql"]
```

### パターン10: プロパティベーステスト

```python
# test_properties.py
from hypothesis import given, strategies as st
import pytest

def reverse_string(s: str) -> str:
    """文字列を反転。"""
    return s[::-1]


@given(st.text())
def test_reverse_twice_is_original(s):
    """プロパティ: 2回反転すると元に戻る。"""
    assert reverse_string(reverse_string(s)) == s


@given(st.text())
def test_reverse_length(s):
    """プロパティ: 反転された文字列は同じ長さ。"""
    assert len(reverse_string(s)) == len(s)


@given(st.integers(), st.integers())
def test_addition_commutative(a, b):
    """プロパティ: 加算は可換。"""
    assert a + b == b + a


@given(st.lists(st.integers()))
def test_sorted_list_properties(lst):
    """プロパティ: ソートされたリストは順序付けられている。"""
    sorted_lst = sorted(lst)

    # 同じ長さ
    assert len(sorted_lst) == len(lst)

    # すべての要素が存在
    assert set(sorted_lst) == set(lst)

    # 順序付けられている
    for i in range(len(sorted_lst) - 1):
        assert sorted_lst[i] <= sorted_lst[i + 1]
```

## テストのベストプラクティス

### テスト構成

```python
# tests/
#   __init__.py
#   conftest.py           # 共有フィクスチャ
#   test_unit/            # 単体テスト
#     test_models.py
#     test_utils.py
#   test_integration/     # 統合テスト
#     test_api.py
#     test_database.py
#   test_e2e/            # エンドツーエンドテスト
#     test_workflows.py
```

### テストの命名

```python
# 良いテスト名
def test_user_creation_with_valid_data():
    """テストされている内容を明確に説明する名前。"""
    pass


def test_login_fails_with_invalid_password():
    """期待される動作を説明する名前。"""
    pass


def test_api_returns_404_for_missing_resource():
    """入力と期待される結果について具体的。"""
    pass


# 悪いテスト名
def test_1():  # 説明的でない
    pass


def test_user():  # 曖昧すぎる
    pass


def test_function():  # テストされている内容を説明していない
    pass
```

### テストマーカー

```python
# test_markers.py
import pytest

@pytest.mark.slow
def test_slow_operation():
    """遅いテストをマーク。"""
    import time
    time.sleep(2)


@pytest.mark.integration
def test_database_integration():
    """統合テストをマーク。"""
    pass


@pytest.mark.skip(reason="Feature not implemented yet")
def test_future_feature():
    """一時的にテストをスキップ。"""
    pass


@pytest.mark.skipif(os.name == "nt", reason="Unix only test")
def test_unix_specific():
    """条件付きスキップ。"""
    pass


@pytest.mark.xfail(reason="Known bug #123")
def test_known_bug():
    """予想される失敗をマーク。"""
    assert False


# 実行:
# pytest -m slow          # 遅いテストのみ実行
# pytest -m "not slow"    # 遅いテストをスキップ
# pytest -m integration   # 統合テストを実行
```

### カバレッジレポート

```bash
# カバレッジをインストール
pip install pytest-cov

# カバレッジ付きでテストを実行
pytest --cov=myapp tests/

# HTMLレポートを生成
pytest --cov=myapp --cov-report=html tests/

# しきい値以下でカバレッジが失敗
pytest --cov=myapp --cov-fail-under=80 tests/

# 欠落行を表示
pytest --cov=myapp --cov-report=term-missing tests/
```

## データベースコードのテスト

```python
# test_database_models.py
import pytest
from sqlalchemy import create_engine, Column, Integer, String
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session

Base = declarative_base()


class User(Base):
    """ユーザーモデル。"""
    __tablename__ = "users"

    id = Column(Integer, primary_key=True)
    name = Column(String(50))
    email = Column(String(100), unique=True)


@pytest.fixture(scope="function")
def db_session() -> Session:
    """テスト用のインメモリデータベースを作成。"""
    engine = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(engine)

    SessionLocal = sessionmaker(bind=engine)
    session = SessionLocal()

    yield session

    session.close()


def test_create_user(db_session):
    """ユーザー作成をテスト。"""
    user = User(name="Test User", email="test@example.com")
    db_session.add(user)
    db_session.commit()

    assert user.id is not None
    assert user.name == "Test User"


def test_query_user(db_session):
    """ユーザークエリをテスト。"""
    user1 = User(name="User 1", email="user1@example.com")
    user2 = User(name="User 2", email="user2@example.com")

    db_session.add_all([user1, user2])
    db_session.commit()

    users = db_session.query(User).all()
    assert len(users) == 2


def test_unique_email_constraint(db_session):
    """ユニークメール制約をテスト。"""
    from sqlalchemy.exc import IntegrityError

    user1 = User(name="User 1", email="same@example.com")
    user2 = User(name="User 2", email="same@example.com")

    db_session.add(user1)
    db_session.commit()

    db_session.add(user2)

    with pytest.raises(IntegrityError):
        db_session.commit()
```

## CI/CD統合

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    strategy:
      matrix:
        python-version: ["3.9", "3.10", "3.11", "3.12"]

    steps:
      - uses: actions/checkout@v3

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: ${{ matrix.python-version }}

      - name: Install dependencies
        run: |
          pip install -e ".[dev]"
          pip install pytest pytest-cov

      - name: Run tests
        run: |
          pytest --cov=myapp --cov-report=xml

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: ./coverage.xml
```

## 設定ファイル

```ini
# pytest.ini
[pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts =
    -v
    --strict-markers
    --tb=short
    --cov=myapp
    --cov-report=term-missing
markers =
    slow: marks tests as slow
    integration: marks integration tests
    unit: marks unit tests
    e2e: marks end-to-end tests
```

```toml
# pyproject.toml
[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
addopts = [
    "-v",
    "--cov=myapp",
    "--cov-report=term-missing",
]

[tool.coverage.run]
source = ["myapp"]
omit = ["*/tests/*", "*/migrations/*"]

[tool.coverage.report]
exclude_lines = [
    "pragma: no cover",
    "def __repr__",
    "raise AssertionError",
    "raise NotImplementedError",
]
```

## リソース

- **pytestドキュメント**: https://docs.pytest.org/
- **unittest.mock**: https://docs.python.org/3/library/unittest.mock.html
- **hypothesis**: プロパティベーステスト
- **pytest-asyncio**: 非同期コードのテスト
- **pytest-cov**: カバレッジレポート
- **pytest-mock**: mock用のpytestラッパー

## ベストプラクティス概要

1. **テストを最初に記述**（TDD）またはコードと一緒に
2. 可能な場合は**テストごとに1つのアサーション**
3. 動作を説明する**説明的なテスト名を使用**
4. **テストを独立**して分離した状態に保つ
5. セットアップとティアダウンに**フィクスチャを使用**
6. 外部依存関係を**適切にモック**
7. 重複を減らすために**テストをパラメータ化**
8. **エッジケース**とエラー条件をテスト
9. **カバレッジを測定**するが品質に焦点
10. すべてのコミットで**CI/CDでテストを実行**
