---
name: architecture-patterns
description: クリーンアーキテクチャ、ヘキサゴナルアーキテクチャ、ドメイン駆動設計を含む実証済みのバックエンドアーキテクチャパターンを実装します。複雑なバックエンドシステムの設計や、保守性向上のための既存アプリケーションのリファクタリング時に使用します。
---

> **[English](../../../../plugins/backend-development/skills/architecture-patterns/SKILL.md)** | **日本語**

# アーキテクチャパターン

保守性、テスト可能性、スケーラビリティに優れたシステムを構築するために、クリーンアーキテクチャ、ヘキサゴナルアーキテクチャ、ドメイン駆動設計などの実証済みバックエンドアーキテクチャパターンをマスターします。

## このスキルを使用するタイミング

- ゼロから新しいバックエンドシステムを設計する場合
- 保守性向上のためにモノリシックアプリケーションをリファクタリングする場合
- チームのアーキテクチャ標準を確立する場合
- 密結合から疎結合アーキテクチャへ移行する場合
- ドメイン駆動設計の原則を実装する場合
- テスト可能でモック可能なコードベースを作成する場合
- マイクロサービス分解を計画する場合

## 中核概念

### 1. クリーンアーキテクチャ（Uncle Bob）

**レイヤー（依存関係は内向きに流れる）:**
- **エンティティ**: コアビジネスモデル
- **ユースケース**: アプリケーションビジネスルール
- **インターフェースアダプター**: コントローラー、プレゼンター、ゲートウェイ
- **フレームワーク＆ドライバー**: UI、データベース、外部サービス

**主要原則:**
- 依存関係は内向きに向く
- 内側のレイヤーは外側のレイヤーについて何も知らない
- ビジネスロジックはフレームワークから独立
- UI、データベース、外部サービスなしでテスト可能

### 2. ヘキサゴナルアーキテクチャ（ポート＆アダプター）

**コンポーネント:**
- **ドメインコア**: ビジネスロジック
- **ポート**: 相互作用を定義するインターフェース
- **アダプター**: ポートの実装（データベース、REST、メッセージキュー）

**利点:**
- 実装を簡単に交換可能（テスト用のモック）
- 技術非依存のコア
- 明確な関心の分離

### 3. ドメイン駆動設計（DDD）

**戦略的パターン:**
- **境界づけられたコンテキスト**: 異なるドメイン用の個別モデル
- **コンテキストマッピング**: コンテキストの関連性
- **ユビキタス言語**: 共通の用語

**戦術的パターン:**
- **エンティティ**: アイデンティティを持つオブジェクト
- **値オブジェクト**: 属性によって定義される不変オブジェクト
- **集約**: 一貫性の境界
- **リポジトリ**: データアクセスの抽象化
- **ドメインイベント**: 発生した出来事

## クリーンアーキテクチャパターン

### ディレクトリ構造
```
app/
├── domain/           # Entities & business rules
│   ├── entities/
│   │   ├── user.py
│   │   └── order.py
│   ├── value_objects/
│   │   ├── email.py
│   │   └── money.py
│   └── interfaces/   # Abstract interfaces
│       ├── user_repository.py
│       └── payment_gateway.py
├── use_cases/        # Application business rules
│   ├── create_user.py
│   ├── process_order.py
│   └── send_notification.py
├── adapters/         # Interface implementations
│   ├── repositories/
│   │   ├── postgres_user_repository.py
│   │   └── redis_cache_repository.py
│   ├── controllers/
│   │   └── user_controller.py
│   └── gateways/
│       ├── stripe_payment_gateway.py
│       └── sendgrid_email_gateway.py
└── infrastructure/   # Framework & external concerns
    ├── database.py
    ├── config.py
    └── logging.py
```

### 実装例

