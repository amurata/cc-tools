> **[English](../../../../../plugins/llm-application-dev/skills/llm-evaluation/SKILL.md)** | **日本語**

---
name: llm-evaluation
description: 自動メトリクス、人間のフィードバック、ベンチマークを使用してLLMアプリケーションの包括的な評価戦略を実装します。LLMパフォーマンスのテスト、AIアプリケーション品質の測定、または評価フレームワークの確立時に使用します。
---

# LLM評価

自動メトリクスから人間評価、A/Bテストまで、LLMアプリケーションの包括的な評価戦略をマスターします。

## このスキルを使用する場合

- LLMアプリケーションパフォーマンスを体系的に測定
- 異なるモデルまたはプロンプトを比較
- デプロイ前にパフォーマンス低下を検出
- プロンプト変更からの改善を検証
- 本番環境システムへの信頼を構築
- ベースラインを確立し、時間とともに進捗を追跡
- 予期しないモデル動作のデバッグ

## コア評価タイプ

### 1. 自動メトリクス
計算されたスコアを使用した高速、反復可能、スケーラブルな評価。

**テキスト生成:**
- **BLEU**: N-gramオーバーラップ（翻訳）
- **ROUGE**: 再現率重視（要約）
- **METEOR**: セマンティック類似性
- **BERTScore**: 埋め込みベースの類似性
- **Perplexity**: 言語モデルの信頼度

**分類:**
- **Accuracy**: 正解率
- **Precision/Recall/F1**: クラス固有のパフォーマンス
- **Confusion Matrix**: エラーパターン
- **AUC-ROC**: ランキング品質

**検索（RAG）:**
- **MRR**: Mean Reciprocal Rank
- **NDCG**: Normalized Discounted Cumulative Gain
- **Precision@K**: トップKに関連
- **Recall@K**: トップKでのカバレッジ

### 2. 人間評価
自動化が困難な品質面の手動評価。

**次元:**
- **正確性**: 事実的正しさ
- **一貫性**: 論理的フロー
- **関連性**: 質問への回答
- **流暢性**: 自然な言語品質
- **安全性**: 有害なコンテンツなし
- **有用性**: ユーザーにとって有用

### 3. LLM-as-Judge
より強力なLLMを使用して、より弱いモデルの出力を評価。

**アプローチ:**
- **Pointwise**: 個別の応答をスコア
- **Pairwise**: 2つの応答を比較
- **Reference-based**: ゴールドスタンダードと比較
- **Reference-free**: 真実なしで判断

## クイックスタート

```python
from llm_eval import EvaluationSuite, Metric

# 評価スイートを定義
suite = EvaluationSuite([
    Metric.accuracy(),
    Metric.bleu(),
    Metric.bertscore(),
    Metric.custom(name="groundedness", fn=check_groundedness)
])

# テストケースを準備
test_cases = [
    {
        "input": "What is the capital of France?",
        "expected": "Paris",
        "context": "France is a country in Europe. Paris is its capital."
    },
    # ... more test cases
]

# 評価を実行
results = suite.evaluate(
    model=your_model,
    test_cases=test_cases
)

print(f"Overall Accuracy: {results.metrics['accuracy']}")
print(f"BLEU Score: {results.metrics['bleu']}")
```

## 自動メトリクス実装

### BLEUスコア
```python
from nltk.translate.bleu_score import sentence_bleu, SmoothingFunction

def calculate_bleu(reference, hypothesis):
    """参照と仮説の間のBLEUスコアを計算"""
    smoothie = SmoothingFunction().method4

    return sentence_bleu(
        [reference.split()],
        hypothesis.split(),
        smoothing_function=smoothie
    )

# 使用法
bleu = calculate_bleu(
    reference="The cat sat on the mat",
    hypothesis="A cat is sitting on the mat"
)
```

### ROUGEスコア
```python
from rouge_score import rouge_scorer

def calculate_rouge(reference, hypothesis):
    """ROUGEスコアを計算"""
    scorer = rouge_scorer.RougeScorer(['rouge1', 'rouge2', 'rougeL'], use_stemmer=True)
    scores = scorer.score(reference, hypothesis)

    return {
        'rouge1': scores['rouge1'].fmeasure,
        'rouge2': scores['rouge2'].fmeasure,
        'rougeL': scores['rougeL'].fmeasure
    }
```

