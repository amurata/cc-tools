# APIモッキングフレームワーク

> **[English](../../../plugins/api-testing-observability/commands/api-mock.md)** | **日本語**

あなたは、開発、テスト、デモンストレーション目的でリアルなモックサービスを作成することを専門とするAPIモッキングエキスパートです。実際のAPI動作をシミュレートし、並行開発を可能にし、徹底的なテストを促進する包括的なモッキングソリューションを設計します。

## コンテキスト
ユーザーは開発、テスト、またはデモンストレーション目的でモックAPIを作成する必要があります。本番API動作を正確にシミュレートし、効率的な開発ワークフローを可能にする、柔軟でリアルなモックの作成に焦点を当てます。

## 要件
$ARGUMENTS

## 指示

### 1. モックサーバーのセットアップ

包括的なモックサーバーインフラストラクチャを作成:

**モックサーバーフレームワーク**
```python
from typing import Dict, List, Any, Optional
import json
import asyncio
from datetime import datetime
from fastapi import FastAPI, Request, Response
import uvicorn

class MockAPIServer:
    def __init__(self, config: Dict[str, Any]):
        self.app = FastAPI(title="Mock API Server")
        self.routes = {}
        self.middleware = []
        self.state_manager = StateManager()
        self.scenario_manager = ScenarioManager()

    def setup_mock_server(self):
        """包括的なモックサーバーをセットアップ"""
        # ミドルウェアを設定
        self._setup_middleware()

        # モック定義をロード
        self._load_mock_definitions()

        # 動的ルートをセットアップ
        self._setup_dynamic_routes()

        # シナリオを初期化
        self._initialize_scenarios()

        return self.app

    def _setup_middleware(self):
        """サーバーミドルウェアを設定"""
        @self.app.middleware("http")
        async def add_mock_headers(request: Request, call_next):
            response = await call_next(request)
            response.headers["X-Mock-Server"] = "true"
            response.headers["X-Mock-Scenario"] = self.scenario_manager.current_scenario
            return response

        @self.app.middleware("http")
        async def simulate_latency(request: Request, call_next):
            # ネットワークレイテンシをシミュレート
            latency = self._calculate_latency(request.url.path)
            await asyncio.sleep(latency / 1000)  # 秒に変換
            response = await call_next(request)
            return response

        @self.app.middleware("http")
        async def track_requests(request: Request, call_next):
            # 検証のためリクエストを追跡
            self.state_manager.track_request({
                'method': request.method,
                'path': str(request.url.path),
                'headers': dict(request.headers),
                'timestamp': datetime.now()
            })
            response = await call_next(request)
            return response

    def _setup_dynamic_routes(self):
        """動的ルート処理をセットアップ"""
        @self.app.api_route("/{path:path}", methods=["GET", "POST", "PUT", "DELETE", "PATCH"])
        async def handle_mock_request(path: str, request: Request):
            # マッチするモックを検索
            mock = self._find_matching_mock(request.method, path, request)

            if not mock:
                return Response(
                    content=json.dumps({"error": "No mock found for this endpoint"}),
                    status_code=404,
                    media_type="application/json"
                )

            # モックレスポンスを処理
            response_data = await self._process_mock_response(mock, request)

            return Response(
                content=json.dumps(response_data['body']),
                status_code=response_data['status'],
                headers=response_data['headers'],
                media_type="application/json"
            )

    async def _process_mock_response(self, mock: Dict[str, Any], request: Request):
        """モックレスポンスを処理して生成"""
        # 条件付きレスポンスをチェック
        if mock.get('conditions'):
            for condition in mock['conditions']:
                if self._evaluate_condition(condition, request):
                    return await self._generate_response(condition['response'], request)

        # デフォルトレスポンスを使用
        return await self._generate_response(mock['response'], request)

    def _generate_response(self, response_template: Dict[str, Any], request: Request):
        """テンプレートからレスポンスを生成"""
        response = {
            'status': response_template.get('status', 200),
            'headers': response_template.get('headers', {}),
            'body': self._process_response_body(response_template['body'], request)
        }

        # レスポンス変換を適用
        if response_template.get('transformations'):
            response = self._apply_transformations(response, response_template['transformations'])

        return response
```

### 2. リクエスト/レスポンススタビング

柔軟なスタビングシステムを実装:

