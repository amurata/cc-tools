> **[English](../../../../../plugins/javascript-typescript/skills/javascript-testing-patterns/SKILL.md)** | **日本語**

---
name: javascript-testing-patterns
description: Jest、Vitest、Testing Libraryを使用した包括的なテスト戦略を実装し、モッキング、フィクスチャ、テスト駆動開発を用いたユニットテスト、統合テスト、エンドツーエンドテストを行います。JavaScript/TypeScriptテストの作成、テストインフラの設定、TDD/BDDワークフローの実装時に使用してください。
---

# JavaScriptテストパターン

モダンなテストフレームワークとベストプラクティスを使用して、JavaScript/TypeScriptアプリケーションで堅牢なテスト戦略を実装するための包括的なガイド。

## このスキルを使用する場面

- 新規プロジェクトのテストインフラのセットアップ
- 関数とクラスのユニットテストの作成
- APIとサービスの統合テストの作成
- ユーザーフローのエンドツーエンドテストの実装
- 外部依存関係とAPIのモック化
- React、Vue、その他のフロントエンドコンポーネントのテスト
- テスト駆動開発（TDD）の実装
- CI/CDパイプラインでの継続的テストのセットアップ

## テストフレームワーク

### Jest - フル機能テストフレームワーク

**セットアップ:**
```typescript
// jest.config.ts
import type { Config } from 'jest';

const config: Config = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/src'],
  testMatch: ['**/__tests__/**/*.ts', '**/?(*.)+(spec|test).ts'],
  collectCoverageFrom: [
    'src/**/*.ts',
    '!src/**/*.d.ts',
    '!src/**/*.interface.ts',
  ],
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80,
    },
  },
  setupFilesAfterEnv: ['<rootDir>/src/test/setup.ts'],
};

export default config;
```

### Vitest - 高速でViteネイティブなテスト

**セットアップ:**
```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      exclude: ['**/*.d.ts', '**/*.config.ts', '**/dist/**'],
    },
    setupFiles: ['./src/test/setup.ts'],
  },
});
```

## ユニットテストパターン

### パターン1: 純粋関数のテスト

```typescript
// utils/calculator.ts
export function add(a: number, b: number): number {
  return a + b;
}

export function divide(a: number, b: number): number {
  if (b === 0) {
    throw new Error('Division by zero');
  }
  return a / b;
}

// utils/calculator.test.ts
import { describe, it, expect } from 'vitest';
import { add, divide } from './calculator';

describe('Calculator', () => {
  describe('add', () => {
    it('should add two positive numbers', () => {
      expect(add(2, 3)).toBe(5);
    });

    it('should add negative numbers', () => {
      expect(add(-2, -3)).toBe(-5);
    });

    it('should handle zero', () => {
      expect(add(0, 5)).toBe(5);
      expect(add(5, 0)).toBe(5);
    });
  });

  describe('divide', () => {
    it('should divide two numbers', () => {
      expect(divide(10, 2)).toBe(5);
    });

    it('should handle decimal results', () => {
      expect(divide(5, 2)).toBe(2.5);
    });

    it('should throw error when dividing by zero', () => {
      expect(() => divide(10, 0)).toThrow('Division by zero');
    });
  });
});
```

### パターン2: クラスのテスト

