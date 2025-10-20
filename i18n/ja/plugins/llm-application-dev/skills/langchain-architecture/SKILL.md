> **[English](../../../../../plugins/llm-application-dev/skills/langchain-architecture/SKILL.md)** | **日本語**

---
name: langchain-architecture
description: エージェント、メモリ、ツール統合パターンを備えたLangChainフレームワークを使用してLLMアプリケーションを設計します。LangChainアプリケーションの構築、AIエージェントの実装、または複雑なLLMワークフローの作成時に使用します。
---

# LangChainアーキテクチャ

エージェント、チェーン、メモリ、ツール統合を備えた洗練されたLLMアプリケーションを構築するためのLangChainフレームワークをマスターします。

## このスキルを使用する場合

- ツールアクセスを持つ自律的なAIエージェントの構築
- 複雑な多段階LLMワークフローの実装
- 会話メモリと状態の管理
- LLMと外部データソースおよびAPIの統合
- モジュール式で再利用可能なLLMアプリケーションコンポーネントの作成
- ドキュメント処理パイプラインの実装
- 本番グレードのLLMアプリケーションの構築

## コアコンセプト

### 1. エージェント
LLMを使用してどのアクションを取るかを決定する自律システム。

**エージェントタイプ:**
- **ReAct**: 推論+行動を交互に実行
- **OpenAI Functions**: 関数呼び出しAPIを活用
- **Structured Chat**: マルチ入力ツールを処理
- **Conversational**: チャットインターフェース用に最適化
- **Self-Ask with Search**: 複雑なクエリを分解

### 2. チェーン
LLMまたは他のユーティリティへの呼び出しのシーケンス。

**チェーンタイプ:**
- **LLMChain**: 基本的なプロンプト+LLMの組み合わせ
- **SequentialChain**: シーケンス内の複数のチェーン
- **RouterChain**: 専門チェーンへの入力をルーティング
- **TransformChain**: ステップ間のデータ変換
- **MapReduceChain**: 集約を伴う並列処理

### 3. メモリ
インタラクション間でコンテキストを維持するためのシステム。

**メモリタイプ:**
- **ConversationBufferMemory**: すべてのメッセージを保存
- **ConversationSummaryMemory**: 古いメッセージを要約
- **ConversationBufferWindowMemory**: 最後のNメッセージを保持
- **EntityMemory**: エンティティに関する情報を追跡
- **VectorStoreMemory**: セマンティック類似性検索

### 4. ドキュメント処理
検索のためにドキュメントを読み込み、変換、保存。

**コンポーネント:**
- **ドキュメントローダー**: 様々なソースから読み込み
- **テキストスプリッター**: ドキュメントをインテリジェントにチャンク化
- **ベクトルストア**: 埋め込みを保存および検索
- **リトリーバー**: 関連ドキュメントを取得
- **インデックス**: 効率的なアクセスのためにドキュメントを整理

### 5. コールバック
ログ、モニタリング、デバッグのためのフック。

**ユースケース:**
- リクエスト/レスポンスのログ
- トークン使用量の追跡
- レイテンシモニタリング
- エラーハンドリング
- カスタムメトリクス収集

## クイックスタート

```python
from langchain.agents import AgentType, initialize_agent, load_tools
from langchain.llms import OpenAI
from langchain.memory import ConversationBufferMemory

# LLMを初期化
llm = OpenAI(temperature=0)

# ツールを読み込み
tools = load_tools(["serpapi", "llm-math"], llm=llm)

# メモリを追加
memory = ConversationBufferMemory(memory_key="chat_history")

# エージェントを作成
agent = initialize_agent(
    tools,
    llm,
    agent=AgentType.CONVERSATIONAL_REACT_DESCRIPTION,
    memory=memory,
    verbose=True
)

# エージェントを実行
result = agent.run("What's the weather in SF? Then calculate 25 * 4")
```

## アーキテクチャパターン

### パターン1: LangChainを使用したRAG
```python
from langchain.chains import RetrievalQA
from langchain.document_loaders import TextLoader
from langchain.text_splitters import CharacterTextSplitter
from langchain.vectorstores import Chroma
from langchain.embeddings import OpenAIEmbeddings

# ドキュメントを読み込みと処理
loader = TextLoader('documents.txt')
documents = loader.load()

text_splitter = CharacterTextSplitter(chunk_size=1000, chunk_overlap=200)
texts = text_splitter.split_documents(documents)

# ベクトルストアを作成
embeddings = OpenAIEmbeddings()
vectorstore = Chroma.from_documents(texts, embeddings)

# 検索チェーンを作成
qa_chain = RetrievalQA.from_chain_type(
    llm=llm,
    chain_type="stuff",
    retriever=vectorstore.as_retriever(),
    return_source_documents=True
)

# クエリ
result = qa_chain({"query": "What is the main topic?"})
```

### パターン2: ツールを持つカスタムエージェント
```python
from langchain.agents import Tool, AgentExecutor
from langchain.agents.react.base import ReActDocstoreAgent
from langchain.tools import tool

@tool
def search_database(query: str) -> str:
    """Search internal database for information."""
    # データベース検索ロジック
    return f"Results for: {query}"

@tool
def send_email(recipient: str, content: str) -> str:
    """Send an email to specified recipient."""
    # メール送信ロジック
    return f"Email sent to {recipient}"

tools = [search_database, send_email]

agent = initialize_agent(
    tools,
    llm,
    agent=AgentType.ZERO_SHOT_REACT_DESCRIPTION,
    verbose=True
)
```