### BERTScore
```python
from bert_score import score

def calculate_bertscore(references, hypotheses):
    """事前学習済みBERTを使用してBERTScoreを計算"""
    P, R, F1 = score(
        hypotheses,
        references,
        lang='en',
        model_type='microsoft/deberta-xlarge-mnli'
    )

    return {
        'precision': P.mean().item(),
        'recall': R.mean().item(),
        'f1': F1.mean().item()
    }
```

### カスタムメトリクス
```python
def calculate_groundedness(response, context):
    """応答が提供されたコンテキストに基づいているかをチェック"""
    # NLIモデルを使用して含意をチェック
    from transformers import pipeline

    nli = pipeline("text-classification", model="microsoft/deberta-large-mnli")

    result = nli(f"{context} [SEP] {response}")[0]

    # 応答がコンテキストに含意される信頼度を返す
    return result['score'] if result['label'] == 'ENTAILMENT' else 0.0

def calculate_toxicity(text):
    """生成されたテキストの有害性を測定"""
    from detoxify import Detoxify

    results = Detoxify('original').predict(text)
    return max(results.values())  # 最高の有害性スコアを返す

def calculate_factuality(claim, knowledge_base):
    """ナレッジベースに対して事実的主張を検証"""
    # ナレッジベースに依存する実装
    # 検索+NLI、またはファクトチェックAPIを使用できる
    pass
```

## LLM-as-Judgeパターン

### 単一出力評価
```python
def llm_judge_quality(response, question):
    """GPT-4を使用して応答品質を判断"""
    prompt = f"""以下の応答を1-10のスケールで評価:
1. 正確性（事実的に正しい）
2. 有用性（質問に答えている）
3. 明確性（よく書かれ理解しやすい）

質問: {question}
応答: {response}

JSON形式で評価を提供:
{{
  "accuracy": <1-10>,
  "helpfulness": <1-10>,
  "clarity": <1-10>,
  "reasoning": "<brief explanation>"
}}
"""

    result = openai.ChatCompletion.create(
        model="gpt-4",
        messages=[{"role": "user", "content": prompt}],
        temperature=0
    )

    return json.loads(result.choices[0].message.content)
```

### ペアワイズ比較
```python
def compare_responses(question, response_a, response_b):
    """LLMジャッジを使用して2つの応答を比較"""
    prompt = f"""これら2つの応答を質問に対して比較し、どちらが優れているかを判断。

質問: {question}

応答A: {response_a}

応答B: {response_b}

どちらの応答が優れているか、その理由は？ 正確性、有用性、明確性を考慮。

JSONで回答:
{{
  "winner": "A" or "B" or "tie",
  "reasoning": "<explanation>",
  "confidence": <1-10>
}}
"""

    result = openai.ChatCompletion.create(
        model="gpt-4",
        messages=[{"role": "user", "content": prompt}],
        temperature=0
    )

    return json.loads(result.choices[0].message.content)
```

[注: 実際のファイルには、人間評価フレームワーク、A/Bテスト、回帰テスト、ベンチマークなどの完全なセクションが続きます]

## リソース

- **references/metrics.md**: 包括的なメトリクスガイド
- **references/human-evaluation.md**: アノテーションのベストプラクティス
- **references/benchmarking.md**: 標準ベンチマーク
- **references/a-b-testing.md**: 統計的テストガイド
- **references/regression-testing.md**: CI/CD統合
- **assets/evaluation-framework.py**: 完全な評価ハーネス
- **assets/benchmark-dataset.jsonl**: サンプルデータセット
- **scripts/evaluate-model.py**: 自動評価ランナー

## ベストプラクティス

1. **複数のメトリクス**: 包括的な視点のために多様なメトリクスを使用
2. **代表的なデータ**: 実世界の多様な例でテスト
3. **ベースライン**: 常にベースラインパフォーマンスと比較
4. **統計的厳密性**: 比較に適切な統計テストを使用
5. **継続的評価**: CI/CDパイプラインに統合
6. **人間検証**: 自動メトリクスと人間判断を組み合わせる
7. **エラー分析**: 失敗を調査して弱点を理解
8. **バージョン管理**: 評価結果を時間とともに追跡

## よくある落とし穴

- **単一メトリクスへの執着**: 他を犠牲にして1つのメトリクスを最適化
- **小さなサンプルサイズ**: あまりにも少ない例から結論を導き出す
- **データ汚染**: トレーニングデータでテスト
- **分散の無視**: 統計的不確実性を考慮しない
- **メトリクスミスマッチ**: ビジネス目標に合わないメトリクスを使用
