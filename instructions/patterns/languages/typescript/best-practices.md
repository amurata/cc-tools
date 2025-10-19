# TypeScript ベストプラクティス

ES2024+機能を活用した型安全で保守性の高いモダンTypeScriptパターン。

## 型安全性

### strictモード
```typescript
// tsconfig.json
{
  "compilerOptions": {
    "strict": true,
    "strictNullChecks": true,
    "noImplicitAny": true
  }
}
```

### interface vs type
```typescript
// interface: オブジェクト定義・拡張可能
interface User {
  id: string;
  email: string;
}

// type: ユニオン・交差・プリミティブ
type Status = 'pending' | 'active' | 'deleted';
type ID = string | number;
```

## unknown over any

```typescript
// Type guard
const hasValue = (data: unknown): data is { value: string } => {
  return typeof data === 'object' && 
         data !== null && 
         'value' in data &&
         typeof (data as any).value === 'string';
};

const process = (data: unknown): string => {
  if (hasValue(data)) {
    return data.value; // 型安全
  }
  throw new Error('Invalid data');
};
```

## ユーティリティ型

```typescript
interface User {
  id: string;
  email: string;
  password: string;
  createdAt: Date;
}

// 部分型
type UserUpdate = Partial<User>;
type RequiredUser = Required<User>;
type PublicUser = Omit<User, 'password'>;
type UserCredentials = Pick<User, 'email' | 'password'>;
type ReadonlyUser = Readonly<User>;

// 高度な型操作
type AsyncData<T> = {
  data: T | null;
  loading: boolean;
  error: Error | null;
};

type ExtractArrayType<T> = T extends readonly (infer U)[] ? U : never;
```

## ジェネリクス

```typescript
// 基本ジェネリクス
const identity = <T>(value: T): T => value;

// 制約付きジェネリクス
const getProperty = <T, K extends keyof T>(obj: T, key: K): T[K] => obj[key];

// ジェネリッククラス
class DataStore<T extends { id: string }> {
  private items = new Map<string, T>();
  
  add(item: T): void {
    this.items.set(item.id, item);
  }
  
  get(id: string): T | undefined {
    return this.items.get(id);
  }
}
```

## 非同期パターン

```typescript
// 非同期関数の型
type AsyncFunction<T> = () => Promise<T>;

// エラーハンドリング付き非同期
async function safeAsync<T>(
  fn: AsyncFunction<T>
): Promise<[T, null] | [null, Error]> {
  try {
    const data = await fn();
    return [data, null];
  } catch (error) {
    return [null, error as Error];
  }
}

// 使用例
const [data, error] = await safeAsync(async () => {
  return await fetchUser();
});
```

## 型ガード

```typescript
// カスタム型ガード
const isString = (value: unknown): value is string => 
  typeof value === 'string';

const isUser = (value: unknown): value is User => {
  return (
    typeof value === 'object' &&
    value !== null &&
    'id' in value &&
    'email' in value
  );
};

// Discriminated Unions
type Result<T> = 
  | { status: 'success'; data: T }
  | { status: 'error'; error: Error }
  | { status: 'loading' };

const handleResult = <T>(result: Result<T>) => {
  switch (result.status) {
    case 'success':
      return result.data; // T型
    case 'error':
      throw result.error; // Error型
    case 'loading':
      return null;
  }
};
```

## Decorators（Stage 3）

```typescript
// メソッドデコレータ
function debounce(delay: number) {
  return function (target: any, propertyKey: string, descriptor: PropertyDescriptor) {
    const original = descriptor.value;
    let timeout: NodeJS.Timeout;
    
    descriptor.value = function (...args: any[]) {
      clearTimeout(timeout);
      timeout = setTimeout(() => original.apply(this, args), delay);
    };
  };
}

class SearchComponent {
  @debounce(300)
  search(query: string) {
    console.log('Searching:', query);
  }
}
```

## パフォーマンス

### 条件付き型
```typescript
type IsArray<T> = T extends any[] ? true : false;
type UnwrapPromise<T> = T extends Promise<infer U> ? U : T;
```

### Template Literal Types
```typescript
type HTTPMethod = 'GET' | 'POST' | 'PUT' | 'DELETE';
type Endpoint = `/api/${string}`;
type APIRoute = `${HTTPMethod} ${Endpoint}`;
```

## チェックリスト

### 型安全性
- [ ] strict mode 有効
- [ ] any 禁止（unknown 使用）
- [ ] 型アサーション最小限
- [ ] null/undefined 明示的処理

### コード品質
- [ ] ユーティリティ型活用
- [ ] ジェネリクス適切使用
- [ ] 型ガード実装
- [ ] エラー型定義

### パフォーマンス
- [ ] 不要な型計算回避
- [ ] 条件付き型適切使用
- [ ] バンドルサイズ考慮