```typescript
// services/user.service.ts
export class UserService {
  private users: Map<string, User> = new Map();

  create(user: User): User {
    if (this.users.has(user.id)) {
      throw new Error('User already exists');
    }
    this.users.set(user.id, user);
    return user;
  }

  findById(id: string): User | undefined {
    return this.users.get(id);
  }

  update(id: string, updates: Partial<User>): User {
    const user = this.users.get(id);
    if (!user) {
      throw new Error('User not found');
    }
    const updated = { ...user, ...updates };
    this.users.set(id, updated);
    return updated;
  }

  delete(id: string): boolean {
    return this.users.delete(id);
  }
}

// services/user.service.test.ts
import { describe, it, expect, beforeEach } from 'vitest';
import { UserService } from './user.service';

describe('UserService', () => {
  let service: UserService;

  beforeEach(() => {
    service = new UserService();
  });

  describe('create', () => {
    it('should create a new user', () => {
      const user = { id: '1', name: 'John', email: 'john@example.com' };
      const created = service.create(user);

      expect(created).toEqual(user);
      expect(service.findById('1')).toEqual(user);
    });

    it('should throw error if user already exists', () => {
      const user = { id: '1', name: 'John', email: 'john@example.com' };
      service.create(user);

      expect(() => service.create(user)).toThrow('User already exists');
    });
  });

  describe('update', () => {
    it('should update existing user', () => {
      const user = { id: '1', name: 'John', email: 'john@example.com' };
      service.create(user);

      const updated = service.update('1', { name: 'Jane' });

      expect(updated.name).toBe('Jane');
      expect(updated.email).toBe('john@example.com');
    });

    it('should throw error if user not found', () => {
      expect(() => service.update('999', { name: 'Jane' }))
        .toThrow('User not found');
    });
  });
});
```

### パターン3: 非同期関数のテスト

```typescript
// services/api.service.ts
export class ApiService {
  async fetchUser(id: string): Promise<User> {
    const response = await fetch(`https://api.example.com/users/${id}`);
    if (!response.ok) {
      throw new Error('User not found');
    }
    return response.json();
  }

  async createUser(user: CreateUserDTO): Promise<User> {
    const response = await fetch('https://api.example.com/users', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(user),
    });
    return response.json();
  }
}

// services/api.service.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { ApiService } from './api.service';

// fetchをグローバルにモック
global.fetch = vi.fn();

describe('ApiService', () => {
  let service: ApiService;

  beforeEach(() => {
    service = new ApiService();
    vi.clearAllMocks();
  });

  describe('fetchUser', () => {
    it('should fetch user successfully', async () => {
      const mockUser = { id: '1', name: 'John', email: 'john@example.com' };

      (fetch as any).mockResolvedValueOnce({
        ok: true,
        json: async () => mockUser,
      });

      const user = await service.fetchUser('1');

      expect(user).toEqual(mockUser);
      expect(fetch).toHaveBeenCalledWith('https://api.example.com/users/1');
    });

    it('should throw error if user not found', async () => {
      (fetch as any).mockResolvedValueOnce({
        ok: false,
      });

      await expect(service.fetchUser('999')).rejects.toThrow('User not found');
    });
  });

  describe('createUser', () => {
    it('should create user successfully', async () => {
      const newUser = { name: 'John', email: 'john@example.com' };
      const createdUser = { id: '1', ...newUser };

      (fetch as any).mockResolvedValueOnce({
        ok: true,
        json: async () => createdUser,
      });

      const user = await service.createUser(newUser);

      expect(user).toEqual(createdUser);
      expect(fetch).toHaveBeenCalledWith(
        'https://api.example.com/users',
        expect.objectContaining({
          method: 'POST',
          body: JSON.stringify(newUser),
        })
      );
    });
  });
});
```

## モッキングパターン

### パターン1: モジュールのモック化

```typescript
// services/email.service.ts
import nodemailer from 'nodemailer';

export class EmailService {
  private transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: 587,
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS,
    },
  });

  async sendEmail(to: string, subject: string, html: string) {
    await this.transporter.sendMail({
      from: process.env.EMAIL_FROM,
      to,
      subject,
      html,
    });
  }
}

// services/email.service.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { EmailService } from './email.service';

vi.mock('nodemailer', () => ({
  default: {
    createTransport: vi.fn(() => ({
      sendMail: vi.fn().mockResolvedValue({ messageId: '123' }),
    })),
  },
}));

