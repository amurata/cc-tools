# Chain-of-Thought プロンプティング

## 概要

Chain-of-Thought (CoT) プロンプティングは、LLMからステップバイステップの推論を引き出し、複雑な推論、数学、論理タスクのパフォーマンスを劇的に向上させます。

## コアテクニック

### Zero-Shot CoT
推論を引き出すために単純なトリガーフレーズを追加します：

```python
def zero_shot_cot(query):
    return f"""{query}

Let's think step by step:"""

# 例
query = "If a train travels 60 mph for 2.5 hours, how far does it go?"
prompt = zero_shot_cot(query)

# モデル出力:
# "Let's think step by step:
# 1. Speed = 60 miles per hour
# 2. Time = 2.5 hours
# 3. Distance = Speed × Time
# 4. Distance = 60 × 2.5 = 150 miles
# Answer: 150 miles"
```

### Few-Shot CoT
明示的な推論チェーンを含む例を提供します：

```python
few_shot_examples = """
Q: Roger has 5 tennis balls. He buys 2 more cans of tennis balls. Each can has 3 balls. How many tennis balls does he have now?
A: Let's think step by step:
1. Roger starts with 5 balls
2. He buys 2 cans, each with 3 balls
3. Balls from cans: 2 × 3 = 6 balls
4. Total: 5 + 6 = 11 balls
Answer: 11

Q: The cafeteria had 23 apples. If they used 20 to make lunch and bought 6 more, how many do they have?
A: Let's think step by step:
1. Started with 23 apples
2. Used 20 for lunch: 23 - 20 = 3 apples left
3. Bought 6 more: 3 + 6 = 9 apples
Answer: 9

Q: {user_query}
A: Let's think step by step:"""
```

### 自己整合性 (Self-Consistency)
複数の推論パスを生成し、多数決を取ります：

```python
import openai
from collections import Counter

def self_consistency_cot(query, n=5, temperature=0.7):
    prompt = f"{query}\n\nLet's think step by step:"

    responses = []
    for _ in range(n):
        response = openai.ChatCompletion.create(
            model="gpt-5",
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

### Least-to-Most プロンプティング
複雑な問題をより単純なサブ問題に分解します：

```python
def least_to_most_prompt(complex_query):
    # ステージ 1: 分解
    decomp_prompt = f"""Break down this complex problem into simpler subproblems:

Problem: {complex_query}

Subproblems:"""

    subproblems = get_llm_response(decomp_prompt)

    # ステージ 2: 順次解決
    solutions = []
    context = ""

    for subproblem in subproblems:
        solve_prompt = f"""{context}

Solve this subproblem:
{subproblem}

Solution:"""
        solution = get_llm_response(solve_prompt)
        solutions.append(solution)
        context += f"\n\nPreviously solved: {subproblem}\nSolution: {solution}"

    # ステージ 3: 最終統合
    final_prompt = f"""Given these solutions to subproblems:
{context}

Provide the final answer to: {complex_query}

Final Answer:"""

    return get_llm_response(final_prompt)
```

### Tree-of-Thought (ToT)
複数の推論分岐を探索します：

```python
class TreeOfThought:
    def __init__(self, llm_client, max_depth=3, branches_per_step=3):
        self.client = llm_client
        self.max_depth = max_depth
        self.branches_per_step = branches_per_step

    def solve(self, problem):
        # 初期の思考分岐を生成
        initial_thoughts = self.generate_thoughts(problem, depth=0)

        # 各分岐を評価
        best_path = None
        best_score = -1

        for thought in initial_thoughts:
            path, score = self.explore_branch(problem, thought, depth=1)
            if score > best_score:
                best_score = score
                best_path = path

        return best_path

    def generate_thoughts(self, problem, context="", depth=0):
        prompt = f"""Problem: {problem}
{context}

Generate {self.branches_per_step} different next steps in solving this problem:

1."""
        response = self.client.complete(prompt)
        return self.parse_thoughts(response)

    def evaluate_thought(self, problem, thought_path):
        prompt = f"""Problem: {problem}

Reasoning path so far:
{thought_path}

Rate this reasoning path from 0-10 for:
- Correctness
- Likelihood of reaching solution
- Logical coherence

Score:"""
        return float(self.client.complete(prompt))
