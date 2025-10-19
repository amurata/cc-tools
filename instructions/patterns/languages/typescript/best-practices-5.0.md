# TypeScript 5.0+ ベストプラクティス

TypeScript 5.0以降の最新機能を活用した次世代型安全プログラミングパターン。

## TypeScript 5.0+ 最新機能

### using宣言 - 自動リソース管理
`using`によるリソースの自動クリーンアップ。

```typescript
// ✅ using宣言パターン
class DatabaseConnection implements Disposable {
  private connection: Connection;
  
  constructor(connectionString: string) {
    this.connection = createConnection(connectionString);
  }
  
  [Symbol.dispose](): void {
    this.connection.close();
    console.log('データベース接続を閉じました');
  }
  
  query(sql: string): Promise<any[]> {
    return this.connection.query(sql);
  }
}

// 自動クリーンアップ
async function performDatabaseOperation(): Promise<void> {
  using db = new DatabaseConnection('postgresql://localhost/mydb');
  // スコープ終了時に自動的にdisposeが呼ばれる
  
  const users = await db.query('SELECT * FROM users');
  console.log(users);
} // ここでdb[Symbol.dispose]()が自動実行

// 非同期リソース管理
class AsyncFileHandler implements AsyncDisposable {
  private fileHandle: FileHandle;
  
  constructor(private path: string) {
    this.fileHandle = fs.open(path, 'r');
  }
  
  async [Symbol.asyncDispose](): Promise<void> {
    await this.fileHandle.close();
    console.log(`ファイル${this.path}を閉じました`);
  }
  
  async read(): Promise<string> {
    return (await this.fileHandle).readFile('utf8');
  }
}

async function processFile(): Promise<string> {
  await using file = new AsyncFileHandler('data.txt');
  return file.read();
} // 非同期でリソース解放
```

### satisfies演算子 - 型検証
型を制約しながらリテラル型を保持。

```typescript
// ✅ satisfies演算子パターン
type Config = {
  endpoint: string;
  port: number;
  ssl?: boolean;
  retries?: number;
};

// 型チェックしつつリテラル型保持
const apiConfig = {
  endpoint: 'https://api.example.com',
  port: 443,
  ssl: true,
  retries: 3,
  timeout: 5000 // 追加プロパティも許可
} satisfies Config;

// apiConfig.port は単なるnumberではなく443
// apiConfig.timeout も利用可能

// 複雑な設定オブジェクト
type DatabaseConfig = {
  host: string;
  port: number;
  credentials: {
    username: string;
    password: string;
  };
};

const dbConfig = {
  host: 'localhost',
  port: 5432,
  credentials: {
    username: 'admin',
    password: 'secret'
  },
  pool: { min: 2, max: 10 } // 型にないが許可される
} satisfies DatabaseConfig;

// 関数の戻り値でのsatisfies
function createTheme() {
  return {
    colors: {
      primary: '#007bff',
      secondary: '#6c757d',
      success: '#28a745'
    },
    spacing: {
      sm: '0.5rem',
      md: '1rem',
      lg: '2rem'
    }
  } satisfies {
    colors: Record<string, string>;
    spacing: Record<string, string>;
  };
}

type Theme = ReturnType<typeof createTheme>;
// colors.primary は具体的に '#007bff' 型
```

### const型パラメータ（TS 5.0+）
ジェネリックでconst assertionを適用。

```typescript
// ✅ const型パラメータ
function createConfiguration<const T>(config: T): T {
  return config;
}

// リテラル型が保持される
const appConfig = createConfiguration({
  version: '2.1.0',
  features: ['auth', 'analytics', 'notifications']
});

// appConfig.version の型は '2.1.0'
// appConfig.features の型は readonly ['auth', 'analytics', 'notifications']

// 配列でのconst型パラメータ
function createArray<const T extends readonly unknown[]>(...items: T): T {
  return items;
}

const fruits = createArray('apple', 'banana', 'orange');
// 型: readonly ['apple', 'banana', 'orange']

// オブジェクトファクトリー
function defineRoutes<const T extends Record<string, string>>(routes: T): T {
  return routes;
}

const routes = defineRoutes({
  home: '/',
  about: '/about',
  contact: '/contact'
});

// routes.home の型は '/' （stringではなく）
```

### 拡張されたdecorator（TS 5.0+）
標準化されたデコレータ構文。

