> **[English](../../../../plugins/incident-response/commands/smart-fix.md) | 日本語**

# マルチエージェントオーケストレーションによるインテリジェントな問題解決

[拡張思考: このワークフローは、AI支援デバッグツールと可観測性プラットフォームを活用して本番問題を体系的に診断および解決する高度なデバッグおよび解決パイプラインを実装します。インテリジェントなデバッグ戦略は、AI コードアシスタント (GitHub Copilot、Claude Code)、可観測性プラットフォーム (Sentry、DataDog、OpenTelemetry)、リグレッション追跡のための git bisect 自動化、分散トレーシングや構造化ログなどの本番セーフなデバッグ技術を含む、最新の 2024/2025 プラクティスを使用して、自動根本原因分析と人間の専門知識を組み合わせます。プロセスは厳密な 4 フェーズアプローチに従います：(1) 問題分析フェーズ - error-detective と debugger エージェントがエラートレース、ログ、再現手順、可観測性データを分析して、上流/下流の影響を含む障害の完全なコンテキストを理解、(2) 根本原因調査フェーズ - debugger と code-reviewer エージェントが深層コード分析、導入コミットを識別するための自動 git bisect、依存関係互換性チェック、正確な障害メカニズムを分離するための状態検査を実行、(3) 修正実装フェーズ - ドメイン固有のエージェント (python-pro、typescript-pro、rust-expert など) が本番セーフプラクティスに従いながら、ユニット、統合、エッジケーステストを含む包括的なテストカバレッジを持つ最小限の修正を実装、(4) 検証フェーズ - test-automator と performance-engineer エージェントがリグレッションスイート、パフォーマンスベンチマーク、セキュリティスキャンを実行し、新しい問題が導入されていないことを検証。複数のシステムにまたがる複雑な問題には、明示的なコンテキスト受け渡しと状態共有を伴う専門エージェント間の調整された協力 (database-optimizer → performance-engineer → devops-troubleshooter) が必要です。ワークフローは、症状を治療するのではなく根本原因を理解すること、永続的なアーキテクチャの改善を実装すること、強化された監視とアラートを通じて検出を自動化すること、型システムの強化、静的分析ルール、改善されたエラー処理パターンを通じて将来の発生を防ぐことを強調します。成功は問題解決だけでなく、平均復旧時間 (MTTR) の短縮、類似問題の防止、システムレジリエンスの向上によって測定されます。]

## フェーズ1: 問題分析 - エラー検出とコンテキスト収集

Taskツールをsubagent_type="error-debugging::error-detective"に続いてsubagent_type="error-debugging::debugger"で使用：

**最初: Error-Detective分析**

**プロンプト:**
```
エラートレース、ログ、可観測性データを分析: $ARGUMENTS

成果物:
1. エラーシグネチャ分析: 例外タイプ、メッセージパターン、頻度、最初の発生
2. スタックトレースの深堀り: 障害場所、コールチェーン、関与コンポーネント
3. 再現手順: 最小限のテストケース、環境要件、必要なデータフィクスチャ
4. 可観測性コンテキスト:
   - Sentry/DataDogエラーグループとトレンド
   - リクエストフローを示す分散トレース (OpenTelemetry/Jaeger)
   - 構造化ログ (相関IDを含むJSONログ)
   - APMメトリクス: レイテンシスパイク、エラーレート、リソース使用
5. ユーザー影響評価: 影響を受けたユーザーセグメント、エラーレート、ビジネスメトリクスへの影響
6. タイムライン分析: いつ始まったか、デプロイメント/設定変更との相関
7. 関連症状: 類似エラー、カスケード障害、上流/下流の影響

使用する最新のデバッグ技術:
- AI支援ログ分析 (パターン検出、異常識別)
- マイクロサービス間の分散トレース相関
- 本番セーフデバッグ (コード変更なし、可観測性データを使用)
- 重複除去と追跡のためのエラーフィンガープリンティング
```

**期待される出力:**
```
ERROR_SIGNATURE: {例外タイプ + キーメッセージパターン}
FREQUENCY: {カウント、レート、トレンド}
FIRST_SEEN: {タイムスタンプまたはgitコミット}
STACK_TRACE: {主要フレームがハイライトされたフォーマット済みトレース}
REPRODUCTION: {最小限の手順 + サンプルデータ}
OBSERVABILITY_LINKS: [Sentry URL、DataDogダッシュボード、トレースID]
USER_IMPACT: {影響を受けたユーザー、重要度、ビジネス影響}
TIMELINE: {いつ始まったか、変更との相関}
RELATED_ISSUES: [類似エラー、カスケード障害]
```

**2番目: Debugger根本原因識別**

