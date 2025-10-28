---
name: e2e-testing-patterns
description: PlaywrightとCypressを使用したエンドツーエンドテストをマスターし、バグを捕捉し、信頼性を向上させ、高速デプロイメントを可能にする信頼性の高いテストスイートを構築。E2Eテストの実装、不安定なテストのデバッグ、テスト基準の確立時に使用。
---

> **[English](../../../../../../plugins/developer-essentials/skills/e2e-testing-patterns/SKILL.md)** | **日本語**

# E2Eテストパターン

迅速なコード出荷の信頼性を提供し、ユーザーより先にリグレッションを捕捉する、信頼性が高く、高速で、保守可能なエンドツーエンドテストスイートを構築します。

## このスキルを使用するタイミング

- エンドツーエンドテスト自動化の実装
- 不安定または信頼性のないテストのデバッグ
- 重要なユーザーワークフローのテスト
- CI/CDテストパイプラインのセットアップ
- 複数ブラウザでのテスト
- アクセシビリティ要件の検証
- レスポンシブデザインのテスト
- E2Eテスト基準の確立

## コア概念

### 1. E2Eテストの基礎

**E2Eでテストすべきもの：**
- 重要なユーザージャーニー（ログイン、チェックアウト、サインアップ）
- 複雑なインタラクション（ドラッグアンドドロップ、複数ステップフォーム）
- クロスブラウザ互換性
- 実際のAPI統合
- 認証フロー

**E2Eでテストすべきでないもの：**
- ユニットレベルのロジック（ユニットテストを使用）
- API契約（統合テストを使用）
- エッジケース（遅すぎる）
- 内部実装の詳細

### 2. テスト哲学

**テストピラミッド：**
```
        /\
       /E2E\         ← 少数、重要なパスに焦点
      /─────\
     /統合  \        ← より多く、コンポーネント間のやり取りをテスト
    /────────\
   /ユニットテスト\  ← 多数、高速、分離
  /────────────\
```

**ベストプラクティス：**
- 実装ではなくユーザー行動をテスト
- テストを独立させる
- テストを決定論的にする
- 速度を最適化
- CSSセレクターではなくdata-testidを使用

## Playwrightパターン

### セットアップと設定

```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
    testDir: './e2e',
    timeout: 30000,
    expect: {
        timeout: 5000,
    },
    fullyParallel: true,
    forbidOnly: !!process.env.CI,
    retries: process.env.CI ? 2 : 0,
    workers: process.env.CI ? 1 : undefined,
    reporter: [
        ['html'],
        ['junit', { outputFile: 'results.xml' }],
    ],
    use: {
        baseURL: 'http://localhost:3000',
        trace: 'on-first-retry',
        screenshot: 'only-on-failure',
        video: 'retain-on-failure',
    },
    projects: [
        { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
        { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
        { name: 'webkit', use: { ...devices['Desktop Safari'] } },
        { name: 'mobile', use: { ...devices['iPhone 13'] } },
    ],
});
```

### パターン1：ページオブジェクトモデル

```typescript
// pages/LoginPage.ts
import { Page, Locator } from '@playwright/test';

export class LoginPage {
    readonly page: Page;
    readonly emailInput: Locator;
    readonly passwordInput: Locator;
    readonly loginButton: Locator;
    readonly errorMessage: Locator;

    constructor(page: Page) {
        this.page = page;
        this.emailInput = page.getByLabel('Email');
        this.passwordInput = page.getByLabel('Password');
        this.loginButton = page.getByRole('button', { name: 'Login' });
        this.errorMessage = page.getByRole('alert');
    }

    async goto() {
        await this.page.goto('/login');
    }

    async login(email: string, password: string) {
        await this.emailInput.fill(email);
        await this.passwordInput.fill(password);
        await this.loginButton.click();
    }

    async getErrorMessage(): Promise<string> {
        return await this.errorMessage.textContent() ?? '';
    }
}

// ページオブジェクトを使用したテスト
import { test, expect } from '@playwright/test';
import { LoginPage } from './pages/LoginPage';

test('ログイン成功', async ({ page }) => {
    const loginPage = new LoginPage(page);
    await loginPage.goto();
    await loginPage.login('user@example.com', 'password123');

    await expect(page).toHaveURL('/dashboard');
    await expect(page.getByRole('heading', { name: 'Dashboard' }))
        .toBeVisible();
});

test('ログイン失敗時エラー表示', async ({ page }) => {
    const loginPage = new LoginPage(page);
    await loginPage.goto();
    await loginPage.login('invalid@example.com', 'wrong');

    const error = await loginPage.getErrorMessage();
    expect(error).toContain('Invalid credentials');
});
```

