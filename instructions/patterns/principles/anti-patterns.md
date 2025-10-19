# アンチパターン

避けるべきコード設計と実装パターン。

## God Object
単一オブジェクトに過剰な責任。

```typescript
// ❌ 悪い: すべてを知っている
class ApplicationManager {
  users: User[];
  products: Product[];
  orders: Order[];
  
  authenticateUser() { /* ... */ }
  processPayment() { /* ... */ }
  sendEmail() { /* ... */ }
  generateReport() { /* ... */ }
  backupDatabase() { /* ... */ }
}

// ✅ 良い: 責任分離
class UserService { /* ... */ }
class PaymentService { /* ... */ }
class EmailService { /* ... */ }
```

## Callback Hell
深くネストしたコールバック。

```typescript
// ❌ 悪い
getData((data) => {
  processData(data, (processed) => {
    saveData(processed, (saved) => {
      notifyUser(saved, (notified) => {
        // 地獄...
      });
    });
  });
});

// ✅ 良い: async/await
const data = await getData();
const processed = await processData(data);
const saved = await saveData(processed);
await notifyUser(saved);
```

## Magic Numbers/Strings
ハードコードされた値。

```typescript
// ❌ 悪い
if (user.age > 17) { /* ... */ }
if (status === "ACTIVE") { /* ... */ }

// ✅ 良い
const MINIMUM_AGE = 18;
enum UserStatus { ACTIVE = "ACTIVE" }

if (user.age >= MINIMUM_AGE) { /* ... */ }
if (status === UserStatus.ACTIVE) { /* ... */ }
```

## Premature Optimization
早すぎる最適化。

```typescript
// ❌ 悪い: 不要な最適化
const cache = new Map();
function simpleCalculation(x: number) {
  if (cache.has(x)) return cache.get(x);
  const result = x * 2;  // 単純計算にキャッシュ不要
  cache.set(x, result);
  return result;
}

// ✅ 良い: まずシンプルに
const simpleCalculation = (x: number) => x * 2;
```

## Copy-Paste Programming
コードの無思考コピー。

```typescript
// ❌ 悪い: 重複コード
const validateEmail = (email: string) => {
  const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return re.test(email);
};

const checkEmail = (email: string) => {
  const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return re.test(email);
};

// ✅ 良い: 再利用
const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const isValidEmail = (email: string) => EMAIL_REGEX.test(email);
```

## Tight Coupling
強い結合。

```typescript
// ❌ 悪い: 具象に依存
class OrderService {
  private emailService = new EmailService();  // 直接依存
  private database = new PostgreSQL();  // 具象クラス
}

// ✅ 良い: 抽象に依存
interface EmailProvider { send(email: Email): Promise<void>; }
interface Database { query(sql: string): Promise<any>; }

class OrderService {
  constructor(
    private emailProvider: EmailProvider,
    private database: Database
  ) {}
}
```

## Spaghetti Code
構造化されていない複雑なコード。

```typescript
// ❌ 悪い: 制御フローが追跡困難
function process(data: any) {
  if (data) {
    if (data.type === 'A') {
      goto labelA;  // 仮想的なgoto
    } else {
      // 処理...
      if (someCondition) {
        // ネスト...
      }
    }
  }
  // labelA: ...
}

// ✅ 良い: 明確な構造
const processTypeA = (data: Data) => { /* ... */ };
const processTypeB = (data: Data) => { /* ... */ };

const process = (data: Data) => {
  if (!data) return;
  
  switch(data.type) {
    case 'A': return processTypeA(data);
    case 'B': return processTypeB(data);
  }
};
```

## Anemic Domain Model
ロジックのないデータコンテナ。

```typescript
// ❌ 悪い: データのみ
class User {
  id: string;
  email: string;
  balance: number;
}

class UserService {
  chargeUser(user: User, amount: number) {
    user.balance -= amount;  // 外部でロジック
  }
}

// ✅ 良い: データとロジックをカプセル化
class User {
  constructor(
    private id: string,
    private email: string,
    private balance: number
  ) {}
  
  charge(amount: number): void {
    if (amount <= 0) throw new Error('Invalid amount');
    if (this.balance < amount) throw new Error('Insufficient funds');
    this.balance -= amount;
  }
}
```

## チェックリスト
- [ ] God Object回避
- [ ] Callback地獄解消
- [ ] マジックナンバー/文字列排除
- [ ] 早すぎる最適化回避
- [ ] コピペプログラミング禁止
- [ ] 疎結合維持
- [ ] スパゲッティコード防止
- [ ] ドメインロジック適切配置