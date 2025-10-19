# Node.jsバックエンドパターン

## プロジェクト構造

### モジュラーアーキテクチャ
ファイルタイプではなく機能別にコードを整理。

```
src/
├── features/
│   ├── auth/
│   │   ├── auth.controller.ts
│   │   ├── auth.service.ts
│   │   ├── auth.middleware.ts
│   │   └── auth.test.ts
│   └── users/
│       ├── user.model.ts
│       ├── user.controller.ts
│       ├── user.service.ts
│       └── user.test.ts
├── shared/
│   ├── database/
│   ├── middleware/
│   └── utils/
└── app.ts
```

## ミドルウェアパターン

### エラーハンドリングミドルウェア
集中エラー処理。

```typescript
// 良い例
class AppError extends Error {
  constructor(
    public statusCode: number,
    public message: string,
    public isOperational = true
  ) {
    super(message);
  }
}

const errorHandler = (err: Error, req: Request, res: Response, next: NextFunction) => {
  if (err instanceof AppError) {
    return res.status(err.statusCode).json({
      status: 'error',
      message: err.message
    });
  }
  
  // 予期しないエラーをログ
  console.error('エラー 💥', err);
  res.status(500).json({
    status: 'error',
    message: '問題が発生しました'
  });
};

// 使用例
app.use(errorHandler);
```

### 非同期ハンドラーラッパー
各ルートでtry-catchを避ける。

```typescript
// 良い例
const asyncHandler = (fn: Function) => (req: Request, res: Response, next: NextFunction) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};

// 使用例
router.get('/users/:id', asyncHandler(async (req, res) => {
  const user = await User.findById(req.params.id);
  if (!user) throw new AppError(404, 'ユーザーが見つかりません');
  res.json(user);
}));

// 悪い例 - 繰り返しのtry-catch
router.get('/users/:id', async (req, res, next) => {
  try {
    const user = await User.findById(req.params.id);
    res.json(user);
  } catch (error) {
    next(error);
  }
});
```

## 認証とセキュリティ

### リフレッシュトークン付きJWT
安全なトークン管理。

```typescript
// 良い例
class AuthService {
  generateTokens(userId: string) {
    const accessToken = jwt.sign(
      { userId },
      process.env.ACCESS_TOKEN_SECRET,
      { expiresIn: '15m' }
    );
    
    const refreshToken = jwt.sign(
      { userId },
      process.env.REFRESH_TOKEN_SECRET,
      { expiresIn: '7d' }
    );
    
    return { accessToken, refreshToken };
  }
  
  async refreshAccessToken(refreshToken: string) {
    const decoded = jwt.verify(refreshToken, process.env.REFRESH_TOKEN_SECRET);
    const tokens = this.generateTokens(decoded.userId);
    
    // 新しいリフレッシュトークンをデータベースに保存
    await RefreshToken.create({
      token: tokens.refreshToken,
      userId: decoded.userId
    });
    
    return tokens;
  }
}
```

### セキュリティヘッダー
helmetを使用してセキュリティヘッダーを設定。

```typescript
// 良い例
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';

app.use(helmet());
app.use(cors({ 
  origin: process.env.ALLOWED_ORIGINS?.split(','),
  credentials: true 
}));

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15分
  max: 100 // 各IPを15分あたり100リクエストに制限
});

app.use('/api', limiter);
```

## データベースパターン

### コネクションプール管理
効率的なデータベース接続。

```typescript
// 良い例 - 単一コネクションプール
import { Pool } from 'pg';

class Database {
  private static pool: Pool;
  
  static getPool(): Pool {
    if (!this.pool) {
      this.pool = new Pool({
        connectionString: process.env.DATABASE_URL,
        max: 20,
        idleTimeoutMillis: 30000,
        connectionTimeoutMillis: 2000,
      });
    }
    return this.pool;
  }
  
  static async query(text: string, params?: any[]) {
    const start = Date.now();
    const res = await this.pool.query(text, params);
    const duration = Date.now() - start;
    console.log('クエリ実行', { text, duration, rows: res.rowCount });
    return res;
  }
}
```

### リポジトリパターン
データベース操作を抽象化。

```typescript
// 良い例
interface Repository<T> {
  findById(id: string): Promise<T | null>;
  findAll(filters?: any): Promise<T[]>;
  create(data: Partial<T>): Promise<T>;
  update(id: string, data: Partial<T>): Promise<T>;
  delete(id: string): Promise<boolean>;
}

class UserRepository implements Repository<User> {
  async findById(id: string): Promise<User | null> {
    const { rows } = await Database.query(
      'SELECT * FROM users WHERE id = $1',
      [id]
    );
    return rows[0] || null;
  }
  
  async create(data: Partial<User>): Promise<User> {
    const { rows } = await Database.query(
      'INSERT INTO users (name, email) VALUES ($1, $2) RETURNING *',
      [data.name, data.email]
    );
    return rows[0];
  }
}
```

## バリデーション

### スキーマバリデーション
入力検証にJoiまたはZodを使用。

```typescript
// 良い例 - Zodバリデーション
import { z } from 'zod';

const createUserSchema = z.object({
  name: z.string().min(2).max(50),
  email: z.string().email(),
  age: z.number().min(18).optional()
});

const validateRequest = (schema: z.ZodSchema) => {
  return (req: Request, res: Response, next: NextFunction) => {
    try {
      schema.parse(req.body);
      next();
    } catch (error) {
      if (error instanceof z.ZodError) {
        res.status(400).json({ errors: error.errors });
      }
    }
  };
};

// 使用例
router.post('/users', 
  validateRequest(createUserSchema),
  asyncHandler(userController.create)
);
```

## ロギング

### 構造化ロギング
本番環境ではWinstonまたはPinoを使用。

```typescript
// 良い例
import winston from 'winston';

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.json(),
  defaultMeta: { service: 'api' },
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' })
  ]
});

if (process.env.NODE_ENV !== 'production') {
  logger.add(new winston.transports.Console({
    format: winston.format.simple()
  }));
}

// リクエストコンテキストと共に使用
app.use((req, res, next) => {
  req.requestId = crypto.randomUUID();
  logger.info('リクエスト受信', {
    requestId: req.requestId,
    method: req.method,
    url: req.url
  });
  next();
});
```

## ベストプラクティスチェックリスト

- [ ] 設定には環境変数を使用
- [ ] グレースフルシャットダウンを実装
- [ ] 圧縮ミドルウェアを使用
- [ ] ヘルスチェックエンドポイントを実装
- [ ] 本番環境ではプロセスマネージャー（PM2）を使用
- [ ] リクエストバリデーションを実装
- [ ] コールバックの代わりにasync/awaitを使用
- [ ] 未処理のプロミス拒否を処理
- [ ] データベースにはコネクションプーリングを使用
- [ ] 適切なロギングを実装
- [ ] レート制限を使用
- [ ] ユーザー入力をサニタイズ