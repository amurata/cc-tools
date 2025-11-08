# エージェントリファレンス

> **[English](../../../docs/agents.md)** | **日本語**

カテゴリー別に整理された、モデル割り当てを含む **85個の専門AIエージェント** の完全なリファレンスです。

## エージェントカテゴリー

### アーキテクチャ & システム設計

#### コアアーキテクチャ

| エージェント | モデル | 説明 |
|-------|-------|-------------|
| [backend-architect](../plugins/backend-development/agents/backend-architect.md) | opus | RESTful API設計、マイクロサービス境界、データベーススキーマ |
| [frontend-developer](../plugins/multi-platform-apps/agents/frontend-developer.md) | sonnet | Reactコンポーネント、レスポンシブレイアウト、クライアント側状態管理 |
| [graphql-architect](../plugins/backend-development/agents/graphql-architect.md) | opus | GraphQLスキーマ、リゾルバー、フェデレーションアーキテクチャ |
| [architect-reviewer](../plugins/comprehensive-review/agents/architect-review.md) | opus | アーキテクチャ一貫性分析とパターン検証 |
| [cloud-architect](../plugins/cloud-infrastructure/agents/cloud-architect.md) | opus | AWS/Azure/GCPインフラストラクチャ設計とコスト最適化 |
| [hybrid-cloud-architect](../plugins/cloud-infrastructure/agents/hybrid-cloud-architect.md) | opus | クラウドとオンプレミス環境にまたがるマルチクラウド戦略 |
| [kubernetes-architect](../plugins/kubernetes-operations/agents/kubernetes-architect.md) | opus | KubernetesとGitOpsを使用したクラウドネイティブインフラストラクチャ |

#### UI/UX & モバイル

| エージェント | モデル | 説明 |
|-------|-------|-------------|
| [ui-ux-designer](../plugins/multi-platform-apps/agents/ui-ux-designer.md) | sonnet | インターフェース設計、ワイヤーフレーム、デザインシステム |
| [ui-visual-validator](../plugins/accessibility-compliance/agents/ui-visual-validator.md) | sonnet | ビジュアルリグレッションテストとUI検証 |
| [mobile-developer](../plugins/multi-platform-apps/agents/mobile-developer.md) | sonnet | React NativeとFlutterアプリケーション開発 |
| [ios-developer](../plugins/multi-platform-apps/agents/ios-developer.md) | sonnet | Swift/SwiftUIを使用したネイティブiOS開発 |
| [flutter-expert](../plugins/multi-platform-apps/agents/flutter-expert.md) | sonnet | 状態管理を含む高度なFlutter開発 |

### プログラミング言語

#### システム & 低レベル

| エージェント | モデル | 説明 |
|-------|-------|-------------|
| [c-pro](../plugins/systems-programming/agents/c-pro.md) | sonnet | メモリ管理とOSインターフェースを使用したシステムプログラミング |
| [cpp-pro](../plugins/systems-programming/agents/cpp-pro.md) | sonnet | RAII、スマートポインタ、STLアルゴリズムを使用したモダンC++ |
| [rust-pro](../plugins/systems-programming/agents/rust-pro.md) | sonnet | 所有権パターンを使用したメモリセーフなシステムプログラミング |
| [golang-pro](../plugins/systems-programming/agents/golang-pro.md) | sonnet | ゴルーチンとチャネルを使用した並行プログラミング |

#### Web & アプリケーション

| エージェント | モデル | 説明 |
|-------|-------|-------------|
| [javascript-pro](../plugins/javascript-typescript/agents/javascript-pro.md) | sonnet | ES6+、非同期パターン、Node.jsを使用したモダンJavaScript |
| [typescript-pro](../plugins/javascript-typescript/agents/typescript-pro.md) | sonnet | 型システムとジェネリクスを使用した高度なTypeScript |
| [python-pro](../plugins/python-development/agents/python-pro.md) | sonnet | 高度な機能と最適化を使用したPython開発 |
| [ruby-pro](../plugins/web-scripting/agents/ruby-pro.md) | sonnet | メタプログラミング、Railsパターン、gem開発を使用したRuby |
| [php-pro](../plugins/web-scripting/agents/php-pro.md) | sonnet | フレームワークとパフォーマンス最適化を使用したモダンPHP |

