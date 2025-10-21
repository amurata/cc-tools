> **[English](../../../../../../plugins/llm-application-dev/skills/prompt-engineering-patterns/references/prompt-optimization.md)** | **日本語**

# プロンプト最適化ガイド

## 体系的な改良プロセス

### 1. ベースライン確立
```python
def establish_baseline(prompt, test_cases):
    results = {
        'accuracy': 0,
        'avg_tokens': 0,
        'avg_latency': 0,
        'success_rate': 0
    }

    for test_case in test_cases:
        response = llm.complete(prompt.format(**test_case['input']))

        results['accuracy'] += evaluate_accuracy(response, test_case['expected'])
        results['avg_tokens'] += count_tokens(response)
        results['avg_latency'] += measure_latency(response)
        results['success_rate'] += is_valid_response(response)

    # テストケース全体で平均化
    n = len(test_cases)
    return {k: v/n for k, v in results.items()}
```

### 2. 反復的改良ワークフロー
```
初期プロンプト → テスト → 失敗を分析 → 改良 → テスト → 繰り返し
```

```python
class PromptOptimizer:
    def __init__(self, initial_prompt, test_suite):
        self.prompt = initial_prompt
        self.test_suite = test_suite
        self.history = []

    def optimize(self, max_iterations=10):
        for i in range(max_iterations):
            # 現在のプロンプトをテスト
            results = self.evaluate_prompt(self.prompt)
            self.history.append({
                'iteration': i,
                'prompt': self.prompt,
                'results': results
            })

            # 十分に良ければ停止
            if results['accuracy'] > 0.95:
                break

            # 失敗を分析
            failures = self.analyze_failures(results)

            # 改良提案を生成
            refinements = self.generate_refinements(failures)

            # 最良の改良を適用
            self.prompt = self.select_best_refinement(refinements)

        return self.get_best_prompt()
```

### 3. A/Bテストフレームワーク
```python
class PromptABTest:
    def __init__(self, variant_a, variant_b):
        self.variant_a = variant_a
        self.variant_b = variant_b

    def run_test(self, test_queries, metrics=['accuracy', 'latency']):
        results = {
            'A': {m: [] for m in metrics},
            'B': {m: [] for m in metrics}
        }

        for query in test_queries:
            # バリアントをランダムに割り当て（50/50分割）
            variant = 'A' if random.random() < 0.5 else 'B'
            prompt = self.variant_a if variant == 'A' else self.variant_b

            response, metrics_data = self.execute_with_metrics(
                prompt.format(query=query['input'])
            )

            for metric in metrics:
                results[variant][metric].append(metrics_data[metric])

        return self.analyze_results(results)

    def analyze_results(self, results):
        from scipy import stats

        analysis = {}
        for metric in results['A'].keys():
            a_values = results['A'][metric]
            b_values = results['B'][metric]

            # 統計的有意性テスト
            t_stat, p_value = stats.ttest_ind(a_values, b_values)

            analysis[metric] = {
                'A_mean': np.mean(a_values),
                'B_mean': np.mean(b_values),
                'improvement': (np.mean(b_values) - np.mean(a_values)) / np.mean(a_values),
                'statistically_significant': p_value < 0.05,
                'p_value': p_value,
                'winner': 'B' if np.mean(b_values) > np.mean(a_values) else 'A'
            }

        return analysis
```

## 最適化戦略

### トークン削減
```python
def optimize_for_tokens(prompt):
    optimizations = [
        # 冗長なフレーズを削除
        ('in order to', 'to'),
        ('due to the fact that', 'because'),
        ('at this point in time', 'now'),

        # 指示を統合
        ('First, ...\\nThen, ...\\nFinally, ...', 'Steps: 1) ... 2) ... 3) ...'),

        # 略語を使用（最初の定義後）
        ('Natural Language Processing (NLP)', 'NLP'),

        # フィラーワードを削除
        (' actually ', ' '),
        (' basically ', ' '),
        (' really ', ' ')
    ]

    optimized = prompt
    for old, new in optimizations:
        optimized = optimized.replace(old, new)

    return optimized
```

