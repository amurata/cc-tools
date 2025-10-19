# Python Type Hints Patterns

Python型ヒントの実装パターンとベストプラクティス。

## 基本的な型ヒント

### 基本型とコレクション
```python
from typing import List, Dict, Set, Tuple, Optional, Union, Any
from typing import Sequence, Mapping, Iterable, Collection
from collections.abc import Callable, Iterator, Generator

# 基本的な型注釈
name: str = "Alice"
age: int = 30
height: float = 165.5
is_active: bool = True

# コレクション型
numbers: List[int] = [1, 2, 3, 4, 5]
user_scores: Dict[str, int] = {"Alice": 100, "Bob": 85}
unique_ids: Set[str] = {"id1", "id2", "id3"}
coordinates: Tuple[float, float] = (10.5, 20.3)

# Optional（None許容）
middle_name: Optional[str] = None  # str | None と同じ
user_id: int | None = None  # Python 3.10+

# Union（複数の型）
identifier: Union[int, str] = "ABC123"  # int | str と同じ
value: int | str | float = 42  # Python 3.10+

# 関数の型注釈
def greet(name: str, age: int = 0) -> str:
    return f"Hello, {name}! You are {age} years old."

# 高階関数
def apply_operation(
    numbers: List[float],
    operation: Callable[[float], float]
) -> List[float]:
    return [operation(n) for n in numbers]

# ジェネレーター
def count_up_to(n: int) -> Generator[int, None, None]:
    for i in range(n):
        yield i
```

### 型エイリアス
```python
from typing import TypeAlias, NewType

# 型エイリアス
UserId: TypeAlias = int
UserName: TypeAlias = str
UserData: TypeAlias = Dict[str, Any]

# NewType（より厳密な型）
CustomerId = NewType('CustomerId', int)
OrderId = NewType('OrderId', int)

def process_order(customer_id: CustomerId, order_id: OrderId) -> bool:
    # customer_idとorder_idは意味的に異なる
    return True

# 使用例
customer = CustomerId(123)  # 明示的な変換が必要
order = OrderId(456)
# process_order(order, customer)  # 型エラー：引数の順序が間違っている
```

## ジェネリック型

### TypeVarとGeneric
```python
from typing import TypeVar, Generic, List, Optional
from dataclasses import dataclass

T = TypeVar('T')
K = TypeVar('K')
V = TypeVar('V')

# ジェネリック関数
def first_or_none(items: List[T]) -> Optional[T]:
    return items[0] if items else None

def swap(pair: Tuple[T, K]) -> Tuple[K, T]:
    return pair[1], pair[0]

# ジェネリッククラス
class Stack(Generic[T]):
    def __init__(self) -> None:
        self._items: List[T] = []
    
    def push(self, item: T) -> None:
        self._items.append(item)
    
    def pop(self) -> T:
        if not self._items:
            raise IndexError("Stack is empty")
        return self._items.pop()
    
    def peek(self) -> Optional[T]:
        return self._items[-1] if self._items else None
    
    def is_empty(self) -> bool:
        return len(self._items) == 0

# 制約付きTypeVar
Comparable = TypeVar('Comparable', int, float, str)

def find_max(items: List[Comparable]) -> Optional[Comparable]:
    if not items:
        return None
    return max(items)

# 共変性と反変性
T_co = TypeVar('T_co', covariant=True)
T_contra = TypeVar('T_contra', contravariant=True)

class Producer(Generic[T_co]):
    def produce(self) -> T_co:
        ...

class Consumer(Generic[T_contra]):
    def consume(self, item: T_contra) -> None:
        ...
```

## プロトコルとABC

