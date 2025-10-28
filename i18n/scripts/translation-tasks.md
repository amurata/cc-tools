# 翻訳タスクリスト

**作成日**: 2025-10-29
**upstream merge**: commit 005896c
**総行数**: 7,669行（13ファイル）

## 📋 翻訳対象ファイル一覧

### 🆕 新規翻訳（developer-essentials プラグイン）

| # | ファイル | 行数 | ステータス | 備考 |
|---|---------|------|-----------|------|
| 1 | `plugins/developer-essentials/skills/auth-implementation-patterns/SKILL.md` | 634 | ⏳ 未着手 | 認証・認可パターン（JWT, OAuth2, RBAC） |
| 2 | `plugins/developer-essentials/skills/error-handling-patterns/SKILL.md` | 636 | ⏳ 未着手 | エラーハンドリングベストプラクティス |
| 3 | `plugins/developer-essentials/skills/monorepo-management/SKILL.md` | 622 | ⏳ 未着手 | モノレポ管理（Nx, Turborepo） |
| 4 | `plugins/developer-essentials/skills/e2e-testing-patterns/SKILL.md` | 547 | ⏳ 未着手 | E2Eテストパターン（Playwright, Cypress） |
| 5 | `plugins/developer-essentials/skills/debugging-strategies/SKILL.md` | 527 | ⏳ 未着手 | デバッグ戦略とツール |
| 6 | `plugins/developer-essentials/skills/code-review-excellence/SKILL.md` | 520 | ⏳ 未着手 | コードレビューベストプラクティス |
| 7 | `plugins/developer-essentials/skills/sql-optimization-patterns/SKILL.md` | 493 | ⏳ 未着手 | SQL最適化パターン |
| 8 | `plugins/developer-essentials/skills/git-advanced-workflows/SKILL.md` | 400 | ⏳ 未着手 | Git高度なワークフロー |

**小計**: 4,379行

### ✏️ 既存ファイルの更新

| # | ファイル | 行数 | ステータス | 備考 |
|---|---------|------|-----------|------|
| 9 | `.claude-plugin/marketplace.json` | 1,992 | ⏳ 未着手 | プラグインマーケットプレイス定義（JSON） |
| 10 | `plugins/backend-development/skills/architecture-patterns/SKILL.md` | 487 | ⏳ 未着手 | アーキテクチャパターン更新 |
| 11 | `plugins/code-review-ai/commands/ai-review.md` | 428 | ⏳ 未着手 | AIレビューコマンド更新 |
| 12 | `docs/agent-skills.md` | 237 | ⏳ 未着手 | エージェントスキルドキュメント更新 |
| 13 | `plugins/code-review-ai/agents/architect-review.md` | 146 | ⏳ 未着手 | アーキテクトレビューエージェント更新 |

**小計**: 3,290行

**総計**: 7,669行

---

## 🎯 翻訳戦略

### フェーズ1: developer-essentials 新規プラグイン（優先度：高）

新規プラグインなので、上流の最新機能を日本語ユーザーに提供するため優先度が高い。

**推奨順序**（ユーザー需要順）:
1. ✅ **auth-implementation-patterns** (634行) - 認証は基本的ニーズ
2. ✅ **error-handling-patterns** (636行) - エラー処理は全開発者に必須
3. **debugging-strategies** (527行) - デバッグは頻繁なタスク
4. **e2e-testing-patterns** (547行) - テスト自動化の需要高
5. **code-review-excellence** (520行) - チーム開発に必須
6. **git-advanced-workflows** (400行) - Git操作は日常的
7. **sql-optimization-patterns** (493行) - データベース最適化
8. **monorepo-management** (622行) - 大規模プロジェクト向け

### フェーズ2: 既存ファイル更新（優先度：中）

upstream の変更を反映し、翻訳版を最新状態に保つ。

**推奨順序**:
1. **marketplace.json** (1,992行) - 構造的JSONなので比較的容易
2. **architecture-patterns/SKILL.md** (487行) - 重要スキル
3. **ai-review.md** (428行) - AI機能更新
4. **agent-skills.md** (237行) - ドキュメント更新
5. **architect-review.md** (146行) - 小規模更新

---

## 📐 翻訳手順（標準プロセス）

### 1. 事前準備

```bash
# 元ファイルを読み込み
cd /Volumes/OWCUS4EXP\ 1M2\ 4TB\ SSD/ghq/github.com/amurata/cc-tools

# ファイル構造確認
ls -la plugins/developer-essentials/skills/[skill-name]/
```