### レイテンシ削減
```python
def optimize_for_latency(prompt):
    strategies = {
        'shorter_prompt': reduce_token_count(prompt),
        'streaming': enable_streaming_response(prompt),
        'caching': add_cacheable_prefix(prompt),
        'early_stopping': add_stop_sequences(prompt)
    }

    # 各戦略をテスト
    best_strategy = None
    best_latency = float('inf')

    for name, modified_prompt in strategies.items():
        latency = measure_average_latency(modified_prompt)
        if latency < best_latency:
            best_latency = latency
            best_strategy = modified_prompt

    return best_strategy
```

### 精度向上
```python
def improve_accuracy(prompt, failure_cases):
    improvements = []

    # 一般的な失敗に対する制約を追加
    if has_format_errors(failure_cases):
        improvements.append("Output must be valid JSON with no additional text.")

    # エッジケースの例を追加
    edge_cases = identify_edge_cases(failure_cases)
    if edge_cases:
        improvements.append(f"Examples of edge cases:\\n{format_examples(edge_cases)}")

    # 検証ステップを追加
    if has_logical_errors(failure_cases):
        improvements.append("Before responding, verify your answer is logically consistent.")

    # 指示を強化
    if has_ambiguity_errors(failure_cases):
        improvements.append(clarify_ambiguous_instructions(prompt))

    return integrate_improvements(prompt, improvements)
```

## パフォーマンスメトリクス

### コアメトリクス
```python
class PromptMetrics:
    @staticmethod
    def accuracy(responses, ground_truth):
        return sum(r == gt for r, gt in zip(responses, ground_truth)) / len(responses)

    @staticmethod
    def consistency(responses):
        # 同一入力が同一出力を生成する頻度を測定
        from collections import defaultdict
        input_responses = defaultdict(list)

        for inp, resp in responses:
            input_responses[inp].append(resp)

        consistency_scores = []
        for inp, resps in input_responses.items():
            if len(resps) > 1:
                # 最も一般的な応答と一致する応答の割合
                most_common_count = Counter(resps).most_common(1)[0][1]
                consistency_scores.append(most_common_count / len(resps))

        return np.mean(consistency_scores) if consistency_scores else 1.0

    @staticmethod
    def token_efficiency(prompt, responses):
        avg_prompt_tokens = np.mean([count_tokens(prompt.format(**r['input'])) for r in responses])
        avg_response_tokens = np.mean([count_tokens(r['output']) for r in responses])
        return avg_prompt_tokens + avg_response_tokens

    @staticmethod
    def latency_p95(latencies):
        return np.percentile(latencies, 95)
```

### 自動評価
```python
def evaluate_prompt_comprehensively(prompt, test_suite):
    results = {
        'accuracy': [],
        'consistency': [],
        'latency': [],
        'tokens': [],
        'success_rate': []
    }

    # 一貫性測定のため、各テストケースを複数回実行
    for test_case in test_suite:
        runs = []
        for _ in range(3):  # テストケースごとに3回実行
            start = time.time()
            response = llm.complete(prompt.format(**test_case['input']))
            latency = time.time() - start

            runs.append(response)
            results['latency'].append(latency)
            results['tokens'].append(count_tokens(prompt) + count_tokens(response))

        # 正確性（3回の実行のベスト）
        accuracies = [evaluate_accuracy(r, test_case['expected']) for r in runs]
        results['accuracy'].append(max(accuracies))

        # 一貫性（3回の実行がどれだけ似ているか？）
        results['consistency'].append(calculate_similarity(runs))

        # 成功率（すべての実行が成功？）
        results['success_rate'].append(all(is_valid(r) for r in runs))

    return {
        'avg_accuracy': np.mean(results['accuracy']),
        'avg_consistency': np.mean(results['consistency']),
        'p95_latency': np.percentile(results['latency'], 95),
        'avg_tokens': np.mean(results['tokens']),
        'success_rate': np.mean(results['success_rate'])
    }
```

## 失敗分析