describe('EmailService', () => {
  let service: EmailService;

  beforeEach(() => {
    service = new EmailService();
  });

  it('should send email successfully', async () => {
    await service.sendEmail(
      'test@example.com',
      'Test Subject',
      '<p>Test Body</p>'
    );

    expect(service['transporter'].sendMail).toHaveBeenCalledWith(
      expect.objectContaining({
        to: 'test@example.com',
        subject: 'Test Subject',
      })
    );
  });
});
```

### パターン2: テスト用の依存性注入

```typescript
// services/user.service.ts
export interface IUserRepository {
  findById(id: string): Promise<User | null>;
  create(user: User): Promise<User>;
}

export class UserService {
  constructor(private userRepository: IUserRepository) {}

  async getUser(id: string): Promise<User> {
    const user = await this.userRepository.findById(id);
    if (!user) {
      throw new Error('User not found');
    }
    return user;
  }

  async createUser(userData: CreateUserDTO): Promise<User> {
    // ビジネスロジックをここに
    const user = { id: generateId(), ...userData };
    return this.userRepository.create(user);
  }
}

// services/user.service.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { UserService, IUserRepository } from './user.service';

describe('UserService', () => {
  let service: UserService;
  let mockRepository: IUserRepository;

  beforeEach(() => {
    mockRepository = {
      findById: vi.fn(),
      create: vi.fn(),
    };
    service = new UserService(mockRepository);
  });

  describe('getUser', () => {
    it('should return user if found', async () => {
      const mockUser = { id: '1', name: 'John', email: 'john@example.com' };
      vi.mocked(mockRepository.findById).mockResolvedValue(mockUser);

      const user = await service.getUser('1');

      expect(user).toEqual(mockUser);
      expect(mockRepository.findById).toHaveBeenCalledWith('1');
    });

    it('should throw error if user not found', async () => {
      vi.mocked(mockRepository.findById).mockResolvedValue(null);

      await expect(service.getUser('999')).rejects.toThrow('User not found');
    });
  });

  describe('createUser', () => {
    it('should create user successfully', async () => {
      const userData = { name: 'John', email: 'john@example.com' };
      const createdUser = { id: '1', ...userData };

      vi.mocked(mockRepository.create).mockResolvedValue(createdUser);

      const user = await service.createUser(userData);

      expect(user).toEqual(createdUser);
      expect(mockRepository.create).toHaveBeenCalled();
    });
  });
});
```

### パターン3: 関数のスパイ

```typescript
// utils/logger.ts
export const logger = {
  info: (message: string) => console.log(`INFO: ${message}`),
  error: (message: string) => console.error(`ERROR: ${message}`),
};

// services/order.service.ts
import { logger } from '../utils/logger';

export class OrderService {
  async processOrder(orderId: string): Promise<void> {
    logger.info(`Processing order ${orderId}`);
    // 注文処理のロジック
    logger.info(`Order ${orderId} processed successfully`);
  }
}

// services/order.service.test.ts
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { OrderService } from './order.service';
import { logger } from '../utils/logger';

describe('OrderService', () => {
  let service: OrderService;
  let loggerSpy: any;

  beforeEach(() => {
    service = new OrderService();
    loggerSpy = vi.spyOn(logger, 'info');
  });

  afterEach(() => {
    loggerSpy.mockRestore();
  });

  it('should log order processing', async () => {
    await service.processOrder('123');

    expect(loggerSpy).toHaveBeenCalledWith('Processing order 123');
    expect(loggerSpy).toHaveBeenCalledWith('Order 123 processed successfully');
    expect(loggerSpy).toHaveBeenCalledTimes(2);
  });
});
```

## 統合テスト

### パターン1: API統合テスト

```typescript
// tests/integration/user.api.test.ts
import request from 'supertest';
import { app } from '../../src/app';
import { pool } from '../../src/config/database';