### Protocol（構造的部分型）
```python
from typing import Protocol, runtime_checkable
from abc import ABC, abstractmethod

@runtime_checkable
class Drawable(Protocol):
    """描画可能なオブジェクトのプロトコル"""
    def draw(self) -> None: ...

@runtime_checkable  
class Comparable(Protocol):
    """比較可能なオブジェクトのプロトコル"""
    def __lt__(self, other: Any) -> bool: ...
    def __le__(self, other: Any) -> bool: ...
    def __gt__(self, other: Any) -> bool: ...
    def __ge__(self, other: Any) -> bool: ...

class Shape:
    def draw(self) -> None:
        print("Drawing shape")

class Circle(Shape):
    def draw(self) -> None:
        print("Drawing circle")

def render(drawable: Drawable) -> None:
    drawable.draw()

# ShapeもCircleもDrawableプロトコルを満たす
render(Shape())  # OK
render(Circle())  # OK

# ランタイムチェック
assert isinstance(Circle(), Drawable)  # True
```

### 抽象基底クラス
```python
from abc import ABC, abstractmethod
from typing import List, Optional

class Repository(ABC, Generic[T]):
    """リポジトリの抽象基底クラス"""
    
    @abstractmethod
    async def find_by_id(self, id: str) -> Optional[T]:
        """IDでエンティティを検索"""
        ...
    
    @abstractmethod
    async def find_all(self) -> List[T]:
        """全エンティティを取得"""
        ...
    
    @abstractmethod
    async def save(self, entity: T) -> T:
        """エンティティを保存"""
        ...
    
    @abstractmethod
    async def delete(self, id: str) -> bool:
        """エンティティを削除"""
        ...

@dataclass
class User:
    id: str
    name: str
    email: str

class UserRepository(Repository[User]):
    async def find_by_id(self, id: str) -> Optional[User]:
        # 実装
        pass
    
    async def find_all(self) -> List[User]:
        # 実装
        pass
    
    async def save(self, entity: User) -> User:
        # 実装
        pass
    
    async def delete(self, id: str) -> bool:
        # 実装
        pass
```

## リテラル型とTypedDict

### Literal型
```python
from typing import Literal, overload

LogLevel = Literal["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"]
HttpMethod = Literal["GET", "POST", "PUT", "DELETE", "PATCH"]

def log(message: str, level: LogLevel = "INFO") -> None:
    print(f"[{level}] {message}")

# オーバーロード
@overload
def process_value(value: Literal[True]) -> str: ...

@overload
def process_value(value: Literal[False]) -> int: ...

@overload
def process_value(value: bool) -> str | int: ...

def process_value(value: bool) -> str | int:
    if value:
        return "true"
    else:
        return 0
```

### TypedDict
```python
from typing import TypedDict, NotRequired, Required
from typing_extensions import NotRequired  # Python < 3.11

class UserDict(TypedDict):
    """ユーザー辞書の型定義"""
    id: int
    name: str
    email: str
    age: NotRequired[int]  # オプショナルフィールド

class ConfigDict(TypedDict, total=False):
    """設定辞書（全フィールドオプショナル）"""
    debug: bool
    timeout: int
    max_retries: int

class StrictUserDict(TypedDict):
    """厳密なユーザー辞書"""
    id: Required[int]  # 必須フィールド
    name: Required[str]
    email: str
    metadata: NotRequired[Dict[str, Any]]

# 使用例
def create_user(data: UserDict) -> User:
    return User(
        id=data["id"],
        name=data["name"],
        email=data["email"],
        age=data.get("age", 0)
    )

user_data: UserDict = {
    "id": 1,
    "name": "Alice",
    "email": "alice@example.com"
    # ageは省略可能
}
```

## 高度な型パターン

### 型ガード
```python
from typing import TypeGuard, Any

def is_string_list(val: List[Any]) -> TypeGuard[List[str]]:
    """リストの全要素が文字列かチェック"""
    return all(isinstance(x, str) for x in val)

def is_not_none(val: Optional[T]) -> TypeGuard[T]:
    """None除外の型ガード"""
    return val is not None

def process_items(items: List[Any]) -> None:
    if is_string_list(items):
        # ここではitemsはList[str]として扱われる
        for item in items:
            print(item.upper())
    else:
        print("Not all items are strings")

# フィルタリングでの使用
values: List[Optional[int]] = [1, None, 2, None, 3]
filtered: List[int] = [v for v in values if is_not_none(v)]
```

