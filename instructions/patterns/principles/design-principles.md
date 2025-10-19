# 設計原則

コード品質と保守性を高める基本設計原則。

## DRY (Don't Repeat Yourself)
知識の重複を避ける。

```typescript
// ✅ 良い: 単一の真実の源
const TAX_RATE = 0.08;
const calculateTax = (amount: number) => amount * TAX_RATE;

// ❌ 悪い: 重複したロジック
const calculateProductTax = (price: number) => price * 0.08;
const calculateServiceTax = (price: number) => price * 0.08;
```

## KISS (Keep It Simple, Stupid)
シンプルさを保つ。

```typescript
// ✅ 良い: シンプルで理解しやすい
const isAdult = (age: number) => age >= 18;

// ❌ 悪い: 過度に複雑
const isAdult = (age: number) => {
  const ADULT_AGE = 18;
  return age >= ADULT_AGE ? true : false;
};
```

## YAGNI (You Aren't Gonna Need It)
必要になるまで実装しない。

```typescript
// ✅ 良い: 現在の要件のみ実装
interface User {
  id: string;
  email: string;
}

// ❌ 悪い: 未使用の将来機能
interface User {
  id: string;
  email: string;
  futureFeature1?: string;  // 未使用
  futureFeature2?: number;  // 未使用
}
```

## 早期リターン
ネストを減らし可読性を向上。

```typescript
// ✅ 良い
function processUser(user: User | null) {
  if (!user) return;
  if (!user.isActive) return;
  if (!user.hasPermission) return;
  
  // メイン処理
  doSomething(user);
}

// ❌ 悪い: 深いネスト
function processUser(user: User | null) {
  if (user) {
    if (user.isActive) {
      if (user.hasPermission) {
        doSomething(user);
      }
    }
  }
}
```

## Composition over Inheritance
継承より合成を優先。

```typescript
// ✅ 良い: 合成
interface Logger { log(msg: string): void; }
interface Validator { validate(data: any): boolean; }

class UserService {
  constructor(
    private logger: Logger,
    private validator: Validator
  ) {}
}

// ❌ 悪い: 深い継承階層
class BaseService { /* ... */ }
class LoggableService extends BaseService { /* ... */ }
class ValidatableService extends LoggableService { /* ... */ }
class UserService extends ValidatableService { /* ... */ }
```

## Separation of Concerns
関心事の分離。

```typescript
// ✅ 良い: 責任が分離
// View層
const UserComponent = ({ user }: Props) => <div>{user.name}</div>;

// ビジネスロジック層
const calculateDiscount = (user: User) => user.isPremium ? 0.2 : 0;

// データ層
const fetchUser = async (id: string) => db.users.findById(id);
```

## チェックリスト
- [ ] 重複コード削除
- [ ] 不要な複雑性排除
- [ ] 未使用機能実装なし
- [ ] 早期リターン活用
- [ ] 合成優先
- [ ] 関心事分離