#### エンタープライズ & JVM

| エージェント | モデル | 説明 |
|-------|-------|-------------|
| [java-pro](../plugins/jvm-languages/agents/java-pro.md) | sonnet | ストリーム、並行性、JVM最適化を使用したモダンJava |
| [scala-pro](../plugins/jvm-languages/agents/scala-pro.md) | sonnet | 関数型プログラミングと分散システムを使用したエンタープライズScala |
| [csharp-pro](../plugins/jvm-languages/agents/csharp-pro.md) | sonnet | .NETフレームワークとパターンを使用したC#開発 |

#### 専門プラットフォーム

| エージェント | モデル | 説明 |
|-------|-------|-------------|
| [elixir-pro](../plugins/functional-programming/agents/elixir-pro.md) | sonnet | OTPパターンとPhoenixフレームワークを使用したElixir |
| [django-pro](../plugins/api-scaffolding/agents/django-pro.md) | sonnet | ORMと非同期ビューを使用したDjango開発 |
| [fastapi-pro](../plugins/api-scaffolding/agents/fastapi-pro.md) | sonnet | 非同期パターンとPydanticを使用したFastAPI |
| [unity-developer](../plugins/game-development/agents/unity-developer.md) | sonnet | Unityゲーム開発と最適化 |
| [minecraft-bukkit-pro](../plugins/game-development/agents/minecraft-bukkit-pro.md) | sonnet | Minecraftサーバープラグイン開発 |
| [sql-pro](../plugins/database-design/agents/sql-pro.md) | sonnet | 複雑なSQLクエリとデータベース最適化 |

### インフラストラクチャ & 運用

#### DevOps & デプロイメント

| エージェント | モデル | 説明 |
|-------|-------|-------------|
| [devops-troubleshooter](../plugins/incident-response/agents/devops-troubleshooter.md) | sonnet | 本番環境デバッグ、ログ分析、デプロイメントトラブルシューティング |
| [deployment-engineer](../plugins/cloud-infrastructure/agents/deployment-engineer.md) | sonnet | CI/CDパイプライン、コンテナ化、クラウドデプロイメント |
| [terraform-specialist](../plugins/cloud-infrastructure/agents/terraform-specialist.md) | sonnet | Terraformモジュールと状態管理を使用したInfrastructure as Code |
| [dx-optimizer](../plugins/team-collaboration/agents/dx-optimizer.md) | sonnet | 開発者エクスペリエンス最適化とツール改善 |

#### データベース管理

| エージェント | モデル | 説明 |
|-------|-------|-------------|
| [database-optimizer](../plugins/observability-monitoring/agents/database-optimizer.md) | sonnet | クエリ最適化、インデックス設計、マイグレーション戦略 |
| [database-admin](../plugins/database-migrations/agents/database-admin.md) | sonnet | データベース運用、バックアップ、レプリケーション、監視 |
| [database-architect](../plugins/database-design/agents/database-architect.md) | opus | ゼロからのデータベース設計、技術選択、スキーマモデリング |

#### インシデント対応 & ネットワーク

| エージェント | モデル | 説明 |
|-------|-------|-------------|
| [incident-responder](../plugins/incident-response/agents/incident-responder.md) | opus | 本番環境インシデント管理と解決 |
| [network-engineer](../plugins/observability-monitoring/agents/network-engineer.md) | sonnet | ネットワークデバッグ、ロードバランシング、トラフィック分析 |

### 品質保証 & セキュリティ

#### コード品質 & レビュー

