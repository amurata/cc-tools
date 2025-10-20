---
name: microservices-patterns
description: サービス境界、イベント駆動通信、回復性パターンを用いたマイクロサービスアーキテクチャを設計します。分散システムの構築、モノリスの分解、マイクロサービスの実装時に使用します。
---

> **[English](../../../../plugins/backend-development/skills/microservices-patterns/SKILL.md)** | **日本語**

# マイクロサービスパターン

分散システムを構築するための、サービス境界、サービス間通信、データ管理、回復性パターンを含むマイクロサービスアーキテクチャパターンをマスターします。

## このスキルを使用するタイミング

- モノリスをマイクロサービスに分解する場合
- サービス境界とコントラクトを設計する場合
- サービス間通信を実装する場合
- 分散データとトランザクションを管理する場合
- 回復性のある分散システムを構築する場合
- サービスディスカバリとロードバランシングを実装する場合
- イベント駆動アーキテクチャを設計する場合

## コアコンセプト

### 1. サービス分解戦略

**ビジネス機能による分解**
- ビジネス機能を中心にサービスを編成
- 各サービスがそのドメインを所有
- 例：OrderService、PaymentService、InventoryService

**サブドメインによる分解（DDD）**
- コアドメイン、サポートサブドメイン
- 境界づけられたコンテキストをサービスにマッピング
- 明確な所有権と責任

**Strangler Figパターン**
- モノリスから段階的に抽出
- 新機能をマイクロサービスとして実装
- プロキシが旧/新システムにルーティング

### 2. 通信パターン

**同期（リクエスト/レスポンス）**
- REST API
- gRPC
- GraphQL

**非同期（イベント/メッセージ）**
- イベントストリーミング（Kafka）
- メッセージキュー（RabbitMQ、SQS）
- Pub/Subパターン

### 3. データ管理

**サービスごとのデータベース**
- 各サービスが自身のデータを所有
- データベースの共有なし
- 疎結合

**Sagaパターン**
- 分散トランザクション
- 補償アクション
- 結果整合性

### 4. 回復性パターン

**サーキットブレーカー**
- 繰り返しエラー時に高速で失敗
- カスケード障害を防止

**バックオフ付きリトライ**
- 一時的な障害処理
- 指数バックオフ

**バルクヘッド**
- リソースを分離
- 障害の影響を制限

## サービス分解パターン

### パターン1：ビジネス機能による分解

```python
# E-commerceの例

# Order Service
class OrderService:
    """注文ライフサイクルを処理します。"""

    async def create_order(self, order_data: dict) -> Order:
        order = Order.create(order_data)

        # 他のサービス向けにイベントを公開
        await self.event_bus.publish(
            OrderCreatedEvent(
                order_id=order.id,
                customer_id=order.customer_id,
                items=order.items,
                total=order.total
            )
        )

        return order

# Payment Service（別サービス）
class PaymentService:
    """決済処理を処理します。"""

    async def process_payment(self, payment_request: PaymentRequest) -> PaymentResult:
        # 決済を処理
        result = await self.payment_gateway.charge(
            amount=payment_request.amount,
            customer=payment_request.customer_id
        )

        if result.success:
            await self.event_bus.publish(
                PaymentCompletedEvent(
                    order_id=payment_request.order_id,
                    transaction_id=result.transaction_id
                )
            )

        return result

# Inventory Service（別サービス）
class InventoryService:
    """在庫管理を処理します。"""

    async def reserve_items(self, order_id: str, items: List[OrderItem]) -> ReservationResult:
        # 在庫を確認
        for item in items:
            available = await self.inventory_repo.get_available(item.product_id)
            if available < item.quantity:
                return ReservationResult(
                    success=False,
                    error=f"Insufficient inventory for {item.product_id}"
                )

        # アイテムを予約
        reservation = await self.create_reservation(order_id, items)

        await self.event_bus.publish(
            InventoryReservedEvent(
                order_id=order_id,
                reservation_id=reservation.id
            )
        )

        return ReservationResult(success=True, reservation=reservation)
```

### パターン2：APIゲートウェイ

