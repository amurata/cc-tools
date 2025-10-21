> **[English](../../../../../plugins/javascript-typescript/skills/typescript-advanced-types/SKILL.md)** | **日本語**

---
name: typescript-advanced-types
description: ジェネリクス、条件型、マップ型、テンプレートリテラル、ユーティリティ型を含むTypeScriptの高度な型システムを習得し、型安全なアプリケーションを構築します。複雑な型ロジックの実装、再利用可能な型ユーティリティの作成、TypeScriptプロジェクトでのコンパイル時型安全性の確保時に使用してください。
---

# TypeScript高度な型

ジェネリクス、条件型、マップ型、テンプレートリテラル型、ユーティリティ型を含むTypeScriptの高度な型システムを習得し、堅牢で型安全なアプリケーションを構築するための包括的なガイダンス。

## このスキルを使用する場面

- 型安全なライブラリやフレームワークの構築
- 再利用可能なジェネリックコンポーネントの作成
- 複雑な型推論ロジックの実装
- 型安全なAPIクライアントの設計
- フォーム検証システムの構築
- 強く型付けされた設定オブジェクトの作成
- 型安全な状態管理の実装
- JavaScriptコードベースのTypeScriptへの移行

## コアコンセプト

### 1. ジェネリクス

**目的:** 型の柔軟性を維持しながら、再利用可能なコンポーネントを作成します。

**基本的なジェネリック関数:**
```typescript
function identity<T>(value: T): T {
  return value;
}

const num = identity<number>(42);        // 型: number
const str = identity<string>("hello");    // 型: string
const auto = identity(true);              // 型推論: boolean
```

**ジェネリック制約:**
```typescript
interface HasLength {
  length: number;
}

function logLength<T extends HasLength>(item: T): T {
  console.log(item.length);
  return item;
}

logLength("hello");           // OK: stringはlengthを持つ
logLength([1, 2, 3]);         // OK: arrayはlengthを持つ
logLength({ length: 10 });    // OK: objectはlengthを持つ
// logLength(42);             // エラー: numberはlengthを持たない
```

**複数の型パラメータ:**
```typescript
function merge<T, U>(obj1: T, obj2: U): T & U {
  return { ...obj1, ...obj2 };
}

const merged = merge(
  { name: "John" },
  { age: 30 }
);
// 型: { name: string } & { age: number }
```

### 2. 条件型

**目的:** 条件に依存する型を作成し、洗練された型ロジックを可能にします。

**基本的な条件型:**
```typescript
type IsString<T> = T extends string ? true : false;

type A = IsString<string>;    // true
type B = IsString<number>;    // false
```

**戻り値型の抽出:**
```typescript
type ReturnType<T> = T extends (...args: any[]) => infer R ? R : never;

function getUser() {
  return { id: 1, name: "John" };
}

type User = ReturnType<typeof getUser>;
// 型: { id: number; name: string; }
```

**分配条件型:**
```typescript
type ToArray<T> = T extends any ? T[] : never;

type StrOrNumArray = ToArray<string | number>;
// 型: string[] | number[]
```

**ネストされた条件:**
```typescript
type TypeName<T> =
  T extends string ? "string" :
  T extends number ? "number" :
  T extends boolean ? "boolean" :
  T extends undefined ? "undefined" :
  T extends Function ? "function" :
  "object";

type T1 = TypeName<string>;     // "string"
type T2 = TypeName<() => void>; // "function"
```

### 3. マップ型

**目的:** プロパティを反復処理して既存の型を変換します。

**基本的なマップ型:**
```typescript
type Readonly<T> = {
  readonly [P in keyof T]: T[P];
};

interface User {
  id: number;
  name: string;
}

type ReadonlyUser = Readonly<User>;
// 型: { readonly id: number; readonly name: string; }
```

**オプショナルプロパティ:**
```typescript
type Partial<T> = {
  [P in keyof T]?: T[P];
};

type PartialUser = Partial<User>;
// 型: { id?: number; name?: string; }
```

**キーの再マッピング:**
```typescript
type Getters<T> = {
  [K in keyof T as `get${Capitalize<string & K>}`]: () => T[K]
};

interface Person {
  name: string;
  age: number;
}

type PersonGetters = Getters<Person>;
// 型: { getName: () => string; getAge: () => number; }
```

**プロパティのフィルタリング:**
```typescript
type PickByType<T, U> = {
  [K in keyof T as T[K] extends U ? K : never]: T[K]
};

interface Mixed {
  id: number;
  name: string;
  age: number;
  active: boolean;
}

type OnlyNumbers = PickByType<Mixed, number>;
// 型: { id: number; age: number; }
```

### 4. テンプレートリテラル型

