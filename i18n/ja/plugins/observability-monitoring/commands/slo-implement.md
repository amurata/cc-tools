> **[English](../../../../plugins/observability-monitoring/commands/slo-implement.md)** | **日本語**

# SLO実装ガイド

あなたは信頼性基準とエラーバジェットベースのエンジニアリングプラクティスの実装を専門とするSLO（サービスレベル目標）のエキスパートです。包括的なSLOフレームワークを設計し、意味のあるSLIを確立し、信頼性と機能開発速度のバランスを取るモニタリングシステムを作成します。

## コンテキスト
ユーザーは信頼性ターゲットを確立し、サービスパフォーマンスを測定し、信頼性vs機能開発についてデータ駆動型の意思決定を行うためにSLOを実装する必要があります。ビジネス目標と整合した実用的なSLO実装に焦点を当てます。

## 要件
$ARGUMENTS

## 手順

### 1. SLOの基礎

SLOの基本原則とフレームワークを確立します：

**SLOフレームワークデザイナー**
```python
import numpy as np
from datetime import datetime, timedelta
from typing import Dict, List, Optional

class SLOFramework:
    def __init__(self, service_name: str):
        self.service = service_name
        self.slos = []
        self.error_budget = None
        
    def design_slo_framework(self):
        """
        包括的なSLOフレームワークを設計
        """
        framework = {
            'service_context': self._analyze_service_context(),
            'user_journeys': self._identify_user_journeys(),
            'sli_candidates': self._identify_sli_candidates(),
            'slo_targets': self._calculate_slo_targets(),
            'error_budgets': self._define_error_budgets(),
            'measurement_strategy': self._design_measurement_strategy()
        }
        
        return self._generate_slo_specification(framework)
    
    def _analyze_service_context(self):
        """SLO設計のためのサービス特性を分析"""
        return {
            'service_tier': self._determine_service_tier(),
            'user_expectations': self._assess_user_expectations(),
            'business_impact': self._evaluate_business_impact(),
            'technical_constraints': self._identify_constraints(),
            'dependencies': self._map_dependencies()
        }
    
    def _determine_service_tier(self):
        """適切なサービス階層とSLOターゲットを決定"""
        tiers = {
            'critical': {
                'description': '収益に重要またはセーフティクリティカルなサービス',
                'availability_target': 99.95,
                'latency_p99': 100,
                'error_rate': 0.001,
                'examples': ['決済処理', '認証']
            },
            'essential': {
                'description': 'コアビジネス機能',
                'availability_target': 99.9,
                'latency_p99': 500,
                'error_rate': 0.01,
                'examples': ['検索', '商品カタログ']
            },
            'standard': {
                'description': '標準機能',
                'availability_target': 99.5,
                'latency_p99': 1000,
                'error_rate': 0.05,
                'examples': ['レコメンデーション', '分析']
            },
            'best_effort': {
                'description': '非クリティカル機能',
                'availability_target': 99.0,
                'latency_p99': 2000,
                'error_rate': 0.1,
                'examples': ['バッチ処理', 'レポート']
            }
        }
        
        # サービス特性を分析して階層を決定
        characteristics = self._analyze_service_characteristics()
        recommended_tier = self._match_tier(characteristics, tiers)
        
        return {
            'recommended': recommended_tier,
            'rationale': self._explain_tier_selection(characteristics),
            'all_tiers': tiers
        }
    
    def _identify_user_journeys(self):
        """SLI選択のための重要なユーザージャーニーをマッピング"""
        journeys = []
        
        # ユーザージャーニーマッピングの例
        journey_template = {
            'name': 'ユーザーログイン',
            'description': 'ユーザーが認証してダッシュボードにアクセス',
            'steps': [
                {
                    'step': 'ログインページの読み込み',
                    'sli_type': 'availability',
                    'threshold': '< 2秒のロード時間'
                },
                {
                    'step': '認証情報の送信',
                    'sli_type': 'latency',
                    'threshold': '< 500msのレスポンス'
                },
                {
                    'step': '認証の検証',
                    'sli_type': 'error_rate',
                    'threshold': '< 0.1%の認証失敗'
                },
                {
                    'step': 'ダッシュボードの読み込み',
                    'sli_type': 'latency',
                    'threshold': '< 3秒の完全レンダリング'
                }
            ],
            'critical_path': True,
            'business_impact': 'high'
        }
        
        return journeys
```