```python
from fastapi import FastAPI, HTTPException, Depends
import httpx
from circuitbreaker import circuit

app = FastAPI()

class APIGateway:
    """すべてのクライアントリクエストの中央エントリーポイント。"""

    def __init__(self):
        self.order_service_url = "http://order-service:8000"
        self.payment_service_url = "http://payment-service:8001"
        self.inventory_service_url = "http://inventory-service:8002"
        self.http_client = httpx.AsyncClient(timeout=5.0)

    @circuit(failure_threshold=5, recovery_timeout=30)
    async def call_order_service(self, path: str, method: str = "GET", **kwargs):
        """サーキットブレーカー付きで注文サービスを呼び出します。"""
        response = await self.http_client.request(
            method,
            f"{self.order_service_url}{path}",
            **kwargs
        )
        response.raise_for_status()
        return response.json()

    async def create_order_aggregate(self, order_id: str) -> dict:
        """複数のサービスからデータを集約します。"""
        # 並列リクエスト
        order, payment, inventory = await asyncio.gather(
            self.call_order_service(f"/orders/{order_id}"),
            self.call_payment_service(f"/payments/order/{order_id}"),
            self.call_inventory_service(f"/reservations/order/{order_id}"),
            return_exceptions=True
        )

        # 部分的な障害を処理
        result = {"order": order}
        if not isinstance(payment, Exception):
            result["payment"] = payment
        if not isinstance(inventory, Exception):
            result["inventory"] = inventory

        return result

@app.post("/api/orders")
async def create_order(
    order_data: dict,
    gateway: APIGateway = Depends()
):
    """APIゲートウェイエンドポイント。"""
    try:
        # 注文サービスにルーティング
        order = await gateway.call_order_service(
            "/orders",
            method="POST",
            json=order_data
        )
        return {"order": order}
    except httpx.HTTPError as e:
        raise HTTPException(status_code=503, detail="Order service unavailable")
```

## 通信パターン

### パターン1：同期REST通信

```python
# Service AがService Bを呼び出す
import httpx
from tenacity import retry, stop_after_attempt, wait_exponential

class ServiceClient:
    """リトライとタイムアウト付きのHTTPクライアント。"""

    def __init__(self, base_url: str):
        self.base_url = base_url
        self.client = httpx.AsyncClient(
            timeout=httpx.Timeout(5.0, connect=2.0),
            limits=httpx.Limits(max_keepalive_connections=20)
        )

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10)
    )
    async def get(self, path: str, **kwargs):
        """自動リトライ付きのGET。"""
        response = await self.client.get(f"{self.base_url}{path}", **kwargs)
        response.raise_for_status()
        return response.json()

    async def post(self, path: str, **kwargs):
        """POSTリクエスト。"""
        response = await self.client.post(f"{self.base_url}{path}", **kwargs)
        response.raise_for_status()
        return response.json()

# 使用例
payment_client = ServiceClient("http://payment-service:8001")
result = await payment_client.post("/payments", json=payment_data)
```

### パターン2：非同期イベント駆動