**プロンプト:**
```
error-detective出力を使用して根本原因調査を実行:

Error-Detectiveからのコンテキスト:
- エラーシグネチャ: {ERROR_SIGNATURE}
- スタックトレース: {STACK_TRACE}
- 再現: {REPRODUCTION}
- 可観測性: {OBSERVABILITY_LINKS}

成果物:
1. 裏付け証拠を含む根本原因仮説
2. コードレベル分析: 変数状態、制御フロー、タイミング問題
3. Git bisect分析: 導入コミットの識別 (git bisect runで自動化)
4. 依存関係分析: バージョン競合、API変更、設定ドリフト
5. 状態検査: データベース状態、キャッシュ状態、外部APIレスポンス
6. 障害メカニズム: コードがこれらの特定条件下で失敗する理由
7. トレードオフを含む修正戦略オプション (クイック修正 vs 適切な修正)

次のフェーズに必要なコンテキスト:
- 変更が必要な正確なファイルパスと行番号
- 影響を受けるデータ構造またはAPIコントラクト
- 更新が必要な可能性のある依存関係
- 修正を検証するためのテストシナリオ
- 維持すべきパフォーマンス特性
```

**期待される出力:**
```
ROOT_CAUSE: {証拠を含む技術的説明}
INTRODUCING_COMMIT: {bisect経由で見つかった場合はgit SHA + サマリー}
AFFECTED_FILES: [特定の行番号を含むファイルパス]
FAILURE_MECHANISM: {なぜ失敗するか - 競合状態、nullチェック、型不一致など}
DEPENDENCIES: [関連システム、ライブラリ、外部API]
FIX_STRATEGY: {理由付きの推奨アプローチ}
QUICK_FIX_OPTION: {該当する場合の一時的な緩和策}
PROPER_FIX_OPTION: {長期的な解決策}
TESTING_REQUIREMENTS: [カバーすべきシナリオ]
```

## フェーズ2: 根本原因調査 - 深層コード分析

Taskツールをsubagent_type="error-debugging::debugger"およびsubagent_type="comprehensive-review::code-reviewer"で体系的な調査に使用：

**最初: Debuggerコード分析**

**プロンプト:**
```
深層コード分析とbisect調査を実行:

フェーズ1からのコンテキスト:
- 根本原因: {ROOT_CAUSE}
- 影響を受けるファイル: {AFFECTED_FILES}
- 障害メカニズム: {FAILURE_MECHANISM}
- 導入コミット: {INTRODUCING_COMMIT}

成果物:
1. コードパス分析: エントリーポイントから障害までの実行をトレース
2. 変数状態追跡: 主要な決定ポイントでの値
3. 制御フロー分析: 分岐、ループ、非同期操作
4. Git bisect自動化: 正確な破損コミットを識別するbisectスクリプトの作成
   ```bash
   git bisect start HEAD v1.2.3
   git bisect run ./test_reproduction.sh
   ```
5. 依存関係互換性マトリックス: 動作/失敗するバージョンの組み合わせ
6. 設定分析: 環境変数、機能フラグ、デプロイメント設定
7. タイミングと競合状態分析: 非同期操作、イベント順序、ロック
8. メモリとリソース分析: リーク、枯渇、競合

最新の調査技術:
- AI支援コード説明 (Claude/Copilotで複雑なロジックを理解)
- 再現テストを伴う自動git bisect
- 依存関係グラフ分析 (npm ls、go mod graph、pip show)
- 設定ドリフト検出 (ステージングと本番を比較)
- 本番トレースを使用したタイムトラベルデバッグ
```

**期待される出力:**
```
CODE_PATH: {エントリー → ... → 主要変数を含む障害場所}
STATE_AT_FAILURE: {変数値、オブジェクト状態、データベース状態}
BISECT_RESULT: {バグを導入した正確なコミット + diff}
DEPENDENCY_ISSUES: [バージョン競合、破壊的変更、CVE]
CONFIGURATION_DRIFT: {環境間の違い}
RACE_CONDITIONS: {非同期問題、イベント順序の問題}
ISOLATION_VERIFICATION: {単一の根本原因か複数の問題かを確認}
```

**2番目: Code-Reviewer深堀り**

**プロンプト:**
```
コードロジックをレビューし設計問題を識別:

Debuggerからのコンテキスト:
- コードパス: {CODE_PATH}
- 障害時の状態: {STATE_AT_FAILURE}
- Bisect結果: {BISECT_RESULT}

成果物:
1. ロジック欠陥分析: 誤った仮定、欠落したエッジケース、誤ったアルゴリズム
2. 型安全性のギャップ: より強い型が問題を防げる場所
3. エラー処理レビュー: 欠落したtry-catch、未処理のpromise、panicシナリオ
4. コントラクト検証: 入力検証のギャップ、出力保証が満たされていない
5. アーキテクチャの問題: 密結合、欠落した抽象化、レイヤリング違反
6. 類似パターン: 同じ脆弱性を持つ他のコード場所
7. 修正設計: 最小限の変更 vs リファクタリング vs アーキテクチャ改善

レビューチェックリスト:
- null/undefined値は正しく処理されているか?
- 非同期操作は適切にawait/チェーンされているか?
- エラーケースは明示的に処理されているか?
- 型アサーションは安全か?
- APIコントラクトは尊重されているか?
- 副作用は分離されているか?
```

