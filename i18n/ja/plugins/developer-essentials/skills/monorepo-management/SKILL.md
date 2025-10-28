---
name: monorepo-management
description: Turborepo、Nx、pnpmワークスペースを使用したモノレポ管理をマスターし、最適化されたビルドと依存関係管理で効率的でスケーラブルなマルチパッケージリポジトリを構築。モノレポのセットアップ、ビルドの最適化、共有依存関係の管理時に使用。
---

> **[English](../../../../../../plugins/developer-essentials/skills/monorepo-management/SKILL.md)** | **日本語**

# モノレポ管理

コード共有、一貫したツール、複数のパッケージとアプリケーション間でのアトミックな変更を可能にする、効率的でスケーラブルなモノレポを構築します。

## このスキルを使用するタイミング

- 新しいモノレポプロジェクトのセットアップ
- マルチリポジトリからモノレポへの移行
- ビルドとテストパフォーマンスの最適化
- 共有依存関係の管理
- コード共有戦略の実装
- モノレポ用CI/CDのセットアップ
- パッケージのバージョニングと公開
- モノレポ固有の問題のデバッグ

## コア概念

### 1. なぜモノレポ？

**利点：**
- 共有コードと依存関係
- プロジェクト間でのアトミックコミット
- 一貫したツールと基準
- より容易なリファクタリング
- 簡素化された依存関係管理
- より良いコード可視性

**課題：**
- スケールでのビルドパフォーマンス
- CI/CDの複雑さ
- アクセス制御
- 大きなGitリポジトリ

### 2. モノレポツール

**パッケージマネージャー：**
- pnpm workspaces（推奨）
- npm workspaces
- Yarn workspaces

**ビルドシステム：**
- Turborepo（ほとんどの場合推奨）
- Nx（機能豊富、複雑）
- Lerna（古い、メンテナンスモード）

## Turborepoセットアップ

### 初期セットアップ

```bash
# 新しいモノレポを作成
npx create-turbo@latest my-monorepo
cd my-monorepo

# 構造：
# apps/
#   web/          - Next.jsアプリ
#   docs/         - ドキュメントサイト
# packages/
#   ui/           - 共有UIコンポーネント
#   config/       - 共有設定
#   tsconfig/     - 共有TypeScript設定
# turbo.json      - Turborepo設定
# package.json    - ルートpackage.json
```

### 設定

```json
// turbo.json
{
  "$schema": "https://turbo.build/schema.json",
  "globalDependencies": ["**/.env.*local"],
  "pipeline": {
    "build": {
      // ビルドは依存関係が先にビルドされることに依存
      "dependsOn": ["^build"],

      // これらの出力をキャッシュ
      "outputs": ["dist/**", ".next/**", "!.next/cache/**"]
    },
    "test": {
      // ビルドに依存
      "dependsOn": ["build"],
      "outputs": ["coverage/**"]
    },
    "lint": {
      "outputs": []
    },
    "dev": {
      "cache": false,
      "persistent": true
    },
    "type-check": {
      "dependsOn": ["^build"],
      "outputs": []
    }
  }
}
```

```json
// package.json（ルート）
{
  "name": "my-monorepo",
  "private": true,
  "workspaces": [
    "apps/*",
    "packages/*"
  ],
  "scripts": {
    "build": "turbo run build",
    "dev": "turbo run dev",
    "test": "turbo run test",
    "lint": "turbo run lint",
    "format": "prettier --write \"**/*.{ts,tsx,md}\"",
    "clean": "turbo run clean && rm -rf node_modules"
  },
  "devDependencies": {
    "turbo": "^1.10.0",
    "prettier": "^3.0.0",
    "typescript": "^5.0.0"
  },
  "packageManager": "pnpm@8.0.0"
}
```

### パッケージ構造

```json
// packages/ui/package.json
{
  "name": "@repo/ui",
  "version": "0.0.0",
  "private": true,
  "main": "./dist/index.js",
  "types": "./dist/index.d.ts",
  "exports": {
    ".": {
      "import": "./dist/index.js",
      "types": "./dist/index.d.ts"
    },
    "./button": {
      "import": "./dist/button.js",
      "types": "./dist/button.d.ts"
    }
  },
  "scripts": {
    "build": "tsup src/index.ts --format esm,cjs --dts",
    "dev": "tsup src/index.ts --format esm,cjs --dts --watch",
    "lint": "eslint src/",
    "type-check": "tsc --noEmit"
  },
  "devDependencies": {
    "@repo/tsconfig": "workspace:*",
    "tsup": "^7.0.0",
    "typescript": "^5.0.0"
  },
  "dependencies": {
    "react": "^18.2.0"
  }
}
```

## pnpmワークスペース

### セットアップ

```yaml
# pnpm-workspace.yaml
packages:
  - 'apps/*'
  - 'packages/*'
  - 'tools/*'
```

