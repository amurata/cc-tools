# Claude Code プラグイン：オーケストレーションと自動化

> **⚡ Sonnet 4.5 & Haiku 4.5 対応** — すべてのエージェントを最新モデル向けにハイブリッドオーケストレーションで最適化
>
> **🎯 エージェントスキル有効化** — 47個の専門スキルがプログレッシブ・ディスクロージャーでClaudeの機能をプラグイン全体に拡張

[Claude Code](https://docs.claude.com/en/docs/claude-code/overview) 向けに、**85個の専門AIエージェント**、**15個のマルチエージェントワークフローオーケストレーター**、**47個のエージェントスキル**、**44個の開発ツール**を **63個の集中的・単一目的プラグイン** に整理した包括的な本番環境対応システムです。

> **[English](../../README.md)** | **日本語**

## 概要

この統合リポジトリは、現代のソフトウェア開発における インテリジェントな自動化とマルチエージェントオーケストレーションに必要なすべてを提供します：

- **63個の集中型プラグイン** - 最小限のトークン使用量と組み合わせ可能性に最適化された、粒度の細かい単一目的プラグイン
- **85個の専門エージェント** - アーキテクチャ、言語、インフラ、品質、データ/AI、ドキュメント、ビジネス運用、SEOにわたる深い知識を持つドメインエキスパート
- **47個のエージェントスキル** - 専門知識のためのプログレッシブ・ディスクロージャーを備えたモジュール式知識パッケージ
- **15個のワークフローオーケストレーター** - フルスタック開発、セキュリティ強化、MLパイプライン、インシデント対応などの複雑な操作のためのマルチエージェント調整システム
- **44個の開発ツール** - プロジェクトのスキャフォールディング、セキュリティスキャン、テスト自動化、インフラセットアップを含む最適化されたユーティリティ

### 主な特徴

- **粒度の細かいプラグインアーキテクチャ**: 最小限のトークン使用量に最適化された63個の集中型プラグイン
- **包括的なツール群**: テスト生成、スキャフォールディング、セキュリティスキャンを含む44個の開発ツール
- **100%エージェントカバレッジ**: すべてのプラグインに専門エージェントが含まれています
- **エージェントスキル**: プログレッシブ・ディスクロージャーとトークン効率性に従った47個の専門スキル
- **明確な整理**: 簡単に見つけられるよう、23カテゴリに各1〜6個のプラグインを配置
- **効率的な設計**: プラグインあたり平均3.4コンポーネント（Anthropicの2〜8パターンに準拠）

### 仕組み

各プラグインは、独自のエージェント、コマンド、スキルと完全に分離されています：

- **必要なものだけインストール** - 各プラグインは、特定のエージェント、コマンド、スキルのみをロードします
- **最小限のトークン使用量** - 不要なリソースはコンテキストにロードされません
- **ミックス＆マッチ** - 複雑なワークフローのために複数のプラグインを組み合わせます
- **明確な境界** - 各プラグインには単一の集中した目的があります
- **プログレッシブ・ディスクロージャー** - スキルは起動時にのみ知識をロードします

**例**: `python-development` をインストールすると、3つのPythonエージェント、1つのスキャフォールディングツールがロードされ、5つのスキルが利用可能になります（約300トークン）。マーケットプレイス全体ではありません。

## クイックスタート

### ステップ1: マーケットプレイスの追加

このマーケットプレイスをClaude Codeに追加します：

```bash
/plugin marketplace add wshobson/agents
```

これにより、63個のプラグインすべてがインストール可能になりますが、**エージェントやツールはコンテキストにロードされません**。

### ステップ2: プラグインのインストール

利用可能なプラグインを閲覧します：

```bash
/plugin
```

必要なプラグインをインストールします：

```bash
# 必須開発プラグイン
/plugin install python-development          # 5つの専門スキルを持つPython
/plugin install javascript-typescript       # 4つの専門スキルを持つJS/TS
/plugin install backend-development         # 3つのアーキテクチャスキルを持つバックエンドAPI

# インフラ＆運用
/plugin install kubernetes-operations       # 4つのデプロイメントスキルを持つK8s
/plugin install cloud-infrastructure        # 4つのクラウドスキルを持つAWS/Azure/GCP

# セキュリティ＆品質
/plugin install security-scanning           # セキュリティスキルを持つSAST
/plugin install code-review-ai             # AI駆動のコードレビュー

# フルスタックオーケストレーション
/plugin install full-stack-orchestration   # マルチエージェントワークフロー
```

インストールされた各プラグインは、**特定のエージェント、コマンド、スキルのみ**をClaudeのコンテキストにロードします。

## ドキュメント

### コアガイド

- **[プラグインリファレンス](docs/plugins.md)** - 全63プラグインの完全なカタログ
- **[エージェントリファレンス](docs/agents.md)** - カテゴリ別に整理された全85エージェント
- **[エージェントスキル](docs/agent-skills.md)** - プログレッシブ・ディスクロージャーを備えた47の専門スキル
- **[使用ガイド](docs/usage.md)** - コマンド、ワークフロー、ベストプラクティス
- **[アーキテクチャ](docs/architecture.md)** - 設計原則とパターン

### クイックリンク

- [インストール](#クイックスタート) - 2ステップで開始
- [必須プラグイン](docs/plugins.md#quick-start---essential-plugins) - すぐに生産性を上げるトッププラグイン
- [コマンドリファレンス](docs/usage.md#command-reference-by-category) - カテゴリ別に整理されたすべてのスラッシュコマンド
- [マルチエージェントワークフロー](docs/usage.md#multi-agent-workflow-examples) - 事前設定されたオーケストレーションの例
- [モデル設定](docs/agents.md#model-configuration) - Haiku/Sonnetハイブリッドオーケストレーション

## 新着情報

### エージェントスキル（14プラグインにわたる47スキル）

Anthropicのプログレッシブ・ディスクロージャーアーキテクチャに従った専門知識パッケージ：

**言語開発：**
- **Python**（5スキル）: 非同期パターン、テスト、パッケージング、パフォーマンス、UVパッケージマネージャー
- **JavaScript/TypeScript**（4スキル）: 高度な型、Node.jsパターン、テスト、モダンES6+

**インフラ＆DevOps：**
- **Kubernetes**（4スキル）: マニフェスト、Helmチャート、GitOps、セキュリティポリシー
- **クラウドインフラ**（4スキル）: Terraform、マルチクラウド、ハイブリッドネットワーキング、コスト最適化
- **CI/CD**（4スキル）: パイプライン設計、GitHub Actions、GitLab CI、シークレット管理

**開発＆アーキテクチャ：**
- **バックエンド**（3スキル）: API設計、アーキテクチャパターン、マイクロサービス
- **LLMアプリケーション**（4スキル）: LangChain、プロンプトエンジニアリング、RAG、評価

**ブロックチェーン＆Web3**（4スキル）: DeFiプロトコル、NFT標準、Solidityセキュリティ、Web3テスト

**その他:** フレームワーク移行、オブザーバビリティ、決済処理、ML運用、セキュリティスキャン

[→ 完全なスキルドキュメントを表示](docs/agent-skills.md)

### ハイブリッドモデルオーケストレーション

最適なパフォーマンスとコストのための戦略的モデル割り当て：
- **47個のHaikuエージェント** - 決定論的タスクの高速実行
- **97個のSonnetエージェント** - 複雑な推論とアーキテクチャ

オーケストレーションパターンは効率のためにモデルを組み合わせます：
```
Sonnet（計画） → Haiku（実行） → Sonnet（レビュー）
```

[→ モデル設定の詳細を表示](docs/agents.md#model-configuration)

## 人気のユースケース

### フルスタック機能開発

```bash
/full-stack-orchestration:full-stack-feature "OAuth2を使用したユーザー認証"
```

7つ以上のエージェントを調整: backend-architect → database-architect → frontend-developer → test-automator → security-auditor → deployment-engineer → observability-engineer

[→ すべてのワークフロー例を表示](docs/usage.md#multi-agent-workflow-examples)

### セキュリティ強化

```bash
/security-scanning:security-hardening --level comprehensive
```

SAST、依存関係スキャン、コードレビューを含むマルチエージェントセキュリティ評価。

### モダンツールによるPython開発

```bash
/python-development:python-scaffold fastapi-microservice
```

非同期パターンを備えた本番環境対応FastAPIプロジェクトを作成し、次のスキルを有効化：
- `async-python-patterns` - AsyncIOと並行処理
- `python-testing-patterns` - pytestとフィクスチャ
- `uv-package-manager` - 高速な依存関係管理

### Kubernetesデプロイメント

```bash
# K8sスキルを自動的に有効化
"HelmチャートとGitOpsを使用した本番環境Kubernetesデプロイメントを作成"
```

本番グレードの設定のために4つの専門スキルを持つkubernetes-architectエージェントを使用します。

[→ 完全な使用ガイドを表示](docs/usage.md)

## プラグインカテゴリ

**23カテゴリ、63プラグイン:**

- 🎨 **開発**（4） - デバッグ、バックエンド、フロントエンド、マルチプラットフォーム
- 📚 **ドキュメント**（2） - コードドキュメント、API仕様、図
- 🔄 **ワークフロー**（3） - git、フルスタック、TDD
- ✅ **テスト**（2） - ユニットテスト、TDDワークフロー
- 🔍 **品質**（3） - コードレビュー、包括的レビュー、パフォーマンス
- 🤖 **AI & ML**（4） - LLMアプリ、エージェントオーケストレーション、コンテキスト、MLOps
- 📊 **データ**（2） - データエンジニアリング、データ検証
- 🗄️ **データベース**（2） - データベース設計、マイグレーション
- 🚨 **運用**（4） - インシデント対応、診断、分散デバッグ、オブザーバビリティ
- ⚡ **パフォーマンス**（2） - アプリケーションパフォーマンス、データベース/クラウド最適化
- ☁️ **インフラ**（5） - デプロイメント、検証、Kubernetes、クラウド、CI/CD
- 🔒 **セキュリティ**（4） - スキャン、コンプライアンス、バックエンド/API、フロントエンド/モバイル
- 💻 **言語**（7） - Python、JS/TS、システム、JVM、スクリプティング、関数型、組み込み
- 🔗 **ブロックチェーン**（1） - スマートコントラクト、DeFi、Web3
- 💰 **金融**（1） - 定量取引、リスク管理
- 💳 **決済**（1） - Stripe、PayPal、請求
- 🎮 **ゲーミング**（1） - Unity、Minecraftプラグイン
- 📢 **マーケティング**（4） - SEOコンテンツ、テクニカルSEO、SEO分析、コンテンツマーケティング
- 💼 **ビジネス**（3） - 分析、HR/法務、顧客/販売
- その他...

[→ 完全なプラグインカタログを表示](docs/plugins.md)

## アーキテクチャのハイライト

### 粒度の細かい設計

- **単一責任** - 各プラグインは1つのことをうまく行います
- **最小限のトークン使用量** - プラグインあたり平均3.4コンポーネント
- **組み合わせ可能** - 複雑なワークフローのためにミックス＆マッチ
- **100%カバレッジ** - すべての85エージェントがプラグイン全体でアクセス可能

### プログレッシブ・ディスクロージャー（スキル）

トークン効率のための3層アーキテクチャ：
1. **メタデータ** - 名前と起動基準（常にロード）
2. **インストラクション** - コアガイダンス（起動時にロード）
3. **リソース** - 例とテンプレート（オンデマンドでロード）

### リポジトリ構造

```
claude-agents/
├── .claude-plugin/
│   └── marketplace.json          # 63プラグイン
├── plugins/
│   ├── python-development/
│   │   ├── agents/               # 3つのPythonエキスパート
│   │   ├── commands/             # スキャフォールディングツール
│   │   └── skills/               # 5つの専門スキル
│   ├── kubernetes-operations/
│   │   ├── agents/               # K8sアーキテクト
│   │   ├── commands/             # デプロイメントツール
│   │   └── skills/               # 4つのK8sスキル
│   └── ... （さらに61プラグイン）
├── docs/                          # 包括的なドキュメント
└── README.md                      # このファイル
```

[→ アーキテクチャの詳細を表示](docs/architecture.md)

## 貢献

新しいエージェント、スキル、コマンドを追加するには：

1. `plugins/` 内の適切なプラグインディレクトリを特定または作成
2. 適切なサブディレクトリに `.md` ファイルを作成：
   - `agents/` - 専門エージェント用
   - `commands/` - ツールとワークフロー用
   - `skills/` - モジュール式知識パッケージ用
3. 命名規則に従う（小文字、ハイフン区切り）
4. 明確な起動基準と包括的なコンテンツを記述
5. `.claude-plugin/marketplace.json` のプラグイン定義を更新

詳細なガイドラインについては、[アーキテクチャドキュメント](docs/architecture.md)を参照してください。

## リソース

### ドキュメント
- [Claude Code ドキュメント](https://docs.claude.com/en/docs/claude-code/overview)
- [プラグインガイド](https://docs.claude.com/en/docs/claude-code/plugins)
- [サブエージェントガイド](https://docs.claude.com/en/docs/claude-code/sub-agents)
- [エージェントスキルガイド](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/overview)
- [スラッシュコマンドリファレンス](https://docs.claude.com/en/docs/claude-code/slash-commands)

### このリポジトリ
- [プラグインリファレンス](docs/plugins.md)
- [エージェントリファレンス](docs/agents.md)
- [エージェントスキルガイド](docs/agent-skills.md)
- [使用ガイド](docs/usage.md)
- [アーキテクチャ](docs/architecture.md)

## ライセンス

MIT License - 詳細については[LICENSE](LICENSE)ファイルを参照してください。

## スター履歴

[![Star History Chart](https://api.star-history.com/svg?repos=wshobson/agents&type=date&legend=top-left)](https://www.star-history.com/#wshobson/agents&type=date&legend=top-left)