**期待される出力:**
```
LOGIC_FLAWS: [特定の誤った仮定またはアルゴリズム]
TYPE_SAFETY_GAPS: [型が問題を防げる場所]
ERROR_HANDLING_GAPS: [未処理のエラーパス]
SIMILAR_VULNERABILITIES: [同じパターンを持つ他のコード]
FIX_DESIGN: {最小限の変更アプローチ}
REFACTORING_OPPORTUNITIES: {より大きな改善が正当化される場合}
ARCHITECTURAL_CONCERNS: {システム的な問題が存在する場合}
```

## フェーズ3: 修正実装 - ドメイン固有エージェント実行

フェーズ2の出力に基づいて、Taskツールを使用して適切なドメインエージェントにルーティング：

**ルーティングロジック:**
- Python問題 → subagent_type="python-development::python-pro"
- TypeScript/JavaScript → subagent_type="javascript-typescript::typescript-pro"
- Go → subagent_type="systems-programming::golang-pro"
- Rust → subagent_type="systems-programming::rust-pro"
- SQL/Database → subagent_type="database-cloud-optimization::database-optimizer"
- Performance → subagent_type="application-performance::performance-engineer"
- Security → subagent_type="security-scanning::security-auditor"

**プロンプトテンプレート (言語に合わせて調整):**
```
包括的なテストカバレッジを持つ本番セーフ修正を実装:

フェーズ2からのコンテキスト:
- 根本原因: {ROOT_CAUSE}
- ロジック欠陥: {LOGIC_FLAWS}
- 修正設計: {FIX_DESIGN}
- 型安全性のギャップ: {TYPE_SAFETY_GAPS}
- 類似の脆弱性: {SIMILAR_VULNERABILITIES}

成果物:
1. 根本原因に対処する最小限の修正実装 (症状ではなく)
2. ユニットテスト:
   - 特定の障害ケースの再現
   - エッジケース (境界値、null/empty、オーバーフロー)
   - エラーパスカバレッジ
3. 統合テスト:
   - 実際の依存関係を含むエンドツーエンドシナリオ
   - 適切な場合の外部APIモック
   - データベース状態検証
4. リグレッションテスト:
   - 類似の脆弱性のテスト
   - 関連コードパスをカバーするテスト
5. パフォーマンス検証:
   - 劣化がないことを示すベンチマーク
   - 該当する場合の負荷テスト
6. 本番セーフプラクティス:
   - 段階的ロールアウトのための機能フラグ
   - 修正が失敗した場合のグレースフルデグラデーション
   - 修正検証のための監視フック
   - デバッグのための構造化ログ

最新の実装技術 (2024/2025):
- テスト生成のためのAIペアプログラミング (GitHub Copilot、Claude Code)
- 型駆動開発 (TypeScript、mypy、clippyを活用)
- コントラクトファーストAPI (OpenAPI、gRPCスキーマ)
- 可観測性ファースト (構造化ログ、メトリクス、トレース)
- 防御的プログラミング (明示的なエラー処理、検証)

実装要件:
- 既存のコードパターンと規約に従う
- 戦略的デバッグログを追加 (JSON構造化ログ)
- 包括的な型アノテーションを含める
- エラーメッセージを実行可能にする (コンテキスト、提案を含める)
- 後方互換性を維持 (破壊的な場合はAPIをバージョン管理)
- 分散トレーシングのためのOpenTelemetryスパンを追加
- 監視のためのメトリクスカウンターを含める (成功/失敗率)
```

**期待される出力:**
```
FIX_SUMMARY: {何が変更され、なぜか - 根本原因 vs 症状}
CHANGED_FILES: [
  {path: "...", changes: "...", reasoning: "..."}
]
NEW_FILES: [{path: "...", purpose: "..."}]
TEST_COVERAGE: {
  unit: "Xシナリオ",
  integration: "Yシナリオ",
  edge_cases: "Zシナリオ",
  regression: "Wシナリオ"
}
TEST_RESULTS: {all_passed: true/false, details: "..."}
BREAKING_CHANGES: {none | 移行パスを含むAPI変更}
OBSERVABILITY_ADDITIONS: [
  {type: "log", location: "...", purpose: "..."},
  {type: "metric", name: "...", purpose: "..."},
  {type: "trace", span: "...", purpose: "..."}
]
FEATURE_FLAGS: [{flag: "...", rollout_strategy: "..."}]
BACKWARD_COMPATIBILITY: {maintained | 緩和策を含む破壊的}
```

