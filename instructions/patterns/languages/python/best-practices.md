# Pythonベストプラクティス

## 型ヒント（Python 3.10+）
コードの明確性とIDE支援のために最新の型アノテーションを使用。

```python
# 良い例 - Python 3.10+構文
def calculate_discount(price: float, discount_rate: float) -> float:
    return price * (1 - discount_rate)

# Union型に | 演算子を使用（Python 3.10+）
def process_items(items: list[str], config: dict[str, Any] | None = None) -> list[str]:
    config = config or {}
    return [item.upper() for item in items]

# 複雑な型にはTypeAlias（Python 3.10+）
from typing import TypeAlias, Any

UserData: TypeAlias = dict[str, str | int | list[str]]

# 悪い例 - 古いスタイル（3.10以前）
from typing import List, Optional, Dict  # もう使わない
def old_process(items: List[str], config: Optional[Dict[str, Any]] = None):  # 古い
    pass
```

## パターンマッチング（Python 3.10+）
クリーンな条件ロジックにmatch/caseを使用。

```python
# 良い例 - パターンマッチング
def handle_response(response: dict[str, Any]) -> str:
    match response:
        case {"status": 200, "data": data}:
            return f"成功: {data}"
        case {"status": 404}:
            return "見つかりません"
        case {"status": code} if code >= 500:
            return f"サーバーエラー: {code}"
        case _:
            return "不明なレスポンス"

# ガード付き構造パターンマッチング
def process_command(command: list[str]) -> str:
    match command:
        case ["move", ("north" | "south" | "east" | "west") as direction]:
            return f"{direction}へ移動"
        case ["attack", target] if target:
            return f"{target}を攻撃"
        case ["defend"]:
            return "防御"
        case _:
            return "無効なコマンド"
```

## データクラス
単純なデータコンテナにはdataclassesを使用。

```python
# 良い例
from dataclasses import dataclass, field
from datetime import datetime

@dataclass
class User:
    id: int
    name: str
    email: str
    created_at: datetime = field(default_factory=datetime.now)
    tags: list[str] = field(default_factory=list)

# バリデーション付き__post_init__
@dataclass
class Product:
    name: str
    price: float
    quantity: int = 0
    
    def __post_init__(self):
        if self.price < 0:
            raise ValueError("価格は負の値にできません")

# 悪い例
class User:
    def __init__(self, id, name, email):
        self.id = id
        self.name = name
        self.email = email
        self.created_at = datetime.now()
```

## プロトコル（構造的サブタイピング）
型安全性を持つダックタイピングにProtocolを使用。

```python
# 良い例 - プロトコルパターン
from typing import Protocol, runtime_checkable

@runtime_checkable
class Drawable(Protocol):
    def draw(self) -> None: ...

@runtime_checkable
class Resizable(Protocol):
    def resize(self, width: int, height: int) -> None: ...

class Shape:
    def draw(self) -> None:
        print("図形を描画")
    
    def resize(self, width: int, height: int) -> None:
        print(f"{width}x{height}にリサイズ")

def render(obj: Drawable) -> None:
    obj.draw()  # 型安全なダックタイピング

# ShapeはDrawableプロトコルを暗黙的に実装
shape = Shape()
render(shape)  # 動作する！

# ランタイムチェック
if isinstance(shape, Drawable):
    print("図形は描画可能")
```

## コンテキストマネージャー
リソース管理にはコンテキストマネージャーを使用。

```python
# 良い例
with open('file.txt', 'r') as f:
    content = f.read()

# contextlibでカスタムコンテキストマネージャー
from contextlib import contextmanager
import sqlite3

@contextmanager
def database_connection(db_name: str):
    conn = sqlite3.connect(db_name)
    try:
        yield conn
    finally:
        conn.close()

# カスタムコンテキストマネージャーの使用
with database_connection('app.db') as conn:
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM users")

# 括弧内コンテキストマネージャー（Python 3.10+）
with (
    open('input.txt') as infile,
    open('output.txt', 'w') as outfile
):
    outfile.write(infile.read())

# 悪い例
f = open('file.txt', 'r')
content = f.read()
f.close()  # 忘れやすい
```

## Async/Await
並行I/O操作にはasync/awaitを使用。

```python
# 良い例
import asyncio
import aiohttp

async def fetch_data(url: str) -> dict[str, Any]:
    async with aiohttp.ClientSession() as session:
        async with session.get(url) as response:
            return await response.json()

async def fetch_multiple(urls: list[str]) -> list[dict[str, Any]]:
    tasks = [fetch_data(url) for url in urls]
    return await asyncio.gather(*tasks)

# asyncio.TaskGroupの使用（Python 3.11+）
async def fetch_with_taskgroup(urls: list[str]) -> list[dict[str, Any]]:
    async with asyncio.TaskGroup() as tg:
        tasks = [tg.create_task(fetch_data(url)) for url in urls]
    return [task.result() for task in tasks]

# 悪い例 - ブロッキングI/O
import requests

def fetch_multiple_blocking(urls):
    results = []
    for url in urls:
        response = requests.get(url)
        results.append(response.json())
    return results
```

## エラー処理
特定の例外と適切なエラー処理を使用。