```python
# Kafkaを使用したイベント駆動通信
from aiokafka import AIOKafkaProducer, AIOKafkaConsumer
import json
from dataclasses import dataclass, asdict
from datetime import datetime

@dataclass
class DomainEvent:
    event_id: str
    event_type: str
    aggregate_id: str
    occurred_at: datetime
    data: dict

class EventBus:
    """イベントの公開とサブスクリプション。"""

    def __init__(self, bootstrap_servers: List[str]):
        self.bootstrap_servers = bootstrap_servers
        self.producer = None

    async def start(self):
        self.producer = AIOKafkaProducer(
            bootstrap_servers=self.bootstrap_servers,
            value_serializer=lambda v: json.dumps(v).encode()
        )
        await self.producer.start()

    async def publish(self, event: DomainEvent):
        """Kafkaトピックにイベントを公開します。"""
        topic = event.event_type
        await self.producer.send_and_wait(
            topic,
            value=asdict(event),
            key=event.aggregate_id.encode()
        )

    async def subscribe(self, topic: str, handler: callable):
        """イベントをサブスクライブします。"""
        consumer = AIOKafkaConsumer(
            topic,
            bootstrap_servers=self.bootstrap_servers,
            value_deserializer=lambda v: json.loads(v.decode()),
            group_id="my-service"
        )
        await consumer.start()

        try:
            async for message in consumer:
                event_data = message.value
                await handler(event_data)
        finally:
            await consumer.stop()

# Order Serviceがイベントを公開
async def create_order(order_data: dict):
    order = await save_order(order_data)

    event = DomainEvent(
        event_id=str(uuid.uuid4()),
        event_type="OrderCreated",
        aggregate_id=order.id,
        occurred_at=datetime.now(),
        data={
            "order_id": order.id,
            "customer_id": order.customer_id,
            "total": order.total
        }
    )

    await event_bus.publish(event)

# Inventory ServiceがOrderCreatedをリッスン
async def handle_order_created(event_data: dict):
    """注文作成に反応します。"""
    order_id = event_data["data"]["order_id"]
    items = event_data["data"]["items"]

    # 在庫を予約
    await reserve_inventory(order_id, items)
```

### パターン3：Sagaパターン（分散トランザクション）

```python
# 注文フルフィルメントのためのSagaオーケストレーション
from enum import Enum
from typing import List, Callable

class SagaStep:
    """Sagaの単一ステップ。"""

    def __init__(
        self,
        name: str,
        action: Callable,
        compensation: Callable
    ):
        self.name = name
        self.action = action
        self.compensation = compensation

class SagaStatus(Enum):
    PENDING = "pending"
    COMPLETED = "completed"
    COMPENSATING = "compensating"
    FAILED = "failed"

class OrderFulfillmentSaga:
    """注文フルフィルメントのためのオーケストレーション済みSaga。"""

    def __init__(self):
        self.steps: List[SagaStep] = [
            SagaStep(
                "create_order",
                action=self.create_order,
                compensation=self.cancel_order
            ),
            SagaStep(
                "reserve_inventory",
                action=self.reserve_inventory,
                compensation=self.release_inventory
            ),
            SagaStep(
                "process_payment",
                action=self.process_payment,
                compensation=self.refund_payment
            ),
            SagaStep(
                "confirm_order",
                action=self.confirm_order,
                compensation=self.cancel_order_confirmation
            )
        ]

    async def execute(self, order_data: dict) -> SagaResult:
        """Sagaステップを実行します。"""
        completed_steps = []
        context = {"order_data": order_data}

        try:
            for step in self.steps:
                # ステップを実行
                result = await step.action(context)
                if not result.success:
                    # 補償
                    await self.compensate(completed_steps, context)
                    return SagaResult(
                        status=SagaStatus.FAILED,
                        error=result.error
                    )

                completed_steps.append(step)
                context.update(result.data)

            return SagaResult(status=SagaStatus.COMPLETED, data=context)

        except Exception as e:
            # エラー時に補償
            await self.compensate(completed_steps, context)
            return SagaResult(status=SagaStatus.FAILED, error=str(e))

    async def compensate(self, completed_steps: List[SagaStep], context: dict):
        """補償アクションを逆順に実行します。"""
        for step in reversed(completed_steps):
            try:
                await step.compensation(context)
            except Exception as e:
                # 補償失敗をログ記録
                print(f"Compensation failed for {step.name}: {e}")

    # ステップ実装
    async def create_order(self, context: dict) -> StepResult:
        order = await order_service.create(context["order_data"])
        return StepResult(success=True, data={"order_id": order.id})

    async def cancel_order(self, context: dict):
        await order_service.cancel(context["order_id"])

    async def reserve_inventory(self, context: dict) -> StepResult:
        result = await inventory_service.reserve(
            context["order_id"],
            context["order_data"]["items"]
        )
        return StepResult(
            success=result.success,
            data={"reservation_id": result.reservation_id}
        )

    async def release_inventory(self, context: dict):
        await inventory_service.release(context["reservation_id"])

    async def process_payment(self, context: dict) -> StepResult:
        result = await payment_service.charge(
            context["order_id"],
            context["order_data"]["total"]
        )
        return StepResult(
            success=result.success,
            data={"transaction_id": result.transaction_id},
            error=result.error
        )

    async def refund_payment(self, context: dict):
        await payment_service.refund(context["transaction_id"])
```