**目的:** パターンマッチングと変換を使用した文字列ベースの型を作成します。

**基本的なテンプレートリテラル:**
```typescript
type EventName = "click" | "focus" | "blur";
type EventHandler = `on${Capitalize<EventName>}`;
// 型: "onClick" | "onFocus" | "onBlur"
```

**文字列操作:**
```typescript
type UppercaseGreeting = Uppercase<"hello">;  // "HELLO"
type LowercaseGreeting = Lowercase<"HELLO">;  // "hello"
type CapitalizedName = Capitalize<"john">;    // "John"
type UncapitalizedName = Uncapitalize<"John">; // "john"
```

**パスの構築:**
```typescript
type Path<T> = T extends object
  ? { [K in keyof T]: K extends string
      ? `${K}` | `${K}.${Path<T[K]>}`
      : never
    }[keyof T]
  : never;

interface Config {
  server: {
    host: string;
    port: number;
  };
  database: {
    url: string;
  };
}

type ConfigPath = Path<Config>;
// 型: "server" | "database" | "server.host" | "server.port" | "database.url"
```

### 5. ユーティリティ型

**組み込みユーティリティ型:**

```typescript
// Partial<T> - 全てのプロパティをオプショナルに
type PartialUser = Partial<User>;

// Required<T> - 全てのプロパティを必須に
type RequiredUser = Required<PartialUser>;

// Readonly<T> - 全てのプロパティを読み取り専用に
type ReadonlyUser = Readonly<User>;

// Pick<T, K> - 特定のプロパティを選択
type UserName = Pick<User, "name" | "email">;

// Omit<T, K> - 特定のプロパティを削除
type UserWithoutPassword = Omit<User, "password">;

// Exclude<T, U> - ユニオンから型を除外
type T1 = Exclude<"a" | "b" | "c", "a">;  // "b" | "c"

// Extract<T, U> - ユニオンから型を抽出
type T2 = Extract<"a" | "b" | "c", "a" | "b">;  // "a" | "b"

// NonNullable<T> - nullとundefinedを除外
type T3 = NonNullable<string | null | undefined>;  // string

// Record<K, T> - キーKと値Tのオブジェクト型を作成
type PageInfo = Record<"home" | "about", { title: string }>;
```

## 高度なパターン

### パターン1: 型安全なイベントエミッター

```typescript
type EventMap = {
  "user:created": { id: string; name: string };
  "user:updated": { id: string };
  "user:deleted": { id: string };
};

class TypedEventEmitter<T extends Record<string, any>> {
  private listeners: {
    [K in keyof T]?: Array<(data: T[K]) => void>;
  } = {};

  on<K extends keyof T>(event: K, callback: (data: T[K]) => void): void {
    if (!this.listeners[event]) {
      this.listeners[event] = [];
    }
    this.listeners[event]!.push(callback);
  }

  emit<K extends keyof T>(event: K, data: T[K]): void {
    const callbacks = this.listeners[event];
    if (callbacks) {
      callbacks.forEach(callback => callback(data));
    }
  }
}

const emitter = new TypedEventEmitter<EventMap>();

emitter.on("user:created", (data) => {
  console.log(data.id, data.name);  // 型安全！
});

emitter.emit("user:created", { id: "1", name: "John" });
// emitter.emit("user:created", { id: "1" });  // エラー: 'name'が不足
```

### パターン2: 型安全なAPIクライアント

```typescript
type HTTPMethod = "GET" | "POST" | "PUT" | "DELETE";

type EndpointConfig = {
  "/users": {
    GET: { response: User[] };
    POST: { body: { name: string; email: string }; response: User };
  };
  "/users/:id": {
    GET: { params: { id: string }; response: User };
    PUT: { params: { id: string }; body: Partial<User>; response: User };
    DELETE: { params: { id: string }; response: void };
  };
};

type ExtractParams<T> = T extends { params: infer P } ? P : never;
type ExtractBody<T> = T extends { body: infer B } ? B : never;
type ExtractResponse<T> = T extends { response: infer R } ? R : never;

class APIClient<Config extends Record<string, Record<HTTPMethod, any>>> {
  async request<
    Path extends keyof Config,
    Method extends keyof Config[Path]
  >(
    path: Path,
    method: Method,
    ...[options]: ExtractParams<Config[Path][Method]> extends never
      ? ExtractBody<Config[Path][Method]> extends never
        ? []
        : [{ body: ExtractBody<Config[Path][Method]> }]
      : [{
          params: ExtractParams<Config[Path][Method]>;
          body?: ExtractBody<Config[Path][Method]>;
        }]
  ): Promise<ExtractResponse<Config[Path][Method]>> {
    // 実装はここ
    return {} as any;
  }
}

const api = new APIClient<EndpointConfig>();

// 型安全なAPI呼び出し
const users = await api.request("/users", "GET");
// 型: User[]

const newUser = await api.request("/users", "POST", {
  body: { name: "John", email: "john@example.com" }
});
// 型: User

const user = await api.request("/users/:id", "GET", {
  params: { id: "123" }
});
// 型: User
```