describe('User API Integration Tests', () => {
  beforeAll(async () => {
    // テストデータベースのセットアップ
    await pool.query('CREATE TABLE IF NOT EXISTS users (...)');
  });

  afterAll(async () => {
    // クリーンアップ
    await pool.query('DROP TABLE IF EXISTS users');
    await pool.end();
  });

  beforeEach(async () => {
    // 各テスト前にデータをクリア
    await pool.query('TRUNCATE TABLE users CASCADE');
  });

  describe('POST /api/users', () => {
    it('should create a new user', async () => {
      const userData = {
        name: 'John Doe',
        email: 'john@example.com',
        password: 'password123',
      };

      const response = await request(app)
        .post('/api/users')
        .send(userData)
        .expect(201);

      expect(response.body).toMatchObject({
        name: userData.name,
        email: userData.email,
      });
      expect(response.body).toHaveProperty('id');
      expect(response.body).not.toHaveProperty('password');
    });

    it('should return 400 if email is invalid', async () => {
      const userData = {
        name: 'John Doe',
        email: 'invalid-email',
        password: 'password123',
      };

      const response = await request(app)
        .post('/api/users')
        .send(userData)
        .expect(400);

      expect(response.body).toHaveProperty('error');
    });

    it('should return 409 if email already exists', async () => {
      const userData = {
        name: 'John Doe',
        email: 'john@example.com',
        password: 'password123',
      };

      await request(app).post('/api/users').send(userData);

      const response = await request(app)
        .post('/api/users')
        .send(userData)
        .expect(409);

      expect(response.body.error).toContain('already exists');
    });
  });

  describe('GET /api/users/:id', () => {
    it('should get user by id', async () => {
      const createResponse = await request(app)
        .post('/api/users')
        .send({
          name: 'John Doe',
          email: 'john@example.com',
          password: 'password123',
        });

      const userId = createResponse.body.id;

      const response = await request(app)
        .get(`/api/users/${userId}`)
        .expect(200);

      expect(response.body).toMatchObject({
        id: userId,
        name: 'John Doe',
        email: 'john@example.com',
      });
    });

    it('should return 404 if user not found', async () => {
      await request(app)
        .get('/api/users/999')
        .expect(404);
    });
  });

  describe('Authentication', () => {
    it('should require authentication for protected routes', async () => {
      await request(app)
        .get('/api/users/me')
        .expect(401);
    });

    it('should allow access with valid token', async () => {
      // ユーザーを作成してログイン
      await request(app)
        .post('/api/users')
        .send({
          name: 'John Doe',
          email: 'john@example.com',
          password: 'password123',
        });

      const loginResponse = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'john@example.com',
          password: 'password123',
        });

      const token = loginResponse.body.token;

      const response = await request(app)
        .get('/api/users/me')
        .set('Authorization', `Bearer ${token}`)
        .expect(200);

      expect(response.body.email).toBe('john@example.com');
    });
  });
});
```

### パターン2: データベース統合テスト

```typescript
// tests/integration/user.repository.test.ts
import { describe, it, expect, beforeAll, afterAll, beforeEach } from 'vitest';
import { Pool } from 'pg';
import { UserRepository } from '../../src/repositories/user.repository';

