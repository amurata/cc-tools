# TDD (Test-Driven Development)

テスト駆動開発のパターンと実践。

## Red-Green-Refactor サイクル

### 1. RED - 失敗するテストを書く
```typescript
// まずテストを書く（この時点では実装なし）
describe('PriceCalculator', () => {
  test('calculates total with tax', () => {
    const calculator = new PriceCalculator();
    expect(calculator.calculateTotal(100)).toBe(108);
  });
});
```

### 2. GREEN - 最小限のコードで通す
```typescript
// テストを通す最小限の実装
class PriceCalculator {
  calculateTotal(amount: number): number {
    return 108; // ハードコード OK
  }
}
```

### 3. REFACTOR - リファクタリング
```typescript
// テストが通る状態を維持しながら改善
class PriceCalculator {
  private readonly TAX_RATE = 0.08;
  
  calculateTotal(amount: number): number {
    return amount * (1 + this.TAX_RATE);
  }
}
```

## テストファースト設計

### 仕様をテストで表現
```typescript
describe('UserRegistration', () => {
  let service: UserRegistrationService;
  
  beforeEach(() => {
    service = new UserRegistrationService();
  });
  
  test('registers user with valid data', async () => {
    const userData = {
      email: 'user@example.com',
      password: 'SecurePass123!',
      name: 'John Doe'
    };
    
    const user = await service.register(userData);
    
    expect(user.id).toBeDefined();
    expect(user.email).toBe(userData.email);
    expect(user.createdAt).toBeInstanceOf(Date);
  });
  
  test('rejects registration with invalid email', async () => {
    const userData = {
      email: 'invalid-email',
      password: 'SecurePass123!',
      name: 'John Doe'
    };
    
    await expect(service.register(userData))
      .rejects.toThrow('Invalid email format');
  });
  
  test('rejects weak passwords', async () => {
    const userData = {
      email: 'user@example.com',
      password: '123',
      name: 'John Doe'
    };
    
    await expect(service.register(userData))
      .rejects.toThrow('Password too weak');
  });
});
```

## TDD実践パターン

### Inside-Out TDD
```typescript
// 内部コンポーネントから外側へ
// 1. ドメインロジックのテスト
test('Order calculates subtotal', () => {
  const order = new Order();
  order.addItem({ price: 100, quantity: 2 });
  expect(order.subtotal).toBe(200);
});

// 2. サービス層のテスト
test('OrderService creates order', () => {
  const service = new OrderService();
  const order = service.createOrder(customerId);
  expect(order).toBeDefined();
});

// 3. API層のテスト
test('POST /orders creates new order', async () => {
  const response = await request(app)
    .post('/orders')
    .send({ customerId: '123' });
  expect(response.status).toBe(201);
});
```

### Outside-In TDD
```typescript
// 外側（UI/API）から内側へ
// 1. E2Eテストから開始
test('User completes purchase flow', async () => {
  await page.goto('/products');
  await page.click('[data-testid="add-to-cart"]');
  await page.click('[data-testid="checkout"]');
  await expect(page).toHaveURL('/order-complete');
});

// 2. 必要なAPIのテスト
test('Checkout API processes payment', async () => {
  const response = await request(app)
    .post('/api/checkout')
    .send({ cartId: '123', paymentMethod: 'card' });
  expect(response.body.orderId).toBeDefined();
});

// 3. ドメインロジックのテスト
test('Payment processor charges card', () => {
  const processor = new PaymentProcessor();
  const result = processor.charge(amount, cardToken);
  expect(result.success).toBe(true);
});
```

## テストダブル戦略

### モック・スタブ・スパイ
```typescript
// スタブ: 固定値を返す
const fetchUserStub = jest.fn().mockResolvedValue({
  id: '1',
  name: 'Test User'
});

// モック: 期待される呼び出しを検証
const emailServiceMock = {
  send: jest.fn().mockResolvedValue(true)
};

test('sends notification on order', async () => {
  const service = new OrderService(emailServiceMock);
  await service.placeOrder(orderData);
  
  expect(emailServiceMock.send).toHaveBeenCalledWith(
    expect.objectContaining({
      to: customerEmail,
      subject: expect.stringContaining('Order Confirmation')
    })
  );
});

// スパイ: 実際の実装を監視
const logSpy = jest.spyOn(console, 'log');
processData();
expect(logSpy).toHaveBeenCalledWith('Processing started');
```

## TDD アンチパターン

### 避けるべきパターン
```typescript
// ❌ テスト後の実装
// 実装してからテストを書く（TDDではない）

// ❌ 過度に複雑なテスト
test('everything works', () => {
  // 100行のセットアップ
  // 複数の検証
  // 理解困難
});

// ❌ 実装詳細のテスト
test('uses specific algorithm', () => {
  // 内部実装に依存
  expect(service._privateMethod()).toBe(something);
});

// ✅ 振る舞いをテスト
test('sorts items by price', () => {
  const items = [
    { name: 'B', price: 200 },
    { name: 'A', price: 100 }
  ];
  
  const sorted = sortByPrice(items);
  
  expect(sorted[0].price).toBe(100);
  expect(sorted[1].price).toBe(200);
});
```

## ベストプラクティス

### FIRST原則
- **F**ast: ミリ秒単位で実行
- **I**ndependent: 他のテストに依存しない
- **R**epeatable: 何度でも同じ結果
- **S**elf-Validating: 自動判定
- **T**imely: コードより先に書く

### テスト命名規則
```typescript
// パターン: [対象]_[状況]_[期待結果]
test('calculateDiscount_validCoupon_appliesPercentage', () => {});
test('validateEmail_missingAtSign_throwsError', () => {});
test('fetchUser_networkError_retriesThreeTimes', () => {});
```

## チェックリスト
- [ ] テストを先に書く
- [ ] Red-Green-Refactorサイクル実践
- [ ] 1テスト1アサーション原則
- [ ] テストの独立性確保
- [ ] 振る舞いをテスト（実装詳細ではなく）
- [ ] 明確なテスト名
- [ ] FIRST原則準拠
- [ ] 適切なテストダブル使用