## フェーズ4: 検証 - 自動テストとパフォーマンス検証

Taskツールをsubagent_type="unit-testing::test-automator"およびsubagent_type="application-performance::performance-engineer"で使用：

**最初: Test-Automatorリグレッションスイート**

**プロンプト:**
```
包括的なリグレッションテストを実行し、修正品質を検証:

フェーズ3からのコンテキスト:
- 修正サマリー: {FIX_SUMMARY}
- 変更されたファイル: {CHANGED_FILES}
- テストカバレッジ: {TEST_COVERAGE}
- テスト結果: {TEST_RESULTS}

成果物:
1. フルテストスイート実行:
   - ユニットテスト (既存のすべて + 新規)
   - 統合テスト
   - エンドツーエンドテスト
   - コントラクトテスト (マイクロサービスの場合)
2. リグレッション検出:
   - 修正前/後のテスト結果を比較
   - 新しい失敗を識別
   - すべてのエッジケースがカバーされていることを検証
3. テスト品質評価:
   - コードカバレッジメトリクス (行、分岐、条件)
   - 該当する場合のミューテーションテスト
   - テストの決定性 (複数回実行)
4. クロス環境テスト:
   - ステージング/QA環境でテスト
   - 本番類似のデータ量でテスト
   - 現実的なネットワーク条件でテスト
5. セキュリティテスト:
   - 認証/認可チェック
   - 入力検証テスト
   - SQLインジェクション、XSS防止
   - 依存関係脆弱性スキャン
6. 自動リグレッションテスト生成:
   - AIを使用して追加のエッジケーステストを生成
   - 複雑なロジックのためのプロパティベーステスト
   - 入力検証のためのファジング

最新のテストプラクティス (2024/2025):
- AI生成テストケース (GitHub Copilot、Claude Code)
- UI/APIコントラクトのスナップショットテスト
- フロントエンドのビジュアルリグレッションテスト
- レジリエンステストのためのカオスエンジニアリング
- 負荷テストのための本番トラフィックリプレイ
```

**期待される出力:**
```
TEST_RESULTS: {
  total: N,
  passed: X,
  failed: Y,
  skipped: Z,
  new_failures: [ある場合はリスト],
  flaky_tests: [ある場合はリスト]
}
CODE_COVERAGE: {
  line: "X%",
  branch: "Y%",
  function: "Z%",
  delta: "+/-W%"
}
REGRESSION_DETECTED: {yes/no + yesの場合は詳細}
CROSS_ENV_RESULTS: {staging: "...", qa: "..."}
SECURITY_SCAN: {
  vulnerabilities: [リストまたは"none"],
  static_analysis: "...",
  dependency_audit: "..."
}
TEST_QUALITY: {deterministic: true/false, coverage_adequate: true/false}
```

**2番目: Performance-Engineer検証**

**プロンプト:**
```
パフォーマンス影響を測定し、リグレッションがないことを検証:

Test-Automatorからのコンテキスト:
- テスト結果: {TEST_RESULTS}
- コードカバレッジ: {CODE_COVERAGE}
- 修正サマリー: {FIX_SUMMARY}

成果物:
1. パフォーマンスベンチマーク:
   - 応答時間 (p50、p95、p99)
   - スループット (リクエスト/秒)
   - リソース使用率 (CPU、メモリ、I/O)
   - データベースクエリパフォーマンス
2. ベースラインとの比較:
   - 修正前/後のメトリクス
   - 許容可能な劣化しきい値
   - パフォーマンス改善の機会
3. 負荷テスト:
   - ピーク負荷下のストレステスト
   - メモリリークのためのソークテスト
   - バースト処理のためのスパイクテスト
4. APM分析:
   - 分散トレース分析
   - 遅いクエリ検出
   - N+1クエリパターン
5. リソースプロファイリング:
   - CPUフレームグラフ
   - メモリ割り当て追跡
   - Goroutine/スレッドリーク
6. 本番準備:
   - キャパシティプランニングへの影響
   - スケーリング特性
   - コスト影響 (クラウドリソース)

最新のパフォーマンスプラクティス:
- OpenTelemetry計装
- 継続的プロファイリング (Pyroscope、pprof)
- リアルユーザーモニタリング (RUM)
- 合成監視
```