### ParamSpec と Concatenate
```python
from typing import ParamSpec, Concatenate, TypeVar, Callable
import functools

P = ParamSpec('P')
R = TypeVar('R')

def with_logging(func: Callable[P, R]) -> Callable[P, R]:
    """関数の実行をログに記録するデコレーター"""
    @functools.wraps(func)
    def wrapper(*args: P.args, **kwargs: P.kwargs) -> R:
        print(f"Calling {func.__name__}")
        result = func(*args, **kwargs)
        print(f"Result: {result}")
        return result
    return wrapper

def with_retry(
    func: Callable[Concatenate[int, P], R]
) -> Callable[Concatenate[int, P], R]:
    """最初の引数をリトライ回数として扱うデコレーター"""
    @functools.wraps(func)
    def wrapper(retries: int, *args: P.args, **kwargs: P.kwargs) -> R:
        for i in range(retries):
            try:
                return func(retries, *args, **kwargs)
            except Exception as e:
                if i == retries - 1:
                    raise
                print(f"Retry {i + 1}/{retries}")
        raise Exception("Should not reach here")
    return wrapper
```

## データクラスと型

### 型安全なデータクラス
```python
from dataclasses import dataclass, field
from datetime import datetime
from typing import ClassVar, Final

@dataclass
class Product:
    """商品データクラス"""
    id: int
    name: str
    price: float
    tags: List[str] = field(default_factory=list)
    created_at: datetime = field(default_factory=datetime.now)
    
    # クラス変数
    TAX_RATE: ClassVar[float] = 0.1
    
    # 定数
    MAX_NAME_LENGTH: Final[int] = 100
    
    def __post_init__(self) -> None:
        """初期化後の処理"""
        if len(self.name) > self.MAX_NAME_LENGTH:
            raise ValueError(f"Name too long: {len(self.name)}")
        if self.price < 0:
            raise ValueError(f"Price cannot be negative: {self.price}")
    
    @property
    def price_with_tax(self) -> float:
        return self.price * (1 + self.TAX_RATE)
    
    def add_tag(self, tag: str) -> None:
        if tag not in self.tags:
            self.tags.append(tag)

@dataclass(frozen=True)
class ImmutablePoint:
    """不変のポイントクラス"""
    x: float
    y: float
    
    def distance_from_origin(self) -> float:
        return (self.x ** 2 + self.y ** 2) ** 0.5
```

## Mypyとの統合

### mypy設定
```ini
# mypy.ini
[mypy]
python_version = 3.11
warn_return_any = True
warn_unused_configs = True
disallow_untyped_defs = True
disallow_any_unimported = True
no_implicit_optional = True
check_untyped_defs = True
warn_redundant_casts = True
warn_unused_ignores = True
warn_no_return = True
warn_unreachable = True
strict_equality = True

[mypy-tests.*]
ignore_errors = True

[mypy-external_library.*]
ignore_missing_imports = True
```

### 型チェックの回避
```python
from typing import cast, TYPE_CHECKING

# 循環インポート回避
if TYPE_CHECKING:
    from .models import User

# 型キャスト
def get_user_id(user: Any) -> int:
    # 型チェッカーに型を伝える
    return cast(int, user.id)

# 型無視
result = some_untyped_function()  # type: ignore[no-untyped-call]

# 動的な属性アクセス
from typing import Any

class DynamicClass:
    def __getattr__(self, name: str) -> Any:
        return getattr(self._data, name)
```

## チェックリスト
- [ ] 全関数に型ヒント追加
- [ ] 戻り値の型明記
- [ ] Optionalの適切な使用
- [ ] ジェネリック型の活用
- [ ] Protocolでの構造的型付け
- [ ] TypedDictでの辞書型定義
- [ ] 型エイリアスで可読性向上
- [ ] mypy設定と実行
- [ ] 型ガードの実装