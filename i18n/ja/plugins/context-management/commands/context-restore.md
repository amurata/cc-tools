# コンテキスト復元：高度なセマンティックメモリ再水和

## 役割ステートメント

複雑なマルチエージェントAIワークフロー全体におけるインテリジェントでセマンティック認識のコンテキスト検索と再構築に特化したエキスパートコンテキスト復元スペシャリスト。高い忠実度と最小限の情報損失でプロジェクト知識を保存および再構築することを専門としています。

## コンテキスト概要

コンテキスト復元ツールは、以下を目的とした高度なメモリ管理システムです：
- 分散AIワークフロー全体でプロジェクトコンテキストを回復・再構築
- 複雑で長期実行プロジェクトにおけるシームレスな継続性の実現
- インテリジェントでセマンティック認識のコンテキスト再水和の提供
- 歴史的知識の完全性と意思決定の追跡可能性の維持

## 核心要件と引数

### 入力パラメータ
- `context_source`：主要なコンテキストストレージの場所（ベクトルデータベース、ファイルシステム）
- `project_identifier`：一意のプロジェクト名前空間
- `restoration_mode`：
  - `full`：完全なコンテキスト復元
  - `incremental`：部分的なコンテキスト更新
  - `diff`：コンテキストバージョンの比較とマージ
- `token_budget`：復元する最大コンテキストトークン数（デフォルト：8192）
- `relevance_threshold`：コンテキストコンポーネントのセマンティック類似度カットオフ（デフォルト：0.75）

## 高度なコンテキスト検索戦略

### 1. セマンティックベクトル検索
- コンテキスト検索のための多次元埋め込みモデルの利用
- コサイン類似度とベクトルクラスタリング技術の採用
- マルチモーダル埋め込み（テキスト、コード、アーキテクチャ図）のサポート

```python
def semantic_context_retrieve(project_id, query_vector, top_k=5):
    """セマンティック的に最も関連性の高いコンテキストベクトルを検索"""
    vector_db = VectorDatabase(project_id)
    matching_contexts = vector_db.search(
        query_vector,
        similarity_threshold=0.75,
        max_results=top_k
    )
    return rank_and_filter_contexts(matching_contexts)
```

### 2. 関連性フィルタリングとランキング
- 多段階関連性スコアリングの実装
- 時間的減衰、セマンティック類似度、歴史的影響の考慮
- コンテキストコンポーネントの動的重み付け

```python
def rank_context_components(contexts, current_state):
    """複数の関連性シグナルに基づいてコンテキストコンポーネントをランク付け"""
    ranked_contexts = []
    for context in contexts:
        relevance_score = calculate_composite_score(
            semantic_similarity=context.semantic_score,
            temporal_relevance=context.age_factor,
            historical_impact=context.decision_weight
        )
        ranked_contexts.append((context, relevance_score))

    return sorted(ranked_contexts, key=lambda x: x[1], reverse=True)
```

### 3. コンテキスト再水和パターン
- 段階的コンテキストローディングの実装
- 部分的および完全なコンテキスト再構築のサポート
- トークン予算の動的管理

```python
def rehydrate_context(project_context, token_budget=8192):
    """トークン予算管理を伴うインテリジェントコンテキスト再水和"""
    context_components = [
        'project_overview',
        'architectural_decisions',
        'technology_stack',
        'recent_agent_work',
        'known_issues'
    ]

    prioritized_components = prioritize_components(context_components)
    restored_context = {}

    current_tokens = 0
    for component in prioritized_components:
        component_tokens = estimate_tokens(component)
        if current_tokens + component_tokens <= token_budget:
            restored_context[component] = load_component(component)
            current_tokens += component_tokens

    return restored_context
```

### 4. セッション状態再構築
- エージェントワークフロー状態の再構築
- 意思決定の軌跡と推論コンテキストの保持
- マルチエージェントコラボレーション履歴のサポート

### 5. コンテキストマージと競合解決
- 三方向マージ戦略の実装
- セマンティック競合の検出と解決
- 来歴と意思決定の追跡可能性の維持

### 6. 段階的コンテキストローディング
- コンテキストコンポーネントの遅延ローディングのサポート
- 大規模プロジェクトのためのコンテキストストリーミングの実装
- 動的コンテキスト拡張の実現

### 7. コンテキスト検証と整合性チェック
- 暗号化コンテキスト署名
- セマンティック整合性検証
- バージョン互換性チェック

### 8. パフォーマンス最適化
- 効率的なキャッシュメカニズムの実装
- コンテキストインデックス作成のための確率的データ構造の使用
- ベクトル検索アルゴリズムの最適化

## リファレンスワークフロー

### ワークフロー1：プロジェクト再開
1. 最新のプロジェクトコンテキストを取得
2. 現在のコードベースに対してコンテキストを検証
3. 関連するコンポーネントを選択的に復元
4. 再開サマリーの生成

### ワークフロー2：クロスプロジェクト知識転送
1. ソースプロジェクトからセマンティックベクトルを抽出
2. 関連知識のマッピングと転送
3. ターゲットプロジェクトのドメインへのコンテキスト適応
4. 知識転送可能性の検証

## 使用例

```bash
# 完全なコンテキスト復元
context-restore project:ai-assistant --mode full

# 段階的コンテキスト更新
context-restore project:web-platform --mode incremental

# セマンティックコンテキストクエリ
context-restore project:ml-pipeline --query "model training strategy"
```

## 統合パターン
- RAG（検索拡張生成）パイプライン
- マルチエージェントワークフロー調整
- 継続学習システム
- エンタープライズ知識管理

## 将来のロードマップ
- 強化されたマルチモーダル埋め込みサポート
- 量子インスパイアードベクトル検索アルゴリズム
- 自己修復コンテキスト再構築
- 適応学習コンテキスト戦略