```json
// .npmrc
# 共有依存関係を巻き上げ
shamefully-hoist=true

# 厳格なピア依存関係
auto-install-peers=true
strict-peer-dependencies=true

# パフォーマンス
store-dir=~/.pnpm-store
```

### 依存関係管理

```bash
# 特定パッケージに依存関係をインストール
pnpm add react --filter @repo/ui
pnpm add -D typescript --filter @repo/ui

# ワークスペース依存関係をインストール
pnpm add @repo/ui --filter web

# すべてのパッケージにインストール
pnpm add -D eslint -w

# すべての依存関係を更新
pnpm update -r

# 依存関係を削除
pnpm remove react --filter @repo/ui
```

### スクリプト

```bash
# 特定パッケージでスクリプトを実行
pnpm --filter web dev
pnpm --filter @repo/ui build

# すべてのパッケージで実行
pnpm -r build
pnpm -r test

# 並列で実行
pnpm -r --parallel dev

# パターンでフィルター
pnpm --filter \"@repo/*\" build
pnpm --filter \"...web\" build  # webと依存関係をビルド
```

## Nxモノレポ

### セットアップ

```bash
# Nxモノレポを作成
npx create-nx-workspace@latest my-org

# アプリケーションを生成
nx generate @nx/react:app my-app
nx generate @nx/next:app my-next-app

# ライブラリを生成
nx generate @nx/react:lib ui-components
nx generate @nx/js:lib utils
```

### 設定

```json
// nx.json
{
  "extends": "nx/presets/npm.json",
  "$schema": "./node_modules/nx/schemas/nx-schema.json",
  "targetDefaults": {
    "build": {
      "dependsOn": ["^build"],
      "inputs": ["production", "^production"],
      "cache": true
    },
    "test": {
      "inputs": ["default", "^production", "{workspaceRoot}/jest.preset.js"],
      "cache": true
    },
    "lint": {
      "inputs": ["default", "{workspaceRoot}/.eslintrc.json"],
      "cache": true
    }
  },
  "namedInputs": {
    "default": ["{projectRoot}/**/*", "sharedGlobals"],
    "production": [
      "default",
      "!{projectRoot}/**/?(*.)+(spec|test).[jt]s?(x)?(.snap)",
      "!{projectRoot}/tsconfig.spec.json"
    ],
    "sharedGlobals": []
  }
}
```

### タスク実行

```bash
# 特定プロジェクトでタスクを実行
nx build my-app
nx test ui-components
nx lint utils

# 影響を受けるプロジェクトで実行
nx affected:build
nx affected:test --base=main

# 依存関係を視覚化
nx graph

# 並列で実行
nx run-many --target=build --all --parallel=3
```

## 共有設定

### TypeScript設定

```json
// packages/tsconfig/base.json
{
  "compilerOptions": {
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "module": "ESNext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "incremental": true,
    "declaration": true
  },
  "exclude": ["node_modules"]
}

// packages/tsconfig/react.json
{
  "extends": "./base.json",
  "compilerOptions": {
    "jsx": "react-jsx",
    "lib": ["ES2022", "DOM", "DOM.Iterable"]
  }
}

// apps/web/tsconfig.json
{
  "extends": "@repo/tsconfig/react.json",
  "compilerOptions": {
    "outDir": "dist",
    "rootDir": "src"
  },
  "include": ["src"],
  "exclude": ["node_modules", "dist"]
}
```

### ESLint設定

```javascript
// packages/config/eslint-preset.js
module.exports = {
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
    'plugin:react/recommended',
    'plugin:react-hooks/recommended',
    'prettier',
  ],
  plugins: ['@typescript-eslint', 'react', 'react-hooks'],
  parser: '@typescript-eslint/parser',
  parserOptions: {
    ecmaVersion: 2022,
    sourceType: 'module',
    ecmaFeatures: {
      jsx: true,
    },
  },
  settings: {
    react: {
      version: 'detect',
    },
  },
  rules: {
    '@typescript-eslint/no-unused-vars': 'error',
    'react/react-in-jsx-scope': 'off',
  },
};

// apps/web/.eslintrc.js
module.exports = {
  extends: ['@repo/config/eslint-preset'],
  rules: {
    // アプリ固有のルール
  },
};
```

## コード共有パターン

### パターン1：共有UIコンポーネント

```typescript
// packages/ui/src/button.tsx
import * as React from 'react';

export interface ButtonProps {
  variant?: 'primary' | 'secondary';
  children: React.ReactNode;
  onClick?: () => void;
}

export function Button({ variant = 'primary', children, onClick }: ButtonProps) {
  return (
    <button
      className={`btn btn-${variant}`}
      onClick={onClick}
    >
      {children}
    </button>
  );
}

// packages/ui/src/index.ts
export { Button, type ButtonProps } from './button';
export { Input, type InputProps } from './input';

// apps/web/src/app.tsx
import { Button } from '@repo/ui';

export function App() {
  return <Button variant="primary">クリック</Button>;
}
```