```python
# domain/entities/user.py
from dataclasses import dataclass
from datetime import datetime
from typing import Optional

@dataclass
class User:
    """Core user entity - no framework dependencies."""
    id: str
    email: str
    name: str
    created_at: datetime
    is_active: bool = True

    def deactivate(self):
        """Business rule: deactivating user."""
        self.is_active = False

    def can_place_order(self) -> bool:
        """Business rule: active users can order."""
        return self.is_active

# domain/interfaces/user_repository.py
from abc import ABC, abstractmethod
from typing import Optional, List
from domain.entities.user import User

class IUserRepository(ABC):
    """Port: defines contract, no implementation."""

    @abstractmethod
    async def find_by_id(self, user_id: str) -> Optional[User]:
        pass

    @abstractmethod
    async def find_by_email(self, email: str) -> Optional[User]:
        pass

    @abstractmethod
    async def save(self, user: User) -> User:
        pass

    @abstractmethod
    async def delete(self, user_id: str) -> bool:
        pass

# use_cases/create_user.py
from domain.entities.user import User
from domain.interfaces.user_repository import IUserRepository
from dataclasses import dataclass
from datetime import datetime
import uuid

@dataclass
class CreateUserRequest:
    email: str
    name: str

@dataclass
class CreateUserResponse:
    user: User
    success: bool
    error: Optional[str] = None

class CreateUserUseCase:
    """Use case: orchestrates business logic."""

    def __init__(self, user_repository: IUserRepository):
        self.user_repository = user_repository

    async def execute(self, request: CreateUserRequest) -> CreateUserResponse:
        # Business validation
        existing = await self.user_repository.find_by_email(request.email)
        if existing:
            return CreateUserResponse(
                user=None,
                success=False,
                error="Email already exists"
            )

        # Create entity
        user = User(
            id=str(uuid.uuid4()),
            email=request.email,
            name=request.name,
            created_at=datetime.now(),
            is_active=True
        )

        # Persist
        saved_user = await self.user_repository.save(user)

        return CreateUserResponse(
            user=saved_user,
            success=True
        )

# adapters/repositories/postgres_user_repository.py
from domain.interfaces.user_repository import IUserRepository
from domain.entities.user import User
from typing import Optional
import asyncpg

class PostgresUserRepository(IUserRepository):
    """Adapter: PostgreSQL implementation."""

    def __init__(self, pool: asyncpg.Pool):
        self.pool = pool

    async def find_by_id(self, user_id: str) -> Optional[User]:
        async with self.pool.acquire() as conn:
            row = await conn.fetchrow(
                "SELECT * FROM users WHERE id = $1", user_id
            )
            return self._to_entity(row) if row else None

    async def find_by_email(self, email: str) -> Optional[User]:
        async with self.pool.acquire() as conn:
            row = await conn.fetchrow(
                "SELECT * FROM users WHERE email = $1", email
            )
            return self._to_entity(row) if row else None

    async def save(self, user: User) -> User:
        async with self.pool.acquire() as conn:
            await conn.execute(
                """
                INSERT INTO users (id, email, name, created_at, is_active)
                VALUES ($1, $2, $3, $4, $5)
                ON CONFLICT (id) DO UPDATE
                SET email = $2, name = $3, is_active = $5
                """,
                user.id, user.email, user.name, user.created_at, user.is_active
            )
            return user

    async def delete(self, user_id: str) -> bool:
        async with self.pool.acquire() as conn:
            result = await conn.execute(
                "DELETE FROM users WHERE id = $1", user_id
            )
            return result == "DELETE 1"

    def _to_entity(self, row) -> User:
        """Map database row to entity."""
        return User(
            id=row["id"],
            email=row["email"],
            name=row["name"],
            created_at=row["created_at"],
            is_active=row["is_active"]
        )

# adapters/controllers/user_controller.py
from fastapi import APIRouter, Depends, HTTPException
from use_cases.create_user import CreateUserUseCase, CreateUserRequest
from pydantic import BaseModel

router = APIRouter()

class CreateUserDTO(BaseModel):
    email: str
    name: str

@router.post("/users")
async def create_user(
    dto: CreateUserDTO,
    use_case: CreateUserUseCase = Depends(get_create_user_use_case)
):
    """Controller: handles HTTP concerns only."""
    request = CreateUserRequest(email=dto.email, name=dto.name)
    response = await use_case.execute(request)

    if not response.success:
        raise HTTPException(status_code=400, detail=response.error)

    return {"user": response.user}
```

## ヘキサゴナルアーキテクチャパターン

```python
# Core domain (hexagon center)
class OrderService:
    """Domain service - no infrastructure dependencies."""

    def __init__(
        self,
        order_repository: OrderRepositoryPort,
        payment_gateway: PaymentGatewayPort,
        notification_service: NotificationPort
    ):
        self.orders = order_repository
        self.payments = payment_gateway
        self.notifications = notification_service

    async def place_order(self, order: Order) -> OrderResult:
        # Business logic
        if not order.is_valid():
            return OrderResult(success=False, error="Invalid order")

        # Use ports (interfaces)
        payment = await self.payments.charge(
            amount=order.total,
            customer=order.customer_id
        )

        if not payment.success:
            return OrderResult(success=False, error="Payment failed")

        order.mark_as_paid()
        saved_order = await self.orders.save(order)

        await self.notifications.send(
            to=order.customer_email,
            subject="Order confirmed",
            body=f"Order {order.id} confirmed"
        )

        return OrderResult(success=True, order=saved_order)

# Ports (interfaces)
class OrderRepositoryPort(ABC):
    @abstractmethod
    async def save(self, order: Order) -> Order:
        pass

class PaymentGatewayPort(ABC):
    @abstractmethod
    async def charge(self, amount: Money, customer: str) -> PaymentResult:
        pass

class NotificationPort(ABC):
    @abstractmethod
    async def send(self, to: str, subject: str, body: str):
        pass

# Adapters (implementations)
class StripePaymentAdapter(PaymentGatewayPort):
    """Primary adapter: connects to Stripe API."""

    def __init__(self, api_key: str):
        self.stripe = stripe
        self.stripe.api_key = api_key

    async def charge(self, amount: Money, customer: str) -> PaymentResult:
        try:
            charge = self.stripe.Charge.create(
                amount=amount.cents,
                currency=amount.currency,
                customer=customer
            )
            return PaymentResult(success=True, transaction_id=charge.id)
        except stripe.error.CardError as e:
            return PaymentResult(success=False, error=str(e))

class MockPaymentAdapter(PaymentGatewayPort):
    """Test adapter: no external dependencies."""

    async def charge(self, amount: Money, customer: str) -> PaymentResult:
        return PaymentResult(success=True, transaction_id="mock-123")
```

