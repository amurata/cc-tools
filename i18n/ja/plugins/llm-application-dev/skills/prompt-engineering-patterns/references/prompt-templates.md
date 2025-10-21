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
            raise ValueError(f"必須変数が不足しています: {missing}")

        return self.template.format(**kwargs)

# 使用法
template = PromptTemplate(
    template_string="{text}を{source_lang}から{target_lang}に翻訳",
    variables=['text', 'source_lang', 'target_lang']
)

prompt = template.render(
    text="Hello world",
    source_lang="English",
    target_lang="Spanish"
)
```

### 条件付きテンプレート
```python
class ConditionalTemplate(PromptTemplate):
    def render(self, **kwargs):
        # 条件ブロックを処理
        result = self.template

        # if-blocksを処理: {{#if variable}}content{{/if}}
        import re
        if_pattern = r'\{\{#if (\w+)\}\}(.*?)\{\{/if\}\}'

        def replace_if(match):
            var_name = match.group(1)
            content = match.group(2)
            return content if kwargs.get(var_name) else ''

        result = re.sub(if_pattern, replace_if, result, flags=re.DOTALL)

        # for-loopsを処理: {{#each items}}{{this}}{{/each}}
        each_pattern = r'\{\{#each (\w+)\}\}(.*?)\{\{/each\}\}'

        def replace_each(match):
            var_name = match.group(1)
            content = match.group(2)
            items = kwargs.get(var_name, [])
            return '\\n'.join(content.replace('{{this}}', str(item)) for item in items)

        result = re.sub(each_pattern, replace_each, result, flags=re.DOTALL)

        # 最後に、残りの変数をレンダリング
        return result.format(**kwargs)

# 使用法
template = ConditionalTemplate("""
以下のテキストを分析してください:
{text}

{{#if include_sentiment}}
感情分析を提供してください。
{{/if}}

{{#if include_entities}}
固有表現を抽出してください。
{{/if}}

{{#if examples}}
参考例:
{{#each examples}}
- {{this}}
{{/each}}
{{/if}}
""")
```

### モジュラーテンプレート構成
```python
class ModularTemplate:
    def __init__(self):
        self.components = {}

    def register_component(self, name, template):
        self.components[name] = template

    def render(self, structure, **kwargs):
        parts = []
        for component_name in structure:
            if component_name in self.components:
                component = self.components[component_name]
                parts.append(component.format(**kwargs))

        return '\\n\\n'.join(parts)

# 使用法
builder = ModularTemplate()

builder.register_component('system', "あなたは{role}です。")
builder.register_component('context', "コンテキスト: {context}")
builder.register_component('instruction', "タスク: {task}")
builder.register_component('examples', "例:\\n{examples}")
builder.register_component('input', "入力: {input}")
builder.register_component('format', "出力形式: {format}")

# 異なるシナリオ用に異なるテンプレートを構成
basic_prompt = builder.render(
    ['system', 'instruction', 'input'],
    role='親切なアシスタント',
    instruction='テキストを要約してください',
    input='...'
)

advanced_prompt = builder.render(
    ['system', 'context', 'examples', 'instruction', 'input', 'format'],
    role='専門アナリスト',
    context='財務分析',
    examples='...',
    instruction='感情を分析してください',
    input='...',
    format='JSON'
)
```

## 一般的なテンプレートパターン

### 分類テンプレート
```python
CLASSIFICATION_TEMPLATE = """
以下の{content_type}を次のカテゴリのいずれかに分類してください: {categories}

{{#if description}}
カテゴリの説明:
{description}
{{/if}}

{{#if examples}}
例:
{examples}
{{/if}}

{content_type}: {input}

カテゴリ:"""
```

### 抽出テンプレート
```python
EXTRACTION_TEMPLATE = """
{content_type}から構造化された情報を抽出してください。

必須フィールド:
{field_definitions}

{{#if examples}}
抽出例:
{examples}
{{/if}}

{content_type}: {input}

抽出された情報(JSON):"""
```

### 生成テンプレート
```python
GENERATION_TEMPLATE = """
以下の{input_type}に基づいて{output_type}を生成してください。

要件:
{requirements}

{{#if style}}
スタイル: {style}
{{/if}}

{{#if constraints}}
制約:
{constraints}
{{/if}}

{{#if examples}}
例:
{examples}
{{/if}}

{input_type}: {input}

{output_type}:"""
```

### 変換テンプレート
```python
TRANSFORMATION_TEMPLATE = """
入力{source_format}を{target_format}に変換してください。

変換ルール:
{rules}

{{#if examples}}
変換例:
{examples}
{{/if}}

入力{source_format}:
{input}

出力{target_format}:"""
```

## 高度な機能

### テンプレート継承
```python
class TemplateRegistry:
    def __init__(self):
        self.templates = {}

    def register(self, name, template, parent=None):
        if parent and parent in self.templates:
            # 親から継承
            base = self.templates[parent]
            template = self.merge_templates(base, template)

        self.templates[name] = template

    def merge_templates(self, parent, child):
        # 子が親のセクションを上書き
        return {**parent, **child}