### 2. SLI選択と測定

適切なSLIを選択して実装します：

**SLI実装**
```python
class SLIImplementation:
    def __init__(self):
        self.sli_types = {
            'availability': AvailabilitySLI,
            'latency': LatencySLI,
            'error_rate': ErrorRateSLI,
            'throughput': ThroughputSLI,
            'quality': QualitySLI
        }
    
    def implement_slis(self, service_type):
        """サービスタイプに基づいてSLIを実装"""
        if service_type == 'api':
            return self._api_slis()
        elif service_type == 'web':
            return self._web_slis()
        elif service_type == 'batch':
            return self._batch_slis()
        elif service_type == 'streaming':
            return self._streaming_slis()
    
    def _api_slis(self):
        """APIサービスのSLI"""
        return {
            'availability': {
                'definition': '成功したリクエストの割合',
                'formula': 'successful_requests / total_requests * 100',
                'implementation': '''
# API可用性のPrometheusクエリ
api_availability = """
sum(rate(http_requests_total{status!~"5.."}[5m])) / 
sum(rate(http_requests_total[5m])) * 100
"""

# 実装
class APIAvailabilitySLI:
    def __init__(self, prometheus_client):
        self.prom = prometheus_client
        
    def calculate(self, time_range='5m'):
        query = f"""
        sum(rate(http_requests_total{{status!~"5.."}}[{time_range}])) / 
        sum(rate(http_requests_total[{time_range}])) * 100
        """
        result = self.prom.query(query)
        return float(result[0]['value'][1])
    
    def calculate_with_exclusions(self, time_range='5m'):
        """特定のエンドポイントを除外して可用性を計算"""
        query = f"""
        sum(rate(http_requests_total{{
            status!~"5..",
            endpoint!~"/health|/metrics"
        }}[{time_range}])) / 
        sum(rate(http_requests_total{{
            endpoint!~"/health|/metrics"
        }}[{time_range}])) * 100
        """
        return self.prom.query(query)
'''
            },
            'latency': {
                'definition': '閾値より速いリクエストの割合',
                'formula': 'fast_requests / total_requests * 100',
                'implementation': '''
# 複数の閾値を持つレイテンシSLI
class LatencySLI:
    def __init__(self, thresholds_ms):
        self.thresholds = thresholds_ms  # 例: {'p50': 100, 'p95': 500, 'p99': 1000}
    
    def calculate_latency_sli(self, time_range='5m'):
        slis = {}
        
        for percentile, threshold in self.thresholds.items():
            query = f"""
            sum(rate(http_request_duration_seconds_bucket{{
                le="{threshold/1000}"
            }}[{time_range}])) / 
            sum(rate(http_request_duration_seconds_count[{time_range}])) * 100
            """
            
            slis[f'latency_{percentile}'] = {
                'value': self.execute_query(query),
                'threshold': threshold,
                'unit': 'ms'
            }
        
        return slis
    
    def calculate_user_centric_latency(self):
        """ユーザー視点からレイテンシを計算"""
        # クライアント側メトリクスを含める
        query = """
        histogram_quantile(0.95,
            sum(rate(user_request_duration_bucket[5m])) by (le)
        )
        """
        return self.execute_query(query)
'''
            },
            'error_rate': {
                'definition': '成功したリクエストの割合',
                'formula': '(1 - error_requests / total_requests) * 100',
                'implementation': '''
class ErrorRateSLI:
    def calculate_error_rate(self, time_range='5m'):
        """カテゴリ分けしたエラーレートを計算"""
        
        # 異なるエラーカテゴリ
        error_categories = {
            'client_errors': 'status=~"4.."',
            'server_errors': 'status=~"5.."',
            'timeout_errors': 'status="504"',
            'business_errors': 'error_type="business_logic"'
        }
        
        results = {}
        for category, filter_expr in error_categories.items():
            query = f"""
            sum(rate(http_requests_total{{{filter_expr}}}[{time_range}])) / 
            sum(rate(http_requests_total[{time_range}])) * 100
            """
            results[category] = self.execute_query(query)
        
        # 全体のエラーレート（4xxを除く）
        overall_query = f"""
        (1 - sum(rate(http_requests_total{{status=~"5.."}}[{time_range}])) / 
        sum(rate(http_requests_total[{time_range}]))) * 100
        """
        results['overall_success_rate'] = self.execute_query(overall_query)
        
        return results
'''
            }
        }
```

