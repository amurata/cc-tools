# Clean Architecture

クリーンアーキテクチャの原則と実装パターン。

## アーキテクチャの原則

### 依存性の方向
```
[External] → [Interface Adapters] → [Use Cases] → [Entities]
    ←              ←                     ←

外側から内側への依存のみ許可
内側は外側を知らない
```

### レイヤー構造
```typescript
// 1. Entities (Enterprise Business Rules)
// ビジネスの核心ロジック
export class User {
  constructor(
    public readonly id: string,
    public email: string,
    public hashedPassword: string
  ) {}
  
  changeEmail(newEmail: string): void {
    if (!this.isValidEmail(newEmail)) {
      throw new Error('Invalid email format');
    }
    this.email = newEmail;
  }
  
  private isValidEmail(email: string): boolean {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
  }
}

// 2. Use Cases (Application Business Rules)
// アプリケーション固有のビジネスルール
export class CreateUserUseCase {
  constructor(
    private userRepository: IUserRepository,
    private emailService: IEmailService,
    private passwordHasher: IPasswordHasher
  ) {}
  
  async execute(request: CreateUserRequest): Promise<CreateUserResponse> {
    const hashedPassword = await this.passwordHasher.hash(request.password);
    
    const user = new User(
      generateId(),
      request.email,
      hashedPassword
    );
    
    await this.userRepository.save(user);
    await this.emailService.sendWelcome(user.email);
    
    return {
      id: user.id,
      email: user.email
    };
  }
}

// 3. Interface Adapters
// 外部とのインターフェース
export class UserController {
  constructor(private createUserUseCase: CreateUserUseCase) {}
  
  async createUser(req: Request, res: Response): Promise<void> {
    const request: CreateUserRequest = {
      email: req.body.email,
      password: req.body.password
    };
    
    const response = await this.createUserUseCase.execute(request);
    
    res.status(201).json(response);
  }
}

// 4. Frameworks & Drivers
// 具体的な実装
export class PostgresUserRepository implements IUserRepository {
  async save(user: User): Promise<void> {
    await db.query(
      'INSERT INTO users (id, email, password) VALUES ($1, $2, $3)',
      [user.id, user.email, user.hashedPassword]
    );
  }
  
  async findById(id: string): Promise<User | null> {
    const result = await db.query('SELECT * FROM users WHERE id = $1', [id]);
    if (result.rows.length === 0) return null;
    
    const row = result.rows[0];
    return new User(row.id, row.email, row.password);
  }
}
```

## 依存性逆転の原則

### インターフェース定義
```typescript
// domain/repositories/IUserRepository.ts
export interface IUserRepository {
  save(user: User): Promise<void>;
  findById(id: string): Promise<User | null>;
  findByEmail(email: string): Promise<User | null>;
  delete(id: string): Promise<void>;
}

// domain/services/IEmailService.ts
export interface IEmailService {
  sendWelcome(email: string): Promise<void>;
  sendPasswordReset(email: string, token: string): Promise<void>;
}

// infrastructure/repositories/UserRepository.ts
import { IUserRepository } from '../../domain/repositories/IUserRepository';

export class UserRepository implements IUserRepository {
  // 具体的な実装
  async save(user: User): Promise<void> {
    // MongoDB, PostgreSQL, etc.
  }
}
```

### 依存性注入
```typescript
// infrastructure/container.ts
import { Container } from 'inversify';

const container = new Container();

// インターフェースと実装のバインディング
container.bind<IUserRepository>('IUserRepository').to(PostgresUserRepository);
container.bind<IEmailService>('IEmailService').to(SendGridEmailService);
container.bind<IPasswordHasher>('IPasswordHasher').to(BcryptPasswordHasher);

// Use Case
container.bind<CreateUserUseCase>(CreateUserUseCase).toSelf();

// Controller
container.bind<UserController>(UserController).toSelf();

export { container };
```

## ディレクトリ構造

### 推奨構造
```
src/
├── domain/              # エンティティとビジネスルール
│   ├── entities/
│   │   ├── User.ts
│   │   └── Order.ts
│   ├── value-objects/
│   │   ├── Email.ts
│   │   └── Money.ts
│   └── repositories/    # インターフェース定義
│       └── IUserRepository.ts
│
├── application/         # ユースケース
│   ├── use-cases/
│   │   ├── CreateUserUseCase.ts
│   │   └── AuthenticateUserUseCase.ts
│   └── services/       # アプリケーションサービス
│       └── IEmailService.ts
│
├── infrastructure/     # 外部システムとの統合
│   ├── repositories/   # Repository実装
│   │   └── PostgresUserRepository.ts
│   ├── services/      # サービス実装
│   │   └── SendGridEmailService.ts
│   └── config/
│       └── database.ts
│
└── presentation/      # UI層
    ├── controllers/
    │   └── UserController.ts
    ├── middlewares/
    └── routes/
```

