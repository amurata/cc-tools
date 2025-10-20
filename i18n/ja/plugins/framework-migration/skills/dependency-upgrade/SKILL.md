> **[English](../../../../../plugins/framework-migration/skills/dependency-upgrade/SKILL.md)** | **日本語**

---
name: dependency-upgrade
description: 互換性分析、段階的ロールアウト、包括的テストを伴うメジャー依存関係バージョンアップグレードを管理します。フレームワークバージョンのアップグレード、メジャー依存関係の更新、またはライブラリの破壊的変更の管理時に使用します。
---

# 依存関係アップグレード

メジャー依存関係バージョンアップグレード、互換性分析、段階的アップグレード戦略、包括的テストアプローチをマスターします。

## このスキルを使用するタイミング

- メジャーフレームワークバージョンのアップグレード
- セキュリティ脆弱性のある依存関係の更新
- レガシー依存関係のモダナイゼーション
- 依存関係の競合の解決
- 段階的アップグレードパスの計画
- 互換性マトリックスのテスト
- 依存関係更新の自動化

## セマンティックバージョニングレビュー

```
MAJOR.MINOR.PATCH (例: 2.3.1)

MAJOR: 破壊的変更
MINOR: 新機能、後方互換性あり
PATCH: バグ修正、後方互換性あり

^2.3.1 = >=2.3.1 <3.0.0 (マイナーアップデート)
~2.3.1 = >=2.3.1 <2.4.0 (パッチアップデート)
2.3.1 = 正確なバージョン
```

## 依存関係分析

### 依存関係の監査
```bash
# npm
npm outdated
npm audit
npm audit fix

# yarn
yarn outdated
yarn audit

# メジャーアップデートを確認
npx npm-check-updates
npx npm-check-updates -u  # package.jsonを更新
```

### 依存関係ツリーの分析
```bash
# パッケージがインストールされた理由を確認
npm ls package-name
yarn why package-name

# 重複パッケージを検索
npm dedupe
yarn dedupe

# 依存関係を可視化
npx madge --image graph.png src/
```

## 互換性マトリックス

```javascript
// compatibility-matrix.js
const compatibilityMatrix = {
  'react': {
    '16.x': {
      'react-dom': '^16.0.0',
      'react-router-dom': '^5.0.0',
      '@testing-library/react': '^11.0.0'
    },
    '17.x': {
      'react-dom': '^17.0.0',
      'react-router-dom': '^5.0.0 || ^6.0.0',
      '@testing-library/react': '^12.0.0'
    },
    '18.x': {
      'react-dom': '^18.0.0',
      'react-router-dom': '^6.0.0',
      '@testing-library/react': '^13.0.0'
    }
  }
};

function checkCompatibility(packages) {
  // マトリックスに対してパッケージバージョンを検証
}
```

## 段階的アップグレード戦略

### フェーズ1: 計画
```bash
# 1. 現在のバージョンを特定
npm list --depth=0

# 2. 破壊的変更を確認
# CHANGELOG.mdとMIGRATION.mdを読む

# 3. アップグレード計画を作成
echo "アップグレード順序:
1. TypeScript
2. React
3. React Router
4. テストライブラリ
5. ビルドツール" > UPGRADE_PLAN.md
```

### フェーズ2: 段階的更新
```bash
# すべてを一度にアップグレードしない！

# ステップ1: TypeScriptを更新
npm install typescript@latest

# テスト
npm run test
npm run build

# ステップ2: Reactを更新（一度に1つのメジャーバージョン）
npm install react@17 react-dom@17

# 再度テスト
npm run test

# ステップ3: 他のパッケージを続ける
npm install react-router-dom@6

# 以下同様...
```

### フェーズ3: 検証
```javascript
// tests/compatibility.test.js
describe('Dependency Compatibility', () => {
  it('should have compatible React versions', () => {
    const reactVersion = require('react/package.json').version;
    const reactDomVersion = require('react-dom/package.json').version;

    expect(reactVersion).toBe(reactDomVersion);
  });

  it('should not have peer dependency warnings', () => {
    // npm lsを実行して警告を確認
  });
});
```

## 破壊的変更の処理

### 破壊的変更の特定
```bash
# changelogパーサーを使用
npx changelog-parser react 16.0.0 17.0.0

# または手動で確認
curl https://raw.githubusercontent.com/facebook/react/main/CHANGELOG.md
```

### 自動修正のためのCodemod
```bash
# Reactアップグレードcodemods
npx react-codeshift <transform> <path>

# 例: ライフサイクルメソッドを更新
npx react-codeshift \
  --parser tsx \
  --transform react-codeshift/transforms/rename-unsafe-lifecycles.js \
  src/
```

### カスタム移行スクリプト
```javascript
// migration-script.js
const fs = require('fs');
const glob = require('glob');

glob('src/**/*.tsx', (err, files) => {
  files.forEach(file => {
    let content = fs.readFileSync(file, 'utf8');

    // 古いAPIを新しいAPIに置き換え
    content = content.replace(
      /componentWillMount/g,
      'UNSAFE_componentWillMount'
    );

    // インポートを更新
    content = content.replace(
      /import { Component } from 'react'/g,
      "import React, { Component } from 'react'"
    );

    fs.writeFileSync(file, content);
  });
});
```

## テスト戦略