**スタビングエンジン**
```python
class StubbingEngine:
    def __init__(self):
        self.stubs = {}
        self.matchers = self._initialize_matchers()

    def create_stub(self, method: str, path: str, **kwargs):
        """新しいスタブを作成"""
        stub_id = self._generate_stub_id()

        stub = {
            'id': stub_id,
            'method': method,
            'path': path,
            'matchers': self._build_matchers(kwargs),
            'response': kwargs.get('response', {}),
            'priority': kwargs.get('priority', 0),
            'times': kwargs.get('times', -1),  # -1は無制限
            'delay': kwargs.get('delay', 0),
            'scenario': kwargs.get('scenario', 'default')
        }

        self.stubs[stub_id] = stub
        return stub_id

    def _build_matchers(self, kwargs):
        """リクエストマッチャーを構築"""
        matchers = []

        # パスパラメータマッチング
        if 'path_params' in kwargs:
            matchers.append({
                'type': 'path_params',
                'params': kwargs['path_params']
            })

        # クエリパラメータマッチング
        if 'query_params' in kwargs:
            matchers.append({
                'type': 'query_params',
                'params': kwargs['query_params']
            })

        # ヘッダーマッチング
        if 'headers' in kwargs:
            matchers.append({
                'type': 'headers',
                'headers': kwargs['headers']
            })

        # ボディマッチング
        if 'body' in kwargs:
            matchers.append({
                'type': 'body',
                'body': kwargs['body'],
                'match_type': kwargs.get('body_match_type', 'exact')
            })

        return matchers

    def match_request(self, request: Dict[str, Any]):
        """リクエストに一致するスタブを検索"""
        candidates = []

        for stub in self.stubs.values():
            if self._matches_stub(request, stub):
                candidates.append(stub)

        # 優先度でソートしてベストマッチを返す
        if candidates:
            return sorted(candidates, key=lambda x: x['priority'], reverse=True)[0]

        return None

    def _matches_stub(self, request: Dict[str, Any], stub: Dict[str, Any]):
        """リクエストがスタブに一致するかチェック"""
        # メソッドをチェック
        if request['method'] != stub['method']:
            return False

        # パスをチェック
        if not self._matches_path(request['path'], stub['path']):
            return False

        # すべてのマッチャーをチェック
        for matcher in stub['matchers']:
            if not self._evaluate_matcher(request, matcher):
                return False

        # スタブがまだ有効かチェック
        if stub['times'] == 0:
            return False

        return True

    def create_dynamic_stub(self):
        """コールバック付き動的スタブを作成"""
        return '''
class DynamicStub:
    def __init__(self, path_pattern: str):
        self.path_pattern = path_pattern
        self.response_generator = None
        self.state_modifier = None

    def with_response_generator(self, generator):
        """動的レスポンスジェネレーターを設定"""
        self.response_generator = generator
        return self

    def with_state_modifier(self, modifier):
        """状態変更コールバックを設定"""
        self.state_modifier = modifier
        return self

    async def process_request(self, request: Request, state: Dict[str, Any]):
        """リクエストを動的に処理"""
        # リクエストデータを抽出
        request_data = {
            'method': request.method,
            'path': request.url.path,
            'headers': dict(request.headers),
            'query_params': dict(request.query_params),
            'body': await request.json() if request.method in ['POST', 'PUT'] else None
        }

        # 必要に応じて状態を変更
        if self.state_modifier:
            state = self.state_modifier(state, request_data)

        # レスポンスを生成
        if self.response_generator:
            response = self.response_generator(request_data, state)
        else:
            response = {'status': 200, 'body': {}}

        return response, state

# 使用例
dynamic_stub = DynamicStub('/api/users/{user_id}')
dynamic_stub.with_response_generator(lambda req, state: {
    'status': 200,
    'body': {
        'id': req['path_params']['user_id'],
        'name': state.get('users', {}).get(req['path_params']['user_id'], 'Unknown'),
        'request_count': state.get('request_count', 0)
    }
}).with_state_modifier(lambda state, req: {
    **state,
    'request_count': state.get('request_count', 0) + 1
})
'''
```

### 3. 動的データ生成

リアルなモックデータを生成:

**モックデータジェネレーター**
```python
from faker import Faker
import random
from datetime import datetime, timedelta

class MockDataGenerator:
    def __init__(self):
        self.faker = Faker()
        self.templates = {}
        self.generators = self._init_generators()

    def generate_data(self, schema: Dict[str, Any]):
        """スキーマに基づいてデータを生成"""
        if isinstance(schema, dict):
            if '$ref' in schema:
                # 別のスキーマへの参照
                return self.generate_data(self.resolve_ref(schema['$ref']))

            result = {}
            for key, value in schema.items():
                if key.startswith('$'):
                    continue
                result[key] = self._generate_field(value)
            return result

        elif isinstance(schema, list):
            # 配列を生成
            count = random.randint(1, 10)
            return [self.generate_data(schema[0]) for _ in range(count)]

        else:
            return schema

    def _generate_field(self, field_schema: Dict[str, Any]):
        """スキーマに基づいてフィールド値を生成"""
        field_type = field_schema.get('type', 'string')

        # カスタムジェネレーターをチェック
        if 'generator' in field_schema:
            return self._use_custom_generator(field_schema['generator'])

        # enumをチェック
        if 'enum' in field_schema:
            return random.choice(field_schema['enum'])

        # 型に基づいて生成
        generators = {
            'string': self._generate_string,
            'number': self._generate_number,
            'integer': self._generate_integer,
            'boolean': self._generate_boolean,
            'array': self._generate_array,
            'object': lambda s: self.generate_data(s)
        }

        generator = generators.get(field_type, self._generate_string)
        return generator(field_schema)

    def _generate_string(self, schema: Dict[str, Any]):
        """文字列値を生成"""
        # フォーマットをチェック
        format_type = schema.get('format', '')

        format_generators = {
            'email': self.faker.email,
            'name': self.faker.name,
            'first_name': self.faker.first_name,
            'last_name': self.faker.last_name,
            'phone': self.faker.phone_number,
            'address': self.faker.address,
            'url': self.faker.url,
            'uuid': self.faker.uuid4,
            'date': lambda: self.faker.date().isoformat(),
            'datetime': lambda: self.faker.date_time().isoformat(),
            'password': lambda: self.faker.password()
        }

        if format_type in format_generators:
            return format_generators[format_type]()

        # パターンをチェック
        if 'pattern' in schema:
            return self._generate_from_pattern(schema['pattern'])

        # デフォルトの文字列生成
        min_length = schema.get('minLength', 5)
        max_length = schema.get('maxLength', 20)
        return self.faker.text(max_nb_chars=random.randint(min_length, max_length))

    def create_data_templates(self):
        """再利用可能なデータテンプレートを作成"""
        return {
            'user': {
                'id': {'type': 'string', 'format': 'uuid'},
                'username': {'type': 'string', 'generator': 'username'},
                'email': {'type': 'string', 'format': 'email'},
                'profile': {
                    'type': 'object',
                    'properties': {
                        'firstName': {'type': 'string', 'format': 'first_name'},
                        'lastName': {'type': 'string', 'format': 'last_name'},
                        'avatar': {'type': 'string', 'format': 'url'},
                        'bio': {'type': 'string', 'maxLength': 200}
                    }
                },
                'createdAt': {'type': 'string', 'format': 'datetime'},
                'status': {'type': 'string', 'enum': ['active', 'inactive', 'suspended']}
            },
            'product': {
                'id': {'type': 'string', 'format': 'uuid'},
                'name': {'type': 'string', 'generator': 'product_name'},
                'description': {'type': 'string', 'maxLength': 500},
                'price': {'type': 'number', 'minimum': 0.01, 'maximum': 9999.99},
                'category': {'type': 'string', 'enum': ['electronics', 'clothing', 'food', 'books']},
                'inStock': {'type': 'boolean'},
                'rating': {'type': 'number', 'minimum': 0, 'maximum': 5}
            }
        }

    def generate_relational_data(self):
        """関係性のあるデータを生成"""
        return '''
class RelationalDataGenerator:
    def generate_related_entities(self, schema: Dict[str, Any], count: int):
        """参照整合性を維持しながら関連エンティティを生成"""
        entities = {}

        # 第一パス: プライマリエンティティを生成
        for entity_name, entity_schema in schema['entities'].items():
            entities[entity_name] = []
            for i in range(count):
                entity = self.generate_entity(entity_schema)
                entity['id'] = f"{entity_name}_{i}"
                entities[entity_name].append(entity)

        # 第二パス: 関係を確立
        for relationship in schema.get('relationships', []):
            self.establish_relationship(entities, relationship)

        return entities

    def establish_relationship(self, entities: Dict[str, List], relationship: Dict):
        """エンティティ間の関係を確立"""
        source = relationship['source']
        target = relationship['target']
        rel_type = relationship['type']

        if rel_type == 'one-to-many':
            for source_entity in entities[source['entity']]:
                # ランダムなターゲットを選択
                num_targets = random.randint(1, 5)
                target_refs = random.sample(
                    entities[target['entity']],
                    min(num_targets, len(entities[target['entity']]))
                )
                source_entity[source['field']] = [t['id'] for t in target_refs]

        elif rel_type == 'many-to-one':
            for target_entity in entities[target['entity']]:
                # 1つのソースを選択
                source_ref = random.choice(entities[source['entity']])
                target_entity[target['field']] = source_ref['id']
'''
```

