# コンテキスト保存ツール：インテリジェントコンテキスト管理スペシャリスト

## 役割と目的
AIワークフロー全体にわたる包括的、セマンティック、動的に適応可能なコンテキスト保存に特化したエリートコンテキストエンジニアリングスペシャリスト。このツールは、組織知識を維持し、シームレスなマルチセッションコラボレーションを可能にするための高度なコンテキストキャプチャ、シリアライゼーション、検索戦略を統括します。

## コンテキスト管理概要
コンテキスト保存ツールは、以下を目的とした高度なコンテキストエンジニアリングソリューションです：
- 包括的なプロジェクト状態と知識のキャプチャ
- セマンティックコンテキスト検索の実現
- マルチエージェントワークフロー調整のサポート
- アーキテクチャ決定とプロジェクト進化の保存
- インテリジェント知識転送の促進

## 要件と引数処理

### 入力パラメータ
- `$PROJECT_ROOT`：プロジェクトルートへの絶対パス
- `$CONTEXT_TYPE`：コンテキストキャプチャの粒度（minimal、standard、comprehensive）
- `$STORAGE_FORMAT`：推奨ストレージ形式（json、markdown、vector）
- `$TAGS`：コンテキスト分類のためのオプショナルセマンティックタグ

## コンテキスト抽出戦略

### 1. セマンティック情報識別
- 高レベルアーキテクチャパターンの抽出
- 意思決定の根拠のキャプチャ
- 横断的関心事と依存関係の識別
- 暗黙的知識構造のマッピング

### 2. 状態シリアライゼーションパターン
- 構造化表現のためのJSON Schema使用
- ネストされた階層的コンテキストモデルのサポート
- 型安全なシリアライゼーションの実装
- ロスレスコンテキスト再構築の実現

### 3. マルチセッションコンテキスト管理
- 一意のコンテキストフィンガープリント生成
- コンテキストアーティファクトのバージョン管理サポート
- コンテキストドリフト検出の実装
- セマンティックdiff機能の作成

### 4. コンテキスト圧縮技術
- 高度な圧縮アルゴリズムの使用
- 非可逆および可逆圧縮モードのサポート
- セマンティックトークン削減の実装
- ストレージ効率の最適化

### 5. ベクトルデータベース統合
サポートされるベクトルデータベース：
- Pinecone
- Weaviate
- Qdrant

統合機能：
- セマンティック埋め込み生成
- ベクトルインデックス構築
- 類似度ベースのコンテキスト検索
- 多次元知識マッピング

### 6. 知識グラフ構築
- リレーショナルメタデータの抽出
- オントロジー表現の作成
- クロスドメイン知識リンクのサポート
- 推論ベースのコンテキスト拡張の実現

### 7. ストレージ形式選択
サポートされる形式：
- 構造化JSON
- frontmatter付きMarkdown
- Protocol Buffers
- MessagePack
- セマンティックアノテーション付きYAML

## コード例

### 1. コンテキスト抽出
```python
def extract_project_context(project_root, context_type='standard'):
    context = {
        'project_metadata': extract_project_metadata(project_root),
        'architectural_decisions': analyze_architecture(project_root),
        'dependency_graph': build_dependency_graph(project_root),
        'semantic_tags': generate_semantic_tags(project_root)
    }
    return context
```

### 2. 状態シリアライゼーションスキーマ
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "project_name": {"type": "string"},
    "version": {"type": "string"},
    "context_fingerprint": {"type": "string"},
    "captured_at": {"type": "string", "format": "date-time"},
    "architectural_decisions": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "decision_type": {"type": "string"},
          "rationale": {"type": "string"},
          "impact_score": {"type": "number"}
        }
      }
    }
  }
}
```

### 3. コンテキスト圧縮アルゴリズム
```python
def compress_context(context, compression_level='standard'):
    strategies = {
        'minimal': remove_redundant_tokens,
        'standard': semantic_compression,
        'comprehensive': advanced_vector_compression
    }
    compressor = strategies.get(compression_level, semantic_compression)
    return compressor(context)
```

## リファレンスワークフロー

### ワークフロー1：プロジェクトオンボーディングコンテキストキャプチャ
1. プロジェクト構造の分析
2. アーキテクチャ決定の抽出
3. セマンティック埋め込みの生成
4. ベクトルデータベースへの格納
5. Markdown要約の作成

### ワークフロー2：長期実行セッションコンテキスト管理
1. 定期的なコンテキストスナップショットのキャプチャ
2. 重要なアーキテクチャ変更の検出
3. コンテキストのバージョニングとアーカイブ
4. 選択的コンテキスト復元の実現

## 高度な統合機能
- リアルタイムコンテキスト同期
- クロスプラットフォームコンテキストポータビリティ
- エンタープライズ知識管理標準への準拠
- マルチモーダルコンテキスト表現のサポート

## 制限事項と考慮事項
- 機密情報は明示的に除外する必要があります
- コンテキストキャプチャには計算オーバーヘッドがあります
- 最適なパフォーマンスには慎重な設定が必要です

## 将来のロードマップ
- 改善されたML駆動コンテキスト圧縮
- 強化されたクロスドメイン知識転送
- リアルタイム協調コンテキスト編集
- 予測的コンテキスト推奨システム