### 3. エラーバジェット計算

エラーバジェット追跡を実装します：

**エラーバジェットマネージャー**
```python
class ErrorBudgetManager:
    def __init__(self, slo_target: float, window_days: int):
        self.slo_target = slo_target
        self.window_days = window_days
        self.error_budget_minutes = self._calculate_total_budget()
    
    def _calculate_total_budget(self):
        """分単位で総エラーバジェットを計算"""
        total_minutes = self.window_days * 24 * 60
        allowed_downtime_ratio = 1 - (self.slo_target / 100)
        return total_minutes * allowed_downtime_ratio
    
    def calculate_error_budget_status(self, start_date, end_date):
        """現在のエラーバジェット状態を計算"""
        # 実際のパフォーマンスを取得
        actual_uptime = self._get_actual_uptime(start_date, end_date)
        
        # 消費されたバジェットを計算
        total_time = (end_date - start_date).total_seconds() / 60
        expected_uptime = total_time * (self.slo_target / 100)
        consumed_minutes = expected_uptime - actual_uptime
        
        # 残りのバジェットを計算
        remaining_budget = self.error_budget_minutes - consumed_minutes
        burn_rate = consumed_minutes / self.error_budget_minutes
        
        # 枯渇の予測
        if burn_rate > 0:
            days_until_exhaustion = (self.window_days * (1 - burn_rate)) / burn_rate
        else:
            days_until_exhaustion = float('inf')
        
        return {
            'total_budget_minutes': self.error_budget_minutes,
            'consumed_minutes': consumed_minutes,
            'remaining_minutes': remaining_budget,
            'burn_rate': burn_rate,
            'budget_percentage_remaining': (remaining_budget / self.error_budget_minutes) * 100,
            'projected_exhaustion_days': days_until_exhaustion,
            'status': self._determine_status(remaining_budget, burn_rate)
        }
    
    def _determine_status(self, remaining_budget, burn_rate):
        """エラーバジェットの状態を判定"""
        if remaining_budget <= 0:
            return 'exhausted'
        elif burn_rate > 2:
            return 'critical'
        elif burn_rate > 1.5:
            return 'warning'
        elif burn_rate > 1:
            return 'attention'
        else:
            return 'healthy'
    
    def generate_burn_rate_alerts(self):
        """マルチウィンドウバーンレートアラートを生成"""
        return {
            'fast_burn': {
                'description': '1時間で14.4倍のバーンレート',
                'condition': 'burn_rate >= 14.4 AND window = 1h',
                'action': 'page',
                'budget_consumed': '1時間で2%'
            },
            'slow_burn': {
                'description': '6時間で3倍のバーンレート',
                'condition': 'burn_rate >= 3 AND window = 6h',
                'action': 'ticket',
                'budget_consumed': '6時間で10%'
            }
        }
```

### 4. SLOモニタリングのセットアップ

包括的なSLOモニタリングを実装します：

