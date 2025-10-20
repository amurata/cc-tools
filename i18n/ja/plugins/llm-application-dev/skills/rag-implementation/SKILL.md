> **[English](../../../../../plugins/llm-application-dev/skills/rag-implementation/SKILL.md)** | **日本語**

---
name: rag-implementation
description: ベクトルデータベースとセマンティック検索を使用してLLMアプリケーションのためのRetrieval-Augmented Generation（RAG）システムを構築します。知識に基づいたAI、ドキュメントQ&Aシステムの構築、またはLLMと外部ナレッジベースの統合時に使用します。
---

# RAG実装

外部知識ソースを使用して正確で根拠のある応答を提供するLLMアプリケーションを構築するために、Retrieval-Augmented Generation（RAG）をマスターします。

## このスキルを使用する場合

- 独自ドキュメントに対するQ&Aシステムの構築
- 最新で事実的な情報を持つチャットボットの作成
- 自然言語クエリによるセマンティック検索の実装
- 根拠のある応答による幻覚の削減
- LLMがドメイン固有の知識にアクセスできるようにする
- ドキュメントアシスタントの構築
- ソース引用付きリサーチツールの作成

## コアコンポーネント

### 1. ベクトルデータベース
**目的**: ドキュメント埋め込みを効率的に保存および検索

**オプション:**
- **Pinecone**: 管理型、スケーラブル、高速クエリ
- **Weaviate**: オープンソース、ハイブリッド検索
- **Milvus**: 高性能、オンプレミス
- **Chroma**: 軽量、使いやすい
- **Qdrant**: 高速、フィルタ検索
- **FAISS**: Metaのライブラリ、ローカルデプロイ

### 2. 埋め込み
**目的**: テキストを類似性検索のための数値ベクトルに変換

**モデル:**
- **text-embedding-ada-002**（OpenAI）: 汎用、1536次元
- **all-MiniLM-L6-v2**（Sentence Transformers）: 高速、軽量
- **e5-large-v2**: 高品質、多言語
- **Instructor**: タスク固有の指示
- **bge-large-en-v1.5**: SOTAパフォーマンス

### 3. 検索戦略
**アプローチ:**
- **Dense Retrieval**: 埋め込みによるセマンティック類似性
- **Sparse Retrieval**: キーワードマッチング（BM25、TF-IDF）
- **Hybrid Search**: DenseとSparseを組み合わせる
- **Multi-Query**: 複数のクエリバリエーションを生成
- **HyDE**: 仮想ドキュメントを生成

### 4. 再ランキング
**目的**: 結果を並べ替えて検索品質を向上

**方法:**
- **Cross-Encoders**: BERTベースの再ランキング
- **Cohere Rerank**: APIベースの再ランキング
- **Maximal Marginal Relevance（MMR）**: 多様性+関連性
- **LLMベース**: LLMを使用して関連性をスコア

## クイックスタート

```python
from langchain.document_loaders import DirectoryLoader
from langchain.text_splitters import RecursiveCharacterTextSplitter
from langchain.embeddings import OpenAIEmbeddings
from langchain.vectorstores import Chroma
from langchain.chains import RetrievalQA
from langchain.llms import OpenAI

# 1. ドキュメントを読み込み
loader = DirectoryLoader('./docs', glob="**/*.txt")
documents = loader.load()

# 2. チャンクに分割
text_splitter = RecursiveCharacterTextSplitter(
    chunk_size=1000,
    chunk_overlap=200,
    length_function=len
)
chunks = text_splitter.split_documents(documents)

# 3. 埋め込みとベクトルストアを作成
embeddings = OpenAIEmbeddings()
vectorstore = Chroma.from_documents(chunks, embeddings)

# 4. 検索チェーンを作成
qa_chain = RetrievalQA.from_chain_type(
    llm=OpenAI(),
    chain_type="stuff",
    retriever=vectorstore.as_retriever(search_kwargs={"k": 4}),
    return_source_documents=True
)

# 5. クエリ
result = qa_chain({"query": "What are the main features?"})
print(result['result'])
print(result['source_documents'])
```

## 高度なRAGパターン

### パターン1: ハイブリッド検索
```python
from langchain.retrievers import BM25Retriever, EnsembleRetriever

# スパースリトリーバー（BM25）
bm25_retriever = BM25Retriever.from_documents(chunks)
bm25_retriever.k = 5

# デンスリトリーバー（埋め込み）
embedding_retriever = vectorstore.as_retriever(search_kwargs={"k": 5})

# 重みで結合
ensemble_retriever = EnsembleRetriever(
    retrievers=[bm25_retriever, embedding_retriever],
    weights=[0.3, 0.7]
)
```