### パターン3: 型安全なビルダーパターン

```typescript
type BuilderState<T> = {
  [K in keyof T]: T[K] | undefined;
};

type RequiredKeys<T> = {
  [K in keyof T]-?: {} extends Pick<T, K> ? never : K;
}[keyof T];

type OptionalKeys<T> = {
  [K in keyof T]-?: {} extends Pick<T, K> ? K : never;
}[keyof T];

type IsComplete<T, S> =
  RequiredKeys<T> extends keyof S
    ? S[RequiredKeys<T>] extends undefined
      ? false
      : true
    : false;

class Builder<T, S extends BuilderState<T> = {}> {
  private state: S = {} as S;

  set<K extends keyof T>(
    key: K,
    value: T[K]
  ): Builder<T, S & Record<K, T[K]>> {
    this.state[key] = value;
    return this as any;
  }

  build(
    this: IsComplete<T, S> extends true ? this : never
  ): T {
    return this.state as T;
  }
}

interface User {
  id: string;
  name: string;
  email: string;
  age?: number;
}

const builder = new Builder<User>();

const user = builder
  .set("id", "1")
  .set("name", "John")
  .set("email", "john@example.com")
  .build();  // OK: 全ての必須フィールドが設定された

// const incomplete = builder
//   .set("id", "1")
//   .build();  // エラー: 必須フィールドが不足
```

### パターン4: ディープReadonly/Partial

```typescript
type DeepReadonly<T> = {
  readonly [P in keyof T]: T[P] extends object
    ? T[P] extends Function
      ? T[P]
      : DeepReadonly<T[P]>
    : T[P];
};

type DeepPartial<T> = {
  [P in keyof T]?: T[P] extends object
    ? T[P] extends Array<infer U>
      ? Array<DeepPartial<U>>
      : DeepPartial<T[P]>
    : T[P];
};

interface Config {
  server: {
    host: string;
    port: number;
    ssl: {
      enabled: boolean;
      cert: string;
    };
  };
  database: {
    url: string;
    pool: {
      min: number;
      max: number;
    };
  };
}

type ReadonlyConfig = DeepReadonly<Config>;
// 全てのネストされたプロパティが読み取り専用

type PartialConfig = DeepPartial<Config>;
// 全てのネストされたプロパティがオプショナル
```

### パターン5: 型安全なフォーム検証

```typescript
type ValidationRule<T> = {
  validate: (value: T) => boolean;
  message: string;
};

type FieldValidation<T> = {
  [K in keyof T]?: ValidationRule<T[K]>[];
};

type ValidationErrors<T> = {
  [K in keyof T]?: string[];
};

class FormValidator<T extends Record<string, any>> {
  constructor(private rules: FieldValidation<T>) {}

  validate(data: T): ValidationErrors<T> | null {
    const errors: ValidationErrors<T> = {};
    let hasErrors = false;

    for (const key in this.rules) {
      const fieldRules = this.rules[key];
      const value = data[key];

      if (fieldRules) {
        const fieldErrors: string[] = [];

        for (const rule of fieldRules) {
          if (!rule.validate(value)) {
            fieldErrors.push(rule.message);
          }
        }

        if (fieldErrors.length > 0) {
          errors[key] = fieldErrors;
          hasErrors = true;
        }
      }
    }

    return hasErrors ? errors : null;
  }
}

interface LoginForm {
  email: string;
  password: string;
}

const validator = new FormValidator<LoginForm>({
  email: [
    {
      validate: (v) => v.includes("@"),
      message: "Email must contain @"
    },
    {
      validate: (v) => v.length > 0,
      message: "Email is required"
    }
  ],
  password: [
    {
      validate: (v) => v.length >= 8,
      message: "Password must be at least 8 characters"
    }
  ]
});

const errors = validator.validate({
  email: "invalid",
  password: "short"
});
// 型: { email?: string[]; password?: string[]; } | null
```

### パターン6: 判別可能なユニオン