**期待される出力:**
```
PERFORMANCE_BASELINE: {
  response_time_p95: "Xms",
  throughput: "Y req/s",
  cpu_usage: "Z%",
  memory_usage: "W MB"
}
PERFORMANCE_AFTER_FIX: {
  response_time_p95: "Xms (delta)",
  throughput: "Y req/s (delta)",
  cpu_usage: "Z% (delta)",
  memory_usage: "W MB (delta)"
}
PERFORMANCE_IMPACT: {
  verdict: "improved|neutral|degraded",
  acceptable: true/false,
  reasoning: "..."
}
LOAD_TEST_RESULTS: {
  max_throughput: "...",
  breaking_point: "...",
  memory_leaks: "none|detected"
}
APM_INSIGHTS: [遅いクエリ、N+1パターン、ボトルネック]
PRODUCTION_READY: {yes/no + noの場合はブロッカー}
```

**3番目: Code-Reviewer最終承認**

**プロンプト:**
```
最終コードレビューを実行しデプロイメントを承認:

テストからのコンテキスト:
- テスト結果: {TEST_RESULTS}
- リグレッション検出: {REGRESSION_DETECTED}
- パフォーマンス影響: {PERFORMANCE_IMPACT}
- セキュリティスキャン: {SECURITY_SCAN}

成果物:
1. コード品質レビュー:
   - プロジェクト規約に従っている
   - コードスメルやアンチパターンなし
   - 適切なエラー処理
   - 十分なログと可観測性
2. アーキテクチャレビュー:
   - システム境界を維持
   - 密結合が導入されていない
   - スケーラビリティの考慮
3. セキュリティレビュー:
   - セキュリティ脆弱性なし
   - 適切な入力検証
   - 認証/認可が正しい
4. ドキュメントレビュー:
   - 必要な場所のコードコメント
   - APIドキュメント更新
   - 運用影響がある場合はランブック更新
5. デプロイメント準備:
   - ロールバック計画の文書化
   - 機能フラグ戦略の定義
   - 監視/アラートの設定
6. リスク評価:
   - 爆発半径の推定
   - ロールアウト戦略の推奨
   - 成功メトリクスの定義

レビューチェックリスト:
- すべてのテストが合格
- パフォーマンスリグレッションなし
- セキュリティ脆弱性に対処
- 破壊的変更が文書化されている
- 後方互換性が維持されている
- 可観測性が十分
- デプロイメント計画が明確
```

**期待される出力:**
```
REVIEW_STATUS: {APPROVED|NEEDS_REVISION|BLOCKED}
CODE_QUALITY: {スコア/評価}
ARCHITECTURE_CONCERNS: [リストまたは"none"]
SECURITY_CONCERNS: [リストまたは"none"]
DEPLOYMENT_RISK: {low|medium|high}
ROLLBACK_PLAN: {
  steps: ["..."],
  estimated_time: "X分",
  data_recovery: "..."
}
ROLLOUT_STRATEGY: {
  approach: "canary|blue-green|rolling|big-bang",
  phases: ["..."],
  success_metrics: ["..."],
  abort_criteria: ["..."]
}
MONITORING_REQUIREMENTS: [
  {metric: "...", threshold: "...", action: "..."}
]
FINAL_VERDICT: {
  approved: true/false,
  blockers: [承認されていない場合はリスト],
  recommendations: ["..."]
}
```

## フェーズ5: ドキュメントと防止 - 長期的レジリエンス

Taskツールをsubagent_type="comprehensive-review::code-reviewer"で防止戦略に使用：

**プロンプト:**
```
修正を文書化し、再発を避けるための防止戦略を実装:

フェーズ4からのコンテキスト:
- 最終評価: {FINAL_VERDICT}
- レビューステータス: {REVIEW_STATUS}
- 根本原因: {ROOT_CAUSE}
- ロールバック計画: {ROLLBACK_PLAN}
- 監視要件: {MONITORING_REQUIREMENTS}

成果物:
1. コードドキュメント:
   - 自明でないロジックのインラインコメント (最小限)
   - 関数/クラスドキュメントの更新
   - APIコントラクトドキュメント
2. 運用ドキュメント:
   - 修正説明とバージョンを含むCHANGELOGエントリー
   - ステークホルダー向けリリースノート
   - オンコールエンジニア向けランブックエントリー
   - 事後検証ドキュメント (高重要度インシデントの場合)
3. 静的分析による防止:
   - リンティングルールの追加 (eslint、ruff、golangci-lint)
   - より厳格なコンパイラ/型チェッカー設定を構成
   - ドメイン固有のパターンのためのカスタムリントルールを追加
   - pre-commitフックの更新
4. 型システムの強化:
   - 網羅性チェックの追加
   - 判別共用体/sum型の使用
   - const/readonlyモディファイアの追加
   - 検証のためのブランド型の活用
5. 監視とアラート:
   - エラーレートアラートの作成 (Sentry、DataDog)
   - ビジネスロジックのカスタムメトリクスの追加
   - 合成モニターの設定 (Pingdom、Checkly)
   - SLO/SLIダッシュボードの構成
6. アーキテクチャ改善:
   - 類似の脆弱性パターンの識別
   - より良い分離のためのリファクタリングの提案
   - 設計決定の文書化
   - 必要に応じてアーキテクチャ図の更新
7. テスト改善:
   - プロパティベーステストの追加
   - 統合テストシナリオの拡張
   - カオスエンジニアリングテストの追加
   - テスト戦略ギャップの文書化

最新の防止プラクティス (2024/2025):
- AI支援コードレビュールール (GitHub Copilot、Claude Code)
- 継続的セキュリティスキャン (Snyk、Dependabot)
- Infrastructure as Code検証 (Terraform validate、CloudFormation Linter)
- APIのコントラクトテスト (Pact、OpenAPI検証)
- 可観測性駆動開発 (デプロイ前に計装)
```

