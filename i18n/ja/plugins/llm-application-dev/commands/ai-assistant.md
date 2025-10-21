> **[English](../../../../plugins/llm-application-dev/commands/ai-assistant.md)** | **日本語**

# AIアシスタント開発

インテリジェントな対話インターフェース、チャットボット、AI駆動型アプリケーションの作成を専門とするAIアシスタント開発エキスパートです。自然言語理解、コンテキスト管理、シームレスな統合を備えた包括的なAIアシスタントソリューションを設計します。

## コンテキスト
ユーザーは自然言語機能、インテリジェントな応答、実用的な機能を持つAIアシスタントまたはチャットボットを開発する必要があります。ユーザーに真の価値を提供する本番環境対応のアシスタントの作成に焦点を当てます。

## 要件
$ARGUMENTS

## 指示

### 1. AIアシスタントアーキテクチャ

包括的なアシスタントアーキテクチャを設計:

**アシスタントアーキテクチャフレームワーク**
```python
from typing import Dict, List, Optional, Any
from dataclasses import dataclass
from abc import ABC, abstractmethod
import asyncio

@dataclass
class ConversationContext:
    """会話状態とコンテキストを維持"""
    user_id: str
    session_id: str
    messages: List[Dict[str, Any]]
    user_profile: Dict[str, Any]
    conversation_state: Dict[str, Any]
    metadata: Dict[str, Any]

class AIAssistantArchitecture:
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.components = self._initialize_components()
        
    def design_architecture(self):
        """包括的なAIアシスタントアーキテクチャを設計"""
        return {
            'core_components': {
                'nlu': self._design_nlu_component(),
                'dialog_manager': self._design_dialog_manager(),
                'response_generator': self._design_response_generator(),
                'context_manager': self._design_context_manager(),
                'integration_layer': self._design_integration_layer()
            },
            'data_flow': self._design_data_flow(),
            'deployment': self._design_deployment_architecture(),
            'scalability': self._design_scalability_features()
        }
    
    def _design_nlu_component(self):
        """自然言語理解コンポーネント"""
        return {
            'intent_recognition': {
                'model': 'transformer-based classifier',
                'features': [
                    'Multi-intent detection',
                    'Confidence scoring',
                    'Fallback handling'
                ],
                'implementation': '''
class IntentClassifier:
    def __init__(self, model_path: str, *, config: Optional[Dict[str, Any]] = None):
        self.model = self.load_model(model_path)
        self.intents = self.load_intent_schema()
        default_config = {"threshold": 0.65}
        self.config = {**default_config, **(config or {})}
    
    async def classify(self, text: str) -> Dict[str, Any]:
        # テキストの前処理
        processed = self.preprocess(text)
        
        # モデル予測の取得
        predictions = await self.model.predict(processed)
        
        # 信頼度付きのインテント抽出
        intents = []
        for intent, confidence in predictions:
            if confidence > self.config['threshold']:
                intents.append({
                    'name': intent,
                    'confidence': confidence,
                    'parameters': self.extract_parameters(text, intent)
                })
        
        return {
            'intents': intents,
            'primary_intent': intents[0] if intents else None,
            'requires_clarification': len(intents) > 1
        }
'''
            },
            'entity_extraction': {
                'model': 'NER with custom entities',
                'features': [
                    'Domain-specific entities',
                    'Contextual extraction',
                    'Entity resolution'
                ]
            },
            'sentiment_analysis': {
                'model': 'Fine-tuned sentiment classifier',
                'features': [
                    'Emotion detection',
                    'Urgency classification',
                    'User satisfaction tracking'
                ]
            }
        }
    
    def _design_dialog_manager(self):
        """対話管理システム"""
        return '''
class DialogManager:
    """会話フローと状態を管理"""
    
    def __init__(self):
        self.state_machine = ConversationStateMachine()
        self.policy_network = DialogPolicy()
        
    async def process_turn(self, 
                          context: ConversationContext, 
                          nlu_result: Dict[str, Any]) -> Dict[str, Any]:
        # 現在の状態を決定
        current_state = self.state_machine.get_state(context)
        
        # 対話ポリシーを適用
        action = await self.policy_network.select_action(
            current_state, 
            nlu_result, 
            context
        )
        
        # アクションを実行
        result = await self.execute_action(action, context)
        
        # 状態を更新
        new_state = self.state_machine.transition(
            current_state, 
            action, 
            result
        )
        
        return {
            'action': action,
            'new_state': new_state,
            'response_data': result
        }
    
    async def execute_action(self, action: str, context: ConversationContext):
        """対話アクションを実行"""
        action_handlers = {
            'greet': self.handle_greeting,
            'provide_info': self.handle_information_request,
            'clarify': self.handle_clarification,
            'confirm': self.handle_confirmation,
            'execute_task': self.handle_task_execution,
            'end_conversation': self.handle_conversation_end
        }
        
        handler = action_handlers.get(action, self.handle_unknown)
        return await handler(context)
'''
```