### ユニットテスト
```javascript
// アップグレード前後でテストが合格することを確認
npm run test

// 必要に応じてテストユーティリティを更新
npm install @testing-library/react@latest
```

### 統合テスト
```javascript
// tests/integration/app.test.js
describe('App Integration', () => {
  it('should render without crashing', () => {
    render(<App />);
  });

  it('should handle navigation', () => {
    const { getByText } = render(<App />);
    fireEvent.click(getByText('Navigate'));
    expect(screen.getByText('New Page')).toBeInTheDocument();
  });
});
```

### ビジュアルリグレッションテスト
```javascript
// visual-regression.test.js
describe('Visual Regression', () => {
  it('should match snapshot', () => {
    const { container } = render(<App />);
    expect(container.firstChild).toMatchSnapshot();
  });
});
```

### E2Eテスト
```javascript
// cypress/e2e/app.cy.js
describe('E2E Tests', () => {
  it('should complete user flow', () => {
    cy.visit('/');
    cy.get('[data-testid="login"]').click();
    cy.get('input[name="email"]').type('user@example.com');
    cy.get('button[type="submit"]').click();
    cy.url().should('include', '/dashboard');
  });
});
```

## 自動化された依存関係更新

### Renovate設定
```json
// renovate.json
{
  "extends": ["config:base"],
  "packageRules": [
    {
      "matchUpdateTypes": ["minor", "patch"],
      "automerge": true
    },
    {
      "matchUpdateTypes": ["major"],
      "automerge": false,
      "labels": ["major-update"]
    }
  ],
  "schedule": ["before 3am on Monday"],
  "timezone": "America/New_York"
}
```

### Dependabot設定
```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5
    reviewers:
      - "team-leads"
    commit-message:
      prefix: "chore"
      include: "scope"
```

## ロールバック計画

```javascript
// rollback.sh
#!/bin/bash

# 現在の状態を保存
git stash
git checkout -b upgrade-branch

# アップグレードを試行
npm install package@latest

# テストを実行
if npm run test; then
  echo "Upgrade successful"
  git add package.json package-lock.json
  git commit -m "chore: upgrade package"
else
  echo "Upgrade failed, rolling back"
  git checkout main
  git branch -D upgrade-branch
  npm install  # package-lock.jsonから復元
fi
```

## 一般的なアップグレードパターン

### ロックファイル管理
```bash
# npm
npm install --package-lock-only  # ロックファイルのみ更新
npm ci  # ロックファイルからクリーンインストール

# yarn
yarn install --frozen-lockfile  # CIモード
yarn upgrade-interactive  # インタラクティブアップグレード
```

### ピア依存関係の解決
```bash
# npm 7+: 厳格なピア依存関係
npm install --legacy-peer-deps  # ピア依存関係を無視

# npm 8+: ピア依存関係をオーバーライド
npm install --force
```

### ワークスペースアップグレード
```bash
# すべてのワークスペースパッケージを更新
npm install --workspaces

# 特定のワークスペースを更新
npm install package@latest --workspace=packages/app
```

## リソース

- **references/semver.md**: セマンティックバージョニングガイド
- **references/compatibility-matrix.md**: 一般的な互換性問題
- **references/staged-upgrades.md**: 段階的アップグレード戦略
- **references/testing-strategy.md**: 包括的テストアプローチ
- **assets/upgrade-checklist.md**: ステップバイステップチェックリスト
- **assets/compatibility-matrix.csv**: バージョン互換性テーブル
- **scripts/audit-dependencies.sh**: 依存関係監査スクリプト

## ベストプラクティス

1. **Changelogを読む**: 何が変わったかを理解する
2. **段階的にアップグレード**: 一度に1つのメジャーバージョン
3. **徹底的にテスト**: ユニット、統合、E2Eテスト
4. **ピア依存関係を確認**: 早期に競合を解決
5. **ロックファイルを使用**: 再現可能なインストールを確保
6. **更新を自動化**: RenovateまたはDependabotを使用
7. **監視**: アップグレード後のランタイムエラーを監視
8. **文書化**: アップグレードノートを保持

## アップグレードチェックリスト

```markdown
アップグレード前:
- [ ] 現在の依存関係バージョンをレビュー
- [ ] 破壊的変更のためにchangelogを読む
- [ ] フィーチャーブランチを作成
- [ ] 現在の状態をバックアップ（git tag）
- [ ] 完全なテストスイートを実行（ベースライン）

アップグレード中:
- [ ] 一度に1つの依存関係をアップグレード
- [ ] ピア依存関係を更新
- [ ] TypeScriptエラーを修正
- [ ] 必要に応じてテストを更新
- [ ] 各アップグレード後にテストスイートを実行
- [ ] バンドルサイズへの影響を確認

アップグレード後:
- [ ] 完全なリグレッションテスト
- [ ] パフォーマンステスト
- [ ] ドキュメントを更新
- [ ] ステージングにデプロイ
- [ ] エラーを監視
- [ ] 本番環境にデプロイ
```

## 一般的な落とし穴

- すべての依存関係を一度にアップグレード
- 各アップグレード後にテストしない
- ピア依存関係警告を無視
- ロックファイルの更新を忘れる
- 破壊的変更ノートを読まない
- メジャーバージョンをスキップ
- ロールバック計画がない