## データフロー

### リクエストからレスポンスまで
```typescript
// 1. Route定義
router.post('/users', userController.create);

// 2. Controller
class UserController {
  async create(req: Request, res: Response) {
    // リクエストをUse Case用のDTOに変換
    const createUserDto: CreateUserDto = {
      email: req.body.email,
      password: req.body.password,
      name: req.body.name
    };
    
    // Use Case実行
    const result = await this.createUserUseCase.execute(createUserDto);
    
    // レスポンス用のViewModelに変換
    const viewModel = UserViewModel.fromDomain(result);
    
    res.json(viewModel);
  }
}

// 3. Use Case
class CreateUserUseCase {
  async execute(dto: CreateUserDto): Promise<User> {
    // ビジネスルール検証
    const existingUser = await this.userRepo.findByEmail(dto.email);
    if (existingUser) {
      throw new EmailAlreadyExistsError();
    }
    
    // エンティティ作成
    const user = User.create({
      email: new Email(dto.email),
      password: await Password.create(dto.password),
      name: dto.name
    });
    
    // 永続化
    await this.userRepo.save(user);
    
    // イベント発行
    await this.eventBus.publish(new UserCreatedEvent(user));
    
    return user;
  }
}
```

## テスト戦略

### ユニットテスト
```typescript
// domain/entities/User.test.ts
describe('User Entity', () => {
  test('creates user with valid data', () => {
    const user = User.create({
      email: new Email('test@example.com'),
      password: Password.fromHash('hashed'),
      name: 'Test User'
    });
    
    expect(user.email.value).toBe('test@example.com');
  });
  
  test('throws error for invalid email', () => {
    expect(() => {
      User.create({
        email: new Email('invalid'),
        password: Password.fromHash('hashed'),
        name: 'Test'
      });
    }).toThrow('Invalid email format');
  });
});

// application/use-cases/CreateUserUseCase.test.ts
describe('CreateUserUseCase', () => {
  let useCase: CreateUserUseCase;
  let mockUserRepo: jest.Mocked<IUserRepository>;
  let mockEmailService: jest.Mocked<IEmailService>;
  
  beforeEach(() => {
    mockUserRepo = createMockUserRepository();
    mockEmailService = createMockEmailService();
    useCase = new CreateUserUseCase(mockUserRepo, mockEmailService);
  });
  
  test('creates user successfully', async () => {
    mockUserRepo.findByEmail.mockResolvedValue(null);
    
    const result = await useCase.execute({
      email: 'new@example.com',
      password: 'SecurePass123!',
      name: 'New User'
    });
    
    expect(result).toBeDefined();
    expect(mockUserRepo.save).toHaveBeenCalled();
    expect(mockEmailService.sendWelcome).toHaveBeenCalled();
  });
});
```

## 実装のヒント

### Value Objects
```typescript
// 不変で自己検証するValue Object
export class Email {
  private readonly _value: string;
  
  constructor(value: string) {
    if (!this.isValid(value)) {
      throw new Error('Invalid email format');
    }
    this._value = value.toLowerCase();
  }
  
  get value(): string {
    return this._value;
  }
  
  equals(other: Email): boolean {
    return this._value === other._value;
  }
  
  private isValid(email: string): boolean {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
  }
}
```

### Domain Events
```typescript
// domain/events/UserCreatedEvent.ts
export class UserCreatedEvent {
  constructor(
    public readonly userId: string,
    public readonly email: string,
    public readonly occurredAt: Date = new Date()
  ) {}
}

// application/event-handlers/SendWelcomeEmailHandler.ts
export class SendWelcomeEmailHandler {
  constructor(private emailService: IEmailService) {}
  
  async handle(event: UserCreatedEvent): Promise<void> {
    await this.emailService.sendWelcome(event.email);
  }
}
```

## チェックリスト
- [ ] 依存性の方向が内向き
- [ ] ビジネスロジックがドメイン層に集約
- [ ] Use Caseが単一責任
- [ ] インターフェースで抽象化
- [ ] 依存性注入使用
- [ ] Value Objects活用
- [ ] ドメインイベント実装
- [ ] 各層が独立してテスト可能
- [ ] フレームワーク非依存