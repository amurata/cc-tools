# Authentication & Authorization Patterns

認証と認可の実装パターンとセキュリティベストプラクティス。

## 認証 (Authentication)

### JWT実装
```typescript
import jwt from 'jsonwebtoken';
import bcrypt from 'bcrypt';

// JWT設定
const JWT_SECRET = process.env.JWT_SECRET!;
const JWT_EXPIRES_IN = '7d';
const REFRESH_TOKEN_EXPIRES_IN = '30d';

// トークン生成
interface TokenPayload {
  userId: string;
  email: string;
  roles: string[];
}

export class AuthService {
  // アクセストークン生成
  generateAccessToken(payload: TokenPayload): string {
    return jwt.sign(payload, JWT_SECRET, {
      expiresIn: JWT_EXPIRES_IN,
      issuer: 'api.example.com',
      audience: 'app.example.com'
    });
  }
  
  // リフレッシュトークン生成
  generateRefreshToken(userId: string): string {
    return jwt.sign(
      { userId, type: 'refresh' },
      JWT_SECRET,
      { expiresIn: REFRESH_TOKEN_EXPIRES_IN }
    );
  }
  
  // トークン検証
  verifyToken(token: string): TokenPayload {
    try {
      return jwt.verify(token, JWT_SECRET) as TokenPayload;
    } catch (error) {
      if (error instanceof jwt.TokenExpiredError) {
        throw new AuthError('Token expired', 401);
      }
      if (error instanceof jwt.JsonWebTokenError) {
        throw new AuthError('Invalid token', 401);
      }
      throw error;
    }
  }
}
```

### パスワード管理
```typescript
export class PasswordService {
  private readonly SALT_ROUNDS = 12;
  private readonly MIN_LENGTH = 8;
  private readonly PASSWORD_REGEX = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])/;
  
  // パスワードハッシュ化
  async hash(password: string): Promise<string> {
    this.validateStrength(password);
    return bcrypt.hash(password, this.SALT_ROUNDS);
  }
  
  // パスワード検証
  async verify(password: string, hash: string): Promise<boolean> {
    return bcrypt.compare(password, hash);
  }
  
  // 強度検証
  validateStrength(password: string): void {
    if (password.length < this.MIN_LENGTH) {
      throw new Error(`Password must be at least ${this.MIN_LENGTH} characters`);
    }
    
    if (!this.PASSWORD_REGEX.test(password)) {
      throw new Error('Password must contain uppercase, lowercase, number and special character');
    }
    
    // 一般的な弱いパスワードチェック
    const commonPasswords = ['password', '12345678', 'qwerty'];
    if (commonPasswords.some(common => password.toLowerCase().includes(common))) {
      throw new Error('Password is too common');
    }
  }
}
```

### 多要素認証 (MFA)
```typescript
import speakeasy from 'speakeasy';
import QRCode from 'qrcode';

export class MFAService {
  // シークレット生成
  generateSecret(user: User): speakeasy.GeneratedSecret {
    return speakeasy.generateSecret({
      name: `MyApp (${user.email})`,
      issuer: 'MyApp',
      length: 32
    });
  }
  
  // QRコード生成
  async generateQRCode(secret: string): Promise<string> {
    const otpauth = speakeasy.otpauthURL({
      secret: secret,
      label: 'MyApp',
      issuer: 'MyApp',
      encoding: 'base32'
    });
    
    return QRCode.toDataURL(otpauth);
  }
  
  // トークン検証
  verifyToken(token: string, secret: string): boolean {
    return speakeasy.totp.verify({
      secret: secret,
      encoding: 'base32',
      token: token,
      window: 2 // 前後2つの時間枠を許容
    });
  }
  
  // バックアップコード生成
  generateBackupCodes(count: number = 10): string[] {
    const codes: string[] = [];
    for (let i = 0; i < count; i++) {
      codes.push(crypto.randomBytes(4).toString('hex').toUpperCase());
    }
    return codes;
  }
}
```

## 認可 (Authorization)

