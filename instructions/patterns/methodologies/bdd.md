# BDD (Behavior-Driven Development)

ビヘイビア駆動開発のパターンと実践。

## Given-When-Then パターン

### 基本構造
```typescript
describe('Shopping Cart Feature', () => {
  test('adds product to cart', () => {
    // Given: 前提条件
    const cart = new ShoppingCart();
    const product = new Product('iPhone', 999);
    
    // When: アクション実行
    cart.addProduct(product);
    
    // Then: 期待結果
    expect(cart.itemCount).toBe(1);
    expect(cart.totalPrice).toBe(999);
  });
});
```

### 複数の前提条件
```typescript
describe('Discount calculation', () => {
  test('applies bulk discount for large orders', () => {
    // Given: 複数の前提条件
    const cart = new ShoppingCart();
    const customer = new Customer({ tier: 'premium' });
    const products = [
      new Product('Item1', 100),
      new Product('Item2', 100),
      new Product('Item3', 100)
    ];
    products.forEach(p => cart.addProduct(p));
    
    // When: 割引計算
    const discount = cart.calculateDiscount(customer);
    
    // Then: 期待される割引
    expect(discount.percentage).toBe(15);
    expect(discount.amount).toBe(45);
  });
});
```

## ユーザーストーリー駆動

### ストーリー形式
```typescript
// As a [role]
// I want [feature]
// So that [benefit]

describe('As a customer', () => {
  describe('I want to search products', () => {
    test('so that I can find items quickly', () => {
      const catalog = new ProductCatalog();
      const results = catalog.search('laptop');
      
      expect(results).toHaveLength(5);
      expect(results[0].name).toContain('laptop');
    });
  });
  
  describe('I want to save items for later', () => {
    test('so that I can purchase them when ready', () => {
      const wishlist = new Wishlist();
      const product = new Product('Gaming Chair', 299);
      
      wishlist.add(product);
      
      expect(wishlist.items).toContain(product);
      expect(wishlist.savedAt).toBeInstanceOf(Date);
    });
  });
});
```

## Cucumber/Gherkin 形式

### Feature ファイル
```gherkin
Feature: User Authentication
  As a user
  I want to log in to my account
  So that I can access my personal data

  Scenario: Successful login with valid credentials
    Given I am on the login page
    When I enter "user@example.com" as email
    And I enter "ValidPass123!" as password
    And I click the login button
    Then I should be redirected to the dashboard
    And I should see "Welcome back!" message

  Scenario: Failed login with invalid password
    Given I am on the login page
    When I enter "user@example.com" as email
    And I enter "wrongpassword" as password
    And I click the login button
    Then I should remain on the login page
    And I should see "Invalid credentials" error
```

### Step Definitions
```typescript
import { Given, When, Then } from '@cucumber/cucumber';

Given('I am on the login page', async () => {
  await page.goto('/login');
});

When('I enter {string} as email', async (email: string) => {
  await page.fill('[data-testid="email-input"]', email);
});

When('I enter {string} as password', async (password: string) => {
  await page.fill('[data-testid="password-input"]', password);
});

When('I click the login button', async () => {
  await page.click('[data-testid="login-button"]');
});

Then('I should be redirected to the dashboard', async () => {
  await expect(page).toHaveURL('/dashboard');
});

Then('I should see {string} message', async (message: string) => {
  await expect(page.locator('.message')).toContainText(message);
});
```

## シナリオアウトライン

### データ駆動テスト
```gherkin
Scenario Outline: Product pricing with different quantities
  Given a product costs $<unit_price>
  When I add <quantity> items to cart
  Then the total should be $<total>
  
  Examples:
    | unit_price | quantity | total |
    | 10         | 1        | 10    |
    | 10         | 5        | 50    |
    | 10         | 10       | 90    |  # bulk discount
```

### TypeScript実装
```typescript
describe('Product pricing scenarios', () => {
  const testCases = [
    { unitPrice: 10, quantity: 1, total: 10 },
    { unitPrice: 10, quantity: 5, total: 50 },
    { unitPrice: 10, quantity: 10, total: 90 } // bulk discount
  ];
  
  testCases.forEach(({ unitPrice, quantity, total }) => {
    test(`${quantity} items @ $${unitPrice} = $${total}`, () => {
      const cart = new Cart();
      const product = new Product('Item', unitPrice);
      
      for (let i = 0; i < quantity; i++) {
        cart.add(product);
      }
      
      expect(cart.calculateTotal()).toBe(total);
    });
  });
});
```

## 実行可能な仕様書

### Living Documentation
```typescript
describe('Order Processing System', () => {
  describe('Order States', () => {
    test('new orders start in PENDING state', () => {
      const order = new Order();
      expect(order.state).toBe('PENDING');
    });
    
    test('confirmed orders move to PROCESSING', () => {
      const order = new Order();
      order.confirm();
      expect(order.state).toBe('PROCESSING');
    });
    
    test('shipped orders cannot be cancelled', () => {
      const order = new Order();
      order.confirm();
      order.ship();
      
      expect(() => order.cancel()).toThrow('Cannot cancel shipped order');
    });
  });
  
  describe('Payment Rules', () => {
    test('requires payment before shipping', () => {
      const order = new Order();
      
      expect(() => order.ship()).toThrow('Payment required');
    });
    
    test('refunds only for cancelled orders', () => {
      const order = new Order();
      order.pay(100);
      order.cancel();
      
      const refund = order.processRefund();
      expect(refund.amount).toBe(100);
    });
  });
});
```

## BDD アンチパターン

### 避けるべきパターン
```typescript
// ❌ 技術的な記述
test('database returns user object', () => {
  // DBの実装詳細
});

// ✅ ビジネス価値の記述
test('registered users can sign in', () => {
  // ユーザー視点の振る舞い
});

// ❌ 実装に依存したテスト
test('calls calculateTax() method', () => {
  // メソッド呼び出しの確認
});

// ✅ 振る舞いをテスト
test('applies correct tax rate to order', () => {
  // 結果の確認
});
```

## コラボレーション

### Three Amigos
```typescript
// 1. Business (PO): 要件定義
// "割引は会員ランクによって変わる"

// 2. Development: 技術的実現
const calculateMemberDiscount = (tier: string): number => {
  const discounts = { bronze: 5, silver: 10, gold: 15 };
  return discounts[tier] || 0;
};

// 3. Testing (QA): 検証シナリオ
describe('Member discount scenarios', () => {
  test.each([
    ['bronze', 5],
    ['silver', 10],
    ['gold', 15],
    ['none', 0]
  ])('%s member gets %i% discount', (tier, expected) => {
    expect(calculateMemberDiscount(tier)).toBe(expected);
  });
});
```

## ベストプラクティス

### 明確な言語
```typescript
// Domain-specific language
class OrderBuilder {
  givenCustomerIs(type: string) { /* ... */ }
  whenPlacesOrderFor(product: string) { /* ... */ }
  thenTotalShouldBe(amount: number) { /* ... */ }
}

// 読みやすいテスト
new OrderBuilder()
  .givenCustomerIs('premium')
  .whenPlacesOrderFor('laptop')
  .thenTotalShouldBe(950); // with discount
```

## チェックリスト
- [ ] Given-When-Then形式で記述
- [ ] ユーザーストーリーから開始
- [ ] ビジネス言語で表現
- [ ] 実行可能な仕様書として機能
- [ ] ステークホルダーが理解可能
- [ ] シナリオが独立して実行可能
- [ ] Three Amigosで協議
- [ ] Living Documentation維持