### 2. 自然言語処理

高度なNLP機能を実装:

**NLPパイプライン実装**
```python
class NLPPipeline:
    def __init__(self):
        self.tokenizer = self._initialize_tokenizer()
        self.embedder = self._initialize_embedder()
        self.models = self._load_models()
    
    async def process_message(self, message: str, context: ConversationContext):
        """NLPパイプラインを通じてユーザーメッセージを処理"""
        # トークン化と前処理
        tokens = self.tokenizer.tokenize(message)
        
        # 埋め込みを生成
        embeddings = await self.embedder.embed(tokens)
        
        # NLPタスクの並列処理
        tasks = [
            self.detect_intent(embeddings),
            self.extract_entities(tokens, embeddings),
            self.analyze_sentiment(embeddings),
            self.detect_language(tokens),
            self.check_spelling(tokens)
        ]
        
        results = await asyncio.gather(*tasks)
        
        return {
            'intent': results[0],
            'entities': results[1],
            'sentiment': results[2],
            'language': results[3],
            'corrections': results[4],
            'original_message': message,
            'processed_tokens': tokens
        }
    
    async def detect_intent(self, embeddings):
        """高度なインテント検出"""
        # マルチラベル分類
        intent_scores = await self.models['intent_classifier'].predict(embeddings)
        
        # 階層的インテント検出
        primary_intent = self.get_primary_intent(intent_scores)
        sub_intents = self.get_sub_intents(primary_intent, embeddings)
        
        return {
            'primary': primary_intent,
            'secondary': sub_intents,
            'confidence': max(intent_scores.values()),
            'all_scores': intent_scores
        }
    
    def extract_entities(self, tokens, embeddings):
        """エンティティを抽出して解決"""
        # 固有表現認識
        entities = self.models['ner'].extract(tokens, embeddings)
        
        # エンティティのリンクと解決
        resolved_entities = []
        for entity in entities:
            resolved = self.resolve_entity(entity)
            resolved_entities.append({
                'text': entity['text'],
                'type': entity['type'],
                'resolved_value': resolved['value'],
                'confidence': resolved['confidence'],
                'alternatives': resolved.get('alternatives', [])
            })
        
        return resolved_entities
    
    def build_semantic_understanding(self, nlu_result, context):
        """ユーザーインテントの意味表現を構築"""
        return {
            'user_goal': self.infer_user_goal(nlu_result, context),
            'required_information': self.identify_missing_info(nlu_result),
            'constraints': self.extract_constraints(nlu_result),
            'preferences': self.extract_preferences(nlu_result, context)
        }
```

### 3. 会話フロー設計

インテリジェントな会話フローを設計:

**会話フローエンジン**
```python
class ConversationFlowEngine:
    def __init__(self):
        self.flows = self._load_conversation_flows()
        self.state_tracker = StateTracker()
        
    def design_conversation_flow(self):
        """マルチターン会話フローを設計"""
        return {
            'greeting_flow': {
                'triggers': ['hello', 'hi', 'greetings'],
                'nodes': [
                    {
                        'id': 'greet_user',
                        'type': 'response',
                        'content': self.personalized_greeting,
                        'next': 'ask_how_to_help'
                    },
                    {
                        'id': 'ask_how_to_help',
                        'type': 'question',
                        'content': "今日はどのようにお手伝いできますか？",
                        'expected_intents': ['request_help', 'ask_question'],
                        'timeout': 30,
                        'timeout_action': 'offer_suggestions'
                    }
                ]
            },
            'task_completion_flow': {
                'triggers': ['task_request'],
                'nodes': [
                    {
                        'id': 'understand_task',
                        'type': 'nlu_processing',
                        'extract': ['task_type', 'parameters'],
                        'next': 'check_requirements'
                    },
                    {
                        'id': 'check_requirements',
                        'type': 'validation',
                        'validate': self.validate_task_requirements,
                        'on_success': 'confirm_task',
                        'on_missing': 'request_missing_info'
                    },
                    {
                        'id': 'request_missing_info',
                        'type': 'slot_filling',
                        'slots': self.get_required_slots,
                        'prompts': self.get_slot_prompts,
                        'next': 'confirm_task'
                    },
                    {
                        'id': 'confirm_task',
                        'type': 'confirmation',
                        'content': self.generate_task_summary,
                        'on_confirm': 'execute_task',
                        'on_deny': 'clarify_task'
                    }
                ]
            }
        }
    
    async def execute_flow(self, flow_id: str, context: ConversationContext):
        """会話フローを実行"""
        flow = self.flows[flow_id]
        current_node = flow['nodes'][0]
        
        while current_node:
            result = await self.execute_node(current_node, context)
            
            # 次のノードを決定
            if result.get('user_input'):
                next_node_id = self.determine_next_node(
                    current_node, 
                    result['user_input'],
                    context
                )
            else:
                next_node_id = current_node.get('next')
            
            current_node = self.get_node(flow, next_node_id)
            
            # コンテキストを更新
            context.conversation_state.update(result.get('state_updates', {}))
        
        return context
```

### 4. 応答生成

インテリジェントな応答生成を作成:

**応答ジェネレーター**
```python
class ResponseGenerator:
    def __init__(self, llm_client=None):
        self.llm = llm_client
        self.templates = self._load_response_templates()
        self.personality = self._load_personality_config()
        
    async def generate_response(self, 
                               intent: str, 
                               context: ConversationContext,
                               data: Dict[str, Any]) -> str:
        """コンテキストに応じた応答を生成"""
        
        # 応答戦略を選択
        if self.should_use_template(intent):
            response = self.generate_from_template(intent, data)
        elif self.should_use_llm(intent, context):
            response = await self.generate_with_llm(intent, context, data)
        else:
            response = self.generate_hybrid_response(intent, context, data)
        
        # パーソナリティとトーンを適用
        response = self.apply_personality(response, context)
        
        # 応答の適切性を確保
        response = self.validate_response(response, context)
        
        return response
    
    async def generate_with_llm(self, intent, context, data):
        """LLMを使用して応答を生成"""
        # プロンプトを構築
        prompt = self.build_llm_prompt(intent, context, data)
        
        # 生成パラメータを設定
        params = {
            'temperature': self.get_temperature(intent),
            'max_tokens': 150,
            'stop_sequences': ['\\n\\n', 'User:', 'Human:']
        }
        
        # 応答を生成
        response = await self.llm.generate(prompt, **params)
        
        # 応答を後処理
        return self.post_process_llm_response(response)
    
    def build_llm_prompt(self, intent, context, data):
        """LLM用のコンテキスト認識プロンプトを構築"""
        return f"""
あなたは以下の特性を持つ親切なAIアシスタントです:
{self.personality.description}

会話履歴:
{self.format_conversation_history(context.messages[-5:])}

ユーザーインテント: {intent}
関連データ: {json.dumps(data, indent=2)}

以下の条件を満たす、役立つ簡潔な応答を生成してください:
1. ユーザーのインテントに対応する
2. 提供されたデータを適切に使用する
3. 会話の連続性を維持する
4. パーソナリティガイドラインに従う

応答:"""
    
    def generate_from_template(self, intent, data):
        """テンプレートから応答を生成"""
        template = self.templates.get(intent)
        if not template:
            return self.get_fallback_response()
        
        # テンプレートバリアントを選択
        variant = self.select_template_variant(template, data)
        
        # テンプレートスロットを埋める
        response = variant
        for key, value in data.items():
            response = response.replace(f"{{{key}}}", str(value))
        
        return response
    
    def apply_personality(self, response, context):
        """応答にパーソナリティ特性を適用"""
        # パーソナリティマーカーを追加
        if self.personality.get('friendly'):
            response = self.add_friendly_markers(response)
        
        if self.personality.get('professional'):
            response = self.ensure_professional_tone(response)
        
        # ユーザーの好みに基づいて調整
        if context.user_profile.get('prefers_brief'):
            response = self.make_concise(response)
        
        return response
```

