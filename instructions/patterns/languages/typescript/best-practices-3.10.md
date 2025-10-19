# TypeScript 3.10+ ベストプラクティス

TypeScript 3.10から4.9までの機能を活用した型安全プログラミングパターン。

## 型安全性優先

### Strictモード設定
最大限の型安全性を確保。

```typescript
// tsconfig.json
{
  "compilerOptions": {
    "strict": true,
    "strictNullChecks": true,
    "noImplicitAny": true,
    "strictFunctionTypes": true,
    "strictBindCallApply": true,
    "strictPropertyInitialization": true,
    "noImplicitReturns": true,
    "noImplicitThis": true
  }
}
```

### Interface vs Type
適切な使い分けパターン。

```typescript
// ✅ オブジェクト構造にはinterfaceを優先
interface User {
  id: string;
  email: string;
  profile?: UserProfile;
}

interface UserProfile {
  name: string;
  avatar?: string;
}

// インターフェース拡張
interface AdminUser extends User {
  permissions: string[];
}

// ✅ ユニオン、プリミティブ、計算型にtype使用
type Status = 'pending' | 'active' | 'deleted';
type ID = string | number;
type UserWithStatus = User & { status: Status };
```

## Union型と型ガード（3.10+構文）

### Union型の活用
TypeScript 3.10+で導入された改良されたUnion型。

```typescript
// ✅ Union型での型安全性
type Result<T> = 
  | { success: true; data: T }
  | { success: false; error: string };

function handleResult<T>(result: Result<T>): T | never {
  if (result.success) {
    return result.data; // TypeScriptはdataの存在を認識
  }
  throw new Error(result.error); // TypeScriptはerrorの存在を認識
}

// 判別可能ユニオン
type Shape = 
  | { kind: 'circle'; radius: number }
  | { kind: 'square'; size: number }
  | { kind: 'rectangle'; width: number; height: number };

function getArea(shape: Shape): number {
  switch (shape.kind) {
    case 'circle':
      return Math.PI * shape.radius ** 2;
    case 'square':
      return shape.size ** 2;
    case 'rectangle':
      return shape.width * shape.height;
  }
}
```

### Type Guardパターン
型の絞り込みとランタイム安全性。

```typescript
// ✅ アロー関数によるtype guard
const isString = (value: unknown): value is string => {
  return typeof value === 'string';
};

const isUser = (value: unknown): value is User => {
  return (
    typeof value === 'object' &&
    value !== null &&
    'id' in value &&
    'email' in value &&
    isString((value as any).id) &&
    isString((value as any).email)
  );
};

// 使用例
function processUserData(data: unknown): string {
  if (isUser(data)) {
    return data.email; // 型安全なアクセス
  }
  throw new Error('無効なユーザーデータ');
}

// Assertion Functions（TS 3.7+）
function assertIsUser(value: unknown): asserts value is User {
  if (!isUser(value)) {
    throw new Error('ユーザーデータではありません');
  }
}

function handleUserData(data: unknown): void {
  assertIsUser(data);
  console.log(data.email); // assertionの後は型が確定
}
```

## Generics and Constraints

### ジェネリック制約パターン
柔軟性と型安全性のバランス。

```typescript
// ✅ keyof制約
function getProperty<T, K extends keyof T>(obj: T, key: K): T[K] {
  return obj[key];
}

const user: User = { id: '1', email: 'test@example.com' };
const email = getProperty(user, 'email'); // 型: string

// 条件付き型制約
type NonNullable<T> = T extends null | undefined ? never : T;

function processNonNull<T>(value: NonNullable<T>): T {
  return value;
}

// マップ型の活用
type Partial<T> = {
  [P in keyof T]?: T[P];
};

type Required<T> = {
  [P in keyof T]-?: T[P];
};

type UserUpdate = Partial<User>;
type RequiredUser = Required<User>;
```

### Utility Types
組み込みユーティリティ型の効果的活用。

```typescript
interface User {
  id: string;
  email: string;
  password: string;
  profile: UserProfile;
}

// ✅ 有用なユーティリティ型パターン
type PublicUser = Omit<User, 'password'>;
type UserCredentials = Pick<User, 'email' | 'password'>;
type UserUpdate = Partial<Omit<User, 'id'>>;

// Record型での型安全なマップ
type UserStatus = 'active' | 'inactive' | 'pending';
type StatusConfig = Record<UserStatus, { color: string; label: string }>;

const statusConfig: StatusConfig = {
  active: { color: 'green', label: 'アクティブ' },
  inactive: { color: 'gray', label: '非アクティブ' },
  pending: { color: 'orange', label: '保留中' }
};

// ReturnType, Parameters の活用
function createUser(email: string, name: string): User {
  return { id: generateId(), email, password: '', profile: { name } };
}

type CreateUserParams = Parameters<typeof createUser>; // [string, string]
type UserCreationResult = ReturnType<typeof createUser>; // User
```

## Const Assertions（TS 3.4+）

### リテラル型の保持
const assertionで型を正確に保持。

```typescript
// ✅ const assertion パターン
const config = {
  api: 'https://api.example.com',
  timeout: 5000,
  retries: 3
} as const;

// 型: {
//   readonly api: "https://api.example.com";
//   readonly timeout: 5000;
//   readonly retries: 3;
// }

const colors = ['red', 'green', 'blue'] as const;
type Color = typeof colors[number]; // 'red' | 'green' | 'blue'

// 関数でのconst assertion
function getConfig() {
  return {
    environment: 'production',
    version: '1.0.0'
  } as const;
}

type Config = ReturnType<typeof getConfig>;
// 型: { readonly environment: "production"; readonly version: "1.0.0"; }
```