**期待される出力:**
```
DOCUMENTATION_UPDATES: [
  {file: "CHANGELOG.md", summary: "..."},
  {file: "docs/runbook.md", summary: "..."},
  {file: "docs/architecture.md", summary: "..."}
]
PREVENTION_MEASURES: {
  static_analysis: [
    {tool: "eslint", rule: "...", reason: "..."},
    {tool: "ruff", rule: "...", reason: "..."}
  ],
  type_system: [
    {enhancement: "...", location: "...", benefit: "..."}
  ],
  pre_commit_hooks: [
    {hook: "...", purpose: "..."}
  ]
}
MONITORING_ADDED: {
  alerts: [
    {name: "...", threshold: "...", channel: "..."}
  ],
  dashboards: [
    {name: "...", metrics: [...], url: "..."}
  ],
  slos: [
    {service: "...", sli: "...", target: "...", window: "..."}
  ]
}
ARCHITECTURAL_IMPROVEMENTS: [
  {improvement: "...", reasoning: "...", effort: "small|medium|large"}
]
SIMILAR_VULNERABILITIES: {
  found: N,
  locations: [...],
  remediation_plan: "..."
}
FOLLOW_UP_TASKS: [
  {task: "...", priority: "high|medium|low", owner: "..."}
]
POSTMORTEM: {
  created: true/false,
  location: "...",
  incident_severity: "SEV1|SEV2|SEV3|SEV4"
}
KNOWLEDGE_BASE_UPDATES: [
  {article: "...", summary: "..."}
]
```

## 複雑な問題のマルチドメイン調整

複数のドメインにまたがる問題の場合、明示的なコンテキスト受け渡しで専門エージェントを順次調整：

**例1: アプリケーションタイムアウトを引き起こすデータベースパフォーマンス問題**

**シーケンス:**
1. **フェーズ1-2**: error-detective + debuggerが遅いデータベースクエリを識別
2. **フェーズ3a**: Task(subagent_type="database-cloud-optimization::database-optimizer")
   - 適切なインデックスでクエリを最適化
   - コンテキスト: "クエリ実行が5秒かかっている、user_id列のインデックスが欠落、N+1クエリパターン検出"
3. **フェーズ3b**: Task(subagent_type="application-performance::performance-engineer")
   - 頻繁にアクセスされるデータのキャッシングレイヤーを追加
   - コンテキスト: "user_id列にインデックスを追加することでデータベースクエリを5秒から50msに最適化。リクエストごとに100+のユーザーレコードを読み込むN+1クエリパターンのため、アプリケーションは依然として2秒の応答時間を経験。ユーザープロファイルに5分のTTLでRedisキャッシュを追加。"
4. **フェーズ3c**: Task(subagent_type="incident-response::devops-troubleshooter")
   - クエリパフォーマンスとキャッシュヒット率の監視を構成
   - コンテキスト: "Redisでキャッシュレイヤーを追加。以下の監視が必要: クエリp95レイテンシー (しきい値: 100ms)、キャッシュヒット率 (しきい値: >80%)、キャッシュメモリ使用量 (80%でアラート)。"

**例2: 本番のフロントエンドJavaScriptエラー**

**シーケンス:**
1. **フェーズ1**: error-detectiveがSentryエラーレポートを分析
   - コンテキスト: "TypeError: Cannot read property 'map' of undefined、過去1時間で500+発生、iOS 14のSafariユーザーに影響"
2. **フェーズ2**: debugger + code-reviewerが調査
   - コンテキスト: "APIレスポンスが結果がない場合に空配列の代わりにnullを返すことがある。フロントエンドは配列を想定。"
3. **フェーズ3a**: Task(subagent_type="javascript-typescript::typescript-pro")
   - 適切なnullチェックでフロントエンドを修正
   - 型ガードを追加
   - コンテキスト: "バックエンドAPI /api/usersエンドポイントが結果がない場合に[]の代わりにnullを返している。両方を処理するようにフロントエンドを修正。TypeScript strict null checksを追加。"