### RBAC (Role-Based Access Control)
```typescript
// ロールとパーミッション定義
enum Role {
  ADMIN = 'admin',
  EDITOR = 'editor',
  VIEWER = 'viewer'
}

enum Permission {
  READ = 'read',
  WRITE = 'write',
  DELETE = 'delete',
  ADMIN = 'admin'
}

// ロールとパーミッションのマッピング
const rolePermissions: Record<Role, Permission[]> = {
  [Role.ADMIN]: [Permission.READ, Permission.WRITE, Permission.DELETE, Permission.ADMIN],
  [Role.EDITOR]: [Permission.READ, Permission.WRITE],
  [Role.VIEWER]: [Permission.READ]
};

// 認可サービス
export class AuthorizationService {
  hasPermission(userRoles: Role[], requiredPermission: Permission): boolean {
    return userRoles.some(role => 
      rolePermissions[role]?.includes(requiredPermission)
    );
  }
  
  hasAnyRole(userRoles: Role[], requiredRoles: Role[]): boolean {
    return requiredRoles.some(role => userRoles.includes(role));
  }
  
  hasAllRoles(userRoles: Role[], requiredRoles: Role[]): boolean {
    return requiredRoles.every(role => userRoles.includes(role));
  }
}

// Express ミドルウェア
export const authorize = (...requiredPermissions: Permission[]) => {
  return (req: Request, res: Response, next: NextFunction) => {
    const user = req.user;
    
    if (!user) {
      return res.status(401).json({ error: 'Unauthorized' });
    }
    
    const authService = new AuthorizationService();
    const hasPermission = requiredPermissions.every(permission =>
      authService.hasPermission(user.roles, permission)
    );
    
    if (!hasPermission) {
      return res.status(403).json({ error: 'Forbidden' });
    }
    
    next();
  };
};
```

### ABAC (Attribute-Based Access Control)
```typescript
// 属性ベースのポリシー
interface AccessContext {
  user: {
    id: string;
    department: string;
    level: number;
  };
  resource: {
    ownerId: string;
    department: string;
    confidentiality: 'public' | 'internal' | 'confidential';
  };
  action: string;
  environment: {
    time: Date;
    ipAddress: string;
  };
}

export class ABACService {
  private policies: Policy[] = [
    {
      name: 'owner-can-edit',
      evaluate: (ctx: AccessContext) => 
        ctx.user.id === ctx.resource.ownerId && ctx.action === 'edit'
    },
    {
      name: 'department-access',
      evaluate: (ctx: AccessContext) =>
        ctx.user.department === ctx.resource.department
    },
    {
      name: 'confidentiality-level',
      evaluate: (ctx: AccessContext) => {
        const levels = { public: 0, internal: 1, confidential: 2 };
        return ctx.user.level >= levels[ctx.resource.confidentiality];
      }
    },
    {
      name: 'business-hours',
      evaluate: (ctx: AccessContext) => {
        const hour = ctx.environment.time.getHours();
        return hour >= 9 && hour < 18;
      }
    }
  ];
  
  evaluate(context: AccessContext, requiredPolicies: string[]): boolean {
    return requiredPolicies.every(policyName => {
      const policy = this.policies.find(p => p.name === policyName);
      return policy ? policy.evaluate(context) : false;
    });
  }
}
```

## セッション管理

### セキュアなセッション設定
```typescript
import session from 'express-session';
import RedisStore from 'connect-redis';
import Redis from 'ioredis';

const redis = new Redis({
  host: process.env.REDIS_HOST,
  port: parseInt(process.env.REDIS_PORT!),
  password: process.env.REDIS_PASSWORD
});

app.use(session({
  store: new RedisStore({ client: redis }),
  secret: process.env.SESSION_SECRET!,
  resave: false,
  saveUninitialized: false,
  rolling: true, // 活動時にセッション更新
  cookie: {
    secure: process.env.NODE_ENV === 'production', // HTTPS必須
    httpOnly: true, // XSS対策
    maxAge: 1000 * 60 * 60 * 24, // 24時間
    sameSite: 'strict' // CSRF対策
  }
}));

// セッション無効化
export const invalidateSession = async (sessionId: string): Promise<void> => {
  await redis.del(`sess:${sessionId}`);
};

// 同時セッション制限
export class SessionManager {
  private userSessions = new Map<string, Set<string>>();
  private readonly MAX_SESSIONS = 3;
  
  async createSession(userId: string, sessionId: string): Promise<void> {
    if (!this.userSessions.has(userId)) {
      this.userSessions.set(userId, new Set());
    }
    
    const sessions = this.userSessions.get(userId)!;
    
    // 最大セッション数を超えた場合、古いセッションを削除
    if (sessions.size >= this.MAX_SESSIONS) {
      const oldestSession = sessions.values().next().value;
      await invalidateSession(oldestSession);
      sessions.delete(oldestSession);
    }
    
    sessions.add(sessionId);
  }
}
```

