# エージェントスキル

> **[English](../../../docs/agent-skills.md)** | **日本語**

エージェントスキルは、Anthropicの[エージェントスキル仕様](https://github.com/anthropics/skills/blob/main/agent_skills_spec.md)に準拠した、専門的なドメイン知識でClaudeの機能を拡張するモジュラーパッケージです。このプラグインエコシステムには、14個のプラグインにまたがる **47個の専門スキル** が含まれており、プログレッシブ・ディスクロージャーと効率的なトークン使用を可能にします。

## 概要

スキルは、すべてをコンテキストに事前読み込みすることなく、特定のドメインにおける深い専門知識をClaudeに提供します。各スキルには以下が含まれます:

- **YAMLフロントマター**: 名前とアクティベーション条件
- **プログレッシブ・ディスクロージャー**: メタデータ → 指示 → リソース
- **アクティベーショントリガー**: 自動呼び出しのための明確な「Use when」句

## プラグイン別スキル

### Kubernetes Operations (4スキル)

| スキル | 説明 |
|-------|-------------|
| **k8s-manifest-generator** | ベストプラクティスに従ったDeployment、Service、ConfigMap、Secret用の本番環境対応Kubernetesマニフェストを作成 |
| **helm-chart-scaffolding** | Kubernetesアプリケーションのテンプレート化とパッケージング用のHelmチャートを設計、整理、管理 |
| **gitops-workflow** | ArgoCDとFluxを使用した自動化された宣言的デプロイメント用のGitOpsワークフローを実装 |
| **k8s-security-policies** | NetworkPolicy、PodSecurityPolicy、RBACを含むKubernetesセキュリティポリシーを実装 |

### LLM Application Development (4スキル)

| スキル | 説明 |
|-------|-------------|
| **langchain-architecture** | エージェント、メモリ、ツール統合を備えたLangChainフレームワークを使用してLLMアプリケーションを設計 |
| **prompt-engineering-patterns** | LLMのパフォーマンスと信頼性のための高度なプロンプトエンジニアリング技術をマスター |
| **rag-implementation** | ベクトルデータベースとセマンティック検索を使用したRetrieval-Augmented Generationシステムを構築 |
| **llm-evaluation** | 自動化されたメトリクスとベンチマーキングを使用した包括的な評価戦略を実装 |

### Backend Development (3スキル)

| スキル | 説明 |
|-------|-------------|
| **api-design-principles** | 直感的でスケーラブル、保守可能なREST・GraphQL API設計をマスター |
| **architecture-patterns** | クリーンアーキテクチャ、ヘキサゴナルアーキテクチャ、ドメイン駆動設計を実装 |
| **microservices-patterns** | サービス境界、イベント駆動通信、レジリエンスを備えたマイクロサービスを設計 |

### Blockchain & Web3 (4スキル)

| スキル | 説明 |
|-------|-------------|
| **defi-protocol-templates** | ステーキング、AMM、ガバナンス、レンディング用のテンプレートを使用したDeFiプロトコルを実装 |
| **nft-standards** | メタデータとマーケットプレイス統合を備えたNFT標準(ERC-721、ERC-1155)を実装 |
| **solidity-security** | 脆弱性を防ぎ、安全なパターンを実装するためのスマートコントラクトセキュリティをマスター |
| **web3-testing** | ユニットテストとメインネットフォーキングを使用したHardhatとFoundryによるスマートコントラクトテスト |

### CI/CD Automation (4スキル)

| スキル | 説明 |
|-------|-------------|
| **deployment-pipeline-design** | 承認ゲートとセキュリティチェックを備えたマルチステージCI/CDパイプラインを設計 |
| **github-actions-templates** | テスト、ビルド、デプロイ用の本番環境対応GitHub Actionsワークフローを作成 |
| **gitlab-ci-patterns** | マルチステージワークフローと分散ランナーを使用したGitLab CI/CDパイプラインを構築 |
| **secrets-management** | Vault、AWS Secrets Manager、またはネイティブソリューションを使用した安全なシークレット管理を実装 |

### Cloud Infrastructure (4スキル)

| スキル | 説明 |
|-------|-------------|
| **terraform-module-library** | AWS、Azure、GCPインフラストラクチャ用の再利用可能なTerraformモジュールを構築 |
| **multi-cloud-architecture** | ベンダーロックインを回避するマルチクラウドアーキテクチャを設計 |
| **hybrid-cloud-networking** | オンプレミスとクラウドプラットフォーム間の安全な接続を構成 |
| **cost-optimization** | 適正サイジング、タグ付け、リザーブドインスタンスによるクラウドコスト最適化 |

### Framework Migration (4スキル)

| スキル | 説明 |
|-------|-------------|
| **react-modernization** | Reactアプリをアップグレードし、フックに移行し、並行機能を採用 |
| **angular-migration** | ハイブリッドモードと段階的な書き換えを使用してAngularJSからAngularへ移行 |
| **database-migration** | ゼロダウンタイム戦略と変換を使用したデータベース移行を実行 |
| **dependency-upgrade** | 互換性分析とテストを使用したメジャー依存関係アップグレードを管理 |

### Observability & Monitoring (4スキル)

| スキル | 説明 |
|-------|-------------|
| **prometheus-configuration** | 包括的なメトリクス収集と監視のためのPrometheusをセットアップ |
| **grafana-dashboards** | リアルタイムシステム可視化のための本番環境対応Grafanaダッシュボードを作成 |
| **distributed-tracing** | JaegerとTempoを使用した分散トレーシングを実装してリクエストを追跡 |
| **slo-implementation** | エラーバジェットとアラートを備えたSLIとSLOを定義 |

### Payment Processing (4スキル)

| スキル | 説明 |
|-------|-------------|
| **stripe-integration** | チェックアウト、サブスクリプション、Webhook用のStripe決済処理を実装 |
| **paypal-integration** | エクスプレスチェックアウトとサブスクリプションを備えたPayPal決済処理を統合 |
| **pci-compliance** | 安全な決済カードデータ処理のためのPCI DSS準拠を実装 |
| **billing-automation** | 定期支払いと請求書発行のための自動請求システムを構築 |

### Python Development (5スキル)

| スキル | 説明 |
|-------|-------------|
| **async-python-patterns** | Python asyncio、並行プログラミング、async/awaitパターンをマスター |
| **python-testing-patterns** | pytest、フィクスチャ、モックを使用した包括的なテストを実装 |
| **python-packaging** | 適切な構造とPyPI公開を備えた配布可能なPythonパッケージを作成 |
| **python-performance-optimization** | cProfileとパフォーマンスベストプラクティスを使用したPythonコードのプロファイリングと最適化 |
| **uv-package-manager** | 高速な依存関係管理と仮想環境のためのuvパッケージマネージャーをマスター |

### JavaScript/TypeScript (4スキル)

| スキル | 説明 |
|-------|-------------|
| **typescript-advanced-types** | ジェネリクスと条件型を含むTypeScriptの高度な型システムをマスター |
| **nodejs-backend-patterns** | Express/Fastifyとベストプラクティスを使用した本番環境対応Node.jsサービスを構築 |
| **javascript-testing-patterns** | Jest、Vitest、Testing Libraryを使用した包括的なテストを実装 |
| **modern-javascript-patterns** | async/await、分割代入、関数型プログラミングを含むES6+機能をマスター |

### API Scaffolding (1スキル)

| スキル | 説明 |
|-------|-------------|
| **fastapi-templates** | 非同期パターンとエラーハンドリングを備えた本番環境対応FastAPIプロジェクトを作成 |

### Machine Learning Operations (1スキル)

| スキル | 説明 |
|-------|-------------|
| **ml-pipeline-workflow** | データ準備からデプロイメントまでのエンドツーエンドMLOpsパイプラインを構築 |

### Security Scanning (1スキル)

| スキル | 説明 |
|-------|-------------|
| **sast-configuration** | 脆弱性検出のための静的アプリケーションセキュリティテストツールを設定 |

## スキルの仕組み

### アクティベーション

スキルは、Claudeがリクエスト内のマッチングパターンを検出すると自動的にアクティベートされます:

```
ユーザー: "Set up Kubernetes deployment with Helm chart"
→ アクティベート: helm-chart-scaffolding, k8s-manifest-generator

ユーザー: "Build a RAG system for document Q&A"
→ アクティベート: rag-implementation, prompt-engineering-patterns

ユーザー: "Optimize Python async performance"
→ アクティベート: async-python-patterns, python-performance-optimization
```

### プログレッシブ・ディスクロージャー

スキルは、トークン効率のために3層アーキテクチャを使用します:

1. **メタデータ** (フロントマター): 名前とアクティベーション条件(常に読み込み)
2. **指示**: コアガイダンスとパターン(アクティベート時に読み込み)
3. **リソース**: 例とテンプレート(オンデマンドで読み込み)

### エージェントとの統合

スキルはエージェントと連携して、深いドメイン専門知識を提供します:

- **エージェント**: 高レベルの推論とオーケストレーション
- **スキル**: 専門知識と実装パターン

ワークフロー例:
```
backend-architect エージェント → APIアーキテクチャを計画
  ↓
api-design-principles スキル → REST/GraphQLベストプラクティスを提供
  ↓
fastapi-templates スキル → 本番環境対応テンプレートを供給
```

## 仕様準拠

全47スキルは[エージェントスキル仕様](https://github.com/anthropics/skills/blob/main/agent_skills_spec.md)に準拠しています:

- ✓ 必須の`name`フィールド(ハイフンケース)
- ✓ 必須の`description`フィールドと「Use when」句
- ✓ 1024文字未満の説明
- ✓ 完全で切り捨てられていない説明
- ✓ 適切なYAMLフロントマター形式

## 新しいスキルの作成

プラグインにスキルを追加するには:

1. `plugins/{plugin-name}/skills/{skill-name}/SKILL.md`を作成
2. YAMLフロントマターを追加:
   ```yaml
   ---
   name: skill-name
   description: スキルの機能。Use when [アクティベーショントリガー].
   ---
   ```
3. プログレッシブ・ディスクロージャーを使用した包括的なスキルコンテンツを記述
4. スキルパスを`marketplace.json`に追加:
   ```json
   {
     "name": "plugin-name",
     "skills": ["./skills/skill-name"]
   }
   ```

### スキル構造

```
plugins/{plugin-name}/
└── skills/
    └── {skill-name}/
        └── SKILL.md        # フロントマター + コンテンツ
```

## メリット

- **トークン効率**: 必要な知識のみを必要な時に読み込み
- **専門知識**: 肥大化なしの深いドメイン知識
- **明確なアクティベーション**: 明示的なトリガーで不要な呼び出しを防止
- **組み合わせ可能性**: ワークフロー全体でスキルをミックス&マッチ
- **保守性**: 分離された更新が他のスキルに影響を与えない

## リソース

- [Anthropic Skills Repository](https://github.com/anthropics/skills)
- [Agent Skills Documentation](https://docs.claude.com/en/docs/claude-code/skills)
