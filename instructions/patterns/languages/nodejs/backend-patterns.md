# Node.js Backend Patterns

モダンNode.jsバックエンド開発のパターンとベストプラクティス。

## アプリケーション構造

### レイヤードアーキテクチャ
```
src/
├── controllers/     # リクエスト処理
├── services/       # ビジネスロジック
├── repositories/   # データアクセス
├── models/         # データモデル
├── middlewares/    # ミドルウェア
├── utils/          # ユーティリティ
└── config/         # 設定
```

### 依存性注入
```typescript
// services/userService.ts
export class UserService {
  constructor(
    private userRepository: UserRepository,
    private emailService: EmailService,
    private cacheService: CacheService
  ) {}
  
  async createUser(data: CreateUserDto): Promise<User> {
    const user = await this.userRepository.create(data);
    await this.emailService.sendWelcome(user.email);
    await this.cacheService.set(`user:${user.id}`, user);
    return user;
  }
}

// DI Container設定
import { Container } from 'inversify';

const container = new Container();
container.bind(UserService).toSelf();
container.bind(UserRepository).toSelf();
container.bind(EmailService).toSelf();
```

## 非同期処理パターン

### Promise Chain vs Async/Await
```typescript
// ✅ Async/Await（推奨）
async function processOrder(orderId: string): Promise<Order> {
  try {
    const order = await fetchOrder(orderId);
    const payment = await processPayment(order);
    const shipment = await createShipment(order);
    
    return { ...order, payment, shipment };
  } catch (error) {
    logger.error('Order processing failed', { orderId, error });
    throw new OrderProcessingError(error.message);
  }
}

// 並列処理
async function fetchUserData(userId: string) {
  const [profile, posts, followers] = await Promise.all([
    fetchProfile(userId),
    fetchPosts(userId),
    fetchFollowers(userId)
  ]);
  
  return { profile, posts, followers };
}
```

### Error Handling
```typescript
// カスタムエラークラス
class AppError extends Error {
  constructor(
    public statusCode: number,
    public message: string,
    public isOperational = true
  ) {
    super(message);
    Error.captureStackTrace(this, this.constructor);
  }
}

// グローバルエラーハンドラー
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  if (err instanceof AppError) {
    return res.status(err.statusCode).json({
      status: 'error',
      message: err.message
    });
  }
  
  // 予期しないエラー
  logger.error('Unexpected error', err);
  res.status(500).json({
    status: 'error',
    message: 'Internal server error'
  });
});
```

## データベースパターン

### Repository Pattern
```typescript
// repositories/userRepository.ts
export class UserRepository {
  async findById(id: string): Promise<User | null> {
    return await db.user.findUnique({ where: { id } });
  }
  
  async findByEmail(email: string): Promise<User | null> {
    return await db.user.findUnique({ where: { email } });
  }
  
  async create(data: CreateUserDto): Promise<User> {
    return await db.user.create({ data });
  }
  
  async update(id: string, data: UpdateUserDto): Promise<User> {
    return await db.user.update({ where: { id }, data });
  }
}
```

### トランザクション管理
```typescript
async function transferMoney(
  fromAccountId: string,
  toAccountId: string,
  amount: number
): Promise<void> {
  await db.$transaction(async (tx) => {
    // 送金元から減算
    const fromAccount = await tx.account.update({
      where: { id: fromAccountId },
      data: { balance: { decrement: amount } }
    });
    
    if (fromAccount.balance < 0) {
      throw new Error('Insufficient funds');
    }
    
    // 送金先に加算
    await tx.account.update({
      where: { id: toAccountId },
      data: { balance: { increment: amount } }
    });
    
    // 取引記録
    await tx.transaction.create({
      data: { fromAccountId, toAccountId, amount }
    });
  });
}
```

## API設計

### RESTful Routes
```typescript
// routes/userRoutes.ts
router.get('/users', authenticate, paginate, userController.list);
router.get('/users/:id', authenticate, userController.get);
router.post('/users', validate(createUserSchema), userController.create);
router.put('/users/:id', authenticate, authorize, userController.update);
router.delete('/users/:id', authenticate, authorize, userController.delete);
```

### バリデーション
```typescript
import { z } from 'zod';

const createUserSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8).regex(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/),
  name: z.string().min(2).max(100),
  age: z.number().min(18).optional()
});

const validateRequest = (schema: z.ZodSchema) => {
  return async (req: Request, res: Response, next: NextFunction) => {
    try {
      req.body = await schema.parseAsync(req.body);
      next();
    } catch (error) {
      if (error instanceof z.ZodError) {
        return res.status(400).json({
          status: 'error',
          errors: error.errors
        });
      }
      next(error);
    }
  };
};
```

## セキュリティ

### 認証・認可
```typescript
// JWT認証
import jwt from 'jsonwebtoken';

export const generateToken = (userId: string): string => {
  return jwt.sign(
    { userId },
    process.env.JWT_SECRET!,
    { expiresIn: '7d' }
  );
};

export const authenticate = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  const token = req.headers.authorization?.replace('Bearer ', '');
  
  if (!token) {
    return res.status(401).json({ message: 'Authentication required' });
  }
  
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET!) as { userId: string };
    req.user = await userService.findById(decoded.userId);
    next();
  } catch (error) {
    res.status(401).json({ message: 'Invalid token' });
  }
};
```

### Rate Limiting
```typescript
import rateLimit from 'express-rate-limit';

const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15分
  max: 100, // 最大100リクエスト
  message: 'Too many requests from this IP'
});

const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  skipSuccessfulRequests: true
});

app.use('/api', apiLimiter);
app.use('/auth/login', loginLimiter);
```

## パフォーマンス最適化

### キャッシング
```typescript
import Redis from 'ioredis';

const redis = new Redis();

export const cacheMiddleware = (ttl: number = 3600) => {
  return async (req: Request, res: Response, next: NextFunction) => {
    const key = `cache:${req.originalUrl}`;
    const cached = await redis.get(key);
    
    if (cached) {
      return res.json(JSON.parse(cached));
    }
    
    // レスポンスをインターセプト
    const originalJson = res.json.bind(res);
    res.json = function(data) {
      redis.setex(key, ttl, JSON.stringify(data));
      return originalJson(data);
    };
    
    next();
  };
};
```

### データベースクエリ最適化
```typescript
// N+1問題の回避
// ❌ 悪い例
const posts = await db.post.findMany();
for (const post of posts) {
  post.author = await db.user.findUnique({ where: { id: post.authorId } });
}

// ✅ 良い例
const posts = await db.post.findMany({
  include: {
    author: true,
    comments: {
      include: {
        user: true
      }
    }
  }
});
```

## ロギング・モニタリング

### 構造化ログ
```typescript
import winston from 'winston';

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.json(),
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' })
  ]
});

// 使用例
logger.info('User created', {
  userId: user.id,
  email: user.email,
  timestamp: new Date().toISOString()
});
```

## チェックリスト
- [ ] レイヤードアーキテクチャ実装
- [ ] 依存性注入使用
- [ ] エラーハンドリング統一
- [ ] バリデーション実装
- [ ] 認証・認可実装
- [ ] Rate Limiting設定
- [ ] キャッシング戦略
- [ ] ロギング実装
- [ ] モニタリング設定