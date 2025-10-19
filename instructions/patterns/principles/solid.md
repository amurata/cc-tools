# SOLID原則

オブジェクト指向設計の5つの基本原則。

## S - Single Responsibility Principle (単一責任の原則)

### 原則
クラスを変更する理由は1つだけであるべき。

### ❌ 悪い例
```typescript
// 複数の責任を持つクラス
class User {
  constructor(
    public name: string,
    public email: string
  ) {}
  
  // 責任1: ユーザー情報管理
  updateEmail(email: string): void {
    this.email = email;
  }
  
  // 責任2: データ永続化
  save(): void {
    const db = Database.connect();
    db.query('UPDATE users SET ...');
  }
  
  // 責任3: メール送信
  sendEmail(message: string): void {
    const mailer = new Mailer();
    mailer.send(this.email, message);
  }
  
  // 責任4: バリデーション
  validateEmail(): boolean {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(this.email);
  }
}
```

### ✅ 良い例
```typescript
// 単一責任に分離
class User {
  constructor(
    public name: string,
    public email: string
  ) {}
  
  updateEmail(email: string): void {
    this.email = email;
  }
}

class UserRepository {
  save(user: User): void {
    const db = Database.connect();
    db.query('UPDATE users SET ...', [user.email, user.name]);
  }
}

class EmailService {
  send(to: string, message: string): void {
    const mailer = new Mailer();
    mailer.send(to, message);
  }
}

class EmailValidator {
  validate(email: string): boolean {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
  }
}
```

## O - Open/Closed Principle (開放閉鎖の原則)

### 原則
拡張に対して開いており、修正に対して閉じているべき。

### ❌ 悪い例
```typescript
class DiscountCalculator {
  calculate(customerType: string, amount: number): number {
    // 新しい顧客タイプを追加するたびに修正が必要
    switch (customerType) {
      case 'regular':
        return amount * 0.95;
      case 'premium':
        return amount * 0.90;
      case 'vip':
        return amount * 0.80;
      default:
        return amount;
    }
  }
}
```

### ✅ 良い例
```typescript
// 抽象化
interface DiscountStrategy {
  calculate(amount: number): number;
}

// 具体的な実装
class RegularDiscount implements DiscountStrategy {
  calculate(amount: number): number {
    return amount * 0.95;
  }
}

class PremiumDiscount implements DiscountStrategy {
  calculate(amount: number): number {
    return amount * 0.90;
  }
}

class VipDiscount implements DiscountStrategy {
  calculate(amount: number): number {
    return amount * 0.80;
  }
}

// 新しい割引タイプの追加（既存コードの修正不要）
class StudentDiscount implements DiscountStrategy {
  calculate(amount: number): number {
    return amount * 0.85;
  }
}

class DiscountCalculator {
  constructor(private strategy: DiscountStrategy) {}
  
  calculate(amount: number): number {
    return this.strategy.calculate(amount);
  }
}
```

## L - Liskov Substitution Principle (リスコフの置換原則)

### 原則
派生クラスは基底クラスと置換可能であるべき。

### ❌ 悪い例
```typescript
class Rectangle {
  constructor(
    protected width: number,
    protected height: number
  ) {}
  
  setWidth(width: number): void {
    this.width = width;
  }
  
  setHeight(height: number): void {
    this.height = height;
  }
  
  getArea(): number {
    return this.width * this.height;
  }
}

// 正方形は幅と高さが同じという制約を破る
class Square extends Rectangle {
  setWidth(width: number): void {
    this.width = width;
    this.height = width; // 高さも変更
  }
  
  setHeight(height: number): void {
    this.width = height; // 幅も変更
    this.height = height;
  }
}

// 置換すると予期しない動作
function testRectangle(rect: Rectangle) {
  rect.setWidth(5);
  rect.setHeight(4);
  console.log(rect.getArea()); // Rectangle: 20, Square: 16 (予期しない)
}
```

### ✅ 良い例
```typescript
// 共通の抽象化
interface Shape {
  getArea(): number;
}

class Rectangle implements Shape {
  constructor(
    private width: number,
    private height: number
  ) {}
  
  getArea(): number {
    return this.width * this.height;
  }
}

class Square implements Shape {
  constructor(private side: number) {}
  
  getArea(): number {
    return this.side * this.side;
  }
}

// 両方のShapeが正しく動作
function calculateArea(shape: Shape): number {
  return shape.getArea();
}
```

## I - Interface Segregation Principle (インターフェース分離の原則)

### 原則
クライアントは使用しないメソッドへの依存を強制されるべきではない。