## Template Literal Types（TS 4.1+）

### 文字列リテラル型の操作
テンプレートリテラル型による型安全な文字列操作。

```typescript
// ✅ Template Literal Types
type HTTPMethod = 'GET' | 'POST' | 'PUT' | 'DELETE';
type APIEndpoint = `/api/${string}`;
type HTTPRequest = `${HTTPMethod} ${APIEndpoint}`;

// 例: 'GET /api/users', 'POST /api/posts' など

// 動的プロパティ名
type EventName = 'click' | 'hover' | 'focus';
type EventHandlers = {
  [K in EventName as `on${Capitalize<K>}`]: (event: Event) => void;
};

// 結果: { onClick: ..., onHover: ..., onFocus: ... }

// CSS-in-JS型安全パターン
type CSSProperty = 'margin' | 'padding' | 'border';
type CSSDirection = 'top' | 'right' | 'bottom' | 'left';
type DirectionalCSS = `${CSSProperty}-${CSSDirection}`;

const styles: Record<DirectionalCSS, string> = {
  'margin-top': '10px',
  'margin-right': '5px',
  // ... 他のプロパティ
} as any; // 簡略化
```

## 関数型パターン

### Arrow Function Priority
アロー関数を優先した関数定義。

```typescript
// ✅ アロー関数パターン
const calculateDiscount = (price: number, rate: number): number => {
  return price * (1 - rate);
};

const asyncFetchUser = async (id: string): Promise<User> => {
  const response = await fetch(`/api/users/${id}`);
  if (!response.ok) {
    throw new Error(`ユーザー${id}の取得に失敗`);
  }
  return response.json();
};

// 高階関数パターン
const withLogging = <T extends any[], R>(
  fn: (...args: T) => R
) => (...args: T): R => {
  console.log(`Calling ${fn.name} with args:`, args);
  const result = fn(...args);
  console.log(`Result:`, result);
  return result;
};

const loggedCalculateDiscount = withLogging(calculateDiscount);
```

## エラーハンドリング

### 型安全なエラー処理
カスタム例外と型ガードの活用。

```typescript
// ✅ 型安全なエラー処理
class ValidationError extends Error {
  constructor(public field: string, message: string) {
    super(message);
    this.name = 'ValidationError';
  }
}

class NetworkError extends Error {
  constructor(public status: number, message: string) {
    super(message);
    this.name = 'NetworkError';
  }
}

// エラー型ガード
const isValidationError = (error: unknown): error is ValidationError => {
  return error instanceof ValidationError;
};

const isNetworkError = (error: unknown): error is NetworkError => {
  return error instanceof NetworkError;
};

// 結果型パターン
type Result<T, E = Error> = 
  | { success: true; data: T }
  | { success: false; error: E };

const safeAsyncOperation = async (id: string): Promise<Result<User>> => {
  try {
    const user = await fetchUser(id);
    return { success: true, data: user };
  } catch (error) {
    return { 
      success: false, 
      error: error instanceof Error ? error : new Error('Unknown error')
    };
  }
};
```

## モジュールパターン

### Named Exports優先（現実的ルール）
原則的にnamed exports、例外的にdefault exports。

```typescript
// ✅ 原則: Named exports
export const UserService = {
  create: (data: UserData): Promise<User> => { /* ... */ },
  update: (id: string, data: Partial<UserData>): Promise<User> => { /* ... */ },
  delete: (id: string): Promise<void> => { /* ... */ }
};

export const validateEmail = (email: string): boolean => {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
};

// ✅ 例外1: メインエントリーポイント（Appコンポーネントなど）
export default class Application {
  constructor(private config: AppConfig) {}
  start(): void { /* ... */ }
}

// ✅ 例外2: 単一責任モジュール
// math-utils.ts
export default function calculate(operation: string, a: number, b: number): number {
  // 単一の主要機能
}

// ✅ Barrel exports パターン
// index.ts
export { UserService } from './UserService';
export { validateEmail, validatePassword } from './validators';
export type { User, UserData } from './types';
```

## TypeScript 3.10-4.9 ベストプラクティスチェックリスト

### 型安全性
- [ ] Strictモード全設定有効化
- [ ] Type assertion完全禁止（type guard使用）
- [ ] `any`型使用禁止（`unknown`使用）
- [ ] インターフェース・type適切使い分け
- [ ] Union型で判別可能パターン使用

### モダン機能
- [ ] Const assertionでリテラル型保持
- [ ] Template literal typesで文字列型操作
- [ ] Utility typesで型変換
- [ ] Conditional typesで柔軟な型定義
- [ ] Mapped typesでオブジェクト型操作

### 関数・モジュール
- [ ] Function宣言禁止（アロー関数使用）
- [ ] Named exports原則、例外的default exports
- [ ] 型ガードでランタイム安全性確保
- [ ] ジェネリック制約で柔軟性と安全性両立

### コード品質
- [ ] すべての関数に型アノテーション
- [ ] エラーに適切な型付け
- [ ] 非同期処理でエラーハンドリング
- [ ] ESLint TypeScript rulesの使用