```typescript
// ✅ モダンデコレータパターン
function logged<T extends (...args: any[]) => any>(
  target: T,
  context: ClassMethodDecoratorContext
): T {
  return function (this: any, ...args: any[]) {
    console.log(`${String(context.name)}を呼び出し:`, args);
    const result = target.apply(this, args);
    console.log(`${String(context.name)}の結果:`, result);
    return result;
  } as T;
}

function validate(
  target: any,
  context: ClassMethodDecoratorContext
) {
  return function (this: any, ...args: any[]) {
    // バリデーションロジック
    if (args.some(arg => arg == null)) {
      throw new Error(`${String(context.name)}: null/undefined引数は不正`);
    }
    return target.apply(this, args);
  };
}

class UserService {
  @logged
  @validate
  createUser(name: string, email: string): User {
    return { id: generateId(), name, email };
  }
  
  @logged
  updateUser(id: string, updates: Partial<User>): User {
    // 更新ロジック
    return { ...existingUser, ...updates };
  }
}

// クラスデコレータ
function singleton<T extends new (...args: any[]) => any>(target: T): T {
  let instance: InstanceType<T>;
  
  return class extends target {
    constructor(...args: any[]) {
      if (instance) {
        return instance;
      }
      super(...args);
      instance = this;
    }
  } as T;
}

@singleton
class ConfigManager {
  private config: Record<string, any> = {};
  
  setConfig(key: string, value: any): void {
    this.config[key] = value;
  }
}
```

## 高度な型システム機能

### Conditional Types の進歩
より柔軟な条件付き型。

```typescript
// ✅ 高度なConditional Types
type IsArray<T> = T extends (infer U)[] ? true : false;
type ArrayElementType<T> = T extends (infer U)[] ? U : never;

// 関数の引数解析
type Parameters<T> = T extends (...args: infer P) => any ? P : never;
type ReturnType<T> = T extends (...args: any[]) => infer R ? R : never;

// 深いReadonly
type DeepReadonly<T> = {
  readonly [P in keyof T]: T[P] extends object ? DeepReadonly<T[P]> : T[P];
};

// 必須フィールド抽出
type RequiredKeys<T> = {
  [K in keyof T]-?: {} extends Pick<T, K> ? never : K;
}[keyof T];

type OptionalKeys<T> = {
  [K in keyof T]-?: {} extends Pick<T, K> ? K : never;
}[keyof T];

// 使用例
interface User {
  id: string;
  name: string;
  email?: string;
  profile?: UserProfile;
}

type UserRequiredKeys = RequiredKeys<User>; // 'id' | 'name'
type UserOptionalKeys = OptionalKeys<User>; // 'email' | 'profile'
```

### Template Literal Types の拡張
より複雑な文字列型操作。

```typescript
// ✅ 高度なTemplate Literal Types
type CamelCase<S extends string> = S extends `${infer P1}_${infer P2}${infer P3}`
  ? `${P1}${Uppercase<P2>}${CamelCase<P3>}`
  : S;

type SnakeCase<S extends string> = S extends `${infer T}${infer U}`
  ? `${T extends Capitalize<T> ? '_' : ''}${Lowercase<T>}${SnakeCase<U>}`
  : S;

// APIエンドポイント型生成
type HTTPMethod = 'GET' | 'POST' | 'PUT' | 'DELETE';
type ResourceName = 'users' | 'posts' | 'comments';
type APIRoute = `/${ResourceName}` | `/${ResourceName}/${string}`;
type APIEndpoint<M extends HTTPMethod, R extends APIRoute> = `${M} ${R}`;

// 型安全なSQL builder
type SQLTable = 'users' | 'posts' | 'comments';
type SQLColumn<T extends SQLTable> = 
  T extends 'users' ? 'id' | 'name' | 'email' :
  T extends 'posts' ? 'id' | 'title' | 'content' | 'user_id' :
  T extends 'comments' ? 'id' | 'content' | 'post_id' | 'user_id' :
  never;

type SQLQuery<T extends SQLTable> = `SELECT ${SQLColumn<T>} FROM ${T}`;

const query: SQLQuery<'users'> = 'SELECT id FROM users'; // ✅
// const invalid: SQLQuery<'users'> = 'SELECT title FROM users'; // ❌
```

## 関数オーバーロードの進歩

### 高度な関数オーバーロード
型安全で柔軟な関数定義。