4. **フェーズ3b**: Task(subagent_type="backend-development::backend-architect")
   - 常に配列を返すようにバックエンドを修正
   - APIコントラクトを更新
   - コンテキスト: "フロントエンドはnullを処理するようになったが、APIはコントラクトに従い、nullではなく[]を返すべき。これを文書化するためにOpenAPIスペックを更新。"
5. **フェーズ4**: test-automatorがクロスブラウザテストを実行
6. **フェーズ5**: code-reviewerがAPIコントラクト変更を文書化

**例3: 認証のセキュリティ脆弱性**

**シーケンス:**
1. **フェーズ1**: error-detectiveがセキュリティスキャンレポートをレビュー
   - コンテキスト: "ログインエンドポイントのSQLインジェクション脆弱性、Snyk重要度: HIGH"
2. **フェーズ2**: debugger + security-auditorが調査
   - コンテキスト: "SQL WHERE句でユーザー入力がサニタイズされていない、認証バイパスを許す"
3. **フェーズ3**: Task(subagent_type="security-scanning::security-auditor")
   - パラメータ化クエリを実装
   - 入力検証を追加
   - レート制限を追加
   - コンテキスト: "文字列連結をプリペアドステートメントに置き換える。メール形式の入力検証を追加。レート制限を実装 (15分あたり5回の試行)。"
4. **フェーズ4a**: test-automatorがセキュリティテストを追加
   - SQLインジェクション試行
   - ブルートフォースシナリオ
5. **フェーズ4b**: security-auditorが侵入テストを実行
6. **フェーズ5**: code-reviewerがセキュリティ改善を文書化し、事後検証を作成

**コンテキスト受け渡しテンプレート:**
```
{next_agent}のためのコンテキスト:

{previous_agent}によって完了:
- {作業のサマリー}
- {主要な発見}
- {行われた変更}

残りの作業:
- {次のエージェントのための具体的なタスク}
- {修正すべきファイル}
- {従うべき制約}

依存関係:
- {影響を受けるシステムまたはコンポーネント}
- {必要なデータ}
- {統合ポイント}

成功基準:
- {測定可能な成果}
- {検証ステップ}
```

## 設定オプション

呼び出し時に優先順位を設定してワークフロー動作をカスタマイズ：

**VERIFICATION_LEVEL**: テストと検証の深度を制御
- **minimal**: 基本テストでクイック修正、パフォーマンスベンチマークをスキップ
  - 使用: 低リスクバグ、表面的な問題、ドキュメント修正
  - フェーズ: 1-2-3 (詳細なフェーズ4をスキップ)
  - タイムライン: ~30分
- **standard**: フルテストカバレッジ + コードレビュー (デフォルト)
  - 使用: ほとんどの本番バグ、機能問題、データバグ
  - フェーズ: 1-2-3-4 (すべての検証)
  - タイムライン: ~2-4時間
- **comprehensive**: 標準 + セキュリティ監査 + パフォーマンスベンチマーク + カオステスト
  - 使用: セキュリティ問題、パフォーマンス問題、データ破損、高トラフィックシステム
  - フェーズ: 1-2-3-4-5 (長期的防止を含む)
  - タイムライン: ~1-2日

**PREVENTION_FOCUS**: 将来の防止への投資を制御
- **none**: 修正のみ、防止作業なし
  - 使用: 一回限りの問題、廃止予定のレガシーコード、外部ライブラリのバグ
  - 出力: コード修正 + テストのみ
- **immediate**: テストと基本的なリンティングを追加 (デフォルト)
  - 使用: 一般的なバグ、繰り返しパターン、チームコードベース
  - 出力: 修正 + テスト + リンティングルール + 最小限の監視
- **comprehensive**: 監視、アーキテクチャ改善を含む完全な防止スイート
  - 使用: 高重要度インシデント、システム的問題、アーキテクチャ問題
  - 出力: 修正 + テスト + リンティング + 監視 + アーキテクチャドキュメント + 事後検証

**ROLLOUT_STRATEGY**: デプロイメントアプローチを制御
- **immediate**: 本番に直接デプロイ (ホットフィックス、低リスク変更用)
- **canary**: トラフィックのサブセットへの段階的ロールアウト (中リスクのデフォルト)
- **blue-green**: 即座のロールバック機能を持つ完全な環境スイッチ
- **feature-flag**: コードをデプロイするが機能フラグでアクティベーションを制御 (高リスク変更)

**OBSERVABILITY_LEVEL**: 計装の深度を制御
- **minimal**: 基本的なエラーログのみ
- **standard**: 構造化ログ + 主要メトリクス (デフォルト)
- **comprehensive**: 完全な分散トレーシング + カスタムダッシュボード + SLO

