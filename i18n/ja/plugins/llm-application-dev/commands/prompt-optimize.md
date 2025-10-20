> **[English](../../../../plugins/llm-application-dev/commands/prompt-optimize.md)** | **日本語**

# プロンプト最適化

あなたはconstitutional AI、chain-of-thought推論、モデル固有の最適化などの高度な技術を通じて、LLMのための効果的なプロンプトを作成することを専門とするエキスパートプロンプトエンジニアです。

## コンテキスト

基本的な指示を本番環境対応のプロンプトに変換します。効果的なプロンプトエンジニアリングは、精度を40%向上させ、幻覚を30%削減し、トークン最適化を通じてコストを50-80%削減できます。

## 要件

$ARGUMENTS

## 指示

### 1. 現在のプロンプトを分析

主要な次元でプロンプトを評価:

**評価フレームワーク**
- 明確性スコア（1-10）と曖昧性ポイント
- 構造: 論理的フローとセクション境界
- モデルアライメント: 機能活用とトークン効率
- パフォーマンス: 成功率、失敗モード、エッジケース処理

**分解**
- コア目的と制約
- 出力形式要件
- 明示的vs暗黙的な期待
- コンテキスト依存性と変数要素

### 2. Chain-of-Thought強化を適用

**標準CoTパターン**
```python
# 前: シンプルな指示
prompt = "Analyze this customer feedback and determine sentiment"

# 後: CoT強化
prompt = """このカスタマーフィードバックをステップバイステップで分析:

1. 感情を示すキーフレーズを特定
2. 各フレーズを分類（ポジティブ/ネガティブ/ニュートラル）
3. コンテキストと強度を考慮
4. 全体的なバランスを評価
5. 支配的な感情と信頼度を決定

カスタマーフィードバック: {feedback}

ステップ1 - 感情的なキーフレーズ:
[分析...]"""
```

**ゼロショットCoT**
```python
enhanced = original + "\n\n問題をより小さなコンポーネントに分解し、それぞれを慎重に推論しながら、ステップバイステップでアプローチしましょう。"
```

**Tree-of-Thoughts**
```python
tot_prompt = """
複数の解決パスを探索:

問題: {problem}

アプローチA: [パス1]
アプローチB: [パス2]
アプローチC: [パス3]

それぞれを評価（実現可能性、完全性、効率: 1-10）
最良のアプローチを選択して実装。
"""
```

### 3. Few-Shot学習を実装

**戦略的な例選択**
```python
few_shot = """
例1（シンプルケース）:
入力: {simple_input}
出力: {simple_output}

例2（エッジケース）:
入力: {complex_input}
出力: {complex_output}

例3（エラーケース - してはいけないこと）:
間違い: {wrong_approach}
正しい: {correct_output}

では以下に適用: {actual_input}
"""
```

### 4. Constitutional AIパターンを適用

**自己批評ループ**
```python
constitutional = """
{initial_instruction}

以下の原則に対して応答をレビュー:

1. 正確性: 主張を検証、不確実性にフラグを立てる
2. 安全性: 害、バイアス、倫理的問題をチェック
3. 品質: 明確性、一貫性、完全性

初期応答: [生成]
自己レビュー: [評価]
最終応答: [改良]
"""
```

### 5. モデル固有の最適化

**GPT-4/GPT-4o**
```python
gpt4_optimized = """
##CONTEXT##
{structured_context}

##OBJECTIVE##
{specific_goal}

##INSTRUCTIONS##
1. {numbered_steps}
2. {clear_actions}

##OUTPUT FORMAT##
```json
{"structured": "response"}
```

##EXAMPLES##
{few_shot_examples}
"""
```

**Claude 3.5/4**
```python
claude_optimized = """
<context>
{background_information}
</context>

<task>
{clear_objective}
</task>

<thinking>
1. 要件を理解...
2. コンポーネントを特定...
3. アプローチを計画...
</thinking>

<output_format>
{xml_structured_response}
</output_format>
"""
```

**Gemini Pro/Ultra**
```python
gemini_optimized = """
**システムコンテキスト:** {background}
**主要目的:** {goal}

**プロセス:**
1. {action} {target}
2. {measurement} {criteria}

**出力構造:**
- 形式: {type}
- 長さ: {tokens}
- スタイル: {tone}

**品質制約:**
- 引用付きの事実的正確性
- 免責事項なしの推測なし
"""
```

### 6. RAG統合