### 2. 翻訳ディレクトリ作成

```bash
# developer-essentialsプラグイン全体を作成
mkdir -p i18n/ja/plugins/developer-essentials/skills/[skill-name]
```

### 3. SKILL.mdファイル翻訳

**フォーマット規約**:
```yaml
---
name: skill-name
description: 日本語説明（簡潔に）
---

> **[English](../../../../../../plugins/developer-essentials/skills/[skill-name]/SKILL.md)** | **日本語**

# 日本語タイトル

日本語本文...
```

**翻訳ガイドライン**:
- **技術用語**: 原則カタカナ（例: Authentication → 認証、JWT → JWT）
- **コード**: 翻訳しない（変数名、関数名、コメントのみ日本語化）
- **見出し**: 必ず日本語化
- **リンク**: `[English](...) | 日本語` 形式を維持

### 4. 品質チェック

```bash
# 相対パス確認
grep -n "English](" i18n/ja/plugins/developer-essentials/skills/*/SKILL.md

# YAML frontmatter確認
head -n 5 i18n/ja/plugins/developer-essentials/skills/*/SKILL.md

# 行数比較（±10%以内が目安）
wc -l plugins/developer-essentials/skills/auth-implementation-patterns/SKILL.md
wc -l i18n/ja/plugins/developer-essentials/skills/auth-implementation-patterns/SKILL.md
```

### 5. marketplace.json 更新

**手順**:
1. 既存の `i18n/ja/.claude-plugin/marketplace.json` を読み込み
2. upstream の `.claude-plugin/marketplace.json` と差分確認
3. 新規プラグイン定義を追加（`developer-essentials`）
4. 既存プラグインの更新を反映

**フォーマット**:
```json
{
  "id": "developer-essentials",
  "name": "開発者必須スキル",
  "description": "認証、エラーハンドリング、デバッグなど8つの必須スキルを提供",
  "version": "1.0.0",
  ...
}
```

---

## 🔄 進捗管理

### セッション1（今回）: 2025-10-29

- [x] 翻訳タスクリスト作成
- [x] auth-implementation-patterns/SKILL.md 翻訳（634→636行、+0.3%）
- [x] error-handling-patterns/SKILL.md 翻訳（636→638行、+0.3%）
- [x] 品質レビュー（YAMLフロントマター、相対パス、構造）
- [x] i18n/ja/README.md 更新（upstream設定ドキュメント追加）

### セッション2（次回）

- [ ] debugging-strategies/SKILL.md 翻訳
- [ ] e2e-testing-patterns/SKILL.md 翻訳
- [ ] code-review-excellence/SKILL.md 翻訳

### セッション3

- [ ] git-advanced-workflows/SKILL.md 翻訳
- [ ] sql-optimization-patterns/SKILL.md 翻訳
- [ ] monorepo-management/SKILL.md 翻訳

### セッション4

- [ ] marketplace.json 更新
- [ ] 既存5ファイル更新
- [ ] 最終品質レビュー

---

## 📚 参考リソース

### 既存翻訳例

最も参考になる既存翻訳:
- `i18n/ja/plugins/python-development/skills/python-testing-patterns/SKILL.md`
- `i18n/ja/plugins/backend-development/skills/api-design-principles/SKILL.md`
- `i18n/ja/plugins/llm-application-dev/skills/prompt-engineering-patterns/SKILL.md`

### 技術用語対訳表

| English | 日本語 | 備考 |
|---------|--------|------|
| Authentication | 認証 | |
| Authorization | 認可 | |
| JWT (JSON Web Token) | JWT | 略語そのまま |
| OAuth2 | OAuth2 | 略語そのまま |
| RBAC | RBAC（ロールベースアクセス制御） | |
| Session | セッション | |
| Token | トークン | |
| Middleware | ミドルウェア | |
| Error Handling | エラーハンドリング | |
| Debugging | デバッグ | |
| E2E Testing | E2Eテスト | |
| Monorepo | モノレポ | |
| Code Review | コードレビュー | |

---

## ✅ 完了基準

各ファイル翻訳完了時の確認項目:

- [ ] YAML frontmatter が正しい形式
- [ ] 英語版へのリンクパスが正確
- [ ] 全見出しが日本語化
- [ ] コードブロック内コメントのみ日本語化
- [ ] 技術用語が統一されている
- [ ] 行数が元ファイルの±20%以内
- [ ] 相対パスが正しく動作

---

**最終更新**: 2025-10-29
**作成者**: Claude (Serena MCP)
