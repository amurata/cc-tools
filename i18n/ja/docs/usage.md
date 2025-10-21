# 使用ガイド

> **[English](../../../docs/usage.md)** | **日本語**

エージェント、スラッシュコマンド、マルチエージェントワークフローの使用に関する完全ガイドです。

## 概要

プラグインエコシステムは2つの主要なインターフェースを提供します:

1. **スラッシュコマンド** - ツールとワークフローの直接呼び出し
2. **自然言語** - Claudeがどのエージェントを使用するかを推論

## スラッシュコマンド

スラッシュコマンドは、エージェントとワークフローを操作するための主要なインターフェースです。各プラグインは、直接実行できる名前空間付きコマンドを提供します。

### コマンド形式

```bash
/plugin-name:command-name [引数]
```

### コマンドの発見

インストール済みプラグインから利用可能なすべてのスラッシュコマンドをリスト表示:

```bash
/plugin
```

### スラッシュコマンドのメリット

- **直接呼び出し** - 自然言語で説明する必要なし
- **構造化された引数** - 明示的にパラメータを渡して正確な制御
- **組み合わせ可能性** - 複雑なワークフローのためにコマンドを連鎖
- **発見可能性** - `/plugin`で利用可能なすべてのコマンドを表示

## 自然言語

Claudeにどのスペシャリストを使用するか推論させる必要がある場合、エージェントは自然言語でも呼び出すことができます:

```
"backend-architectを使用して認証APIを設計して"
"security-auditorにOWASP脆弱性をスキャンさせて"
"performance-engineerにこのデータベースクエリを最適化させて"
```

Claude Codeは、リクエストに基づいて適切なエージェントを自動的に選択および調整します。

## カテゴリー別コマンドリファレンス

### 開発 & 機能

| コマンド | 説明 |
|---------|-------------|
| `/backend-development:feature-development` | エンドツーエンドバックエンド機能開発 |
| `/full-stack-orchestration:full-stack-feature` | 完全なフルスタック機能実装 |
| `/multi-platform-apps:multi-platform` | クロスプラットフォームアプリ開発調整 |

### テスト & 品質

| コマンド | 説明 |
|---------|-------------|
| `/unit-testing:test-generate` | 包括的なユニットテスト生成 |
| `/tdd-workflows:tdd-cycle` | 完全なTDDレッド-グリーン-リファクタリングサイクル |
| `/tdd-workflows:tdd-red` | 最初に失敗するテストを記述 |
| `/tdd-workflows:tdd-green` | テストを通過するコードを実装 |
| `/tdd-workflows:tdd-refactor` | テストが通過した状態でリファクタリング |

### コード品質 & レビュー

| コマンド | 説明 |
|---------|-------------|
| `/code-review-ai:ai-review` | AI駆動コードレビュー |
| `/comprehensive-review:full-review` | 多角的分析 |
| `/comprehensive-review:pr-enhance` | プルリクエスト機能強化 |

### デバッグ & トラブルシューティング

| コマンド | 説明 |
|---------|-------------|
| `/debugging-toolkit:smart-debug` | インタラクティブスマートデバッグ |
| `/incident-response:incident-response` | 本番環境インシデント管理 |
| `/incident-response:smart-fix` | 自動インシデント解決 |
| `/error-debugging:error-analysis` | 深いエラー分析 |
| `/error-debugging:error-trace` | スタックトレースデバッグ |
| `/error-diagnostics:smart-debug` | スマート診断デバッグ |
| `/distributed-debugging:debug-trace` | 分散システムトレーシング |

### セキュリティ

| コマンド | 説明 |
|---------|-------------|
| `/security-scanning:security-hardening` | 包括的なセキュリティ強化 |
| `/security-scanning:security-sast` | 静的アプリケーションセキュリティテスト |
| `/security-scanning:security-dependencies` | 依存関係脆弱性スキャン |
| `/security-compliance:compliance-check` | SOC2/HIPAA/GDPR準拠 |
| `/frontend-mobile-security:xss-scan` | XSS脆弱性スキャン |

### インフラストラクチャ & デプロイメント

| コマンド | 説明 |
|---------|-------------|
| `/observability-monitoring:monitor-setup` | 監視インフラストラクチャのセットアップ |
| `/observability-monitoring:slo-implement` | SLO/SLIメトリクスの実装 |
| `/deployment-validation:config-validate` | デプロイメント前検証 |
| `/cicd-automation:workflow-automate` | CI/CDパイプライン自動化 |

### データ & ML