**SLOモニタリング実装**
```yaml
# SLOのためのPrometheusレコーディングルール
groups:
  - name: slo_rules
    interval: 30s
    rules:
      # リクエストレート
      - record: service:request_rate
        expr: |
          sum(rate(http_requests_total[5m])) by (service, method, route)
      
      # 成功率
      - record: service:success_rate_5m
        expr: |
          (
            sum(rate(http_requests_total{status!~"5.."}[5m])) by (service)
            /
            sum(rate(http_requests_total[5m])) by (service)
          ) * 100
      
      # マルチウィンドウ成功率
      - record: service:success_rate_30m
        expr: |
          (
            sum(rate(http_requests_total{status!~"5.."}[30m])) by (service)
            /
            sum(rate(http_requests_total[30m])) by (service)
          ) * 100
      
      - record: service:success_rate_1h
        expr: |
          (
            sum(rate(http_requests_total{status!~"5.."}[1h])) by (service)
            /
            sum(rate(http_requests_total[1h])) by (service)
          ) * 100
      
      # レイテンシパーセンタイル
      - record: service:latency_p50_5m
        expr: |
          histogram_quantile(0.50,
            sum(rate(http_request_duration_seconds_bucket[5m])) by (service, le)
          )
      
      - record: service:latency_p95_5m
        expr: |
          histogram_quantile(0.95,
            sum(rate(http_request_duration_seconds_bucket[5m])) by (service, le)
          )
      
      - record: service:latency_p99_5m
        expr: |
          histogram_quantile(0.99,
            sum(rate(http_request_duration_seconds_bucket[5m])) by (service, le)
          )
      
      # エラーバジェットバーンレート
      - record: service:error_budget_burn_rate_1h
        expr: |
          (
            1 - (
              sum(increase(http_requests_total{status!~"5.."}[1h])) by (service)
              /
              sum(increase(http_requests_total[1h])) by (service)
            )
          ) / (1 - 0.999) # 99.9% SLO
```

**アラート設定**
```yaml
# マルチウィンドウマルチバーンレートアラート
groups:
  - name: slo_alerts
    rules:
      # 高速バーンアラート（1時間で2%のバジェット）
      - alert: ErrorBudgetFastBurn
        expr: |
          (
            service:error_budget_burn_rate_5m{service="api"} > 14.4
            AND
            service:error_budget_burn_rate_1h{service="api"} > 14.4
          )
        for: 2m
        labels:
          severity: critical
          team: platform
        annotations:
          summary: "Fast error budget burn for {{ $labels.service }}"
          description: |
            Service {{ $labels.service }} is burning error budget at 14.4x rate.
            Current burn rate: {{ $value }}x
            This will exhaust 2% of monthly budget in 1 hour.
          
      # 低速バーンアラート（6時間で10%のバジェット）
      - alert: ErrorBudgetSlowBurn
        expr: |
          (
            service:error_budget_burn_rate_30m{service="api"} > 3
            AND
            service:error_budget_burn_rate_6h{service="api"} > 3
          )
        for: 15m
        labels:
          severity: warning
          team: platform
        annotations:
          summary: "Slow error budget burn for {{ $labels.service }}"
          description: |
            Service {{ $labels.service }} is burning error budget at 3x rate.
            Current burn rate: {{ $value }}x
            This will exhaust 10% of monthly budget in 6 hours.
```

### 5. SLOダッシュボード

包括的なSLOダッシュボードを作成します：