### パターン2: マルチクエリ検索
```python
from langchain.retrievers.multi_query import MultiQueryRetriever

# 複数のクエリ視点を生成
retriever = MultiQueryRetriever.from_llm(
    retriever=vectorstore.as_retriever(),
    llm=OpenAI()
)

# 単一クエリ → 複数のバリエーション → 結合された結果
results = retriever.get_relevant_documents("What is the main topic?")
```

### パターン3: コンテキスト圧縮
```python
from langchain.retrievers import ContextualCompressionRetriever
from langchain.retrievers.document_compressors import LLMChainExtractor

compressor = LLMChainExtractor.from_llm(llm)

compression_retriever = ContextualCompressionRetriever(
    base_compressor=compressor,
    base_retriever=vectorstore.as_retriever()
)

# ドキュメントの関連部分のみを返す
compressed_docs = compression_retriever.get_relevant_documents("query")
```

### パターン4: 親ドキュメントリトリーバー
```python
from langchain.retrievers import ParentDocumentRetriever
from langchain.storage import InMemoryStore

# 親ドキュメント用ストア
store = InMemoryStore()

# 検索用小チャンク、コンテキスト用大チャンク
child_splitter = RecursiveCharacterTextSplitter(chunk_size=400)
parent_splitter = RecursiveCharacterTextSplitter(chunk_size=2000)

retriever = ParentDocumentRetriever(
    vectorstore=vectorstore,
    docstore=store,
    child_splitter=child_splitter,
    parent_splitter=parent_splitter
)
```

## ドキュメントチャンキング戦略

### 再帰文字テキストスプリッター
```python
from langchain.text_splitters import RecursiveCharacterTextSplitter

splitter = RecursiveCharacterTextSplitter(
    chunk_size=1000,
    chunk_overlap=200,
    length_function=len,
    separators=["\n\n", "\n", " ", ""]  # これらを順番に試す
)
```

### トークンベース分割
```python
from langchain.text_splitters import TokenTextSplitter

splitter = TokenTextSplitter(
    chunk_size=512,
    chunk_overlap=50
)
```

### セマンティックチャンキング
```python
from langchain.text_splitters import SemanticChunker

splitter = SemanticChunker(
    embeddings=OpenAIEmbeddings(),
    breakpoint_threshold_type="percentile"
)
```

### Markdownヘッダースプリッター
```python
from langchain.text_splitters import MarkdownHeaderTextSplitter

headers_to_split_on = [
    ("#", "Header 1"),
    ("##", "Header 2"),
    ("###", "Header 3"),
]

splitter = MarkdownHeaderTextSplitter(headers_to_split_on=headers_to_split_on)
```

[注: 実際のファイルには、ベクトルストア設定、検索最適化、RAGプロンプトエンジニアリング、評価メトリクスなどの完全なセクションが続きます]

## リソース

- **references/vector-databases.md**: ベクトルDBの詳細比較
- **references/embeddings.md**: 埋め込みモデル選択ガイド
- **references/retrieval-strategies.md**: 高度な検索技術
- **references/reranking.md**: 再ランキング方法と使用時期
- **references/context-window.md**: コンテキスト制限の管理
- **assets/vector-store-config.yaml**: 設定テンプレート
- **assets/retriever-pipeline.py**: 完全なRAGパイプライン
- **assets/embedding-models.md**: モデル比較とベンチマーク

## ベストプラクティス

1. **チャンクサイズ**: コンテキストと特異性のバランス（500-1000トークン）
2. **オーバーラップ**: 境界でコンテキストを保持するために10-20%のオーバーラップを使用
3. **メタデータ**: フィルタリングとデバッグのためにソース、ページ、タイムスタンプを含める
4. **ハイブリッド検索**: 最良の結果のためにセマンティックとキーワード検索を組み合わせる
5. **再ランキング**: クロスエンコーダーでトップ結果を改善
6. **引用**: 透明性のために常にソースドキュメントを返す
7. **評価**: 検索品質と回答精度を継続的にテスト
8. **モニタリング**: 本番環境で検索メトリクスを追跡

## よくある問題

- **検索不良**: 埋め込み品質、チャンクサイズ、クエリ定式化をチェック
- **無関係な結果**: メタデータフィルタリングを追加、ハイブリッド検索を使用、再ランキング
- **情報欠落**: ドキュメントが適切にインデックスされていることを確認
- **クエリが遅い**: ベクトルストアを最適化、キャッシングを使用、kを削減
- **幻覚**: 根拠プロンプトを改善、検証ステップを追加