| コマンド | 説明 |
|---------|-------------|
| `/machine-learning-ops:ml-pipeline` | MLトレーニングパイプラインオーケストレーション |
| `/data-engineering:data-pipeline` | ETL/ELTパイプライン構築 |
| `/data-engineering:data-driven-feature` | データ駆動機能開発 |

### ドキュメント

| コマンド | 説明 |
|---------|-------------|
| `/code-documentation:doc-generate` | 包括的なドキュメント生成 |
| `/code-documentation:code-explain` | コード機能の説明 |
| `/documentation-generation:doc-generate` | OpenAPI仕様、図、チュートリアル |

### リファクタリング & メンテナンス

| コマンド | 説明 |
|---------|-------------|
| `/code-refactoring:refactor-clean` | コードクリーンアップとリファクタリング |
| `/code-refactoring:tech-debt` | 技術的負債管理 |
| `/codebase-cleanup:deps-audit` | 依存関係監査 |
| `/codebase-cleanup:tech-debt` | 技術的負債削減 |
| `/framework-migration:legacy-modernize` | レガシーコードモダナイゼーション |
| `/framework-migration:code-migrate` | フレームワークマイグレーション |
| `/framework-migration:deps-upgrade` | 依存関係アップグレード |

### データベース

| コマンド | 説明 |
|---------|-------------|
| `/database-migrations:sql-migrations` | SQLマイグレーション自動化 |
| `/database-migrations:migration-observability` | マイグレーション監視 |
| `/database-cloud-optimization:cost-optimize` | データベースとクラウド最適化 |

### Git & PRワークフロー

| コマンド | 説明 |
|---------|-------------|
| `/git-pr-workflows:pr-enhance` | プルリクエスト品質向上 |
| `/git-pr-workflows:onboard` | チームオンボーディング自動化 |
| `/git-pr-workflows:git-workflow` | Gitワークフロー自動化 |

### プロジェクトスキャフォールディング

| コマンド | 説明 |
|---------|-------------|
| `/python-development:python-scaffold` | FastAPI/Djangoプロジェクトセットアップ |
| `/javascript-typescript:typescript-scaffold` | Next.js/React + Viteセットアップ |
| `/systems-programming:rust-project` | Rustプロジェクトスキャフォールディング |

### AI & LLM開発

| コマンド | 説明 |
|---------|-------------|
| `/llm-application-dev:langchain-agent` | LangChainエージェント開発 |
| `/llm-application-dev:ai-assistant` | AIアシスタント実装 |
| `/llm-application-dev:prompt-optimize` | プロンプトエンジニアリング最適化 |
| `/agent-orchestration:multi-agent-optimize` | マルチエージェント最適化 |
| `/agent-orchestration:improve-agent` | エージェント改善ワークフロー |

### テスト & パフォーマンス

| コマンド | 説明 |
|---------|-------------|
| `/performance-testing-review:ai-review` | パフォーマンス分析 |
| `/application-performance:performance-optimization` | アプリ最適化 |

### チームコラボレーション

| コマンド | 説明 |
|---------|-------------|
| `/team-collaboration:issue` | Issue管理自動化 |
| `/team-collaboration:standup-notes` | スタンドアップノート生成 |

### アクセシビリティ

| コマンド | 説明 |
|---------|-------------|
| `/accessibility-compliance:accessibility-audit` | WCAG準拠監査 |

### API開発

| コマンド | 説明 |
|---------|-------------|
| `/api-testing-observability:api-mock` | APIモックとテスト |

### コンテキスト管理

| コマンド | 説明 |
|---------|-------------|
| `/context-management:context-save` | 会話コンテキストの保存 |
| `/context-management:context-restore` | 以前のコンテキストの復元 |

## マルチエージェントワークフロー例

プラグインは、スラッシュコマンドからアクセス可能な事前設定されたマルチエージェントワークフローを提供します。

### フルスタック開発

```bash
# コマンドベースのワークフロー呼び出し
/full-stack-orchestration:full-stack-feature "リアルタイム分析を含むユーザーダッシュボード"

# 自然言語代替
"リアルタイム分析を含むユーザーダッシュボードを実装して"
```

**オーケストレーション:** backend-architect → database-architect → frontend-developer → test-automator → security-auditor → deployment-engineer → observability-engineer

**実行内容:**

1. マイグレーション付きデータベーススキーマ設計
2. バックエンドAPI実装(REST/GraphQL)
3. 状態管理を使用したフロントエンドコンポーネント
4. 包括的なテストスイート(ユニット/統合/E2E)
5. セキュリティ監査と強化
6. 機能フラグ付きCI/CDパイプラインセットアップ
7. 可観測性と監視設定