| エージェント | モデル | 説明 |
|-------|-------|-------------|
| [code-reviewer](../plugins/comprehensive-review/agents/code-reviewer.md) | opus | セキュリティと本番環境の信頼性に焦点を当てたコードレビュー |
| [security-auditor](../plugins/comprehensive-review/agents/security-auditor.md) | opus | 脆弱性評価とOWASP準拠 |
| [backend-security-coder](../plugins/data-validation-suite/agents/backend-security-coder.md) | opus | 安全なバックエンドコーディング慣行、APIセキュリティ実装 |
| [frontend-security-coder](../plugins/frontend-mobile-security/agents/frontend-security-coder.md) | opus | XSS防止、CSP実装、クライアント側セキュリティ |
| [mobile-security-coder](../plugins/frontend-mobile-security/agents/mobile-security-coder.md) | opus | モバイルセキュリティパターン、WebViewセキュリティ、生体認証 |

#### テスト & デバッグ

| エージェント | モデル | 説明 |
|-------|-------|-------------|
| [test-automator](../plugins/codebase-cleanup/agents/test-automator.md) | sonnet | 包括的なテストスイート作成(ユニット、統合、e2e) |
| [tdd-orchestrator](../plugins/backend-development/agents/tdd-orchestrator.md) | sonnet | テスト駆動開発手法のガイダンス |
| [debugger](../plugins/error-debugging/agents/debugger.md) | sonnet | エラー解決とテスト失敗分析 |
| [error-detective](../plugins/error-debugging/agents/error-detective.md) | sonnet | ログ分析とエラーパターン認識 |

#### パフォーマンス & 可観測性

| エージェント | モデル | 説明 |
|-------|-------|-------------|
| [performance-engineer](../plugins/observability-monitoring/agents/performance-engineer.md) | opus | アプリケーションプロファイリングと最適化 |
| [observability-engineer](../plugins/observability-monitoring/agents/observability-engineer.md) | opus | 本番環境監視、分散トレーシング、SLI/SLO管理 |
| [search-specialist](../plugins/content-marketing/agents/search-specialist.md) | haiku | 高度なWeb調査と情報統合 |

### データ & AI

#### データエンジニアリング & 分析

| エージェント | モデル | 説明 |
|-------|-------|-------------|
| [data-scientist](../plugins/machine-learning-ops/agents/data-scientist.md) | opus | データ分析、SQLクエリ、BigQuery操作 |
| [data-engineer](../plugins/data-engineering/agents/data-engineer.md) | sonnet | ETLパイプライン、データウェアハウス、ストリーミングアーキテクチャ |

#### 機械学習 & AI

| エージェント | モデル | 説明 |
|-------|-------|-------------|
| [ai-engineer](../plugins/llm-application-dev/agents/ai-engineer.md) | opus | LLMアプリケーション、RAGシステム、プロンプトパイプライン |
| [ml-engineer](../plugins/machine-learning-ops/agents/ml-engineer.md) | opus | MLパイプライン、モデルサービング、特徴量エンジニアリング |
| [mlops-engineer](../plugins/machine-learning-ops/agents/mlops-engineer.md) | opus | MLインフラストラクチャ、実験追跡、モデルレジストリ |
| [prompt-engineer](../plugins/llm-application-dev/agents/prompt-engineer.md) | opus | LLMプロンプト最適化とエンジニアリング |

### ドキュメント & テクニカルライティング

| エージェント | モデル | 説明 |
|-------|-------|-------------|
| [docs-architect](../plugins/code-documentation/agents/docs-architect.md) | opus | 包括的な技術ドキュメント生成 |
| [api-documenter](../plugins/api-testing-observability/agents/api-documenter.md) | sonnet | OpenAPI/Swagger仕様と開発者ドキュメント |
| [reference-builder](../plugins/documentation-generation/agents/reference-builder.md) | haiku | 技術リファレンスとAPIドキュメント |
| [tutorial-engineer](../plugins/code-documentation/agents/tutorial-engineer.md) | sonnet | ステップバイステップチュートリアルと教育コンテンツ |
| [mermaid-expert](../plugins/documentation-generation/agents/mermaid-expert.md) | sonnet | 図作成(フローチャート、シーケンス、ERD) |

### ビジネス & 運用

#### ビジネス分析 & 財務