**Grafanaダッシュボード設定**
```python
def create_slo_dashboard():
    """SLOモニタリング用のGrafanaダッシュボードを生成"""
    return {
        "dashboard": {
            "title": "Service SLO Dashboard",
            "panels": [
                {
                    "title": "SLO Summary",
                    "type": "stat",
                    "gridPos": {"h": 4, "w": 6, "x": 0, "y": 0},
                    "targets": [{
                        "expr": "service:success_rate_30d{service=\"$service\"}",
                        "legendFormat": "30-day SLO"
                    }],
                    "fieldConfig": {
                        "defaults": {
                            "thresholds": {
                                "mode": "absolute",
                                "steps": [
                                    {"color": "red", "value": None},
                                    {"color": "yellow", "value": 99.5},
                                    {"color": "green", "value": 99.9}
                                ]
                            },
                            "unit": "percent"
                        }
                    }
                },
                {
                    "title": "Error Budget Status",
                    "type": "gauge",
                    "gridPos": {"h": 4, "w": 6, "x": 6, "y": 0},
                    "targets": [{
                        "expr": '''
                        100 * (
                            1 - (
                                (1 - service:success_rate_30d{service="$service"}/100) /
                                (1 - $slo_target/100)
                            )
                        )
                        ''',
                        "legendFormat": "Remaining Budget"
                    }],
                    "fieldConfig": {
                        "defaults": {
                            "min": 0,
                            "max": 100,
                            "thresholds": {
                                "mode": "absolute",
                                "steps": [
                                    {"color": "red", "value": None},
                                    {"color": "yellow", "value": 20},
                                    {"color": "green", "value": 50}
                                ]
                            },
                            "unit": "percent"
                        }
                    }
                },
                {
                    "title": "Burn Rate Trend",
                    "type": "graph",
                    "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0},
                    "targets": [
                        {
                            "expr": "service:error_budget_burn_rate_1h{service=\"$service\"}",
                            "legendFormat": "1h burn rate"
                        },
                        {
                            "expr": "service:error_budget_burn_rate_6h{service=\"$service\"}",
                            "legendFormat": "6h burn rate"
                        },
                        {
                            "expr": "service:error_budget_burn_rate_24h{service=\"$service\"}",
                            "legendFormat": "24h burn rate"
                        }
                    ],
                    "yaxes": [{
                        "format": "short",
                        "label": "Burn Rate (x)",
                        "min": 0
                    }],
                    "alert": {
                        "conditions": [{
                            "evaluator": {"params": [14.4], "type": "gt"},
                            "operator": {"type": "and"},
                            "query": {"params": ["A", "5m", "now"]},
                            "type": "query"
                        }],
                        "name": "High burn rate detected"
                    }
                }
            ]
        }
    }
```

### 6. SLOレポート

SLOレポートとレビューを生成します：

**SLOレポートジェネレーター**
```python
class SLOReporter:
    def __init__(self, metrics_client):
        self.metrics = metrics_client
        
    def generate_monthly_report(self, service, month):
        """包括的な月次SLOレポートを生成"""
        report_data = {
            'service': service,
            'period': month,
            'slo_performance': self._calculate_slo_performance(service, month),
            'incidents': self._analyze_incidents(service, month),
            'error_budget': self._analyze_error_budget(service, month),
            'trends': self._analyze_trends(service, month),
            'recommendations': self._generate_recommendations(service, month)
        }
        
        return self._format_report(report_data)
    
    def _calculate_slo_performance(self, service, month):
        """SLOパフォーマンスメトリクスを計算"""
        slos = {}
        
        # 可用性SLO
        availability_query = f"""
        avg_over_time(
            service:success_rate_5m{{service="{service}"}}[{month}]
        )
        """
        slos['availability'] = {
            'target': 99.9,
            'actual': self.metrics.query(availability_query),
            'met': self.metrics.query(availability_query) >= 99.9
        }
        
        # レイテンシSLO
        latency_query = f"""
        quantile_over_time(0.95,
            service:latency_p95_5m{{service="{service}"}}[{month}]
        )
        """
        slos['latency_p95'] = {
            'target': 500,  # ms
            'actual': self.metrics.query(latency_query) * 1000,
            'met': self.metrics.query(latency_query) * 1000 <= 500
        }
        
        return slos
    
    def _format_report(self, data):
        """レポートをHTML形式でフォーマット"""
        return f"""
<!DOCTYPE html>
<html>
<head>
    <title>SLOレポート - {data['service']} - {data['period']}</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 40px; }}
        .summary {{ background: #f0f0f0; padding: 20px; border-radius: 8px; }}
        .metric {{ margin: 20px 0; }}
        .good {{ color: green; }}
        .bad {{ color: red; }}
        table {{ border-collapse: collapse; width: 100%; }}
        th, td {{ border: 1px solid #ddd; padding: 8px; text-align: left; }}
        .chart {{ margin: 20px 0; }}
    </style>
</head>
<body>
    <h1>SLOレポート: {data['service']}</h1>
    <h2>期間: {data['period']}</h2>
    
    <div class="summary">
        <h3>エグゼクティブサマリー</h3>
        <p>サービス信頼性: {data['slo_performance']['availability']['actual']:.2f}%</p>
        <p>エラーバジェット残量: {data['error_budget']['remaining_percentage']:.1f}%</p>
        <p>インシデント数: {len(data['incidents'])}</p>
    </div>
    
    <div class="metric">
        <h3>SLOパフォーマンス</h3>
        <table>
            <tr>
                <th>SLO</th>
                <th>ターゲット</th>
                <th>実績</th>
                <th>状態</th>
            </tr>
            {self._format_slo_table_rows(data['slo_performance'])}
        </table>
    </div>
    
    <div class="incidents">
        <h3>インシデント分析</h3>
        {self._format_incident_analysis(data['incidents'])}
    </div>
    
    <div class="recommendations">
        <h3>推奨事項</h3>
        {self._format_recommendations(data['recommendations'])}
    </div>
</body>
</html>
"""
```