## ドメイン駆動設計パターン

```python
# Value Objects (immutable)
from dataclasses import dataclass
from typing import Optional

@dataclass(frozen=True)
class Email:
    """Value object: validated email."""
    value: str

    def __post_init__(self):
        if "@" not in self.value:
            raise ValueError("Invalid email")

@dataclass(frozen=True)
class Money:
    """Value object: amount with currency."""
    amount: int  # cents
    currency: str

    def add(self, other: "Money") -> "Money":
        if self.currency != other.currency:
            raise ValueError("Currency mismatch")
        return Money(self.amount + other.amount, self.currency)

# Entities (with identity)
class Order:
    """Entity: has identity, mutable state."""

    def __init__(self, id: str, customer: Customer):
        self.id = id
        self.customer = customer
        self.items: List[OrderItem] = []
        self.status = OrderStatus.PENDING
        self._events: List[DomainEvent] = []

    def add_item(self, product: Product, quantity: int):
        """Business logic in entity."""
        item = OrderItem(product, quantity)
        self.items.append(item)
        self._events.append(ItemAddedEvent(self.id, item))

    def total(self) -> Money:
        """Calculated property."""
        return sum(item.subtotal() for item in self.items)

    def submit(self):
        """State transition with business rules."""
        if not self.items:
            raise ValueError("Cannot submit empty order")
        if self.status != OrderStatus.PENDING:
            raise ValueError("Order already submitted")

        self.status = OrderStatus.SUBMITTED
        self._events.append(OrderSubmittedEvent(self.id))

# Aggregates (consistency boundary)
class Customer:
    """Aggregate root: controls access to entities."""

    def __init__(self, id: str, email: Email):
        self.id = id
        self.email = email
        self._addresses: List[Address] = []
        self._orders: List[str] = []  # Order IDs, not full objects

    def add_address(self, address: Address):
        """Aggregate enforces invariants."""
        if len(self._addresses) >= 5:
            raise ValueError("Maximum 5 addresses allowed")
        self._addresses.append(address)

    @property
    def primary_address(self) -> Optional[Address]:
        return next((a for a in self._addresses if a.is_primary), None)

# Domain Events
@dataclass
class OrderSubmittedEvent:
    order_id: str
    occurred_at: datetime = field(default_factory=datetime.now)

# Repository (aggregate persistence)
class OrderRepository:
    """Repository: persist/retrieve aggregates."""

    async def find_by_id(self, order_id: str) -> Optional[Order]:
        """Reconstitute aggregate from storage."""
        pass

    async def save(self, order: Order):
        """Persist aggregate and publish events."""
        await self._persist(order)
        await self._publish_events(order._events)
        order._events.clear()
```

## リソース

- **references/clean-architecture-guide.md**: 詳細なレイヤー分解
- **references/hexagonal-architecture-guide.md**: ポート＆アダプターパターン
- **references/ddd-tactical-patterns.md**: エンティティ、値オブジェクト、集約
- **assets/clean-architecture-template/**: 完全なプロジェクト構造
- **assets/ddd-examples/**: ドメインモデリング例

## ベストプラクティス

1. **依存関係ルール**: 依存関係は常に内向き
2. **インターフェース分離**: 小さく焦点を絞ったインターフェース
3. **ドメイン内のビジネスロジック**: フレームワークをコアから排除
4. **テストの独立性**: インフラストラクチャなしでコアをテスト可能に
5. **境界づけられたコンテキスト**: 明確なドメイン境界
6. **ユビキタス言語**: 一貫した用語
7. **薄いコントローラー**: ユースケースに委譲
8. **リッチドメインモデル**: データと振る舞いを一緒に

## よくある落とし穴

- **貧血ドメイン**: データのみで振る舞いのないエンティティ
- **フレームワーク結合**: ビジネスロジックがフレームワークに依存
- **肥大したコントローラー**: コントローラー内のビジネスロジック
- **リポジトリ漏洩**: ORMオブジェクトの露出
- **抽象化の欠如**: コア内の具象依存
- **過度な設計**: シンプルなCRUDにクリーンアーキテクチャを適用