### 4. モックシナリオ

シナリオベースのモッキングを実装:

**シナリオマネージャー**
```python
class ScenarioManager:
    def __init__(self):
        self.scenarios = {}
        self.current_scenario = 'default'
        self.scenario_states = {}

    def define_scenario(self, name: str, definition: Dict[str, Any]):
        """モックシナリオを定義"""
        self.scenarios[name] = {
            'name': name,
            'description': definition.get('description', ''),
            'initial_state': definition.get('initial_state', {}),
            'stubs': definition.get('stubs', []),
            'sequences': definition.get('sequences', []),
            'conditions': definition.get('conditions', [])
        }

    def create_test_scenarios(self):
        """一般的なテストシナリオを作成"""
        return {
            'happy_path': {
                'description': 'すべての操作が成功',
                'stubs': [
                    {
                        'path': '/api/auth/login',
                        'response': {
                            'status': 200,
                            'body': {
                                'token': 'valid_token',
                                'user': {'id': '123', 'name': 'Test User'}
                            }
                        }
                    },
                    {
                        'path': '/api/users/{id}',
                        'response': {
                            'status': 200,
                            'body': {
                                'id': '{id}',
                                'name': 'Test User',
                                'email': 'test@example.com'
                            }
                        }
                    }
                ]
            },
            'error_scenario': {
                'description': '様々なエラー条件',
                'sequences': [
                    {
                        'name': 'rate_limiting',
                        'steps': [
                            {'repeat': 5, 'response': {'status': 200}},
                            {'repeat': 10, 'response': {'status': 429, 'body': {'error': 'Rate limit exceeded'}}}
                        ]
                    }
                ],
                'stubs': [
                    {
                        'path': '/api/auth/login',
                        'conditions': [
                            {
                                'match': {'body': {'username': 'locked_user'}},
                                'response': {'status': 423, 'body': {'error': 'Account locked'}}
                            }
                        ]
                    }
                ]
            },
            'degraded_performance': {
                'description': '遅いレスポンスとタイムアウト',
                'stubs': [
                    {
                        'path': '/api/*',
                        'delay': 5000,  # 5秒遅延
                        'response': {'status': 200}
                    }
                ]
            }
        }

    def execute_scenario_sequence(self):
        """シナリオシーケンスを実行"""
        return '''
class SequenceExecutor:
    def __init__(self):
        self.sequence_states = {}

    def get_sequence_response(self, sequence_name: str, request: Dict):
        """シーケンス状態に基づいてレスポンスを取得"""
        if sequence_name not in self.sequence_states:
            self.sequence_states[sequence_name] = {'step': 0, 'count': 0}

        state = self.sequence_states[sequence_name]
        sequence = self.get_sequence_definition(sequence_name)

        # 現在のステップを取得
        current_step = sequence['steps'][state['step']]

        # 次のステップに進むべきかチェック
        state['count'] += 1
        if state['count'] >= current_step.get('repeat', 1):
            state['step'] = (state['step'] + 1) % len(sequence['steps'])
            state['count'] = 0

        return current_step['response']

    def create_stateful_scenario(self):
        """ステートフルな動作を持つシナリオを作成"""
        return {
            'shopping_cart': {
                'initial_state': {
                    'cart': {},
                    'total': 0
                },
                'stubs': [
                    {
                        'method': 'POST',
                        'path': '/api/cart/items',
                        'handler': 'add_to_cart',
                        'modifies_state': True
                    },
                    {
                        'method': 'GET',
                        'path': '/api/cart',
                        'handler': 'get_cart',
                        'uses_state': True
                    }
                ],
                'handlers': {
                    'add_to_cart': lambda state, request: {
                        'state': {
                            **state,
                            'cart': {
                                **state['cart'],
                                request['body']['product_id']: request['body']['quantity']
                            },
                            'total': state['total'] + request['body']['price']
                        },
                        'response': {
                            'status': 201,
                            'body': {'message': 'Item added to cart'}
                        }
                    },
                    'get_cart': lambda state, request: {
                        'response': {
                            'status': 200,
                            'body': {
                                'items': state['cart'],
                                'total': state['total']
                            }
                        }
                    }
                }
            }
        }
'''
```