# 使用法
registry = TemplateRegistry()

registry.register('base_analysis', {
    'system': 'あなたは専門アナリストです。',
    'format': '構造化された形式で分析を提供してください。'
})

registry.register('sentiment_analysis', {
    'instruction': '感情を分析してください',
    'format': '-1から1までの感情スコアを提供してください。'
}, parent='base_analysis')
```

### 変数検証
```python
class ValidatedTemplate:
    def __init__(self, template, schema):
        self.template = template
        self.schema = schema

    def validate_vars(self, **kwargs):
        for var_name, var_schema in self.schema.items():
            if var_name in kwargs:
                value = kwargs[var_name]

                # 型検証
                if 'type' in var_schema:
                    expected_type = var_schema['type']
                    if not isinstance(value, expected_type):
                        raise TypeError(f"{var_name}は{expected_type}型である必要があります")

                # 範囲検証
                if 'min' in var_schema and value < var_schema['min']:
                    raise ValueError(f"{var_name}は{var_schema['min']}以上である必要があります")

                if 'max' in var_schema and value > var_schema['max']:
                    raise ValueError(f"{var_name}は{var_schema['max']}以下である必要があります")

                # 列挙検証
                if 'choices' in var_schema and value not in var_schema['choices']:
                    raise ValueError(f"{var_name}は{var_schema['choices']}のいずれかである必要があります")

    def render(self, **kwargs):
        self.validate_vars(**kwargs)
        return self.template.format(**kwargs)

# 使用法
template = ValidatedTemplate(
    template="{length}語で{tone}なトーンで要約してください",
    schema={
        'length': {'type': int, 'min': 10, 'max': 500},
        'tone': {'type': str, 'choices': ['フォーマル', 'カジュアル', '技術的']}
    }
)
```

### テンプレートキャッシング
```python
class CachedTemplate:
    def __init__(self, template):
        self.template = template
        self.cache = {}

    def render(self, use_cache=True, **kwargs):
        if use_cache:
            cache_key = self.get_cache_key(kwargs)
            if cache_key in self.cache:
                return self.cache[cache_key]

        result = self.template.format(**kwargs)

        if use_cache:
            self.cache[cache_key] = result

        return result

    def get_cache_key(self, kwargs):
        return hash(frozenset(kwargs.items()))

    def clear_cache(self):
        self.cache = {}
```

## マルチターンテンプレート

### 会話テンプレート
```python
class ConversationTemplate:
    def __init__(self, system_prompt):
        self.system_prompt = system_prompt
        self.history = []

    def add_user_message(self, message):
        self.history.append({'role': 'user', 'content': message})

    def add_assistant_message(self, message):
        self.history.append({'role': 'assistant', 'content': message})

    def render_for_api(self):
        messages = [{'role': 'system', 'content': self.system_prompt}]
        messages.extend(self.history)
        return messages

    def render_as_text(self):
        result = f"システム: {self.system_prompt}\\n\\n"
        for msg in self.history:
            role = msg['role'].capitalize()
            result += f"{role}: {msg['content']}\\n\\n"
        return result
```

### 状態ベーステンプレート
```python
class StatefulTemplate:
    def __init__(self):
        self.state = {}
        self.templates = {}

    def set_state(self, **kwargs):
        self.state.update(kwargs)

    def register_state_template(self, state_name, template):
        self.templates[state_name] = template

    def render(self):
        current_state = self.state.get('current_state', 'default')
        template = self.templates.get(current_state)

        if not template:
            raise ValueError(f"状態のテンプレートがありません: {current_state}")

        return template.format(**self.state)

# マルチステップワークフローの使用法
workflow = StatefulTemplate()

workflow.register_state_template('init', """
ようこそ！{task}をしましょう。
あなたの{first_input}は何ですか？
""")

workflow.register_state_template('processing', """
ありがとうございます！{first_input}を処理しています。
次に、あなたの{second_input}は何ですか？
""")

workflow.register_state_template('complete', """
素晴らしい！以下に基づいて:
- {first_input}
- {second_input}

結果は次のとおりです: {result}
""")
```

## ベストプラクティス

1. **DRYに保つ**: 繰り返しを避けるためにテンプレートを使用
2. **早期検証**: レンダリング前に変数をチェック
3. **テンプレートをバージョン管理**: コードのように変更を追跡
4. **バリエーションをテスト**: テンプレートが多様な入力で動作することを確認
5. **変数を文書化**: 必須/オプションの変数を明確に指定
6. **型ヒントを使用**: 変数型を明示的にする
7. **デフォルトを提供**: 適切な場所で賢明なデフォルト値を設定
8. **賢くキャッシュ**: 静的テンプレートをキャッシュし、動的なものはしない

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