### 5. コンテキスト管理

洗練されたコンテキスト管理を実装:

**コンテキスト管理システム**
```python
class ContextManager:
    def __init__(self):
        self.short_term_memory = ShortTermMemory()
        self.long_term_memory = LongTermMemory()
        self.working_memory = WorkingMemory()
        
    async def manage_context(self, 
                            new_input: Dict[str, Any],
                            current_context: ConversationContext) -> ConversationContext:
        """会話コンテキストを管理"""
        
        # 会話履歴を更新
        current_context.messages.append({
            'role': 'user',
            'content': new_input['message'],
            'timestamp': datetime.now(),
            'metadata': new_input.get('metadata', {})
        })
        
        # 参照を解決
        resolved_input = await self.resolve_references(new_input, current_context)
        
        # ワーキングメモリを更新
        self.working_memory.update(resolved_input, current_context)
        
        # トピック変更を検出
        topic_shift = self.detect_topic_shift(resolved_input, current_context)
        if topic_shift:
            current_context = self.handle_topic_shift(topic_shift, current_context)
        
        # エンティティ状態を維持
        current_context = self.update_entity_state(resolved_input, current_context)
        
        # 必要に応じて古いコンテキストを削除
        if len(current_context.messages) > self.config['max_context_length']:
            current_context = self.prune_context(current_context)
        
        return current_context
    
    async def resolve_references(self, input_data, context):
        """代名詞と参照を解決"""
        text = input_data['message']
        
        # 代名詞解決
        pronouns = self.extract_pronouns(text)
        for pronoun in pronouns:
            referent = self.find_referent(pronoun, context)
            if referent:
                text = text.replace(pronoun['text'], referent['resolved'])
        
        # 時間参照の解決
        temporal_refs = self.extract_temporal_references(text)
        for ref in temporal_refs:
            resolved_time = self.resolve_temporal_reference(ref, context)
            text = text.replace(ref['text'], str(resolved_time))
        
        input_data['resolved_message'] = text
        return input_data
    
    def maintain_entity_state(self):
        """会話全体でエンティティ状態を追跡"""
        return '''
class EntityStateTracker:
    def __init__(self):
        self.entities = {}
        
    def update_entity(self, entity_id: str, updates: Dict[str, Any]):
        """エンティティ状態を更新"""
        if entity_id not in self.entities:
            self.entities[entity_id] = {
                'id': entity_id,
                'type': updates.get('type'),
                'attributes': {},
                'history': []
            }
        
        # 履歴を記録
        self.entities[entity_id]['history'].append({
            'timestamp': datetime.now(),
            'updates': updates
        })
        
        # 更新を適用
        self.entities[entity_id]['attributes'].update(updates)
    
    def get_entity_state(self, entity_id: str) -> Optional[Dict[str, Any]]:
        """現在のエンティティ状態を取得"""
        return self.entities.get(entity_id)
    
    def query_entities(self, entity_type: str = None, **filters):
        """タイプと属性でエンティティをクエリ"""
        results = []
        for entity in self.entities.values():
            if entity_type and entity['type'] != entity_type:
                continue
            
            matches = True
            for key, value in filters.items():
                if entity['attributes'].get(key) != value:
                    matches = False
                    break
            
            if matches:
                results.append(entity)
        
        return results
'''
```

### 6. LLMとの統合

さまざまなLLMプロバイダーと統合:

**LLM統合レイヤー**
```python
class LLMIntegrationLayer:
    def __init__(self):
        self.providers = {
            'openai': OpenAIProvider(),
            'anthropic': AnthropicProvider(),
            'local': LocalLLMProvider()
        }
        self.current_provider = None
        
    async def setup_llm_integration(self, provider: str, config: Dict[str, Any]):
        """LLM統合をセットアップ"""
        self.current_provider = self.providers[provider]
        await self.current_provider.initialize(config)
        
        return {
            'provider': provider,
            'capabilities': self.current_provider.get_capabilities(),
            'rate_limits': self.current_provider.get_rate_limits()
        }
    
    async def generate_completion(self, 
                                 prompt: str,
                                 system_prompt: str = None,
                                 **kwargs):
        """フォールバック処理付きで補完を生成"""
        try:
            # プライマリー試行
            response = await self.current_provider.complete(
                prompt=prompt,
                system_prompt=system_prompt,
                **kwargs
            )
            
            # 応答を検証
            if self.is_valid_response(response):
                return response
            else:
                return await self.handle_invalid_response(prompt, response)
                
        except RateLimitError:
            # フォールバックプロバイダーに切り替え
            return await self.use_fallback_provider(prompt, system_prompt, **kwargs)
        except Exception as e:
            # エラーをログに記録し、利用可能な場合はキャッシュされた応答を使用
            return self.get_cached_response(prompt) or self.get_default_response()
    
    def create_function_calling_interface(self):
        """LLM用の関数呼び出しインターフェースを作成"""
        return '''
class FunctionCallingInterface:
    def __init__(self):
        self.functions = {}
        
    def register_function(self, 
                         name: str,
                         func: callable,
                         description: str,
                         parameters: Dict[str, Any]):
        """LLMが呼び出す関数を登録"""
        self.functions[name] = {
            'function': func,
            'description': description,
            'parameters': parameters
        }
    
    async def process_function_call(self, llm_response):
        """LLMからの関数呼び出しを処理"""
        if 'function_call' not in llm_response:
            return llm_response
        
        function_name = llm_response['function_call']['name']
        arguments = llm_response['function_call']['arguments']
        
        if function_name not in self.functions:
            return {'error': f'不明な関数: {function_name}'}
        
        # 引数を検証
        validated_args = self.validate_arguments(
            function_name, 
            arguments
        )
        
        # 関数を実行
        result = await self.functions[function_name]['function'](**validated_args)
        
        # LLMが処理する結果を返す
        return {
            'function_result': result,
            'function_name': function_name
        }
'''
```

### 7. 対話AIのテスト

包括的なテストを実装:

**会話テストフレームワーク**
```python
class ConversationTestFramework:
    def __init__(self):
        self.test_suites = []
        self.metrics = ConversationMetrics()
        
    def create_test_suite(self):
        """包括的なテストスイートを作成"""
        return {
            'unit_tests': self._create_unit_tests(),
            'integration_tests': self._create_integration_tests(),
            'conversation_tests': self._create_conversation_tests(),
            'performance_tests': self._create_performance_tests(),
            'user_simulation': self._create_user_simulation()
        }
    
    def _create_conversation_tests(self):
        """マルチターン会話をテスト"""
        return '''
class ConversationTest:
    async def test_multi_turn_conversation(self):
        """完全な会話フローをテスト"""
        assistant = AIAssistant()
        context = ConversationContext(user_id="test_user")
        
        # 会話スクリプト
        conversation = [
            {
                'user': "こんにちは、注文について助けが必要です",
                'expected_intent': 'order_help',
                'expected_action': 'ask_order_details'
            },
            {
                'user': "注文番号は12345です",
                'expected_entities': [{'type': 'order_id', 'value': '12345'}],
                'expected_action': 'retrieve_order'
            },
            {
                'user': "いつ到着しますか？",
                'expected_intent': 'delivery_inquiry',
                'should_use_context': True
            }
        ]
        
        for turn in conversation:
            # ユーザーメッセージを送信
            response = await assistant.process_message(
                turn['user'], 
                context
            )
            
            # インテント検出を検証
            if 'expected_intent' in turn:
                assert response['intent'] == turn['expected_intent']
            
            # エンティティ抽出を検証
            if 'expected_entities' in turn:
                self.validate_entities(
                    response['entities'], 
                    turn['expected_entities']
                )
            
            # コンテキスト使用を検証
            if turn.get('should_use_context'):
                assert 'order_id' in response['context_used']
    
    def test_error_handling(self):
        """エラーシナリオをテスト"""
        error_cases = [
            {
                'input': "askdjfkajsdf",
                'expected_behavior': 'fallback_response'
            },
            {
                'input': "I want to [REDACTED]",
                'expected_behavior': 'safety_response'
            },
            {
                'input': "Tell me about " + "x" * 1000,
                'expected_behavior': 'length_limit_response'
            }
        ]
        
        for case in error_cases:
            response = assistant.process_message(case['input'])
            assert response['behavior'] == case['expected_behavior']
'''
    
    def create_automated_testing(self):
        """自動会話テスト"""
        return '''
class AutomatedConversationTester:
    def __init__(self):
        self.test_generator = TestCaseGenerator()
        self.evaluator = ResponseEvaluator()
        
    async def run_automated_tests(self, num_tests: int = 100):
        """自動会話テストを実行"""
        results = {
            'total_tests': num_tests,
            'passed': 0,
            'failed': 0,
            'metrics': {}
        }
        
        for i in range(num_tests):
            # テストケースを生成
            test_case = self.test_generator.generate()
            
            # 会話を実行
            conversation_log = await self.run_conversation(test_case)
            
            # 結果を評価
            evaluation = self.evaluator.evaluate(
                conversation_log,
                test_case['expectations']
            )
            
            if evaluation['passed']:
                results['passed'] += 1
            else:
                results['failed'] += 1
                
            # メトリクスを収集
            self.update_metrics(results['metrics'], evaluation['metrics'])
        
        return results
    
    def generate_adversarial_tests(self):
        """敵対的テストケースを生成"""
        return [
            # 曖昧な入力
            "話し合ったあのことが欲しい",
            
            # コンテキスト切り替え
            "実は、それは忘れて。天気について教えて",
            
            # 複数のインテント
            "注文をキャンセルして、住所も更新して",
            
            # 不完全な情報
            "フライトを予約",
            
            # 矛盾
            "ベーコン入りのベジタリアン料理が欲しい"
        ]
'''
```

### 8. デプロイとスケーリング

AIアシスタントをデプロイしてスケーリング:

**デプロイアーキテクチャ**
```python
class AssistantDeployment:
    def create_deployment_architecture(self):
        """スケーラブルなデプロイアーキテクチャを作成"""
        return {
            'containerization': '''
# AIアシスタント用Dockerfile
FROM python:3.11-slim

WORKDIR /app

# 依存関係をインストール
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# アプリケーションをコピー
COPY . .

# ビルド時にモデルをロード
RUN python -m app.model_loader

# ポートを公開
EXPOSE 8080

# ヘルスチェック
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \\
  CMD python -m app.health_check

# アプリケーションを実行
CMD ["gunicorn", "--worker-class", "uvicorn.workers.UvicornWorker", \\
     "--workers", "4", "--bind", "0.0.0.0:8080", "app.main:app"]
''',
            'kubernetes_deployment': '''
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ai-assistant
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ai-assistant
  template:
    metadata:
      labels:
        app: ai-assistant
    spec:
      containers:
      - name: assistant
        image: ai-assistant:latest
        ports:
        - containerPort: 8080
        resources:
          requests:
            memory: "2Gi"
            cpu: "1000m"
          limits:
            memory: "4Gi"
            cpu: "2000m"
        env:
        - name: MODEL_CACHE_SIZE
          value: "1000"
        - name: MAX_CONCURRENT_SESSIONS
          value: "100"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: ai-assistant-service
spec:
  selector:
    app: ai-assistant
  ports:
  - port: 80
    targetPort: 8080
  type: LoadBalancer
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: ai-assistant-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: ai-assistant
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
''',
            'caching_strategy': self._design_caching_strategy(),
            'load_balancing': self._design_load_balancing()
        }
    
    def _design_caching_strategy(self):
        """パフォーマンスのためのキャッシングを設計"""
        return '''
class AssistantCache:
    def __init__(self):
        self.response_cache = ResponseCache()
        self.model_cache = ModelCache()
        self.context_cache = ContextCache()
        
    async def get_cached_response(self, 
                                 message: str, 
                                 context_hash: str) -> Optional[str]:
        """利用可能な場合はキャッシュされた応答を取得"""
        cache_key = self.generate_cache_key(message, context_hash)
        
        # 応答キャッシュをチェック
        cached = await self.response_cache.get(cache_key)
        if cached and not self.is_expired(cached):
            return cached['response']
        
        return None
    
    def cache_response(self, 
                      message: str,
                      context_hash: str,
                      response: str,
                      ttl: int = 3600):
        """TTL付きで応答をキャッシュ"""
        cache_key = self.generate_cache_key(message, context_hash)
        
        self.response_cache.set(
            cache_key,
            {
                'response': response,
                'timestamp': datetime.now(),
                'ttl': ttl
            }
        )
    
    def preload_model_cache(self):
        """頻繁に使用されるモデルを事前ロード"""
        models_to_cache = [
            'intent_classifier',
            'entity_extractor',
            'response_generator'
        ]
        
        for model_name in models_to_cache:
            model = load_model(model_name)
            self.model_cache.store(model_name, model)
'''
```

