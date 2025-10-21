> **[English](../../../../../plugins/llm-application-dev/skills/llm-evaluation/SKILL.md)** | **日本語**

---
name: llm-evaluation
description: 自動メトリクス、人間のフィードバック、ベンチマークを使用してLLMアプリケーションの包括的な評価戦略を実装します。LLMパフォーマンスのテスト、AIアプリケーション品質の測定、または評価フレームワークの確立時に使用します。
---

# LLM評価

自動メトリクスから人間評価、A/Bテストまで、LLMアプリケーションの包括的な評価戦略をマスターします。

## このスキルを使用する場合

- LLMアプリケーションパフォーマンスを体系的に測定する場合
- 異なるモデルまたはプロンプトを比較する場合
- デプロイ前にパフォーマンス低下を検出する場合
- プロンプト変更からの改善を検証する場合
- 本番環境システムへの信頼を構築する場合
- ベースラインを確立し、時間とともに進捗を追跡する場合
- 予期しないモデル動作のデバッグを行う場合

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
- **MRR**: Mean Reciprocal Rank（平均逆順位）
- **NDCG**: Normalized Discounted Cumulative Gain（正規化割引累積利得）
- **Precision@K**: トップKに関連するもの
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
より強力なLLMを使用して、より弱いモデルの出力を評価します。

**アプローチ:**
- **Pointwise**: 個別の応答をスコア付け
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
    """参照と仮説の間のBLEUスコアを計算します。"""
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
    """ROUGEスコアを計算します。"""
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
    """事前学習済みBERTを使用してBERTScoreを計算します。"""
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
    """応答が提供されたコンテキストに基づいているかをチェックします。"""
    # NLIモデルを使用して含意をチェック
    from transformers import pipeline

    nli = pipeline("text-classification", model="microsoft/deberta-large-mnli")

    result = nli(f"{context} [SEP] {response}")[0]

    # 応答がコンテキストに含意される信頼度を返す
    return result['score'] if result['label'] == 'ENTAILMENT' else 0.0

def calculate_toxicity(text):
    """生成されたテキストの有害性を測定します。"""
    from detoxify import Detoxify

    results = Detoxify('original').predict(text)
    return max(results.values())  # 最高の有害性スコアを返す

def calculate_factuality(claim, knowledge_base):
    """ナレッジベースに対して事実的主張を検証します。"""
    # ナレッジベースに依存する実装
    # 検索+NLI、またはファクトチェックAPIを使用できる
    pass
```

## LLM-as-Judgeパターン

### 単一出力評価
```python
def llm_judge_quality(response, question):
    """GPT-4を使用して応答品質を判断します。"""
    prompt = f"""Rate the following response on a scale of 1-10 for:
1. Accuracy (factually correct)
2. Helpfulness (answers the question)
3. Clarity (well-written and understandable)

Question: {question}
Response: {response}

Provide ratings in JSON format:
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
    """LLMジャッジを使用して2つの応答を比較します。"""
    prompt = f"""Compare these two responses to the question and determine which is better.

Question: {question}

Response A: {response_a}

Response B: {response_b}

Which response is better and why? Consider accuracy, helpfulness, and clarity.

Answer with JSON:
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

## 人間評価フレームワーク

### アノテーションガイドライン
```python
class AnnotationTask:
    """人間アノテーションタスクの構造。"""

    def __init__(self, response, question, context=None):
        self.response = response
        self.question = question
        self.context = context

    def get_annotation_form(self):
        return {
            "question": self.question,
            "context": self.context,
            "response": self.response,
            "ratings": {
                "accuracy": {
                    "scale": "1-5",
                    "description": "Is the response factually correct?"
                },
                "relevance": {
                    "scale": "1-5",
                    "description": "Does it answer the question?"
                },
                "coherence": {
                    "scale": "1-5",
                    "description": "Is it logically consistent?"
                }
            },
            "issues": {
                "factual_error": False,
                "hallucination": False,
                "off_topic": False,
                "unsafe_content": False
            },
            "feedback": ""
        }
```

### 評価者間一致度
```python
from sklearn.metrics import cohen_kappa_score

def calculate_agreement(rater1_scores, rater2_scores):
    """評価者間一致度を計算します。"""
    kappa = cohen_kappa_score(rater1_scores, rater2_scores)

    interpretation = {
        kappa < 0: "Poor",
        kappa < 0.2: "Slight",
        kappa < 0.4: "Fair",
        kappa < 0.6: "Moderate",
        kappa < 0.8: "Substantial",
        kappa <= 1.0: "Almost Perfect"
    }

    return {
        "kappa": kappa,
        "interpretation": interpretation[True]
    }
```

