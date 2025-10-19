# JavaScriptテストパターン (2024)

## Vitest (高速で現代的なテストランナー)

### Vitestの基本設定
```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: './src/test/setup.ts',
    coverage: {
      reporter: ['text', 'json', 'html'],
      exclude: ['node_modules/', 'src/test/'],
    },
  },
});
```

### Vitestによるユニットテスト
```typescript
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';

// モックの設定
vi.mock('@/services/api', () => ({
  fetchUser: vi.fn(),
}));

describe('UserService', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });
  
  it('ユーザー情報を正しく取得する', async () => {
    const mockUser = { id: 1, name: 'Test User' };
    vi.mocked(fetchUser).mockResolvedValue(mockUser);
    
    const user = await getUserInfo(1);
    
    expect(user).toEqual(mockUser);
    expect(fetchUser).toHaveBeenCalledWith(1);
  });
  
  // スナップショットテスト
  it('正しいUIをレンダリングする', () => {
    const { container } = render(<UserCard user={mockUser} />);
    expect(container).toMatchSnapshot();
  });
});
```

## Playwright (E2Eテスト)

### Playwrightの設定
```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },
    // モバイルテスト
    {
      name: 'Mobile Chrome',
      use: { ...devices['Pixel 5'] },
    },
  ],
});
```

### PlaywrightによるE2Eテスト
```typescript
import { test, expect } from '@playwright/test';

test.describe('ユーザー認証フロー', () => {
  test('ログインして商品を購入する', async ({ page }) => {
    // ページへナビゲート
    await page.goto('/login');
    
    // ログインフォームを埋める
    await page.fill('[data-testid="email-input"]', 'user@example.com');
    await page.fill('[data-testid="password-input"]', 'password123');
    
    // ログインボタンをクリック
    await page.click('[data-testid="login-button"]');
    
    // ダッシュボードへのリダイレクトを待つ
    await page.waitForURL('/dashboard');
    
    // ユーザー名が表示されていることを確認
    await expect(page.locator('[data-testid="user-name"]')).toContainText('Test User');
    
    // 商品を選択
    await page.click('[data-testid="product-1"]');
    
    // カートに追加
    await page.click('[data-testid="add-to-cart"]');
    
    // カートアイコンの数値を確認
    await expect(page.locator('[data-testid="cart-count"]')).toHaveText('1');
    
    // スクリーンショットを撮る
    await page.screenshot({ path: 'cart-added.png' });
  });
  
  test('APIモックを使用したテスト', async ({ page }) => {
    // APIレスポンスをモック
    await page.route('**/api/products', async route => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          { id: 1, name: 'Product 1', price: 100 },
          { id: 2, name: 'Product 2', price: 200 },
        ]),
      });
    });
    
    await page.goto('/products');
    
    // 商品が表示されることを確認
    await expect(page.locator('[data-testid="product-list"] > li')).toHaveCount(2);
  });
});
```

## Testing Library (コンポーネントテスト標準)

### 基本的なテスト構造
テストを明確かつ一貫して整理。

```javascript
// 良い例
describe('Calculator', () => {
  describe('add', () => {
    it('正の数を2つ加算する', () => {
      expect(add(2, 3)).toBe(5);
    });
    
    it('負の数を処理する', () => {
      expect(add(-1, -1)).toBe(-2);
    });
    
    it('数値以外の入力にはNaNを返す', () => {
      expect(add('a', 'b')).toBeNaN();
    });
  });
});

// テスト命名: should + 期待される動作 + 条件
it('ゼロ除算でエラーをスローする', () => {
  expect(() => divide(10, 0)).toThrow('ゼロ除算');
});
```

### モック
ユニットを分離し依存関係を制御。

```javascript
// 良い例 - 外部依存をモック
jest.mock('./api');
import { fetchUser } from './api';

describe('UserService', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });
  
  it('ユーザーデータを取得して変換する', async () => {
    const mockUser = { id: 1, name: 'Alice' };
    fetchUser.mockResolvedValue(mockUser);
    
    const result = await getUserProfile(1);
    
    expect(fetchUser).toHaveBeenCalledWith(1);
    expect(fetchUser).toHaveBeenCalledTimes(1);
    expect(result).toEqual({
      ...mockUser,
      displayName: 'Alice'
    });
  });
});

// 既存メソッドをスパイ
const consoleSpy = jest.spyOn(console, 'log').mockImplementation();
```

## Reactテスト

### コンポーネントテスト
React Testing Libraryでコンポーネントをテスト。

```javascript
// 良い例 - 実装ではなくユーザー動作をテスト
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

describe('LoginForm', () => {
  it('有効な認証情報でフォームを送信する', async () => {
    const handleSubmit = jest.fn();
    render(<LoginForm onSubmit={handleSubmit} />);
    
    const user = userEvent.setup();
    
    await user.type(screen.getByLabelText(/メール/i), 'user@example.com');
    await user.type(screen.getByLabelText(/パスワード/i), 'password123');
    await user.click(screen.getByRole('button', { name: /ログイン/i }));
    
    await waitFor(() => {
      expect(handleSubmit).toHaveBeenCalledWith({
        email: 'user@example.com',
        password: 'password123'
      });
    });
  });
  
  it('無効なメールでエラーを表示する', async () => {
    render(<LoginForm />);
    
    const emailInput = screen.getByLabelText(/メール/i);
    fireEvent.blur(emailInput);
    
    expect(await screen.findByText(/無効なメール/i)).toBeInTheDocument();
  });
});
```

### カスタムフックテスト
フックを単独でテスト。

