> **[English](../../../../../../plugins/llm-application-dev/skills/prompt-engineering-patterns/references/prompt-templates.md)** | **日本語**

# プロンプトテンプレートシステム

## テンプレートアーキテクチャ

### 基本テンプレート構造
```python
class PromptTemplate:
    def __init__(self, template_string, variables=None):
        self.template = template_string
        self.variables = variables or []

    def render(self, **kwargs):
        missing = set(self.variables) - set(kwargs.keys())
        if missing:
            raise ValueError(f"必須変数が不足: {missing}")

        return self.template.format(**kwargs)

# 使用法
template = PromptTemplate(
    template_string="{text}を{source_lang}から{target_lang}に翻訳",
    variables=['text', 'source_lang', 'target_lang']
)

prompt = template.render(
    text="Hello world",
    source_lang="英語",
    target_lang="スペイン語"
)
```

[注: 実際のファイルには、条件付きテンプレート、モジュラーテンプレート構成、一般的なテンプレートパターン、高度な機能などの完全なセクションが続きます]

## ベストプラクティス

1. **DRYに保つ**: 繰り返しを避けるためにテンプレートを使用
2. **早期検証**: レンダリング前に変数をチェック
3. **テンプレートをバージョン管理**: コードのように変更を追跡
4. **バリエーションをテスト**: テンプレートが多様な入力で動作することを確認
5. **変数を文書化**: 必須/オプションの変数を明確に指定
6. **型ヒントを使用**: 変数型を明示
7. **デフォルトを提供**: 適切な場所で賢明なデフォルト値を設定
8. **賢くキャッシュ**: 静的テンプレートをキャッシュ、動的なものはしない

## テンプレートライブラリ

### 質問応答
```python
QA_TEMPLATES = {
    'factual': """コンテキストに基づいて質問に答えてください。

コンテキスト: {context}
質問: {question}
答え:""",

    'multi_hop': """複数の事実にわたって推論して質問に答えてください。

事実: {facts}
質問: {question}

推論:""",

    'conversational': """会話を自然に続けてください。

これまでの会話:
{history}

ユーザー: {question}
アシスタント:"""
}
```

### コンテンツ生成
```python
GENERATION_TEMPLATES = {
    'blog_post': """{topic}についてのブログ投稿を書いてください。

要件:
- 長さ: {word_count}語
- トーン: {tone}
- 含める: {key_points}

ブログ投稿:""",

    'product_description': """{product}の製品説明を書いてください。

特徴: {features}
利点: {benefits}
ターゲットオーディエンス: {audience}

説明:""",

    'email': """{type}メールを書いてください。

宛先: {recipient}
コンテキスト: {context}
重要ポイント: {key_points}

メール:"""
}
```

## パフォーマンス考慮事項

- 繰り返し使用のためにテンプレートを事前コンパイル
- 変数が静的な場合はレンダリングされたテンプレートをキャッシュ
- ループ内の文字列連結を最小化
- 効率的な文字列フォーマット（f-strings、.format()）を使用
- ボトルネックのためにテンプレートレンダリングをプロファイル