### パターン2：テストデータ用フィクスチャ

```typescript
// fixtures/test-data.ts
import { test as base } from '@playwright/test';

type TestData = {
    testUser: {
        email: string;
        password: string;
        name: string;
    };
    adminUser: {
        email: string;
        password: string;
    };
};

export const test = base.extend<TestData>({
    testUser: async ({}, use) => {
        const user = {
            email: `test-${Date.now()}@example.com`,
            password: 'Test123!@#',
            name: 'Test User',
        };
        // セットアップ：データベースにユーザーを作成
        await createTestUser(user);
        await use(user);
        // クリーンアップ：ユーザーを削除
        await deleteTestUser(user.email);
    },

    adminUser: async ({}, use) => {
        await use({
            email: 'admin@example.com',
            password: process.env.ADMIN_PASSWORD!,
        });
    },
});

// テストでの使用
import { test } from './fixtures/test-data';

test('ユーザーがプロフィールを更新できる', async ({ page, testUser }) => {
    await page.goto('/login');
    await page.getByLabel('Email').fill(testUser.email);
    await page.getByLabel('Password').fill(testUser.password);
    await page.getByRole('button', { name: 'Login' }).click();

    await page.goto('/profile');
    await page.getByLabel('Name').fill('Updated Name');
    await page.getByRole('button', { name: 'Save' }).click();

    await expect(page.getByText('Profile updated')).toBeVisible();
});
```

### パターン3：待機戦略

```typescript
// ❌ 悪い例：固定タイムアウト
await page.waitForTimeout(3000);  // 不安定！

// ✅ 良い例：特定の条件を待つ
await page.waitForLoadState('networkidle');
await page.waitForURL('/dashboard');
await page.waitForSelector('[data-testid=\"user-profile\"]');

// ✅ より良い例：アサーション付き自動待機
await expect(page.getByText('Welcome')).toBeVisible();
await expect(page.getByRole('button', { name: 'Submit' }))
    .toBeEnabled();

// APIレスポンスを待つ
const responsePromise = page.waitForResponse(
    response => response.url().includes('/api/users') && response.status() === 200
);
await page.getByRole('button', { name: 'Load Users' }).click();
const response = await responsePromise;
const data = await response.json();
expect(data.users).toHaveLength(10);

// 複数条件を待つ
await Promise.all([
    page.waitForURL('/success'),
    page.waitForLoadState('networkidle'),
    expect(page.getByText('Payment successful')).toBeVisible(),
]);
```

### パターン4：ネットワークモッキングとインターセプト

```typescript
// APIレスポンスをモック
test('API失敗時エラー表示', async ({ page }) => {
    await page.route('**/api/users', route => {
        route.fulfill({
            status: 500,
            contentType: 'application/json',
            body: JSON.stringify({ error: 'Internal Server Error' }),
        });
    });

    await page.goto('/users');
    await expect(page.getByText('Failed to load users')).toBeVisible();
});

// リクエストをインターセプトして変更
test('APIリクエストを変更可能', async ({ page }) => {
    await page.route('**/api/users', async route => {
        const request = route.request();
        const postData = JSON.parse(request.postData() || '{}');

        // リクエストを変更
        postData.role = 'admin';

        await route.continue({
            postData: JSON.stringify(postData),
        });
    });

    // テスト継続...
});

// サードパーティサービスをモック
test('モックStripeで決済フロー', async ({ page }) => {
    await page.route('**/api/stripe/**', route => {
        route.fulfill({
            status: 200,
            body: JSON.stringify({
                id: 'mock_payment_id',
                status: 'succeeded',
            }),
        });
    });

    // モックレスポンスで決済フローをテスト
});
```