| エージェント | モデル | 説明 |
|-------|-------|-------------|
| [business-analyst](../plugins/business-analytics/agents/business-analyst.md) | sonnet | メトリクス分析、レポート作成、KPI追跡 |
| [quant-analyst](../plugins/quantitative-trading/agents/quant-analyst.md) | opus | 財務モデリング、取引戦略、市場分析 |
| [risk-manager](../plugins/quantitative-trading/agents/risk-manager.md) | sonnet | ポートフォリオリスク監視と管理 |

#### マーケティング & セールス

| エージェント | モデル | 説明 |
|-------|-------|-------------|
| [content-marketer](../plugins/content-marketing/agents/content-marketer.md) | sonnet | ブログ投稿、ソーシャルメディア、メールキャンペーン |
| [sales-automator](../plugins/customer-sales-automation/agents/sales-automator.md) | haiku | コールドメール、フォローアップ、提案書生成 |

#### サポート & 法務

| エージェント | モデル | 説明 |
|-------|-------|-------------|
| [customer-support](../plugins/customer-sales-automation/agents/customer-support.md) | sonnet | サポートチケット、FAQレスポンス、顧客コミュニケーション |
| [hr-pro](../plugins/hr-legal-compliance/agents/hr-pro.md) | opus | HR運用、ポリシー、従業員関係 |
| [legal-advisor](../plugins/hr-legal-compliance/agents/legal-advisor.md) | opus | プライバシーポリシー、利用規約、法務文書 |

### SEO & コンテンツ最適化

| エージェント | モデル | 説明 |
|-------|-------|-------------|
| [seo-content-auditor](../plugins/seo-content-creation/agents/seo-content-auditor.md) | sonnet | コンテンツ品質分析、E-E-A-Tシグナル評価 |
| [seo-meta-optimizer](../plugins/seo-technical-optimization/agents/seo-meta-optimizer.md) | haiku | メタタイトルとディスクリプションの最適化 |
| [seo-keyword-strategist](../plugins/seo-technical-optimization/agents/seo-keyword-strategist.md) | haiku | キーワード分析とセマンティックバリエーション |
| [seo-structure-architect](../plugins/seo-technical-optimization/agents/seo-structure-architect.md) | haiku | コンテンツ構造とスキーママークアップ |
| [seo-snippet-hunter](../plugins/seo-technical-optimization/agents/seo-snippet-hunter.md) | haiku | 強調スニペット形式設定 |
| [seo-content-refresher](../plugins/seo-analysis-monitoring/agents/seo-content-refresher.md) | haiku | コンテンツ鮮度分析 |
| [seo-cannibalization-detector](../plugins/seo-analysis-monitoring/agents/seo-cannibalization-detector.md) | haiku | キーワード重複検出 |
| [seo-authority-builder](../plugins/seo-analysis-monitoring/agents/seo-authority-builder.md) | sonnet | E-E-A-Tシグナル分析 |
| [seo-content-writer](../plugins/seo-content-creation/agents/seo-content-writer.md) | sonnet | SEO最適化コンテンツ作成 |
| [seo-content-planner](../plugins/seo-content-creation/agents/seo-content-planner.md) | haiku | コンテンツ計画とトピッククラスター |

### 専門ドメイン

| エージェント | モデル | 説明 |
|-------|-------|-------------|
| [arm-cortex-expert](../plugins/arm-cortex-microcontrollers/agents/arm-cortex-expert.md) | sonnet | ARM Cortex-Mファームウェアとペリフェラルドライバー開発 |
| [blockchain-developer](../plugins/blockchain-web3/agents/blockchain-developer.md) | sonnet | Web3アプリ、スマートコントラクト、DeFiプロトコル |
| [payment-integration](../plugins/payment-processing/agents/payment-integration.md) | sonnet | 決済プロセッサー統合(Stripe、PayPal) |
| [legacy-modernizer](../plugins/framework-migration/agents/legacy-modernizer.md) | sonnet | レガシーコードリファクタリングとモダナイゼーション |
| [context-manager](../plugins/agent-orchestration/agents/context-manager.md) | haiku | マルチエージェントコンテキスト管理 |

## モデル構成

