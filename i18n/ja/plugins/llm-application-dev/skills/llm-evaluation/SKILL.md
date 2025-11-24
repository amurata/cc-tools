---
name: llm-evaluation
description: 自動メトリクス、人間によるフィードバック、およびベンチマークを使用して、LLMアプリケーションの包括的な評価戦略を実装します。LLMのパフォーマンスをテストし、AIアプリケーションの品質を測定し、または評価フレームワークを確立する場合に使用します。
---

# LLM評価

自動メトリクスから人間による評価、A/Bテストまで、LLMアプリケーションの包括的な評価戦略をマスターします。

## このスキルをいつ使用するか

- LLMアプリケーションのパフォーマンスを体系的に測定する
- 異なるモデルやプロンプトを比較する
- デプロイ前にパフォーマンスの低下（リグレッション）を検出する
- プロンプトの変更による改善を検証する
- 本番システムへの信頼を築く
- ベースラインを確立し、時間の経過とともに進捗を追跡する
- 予期しないモデルの動作をデバッグする

## コア評価タイプ

### 1. 自動メトリクス
計算されたスコアを使用した、高速で再現性があり、スケーラブルな評価。

**テキスト生成:**
- **BLEU**: N-gramの重複（翻訳）
- **ROUGE**: 再現率重視（要約）
- **METEOR**: 意味的類似性
- **BERTScore**: エンベディングベースの類似性
- **Perplexity**: 言語モデルの確信度

**分類:**
- **Accuracy**: 正解率
- **Precision/Recall/F1**: クラス固有のパフォーマンス
- **Confusion Matrix**: エラーパターン
- **AUC-ROC**: ランキング品質

**検索 (RAG):**
- **MRR**: 平均相互ランク (Mean Reciprocal Rank)
- **NDCG**: 正規化割引累積利得 (Normalized Discounted Cumulative Gain)
- **Precision@K**: 上位K件の関連性
- **Recall@K**: 上位K件の網羅率

### 2. 人間による評価
自動化が難しい品質面の手動評価。

**次元:**
- **Accuracy**: 事実の正確さ
- **Coherence**: 論理的な流れ
- **Relevance**: 質問に答えているか
- **Fluency**: 自然言語の品質
- **Safety**: 有害なコンテンツがないか
- **Helpfulness**: ユーザーにとって有用か

### 3. LLM-as-Judge
より強力なLLMを使用して、より弱いモデルの出力を評価します。

**アプローチ:**
- **Pointwise**: 個々の回答をスコアリング
- **Pairwise**: 2つの回答を比較
- **Reference-based**: ゴールドスタンダードと比較
- **Reference-free**: 正解なしで判断

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
    # ... その他のテストケース
]

# 評価を実行
results = suite.evaluate(
    model=your_model,
    test_cases=test_cases
)

print(f"Overall Accuracy: {results.metrics['accuracy']}")
print(f"BLEU Score: {results.metrics['bleu']}")
```

## 自動メトリクスの実装

### BLEU Score
```python
from nltk.translate.bleu_score import sentence_bleu, SmoothingFunction

def calculate_bleu(reference, hypothesis):
    """リファレンスと仮説の間のBLEUスコアを計算します。"""
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

### ROUGE Score
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
    """回答が提供されたコンテキストに基づいているか確認します。"""
    # 含意を確認するためにNLIモデルを使用
    from transformers import pipeline

    nli = pipeline("text-classification", model="microsoft/deberta-large-mnli")

    result = nli(f"{context} [SEP] {response}")[0]

    # 回答がコンテキストによって含意される確信度を返す
    return result['score'] if result['label'] == 'ENTAILMENT' else 0.0

def calculate_toxicity(text):
    """生成されたテキストの毒性を測定します。"""
    from detoxify import Detoxify

    results = Detoxify('original').predict(text)
    return max(results.values())  # 最も高い毒性スコアを返す

def calculate_factuality(claim, knowledge_base):
    """ナレッジベースに対して事実の主張を検証します。"""
    # 実装はナレッジベースに依存します
    # 検索 + NLI、またはファクトチェックAPIを使用できます
    pass
