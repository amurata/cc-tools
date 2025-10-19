# Microservices アーキテクチャ

分散システムとマイクロサービスのパターン。

## サービス設計

### ドメイン境界
```yaml
# サービス分割例
services:
  user-service:
    responsibilities:
      - ユーザー認証
      - プロファイル管理
    database: PostgreSQL
    
  order-service:
    responsibilities:
      - 注文処理
      - 在庫管理
    database: MongoDB
    
  payment-service:
    responsibilities:
      - 決済処理
      - 請求管理
    database: PostgreSQL
```

### API Gateway
```typescript
// API Gateway実装例 (Express)
const gateway = express();

// ルーティング
gateway.use('/api/users', 
  createProxyMiddleware({
    target: 'http://user-service:3001'
  })
);

gateway.use('/api/orders',
  createProxyMiddleware({
    target: 'http://order-service:3002'
  })
);

// 認証
gateway.use(authMiddleware);
```

## サービス間通信

### REST API
```typescript
// サービス間HTTP通信
class OrderService {
  async createOrder(orderData) {
    // ユーザー検証
    const user = await fetch(`http://user-service/users/${orderData.userId}`);
    if (!user.ok) throw new Error('User not found');
    
    // 在庫確認
    const inventory = await fetch(`http://inventory-service/check`, {
      method: 'POST',
      body: JSON.stringify(orderData.items)
    });
    
    // 注文作成
    return await this.orderRepository.create(orderData);
  }
}
```

### メッセージキュー
```typescript
// RabbitMQ/Kafka実装
const amqp = require('amqplib');

// Publisher
async function publishOrder(order) {
  const connection = await amqp.connect('amqp://localhost');
  const channel = await connection.createChannel();
  
  await channel.assertQueue('orders');
  channel.sendToQueue('orders', Buffer.from(JSON.stringify(order)));
}

// Subscriber
async function consumeOrders() {
  const connection = await amqp.connect('amqp://localhost');
  const channel = await connection.createChannel();
  
  await channel.assertQueue('orders');
  channel.consume('orders', (msg) => {
    const order = JSON.parse(msg.content.toString());
    processOrder(order);
    channel.ack(msg);
  });
}
```

## データ管理

### Database per Service
```typescript
// 各サービスが独自のDB
// user-service/db.ts
const userDB = new PrismaClient({
  datasources: { db: { url: process.env.USER_DB_URL } }
});

// order-service/db.ts
const orderDB = new MongoClient(process.env.ORDER_DB_URL);
```

### Saga パターン
```typescript
// 分散トランザクション
class OrderSaga {
  async execute(order) {
    const steps = [
      { service: 'payment', action: 'reserve', compensate: 'cancel' },
      { service: 'inventory', action: 'reserve', compensate: 'release' },
      { service: 'shipping', action: 'schedule', compensate: 'cancel' }
    ];
    
    const executed = [];
    
    try {
      for (const step of steps) {
        await this.executeStep(step, order);
        executed.push(step);
      }
    } catch (error) {
      // ロールバック
      for (const step of executed.reverse()) {
        await this.compensate(step, order);
      }
      throw error;
    }
  }
}
```

## サービスディスカバリー

### Consul/Eureka統合
```typescript
// サービス登録
const consul = require('consul')();

consul.agent.service.register({
  name: 'user-service',
  id: 'user-service-1',
  address: '192.168.1.100',
  port: 3001,
  check: {
    http: 'http://192.168.1.100:3001/health',
    interval: '10s'
  }
});

// サービス発見
async function getService(serviceName) {
  const services = await consul.health.service(serviceName);
  const healthy = services.filter(s => s.Checks.every(c => c.Status === 'passing'));
  return healthy[Math.floor(Math.random() * healthy.length)];
}
```

## レジリエンス

### Circuit Breaker
```typescript
class CircuitBreaker {
  constructor(threshold = 5, timeout = 60000) {
    this.failureCount = 0;
    this.threshold = threshold;
    this.timeout = timeout;
    this.state = 'CLOSED';
    this.nextAttempt = Date.now();
  }
  
  async call(fn) {
    if (this.state === 'OPEN') {
      if (Date.now() < this.nextAttempt) {
        throw new Error('Circuit breaker is OPEN');
      }
      this.state = 'HALF_OPEN';
    }
    
    try {
      const result = await fn();
      this.onSuccess();
      return result;
    } catch (error) {
      this.onFailure();
      throw error;
    }
  }
  
  onSuccess() {
    this.failureCount = 0;
    this.state = 'CLOSED';
  }
  
  onFailure() {
    this.failureCount++;
    if (this.failureCount >= this.threshold) {
      this.state = 'OPEN';
      this.nextAttempt = Date.now() + this.timeout;
    }
  }
}
```

### Retry with Backoff
```typescript
async function retryWithBackoff(fn, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await fn();
    } catch (error) {
      if (i === maxRetries - 1) throw error;
      
      const delay = Math.pow(2, i) * 1000; // Exponential backoff
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }
}
```

## 監視とロギング

### 分散トレーシング
```typescript
// OpenTelemetry
const { trace } = require('@opentelemetry/api');
const tracer = trace.getTracer('order-service');

async function processOrder(order) {
  const span = tracer.startSpan('process-order');
  span.setAttribute('order.id', order.id);
  
  try {
    // 処理
    const result = await orderLogic(order);
    span.setStatus({ code: SpanStatusCode.OK });
    return result;
  } catch (error) {
    span.recordException(error);
    span.setStatus({ code: SpanStatusCode.ERROR });
    throw error;
  } finally {
    span.end();
  }
}
```

## チェックリスト
- [ ] サービス境界明確化
- [ ] API Gateway実装
- [ ] サービス間通信戦略
- [ ] データ一貫性対策
- [ ] サービスディスカバリー
- [ ] 障害対策（Circuit Breaker）
- [ ] 監視・ロギング体制