### パターン3: 多段階チェーン
```python
from langchain.chains import LLMChain, SequentialChain
from langchain.prompts import PromptTemplate

# ステップ1: 主要情報を抽出
extract_prompt = PromptTemplate(
    input_variables=["text"],
    template="Extract key entities from: {text}\n\nEntities:"
)
extract_chain = LLMChain(llm=llm, prompt=extract_prompt, output_key="entities")

# ステップ2: エンティティを分析
analyze_prompt = PromptTemplate(
    input_variables=["entities"],
    template="Analyze these entities: {entities}\n\nAnalysis:"
)
analyze_chain = LLMChain(llm=llm, prompt=analyze_prompt, output_key="analysis")

# ステップ3: サマリーを生成
summary_prompt = PromptTemplate(
    input_variables=["entities", "analysis"],
    template="Summarize:\nEntities: {entities}\nAnalysis: {analysis}\n\nSummary:"
)
summary_chain = LLMChain(llm=llm, prompt=summary_prompt, output_key="summary")

# シーケンシャルチェーンに結合
overall_chain = SequentialChain(
    chains=[extract_chain, analyze_chain, summary_chain],
    input_variables=["text"],
    output_variables=["entities", "analysis", "summary"],
    verbose=True
)
```

## メモリ管理のベストプラクティス

### 適切なメモリタイプの選択
```python
# 短い会話用（< 10メッセージ）
from langchain.memory import ConversationBufferMemory
memory = ConversationBufferMemory()

# 長い会話用（古いメッセージを要約）
from langchain.memory import ConversationSummaryMemory
memory = ConversationSummaryMemory(llm=llm)

# スライディングウィンドウ用（最後のNメッセージ）
from langchain.memory import ConversationBufferWindowMemory
memory = ConversationBufferWindowMemory(k=5)

# エンティティ追跡用
from langchain.memory import ConversationEntityMemory
memory = ConversationEntityMemory(llm=llm)

# 関連履歴のセマンティック検索用
from langchain.memory import VectorStoreRetrieverMemory
memory = VectorStoreRetrieverMemory(retriever=retriever)
```

## コールバックシステム

### カスタムコールバックハンドラー
```python
from langchain.callbacks.base import BaseCallbackHandler

class CustomCallbackHandler(BaseCallbackHandler):
    def on_llm_start(self, serialized, prompts, **kwargs):
        print(f"LLM started with prompts: {prompts}")

    def on_llm_end(self, response, **kwargs):
        print(f"LLM ended with response: {response}")

    def on_llm_error(self, error, **kwargs):
        print(f"LLM error: {error}")

    def on_chain_start(self, serialized, inputs, **kwargs):
        print(f"Chain started with inputs: {inputs}")

    def on_agent_action(self, action, **kwargs):
        print(f"Agent taking action: {action}")

# コールバックを使用
agent.run("query", callbacks=[CustomCallbackHandler()])
```

## テスト戦略

```python
import pytest
from unittest.mock import Mock

def test_agent_tool_selection():
    # 特定のツール選択を返すようにLLMをモック
    mock_llm = Mock()
    mock_llm.predict.return_value = "Action: search_database\nAction Input: test query"

    agent = initialize_agent(tools, mock_llm, agent=AgentType.ZERO_SHOT_REACT_DESCRIPTION)

    result = agent.run("test query")

    # 正しいツールが選択されたことを確認
    assert "search_database" in str(mock_llm.predict.call_args)

def test_memory_persistence():
    memory = ConversationBufferMemory()

    memory.save_context({"input": "Hi"}, {"output": "Hello!"})

    assert "Hi" in memory.load_memory_variables({})['history']
    assert "Hello!" in memory.load_memory_variables({})['history']
```

## パフォーマンス最適化

### 1. キャッシング
```python
from langchain.cache import InMemoryCache
import langchain

langchain.llm_cache = InMemoryCache()
```

### 2. バッチ処理
```python
# 複数のドキュメントを並列処理
from langchain.document_loaders import DirectoryLoader
from concurrent.futures import ThreadPoolExecutor

loader = DirectoryLoader('./docs')
docs = loader.load()

def process_doc(doc):
    return text_splitter.split_documents([doc])

with ThreadPoolExecutor(max_workers=4) as executor:
    split_docs = list(executor.map(process_doc, docs))
```

### 3. ストリーミングレスポンス
```python
from langchain.callbacks.streaming_stdout import StreamingStdOutCallbackHandler

llm = OpenAI(streaming=True, callbacks=[StreamingStdOutCallbackHandler()])
```

## リソース

- **references/agents.md**: エージェントアーキテクチャの詳細
- **references/memory.md**: メモリシステムパターン
- **references/chains.md**: チェーン構成戦略
- **references/document-processing.md**: ドキュメント読み込みとインデックス
- **references/callbacks.md**: モニタリングと可観測性
- **assets/agent-template.py**: 本番環境対応エージェントテンプレート
- **assets/memory-config.yaml**: メモリ設定例
- **assets/chain-example.py**: 複雑なチェーンの例

## よくある落とし穴

1. **メモリオーバーフロー**: 会話履歴の長さを管理しない
2. **ツール選択エラー**: 不適切なツール説明がエージェントを混乱させる
3. **コンテキストウィンドウ超過**: LLMトークン制限を超える
4. **エラーハンドリングなし**: エージェントの失敗をキャッチして処理しない
5. **非効率な検索**: ベクトルストアクエリを最適化しない

## 本番環境チェックリスト

- [ ] 適切なエラーハンドリングを実装
- [ ] リクエスト/レスポンスのログを追加
- [ ] トークン使用量とコストを監視
- [ ] エージェント実行のタイムアウト制限を設定
- [ ] レート制限を実装
- [ ] 入力検証を追加
- [ ] エッジケースでテスト
- [ ] 可観測性を設定（コールバック）
- [ ] フォールバック戦略を実装
- [ ] プロンプトと設定をバージョン管理