## Cypressパターン

### セットアップと設定

```typescript
// cypress.config.ts
import { defineConfig } from 'cypress';

export default defineConfig({
    e2e: {
        baseUrl: 'http://localhost:3000',
        viewportWidth: 1280,
        viewportHeight: 720,
        video: false,
        screenshotOnRunFailure: true,
        defaultCommandTimeout: 10000,
        requestTimeout: 10000,
        setupNodeEvents(on, config) {
            // ノードイベントリスナーを実装
        },
    },
});
```

### パターン1：カスタムコマンド

```typescript
// cypress/support/commands.ts
declare global {
    namespace Cypress {
        interface Chainable {
            login(email: string, password: string): Chainable<void>;
            createUser(userData: UserData): Chainable<User>;
            dataCy(value: string): Chainable<JQuery<HTMLElement>>;
        }
    }
}

Cypress.Commands.add('login', (email: string, password: string) => {
    cy.visit('/login');
    cy.get('[data-testid=\"email\"]').type(email);
    cy.get('[data-testid=\"password\"]').type(password);
    cy.get('[data-testid=\"login-button\"]').click();
    cy.url().should('include', '/dashboard');
});

Cypress.Commands.add('createUser', (userData: UserData) => {
    return cy.request('POST', '/api/users', userData)
        .its('body');
});

Cypress.Commands.add('dataCy', (value: string) => {
    return cy.get(`[data-cy=\"${value}\"]`);
});

// 使用例
cy.login('user@example.com', 'password');
cy.dataCy('submit-button').click();
```

### パターン2：Cypressインターセプト

```typescript
// API呼び出しをモック
cy.intercept('GET', '/api/users', {
    statusCode: 200,
    body: [
        { id: 1, name: 'John' },
        { id: 2, name: 'Jane' },
    ],
}).as('getUsers');

cy.visit('/users');
cy.wait('@getUsers');
cy.get('[data-testid=\"user-list\"]').children().should('have.length', 2);

// レスポンスを変更
cy.intercept('GET', '/api/users', (req) => {
    req.reply((res) => {
        // レスポンスを変更
        res.body.users = res.body.users.slice(0, 5);
        res.send();
    });
});

// 遅いネットワークをシミュレート
cy.intercept('GET', '/api/data', (req) => {
    req.reply((res) => {
        res.delay(3000);  // 3秒遅延
        res.send();
    });
});
```

## 高度なパターン

### パターン1：ビジュアルリグレッションテスト

```typescript
// Playwrightで
import { test, expect } from '@playwright/test';

test('ホームページが正しく表示される', async ({ page }) => {
    await page.goto('/');
    await expect(page).toHaveScreenshot('homepage.png', {
        fullPage: true,
        maxDiffPixels: 100,
    });
});

test('ボタンの全状態', async ({ page }) => {
    await page.goto('/components');

    const button = page.getByRole('button', { name: 'Submit' });

    // デフォルト状態
    await expect(button).toHaveScreenshot('button-default.png');

    // ホバー状態
    await button.hover();
    await expect(button).toHaveScreenshot('button-hover.png');

    // 無効状態
    await button.evaluate(el => el.setAttribute('disabled', 'true'));
    await expect(button).toHaveScreenshot('button-disabled.png');
});
```

### パターン2：シャーディングによる並列テスト

```typescript
// playwright.config.ts
export default defineConfig({
    projects: [
        {
            name: 'shard-1',
            use: { ...devices['Desktop Chrome'] },
            grepInvert: /@slow/,
            shard: { current: 1, total: 4 },
        },
        {
            name: 'shard-2',
            use: { ...devices['Desktop Chrome'] },
            shard: { current: 2, total: 4 },
        },
        // ... その他のシャード
    ],
});