### 失敗の分類
```python
class FailureAnalyzer:
    def categorize_failures(self, test_results):
        categories = {
            'format_errors': [],
            'factual_errors': [],
            'logic_errors': [],
            'incomplete_responses': [],
            'hallucinations': [],
            'off_topic': []
        }

        for result in test_results:
            if not result['success']:
                category = self.determine_failure_type(
                    result['response'],
                    result['expected']
                )
                categories[category].append(result)

        return categories

    def generate_fixes(self, categorized_failures):
        fixes = []

        if categorized_failures['format_errors']:
            fixes.append({
                'issue': 'Format errors',
                'fix': 'Add explicit format examples and constraints',
                'priority': 'high'
            })

        if categorized_failures['hallucinations']:
            fixes.append({
                'issue': 'Hallucinations',
                'fix': 'Add grounding instruction: "Base your answer only on provided context"',
                'priority': 'critical'
            })

        if categorized_failures['incomplete_responses']:
            fixes.append({
                'issue': 'Incomplete responses',
                'fix': 'Add: "Ensure your response fully addresses all parts of the question"',
                'priority': 'medium'
            })

        return fixes
```

## バージョニングとロールバック

### プロンプトバージョン管理
```python
class PromptVersionControl:
    def __init__(self, storage_path):
        self.storage = storage_path
        self.versions = []

    def save_version(self, prompt, metadata):
        version = {
            'id': len(self.versions),
            'prompt': prompt,
            'timestamp': datetime.now(),
            'metrics': metadata.get('metrics', {}),
            'description': metadata.get('description', ''),
            'parent_id': metadata.get('parent_id')
        }
        self.versions.append(version)
        self.persist()
        return version['id']

    def rollback(self, version_id):
        if version_id < len(self.versions):
            return self.versions[version_id]['prompt']
        raise ValueError(f"Version {version_id} not found")

    def compare_versions(self, v1_id, v2_id):
        v1 = self.versions[v1_id]
        v2 = self.versions[v2_id]

        return {
            'diff': generate_diff(v1['prompt'], v2['prompt']),
            'metrics_comparison': {
                metric: {
                    'v1': v1['metrics'].get(metric),
                    'v2': v2['metrics'].get(metric),
                    'change': v2['metrics'].get(metric, 0) - v1['metrics'].get(metric, 0)
                }
                for metric in set(v1['metrics'].keys()) | set(v2['metrics'].keys())
            }
        }
```

## ベストプラクティス

1. **ベースラインを確立**: 常に初期パフォーマンスを測定します
2. **一度に一つ変更**: 明確な帰属のために変数を分離します
3. **徹底的にテスト**: 多様で代表的なテストケースを使用します
4. **メトリクスを追跡**: すべての実験と結果をログに記録します
5. **有意性を検証**: A/B比較に統計的テストを使用します
6. **変更を文書化**: 何をなぜ変更したかの詳細なメモを保持します
7. **すべてをバージョン管理**: 以前のバージョンへのロールバックを可能にします
8. **本番環境を監視**: デプロイされたプロンプトを継続的に評価します

## 一般的な最適化パターン

### パターン1: 構造を追加
```
変更前: "Analyze this text"
変更後: "Analyze this text for:\n1. Main topic\n2. Key arguments\n3. Conclusion"
```

### パターン2: 例を追加
```
変更前: "Extract entities"
変更後: "Extract entities\\n\\nExample:\\nText: Apple released iPhone\\nEntities: {company: Apple, product: iPhone}"
```

### パターン3: 制約を追加
```
変更前: "Summarize this"
変更後: "Summarize in exactly 3 bullet points, 15 words each"
```

### パターン4: 検証を追加
```
変更前: "Calculate..."
変更後: "Calculate... Then verify your calculation is correct before responding."
```

## ツールとユーティリティ

- バージョン比較のためのプロンプト差分ツール
- 自動テストランナー
- メトリクスダッシュボード
- A/Bテストフレームワーク
- トークンカウントユーティリティ
- レイテンシプロファイラー