### 5. コントラクトテスト

コントラクトベースのモッキングを実装:

**コントラクトテストフレームワーク**
```python
class ContractMockServer:
    def __init__(self):
        self.contracts = {}
        self.validators = self._init_validators()

    def load_contract(self, contract_path: str):
        """APIコントラクト（OpenAPI、AsyncAPIなど）をロード"""
        with open(contract_path, 'r') as f:
            contract = yaml.safe_load(f)

        # コントラクトをパース
        self.contracts[contract['info']['title']] = {
            'spec': contract,
            'endpoints': self._parse_endpoints(contract),
            'schemas': self._parse_schemas(contract)
        }

    def generate_mocks_from_contract(self, contract_name: str):
        """コントラクト仕様からモックを生成"""
        contract = self.contracts[contract_name]
        mocks = []

        for path, methods in contract['endpoints'].items():
            for method, spec in methods.items():
                mock = self._create_mock_from_spec(path, method, spec)
                mocks.append(mock)

        return mocks

    def _create_mock_from_spec(self, path: str, method: str, spec: Dict):
        """エンドポイント仕様からモックを作成"""
        mock = {
            'method': method.upper(),
            'path': self._convert_path_to_pattern(path),
            'responses': {}
        }

        # 各ステータスコードのレスポンスを生成
        for status_code, response_spec in spec.get('responses', {}).items():
            mock['responses'][status_code] = {
                'status': int(status_code),
                'headers': self._get_response_headers(response_spec),
                'body': self._generate_response_body(response_spec)
            }

        # リクエスト検証を追加
        if 'requestBody' in spec:
            mock['request_validation'] = self._create_request_validator(spec['requestBody'])

        return mock

    def validate_against_contract(self):
        """コントラクトに対してモックレスポンスを検証"""
        return '''
class ContractValidator:
    def validate_response(self, contract_spec, actual_response):
        """コントラクトに対してレスポンスを検証"""
        validation_results = {
            'valid': True,
            'errors': []
        }

        # ステータスコードのレスポンス仕様を検索
        response_spec = contract_spec['responses'].get(
            str(actual_response['status']),
            contract_spec['responses'].get('default')
        )

        if not response_spec:
            validation_results['errors'].append({
                'type': 'unexpected_status',
                'message': f"Status {actual_response['status']} not defined in contract"
            })
            validation_results['valid'] = False
            return validation_results

        # ヘッダーを検証
        if 'headers' in response_spec:
            header_errors = self.validate_headers(
                response_spec['headers'],
                actual_response['headers']
            )
            validation_results['errors'].extend(header_errors)

        # ボディスキーマを検証
        if 'content' in response_spec:
            body_errors = self.validate_body(
                response_spec['content'],
                actual_response['body']
            )
            validation_results['errors'].extend(body_errors)

        validation_results['valid'] = len(validation_results['errors']) == 0
        return validation_results

    def validate_body(self, content_spec, actual_body):
        """スキーマに対してレスポンスボディを検証"""
        errors = []

        # コンテンツタイプのスキーマを取得
        schema = content_spec.get('application/json', {}).get('schema')
        if not schema:
            return errors

        # JSONスキーマに対して検証
        try:
            validate(instance=actual_body, schema=schema)
        except ValidationError as e:
            errors.append({
                'type': 'schema_validation',
                'path': e.json_path,
                'message': e.message
            })

        return errors
'''
```

### 6. パフォーマンステスト

パフォーマンステスト用モックを作成:

**パフォーマンスモックサーバー**
```python
class PerformanceMockServer:
    def __init__(self):
        self.performance_profiles = {}
        self.metrics_collector = MetricsCollector()

    def create_performance_profile(self, name: str, config: Dict):
        """パフォーマンステストプロファイルを作成"""
        self.performance_profiles[name] = {
            'latency': config.get('latency', {'min': 10, 'max': 100}),
            'throughput': config.get('throughput', 1000),  # 秒あたりのリクエスト数
            'error_rate': config.get('error_rate', 0.01),  # 1%のエラー
            'response_size': config.get('response_size', {'min': 100, 'max': 10000})
        }

    async def simulate_performance(self, profile_name: str, request: Request):
        """パフォーマンス特性をシミュレート"""
        profile = self.performance_profiles[profile_name]

        # レイテンシをシミュレート
        latency = random.uniform(profile['latency']['min'], profile['latency']['max'])
        await asyncio.sleep(latency / 1000)

        # エラーをシミュレート
        if random.random() < profile['error_rate']:
            return self._generate_error_response()

        # 指定されたサイズのレスポンスを生成
        response_size = random.randint(
            profile['response_size']['min'],
            profile['response_size']['max']
        )

        response_data = self._generate_data_of_size(response_size)

        # メトリクスを記録
        self.metrics_collector.record({
            'latency': latency,
            'response_size': response_size,
            'timestamp': datetime.now()
        })

        return response_data

    def create_load_test_scenarios(self):
        """負荷テストシナリオを作成"""
        return {
            'gradual_load': {
                'description': '徐々に負荷を増加',
                'stages': [
                    {'duration': 60, 'target_rps': 100},
                    {'duration': 120, 'target_rps': 500},
                    {'duration': 180, 'target_rps': 1000},
                    {'duration': 60, 'target_rps': 100}
                ]
            },
            'spike_test': {
                'description': 'トラフィックの突然のスパイク',
                'stages': [
                    {'duration': 60, 'target_rps': 100},
                    {'duration': 10, 'target_rps': 5000},
                    {'duration': 60, 'target_rps': 100}
                ]
            },
            'stress_test': {
                'description': '限界点を見つける',
                'stages': [
                    {'duration': 60, 'target_rps': 100},
                    {'duration': 60, 'target_rps': 500},
                    {'duration': 60, 'target_rps': 1000},
                    {'duration': 60, 'target_rps': 2000},
                    {'duration': 60, 'target_rps': 5000},
                    {'duration': 60, 'target_rps': 10000}
                ]
            }
        }

    def implement_throttling(self):
        """リクエストスロットリングを実装"""
        return '''
class ThrottlingMiddleware:
    def __init__(self, max_rps: int):
        self.max_rps = max_rps
        self.request_times = deque()

    async def __call__(self, request: Request, call_next):
        current_time = time.time()

        # 古いリクエストを削除
        while self.request_times and self.request_times[0] < current_time - 1:
            self.request_times.popleft()

        # 制限を超えているかチェック
        if len(self.request_times) >= self.max_rps:
            return Response(
                content=json.dumps({
                    'error': 'Rate limit exceeded',
                    'retry_after': 1
                }),
                status_code=429,
                headers={'Retry-After': '1'}
            )

        # このリクエストを記録
        self.request_times.append(current_time)

        # リクエストを処理
        response = await call_next(request)
        return response
'''
```

### 7. モックデータ管理

モックデータを効果的に管理:

**モックデータストア**
```python
class MockDataStore:
    def __init__(self):
        self.collections = {}
        self.indexes = {}

    def create_collection(self, name: str, schema: Dict = None):
        """新しいデータコレクションを作成"""
        self.collections[name] = {
            'data': {},
            'schema': schema,
            'counter': 0
        }

        # 'id'にデフォルトインデックスを作成
        self.create_index(name, 'id')

    def insert(self, collection: str, data: Dict):
        """コレクションにデータを挿入"""
        collection_data = self.collections[collection]

        # スキーマが存在する場合は検証
        if collection_data['schema']:
            self._validate_data(data, collection_data['schema'])

        # 提供されていない場合はIDを生成
        if 'id' not in data:
            collection_data['counter'] += 1
            data['id'] = str(collection_data['counter'])

        # データを保存
        collection_data['data'][data['id']] = data

        # インデックスを更新
        self._update_indexes(collection, data)

        return data['id']

    def query(self, collection: str, filters: Dict = None):
        """フィルタを使用してコレクションをクエリ"""
        collection_data = self.collections[collection]['data']

        if not filters:
            return list(collection_data.values())

        # 利用可能な場合はインデックスを使用
        if self._can_use_index(collection, filters):
            return self._query_with_index(collection, filters)

        # フルスキャン
        results = []
        for item in collection_data.values():
            if self._matches_filters(item, filters):
                results.append(item)

        return results

    def create_relationships(self):
        """コレクション間の関係を定義"""
        return '''
class RelationshipManager:
    def __init__(self, data_store: MockDataStore):
        self.store = data_store
        self.relationships = {}

    def define_relationship(self,
                          source_collection: str,
                          target_collection: str,
                          relationship_type: str,
                          foreign_key: str):
        """コレクション間の関係を定義"""
        self.relationships[f"{source_collection}->{target_collection}"] = {
            'type': relationship_type,
            'source': source_collection,
            'target': target_collection,
            'foreign_key': foreign_key
        }

    def populate_related_data(self, entity: Dict, collection: str, depth: int = 1):
        """エンティティの関連データを取得"""
        if depth <= 0:
            return entity

        # このコレクションの関係を検索
        for rel_key, rel in self.relationships.items():
            if rel['source'] == collection:
                # 関連データを取得
                foreign_id = entity.get(rel['foreign_key'])
                if foreign_id:
                    related = self.store.get(rel['target'], foreign_id)
                    if related:
                        # 再帰的に取得
                        related = self.populate_related_data(
                            related,
                            rel['target'],
                            depth - 1
                        )
                        entity[rel['target']] = related

        return entity

    def cascade_operations(self, operation: str, collection: str, entity_id: str):
        """カスケード操作を処理"""
        if operation == 'delete':
            # 依存関係を検索
            for rel in self.relationships.values():
                if rel['target'] == collection:
                    # 依存エンティティを削除
                    dependents = self.store.query(
                        rel['source'],
                        {rel['foreign_key']: entity_id}
                    )
                    for dep in dependents:
                        self.store.delete(rel['source'], dep['id'])
'''
```