### ❌ 悪い例
```typescript
// 大きすぎるインターフェース
interface Worker {
  work(): void;
  eat(): void;
  sleep(): void;
  code(): void;
  attendMeeting(): void;
}

class Developer implements Worker {
  work(): void { /* 実装 */ }
  eat(): void { /* 実装 */ }
  sleep(): void { /* 実装 */ }
  code(): void { /* 実装 */ }
  attendMeeting(): void { /* 実装 */ }
}

class Robot implements Worker {
  work(): void { /* 実装 */ }
  eat(): void { 
    throw new Error('Robots do not eat'); // 不要
  }
  sleep(): void { 
    throw new Error('Robots do not sleep'); // 不要
  }
  code(): void { /* 実装 */ }
  attendMeeting(): void { /* 実装 */ }
}
```

### ✅ 良い例
```typescript
// 小さく分離されたインターフェース
interface Workable {
  work(): void;
}

interface Eatable {
  eat(): void;
}

interface Sleepable {
  sleep(): void;
}

interface Codeable {
  code(): void;
}

interface Attendable {
  attendMeeting(): void;
}

class Developer implements Workable, Eatable, Sleepable, Codeable, Attendable {
  work(): void { /* 実装 */ }
  eat(): void { /* 実装 */ }
  sleep(): void { /* 実装 */ }
  code(): void { /* 実装 */ }
  attendMeeting(): void { /* 実装 */ }
}

class Robot implements Workable, Codeable, Attendable {
  work(): void { /* 実装 */ }
  code(): void { /* 実装 */ }
  attendMeeting(): void { /* 実装 */ }
  // eat()とsleep()は不要
}
```

## D - Dependency Inversion Principle (依存性逆転の原則)

### 原則
高レベルモジュールは低レベルモジュールに依存すべきではない。両方とも抽象に依存すべき。

### ❌ 悪い例
```typescript
// 高レベルクラスが低レベルクラスに直接依存
class EmailService {
  send(to: string, message: string): void {
    // SMTP実装
    console.log(`Sending email to ${to}: ${message}`);
  }
}

class UserService {
  private emailService: EmailService;
  
  constructor() {
    this.emailService = new EmailService(); // 直接依存
  }
  
  registerUser(email: string): void {
    // ユーザー登録ロジック
    this.emailService.send(email, 'Welcome!');
  }
}
```

### ✅ 良い例
```typescript
// 抽象に依存
interface MessageService {
  send(to: string, message: string): void;
}

class EmailService implements MessageService {
  send(to: string, message: string): void {
    console.log(`Email to ${to}: ${message}`);
  }
}

class SMSService implements MessageService {
  send(to: string, message: string): void {
    console.log(`SMS to ${to}: ${message}`);
  }
}

class UserService {
  constructor(
    private messageService: MessageService // 抽象に依存
  ) {}
  
  registerUser(contact: string): void {
    // ユーザー登録ロジック
    this.messageService.send(contact, 'Welcome!');
  }
}

// 依存性注入
const emailUserService = new UserService(new EmailService());
const smsUserService = new UserService(new SMSService());
```

## 実践的な適用例

### リファクタリング前
```typescript
class OrderService {
  processOrder(order: Order): void {
    // 複数の責任
    const total = order.items.reduce((sum, item) => sum + item.price, 0);
    
    // 直接的な依存
    const db = new Database();
    db.save(order);
    
    // 大きすぎるインターフェース
    const payment = new PaymentProcessor();
    payment.processCredit(total);
    
    // 具体的な実装への依存
    const email = new EmailSender();
    email.send(order.customerEmail, `Order confirmed: ${order.id}`);
  }
}
```

### リファクタリング後
```typescript
// S: 単一責任
class OrderCalculator {
  calculateTotal(items: OrderItem[]): number {
    return items.reduce((sum, item) => sum + item.price, 0);
  }
}

// I: インターフェース分離
interface PaymentMethod {
  process(amount: number): Promise<PaymentResult>;
}

// D: 依存性逆転
interface NotificationService {
  notify(recipient: string, message: string): Promise<void>;
}

interface OrderRepository {
  save(order: Order): Promise<void>;
}

// O: 開放閉鎖
class OrderService {
  constructor(
    private calculator: OrderCalculator,
    private repository: OrderRepository,
    private paymentMethod: PaymentMethod,
    private notificationService: NotificationService
  ) {}
  
  async processOrder(order: Order): Promise<void> {
    const total = this.calculator.calculateTotal(order.items);
    
    const paymentResult = await this.paymentMethod.process(total);
    if (!paymentResult.success) {
      throw new PaymentFailedError();
    }
    
    await this.repository.save(order);
    await this.notificationService.notify(
      order.customerEmail,
      `Order confirmed: ${order.id}`
    );
  }
}
```

## チェックリスト
- [ ] 各クラスが単一の責任を持つ
- [ ] 新機能追加時に既存コード修正不要
- [ ] 派生クラスが基底クラスと置換可能
- [ ] インターフェースが小さく分離されている
- [ ] 具体実装ではなく抽象に依存
- [ ] 依存性注入を使用
- [ ] テストが容易
- [ ] 変更の影響範囲が限定的