エージェントは、タスクの複雑さと計算要件に基づいて、特定のClaudeモデルに割り当てられます。

### モデル分布サマリー

| モデル | エージェント数 | ユースケース |
|-------|-------------|----------|
| Haiku | 47 | 高速実行タスク: テスト、ドキュメント、運用、データベース最適化、ビジネス |
| Sonnet | 97 | 複雑な推論、アーキテクチャ、言語専門知識、オーケストレーション、セキュリティ |

### モデル選択基準

#### Haiku - 高速実行 & 決定的タスク

**以下の場合に使用:**
- 明確に定義された仕様からのコード生成
- 確立されたパターンに従ったテスト作成
- 明確なテンプレートを使用したドキュメント作成
- インフラストラクチャ操作の実行
- データベースクエリ最適化の実行
- カスタマーサポート応答の処理
- SEO最適化タスクの処理
- デプロイメントパイプラインの管理

#### Sonnet - 複雑な推論 & アーキテクチャ

**以下の場合に使用:**
- システムアーキテクチャの設計
- 技術選択の意思決定
- セキュリティ監査の実行
- アーキテクチャパターンのコードレビュー
- 複雑なAI/MLパイプラインの作成
- 言語固有の専門知識の提供
- マルチエージェントワークフローのオーケストレーション
- ビジネスクリティカルな法務/HR事項の処理

### ハイブリッドオーケストレーションパターン

プラグインエコシステムは、最適なパフォーマンスとコスト効率のためにSonnet + Haikuオーケストレーションを活用します:

#### パターン1: 計画 → 実行
```
Sonnet: backend-architect (APIアーキテクチャを設計)
  ↓
Haiku: 仕様に従ってAPIエンドポイントを生成
  ↓
Haiku: test-automator (包括的なテストを生成)
  ↓
Sonnet: code-reviewer (アーキテクチャレビュー)
```

#### パターン2: 推論 → アクション (インシデント対応)
```
Sonnet: incident-responder (問題を診断、戦略を作成)
  ↓
Haiku: devops-troubleshooter (修正を実行)
  ↓
Haiku: deployment-engineer (ホットフィックスをデプロイ)
  ↓
Haiku: 監視アラートを実装
```

#### パターン3: 複雑 → シンプル (データベース設計)
```
Sonnet: database-architect (スキーマ設計、技術選択)
  ↓
Haiku: sql-pro (マイグレーションスクリプトを生成)
  ↓
Haiku: database-admin (マイグレーションを実行)
  ↓
Haiku: database-optimizer (クエリパフォーマンスを調整)
```

#### パターン4: マルチエージェントワークフロー
```
フルスタック機能開発:
Sonnet: backend-architect + frontend-developer (コンポーネントを設計)
  ↓
Haiku: 設計に従ってコードを生成
  ↓
Haiku: test-automator (ユニット + 統合テスト)
  ↓
Sonnet: security-auditor (セキュリティレビュー)
  ↓
Haiku: deployment-engineer (CI/CDセットアップ)
  ↓
Haiku: 可観測性スタックをセットアップ
```

## エージェント呼び出し

### 自然言語

Claudeにどのスペシャリストを使用するか推論させる必要がある場合、エージェントは自然言語で呼び出すことができます:

```
"backend-architectを使用して認証APIを設計して"
"security-auditorにOWASP脆弱性をスキャンさせて"
"performance-engineerにこのデータベースクエリを最適化させて"
```

### スラッシュコマンド

多くのエージェントは、直接呼び出しのためのプラグインスラッシュコマンドからアクセスできます:

```bash
/backend-development:feature-development user authentication
/security-scanning:security-sast
/incident-response:smart-fix "memory leak in payment service"
```

## コントリビューション

新しいエージェントを追加するには:

1. `plugins/{plugin-name}/agents/{agent-name}.md`を作成
2. 名前、説明、モデル割り当てを含むフロントマターを追加
3. 包括的なシステムプロンプトを記述
4. `.claude-plugin/marketplace.json`のプラグイン定義を更新

詳細は[コントリビューションガイド](../../../CONTRIBUTING.md)を参照してください。