```javascript
// 良い例
import { renderHook, act } from '@testing-library/react';

describe('useCounter', () => {
  it('カウンターをインクリメントする', () => {
    const { result } = renderHook(() => useCounter());
    
    expect(result.current.count).toBe(0);
    
    act(() => {
      result.current.increment();
    });
    
    expect(result.current.count).toBe(1);
  });
  
  it('初期値にリセットする', () => {
    const { result } = renderHook(() => useCounter(10));
    
    act(() => {
      result.current.increment();
      result.current.reset();
    });
    
    expect(result.current.count).toBe(10);
  });
});
```

## APIテスト

### HTTPリクエストのモック
実際のネットワークリクエストなしでAPIコールをテスト。

```javascript
// 良い例 - MSWでAPIモック
import { rest } from 'msw';
import { setupServer } from 'msw/node';

const server = setupServer(
  rest.get('/api/users/:id', (req, res, ctx) => {
    return res(ctx.json({ id: req.params.id, name: 'テストユーザー' }));
  }),
  
  rest.post('/api/users', (req, res, ctx) => {
    return res(ctx.status(201), ctx.json({ id: 123, ...req.body }));
  })
);

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

it('ユーザーデータを取得する', async () => {
  const user = await fetchUser(1);
  expect(user).toEqual({ id: '1', name: 'テストユーザー' });
});
```

## 統合テスト

### データベーステスト
実際のデータベース操作でテスト。

```javascript
// 良い例 - テストデータベースを使用
describe('UserRepository', () => {
  let db;
  
  beforeAll(async () => {
    db = await createTestDatabase();
  });
  
  afterAll(async () => {
    await db.close();
  });
  
  beforeEach(async () => {
    await db.clean();
  });
  
  it('ユーザーを作成して取得する', async () => {
    const repo = new UserRepository(db);
    
    const created = await repo.create({
      name: 'Alice',
      email: 'alice@example.com'
    });
    
    const retrieved = await repo.findById(created.id);
    
    expect(retrieved).toMatchObject({
      name: 'Alice',
      email: 'alice@example.com'
    });
  });
});
```

## E2Eテスト

### Playwright/Cypressテスト
完全なユーザーフローをテスト。

```javascript
// 良い例 - Playwrightの例
import { test, expect } from '@playwright/test';

test.describe('ユーザー登録', () => {
  test('登録フローを完了する', async ({ page }) => {
    await page.goto('/register');
    
    await page.fill('[name="email"]', 'newuser@example.com');
    await page.fill('[name="password"]', 'SecurePass123!');
    await page.fill('[name="confirmPassword"]', 'SecurePass123!');
    
    await page.click('button[type="submit"]');
    
    await expect(page).toHaveURL('/dashboard');
    await expect(page.locator('h1')).toContainText('ようこそ');
  });
  
  test('バリデーションエラーを処理する', async ({ page }) => {
    await page.goto('/register');
    
    await page.fill('[name="email"]', 'invalid-email');
    await page.click('button[type="submit"]');
    
    await expect(page.locator('.error')).toContainText('無効なメール');
  });
});
```

## テストユーティリティ

### テストデータファクトリー
一貫したテストデータを生成。

```javascript
// 良い例
const createUser = (overrides = {}) => ({
  id: faker.datatype.uuid(),
  name: faker.name.fullName(),
  email: faker.internet.email(),
  createdAt: new Date(),
  ...overrides
});

const createPost = (overrides = {}) => ({
  id: faker.datatype.uuid(),
  title: faker.lorem.sentence(),
  content: faker.lorem.paragraphs(),
  authorId: overrides.authorId || createUser().id,
  ...overrides
});

// 使用例
it('ユーザーの投稿を表示する', () => {
  const user = createUser();
  const posts = Array.from({ length: 5 }, () => 
    createPost({ authorId: user.id })
  );
  
  // テストロジック...
});
```

### カスタムマッチャー
ドメイン固有のアサーションを作成。

```javascript
// 良い例
expect.extend({
  toBeWithinRange(received, floor, ceiling) {
    const pass = received >= floor && received <= ceiling;
    return {
      pass,
      message: () => 
        `${received}が範囲${floor} - ${ceiling}内にあることを期待`
    };
  }
});

// 使用例
it('範囲内の乱数を生成する', () => {
  const result = randomInRange(1, 10);
  expect(result).toBeWithinRange(1, 10);
});
```

## パフォーマンステスト

### ベンチマークテスト
パフォーマンスを測定してアサート。

```javascript
// 良い例
describe('パフォーマンス', () => {
  it('時間制限内に大規模データセットを処理する', () => {
    const largeArray = Array.from({ length: 10000 }, (_, i) => i);
    
    const start = performance.now();
    const result = processArray(largeArray);
    const duration = performance.now() - start;
    
    expect(duration).toBeLessThan(100); // 100ms制限
    expect(result).toHaveLength(10000);
  });
  
  it('メモリ制限を超えない', () => {
    const initialMemory = process.memoryUsage().heapUsed;
    
    processLargeData();
    
    const finalMemory = process.memoryUsage().heapUsed;
    const memoryIncrease = (finalMemory - initialMemory) / 1024 / 1024;
    
    expect(memoryIncrease).toBeLessThan(50); // 50MB制限
  });
});
```

## ベストプラクティスチェックリスト

- [ ] コードの前または並行してテストを書く（TDD/BDD）
- [ ] 実装詳細ではなく動作をテスト
- [ ] 説明的なテスト名を使用
- [ ] テストを独立して分離
- [ ] 外部依存をモック
- [ ] テストデータファクトリーを使用
- [ ] テスト後のクリーンアップ（teardown）
- [ ] エッジケースとエラーシナリオをテスト
- [ ] 高いコードカバレッジを維持（80%以上）
- [ ] CI/CDパイプラインでテストを実行
- [ ] スナップショットテストは控えめに使用
- [ ] テストを高速で決定的に保つ