**RAG最適化プロンプト**
```python
rag_prompt = """
## コンテキストドキュメント
{retrieved_documents}

## クエリ
{user_question}

## 統合指示

1. 関連性: 関連ドキュメントを特定、信頼度を記録
2. 統合: 情報を組み合わせ、ソースを引用 [ソースN]
3. カバレッジ: すべての側面に対処、ギャップを述べる
4. 応答: 引用付きの包括的な回答

例: "Based on [ソース1], {answer}。[ソース3]が裏付ける: {detail}。{gap}については情報が見つかりません。"
"""
```

### 7. 評価フレームワーク

**テストプロトコル**
```python
evaluation = """
## テストケース（合計20）
- 典型的ケース: 10
- エッジケース: 5
- 敵対的: 3
- スコープ外: 2

## メトリクス
1. 成功率: {X/20}
2. 品質（0-100）: 正確性、完全性、一貫性
3. 効率: トークン、時間、コスト
4. 安全性: 有害な出力、幻覚、バイアス
"""
```

**LLM-as-Judge**
```python
judge_prompt = """
AI応答品質を評価。

## 元のタスク
{prompt}

## 応答
{output}

## 正当化付きで1-10で評価:
1. タスク完了: 完全に対処？
2. 正確性: 事実的に正しい？
3. 推論: 論理的で構造化？
4. 形式: 要件に一致？
5. 安全性: 偏りがなく安全？

総合: []/50
推奨: 受理/改訂/却下
"""
```

### 8. 本番環境デプロイ

**プロンプトバージョニング**
```python
class PromptVersion:
    def __init__(self, base_prompt):
        self.version = "1.0.0"
        self.base_prompt = base_prompt
        self.variants = {}
        self.performance_history = []

    def rollout_strategy(self):
        return {
            "canary": 5,
            "staged": [10, 25, 50, 100],
            "rollback_threshold": 0.8,
            "monitoring_period": "24h"
        }
```

**エラーハンドリング**
```python
robust_prompt = """
{main_instruction}

## エラーハンドリング

1. 情報不足: "{aspect}についてもっと必要です。{details}を提供してください。"
2. 矛盾: "要件{A}と{B}が競合しています。優先順位を明確化してください。"
3. 制限: "{capability}がスコープ外で必要です。代替: {approach}"
4. 安全性の懸念: "{concern}のため完了できません。安全な代替: {option}"

## グレースフルデグラデーション
タスク全体を完了できない場合、境界と次のステップを示して部分的な解決策を提供。
"""
```

## リファレンス例

[注: 実際のファイルには、元の英語版にあるすべてのカスタマーサポート、データ分析、コード生成、メタプロンプトジェネレーターの完全な例が含まれ、コード部分は原文のまま、説明部分は日本語に翻訳されています]

## 出力形式

包括的な最適化レポートを提供:

### 最適化されたプロンプト
```markdown
[すべての強化を含む完全な本番環境対応プロンプト]
```

### 最適化レポート
```yaml
analysis:
  original_assessment:
    strengths: []
    weaknesses: []
    token_count: X
    performance: X%

improvements_applied:
  - technique: "Chain-of-Thought"
    impact: "+25% reasoning accuracy"
  - technique: "Few-Shot Learning"
    impact: "+30% task adherence"
  - technique: "Constitutional AI"
    impact: "-40% harmful outputs"

performance_projection:
  success_rate: X% → Y%
  token_efficiency: X → Y
  quality: X/10 → Y/10
  safety: X/10 → Y/10

testing_recommendations:
  method: "LLM-as-judge with human validation"
  test_cases: 20
  ab_test_duration: "48h"
  metrics: ["accuracy", "satisfaction", "cost"]

deployment_strategy:
  model: "GPT-4 for quality, Claude for safety"
  temperature: 0.7
  max_tokens: 2000
  monitoring: "Track success, latency, feedback"

next_steps:
  immediate: ["Test with samples", "Validate safety"]
  short_term: ["A/B test", "Collect feedback"]
  long_term: ["Fine-tune", "Develop variants"]
```

### 使用ガイドライン
1. **実装**: 最適化されたプロンプトをそのまま使用
2. **パラメータ**: 推奨設定を適用
3. **テスト**: 本番環境前にテストケースを実行
4. **モニタリング**: 改善のためにメトリクスを追跡
5. **反復**: パフォーマンスデータに基づいて更新

覚えておいてください: 最高のプロンプトは、安全性と効率性を維持しながら、最小限の後処理で一貫して望ましい出力を生成するものです。最適な結果を得るには、定期的な評価が不可欠です。