```typescript
type Success<T> = {
  status: "success";
  data: T;
};

type Error = {
  status: "error";
  error: string;
};

type Loading = {
  status: "loading";
};

type AsyncState<T> = Success<T> | Error | Loading;

function handleState<T>(state: AsyncState<T>): void {
  switch (state.status) {
    case "success":
      console.log(state.data);  // 型: T
      break;
    case "error":
      console.log(state.error);  // 型: string
      break;
    case "loading":
      console.log("Loading...");
      break;
  }
}

// 型安全なステートマシン
type State =
  | { type: "idle" }
  | { type: "fetching"; requestId: string }
  | { type: "success"; data: any }
  | { type: "error"; error: Error };

type Event =
  | { type: "FETCH"; requestId: string }
  | { type: "SUCCESS"; data: any }
  | { type: "ERROR"; error: Error }
  | { type: "RESET" };

function reducer(state: State, event: Event): State {
  switch (state.type) {
    case "idle":
      return event.type === "FETCH"
        ? { type: "fetching", requestId: event.requestId }
        : state;
    case "fetching":
      if (event.type === "SUCCESS") {
        return { type: "success", data: event.data };
      }
      if (event.type === "ERROR") {
        return { type: "error", error: event.error };
      }
      return state;
    case "success":
    case "error":
      return event.type === "RESET" ? { type: "idle" } : state;
  }
}
```

## 型推論テクニック

### 1. inferキーワード

```typescript
// 配列要素の型を抽出
type ElementType<T> = T extends (infer U)[] ? U : never;

type NumArray = number[];
type Num = ElementType<NumArray>;  // number

// Promise型を抽出
type PromiseType<T> = T extends Promise<infer U> ? U : never;

type AsyncNum = PromiseType<Promise<number>>;  // number

// 関数パラメータを抽出
type Parameters<T> = T extends (...args: infer P) => any ? P : never;

function foo(a: string, b: number) {}
type FooParams = Parameters<typeof foo>;  // [string, number]
```

### 2. 型ガード

```typescript
function isString(value: unknown): value is string {
  return typeof value === "string";
}

function isArrayOf<T>(
  value: unknown,
  guard: (item: unknown) => item is T
): value is T[] {
  return Array.isArray(value) && value.every(guard);
}

const data: unknown = ["a", "b", "c"];

if (isArrayOf(data, isString)) {
  data.forEach(s => s.toUpperCase());  // 型: string[]
}
```

### 3. アサーション関数

```typescript
function assertIsString(value: unknown): asserts value is string {
  if (typeof value !== "string") {
    throw new Error("Not a string");
  }
}

function processValue(value: unknown) {
  assertIsString(value);
  // valueは今string型
  console.log(value.toUpperCase());
}
```

## ベストプラクティス

1. **`any`より`unknown`を使用**: 型チェックを強制
2. **オブジェクト形状には`interface`を優先**: より良いエラーメッセージ
3. **ユニオンと複雑な型には`type`を使用**: より柔軟
4. **型推論を活用**: 可能な場合はTypeScriptに推論させる
5. **ヘルパー型を作成**: 再利用可能な型ユーティリティを構築
6. **const assertionを使用**: リテラル型を保持
7. **型アサーションを避ける**: 代わりに型ガードを使用
8. **複雑な型を文書化**: JSDocコメントを追加
9. **strictモードを使用**: 全ての厳格なコンパイラオプションを有効化
10. **型をテスト**: 型テストを使用して型の動作を検証

## 型テスト

```typescript
// 型アサーションテスト
type AssertEqual<T, U> =
  [T] extends [U]
    ? [U] extends [T]
      ? true
      : false
    : false;

type Test1 = AssertEqual<string, string>;        // true
type Test2 = AssertEqual<string, number>;        // false
type Test3 = AssertEqual<string | number, string>; // false

// エラー期待ヘルパー
type ExpectError<T extends never> = T;

// 使用例
type ShouldError = ExpectError<AssertEqual<string, number>>;
```

## よくある落とし穴

1. **`any`の過度な使用**: TypeScriptの目的を無効化
2. **厳格なnullチェックを無視**: ランタイムエラーにつながる可能性
3. **複雑すぎる型**: コンパイルを遅くする可能性
4. **判別可能なユニオンを使用しない**: 型の絞り込みの機会を逃す
5. **readonlyモディファイアを忘れる**: 意図しない変更を許可
6. **循環型参照**: コンパイラエラーを引き起こす可能性
7. **エッジケースを処理しない**: 空の配列やnull値など

## パフォーマンスの考慮事項

- 深くネストされた条件型を避ける
- 可能な場合は単純な型を使用
- 複雑な型計算をキャッシュ
- 再帰型の再帰深度を制限
- ビルドツールを使用して本番環境で型チェックをスキップ

## リソース

- **TypeScript Handbook**: https://www.typescriptlang.org/docs/handbook/
- **Type Challenges**: https://github.com/type-challenges/type-challenges
- **TypeScript Deep Dive**: https://basarat.gitbook.io/typescript/
- **Effective TypeScript**: Dan Vanderkamによる書籍