describe('UserRepository Integration Tests', () => {
  let pool: Pool;
  let repository: UserRepository;

  beforeAll(async () => {
    pool = new Pool({
      host: 'localhost',
      port: 5432,
      database: 'test_db',
      user: 'test_user',
      password: 'test_password',
    });

    repository = new UserRepository(pool);

    // テーブルを作成
    await pool.query(`
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        email VARCHAR(255) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
  });

  afterAll(async () => {
    await pool.query('DROP TABLE IF EXISTS users');
    await pool.end();
  });

  beforeEach(async () => {
    await pool.query('TRUNCATE TABLE users CASCADE');
  });

  it('should create a user', async () => {
    const user = await repository.create({
      name: 'John Doe',
      email: 'john@example.com',
      password: 'hashed_password',
    });

    expect(user).toHaveProperty('id');
    expect(user.name).toBe('John Doe');
    expect(user.email).toBe('john@example.com');
  });

  it('should find user by email', async () => {
    await repository.create({
      name: 'John Doe',
      email: 'john@example.com',
      password: 'hashed_password',
    });

    const user = await repository.findByEmail('john@example.com');

    expect(user).toBeTruthy();
    expect(user?.name).toBe('John Doe');
  });

  it('should return null if user not found', async () => {
    const user = await repository.findByEmail('nonexistent@example.com');
    expect(user).toBeNull();
  });
});
```

## Testing Libraryによるフロントエンドテスト

### パターン1: Reactコンポーネントのテスト

```typescript
// components/UserForm.tsx
import { useState } from 'react';

interface Props {
  onSubmit: (user: { name: string; email: string }) => void;
}

export function UserForm({ onSubmit }: Props) {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSubmit({ name, email });
  };

  return (
    <form onSubmit={handleSubmit}>
      <input
        type="text"
        placeholder="Name"
        value={name}
        onChange={(e) => setName(e.target.value)}
        data-testid="name-input"
      />
      <input
        type="email"
        placeholder="Email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        data-testid="email-input"
      />
      <button type="submit">Submit</button>
    </form>
  );
}

// components/UserForm.test.tsx
import { render, screen, fireEvent } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { UserForm } from './UserForm';

describe('UserForm', () => {
  it('should render form inputs', () => {
    render(<UserForm onSubmit={vi.fn()} />);

    expect(screen.getByPlaceholderText('Name')).toBeInTheDocument();
    expect(screen.getByPlaceholderText('Email')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Submit' })).toBeInTheDocument();
  });

  it('should update input values', () => {
    render(<UserForm onSubmit={vi.fn()} />);

    const nameInput = screen.getByTestId('name-input') as HTMLInputElement;
    const emailInput = screen.getByTestId('email-input') as HTMLInputElement;

    fireEvent.change(nameInput, { target: { value: 'John Doe' } });
    fireEvent.change(emailInput, { target: { value: 'john@example.com' } });

    expect(nameInput.value).toBe('John Doe');
    expect(emailInput.value).toBe('john@example.com');
  });

  it('should call onSubmit with form data', () => {
    const onSubmit = vi.fn();
    render(<UserForm onSubmit={onSubmit} />);

    fireEvent.change(screen.getByTestId('name-input'), {
      target: { value: 'John Doe' },
    });
    fireEvent.change(screen.getByTestId('email-input'), {
      target: { value: 'john@example.com' },
    });
    fireEvent.click(screen.getByRole('button', { name: 'Submit' }));

    expect(onSubmit).toHaveBeenCalledWith({
      name: 'John Doe',
      email: 'john@example.com',
    });
  });
});
```

### パターン2: フックのテスト

```typescript
// hooks/useCounter.ts
import { useState, useCallback } from 'react';

export function useCounter(initialValue = 0) {
  const [count, setCount] = useState(initialValue);

  const increment = useCallback(() => setCount((c) => c + 1), []);
  const decrement = useCallback(() => setCount((c) => c - 1), []);
  const reset = useCallback(() => setCount(initialValue), [initialValue]);

  return { count, increment, decrement, reset };
}

// hooks/useCounter.test.ts
import { renderHook, act } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import { useCounter } from './useCounter';

describe('useCounter', () => {
  it('should initialize with default value', () => {
    const { result } = renderHook(() => useCounter());
    expect(result.current.count).toBe(0);
  });

  it('should initialize with custom value', () => {
    const { result } = renderHook(() => useCounter(10));
    expect(result.current.count).toBe(10);
  });

  it('should increment count', () => {
    const { result } = renderHook(() => useCounter());

    act(() => {
      result.current.increment();
    });

    expect(result.current.count).toBe(1);
  });

  it('should decrement count', () => {
    const { result } = renderHook(() => useCounter(5));

    act(() => {
      result.current.decrement();
    });

    expect(result.current.count).toBe(4);
  });

  it('should reset to initial value', () => {
    const { result } = renderHook(() => useCounter(10));

    act(() => {
      result.current.increment();
      result.current.increment();
    });

    expect(result.current.count).toBe(12);

    act(() => {
      result.current.reset();
    });

    expect(result.current.count).toBe(10);
  });
});
```

## テストフィクスチャとファクトリー

```typescript
// tests/fixtures/user.fixture.ts
import { faker } from '@faker-js/faker';

export function createUserFixture(overrides?: Partial<User>): User {
  return {
    id: faker.string.uuid(),
    name: faker.person.fullName(),
    email: faker.internet.email(),
    createdAt: faker.date.past(),
    ...overrides,
  };
}

export function createUsersFixture(count: number): User[] {
  return Array.from({ length: count }, () => createUserFixture());
}

// テストでの使用
import { createUserFixture, createUsersFixture } from '../fixtures/user.fixture';

describe('UserService', () => {
  it('should process user', () => {
    const user = createUserFixture({ name: 'John Doe' });
    // テストでuserを使用
  });

  it('should handle multiple users', () => {
    const users = createUsersFixture(10);
    // テストでusersを使用
  });
});
```

## スナップショットテスト

```typescript
// components/UserCard.test.tsx
import { render } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import { UserCard } from './UserCard';

describe('UserCard', () => {
  it('should match snapshot', () => {
    const user = {
      id: '1',
      name: 'John Doe',
      email: 'john@example.com',
      avatar: 'https://example.com/avatar.jpg',
    };

    const { container } = render(<UserCard user={user} />);

    expect(container.firstChild).toMatchSnapshot();
  });

  it('should match snapshot with loading state', () => {
    const { container } = render(<UserCard loading />);
    expect(container.firstChild).toMatchSnapshot();
  });
});
```

## カバレッジレポート

```typescript
// package.json
{
  "scripts": {
    "test": "vitest",
    "test:coverage": "vitest --coverage",
    "test:ui": "vitest --ui"
  }
}
```

## ベストプラクティス

1. **AAAパターンに従う**: Arrange（準備）、Act（実行）、Assert（検証）
2. **テストごとに1つのアサーション**: または論理的に関連するアサーション
3. **説明的なテスト名**: テストする内容を説明
4. **beforeEach/afterEachを使用**: セットアップとティアダウン用
5. **外部依存関係をモック**: テストを分離して保つ
6. **エッジケースをテスト**: ハッピーパスだけでなく
7. **実装の詳細を避ける**: 実装ではなく動作をテスト
8. **テストファクトリーを使用**: 一貫したテストデータのため
9. **テストを高速に保つ**: 遅い操作をモック
10. **テストを最初に書く（TDD）**: 可能な場合
11. **テストカバレッジを維持**: 80%以上のカバレッジを目指す
12. **TypeScriptを使用**: 型安全なテストのため
13. **エラーハンドリングをテスト**: 成功ケースだけでなく
14. **data-testidを控えめに使用**: セマンティッククエリを優先
15. **テスト後にクリーンアップ**: テスト汚染を防ぐ

## 一般的なパターン

### テストの構成

```typescript
describe('UserService', () => {
  describe('createUser', () => {
    it('should create user successfully', () => {});
    it('should throw error if email exists', () => {});
    it('should hash password', () => {});
  });

  describe('updateUser', () => {
    it('should update user', () => {});
    it('should throw error if not found', () => {});
  });
});
```

### Promiseのテスト

```typescript
// async/awaitを使用
it('should fetch user', async () => {
  const user = await service.fetchUser('1');
  expect(user).toBeDefined();
});

// リジェクションのテスト
it('should throw error', async () => {
  await expect(service.fetchUser('invalid')).rejects.toThrow('Not found');
});
```

### タイマーのテスト

```typescript
import { vi } from 'vitest';

it('should call function after delay', () => {
  vi.useFakeTimers();

  const callback = vi.fn();
  setTimeout(callback, 1000);

  expect(callback).not.toHaveBeenCalled();

  vi.advanceTimersByTime(1000);

  expect(callback).toHaveBeenCalled();

  vi.useRealTimers();
});
```

## リソース

- **Jest Documentation**: https://jestjs.io/
- **Vitest Documentation**: https://vitest.dev/
- **Testing Library**: https://testing-library.com/
- **Kent C. Dodds Testing Blog**: https://kentcdodds.com/blog/
