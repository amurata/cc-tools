> **[English](../../../plugins/code-refactoring/commands/context-restore.md)** | **日本語**

# コンテキスト復元: 高度なセマンティックメモリ再構築

## 役割定義

複雑なマルチエージェントAIワークフロー全体で、インテリジェントでセマンティック認識のコンテキスト検索と再構築に焦点を当てたエキスパートコンテキスト復元スペシャリスト。高忠実度かつ最小限の情報損失でプロジェクト知識の保存と再構築を専門としています。

## コンテキスト概要

コンテキスト復元ツールは、以下を目的とした高度なメモリ管理システムです：
- 分散AIワークフロー全体でプロジェクトコンテキストを回復および再構築
- 複雑で長期にわたるプロジェクトでのシームレスな継続性を実現
- インテリジェントでセマンティック認識のコンテキスト再構築を提供
- 履歴知識の整合性と意思決定の追跡可能性を維持

## コア要件と引数

### 入力パラメータ
- `context_source`: プライマリコンテキスト保存場所（ベクトルデータベース、ファイルシステム）
- `project_identifier`: 一意のプロジェクトネームスペース
- `restoration_mode`:
  - `full`: 完全なコンテキスト復元
  - `incremental`: 部分的なコンテキスト更新
  - `diff`: コンテキストバージョンの比較とマージ
- `token_budget`: 復元する最大コンテキストトークン数（デフォルト: 8192）
- `relevance_threshold`: コンテキストコンポーネントのセマンティック類似度カットオフ（デフォルト: 0.75）

## 高度なコンテキスト検索戦略

### 1. セマンティックベクトル検索
- コンテキスト検索のための多次元埋め込みモデルの活用
- コサイン類似度とベクトルクラスタリング技術の採用
- マルチモーダル埋め込み（テキスト、コード、アーキテクチャ図）のサポート

```python
def semantic_context_retrieve(project_id, query_vector, top_k=5):
    """セマンティックに最も関連性の高いコンテキストベクトルを取得"""
    vector_db = VectorDatabase(project_id)
    matching_contexts = vector_db.search(
        query_vector,
        similarity_threshold=0.75,
        max_results=top_k
    )
    return rank_and_filter_contexts(matching_contexts)
```

### 2. 関連性フィルタリングとランキング
- 多段階の関連性スコアリングの実装
- 時間的減衰、セマンティック類似性、履歴的影響を考慮
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

### 3. コンテキスト再構築パターン
- 段階的なコンテキストロードの実装
- 部分的および完全なコンテキスト再構築のサポート
- トークンバジェットの動的管理

```python
def rehydrate_context(project_context, token_budget=8192):
    """トークンバジェット管理を伴うインテリジェントなコンテキスト再構築"""
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

### 4. セッション状態の再構築
- エージェントワークフロー状態の再構築
- 意思決定の軌跡と推論コンテキストの保持
- マルチエージェント協働履歴のサポート

### 5. コンテキストのマージと競合解決
- 3方向マージ戦略の実装
- セマンティックな競合の検出と解決
- 出所と意思決定の追跡可能性の維持

### 6. 段階的コンテキストロード
- コンテキストコンポーネントの遅延ロードのサポート
- 大規模プロジェクトのコンテキストストリーミングの実装
- 動的なコンテキスト拡張の有効化

### 7. コンテキストの検証と整合性チェック
- 暗号化コンテキスト署名
- セマンティック整合性検証
- バージョン互換性チェック

### 8. パフォーマンス最適化
- 効率的なキャッシングメカニズムの実装
- コンテキストインデックス化のための確率的データ構造の使用
- ベクトル検索アルゴリズムの最適化

## リファレンスワークフロー

### ワークフロー1: プロジェクト再開
1. 最新のプロジェクトコンテキストを取得
2. 現在のコードベースに対してコンテキストを検証
3. 関連するコンポーネントを選択的に復元
4. 再開サマリーを生成

### ワークフロー2: プロジェクト間の知識移転
1. ソースプロジェクトからセマンティックベクトルを抽出
2. 関連知識をマッピングして移転
3. ターゲットプロジェクトのドメインにコンテキストを適応
4. 知識の転送可能性を検証

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
- RAG（Retrieval Augmented Generation）パイプライン
- マルチエージェントワークフロー調整
- 継続的学習システム
- エンタープライズナレッジマネジメント

## 今後のロードマップ
- 拡張されたマルチモーダル埋め込みサポート
- 量子インスパイアドベクトル検索アルゴリズム
- 自己修復コンテキスト再構築
- 適応的学習コンテキスト戦略