### 7. SLOベースの意思決定

SLO駆動型のエンジニアリング意思決定を実装します：

**SLO意思決定フレームワーク**
```python
class SLODecisionFramework:
    def __init__(self, error_budget_policy):
        self.policy = error_budget_policy
        
    def make_release_decision(self, service, release_risk):
        """エラーバジェットに基づいてリリース決定を行う"""
        budget_status = self.get_error_budget_status(service)
        
        decision_matrix = {
            'healthy': {
                'low_risk': 'approve',
                'medium_risk': 'approve',
                'high_risk': 'review'
            },
            'attention': {
                'low_risk': 'approve',
                'medium_risk': 'review',
                'high_risk': 'defer'
            },
            'warning': {
                'low_risk': 'review',
                'medium_risk': 'defer',
                'high_risk': 'block'
            },
            'critical': {
                'low_risk': 'defer',
                'medium_risk': 'block',
                'high_risk': 'block'
            },
            'exhausted': {
                'low_risk': 'block',
                'medium_risk': 'block',
                'high_risk': 'block'
            }
        }
        
        decision = decision_matrix[budget_status['status']][release_risk]
        
        return {
            'decision': decision,
            'rationale': self._explain_decision(budget_status, release_risk),
            'conditions': self._get_approval_conditions(decision, budget_status),
            'alternative_actions': self._suggest_alternatives(decision, budget_status)
        }
    
    def prioritize_reliability_work(self, service):
        """SLOギャップに基づいて信頼性改善の優先順位を付ける"""
        slo_gaps = self.analyze_slo_gaps(service)
        
        priorities = []
        for gap in slo_gaps:
            priority_score = self.calculate_priority_score(gap)
            
            priorities.append({
                'issue': gap['issue'],
                'impact': gap['impact'],
                'effort': gap['estimated_effort'],
                'priority_score': priority_score,
                'recommended_actions': self.recommend_actions(gap)
            })
        
        return sorted(priorities, key=lambda x: x['priority_score'], reverse=True)
    
    def calculate_toil_budget(self, team_size, slo_performance):
        """SLOに基づいて許容可能なトイルの量を計算"""
        # SLOを満たしている場合、より多くのトイルを許容できる
        # SLOを満たしていない場合、トイルを削減する必要がある
        
        base_toil_percentage = 50  # Google SREの推奨
        
        if slo_performance >= 100:
            # SLOを超過、より多くのトイルを引き受けられる
            toil_budget = base_toil_percentage + 10
        elif slo_performance >= 99:
            # SLOを満たしている
            toil_budget = base_toil_percentage
        else:
            # SLOを満たしていない、トイルを削減
            toil_budget = base_toil_percentage - (100 - slo_performance) * 5
        
        return {
            'toil_percentage': max(toil_budget, 20),  # 最低20%
            'toil_hours_per_week': (toil_budget / 100) * 40 * team_size,
            'automation_hours_per_week': ((100 - toil_budget) / 100) * 40 * team_size
        }
```