// CIで実行
// npx playwright test --shard=1/4
// npx playwright test --shard=2/4
```

### パターン3：アクセシビリティテスト

```typescript
// インストール: npm install @axe-core/playwright
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test('ページにアクセシビリティ違反がないこと', async ({ page }) => {
    await page.goto('/');

    const accessibilityScanResults = await new AxeBuilder({ page })
        .exclude('#third-party-widget')
        .analyze();

    expect(accessibilityScanResults.violations).toEqual([]);
});

test('フォームがアクセシブル', async ({ page }) => {
    await page.goto('/signup');

    const results = await new AxeBuilder({ page })
        .include('form')
        .analyze();

    expect(results.violations).toEqual([]);
});
```

## ベストプラクティス

1. **データ属性を使用**：安定したセレクター用に`data-testid`または`data-cy`
2. **脆弱なセレクターを避ける**：CSSクラスやDOM構造に依存しない
3. **ユーザー行動をテスト**：クリック、入力、表示 - 実装の詳細ではない
4. **テストを独立させる**：各テストは分離して実行すべき
5. **テストデータをクリーンアップ**：各テストでテストデータを作成・破棄
6. **ページオブジェクトを使用**：ページロジックをカプセル化
7. **意味のあるアサーション**：実際のユーザーに見える動作を確認
8. **速度を最適化**：可能な限りモック、並列実行

```typescript
// ❌ 悪いセレクター
cy.get('.btn.btn-primary.submit-button').click();
cy.get('div > form > div:nth-child(2) > input').type('text');

// ✅ 良いセレクター
cy.getByRole('button', { name: 'Submit' }).click();
cy.getByLabel('Email address').type('user@example.com');
cy.get('[data-testid=\"email-input\"]').type('user@example.com');
```

## よくある落とし穴

- **不安定なテスト**：固定タイムアウトではなく適切な待機を使用
- **遅いテスト**：外部APIをモック、並列実行を使用
- **過剰テスト**：すべてのエッジケースをE2Eでテストしない
- **結合したテスト**：テストは互いに依存すべきでない
- **貧弱なセレクター**：CSSクラスやnth-childを避ける
- **クリーンアップなし**：各テスト後にテストデータをクリーンアップ
- **実装のテスト**：内部ではなくユーザー行動をテスト

## 失敗したテストのデバッグ

```typescript
// Playwrightデバッグ
// 1. ヘッドモードで実行
npx playwright test --headed

// 2. デバッグモードで実行
npx playwright test --debug

// 3. トレースビューアーを使用
await page.screenshot({ path: 'screenshot.png' });
await page.video()?.saveAs('video.webm');

// 4. より良いレポートのためにtest.stepを追加
test('チェックアウトフロー', async ({ page }) => {
    await test.step('カートにアイテムを追加', async () => {
        await page.goto('/products');
        await page.getByRole('button', { name: 'Add to Cart' }).click();
    });

    await test.step('チェックアウトに進む', async () => {
        await page.goto('/cart');
        await page.getByRole('button', { name: 'Checkout' }).click();
    });
});

// 5. ページ状態を検査
await page.pause();  // 実行を一時停止、インスペクターを開く
```

## リソース

- **references/playwright-best-practices.md**：Playwright固有のパターン
- **references/cypress-best-practices.md**：Cypress固有のパターン
- **references/flaky-test-debugging.md**：信頼性のないテストのデバッグ
- **assets/e2e-testing-checklist.md**：E2Eでテストすべきこと
- **assets/selector-strategies.md**：信頼性の高いセレクターの見つけ方
- **scripts/test-analyzer.ts**：テストの不安定性と所要時間を分析