```typescript
// ✅ 高度なオーバーロードパターン
interface EventMap {
  click: { x: number; y: number };
  keypress: { key: string };
  change: { value: string };
}

function addEventListener<K extends keyof EventMap>(
  event: K,
  handler: (event: EventMap[K]) => void
): void;
function addEventListener(
  event: string,
  handler: (event: any) => void
): void;
function addEventListener(
  event: string,
  handler: (event: any) => void
): void {
  // 実装
}

// 使用時に型安全
addEventListener('click', (e) => {
  console.log(e.x, e.y); // 型安全
});

addEventListener('keypress', (e) => {
  console.log(e.key); // 型安全
});

// データフェッチャーのオーバーロード
function fetchData(url: string): Promise<unknown>;
function fetchData<T>(url: string, parser: (data: unknown) => T): Promise<T>;
function fetchData<T>(
  url: string, 
  parser?: (data: unknown) => T
): Promise<T | unknown> {
  return fetch(url)
    .then(res => res.json())
    .then(data => parser ? parser(data) : data);
}

// 使用例
const userData = await fetchData('/api/user', (data): User => {
  // パース・バリデーション
  return data as User;
});
```

## エラーハンドリングの進歩

### 型安全な例外処理（TS 5.0+）
より洗練されたエラー処理パターン。

```typescript
// ✅ 型安全なResult型パターン
type Result<T, E = Error> = 
  | { readonly status: 'success'; readonly data: T }
  | { readonly status: 'error'; readonly error: E };

// カスタムエラー型
class ValidationError extends Error {
  constructor(
    public readonly field: string,
    message: string
  ) {
    super(message);
    this.name = 'ValidationError';
  }
}

class NetworkError extends Error {
  constructor(
    public readonly statusCode: number,
    message: string
  ) {
    super(message);
    this.name = 'NetworkError';
  }
}

// 型安全な操作関数
const safeParseJSON = <T>(json: string): Result<T, SyntaxError> => {
  try {
    const data = JSON.parse(json);
    return { status: 'success', data };
  } catch (error) {
    return { 
      status: 'error', 
      error: error instanceof SyntaxError ? error : new SyntaxError('Parse failed')
    };
  }
};

// チェーン可能なResult操作
const mapResult = <T, U, E>(
  result: Result<T, E>,
  fn: (data: T) => U
): Result<U, E> => {
  return result.status === 'success' 
    ? { status: 'success', data: fn(result.data) }
    : result;
};

const flatMapResult = <T, U, E>(
  result: Result<T, E>,
  fn: (data: T) => Result<U, E>
): Result<U, E> => {
  return result.status === 'success' ? fn(result.data) : result;
};

// 使用例
const processUserInput = (input: string): Result<User, ValidationError | SyntaxError> => {
  const parseResult = safeParseJSON<{name: string; email: string}>(input);
  
  return flatMapResult(parseResult, (data) => {
    if (!data.email.includes('@')) {
      return { 
        status: 'error', 
        error: new ValidationError('email', '無効なメール形式') 
      };
    }
    
    return { 
      status: 'success', 
      data: { id: generateId(), ...data } 
    };
  });
};
```

## TypeScript 5.0+ ベストプラクティスチェックリスト

### 最新機能活用
- [ ] リソース管理にusing宣言使用
- [ ] 型制約にsatisfies演算子活用
- [ ] ジェネリックでconst型パラメータ使用
- [ ] 標準デコレータ構文使用
- [ ] 高度なTemplate Literal Types活用

### 型システム
- [ ] Conditional Typesで柔軟な型操作
- [ ] Mapped Typesでオブジェクト変換
- [ ] Function overloadsで型安全API
- [ ] Brand typesで型の区別強化
- [ ] Phantom typesで状態管理

### エラー処理
- [ ] Result型パターンで型安全例外処理
- [ ] カスタムエラークラスで詳細情報
- [ ]型ガードでエラー種別判定
- [ ] チェーン可能な操作で関数型スタイル

### パフォーマンス
- [ ] Tree shakingを意識した型定義
- [ ] Lazy evaluationパターン活用
- [ ] Type-only importsで最適化
- [ ] Const assertionsでコンパイル時最適化

### 互換性
- [ ] TSConfig targeting ES2022+
- [ ] Node.js LTS対応設定
- [ ] Bundler互換性確保
- [ ] 段階的adoption戦略