# CI/CD Patterns

継続的インテグレーション/継続的デプロイメントのパターンとベストプラクティス。

## GitHub Actions

### 基本的なワークフロー
```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]
  workflow_dispatch:

env:
  NODE_VERSION: '18'
  PNPM_VERSION: '8'

jobs:
  # 依存関係のキャッシュ
  setup:
    runs-on: ubuntu-latest
    outputs:
      cache-key: ${{ steps.cache-keys.outputs.key }}
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
      
      - name: Setup pnpm
        uses: pnpm/action-setup@v2
        with:
          version: ${{ env.PNPM_VERSION }}
      
      - name: Get pnpm store directory
        id: pnpm-cache
        shell: bash
        run: |
          echo "STORE_PATH=$(pnpm store path)" >> $GITHUB_OUTPUT
      
      - name: Setup pnpm cache
        uses: actions/cache@v3
        with:
          path: ${{ steps.pnpm-cache.outputs.STORE_PATH }}
          key: ${{ runner.os }}-pnpm-store-${{ hashFiles('**/pnpm-lock.yaml') }}
          restore-keys: |
            ${{ runner.os }}-pnpm-store-
      
      - name: Install dependencies
        run: pnpm install --frozen-lockfile

  # リント & フォーマット
  lint:
    needs: setup
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/setup-node
      
      - name: Run ESLint
        run: pnpm lint
      
      - name: Check formatting
        run: pnpm format:check
      
      - name: Type check
        run: pnpm type-check

  # テスト実行
  test:
    needs: setup
    runs-on: ubuntu-latest
    strategy:
      matrix:
        shard: [1, 2, 3, 4]
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/setup-node
      
      - name: Run tests
        run: pnpm test --shard=${{ matrix.shard }}/4 --coverage
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: ./coverage/lcov.info
          flags: unittests
          name: codecov-${{ matrix.shard }}

  # ビルド
  build:
    needs: [lint, test]
    runs-on: ubuntu-latest
    strategy:
      matrix:
        environment: [development, staging, production]
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/setup-node
      
      - name: Build application
        run: pnpm build --mode ${{ matrix.environment }}
        env:
          VITE_API_URL: ${{ secrets[format('VITE_API_URL_{0}', matrix.environment)] }}
      
      - name: Upload build artifacts
        uses: actions/upload-artifact@v3
        with:
          name: build-${{ matrix.environment }}
          path: dist/
          retention-days: 7

  # デプロイ（メインブランチのみ）
  deploy:
    if: github.ref == 'refs/heads/main'
    needs: build
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v4
      
      - name: Download build artifacts
        uses: actions/download-artifact@v3
        with:
          name: build-production
          path: dist/
      
      - name: Deploy to Vercel
        uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          vercel-args: '--prod'
```

### 複合アクション
```yaml
# .github/actions/setup-node/action.yml
name: 'Setup Node.js environment'
description: 'Setup Node.js and restore dependencies'

runs:
  using: 'composite'
  steps:
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version-file: '.nvmrc'
        cache: 'pnpm'
    
    - name: Setup pnpm
      uses: pnpm/action-setup@v2
      with:
        version: 8
        run_install: |
          - recursive: true
            args: [--frozen-lockfile, --strict-peer-dependencies]
    
    - name: Cache Playwright browsers
      if: inputs.playwright == 'true'
      uses: actions/cache@v3
      with:
        path: ~/.cache/ms-playwright
        key: playwright-${{ runner.os }}-${{ hashFiles('**/package-lock.json') }}
```

## Docker 統合

### マルチステージビルド
```dockerfile
# Build stage
FROM node:18-alpine AS builder
WORKDIR /app

# Install pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

# Copy package files
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

# Copy source and build
COPY . .
RUN pnpm build

# Production stage
FROM node:18-alpine AS runner
WORKDIR /app

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001

# Copy built application
COPY --from=builder --chown=nextjs:nodejs /app/dist ./dist
COPY --from=builder --chown=nextjs:nodejs /app/package.json ./

# Install production dependencies only
RUN pnpm install --prod --frozen-lockfile

USER nextjs
EXPOSE 3000

CMD ["node", "dist/index.js"]
```

### Docker Compose for CI
```yaml
version: '3.8'

services:
  app:
    build:
      context: .
      target: builder
    command: pnpm test:ci
    environment:
      NODE_ENV: test
      DATABASE_URL: postgresql://user:pass@postgres:5432/testdb
      REDIS_URL: redis://redis:6379
    depends_on:
      - postgres
      - redis
    volumes:
      - .:/app
      - /app/node_modules

  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
      POSTGRES_DB: testdb
    tmpfs:
      - /var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes
    tmpfs:
      - /data

  e2e:
    build:
      context: .
      target: builder
    command: pnpm test:e2e
    environment:
      PLAYWRIGHT_BASE_URL: http://app:3000
    depends_on:
      - app
    volumes:
      - ./test-results:/app/test-results
```

## 環境別設定