## 回復性パターン

### サーキットブレーカーパターン

```python
from enum import Enum
from datetime import datetime, timedelta
from typing import Callable, Any

class CircuitState(Enum):
    CLOSED = "closed"  # 通常動作
    OPEN = "open"      # 失敗中、リクエストを拒否
    HALF_OPEN = "half_open"  # 回復をテスト中

class CircuitBreaker:
    """サービス呼び出し用のサーキットブレーカー。"""

    def __init__(
        self,
        failure_threshold: int = 5,
        recovery_timeout: int = 30,
        success_threshold: int = 2
    ):
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.success_threshold = success_threshold

        self.failure_count = 0
        self.success_count = 0
        self.state = CircuitState.CLOSED
        self.opened_at = None

    async def call(self, func: Callable, *args, **kwargs) -> Any:
        """サーキットブレーカー付きで関数を実行します。"""

        if self.state == CircuitState.OPEN:
            if self._should_attempt_reset():
                self.state = CircuitState.HALF_OPEN
            else:
                raise CircuitBreakerOpenError("Circuit breaker is open")

        try:
            result = await func(*args, **kwargs)
            self._on_success()
            return result

        except Exception as e:
            self._on_failure()
            raise

    def _on_success(self):
        """成功した呼び出しを処理します。"""
        self.failure_count = 0

        if self.state == CircuitState.HALF_OPEN:
            self.success_count += 1
            if self.success_count >= self.success_threshold:
                self.state = CircuitState.CLOSED
                self.success_count = 0

    def _on_failure(self):
        """失敗した呼び出しを処理します。"""
        self.failure_count += 1

        if self.failure_count >= self.failure_threshold:
            self.state = CircuitState.OPEN
            self.opened_at = datetime.now()

        if self.state == CircuitState.HALF_OPEN:
            self.state = CircuitState.OPEN
            self.opened_at = datetime.now()

    def _should_attempt_reset(self) -> bool:
        """再試行するのに十分な時間が経過したかをチェックします。"""
        return (
            datetime.now() - self.opened_at
            > timedelta(seconds=self.recovery_timeout)
        )

# 使用例
breaker = CircuitBreaker(failure_threshold=5, recovery_timeout=30)

async def call_payment_service(payment_data: dict):
    return await breaker.call(
        payment_client.process_payment,
        payment_data
    )
```

## リソース

- **references/service-decomposition-guide.md**: モノリスの分解
- **references/communication-patterns.md**: 同期vs非同期パターン
- **references/saga-implementation.md**: 分散トランザクション
- **assets/circuit-breaker.py**: 本番環境用サーキットブレーカー
- **assets/event-bus-template.py**: Kafkaイベントバス実装
- **assets/api-gateway-template.py**: 完全なAPIゲートウェイ

## ベストプラクティス

1. **サービス境界**: ビジネス機能に合わせる
2. **サービスごとのデータベース**: データベースを共有しない
3. **APIコントラクト**: バージョン管理され、後方互換性がある
4. **可能な限り非同期**: 直接呼び出しよりもイベントを使用
5. **サーキットブレーカー**: サービス障害時に高速で失敗
6. **分散トレーシング**: サービス間でリクエストを追跡
7. **サービスレジストリ**: 動的なサービスディスカバリ
8. **ヘルスチェック**: livenessとreadinessプローブ

## よくある落とし穴

- **分散モノリス**: 密結合されたサービス
- **おしゃべりなサービス**: サービス間呼び出しが多すぎる
- **データベースの共有**: データを通じた密結合
- **サーキットブレーカーなし**: カスケード障害
- **すべて同期**: 密結合、回復性の低下
- **時期尚早なマイクロサービス**: マイクロサービスから始める
- **ネットワーク障害の無視**: 信頼性の高いネットワークを想定
- **補償ロジックなし**: 失敗したトランザクションを元に戻せない