```python
# 良い例 - カスタム例外とException Groups（Python 3.11+）
class ValidationError(Exception):
    """検証失敗時に発生"""
    pass

class EmailValidationError(ValidationError):
    """特定のメール検証エラー"""
    pass

def validate_user(data: dict[str, Any]) -> None:
    errors = []
    
    if 'email' not in data:
        errors.append(EmailValidationError("メールは必須"))
    elif '@' not in data['email']:
        errors.append(EmailValidationError(f"無効なメール: {data['email']}"))
    
    if 'age' in data and data['age'] < 0:
        errors.append(ValidationError("年齢は負の値にできません"))
    
    if errors:
        raise ExceptionGroup("検証失敗", errors)

# exception groupsの処理
try:
    validate_user({'email': 'invalid', 'age': -1})
except* EmailValidationError as eg:
    for error in eg.exceptions:
        print(f"メールエラー: {error}")
except* ValidationError as eg:
    for error in eg.exceptions:
        print(f"検証エラー: {error}")
```

## リスト内包表記とジェネレータ
クリーンなコードには内包表記、メモリ効率にはジェネレータを使用。

```python
# 良い例
# セイウチ演算子付きリスト内包表記（Python 3.8+）
data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
filtered = [y for x in data if (y := x * 2) > 10]

# 大規模データセット用ジェネレータ
def read_large_file(file_path: str):
    with open(file_path) as f:
        for line in f:
            if processed := line.strip():  # セイウチ演算子
                yield processed

# ジェネレータ式
sum_squares = sum(x**2 for x in range(1000000))

# 悪い例
squares = []
for x in range(10):
    if x % 2 == 0:
        squares.append(x**2)
```

## デコレータ
横断的関心事にはデコレータを使用。

```python
# 良い例 - ParamSpecを使った最新デコレータ（Python 3.10+）
from functools import wraps
from typing import ParamSpec, TypeVar, Callable
import time

P = ParamSpec('P')
R = TypeVar('R')

def measure_time(func: Callable[P, R]) -> Callable[P, R]:
    @wraps(func)
    def wrapper(*args: P.args, **kwargs: P.kwargs) -> R:
        start = time.time()
        result = func(*args, **kwargs)
        end = time.time()
        print(f"{func.__name__}は{end - start:.2f}秒かかりました")
        return result
    return wrapper

@measure_time
def slow_function() -> str:
    time.sleep(1)
    return "完了"

# キャッシュデコレータ
from functools import lru_cache

@lru_cache(maxsize=128)
def expensive_computation(n: int) -> int:
    return n ** n
```

## パス処理
ファイルシステム操作にはpathlibを使用。

```python
# 良い例
from pathlib import Path

project_root = Path(__file__).parent.parent
config_file = project_root / "config" / "settings.json"

if config_file.exists():
    with config_file.open() as f:
        config = json.load(f)

# ディレクトリが存在しない場合は作成
output_dir = project_root / "output"
output_dir.mkdir(parents=True, exist_ok=True)

# globパターン
for py_file in project_root.glob("**/*.py"):
    print(py_file)

# 悪い例
import os

project_root = os.path.dirname(os.path.dirname(__file__))
config_file = os.path.join(project_root, "config", "settings.json")
```

## テスト
pytestで包括的なテストを記述。

```python
# 良い例 - 型ヒント付き最新pytest
import pytest
from unittest.mock import Mock, AsyncMock, patch

def test_user_creation() -> None:
    user = User(id=1, name="Alice", email="alice@example.com")
    assert user.name == "Alice"
    assert user.email == "alice@example.com"

@pytest.fixture
def mock_database() -> Mock:
    db = Mock()
    db.get_user.return_value = {"id": 1, "name": "Alice"}
    return db

def test_get_user_from_db(mock_database: Mock) -> None:
    user = get_user(mock_database, user_id=1)
    assert user["name"] == "Alice"
    mock_database.get_user.assert_called_once_with(1)

# 非同期テスト
@pytest.mark.asyncio
async def test_async_function() -> None:
    mock_api = AsyncMock()
    mock_api.fetch.return_value = {"status": "ok"}
    result = await process_api_call(mock_api)
    assert result["status"] == "ok"

# パラメータ化テスト
@pytest.mark.parametrize("input,expected", [
    (2, 4),
    (3, 9),
    (4, 16),
])
def test_square(input: int, expected: int) -> None:
    assert square(input) == expected
```

## ベストプラクティスチェックリスト

- [ ] すべての関数に型ヒントを使用（Python 3.10+構文）
- [ ] Union型に `|` を使用、`Union[X, Y]` は不使用
- [ ] 組み込みジェネリック（`list`、`dict`）使用、`List`、`Dict`は不使用
- [ ] 複雑な条件にパターンマッチングを使用
- [ ] 構造的サブタイピングにProtocolを使用
- [ ] PEP 8スタイルガイドに従う
- [ ] 仮想環境を使用（venv、poetry、pipenv）
- [ ] requirements.txtまたはpyproject.tomlで依存関係を固定
- [ ] フォーマットにはf文字列を使用
- [ ] os.pathよりpathlibを優先
- [ ] モジュール、クラス、関数にdocstringを記述
- [ ] デバッグにはprintの代わりにloggingを使用
- [ ] 例外を具体的に処理
- [ ] pytestでテストを記述
- [ ] リンターを使用（pylint、flake8、black、mypy）