## A/Bテスト

### 統計的テストフレームワーク
```python
from scipy import stats
import numpy as np

class ABTest:
    def __init__(self, variant_a_name="A", variant_b_name="B"):
        self.variant_a = {"name": variant_a_name, "scores": []}
        self.variant_b = {"name": variant_b_name, "scores": []}

    def add_result(self, variant, score):
        """バリアントの評価結果を追加します。"""
        if variant == "A":
            self.variant_a["scores"].append(score)
        else:
            self.variant_b["scores"].append(score)

    def analyze(self, alpha=0.05):
        """統計分析を実行します。"""
        a_scores = self.variant_a["scores"]
        b_scores = self.variant_b["scores"]

        # T検定
        t_stat, p_value = stats.ttest_ind(a_scores, b_scores)

        # 効果量（Cohen's d）
        pooled_std = np.sqrt((np.std(a_scores)**2 + np.std(b_scores)**2) / 2)
        cohens_d = (np.mean(b_scores) - np.mean(a_scores)) / pooled_std

        return {
            "variant_a_mean": np.mean(a_scores),
            "variant_b_mean": np.mean(b_scores),
            "difference": np.mean(b_scores) - np.mean(a_scores),
            "relative_improvement": (np.mean(b_scores) - np.mean(a_scores)) / np.mean(a_scores),
            "p_value": p_value,
            "statistically_significant": p_value < alpha,
            "cohens_d": cohens_d,
            "effect_size": self.interpret_cohens_d(cohens_d),
            "winner": "B" if np.mean(b_scores) > np.mean(a_scores) else "A"
        }

    @staticmethod
    def interpret_cohens_d(d):
        """Cohen's d効果量を解釈します。"""
        abs_d = abs(d)
        if abs_d < 0.2:
            return "negligible"
        elif abs_d < 0.5:
            return "small"
        elif abs_d < 0.8:
            return "medium"
        else:
            return "large"
```

## 回帰テスト

### 回帰検出
```python
class RegressionDetector:
    def __init__(self, baseline_results, threshold=0.05):
        self.baseline = baseline_results
        self.threshold = threshold

    def check_for_regression(self, new_results):
        """新しい結果が回帰を示しているかを検出します。"""
        regressions = []

        for metric in self.baseline.keys():
            baseline_score = self.baseline[metric]
            new_score = new_results.get(metric)

            if new_score is None:
                continue

            # 相対変化を計算
            relative_change = (new_score - baseline_score) / baseline_score

            # 大幅な減少にフラグを立てる
            if relative_change < -self.threshold:
                regressions.append({
                    "metric": metric,
                    "baseline": baseline_score,
                    "current": new_score,
                    "change": relative_change
                })

        return {
            "has_regression": len(regressions) > 0,
            "regressions": regressions
        }
```

## ベンチマーク

### ベンチマークの実行
```python
class BenchmarkRunner:
    def __init__(self, benchmark_dataset):
        self.dataset = benchmark_dataset

    def run_benchmark(self, model, metrics):
        """ベンチマークでモデルを実行し、メトリクスを計算します。"""
        results = {metric.name: [] for metric in metrics}

        for example in self.dataset:
            # 予測を生成
            prediction = model.predict(example["input"])

            # 各メトリクスを計算
            for metric in metrics:
                score = metric.calculate(
                    prediction=prediction,
                    reference=example["reference"],
                    context=example.get("context")
                )
                results[metric.name].append(score)

        # 結果を集約
        return {
            metric: {
                "mean": np.mean(scores),
                "std": np.std(scores),
                "min": min(scores),
                "max": max(scores)
            }
            for metric, scores in results.items()
        }
```

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

1. **複数のメトリクス**: 包括的な視点のために多様なメトリクスを使用します
2. **代表的なデータ**: 実世界の多様な例でテストします
3. **ベースライン**: 常にベースラインパフォーマンスと比較します
4. **統計的厳密性**: 比較に適切な統計テストを使用します
5. **継続的評価**: CI/CDパイプラインに統合します
6. **人間検証**: 自動メトリクスと人間の判断を組み合わせます
7. **エラー分析**: 失敗を調査して弱点を理解します
8. **バージョン管理**: 評価結果を時間とともに追跡します

## よくある落とし穴

- **単一メトリクスへの執着**: 他を犠牲にして1つのメトリクスを最適化してしまう
- **小さなサンプルサイズ**: あまりにも少ない例から結論を導き出してしまう
- **データ汚染**: トレーニングデータでテストしてしまう
- **分散の無視**: 統計的不確実性を考慮しない
- **メトリクスミスマッチ**: ビジネス目標に合わないメトリクスを使用してしまう