```

## LLM-as-Judge パターン

### 単一出力評価
```python
def llm_judge_quality(response, question):
    """GPT-5を使用して回答品質を判断します。"""
    prompt = f"""以下の回答を1-10のスケールで評価してください：
1. 正確性（事実として正しい）
2. 有用性（質問に答えている）
3. 明確性（よく書かれていて理解しやすい）

質問: {question}
回答: {response}

JSON形式で評価を提供してください：
{{
  "accuracy": <1-10>,
  "helpfulness": <1-10>,
  "clarity": <1-10>,
  "reasoning": "<短い説明>"
}}
"""

    result = openai.ChatCompletion.create(
        model="gpt-5",
        messages=[{"role": "user", "content": prompt}],
        temperature=0
    )

    return json.loads(result.choices[0].message.content)
```

### ペアワイズ比較
```python
def compare_responses(question, response_a, response_b):
    """LLMジャッジを使用して2つの回答を比較します。"""
    prompt = f"""質問に対するこれら2つの回答を比較し、どちらが優れているか判断してください。

質問: {question}

回答 A: {response_a}

回答 B: {response_b}

どちらの回答が優れていますか？その理由は？正確性、有用性、明確性を考慮してください。

JSONで答えてください：
{{
  "winner": "A" または "B" または "tie",
  "reasoning": "<説明>",
  "confidence": <1-10>
}}
"""

    result = openai.ChatCompletion.create(
        model="gpt-5",
        messages=[{"role": "user", "content": prompt}],
        temperature=0
    )

    return json.loads(result.choices[0].message.content)
```

## 人間による評価フレームワーク

### アノテーションガイドライン
```python
class AnnotationTask:
    """人間によるアノテーションタスクの構造。"""

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
                    "description": "回答は事実として正しいですか？"
                },
                "relevance": {
                    "scale": "1-5",
                    "description": "質問に答えていますか？"
                },
                "coherence": {
                    "scale": "1-5",
                    "description": "論理的に一貫していますか？"
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

### 評価者間一致率
```python
from sklearn.metrics import cohen_kappa_score

def calculate_agreement(rater1_scores, rater2_scores):
    """評価者間一致率を計算します。"""
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

## A/B テスト

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

        # 効果量 (Cohen's d)
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
        """Cohen's d 効果量を解釈します。"""
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
        """新しい結果が回帰を示しているか検出します。"""
        regressions = []

        for metric in self.baseline.keys():
            baseline_score = self.baseline[metric]
            new_score = new_results.get(metric)

            if new_score is None:
                continue

            # 相対変化を計算
            relative_change = (new_score - baseline_score) / baseline_score

            # 有意な減少がある場合はフラグを立てる
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

        # 結果を集計
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
- **references/regression-testing.md**: CI/CD 統合
- **assets/evaluation-framework.py**: 完全な評価ハーネス
- **assets/benchmark-dataset.jsonl**: データセット例
- **scripts/evaluate-model.py**: 自動評価ランナー

## ベストプラクティス

1. **複数のメトリクス**: 包括的なビューのために多様なメトリクスを使用する
2. **代表的なデータ**: 実世界の多様な例でテストする
3. **ベースライン**: 常にベースラインパフォーマンスと比較する
4. **統計的厳密さ**: 比較には適切な統計的テストを使用する
5. **継続的評価**: CI/CD パイプラインに統合する
6. **人間による検証**: 自動メトリクスと人間の判断を組み合わせる
7. **エラー分析**: 弱点を理解するために失敗を調査する
8. **バージョン管理**: 時間の経過とともに評価結果を追跡する

## 一般的な落とし穴

- **単一メトリクスへの執着**: 他を犠牲にして1つのメトリクスに最適化する
- **小さなサンプルサイズ**: 少なすぎる例から結論を導き出す
- **データ汚染**: トレーニングデータでテストする
- **分散の無視**: 統計的不確実性を考慮しない
- **メトリクスの不一致**: ビジネス目標と一致しないメトリクスを使用する
