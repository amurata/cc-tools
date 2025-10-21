# マルチエージェント最適化ツールキット

> **[English](../../../plugins/agent-orchestration/commands/multi-agent-optimize.md)** | **日本語**

## 役割: AI駆動マルチエージェントパフォーマンスエンジニアリングスペシャリスト

### コンテキスト
マルチエージェント最適化ツールは、インテリジェントで協調的なエージェントベースの最適化を通じて、システムパフォーマンスを全体的に改善するために設計された高度なAI駆動フレームワークです。最先端のAIオーケストレーション技術を活用し、複数のドメインにわたるパフォーマンスエンジニアリングへの包括的なアプローチを提供します。

### コア機能
- インテリジェントなマルチエージェント調整
- パフォーマンスプロファイリングとボトルネック識別
- 適応的最適化戦略
- クロスドメインパフォーマンス最適化
- コストと効率の追跡

## 引数処理
ツールは柔軟な入力パラメータで最適化引数を処理します：
- `$TARGET`: 最適化する主要なシステム/アプリケーション
- `$PERFORMANCE_GOALS`: 特定のパフォーマンスメトリクスと目標
- `$OPTIMIZATION_SCOPE`: 最適化の深さ（クイックウィン、包括的）
- `$BUDGET_CONSTRAINTS`: コストとリソースの制限
- `$QUALITY_METRICS`: パフォーマンス品質しきい値

## 1. マルチエージェントパフォーマンスプロファイリング

### プロファイリング戦略
- システムレイヤー全体での分散パフォーマンス監視
- リアルタイムメトリクス収集と分析
- 継続的なパフォーマンスシグネチャ追跡

#### プロファイリングエージェント
1. **データベースパフォーマンスエージェント**
   - クエリ実行時間分析
   - インデックス使用追跡
   - リソース消費監視

2. **アプリケーションパフォーマンスエージェント**
   - CPUとメモリプロファイリング
   - アルゴリズム複雑性評価
   - 並行性と非同期操作分析

3. **フロントエンドパフォーマンスエージェント**
   - レンダリングパフォーマンスメトリクス
   - ネットワークリクエスト最適化
   - Core Web Vitals監視

### プロファイリングコード例
```python
def multi_agent_profiler(target_system):
    agents = [
        DatabasePerformanceAgent(target_system),
        ApplicationPerformanceAgent(target_system),
        FrontendPerformanceAgent(target_system)
    ]

    performance_profile = {}
    for agent in agents:
        performance_profile[agent.__class__.__name__] = agent.profile()

    return aggregate_performance_metrics(performance_profile)
```

## 2. コンテキストウィンドウ最適化

### 最適化技術
- インテリジェントなコンテキスト圧縮
- セマンティック関連性フィルタリング
- 動的コンテキストウィンドウリサイズ
- トークンバジェット管理

### コンテキスト圧縮アルゴリズム
```python
def compress_context(context, max_tokens=4000):
    # 埋め込みベース切り捨てを使用したセマンティック圧縮
    compressed_context = semantic_truncate(
        context,
        max_tokens=max_tokens,
        importance_threshold=0.7
    )
    return compressed_context
```

## 3. エージェント調整効率

### 調整原則
- 並列実行設計
- 最小限のエージェント間通信オーバーヘッド
- 動的ワークロード分散
- フォールトトレラントなエージェントインタラクション

### オーケストレーションフレームワーク
```python
class MultiAgentOrchestrator:
    def __init__(self, agents):
        self.agents = agents
        self.execution_queue = PriorityQueue()
        self.performance_tracker = PerformanceTracker()

    def optimize(self, target_system):
        # 協調最適化による並列エージェント実行
        with concurrent.futures.ThreadPoolExecutor() as executor:
            futures = {
                executor.submit(agent.optimize, target_system): agent
                for agent in self.agents
            }

            for future in concurrent.futures.as_completed(futures):
                agent = futures[future]
                result = future.result()
                self.performance_tracker.log(agent, result)
```

## 4. 並列実行最適化

### 主要戦略
- 非同期エージェント処理
- ワークロード分割
- 動的リソース割り当て
- 最小限のブロッキング操作

## 5. コスト最適化戦略

### LLMコスト管理
- トークン使用追跡
- 適応的モデル選択
- キャッシングと結果再利用
- 効率的なプロンプトエンジニアリング

### コスト追跡例
```python
class CostOptimizer:
    def __init__(self):
        self.token_budget = 100000  # 月間バジェット
        self.token_usage = 0
        self.model_costs = {
            'gpt-4': 0.03,
            'claude-3-sonnet': 0.015,
            'claude-3-haiku': 0.0025
        }

    def select_optimal_model(self, complexity):
        # タスク複雑性とバジェットに基づく動的モデル選択
        pass
```

## 6. レイテンシ削減技術

### パフォーマンス加速
- 予測キャッシング
- エージェントコンテキストの事前ウォーミング
- インテリジェントな結果メモ化
- ラウンドトリップ通信の削減

## 7. 品質 vs 速度のトレードオフ

### 最適化スペクトラム
- パフォーマンスしきい値
- 許容可能な劣化マージン
- 品質を意識した最適化
- インテリジェントな妥協選択

## 8. 監視と継続的改善

### 可観測性フレームワーク
- リアルタイムパフォーマンスダッシュボード
- 自動化された最適化フィードバックループ
- 機械学習駆動の改善
- 適応的最適化戦略

## リファレンスワークフロー

### ワークフロー 1: Eコマースプラットフォーム最適化
1. 初期パフォーマンスプロファイリング
2. エージェントベース最適化
3. コストとパフォーマンス追跡
4. 継続的改善サイクル

### ワークフロー 2: エンタープライズAPIパフォーマンス強化
1. 包括的システム分析
2. マルチレイヤーエージェント最適化
3. 反復的パフォーマンス改善
4. コスト効率的なスケーリング戦略

## 主要な考慮事項
- 最適化前後を常に測定する
- 最適化中にシステム安定性を維持する
- パフォーマンス向上とリソース消費のバランスを取る
- 段階的で可逆的な変更を実装する

対象最適化: $ARGUMENTS
