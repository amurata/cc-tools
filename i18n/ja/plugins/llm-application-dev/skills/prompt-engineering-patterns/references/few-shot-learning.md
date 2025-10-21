> **[English](../../../../../../plugins/llm-application-dev/skills/prompt-engineering-patterns/references/few-shot-learning.md)** | **日本語**

# Few-Shot学習ガイド

## 概要

Few-shot学習により、LLMはプロンプト内に少数の例（通常1-10個）を提供することでタスクを実行できます。この技術は、特定のフォーマット、スタイル、またはドメイン知識を必要とするタスクに非常に効果的です。

## 例選択戦略

### 1. セマンティック類似性
埋め込みベースの検索を使用して、入力クエリに最も類似した例を選択。

```python
from sentence_transformers import SentenceTransformer
import numpy as np

class SemanticExampleSelector:
    def __init__(self, examples, model_name='all-MiniLM-L6-v2'):
        self.model = SentenceTransformer(model_name)
        self.examples = examples
        self.example_embeddings = self.model.encode([ex['input'] for ex in examples])

    def select(self, query, k=3):
        query_embedding = self.model.encode([query])
        similarities = np.dot(self.example_embeddings, query_embedding.T).flatten()
        top_indices = np.argsort(similarities)[-k:][::-1]
        return [self.examples[i] for i in top_indices]
```

**最適用途**: 質問応答、テキスト分類、抽出タスク

### 2. 多様性サンプリング
異なるパターンとエッジケースのカバレッジを最大化。

```python
from sklearn.cluster import KMeans

class DiversityExampleSelector:
    def __init__(self, examples, model_name='all-MiniLM-L6-v2'):
        self.model = SentenceTransformer(model_name)
        self.examples = examples
        self.embeddings = self.model.encode([ex['input'] for ex in examples])

    def select(self, k=5):
        # k-meansを使用して多様なクラスター中心を見つける
        kmeans = KMeans(n_clusters=k, random_state=42)
        kmeans.fit(self.embeddings)

        # 各クラスター中心に最も近い例を選択
        diverse_examples = []
        for center in kmeans.cluster_centers_:
            distances = np.linalg.norm(self.embeddings - center, axis=1)
            closest_idx = np.argmin(distances)
            diverse_examples.append(self.examples[closest_idx])

        return diverse_examples
```

**最適用途**: タスクの変動性の実証、エッジケース処理

### 3. 難易度ベースの選択
例の複雑さを徐々に増やして学習をスキャフォールディング。

```python
class ProgressiveExampleSelector:
    def __init__(self, examples):
        # 例には'difficulty'スコア（0-1）が必要
        self.examples = sorted(examples, key=lambda x: x['difficulty'])

    def select(self, k=3):
        # 難易度が線形に増加する例を選択
        step = len(self.examples) // k
        return [self.examples[i * step] for i in range(k)]
```

**最適用途**: 複雑な推論タスク、コード生成

### 4. エラーベースの選択
一般的な失敗モードに対処する例を含める。

```python
class ErrorGuidedSelector:
    def __init__(self, examples, error_patterns):
        self.examples = examples
        self.error_patterns = error_patterns  # 避けるべき一般的なミス

    def select(self, query, k=3):
        # エラーパターンの正しい処理を示す例を選択
        selected = []
        for pattern in self.error_patterns[:k]:
            matching = [ex for ex in self.examples if pattern in ex['demonstrates']]
            if matching:
                selected.append(matching[0])
        return selected
```

**最適用途**: 既知の失敗パターンを持つタスク、安全性が重要なアプリケーション

## 例構築のベストプラクティス

### フォーマットの一貫性
すべての例は同一のフォーマットに従う必要があります:

```python
# 良い例: 一貫したフォーマット
examples = [
    {
        "input": "フランスの首都は何ですか？",
        "output": "パリ"
    },
    {
        "input": "ドイツの首都は何ですか？",
        "output": "ベルリン"
    }
]

# 悪い例: 一貫性のないフォーマット
examples = [
    "Q: フランスの首都は何ですか？ A: パリ",
    {"question": "ドイツの首都は何ですか？", "answer": "ベルリン"}
]
```

### 入力-出力のアライメント
例がモデルに実行させたい正確なタスクを示すことを確認:

```python
# 良い例: 明確な入力-出力関係
example = {
    "input": "感情: その映画はひどくて退屈でした。",
    "output": "ネガティブ"
}

# 悪い例: 曖昧な関係
example = {
    "input": "その映画はひどくて退屈でした。",
    "output": "このレビューは映画に対してネガティブな感情を表現しています。"
}
```

### 複雑さのバランス
期待される難易度範囲にまたがる例を含める:

```python
examples = [
    # シンプルケース
    {"input": "2 + 2", "output": "4"},

    # 中程度のケース
    {"input": "15 * 3 + 8", "output": "53"},

    # 複雑なケース
    {"input": "(12 + 8) * 3 - 15 / 5", "output": "57"}
]
```

## コンテキストウィンドウ管理

### トークンバジェット割り当て
4Kコンテキストウィンドウの典型的な配分:

```
システムプロンプト:        500トークン  (12%)
Few-Shot例:             1500トークン  (38%)
ユーザー入力:             500トークン  (12%)
応答:                   1500トークン  (38%)
```