### パターン2：共有ユーティリティ

```typescript
// packages/utils/src/string.ts
export function capitalize(str: string): string {
  return str.charAt(0).toUpperCase() + str.slice(1);
}

export function truncate(str: string, length: number): string {
  return str.length > length ? str.slice(0, length) + '...' : str;
}

// packages/utils/src/index.ts
export * from './string';
export * from './array';
export * from './date';

// アプリでの使用
import { capitalize, truncate } from '@repo/utils';
```

### パターン3：共有型

```typescript
// packages/types/src/user.ts
export interface User {
  id: string;
  email: string;
  name: string;
  role: 'admin' | 'user';
}

export interface CreateUserInput {
  email: string;
  name: string;
  password: string;
}

// フロントエンドとバックエンド両方で使用
import type { User, CreateUserInput } from '@repo/types';
```

## ビルド最適化

### Turborepoキャッシング

```json
// turbo.json
{
  "pipeline": {
    "build": {
      // ビルドは依存関係が先にビルドされることに依存
      "dependsOn": ["^build"],

      // これらの出力をキャッシュ
      "outputs": ["dist/**", ".next/**"],

      // これらの入力に基づいてキャッシュ（デフォルト：すべてのファイル）
      "inputs": ["src/**/*.tsx", "src/**/*.ts", "package.json"]
    },
    "test": {
      // テストを並列実行、ビルドに依存しない
      "cache": true,
      "outputs": ["coverage/**"]
    }
  }
}
```

### リモートキャッシング

```bash
# Turborepoリモートキャッシュ（Vercel）
npx turbo login
npx turbo link

# カスタムリモートキャッシュ
# turbo.json
{
  "remoteCache": {
    "signature": true,
    "enabled": true
  }
}
```

## モノレポ用CI/CD

### GitHub Actions

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0  # Nx affectedコマンド用

      - uses: pnpm/action-setup@v2
        with:
          version: 8

      - uses: actions/setup-node@v3
        with:
          node-version: 18
          cache: 'pnpm'

      - name: 依存関係をインストール
        run: pnpm install --frozen-lockfile

      - name: ビルド
        run: pnpm turbo run build

      - name: テスト
        run: pnpm turbo run test

      - name: Lint
        run: pnpm turbo run lint

      - name: 型チェック
        run: pnpm turbo run type-check
```

### 影響を受けるもののみデプロイ

```yaml
# 変更されたアプリのみデプロイ
- name: 影響を受けるアプリをデプロイ
  run: |
    if pnpm nx affected:apps --base=origin/main --head=HEAD | grep -q "web"; then
      echo "webアプリをデプロイ中"
      pnpm --filter web deploy
    fi
```

## ベストプラクティス

1. **一貫したバージョニング**：ワークスペース全体で依存関係バージョンをロック
2. **共有設定**：ESLint、TypeScript、Prettier設定を集中化
3. **依存関係グラフ**：非循環を維持、循環依存を避ける
4. **効果的にキャッシュ**：入力/出力を正しく設定
5. **型安全性**：フロントエンド/バックエンド間で型を共有
6. **テスト戦略**：パッケージでユニットテスト、アプリでE2E
7. **ドキュメント**：各パッケージにREADME
8. **リリース戦略**：バージョニングにchangesetsを使用

## よくある落とし穴

- **循環依存**：AがBに依存、BがAに依存
- **ファントム依存関係**：package.jsonにない依存関係を使用
- **不正確なキャッシュ入力**：Turborepo入力でファイルが欠落
- **過剰共有**：別々にすべきコードを共有
- **共有不足**：パッケージ間でコードを重複
- **大きなモノレポ**：適切なツールなしではビルドが遅くなる

## パッケージの公開

```bash
# Changesetsを使用
pnpm add -Dw @changesets/cli
pnpm changeset init

# changesetを作成
pnpm changeset

# パッケージをバージョニング
pnpm changeset version

# 公開
pnpm changeset publish
```

```yaml
# .github/workflows/release.yml
- name: リリースPRを作成または公開
  uses: changesets/action@v1
  with:
    publish: pnpm release
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

## リソース

- **references/turborepo-guide.md**：包括的なTurborepoドキュメント
- **references/nx-guide.md**：Nxモノレポパターン
- **references/pnpm-workspaces.md**：pnpmワークスペース機能
- **assets/monorepo-checklist.md**：セットアップチェックリスト
- **assets/migration-guide.md**：マルチリポジトリからモノレポへの移行
- **scripts/dependency-graph.ts**：パッケージ依存関係を視覚化
