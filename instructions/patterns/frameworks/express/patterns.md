# Express.js パターン

Node.js バックエンドAPIのためのExpress.jsパターン。

## アプリケーション構造

### 基本セットアップ
```javascript
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');

const app = express();

// ミドルウェア
app.use(helmet()); // セキュリティヘッダー
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// ルート
app.use('/api/users', userRoutes);
app.use('/api/products', productRoutes);

// エラーハンドリング
app.use(errorHandler);

const PORT = process.env.PORT || 3000;
app.listen(PORT);
```

## ルーティング

### モジュラールーター
```javascript
// routes/users.js
const router = express.Router();

router.get('/', getAllUsers);
router.get('/:id', getUser);
router.post('/', createUser);
router.put('/:id', updateUser);
router.delete('/:id', deleteUser);

module.exports = router;
```

### パラメータ検証
```javascript
const { body, param, validationResult } = require('express-validator');

router.post('/',
  body('email').isEmail(),
  body('password').isLength({ min: 8 }),
  (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    next();
  },
  createUser
);
```

## ミドルウェア

### 認証ミドルウェア
```javascript
const jwt = require('jsonwebtoken');

const authenticate = (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];
  
  if (!token) {
    return res.status(401).json({ error: 'No token provided' });
  }
  
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    res.status(401).json({ error: 'Invalid token' });
  }
};

// 使用
router.get('/profile', authenticate, getProfile);
```

### レート制限
```javascript
const rateLimit = require('express-rate-limit');

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15分
  max: 100, // 最大100リクエスト
  message: 'Too many requests'
});

app.use('/api/', limiter);
```

## エラーハンドリング

### グローバルエラーハンドラー
```javascript
class AppError extends Error {
  constructor(message, statusCode) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = true;
  }
}

const errorHandler = (err, req, res, next) => {
  const { statusCode = 500, message } = err;
  
  res.status(statusCode).json({
    status: 'error',
    statusCode,
    message,
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
};

// 非同期エラーキャッチ
const catchAsync = (fn) => {
  return (req, res, next) => {
    fn(req, res, next).catch(next);
  };
};
```

## データベース統合

### MongoDB (Mongoose)
```javascript
const mongoose = require('mongoose');

// スキーマ定義
const userSchema = new mongoose.Schema({
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  createdAt: { type: Date, default: Date.now }
});

// ミドルウェア
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  this.password = await bcrypt.hash(this.password, 10);
  next();
});

const User = mongoose.model('User', userSchema);
```

### PostgreSQL (Prisma)
```javascript
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

const getUsers = catchAsync(async (req, res) => {
  const users = await prisma.user.findMany({
    select: {
      id: true,
      email: true,
      name: true
    }
  });
  res.json(users);
});
```

## セキュリティ

### 入力サニタイゼーション
```javascript
const mongoSanitize = require('express-mongo-sanitize');
const xss = require('xss-clean');

app.use(mongoSanitize()); // NoSQL インジェクション防止
app.use(xss()); // XSS攻撃防止
```

### HTTPS強制
```javascript
app.use((req, res, next) => {
  if (req.header('x-forwarded-proto') !== 'https') {
    res.redirect(`https://${req.header('host')}${req.url}`);
  } else {
    next();
  }
});
```

## パフォーマンス

### 圧縮
```javascript
const compression = require('compression');
app.use(compression());
```

### キャッシング
```javascript
const redis = require('redis');
const client = redis.createClient();

const cache = (duration) => {
  return async (req, res, next) => {
    const key = req.originalUrl;
    const cached = await client.get(key);
    
    if (cached) {
      return res.json(JSON.parse(cached));
    }
    
    res.sendResponse = res.json;
    res.json = (body) => {
      client.setex(key, duration, JSON.stringify(body));
      res.sendResponse(body);
    };
    next();
  };
};

// 使用
router.get('/products', cache(300), getProducts);
```

## チェックリスト
- [ ] 適切なミドルウェア構成
- [ ] ルートモジュール化
- [ ] 入力検証実装
- [ ] 認証・認可
- [ ] エラーハンドリング
- [ ] セキュリティ対策
- [ ] パフォーマンス最適化