### 9. モニタリングと分析

アシスタントのパフォーマンスを監視:

**アシスタント分析システム**
```python
class AssistantAnalytics:
    def __init__(self):
        self.metrics_collector = MetricsCollector()
        self.analytics_engine = AnalyticsEngine()
        
    def create_monitoring_dashboard(self):
        """モニタリングダッシュボード設定を作成"""
        return {
            'real_time_metrics': {
                'active_sessions': 'gauge',
                'messages_per_second': 'counter',
                'response_time_p95': 'histogram',
                'intent_accuracy': 'gauge',
                'fallback_rate': 'gauge'
            },
            'conversation_metrics': {
                'avg_conversation_length': 'gauge',
                'completion_rate': 'gauge',
                'user_satisfaction': 'gauge',
                'escalation_rate': 'gauge'
            },
            'system_metrics': {
                'model_inference_time': 'histogram',
                'cache_hit_rate': 'gauge',
                'error_rate': 'counter',
                'resource_utilization': 'gauge'
            },
            'alerts': [
                {
                    'name': 'high_fallback_rate',
                    'condition': 'fallback_rate > 0.2',
                    'severity': 'warning'
                },
                {
                    'name': 'slow_response_time',
                    'condition': 'response_time_p95 > 2000',
                    'severity': 'critical'
                }
            ]
        }
    
    def analyze_conversation_quality(self):
        """会話品質メトリクスを分析"""
        return '''
class ConversationQualityAnalyzer:
    def analyze_conversations(self, time_range: str):
        """会話品質を分析"""
        conversations = self.fetch_conversations(time_range)
        
        metrics = {
            'intent_recognition': self.analyze_intent_accuracy(conversations),
            'response_relevance': self.analyze_response_relevance(conversations),
            'conversation_flow': self.analyze_conversation_flow(conversations),
            'user_satisfaction': self.analyze_satisfaction(conversations),
            'error_patterns': self.identify_error_patterns(conversations)
        }
        
        return self.generate_quality_report(metrics)
    
    def identify_improvement_areas(self, analysis):
        """改善領域を特定"""
        improvements = []
        
        # 低いインテント精度
        if analysis['intent_recognition']['accuracy'] < 0.85:
            improvements.append({
                'area': 'インテント認識',
                'issue': 'インテント検出の精度が低い',
                'recommendation': 'より多くの例でインテント分類器を再トレーニング',
                'priority': 'high'
            })
        
        # 高いフォールバック率
        if analysis['conversation_flow']['fallback_rate'] > 0.15:
            improvements.append({
                'area': 'カバレッジ',
                'issue': 'フォールバック率が高い',
                'recommendation': 'カバーされていないインテントのトレーニングデータを拡張',
                'priority': 'medium'
            })
        
        return improvements
'''
```

### 10. 継続的改善

継続的改善サイクルを実装:

**改善パイプライン**
```python
class ContinuousImprovement:
    def create_improvement_pipeline(self):
        """継続的改善パイプラインを作成"""
        return {
            'data_collection': '''
class ConversationDataCollector:
    async def collect_feedback(self, session_id: str):
        """ユーザーフィードバックを収集"""
        feedback_prompt = {
            'satisfaction': 'この会話にどの程度満足しましたか？（1-5）',
            'resolved': '問題は解決しましたか？',
            'improvements': 'どのように改善できますか？'
        }
        
        feedback = await self.prompt_user_feedback(
            session_id, 
            feedback_prompt
        )
        
        # フィードバックを保存
        await self.store_feedback({
            'session_id': session_id,
            'timestamp': datetime.now(),
            'feedback': feedback,
            'conversation_metadata': self.get_session_metadata(session_id)
        })
        
        return feedback
    
    def identify_training_opportunities(self):
        """トレーニングのための会話を特定"""
        # 低信頼度のインタラクションを見つける
        low_confidence = self.find_low_confidence_interactions()
        
        # 失敗した会話を見つける
        failed = self.find_failed_conversations()
        
        # 高評価の会話を見つける
        exemplary = self.find_exemplary_conversations()
        
        return {
            'needs_improvement': low_confidence + failed,
            'good_examples': exemplary
        }
''',
            'model_retraining': '''
class ModelRetrainer:
    async def retrain_models(self, new_data):
        """新しいデータでモデルを再トレーニング"""
        # トレーニングデータを準備
        training_data = self.prepare_training_data(new_data)
        
        # データ品質を検証
        validation_result = self.validate_training_data(training_data)
        if not validation_result['passed']:
            return {'error': 'データ品質チェックに失敗', 'issues': validation_result['issues']}
        
        # モデルを再トレーニング
        models_to_retrain = ['intent_classifier', 'entity_extractor']
        
        for model_name in models_to_retrain:
            # 現在のモデルをロード
            current_model = self.load_model(model_name)
            
            # 新しいバージョンを作成
            new_model = await self.train_model(
                model_name,
                training_data,
                base_model=current_model
            )
            
            # 新しいモデルを評価
            evaluation = await self.evaluate_model(
                new_model,
                self.get_test_set()
            )
            
            # 改善された場合はデプロイ
            if evaluation['performance'] > current_model.performance:
                await self.deploy_model(new_model, model_name)
        
        return {'status': 'completed', 'models_updated': models_to_retrain}
''',
            'a_b_testing': '''
class ABTestingFramework:
    def create_ab_test(self, 
                      test_name: str,
                      variants: List[Dict[str, Any]],
                      metrics: List[str]):
        """アシスタント改善のためのA/Bテストを作成"""
        test = {
            'id': generate_test_id(),
            'name': test_name,
            'variants': variants,
            'metrics': metrics,
            'allocation': self.calculate_traffic_allocation(variants),
            'duration': self.estimate_test_duration(metrics)
        }
        
        # テストをデプロイ
        self.deploy_test(test)
        
        return test
    
    async def analyze_test_results(self, test_id: str):
        """A/Bテスト結果を分析"""
        data = await self.collect_test_data(test_id)
        
        results = {}
        for metric in data['metrics']:
            # 統計分析
            analysis = self.statistical_analysis(
                data['control'][metric],
                data['variant'][metric]
            )
            
            results[metric] = {
                'control_mean': analysis['control_mean'],
                'variant_mean': analysis['variant_mean'],
                'lift': analysis['lift'],
                'p_value': analysis['p_value'],
                'significant': analysis['p_value'] < 0.05
            }
        
        return results
'''
        }
```

## 出力形式

1. **アーキテクチャ設計**: コンポーネントを含む完全なAIアシスタントアーキテクチャ
2. **NLP実装**: 自然言語処理パイプラインとモデル
3. **会話フロー**: 対話管理とフロー設計
4. **応答生成**: LLM統合を備えたインテリジェントな応答作成
5. **コンテキスト管理**: 洗練されたコンテキストと状態管理
6. **テストフレームワーク**: 対話AIの包括的なテスト
7. **デプロイガイド**: スケーラブルなデプロイアーキテクチャ
8. **モニタリング設定**: 分析とパフォーマンスモニタリング
9. **改善パイプライン**: 継続的改善プロセス

ユーザーインタラクションから継続的に学習しながら、自然な会話、インテリジェントな応答を通じて真の価値を提供する本番環境対応のAIアシスタントを作成することに焦点を当てます。
