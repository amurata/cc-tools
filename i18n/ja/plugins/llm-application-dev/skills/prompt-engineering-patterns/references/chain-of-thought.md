> **[English](../../../../../../plugins/llm-application-dev/skills/prompt-engineering-patterns/references/chain-of-thought.md)** | **日本語**

# Chain-of-Thoughtプロンプト

## 概要

Chain-of-Thought（CoT）プロンプトは、LLMからステップバイステップの推論を引き出し、複雑な推論、数学、論理タスクでのパフォーマンスを劇的に向上させます。

## コア技術

### ゼロショットCoT
推論を引き出すためにシンプルなトリガーフレーズを追加:

```python
def zero_shot_cot(query):
    return f"""{query}

ステップバイステップで考えてみましょう:"""

# 例
query = "列車が時速60マイルで2.5時間走行した場合、どのくらいの距離を移動しますか？"
prompt = zero_shot_cot(query)

# モデル出力:
# "ステップバイステップで考えてみましょう:
# 1. 速度 = 時速60マイル
# 2. 時間 = 2.5時間
# 3. 距離 = 速度 × 時間
# 4. 距離 = 60 × 2.5 = 150マイル
# 答え: 150マイル"
```

### Few-Shot CoT
明示的な推論チェーンを持つ例を提供:

```python
few_shot_examples = """
Q: ロジャーはテニスボールを5個持っています。彼はテニスボールの缶を2個追加購入しました。各缶には3個のボールが入っています。彼は今何個のテニスボールを持っていますか？
A: ステップバイステップで考えてみましょう:
1. ロジャーは5個のボールから始まります
2. 彼は2缶を購入し、各缶には3個のボールが入っています
3. 缶からのボール: 2 × 3 = 6個のボール
4. 合計: 5 + 6 = 11個のボール
答え: 11

Q: カフェテリアにはリンゴが23個ありました。昼食を作るために20個を使用し、さらに6個購入した場合、何個持っていますか？
A: ステップバイステップで考えてみましょう:
1. 23個のリンゴから始まりました
2. 昼食に20個使用: 23 - 20 = 3個のリンゴが残ります
3. さらに6個購入: 3 + 6 = 9個のリンゴ
答え: 9

Q: {user_query}
A: ステップバイステップで考えてみましょう:"""
```

### Self-Consistency
複数の推論パスを生成し、多数決を取る:

```python
import openai
from collections import Counter

def self_consistency_cot(query, n=5, temperature=0.7):
    prompt = f"{query}\n\nステップバイステップで考えてみましょう:"

    responses = []
    for _ in range(n):
        response = openai.ChatCompletion.create(
            model="gpt-4",
            messages=[{"role": "user", "content": prompt}],
            temperature=temperature
        )
        responses.append(extract_final_answer(response))

    # 多数決を取る
    answer_counts = Counter(responses)
    final_answer = answer_counts.most_common(1)[0][0]

    return {
        'answer': final_answer,
        'confidence': answer_counts[final_answer] / n,
        'all_responses': responses
    }
```

## 高度なパターン

### Least-to-Mostプロンプト
複雑な問題をより単純な部分問題に分解:

```python
def least_to_most_prompt(complex_query):
    # ステージ1: 分解
    decomp_prompt = f"""この複雑な問題をより単純な部分問題に分解:

問題: {complex_query}

部分問題:"""

    subproblems = get_llm_response(decomp_prompt)

    # ステージ2: 順次解決
    solutions = []
    context = ""

    for subproblem in subproblems:
        solve_prompt = f"""{context}

この部分問題を解決:
{subproblem}

解答:"""
        solution = get_llm_response(solve_prompt)
        solutions.append(solution)
        context += f"\n\n以前に解決: {subproblem}\n解答: {solution}"

    # ステージ3: 最終統合
    final_prompt = f"""これらの部分問題の解答を考慮:
{context}

{complex_query}への最終回答を提供

最終回答:"""

    return get_llm_response(final_prompt)
```

### Tree-of-Thought（ToT）
複数の推論ブランチを探索:

```python
class TreeOfThought:
    def __init__(self, llm_client, max_depth=3, branches_per_step=3):
        self.client = llm_client
        self.max_depth = max_depth
        self.branches_per_step = branches_per_step

    def solve(self, problem):
        # 初期思考ブランチを生成
        initial_thoughts = self.generate_thoughts(problem, depth=0)

        # 各ブランチを評価
        best_path = None
        best_score = -1

        for thought in initial_thoughts:
            path, score = self.explore_branch(problem, thought, depth=1)
            if score > best_score:
                best_score = score
                best_path = path

        return best_path

    def generate_thoughts(self, problem, context="", depth=0):
        prompt = f"""問題: {problem}
{context}

この問題を解決するための{self.branches_per_step}の異なる次のステップを生成:

1."""
        response = self.client.complete(prompt)
        return self.parse_thoughts(response)

    def evaluate_thought(self, problem, thought_path):
        prompt = f"""問題: {problem}

これまでの推論パス:
{thought_path}

この推論パスを以下について0-10で評価:
- 正しさ
- 解決に到達する可能性
- 論理的一貫性

スコア:"""
        return float(self.client.complete(prompt))
```