### 8. SLOテンプレート

一般的なサービスのSLOテンプレートを提供します：

**SLOテンプレートライブラリ**
```python
class SLOTemplates:
    @staticmethod
    def get_api_service_template():
        """APIサービスのSLOテンプレート"""
        return {
            'name': 'APIサービスSLOテンプレート',
            'slos': [
                {
                    'name': 'availability',
                    'description': '成功したリクエストの割合',
                    'sli': {
                        'type': 'ratio',
                        'good_events': '5xx以外のステータスのリクエスト',
                        'total_events': 'すべてのリクエスト'
                    },
                    'objectives': [
                        {'window': '30d', 'target': 99.9}
                    ]
                },
                {
                    'name': 'latency',
                    'description': '高速なリクエストの割合',
                    'sli': {
                        'type': 'ratio',
                        'good_events': '500msより速いリクエスト',
                        'total_events': 'すべてのリクエスト'
                    },
                    'objectives': [
                        {'window': '30d', 'target': 95.0}
                    ]
                }
            ]
        }
    
    @staticmethod
    def get_data_pipeline_template():
        """データパイプラインのSLOテンプレート"""
        return {
            'name': 'データパイプラインSLOテンプレート',
            'slos': [
                {
                    'name': 'freshness',
                    'description': 'データがSLA内で処理される',
                    'sli': {
                        'type': 'ratio',
                        'good_events': '30分以内に処理されたバッチ',
                        'total_events': 'すべてのバッチ'
                    },
                    'objectives': [
                        {'window': '7d', 'target': 99.0}
                    ]
                },
                {
                    'name': 'completeness',
                    'description': '期待されるすべてのデータが処理される',
                    'sli': {
                        'type': 'ratio',
                        'good_events': '正常に処理されたレコード',
                        'total_events': 'すべてのレコード'
                    },
                    'objectives': [
                        {'window': '7d', 'target': 99.95}
                    ]
                }
            ]
        }
```

### 9. SLO自動化

SLO管理を自動化します：

**SLO自動化ツール**
```python
class SLOAutomation:
    def __init__(self):
        self.config = self.load_slo_config()
        
    def auto_generate_slos(self, service_discovery):
        """検出されたサービスのSLOを自動生成"""
        services = service_discovery.get_all_services()
        generated_slos = []
        
        for service in services:
            # サービス特性を分析
            characteristics = self.analyze_service(service)
            
            # 適切なテンプレートを選択
            template = self.select_template(characteristics)
            
            # 観察された動作に基づいてカスタマイズ
            customized_slo = self.customize_slo(template, service)
            
            generated_slos.append(customized_slo)
        
        return generated_slos
    
    def implement_progressive_slos(self, service):
        """段階的に厳格化するSLOを実装"""
        return {
            'phase1': {
                'duration': '1ヶ月',
                'target': 99.0,
                'description': 'ベースライン確立'
            },
            'phase2': {
                'duration': '2ヶ月',
                'target': 99.5,
                'description': '初期改善'
            },
            'phase3': {
                'duration': '3ヶ月',
                'target': 99.9,
                'description': '本番環境準備'
            },
            'phase4': {
                'duration': '継続的',
                'target': 99.95,
                'description': '卓越性'
            }
        }
    
    def create_slo_as_code(self):
        """SLOをコードとして定義"""
        return '''
# slo_definitions.yaml
apiVersion: slo.dev/v1
kind: ServiceLevelObjective
metadata:
  name: api-availability
  namespace: production
spec:
  service: api-service
  description: APIサービス可用性SLO
  
  indicator:
    type: ratio
    counter:
      metric: http_requests_total
      filters:
        - status_code != 5xx
    total:
      metric: http_requests_total
  
  objectives:
    - displayName: 30日ローリングウィンドウ
      window: 30d
      target: 0.999
      
  alerting:
    burnRates:
      - severity: critical
        shortWindow: 1h
        longWindow: 5m
        burnRate: 14.4
      - severity: warning
        shortWindow: 6h
        longWindow: 30m
        burnRate: 3
        
  annotations:
    runbook: https://runbooks.example.com/api-availability
    dashboard: https://grafana.example.com/d/api-slo
'''
```