### セキュリティ強化

```bash
# 包括的なセキュリティ評価と修正
/security-scanning:security-hardening --level comprehensive

# 自然言語代替
"セキュリティ監査を実行してOWASPベストプラクティスを実装して"
```

**オーケストレーション:** security-auditor → backend-security-coder → frontend-security-coder → mobile-security-coder → test-automator

### データ/MLパイプライン

```bash
# 本番環境デプロイメント付きML機能開発
/machine-learning-ops:ml-pipeline "顧客離脱予測モデル"

# 自然言語代替
"デプロイメント付き顧客離脱予測モデルを構築して"
```

**オーケストレーション:** data-scientist → data-engineer → ml-engineer → mlops-engineer → performance-engineer

### インシデント対応

```bash
# 根本原因分析付きスマートデバッグ
/incident-response:smart-fix "決済サービスの本番環境メモリリーク"

# 自然言語代替
"本番環境メモリリークをデバッグしてランブックを作成して"
```

**オーケストレーション:** incident-responder → devops-troubleshooter → debugger → error-detective → observability-engineer

## コマンド引数とオプション

多くのスラッシュコマンドは、正確な制御のための引数をサポートしています:

```bash
# 特定ファイルのテスト生成
/unit-testing:test-generate src/api/users.py

# 手法指定付き機能開発
/backend-development:feature-development OAuth2 integration with social login

# セキュリティ依存関係スキャン
/security-scanning:security-dependencies

# コンポーネントスキャフォールディング
/frontend-mobile-development:component-scaffold UserProfile component with hooks

# TDDワークフローサイクル
/tdd-workflows:tdd-red User can reset password
/tdd-workflows:tdd-green
/tdd-workflows:tdd-refactor

# スマートデバッグ
/debugging-toolkit:smart-debug memory leak in checkout flow

# Pythonプロジェクトスキャフォールディング
/python-development:python-scaffold fastapi-microservice
```

## 自然言語とコマンドの組み合わせ

最適な柔軟性のために両方のアプローチを組み合わせることができます:

```
# 構造化されたワークフローのためにコマンドで開始
/full-stack-orchestration:full-stack-feature "決済処理"

# 次に自然言語でガイダンスを提供
"PCI-DSS準拠を確保してStripeと統合して"
"失敗したトランザクションのためのリトライロジックを追加して"
"不正検出ルールをセットアップして"
```

## ベストプラクティス

### スラッシュコマンドを使用する場合

- **構造化されたワークフロー** - 明確なフェーズを持つ複数ステップのプロセス
- **反復的なタスク** - 頻繁に実行する操作
- **正確な制御** - 特定のパラメータが必要な場合
- **発見** - 利用可能な機能を探索

### 自然言語を使用する場合

- **探索的作業** - どのツールを使用するか不確かな場合
- **複雑な推論** - Claudeが複数のエージェントを調整する必要がある場合
- **コンテキストに依存する決定** - 正しいアプローチが状況に依存する場合
- **アドホックタスク** - コマンドに適合しない一回限りの操作

### ワークフロー構成

複雑なシナリオのために複数のプラグインを組み合わせます:

```bash
# 1. 機能開発から開始
/backend-development:feature-development payment processing API

# 2. セキュリティ強化を追加
/security-scanning:security-hardening

# 3. 包括的なテストを生成
/unit-testing:test-generate

# 4. 実装をレビュー
/code-review-ai:ai-review

# 5. CI/CDをセットアップ
/cicd-automation:workflow-automate

# 6. 監視を追加
/observability-monitoring:monitor-setup
```

## Agent Skills統合

Agent Skillsはコマンドと連携して深い専門知識を提供します:

```
ユーザー: "非同期パターンでFastAPIプロジェクトをセットアップして"
→ アクティベート: fastapi-templates スキル
→ 呼び出し: /python-development:python-scaffold
→ 結果: ベストプラクティスを含む本番環境対応FastAPIプロジェクト

ユーザー: "HelmでKubernetesデプロイメントを実装して"
→ アクティベート: helm-chart-scaffolding, k8s-manifest-generator スキル
→ ガイド: kubernetes-architect エージェント
→ 結果: Helmチャート付き本番環境グレードK8sマニフェスト
```

47個の専門スキルの詳細は[Agent Skills](./agent-skills.md)を参照してください。

## 関連項目

- [Agent Skills](./agent-skills.md) - 専門知識パッケージ
- [Agent Reference](./agents.md) - 完全なエージェントカタログ
- [Plugin Reference](./plugins.md) - 全63プラグイン
- [Architecture](./architecture.md) - 設計原則