### 検証ステップ
エラーをキャッチするための明示的な検証を追加:

```python
def cot_with_verification(query):
    # ステップ1: 推論と回答を生成
    reasoning_prompt = f"""{query}

これをステップバイステップで解決しましょう:"""

    reasoning_response = get_llm_response(reasoning_prompt)

    # ステップ2: 推論を検証
    verification_prompt = f"""元の問題: {query}

提案された解答:
{reasoning_response}

次の方法でこの解答を検証:
1. 各ステップの論理エラーをチェック
2. 算術計算を検証
3. 最終回答が理にかなっていることを確認

この解答は正しいですか？正しくない場合、何が間違っていますか？

検証:"""

    verification = get_llm_response(verification_prompt)

    # ステップ3: 必要に応じて修正
    if "incorrect" in verification.lower() or "error" in verification.lower():
        revision_prompt = f"""前の解答にエラーがありました:
{verification}

{query}への修正された解答を提供してください

修正された解答:"""
        return get_llm_response(revision_prompt)

    return reasoning_response
```

## ドメイン固有のCoT

### 数学問題
```python
math_cot_template = """
問題: {problem}

解答:
ステップ1: 既知のものを特定
- {list_known_values}

ステップ2: 見つける必要があるものを特定
- {target_variable}

ステップ3: 関連する公式を選択
- {formulas}

ステップ4: 値を代入
- {substitution}

ステップ5: 計算
- {calculation}

ステップ6: 検証して答えを述べる
- {verification}

答え: {final_answer}
"""
```

### コードデバッグ
```python
debug_cot_template = """
エラーのあるコード:
{code}

エラーメッセージ:
{error}

デバッグプロセス:
ステップ1: エラーメッセージを理解
- {interpret_error}

ステップ2: 問題のある行を特定
- {identify_line}

ステップ3: この行が失敗する理由を分析
- {root_cause}

ステップ4: 修正を決定
- {proposed_fix}

ステップ5: 修正がエラーに対処することを検証
- {verification}

修正されたコード:
{corrected_code}
"""
```

### 論理推論
```python
logic_cot_template = """
前提:
{premises}

質問: {question}

推論:
ステップ1: 与えられたすべての事実をリストアップ
{facts}

ステップ2: 論理的関係を特定
{relationships}

ステップ3: 演繹推論を適用
{deductions}

ステップ4: 結論を導出
{conclusion}

答え: {final_answer}
"""
```

## パフォーマンス最適化

### 推論パターンのキャッシング
```python
class ReasoningCache:
    def __init__(self):
        self.cache = {}

    def get_similar_reasoning(self, problem, threshold=0.85):
        problem_embedding = embed(problem)

        for cached_problem, reasoning in self.cache.items():
            similarity = cosine_similarity(
                problem_embedding,
                embed(cached_problem)
            )
            if similarity > threshold:
                return reasoning

        return None

    def add_reasoning(self, problem, reasoning):
        self.cache[problem] = reasoning
```

### 適応的推論深度
```python
def adaptive_cot(problem, initial_depth=3):
    depth = initial_depth

    while depth <= 10:  # 最大深度
        response = generate_cot(problem, num_steps=depth)

        # 解答が完全かどうかをチェック
        if is_solution_complete(response):
            return response

        depth += 2  # 推論深度を増やす

    return response  # 最良の試みを返す
```

## 評価メトリクス

```python
def evaluate_cot_quality(reasoning_chain):
    metrics = {
        'coherence': measure_logical_coherence(reasoning_chain),
        'completeness': check_all_steps_present(reasoning_chain),
        'correctness': verify_final_answer(reasoning_chain),
        'efficiency': count_unnecessary_steps(reasoning_chain),
        'clarity': rate_explanation_clarity(reasoning_chain)
    }
    return metrics
```

## ベストプラクティス

1. **明確なステップマーカー**: 番号付きステップまたは明確な区切りを使用
2. **すべての作業を表示**: 明白なステップであってもスキップしない
3. **計算を検証**: 明示的な検証ステップを追加
4. **仮定を述べる**: 暗黙の仮定を明示的にする
5. **エッジケースを確認**: 境界条件を考慮
6. **例を使用**: まず例で推論パターンを示す

## よくある落とし穴

- **早期の結論**: 完全な推論なしで答えに飛びつく
- **循環論理**: 結論を使用して推論を正当化
- **欠落ステップ**: 中間計算をスキップ
- **過度に複雑**: 混乱させる不要なステップを追加
- **一貫性のないフォーマット**: 推論の途中でステップ構造を変更

## CoTを使用するとき

**CoTを使用する場合:**
- 数学と算術問題
- 論理推論タスク
- 多段階計画
- コード生成とデバッグ
- 複雑な意思決定

**CoTをスキップする場合:**
- シンプルな事実クエリ
- 直接的な検索
- クリエイティブライティング
- 簡潔性を必要とするタスク
- リアルタイム、レイテンシに敏感なアプリケーション

## リソース

- CoT評価のためのベンチマークデータセット
- 事前構築されたCoTプロンプトテンプレート
- 推論検証ツール
- ステップ抽出と解析ユーティリティ