```

### 検証ステップ
エラーを検出するために明示的な検証を追加します：

```python
def cot_with_verification(query):
    # ステージ 1: 推論と回答を生成
    reasoning_prompt = f"""{query}

Let's solve this step by step:"""

    reasoning_response = get_llm_response(reasoning_prompt)

    # ステージ 2: 推論を検証
    verification_prompt = f"""Original problem: {query}

Proposed solution:
{reasoning_response}

Verify this solution by:
1. Checking each step for logical errors
2. Verifying arithmetic calculations
3. Ensuring the final answer makes sense

Is this solution correct? If not, what's wrong?

Verification:"""

    verification = get_llm_response(verification_prompt)

    # ステージ 3: 必要に応じて修正
    if "incorrect" in verification.lower() or "error" in verification.lower():
        revision_prompt = f"""The previous solution had errors:
{verification}

Please provide a corrected solution to: {query}

Corrected solution:"""
        return get_llm_response(revision_prompt)

    return reasoning_response
```

## ドメイン固有の CoT

### 数学の問題
```python
math_cot_template = """
Problem: {problem}

Solution:
Step 1: Identify what we know
- {list_known_values}

Step 2: Identify what we need to find
- {target_variable}

Step 3: Choose relevant formulas
- {formulas}

Step 4: Substitute values
- {substitution}

Step 5: Calculate
- {calculation}

Step 6: Verify and state answer
- {verification}

Answer: {final_answer}
"""
```

### コードデバッグ
```python
debug_cot_template = """
Code with error:
{code}

Error message:
{error}

Debugging process:
Step 1: Understand the error message
- {interpret_error}

Step 2: Locate the problematic line
- {identify_line}

Step 3: Analyze why this line fails
- {root_cause}

Step 4: Determine the fix
- {proposed_fix}

Step 5: Verify the fix addresses the error
- {verification}

Fixed code:
{corrected_code}
"""
```

### 論理的推論
```python
logic_cot_template = """
Premises:
{premises}

Question: {question}

Reasoning:
Step 1: List all given facts
{facts}

Step 2: Identify logical relationships
{relationships}

Step 3: Apply deductive reasoning
{deductions}

Step 4: Draw conclusion
{conclusion}

Answer: {final_answer}
"""
```

## パフォーマンス最適化

### 推論パターンのキャッシュ
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

### 適応型推論深度
```python
def adaptive_cot(problem, initial_depth=3):
    depth = initial_depth

    while depth <= 10:  # 最大深度
        response = generate_cot(problem, num_steps=depth)

        # 解決策が完全か確認
        if is_solution_complete(response):
            return response

        depth += 2  # 推論深度を増やす

    return response  # 最良の試行を返す
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

1. **明確なステップマーカー**: 番号付きステップまたは明確な区切り文字を使用する
2. **すべての作業を表示**: 明らかなステップであってもスキップしない
3. **計算の検証**: 明示的な検証ステップを追加する
4. **仮定を述べる**: 暗黙の仮定を明示的にする
5. **エッジケースの確認**: 境界条件を考慮する
6. **例を使用する**: 最初に例を使って推論パターンを示す

## 一般的な落とし穴

- **時期尚早な結論**: 完全な推論なしに答えに飛びつく
- **循環論法**: 推論を正当化するために結論を使用する
- **ステップの欠落**: 中間計算をスキップする
- **過度に複雑**: 混乱させる不要なステップを追加する
- **一貫性のない形式**: 推論の途中でステップ構造を変更する

## CoT をいつ使用するか

**以下の場合に CoT を使用:**
- 数学および算術の問題
- 論理的推論タスク
- マルチステップ計画
- コード生成とデバッグ
- 複雑な意思決定

**以下の場合に CoT をスキップ:**
- 単純な事実のクエリ
- 直接的なルックアップ
- クリエイティブライティング
- 簡潔さを必要とするタスク
- リアルタイム、レイテンシに敏感なアプリケーション

## リソース

- CoT 評価用ベンチマークデータセット
- 事前構築済み CoT プロンプトテンプレート
- 推論検証ツール
- ステップ抽出および解析ユーティリティ