### 環境変数管理
```typescript
// config/env.ts
import { z } from 'zod';

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']),
  PORT: z.string().transform(Number).default('3000'),
  DATABASE_URL: z.string().url(),
  REDIS_URL: z.string().url(),
  JWT_SECRET: z.string().min(32),
  API_KEY: z.string(),
  SENTRY_DSN: z.string().url().optional(),
  LOG_LEVEL: z.enum(['debug', 'info', 'warn', 'error']).default('info')
});

export const env = envSchema.parse(process.env);

// 環境別設定
export const config = {
  isDevelopment: env.NODE_ENV === 'development',
  isProduction: env.NODE_ENV === 'production',
  isTest: env.NODE_ENV === 'test',
  
  server: {
    port: env.PORT,
    corsOrigins: env.NODE_ENV === 'production'
      ? ['https://app.example.com']
      : ['http://localhost:3000']
  },
  
  database: {
    url: env.DATABASE_URL,
    ssl: env.NODE_ENV === 'production',
    poolSize: env.NODE_ENV === 'production' ? 20 : 5
  },
  
  redis: {
    url: env.REDIS_URL,
    ttl: env.NODE_ENV === 'production' ? 3600 : 60
  },
  
  security: {
    jwtSecret: env.JWT_SECRET,
    bcryptRounds: env.NODE_ENV === 'production' ? 12 : 4
  }
};
```

## デプロイメント戦略

### Blue-Green デプロイメント
```yaml
# Kubernetes manifests
apiVersion: v1
kind: Service
metadata:
  name: app-service
spec:
  selector:
    app: myapp
    version: green  # または blue
  ports:
    - port: 80
      targetPort: 3000

---
# Blue deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-blue
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
      version: blue
  template:
    metadata:
      labels:
        app: myapp
        version: blue
    spec:
      containers:
      - name: app
        image: myapp:v1.0.0
        ports:
        - containerPort: 3000

---
# Green deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-green
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
      version: green
  template:
    metadata:
      labels:
        app: myapp
        version: green
    spec:
      containers:
      - name: app
        image: myapp:v2.0.0
        ports:
        - containerPort: 3000
```

### カナリアリリース
```typescript
// Feature flag による段階的リリース
import { FeatureFlag } from '@/lib/feature-flag';

const featureFlags = new FeatureFlag({
  newCheckoutFlow: {
    enabled: true,
    rolloutPercentage: 10, // 10%のユーザーに公開
    allowList: ['beta-tester@example.com'],
    denyList: [],
    startDate: new Date('2024-01-01'),
    endDate: new Date('2024-02-01')
  }
});

// 使用例
export function CheckoutPage({ user }: { user: User }) {
  if (featureFlags.isEnabled('newCheckoutFlow', user)) {
    return <NewCheckoutFlow />;
  }
  
  return <LegacyCheckoutFlow />;
}
```

## モニタリング & ロールバック

### ヘルスチェック
```typescript
// health/health.controller.ts
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    version: process.env.APP_VERSION || 'unknown'
  });
});

app.get('/health/ready', async (req, res) => {
  try {
    // 依存サービスチェック
    await Promise.all([
      db.raw('SELECT 1'),
      redis.ping(),
      checkExternalAPI()
    ]);
    
    res.json({ status: 'ready' });
  } catch (error) {
    res.status(503).json({
      status: 'not ready',
      error: error.message
    });
  }
});
```

### 自動ロールバック
```yaml
# GitHub Actions でのロールバック
name: Auto Rollback

on:
  workflow_run:
    workflows: ["Deploy"]
    types: [completed]

jobs:
  monitor:
    runs-on: ubuntu-latest
    if: ${{ github.event.workflow_run.conclusion == 'success' }}
    steps:
      - name: Wait for deployment
        run: sleep 60
      
      - name: Check health
        id: health
        run: |
          for i in {1..10}; do
            if curl -f https://api.example.com/health; then
              echo "Health check passed"
              exit 0
            fi
            echo "Health check failed, attempt $i"
            sleep 30
          done
          exit 1
      
      - name: Rollback on failure
        if: failure()
        run: |
          echo "Health checks failed, initiating rollback"
          # Vercel rollback
          vercel rollback --token=${{ secrets.VERCEL_TOKEN }}
```

## シークレット管理

### GitHub Secrets 統合
```yaml
# .github/workflows/secrets.yml
name: Sync Secrets

on:
  schedule:
    - cron: '0 0 * * 0' # 週次
  workflow_dispatch:

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - name: Sync from Vault
        env:
          VAULT_ADDR: ${{ secrets.VAULT_ADDR }}
          VAULT_TOKEN: ${{ secrets.VAULT_TOKEN }}
        run: |
          # Vault から秘密情報を取得
          vault kv get -format=json secret/app | \
            jq -r '.data.data | to_entries[] | "::add-mask::\(.value)"'
          
          # GitHub Secrets を更新
          gh secret set DATABASE_URL --body="$DATABASE_URL"
          gh secret set API_KEY --body="$API_KEY"
```

## チェックリスト
- [ ] CI/CDパイプライン構築
- [ ] 自動テスト統合
- [ ] ビルド最適化
- [ ] 環境別設定管理
- [ ] デプロイメント戦略選択
- [ ] ヘルスチェック実装
- [ ] ロールバック手順
- [ ] シークレット管理
- [ ] モニタリング設定
- [ ] 通知設定