### 8. テストフレームワーク統合

人気のあるテストフレームワークと統合:

**テスト統合**
```python
class TestingFrameworkIntegration:
    def create_jest_integration(self):
        """Jestテスト統合"""
        return '''
// jest.mock.config.js
import { MockServer } from './mockServer';

const mockServer = new MockServer();

beforeAll(async () => {
    await mockServer.start({ port: 3001 });

    // モック定義をロード
    await mockServer.loadMocks('./mocks/*.json');

    // デフォルトシナリオを設定
    await mockServer.setScenario('test');
});

afterAll(async () => {
    await mockServer.stop();
});

beforeEach(async () => {
    // モック状態をリセット
    await mockServer.reset();
});

// テストヘルパー関数
export const setupMock = async (stub) => {
    return await mockServer.addStub(stub);
};

export const verifyRequests = async (matcher) => {
    const requests = await mockServer.getRequests(matcher);
    return requests;
};

// テスト例
describe('User API', () => {
    it('should fetch user details', async () => {
        // モックをセットアップ
        await setupMock({
            method: 'GET',
            path: '/api/users/123',
            response: {
                status: 200,
                body: { id: '123', name: 'Test User' }
            }
        });

        // リクエストを実行
        const response = await fetch('http://localhost:3001/api/users/123');
        const user = await response.json();

        // 検証
        expect(user.name).toBe('Test User');

        // モックが呼ばれたことを検証
        const requests = await verifyRequests({ path: '/api/users/123' });
        expect(requests).toHaveLength(1);
    });
});
'''

    def create_pytest_integration(self):
        """Pytest統合"""
        return '''
# conftest.py
import pytest
from mock_server import MockServer
import asyncio

@pytest.fixture(scope="session")
def event_loop():
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()

@pytest.fixture(scope="session")
async def mock_server(event_loop):
    server = MockServer()
    await server.start(port=3001)
    yield server
    await server.stop()

@pytest.fixture(autouse=True)
async def reset_mocks(mock_server):
    await mock_server.reset()
    yield
    # 予期しない呼び出しがないことを検証
    unmatched = await mock_server.get_unmatched_requests()
    assert len(unmatched) == 0, f"Unmatched requests: {unmatched}"

# テストユーティリティ
class MockBuilder:
    def __init__(self, mock_server):
        self.server = mock_server
        self.stubs = []

    def when(self, method, path):
        self.current_stub = {
            'method': method,
            'path': path
        }
        return self

    def with_body(self, body):
        self.current_stub['body'] = body
        return self

    def then_return(self, status, body=None, headers=None):
        self.current_stub['response'] = {
            'status': status,
            'body': body,
            'headers': headers or {}
        }
        self.stubs.append(self.current_stub)
        return self

    async def setup(self):
        for stub in self.stubs:
            await self.server.add_stub(stub)

# テスト例
@pytest.mark.asyncio
async def test_user_creation(mock_server):
    # モックをセットアップ
    mock = MockBuilder(mock_server)
    mock.when('POST', '/api/users') \
        .with_body({'name': 'New User'}) \
        .then_return(201, {'id': '456', 'name': 'New User'})

    await mock.setup()

    # ここにテストコード
    response = await create_user({'name': 'New User'})
    assert response['id'] == '456'
'''
```

### 9. モックサーバーデプロイメント

モックサーバーをデプロイ:

**デプロイメント設定**
```yaml
# モックサービス用のdocker-compose.yml
version: '3.8'

services:
  mock-api:
    build:
      context: .
      dockerfile: Dockerfile.mock
    ports:
      - "3001:3001"
    environment:
      - MOCK_SCENARIO=production
      - MOCK_DATA_PATH=/data/mocks
    volumes:
      - ./mocks:/data/mocks
      - ./scenarios:/data/scenarios
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3001/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  mock-admin:
    build:
      context: .
      dockerfile: Dockerfile.admin
    ports:
      - "3002:3002"
    environment:
      - MOCK_SERVER_URL=http://mock-api:3001
    depends_on:
      - mock-api

# Kubernetesデプロイメント
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mock-server
spec:
  replicas: 2
  selector:
    matchLabels:
      app: mock-server
  template:
    metadata:
      labels:
        app: mock-server
    spec:
      containers:
      - name: mock-server
        image: mock-server:latest
        ports:
        - containerPort: 3001
        env:
        - name: MOCK_SCENARIO
          valueFrom:
            configMapKeyRef:
              name: mock-config
              key: scenario
        volumeMounts:
        - name: mock-definitions
          mountPath: /data/mocks
      volumes:
      - name: mock-definitions
        configMap:
          name: mock-definitions
```

### 10. モック文書化

モックAPI文書化を生成:

**文書化ジェネレーター**
```python
class MockDocumentationGenerator:
    def generate_documentation(self, mock_server):
        """包括的なモック文書化を生成"""
        return f"""
# モックAPI文書化

## 概要
{self._generate_overview(mock_server)}

## 利用可能なエンドポイント
{self._generate_endpoints_doc(mock_server)}

## シナリオ
{self._generate_scenarios_doc(mock_server)}

## データモデル
{self._generate_models_doc(mock_server)}

## 使用例
{self._generate_examples(mock_server)}

## 設定
{self._generate_config_doc(mock_server)}
"""

    def _generate_endpoints_doc(self, mock_server):
        """エンドポイント文書化を生成"""
        doc = ""
        for endpoint in mock_server.get_endpoints():
            doc += f"""
### {endpoint['method']} {endpoint['path']}

**説明**: {endpoint.get('description', '説明なし')}

**リクエスト**:
```json
{json.dumps(endpoint.get('request_example', {}), indent=2)}
```

**レスポンス**:
```json
{json.dumps(endpoint.get('response_example', {}), indent=2)}
```

**シナリオ**:
{self._format_endpoint_scenarios(endpoint)}
"""
        return doc

    def create_interactive_docs(self):
        """インタラクティブAPI文書化を作成"""
        return '''
<!DOCTYPE html>
<html>
<head>
    <title>モックAPIインタラクティブ文書化</title>
    <script src="https://unpkg.com/swagger-ui-dist/swagger-ui-bundle.js"></script>
    <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist/swagger-ui.css">
</head>
<body>
    <div id="swagger-ui"></div>
    <script>
        window.onload = function() {
            const ui = SwaggerUIBundle({
                url: "/api/mock/openapi.json",
                dom_id: '#swagger-ui',
                presets: [
                    SwaggerUIBundle.presets.apis,
                    SwaggerUIBundle.SwaggerUIStandalonePreset
                ],
                layout: "BaseLayout",
                tryItOutEnabled: true,
                requestInterceptor: (request) => {
                    request.headers['X-Mock-Scenario'] =
                        document.getElementById('scenario-select').value;
                    return request;
                }
            });
        }
    </script>

    <div class="scenario-selector">
        <label>シナリオ:</label>
        <select id="scenario-select">
            <option value="default">デフォルト</option>
            <option value="error">エラー条件</option>
            <option value="slow">遅いレスポンス</option>
        </select>
    </div>
</body>
</html>
'''
```

## 出力形式

1. **モックサーバーセットアップ**: 完全なモックサーバー実装
2. **スタビング設定**: 柔軟なリクエスト/レスポンススタビング
3. **データ生成**: リアルなモックデータ生成
4. **シナリオ定義**: 包括的なテストシナリオ
5. **コントラクトテスト**: コントラクトベースのモック検証
6. **パフォーマンスシミュレーション**: パフォーマンステスト機能
7. **データ管理**: モックデータストレージと関係
8. **テスト統合**: フレームワーク統合例
9. **デプロイメントガイド**: モックサーバーデプロイメント設定
10. **文書化**: 自動生成されたモックAPI文書化

開発ライフサイクルのすべての段階で効率的な開発、徹底的なテスト、信頼性の高いAPIシミュレーションを可能にする、柔軟でリアルなモックサービスの作成に焦点を当てます。
