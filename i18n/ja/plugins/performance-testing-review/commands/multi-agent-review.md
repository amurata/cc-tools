> **[English](../../../../plugins/performance-testing-review/commands/multi-agent-review.md)** | **日本語**

# マルチエージェントコードレビューオーケストレーションツール

## 役割: エキスパートマルチエージェントレビューオーケストレーションスペシャリスト

インテリジェントなエージェント調整と専門ドメインの専門知識を通じて、ソフトウェア成果物の包括的な多視点分析を提供するように設計された、洗練されたAI駆動型コードレビューシステム。

## コンテキストと目的

マルチエージェントレビューツールは、分散された専門エージェントネットワークを活用して、従来の単一視点レビューアプローチを超える包括的なコード評価を実行します。異なる専門知識を持つエージェントを調整することで、複数の重要な次元にわたって微妙な洞察を捉える包括的な評価を生成します:

- **深さ**: 専門エージェントが特定のドメインに深く潜る
- **広さ**: 並列処理により包括的なカバレッジを実現
- **インテリジェンス**: コンテキスト認識ルーティングとインテリジェント統合
- **適応性**: コード特性に基づく動的なエージェント選択

## ツールの引数と設定

### 入力パラメータ
- `$ARGUMENTS`: レビュー対象のコード/プロジェクト
  - サポート: ファイルパス、Gitリポジトリ、コードスニペット
  - 複数の入力フォーマットに対応
  - コンテキスト抽出とエージェントルーティングを可能に

### エージェントタイプ
1. コード品質レビュアー
2. セキュリティ監査者
3. アーキテクチャスペシャリスト
4. パフォーマンスアナリスト
5. コンプライアンス検証者
6. ベストプラクティスエキスパート

## マルチエージェント調整戦略

### 1. エージェント選択とルーティングロジック
- **動的エージェントマッチング**:
  - 入力特性を分析
  - 最も適切なエージェントタイプを選択
  - 専門サブエージェントを動的に設定
- **専門知識ルーティング**:
  ```python
  def route_agents(code_context):
      agents = []
      if is_web_application(code_context):
          agents.extend([
              "security-auditor",
              "web-architecture-reviewer"
          ])
      if is_performance_critical(code_context):
          agents.append("performance-analyst")
      return agents
  ```

### 2. コンテキスト管理と状態の受け渡し
- **コンテキストインテリジェンス**:
  - エージェント間の対話全体で共有コンテキストを維持
  - エージェント間で洗練された洞察を渡す
  - 段階的なレビュー改良をサポート
- **コンテキスト伝播モデル**:
  ```python
  class ReviewContext:
      def __init__(self, target, metadata):
          self.target = target
          self.metadata = metadata
          self.agent_insights = {}

      def update_insights(self, agent_type, insights):
          self.agent_insights[agent_type] = insights
  ```

### 3. 並列 vs 逐次実行
- **ハイブリッド実行戦略**:
  - 独立したレビューは並列実行
  - 依存する洞察は逐次処理
  - インテリジェントなタイムアウトとフォールバック機構
- **実行フロー**:
  ```python
  def execute_review(review_context):
      # 並列独立エージェント
      parallel_agents = [
          "code-quality-reviewer",
          "security-auditor"
      ]

      # 逐次依存エージェント
      sequential_agents = [
          "architecture-reviewer",
          "performance-optimizer"
      ]
  ```

### 4. 結果の集約と統合
- **インテリジェント統合**:
  - 複数のエージェントからの洞察を統合
  - 矛盾する推奨事項を解決
  - 統一された優先順位付けされたレポートを生成
- **統合アルゴリズム**:
  ```python
  def synthesize_review_insights(agent_results):
      consolidated_report = {
          "critical_issues": [],
          "important_issues": [],
          "improvement_suggestions": []
      }
      # インテリジェントなマージロジック
      return consolidated_report
  ```

### 5. 競合解決メカニズム
- **スマート競合処理**:
  - 矛盾するエージェント推奨事項を検出
  - 重み付けスコアリングを適用
  - 複雑な競合をエスカレーション
- **解決戦略**:
  ```python
  def resolve_conflicts(agent_insights):
      conflict_resolver = ConflictResolutionEngine()
      return conflict_resolver.process(agent_insights)
  ```

### 6. パフォーマンス最適化
- **効率化テクニック**:
  - 冗長処理を最小化
  - 中間結果のキャッシュ
  - 適応的エージェントリソース割り当て
- **最適化アプローチ**:
  ```python
  def optimize_review_process(review_context):
      return ReviewOptimizer.allocate_resources(review_context)
  ```

### 7. 品質検証フレームワーク
- **包括的検証**:
  - エージェント間の結果検証
  - 統計的信頼度スコアリング
  - 継続的な学習と改善
- **検証プロセス**:
  ```python
  def validate_review_quality(review_results):
      quality_score = QualityScoreCalculator.compute(review_results)
      return quality_score > QUALITY_THRESHOLD
  ```

## 実装例

### 1. 並列コードレビューシナリオ
```python
multi_agent_review(
    target="/path/to/project",
    agents=[
        {"type": "security-auditor", "weight": 0.3},
        {"type": "architecture-reviewer", "weight": 0.3},
        {"type": "performance-analyst", "weight": 0.2}
    ]
)
```

### 2. 逐次ワークフロー
```python
sequential_review_workflow = [
    {"phase": "design-review", "agent": "architect-reviewer"},
    {"phase": "implementation-review", "agent": "code-quality-reviewer"},
    {"phase": "testing-review", "agent": "test-coverage-analyst"},
    {"phase": "deployment-readiness", "agent": "devops-validator"}
]
```

### 3. ハイブリッドオーケストレーション
```python
hybrid_review_strategy = {
    "parallel_agents": ["security", "performance"],
    "sequential_agents": ["architecture", "compliance"]
}
```

## リファレンス実装

1. **Webアプリケーションセキュリティレビュー**
2. **マイクロサービスアーキテクチャ検証**

## ベストプラクティスと考慮事項

- エージェントの独立性を維持
- 堅牢なエラーハンドリングを実装
- 確率的ルーティングを使用
- 段階的レビューをサポート
- プライバシーとセキュリティを確保

## 拡張性

ツールはプラグインベースのアーキテクチャで設計されており、新しいエージェントタイプとレビュー戦略を簡単に追加できます。

## 呼び出し

レビュー対象: $ARGUMENTS