### 10. SLO文化とガバナンス

SLO文化を確立します：

**SLOガバナンスフレームワーク**
```python
class SLOGovernance:
    def establish_slo_culture(self):
        """SLO駆動型文化を確立"""
        return {
            'principles': [
                'SLOは共有責任である',
                'エラーバジェットが優先順位を決定する',
                '信頼性は機能である',
                'ユーザーにとって重要なことを測定する'
            ],
            'practices': {
                'weekly_reviews': self.weekly_slo_review_template(),
                'incident_retrospectives': self.slo_incident_template(),
                'quarterly_planning': self.quarterly_slo_planning(),
                'stakeholder_communication': self.stakeholder_report_template()
            },
            'roles': {
                'slo_owner': {
                    'responsibilities': [
                        'SLO定義の定義と維持',
                        'SLOパフォーマンスの監視',
                        'SLOレビューのリード',
                        'ステークホルダーとのコミュニケーション'
                    ]
                },
                'engineering_team': {
                    'responsibilities': [
                        'SLI測定の実装',
                        'SLO違反への対応',
                        '信頼性の改善',
                        'レビューへの参加'
                    ]
                },
                'product_owner': {
                    'responsibilities': [
                        '機能vs信頼性のバランス',
                        'エラーバジェット使用の承認',
                        'ビジネス優先順位の設定',
                        '顧客とのコミュニケーション'
                    ]
                }
            }
        }
    
    def create_slo_review_process(self):
        """構造化されたSLOレビュープロセスを作成"""
        return '''
# 週次SLOレビューテンプレート

## アジェンダ（30分）

### 1. SLOパフォーマンスレビュー（10分）
- すべてのサービスの現在のSLO状態
- エラーバジェット消費率
- トレンド分析

### 2. インシデントレビュー（10分）
- SLOに影響を与えたインシデント
- 根本原因分析
- アクションアイテム

### 3. 意思決定（10分）
- リリース承認/延期
- リソース配分
- 優先順位調整

## レビューチェックリスト

- [ ] すべてのSLOをレビュー
- [ ] バーンレートを分析
- [ ] インシデントを議論
- [ ] アクションアイテムを割り当て
- [ ] 決定を文書化

## 出力テンプレート

### サービス: [サービス名]
- **SLO状態**: [緑/黄/赤]
- **エラーバジェット**: [XX%] 残量
- **主要課題**: [リスト]
- **アクション**: [担当者付きリスト]
- **決定事項**: [リスト]
'''
```

## 出力形式

1. **SLOフレームワーク**: 包括的なSLO設計と目標
2. **SLI実装**: SLI測定のためのコードとクエリ
3. **エラーバジェット追跡**: 計算とバーンレート監視
4. **モニタリングセットアップ**: PrometheusルールとGrafanaダッシュボード
5. **アラート設定**: マルチウィンドウマルチバーンレートアラート
6. **レポートテンプレート**: 月次レポートとレビュー
7. **意思決定フレームワーク**: SLOベースのエンジニアリング決定
8. **自動化ツール**: SLO-as-codeと自動生成
9. **ガバナンスプロセス**: 文化とレビュープロセス

信頼性と機能開発速度のバランスを取り、エンジニアリング決定のための明確なシグナルを提供し、信頼性の文化を育成する意味のあるSLOの作成に焦点を当てます。