## OAuth 2.0 / OpenID Connect

### OAuth実装
```typescript
import passport from 'passport';
import { Strategy as GoogleStrategy } from 'passport-google-oauth20';

// Google OAuth設定
passport.use(new GoogleStrategy({
  clientID: process.env.GOOGLE_CLIENT_ID!,
  clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
  callbackURL: '/auth/google/callback'
}, async (accessToken, refreshToken, profile, done) => {
  try {
    // ユーザー検索または作成
    let user = await userRepository.findByGoogleId(profile.id);
    
    if (!user) {
      user = await userRepository.create({
        googleId: profile.id,
        email: profile.emails![0].value,
        name: profile.displayName,
        avatar: profile.photos![0].value
      });
    }
    
    return done(null, user);
  } catch (error) {
    return done(error as Error);
  }
}));

// ルート設定
app.get('/auth/google',
  passport.authenticate('google', { scope: ['profile', 'email'] })
);

app.get('/auth/google/callback',
  passport.authenticate('google', { failureRedirect: '/login' }),
  (req, res) => {
    // JWTトークン生成
    const token = authService.generateAccessToken({
      userId: req.user!.id,
      email: req.user!.email,
      roles: req.user!.roles
    });
    
    res.redirect(`/dashboard?token=${token}`);
  }
);
```

## セキュリティヘッダー

### ヘルメット設定
```typescript
import helmet from 'helmet';

app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true
  }
}));

// CORS設定
import cors from 'cors';

app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000'],
  credentials: true,
  optionsSuccessStatus: 200
}));
```

## ブルートフォース対策

### ログイン試行制限
```typescript
export class LoginAttemptTracker {
  private attempts = new Map<string, { count: number; lastAttempt: Date }>();
  private readonly MAX_ATTEMPTS = 5;
  private readonly LOCKOUT_DURATION = 15 * 60 * 1000; // 15分
  
  canAttempt(identifier: string): boolean {
    const record = this.attempts.get(identifier);
    
    if (!record) return true;
    
    const timeSinceLastAttempt = Date.now() - record.lastAttempt.getTime();
    
    if (timeSinceLastAttempt > this.LOCKOUT_DURATION) {
      this.attempts.delete(identifier);
      return true;
    }
    
    return record.count < this.MAX_ATTEMPTS;
  }
  
  recordAttempt(identifier: string, success: boolean): void {
    if (success) {
      this.attempts.delete(identifier);
      return;
    }
    
    const record = this.attempts.get(identifier) || { count: 0, lastAttempt: new Date() };
    record.count++;
    record.lastAttempt = new Date();
    this.attempts.set(identifier, record);
  }
  
  getRemainingAttempts(identifier: string): number {
    const record = this.attempts.get(identifier);
    if (!record) return this.MAX_ATTEMPTS;
    return Math.max(0, this.MAX_ATTEMPTS - record.count);
  }
}
```

## チェックリスト
- [ ] パスワード強度検証実装
- [ ] パスワードハッシュ化（bcrypt/argon2）
- [ ] JWT適切な有効期限設定
- [ ] リフレッシュトークン実装
- [ ] MFA/2FA オプション
- [ ] RBAC/ABAC実装
- [ ] セッションセキュリティ設定
- [ ] CSRF対策
- [ ] XSS対策
- [ ] ブルートフォース対策
- [ ] セキュリティヘッダー設定
- [ ] HTTPS強制