**呼び出し例:**
```
問題: チェックアウトページでユーザーがタイムアウトエラーを経験 (500+エラー/時間)

設定:
- VERIFICATION_LEVEL: comprehensive (収益に影響)
- PREVENTION_FOCUS: comprehensive (ビジネス影響が高い)
- ROLLOUT_STRATEGY: canary (最初に5%のトラフィックでテスト)
- OBSERVABILITY_LEVEL: comprehensive (詳細な監視が必要)
```

## 最新デバッグツール統合

このワークフローは最新の2024/2025ツールを活用：

**可観測性プラットフォーム:**
- Sentry (エラー追跡、リリース追跡、パフォーマンス監視)
- DataDog (APM、ログ、トレース、インフラストラクチャ監視)
- OpenTelemetry (ベンダー中立の分散トレーシング)
- Honeycomb (複雑な分散システムのための可観測性)
- New Relic (APM、合成監視)

**AI支援デバッグ:**
- GitHub Copilot (コード提案、テスト生成、バグパターン認識)
- Claude Code (包括的なコード分析、アーキテクチャレビュー)
- Sourcegraph Cody (コードベース検索と理解)
- Tabnine (バグ防止を伴うコード補完)

**Gitとバージョン管理:**
- 再現スクリプトを使用した自動git bisect
- bisectコミットでの自動テストのためのGitHub Actions
- コード所有権を識別するためのGit blame分析
- 変更を理解するためのコミットメッセージ分析

**テストフレームワーク:**
- Jest/Vitest (JavaScript/TypeScriptユニット/統合テスト)
- pytest (フィクスチャとパラメータ化を使用したPythonテスト)
- Go testing + testify (Goユニットとテーブル駆動テスト)
- Playwright/Cypress (エンドツーエンドブラウザテスト)
- k6/Locust (負荷とパフォーマンステスト)

**静的分析:**
- ESLint/Prettier (JavaScript/TypeScriptリンティングとフォーマット)
- Ruff/mypy (Pythonリンティングと型チェック)
- golangci-lint (Go包括的リンティング)
- Clippy (Rustリンティングとベストプラクティス)
- SonarQube (エンタープライズコード品質とセキュリティ)

**パフォーマンスプロファイリング:**
- Chrome DevTools (フロントエンドパフォーマンス)
- pprof (Goプロファイリング)
- py-spy (Pythonプロファイリング)
- Pyroscope (継続的プロファイリング)
- CPU/メモリ分析のためのフレームグラフ

**セキュリティスキャン:**
- Snyk (依存関係脆弱性スキャン)
- Dependabot (自動依存関係更新)
- OWASP ZAP (セキュリティテスト)
- Semgrep (カスタムセキュリティルール)
- npm audit / pip-audit / cargo audit

## 成功基準

修正は以下のすべてが満たされた場合に完了と見なされます：

**根本原因の理解:**
- 裏付け証拠を伴う根本原因が識別されている
- 障害メカニズムが明確に文書化されている
- 導入コミットが識別されている (git bisect経由で該当する場合)
- 類似の脆弱性がカタログ化されている

**修正品質:**
- 修正は症状ではなく根本原因に対処している
- 最小限のコード変更 (過度な設計を避ける)
- プロジェクト規約とパターンに従っている
- コードスメルやアンチパターンが導入されていない
- 後方互換性が維持されている (または破壊的変更が文書化されている)

**テスト検証:**
- すべての既存テストが合格 (ゼロリグレッション)
- 新しいテストが特定のバグ再現をカバーしている
- エッジケースとエラーパスがテストされている
- 統合テストがエンドツーエンドの動作を検証している
- テストカバレッジが増加 (または高レベルで維持されている)

**パフォーマンスとセキュリティ:**
- パフォーマンス劣化なし (p95レイテンシーがベースラインの5%以内)
- セキュリティ脆弱性が導入されていない
- リソース使用が許容範囲 (メモリ、CPU、I/O)
- 高トラフィック変更のための負荷テストが合格

**デプロイメント準備:**
- ドメインエキスパートによるコードレビュー承認
- ロールバック計画が文書化されテストされている
- 機能フラグが構成されている (該当する場合)
- 監視とアラートが構成されている
- トラブルシューティング手順を含むランブックが更新されている

**防止策:**
- 静的分析ルールが追加されている (該当する場合)
- 型システム改善が実装されている (該当する場合)
- ドキュメントが更新されている (コード、API、ランブック)
- 事後検証が作成されている (高重要度インシデントの場合)
- ナレッジベース記事が作成されている (新規問題の場合)

**メトリクス:**
- 平均復旧時間 (MTTR): SEV2+で < 4時間
- バグ再発率: 0% (同じ根本原因が再発すべきでない)
- テストカバレッジ: 減少なし、理想的には増加
- デプロイメント成功率: > 95% (ロールバック率 < 5%)

解決すべき問題: $ARGUMENTS