### 動的例切り捨て
```python
class TokenAwareSelector:
    def __init__(self, examples, tokenizer, max_tokens=1500):
        self.examples = examples
        self.tokenizer = tokenizer
        self.max_tokens = max_tokens

    def select(self, query, k=5):
        selected = []
        total_tokens = 0

        # 最も関連性の高い例から始める
        candidates = self.rank_by_relevance(query)

        for example in candidates[:k]:
            example_tokens = len(self.tokenizer.encode(
                f"入力: {example['input']}\n出力: {example['output']}\n\n"
            ))

            if total_tokens + example_tokens <= self.max_tokens:
                selected.append(example)
                total_tokens += example_tokens
            else:
                break

        return selected
```

## エッジケース処理

### 境界例を含める
```python
edge_case_examples = [
    # 空の入力
    {"input": "", "output": "入力テキストを提供してください。"},

    # 非常に長い入力（例では切り捨て）
    {"input": "..." + "word " * 1000, "output": "入力が最大長を超えています。"},

    # 曖昧な入力
    {"input": "bank", "output": "曖昧: 金融機関または河岸を指す可能性があります。"},

    # 無効な入力
    {"input": "!@#$%", "output": "無効な入力形式。有効なテキストを提供してください。"}
]
```

## Few-Shotプロンプトテンプレート

### 分類テンプレート
```python
def build_classification_prompt(examples, query, labels):
    prompt = f"テキストをこれらのカテゴリのいずれかに分類: {', '.join(labels)}\n\n"

    for ex in examples:
        prompt += f"テキスト: {ex['input']}\nカテゴリ: {ex['output']}\n\n"

    prompt += f"テキスト: {query}\nカテゴリ:"
    return prompt
```

### 抽出テンプレート
```python
def build_extraction_prompt(examples, query):
    prompt = "テキストから構造化情報を抽出。\n\n"

    for ex in examples:
        prompt += f"テキスト: {ex['input']}\n抽出: {json.dumps(ex['output'])}\n\n"

    prompt += f"テキスト: {query}\n抽出:"
    return prompt
```

### 変換テンプレート
```python
def build_transformation_prompt(examples, query):
    prompt = "例に示されたパターンに従って入力を変換。\n\n"

    for ex in examples:
        prompt += f"入力: {ex['input']}\n出力: {ex['output']}\n\n"

    prompt += f"入力: {query}\n出力:"
    return prompt
```

## 評価と最適化

### 例品質メトリクス
```python
def evaluate_example_quality(example, validation_set):
    metrics = {
        'clarity': rate_clarity(example),  # 0-1スコア
        'representativeness': calculate_similarity_to_validation(example, validation_set),
        'difficulty': estimate_difficulty(example),
        'uniqueness': calculate_uniqueness(example, other_examples)
    }
    return metrics
```

### 例セットのA/Bテスト
```python
class ExampleSetTester:
    def __init__(self, llm_client):
        self.client = llm_client

    def compare_example_sets(self, set_a, set_b, test_queries):
        results_a = self.evaluate_set(set_a, test_queries)
        results_b = self.evaluate_set(set_b, test_queries)

        return {
            'set_a_accuracy': results_a['accuracy'],
            'set_b_accuracy': results_b['accuracy'],
            'winner': 'A' if results_a['accuracy'] > results_b['accuracy'] else 'B',
            'improvement': abs(results_a['accuracy'] - results_b['accuracy'])
        }

    def evaluate_set(self, examples, test_queries):
        correct = 0
        for query in test_queries:
            prompt = build_prompt(examples, query['input'])
            response = self.client.complete(prompt)
            if response == query['expected_output']:
                correct += 1
        return {'accuracy': correct / len(test_queries)}
```

## 高度な技術

### メタ学習（選択を学習）
どの例が最も効果的かを予測する小規模モデルをトレーニング:

```python
from sklearn.ensemble import RandomForestClassifier

class LearnedExampleSelector:
    def __init__(self):
        self.selector_model = RandomForestClassifier()

    def train(self, training_data):
        # training_data: (query, example, success)タプルのリスト
        features = []
        labels = []

        for query, example, success in training_data:
            features.append(self.extract_features(query, example))
            labels.append(1 if success else 0)

        self.selector_model.fit(features, labels)

    def extract_features(self, query, example):
        return [
            semantic_similarity(query, example['input']),
            len(example['input']),
            len(example['output']),
            keyword_overlap(query, example['input'])
        ]

    def select(self, query, candidates, k=3):
        scores = []
        for example in candidates:
            features = self.extract_features(query, example)
            score = self.selector_model.predict_proba([features])[0][1]
            scores.append((score, example))

        return [ex for _, ex in sorted(scores, reverse=True)[:k]]
```

### 適応的例数
タスクの難易度に基づいて例の数を動的に調整:

```python
class AdaptiveExampleSelector:
    def __init__(self, examples):
        self.examples = examples

    def select(self, query, max_examples=5):
        # 1例から始める
        for k in range(1, max_examples + 1):
            selected = self.get_top_k(query, k)

            # クイック信頼度チェック（軽量モデルを使用可能）
            if self.estimated_confidence(query, selected) > 0.9:
                return selected

        return selected  # 十分に信頼できない場合はmax_examplesを返す
```

## よくあるミス

1. **例が多すぎる**: 多いほど良いとは限らない; 焦点を希薄化する可能性がある
2. **無関係な例**: 例はターゲットタスクと密接に一致する必要がある
3. **一貫性のないフォーマット**: 出力形式についてモデルを混乱させる
4. **例への過剰適合**: モデルが例のパターンを文字通りコピーしすぎる
5. **トークン制限の無視**: 実際の入力/出力のスペースが不足する

## リソース

- 例データセットリポジトリ
- 一般的なタスクのための事前構築された例セレクター
- Few-Shotパフォーマンスの評価フレームワーク
- 異なるモデルのためのトークンカウントユーティリティ
