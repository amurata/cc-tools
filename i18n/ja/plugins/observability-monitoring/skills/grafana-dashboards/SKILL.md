---
name: grafana-dashboards
description: システムとアプリケーションメトリクスのリアルタイム可視化のための本番環境Grafanaダッシュボードを作成・管理します。モニタリングダッシュボードの構築、メトリクスの可視化、運用可観測性インターフェースの作成時に使用します。
---

> **[English](../../../../../plugins/observability-monitoring/skills/grafana-dashboards/SKILL.md)** | **日本語**

# Grafanaダッシュボード

包括的なシステム可観測性のための本番環境対応Grafanaダッシュボードを作成・管理します。

## 目的

アプリケーション、インフラストラクチャ、ビジネスメトリクスを監視するための効果的なGrafanaダッシュボードを設計します。

## 使用タイミング

- Prometheusメトリクスの可視化
- カスタムダッシュボードの作成
- SLOダッシュボードの実装
- インフラストラクチャの監視
- ビジネスKPIの追跡

## ダッシュボード設計原則

### 1. 情報の階層
```
┌─────────────────────────────────────┐
│  重要なメトリクス（大きな数字）      │
├─────────────────────────────────────┤
│  主要なトレンド（時系列）            │
├─────────────────────────────────────┤
│  詳細メトリクス（テーブル/ヒートマップ）│
└─────────────────────────────────────┘
```

### 2. REDメソッド（サービス）
- **Rate（レート）** - 秒あたりのリクエスト数
- **Errors（エラー）** - エラー率
- **Duration（期間）** - レイテンシ/レスポンスタイム

### 3. USEメソッド（リソース）
- **Utilization（使用率）** - リソースがビジーである時間の割合
- **Saturation（飽和度）** - キュー長/待機時間
- **Errors（エラー）** - エラー数

## ダッシュボード構造

### APIモニタリングダッシュボード

```json
{
  "dashboard": {
    "title": "API Monitoring",
    "tags": ["api", "production"],
    "timezone": "browser",
    "refresh": "30s",
    "panels": [
      {
        "title": "Request Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "sum(rate(http_requests_total[5m])) by (service)",
            "legendFormat": "{{service}}"
          }
        ],
        "gridPos": {"x": 0, "y": 0, "w": 12, "h": 8}
      },
      {
        "title": "Error Rate %",
        "type": "graph",
        "targets": [
          {
            "expr": "(sum(rate(http_requests_total{status=~\"5..\"}[5m])) / sum(rate(http_requests_total[5m]))) * 100",
            "legendFormat": "Error Rate"
          }
        ],
        "alert": {
          "conditions": [
            {
              "evaluator": {"params": [5], "type": "gt"},
              "operator": {"type": "and"},
              "query": {"params": ["A", "5m", "now"]},
              "type": "query"
            }
          ]
        },
        "gridPos": {"x": 12, "y": 0, "w": 12, "h": 8}
      },
      {
        "title": "P95 Latency",
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le, service))",
            "legendFormat": "{{service}}"
          }
        ],
        "gridPos": {"x": 0, "y": 8, "w": 24, "h": 8}
      }
    ]
  }
}
```

**参照:** `assets/api-dashboard.json`を参照

## パネルタイプ

### 1. Statパネル（単一値）
```json
{
  "type": "stat",
  "title": "Total Requests",
  "targets": [{
    "expr": "sum(http_requests_total)"
  }],
  "options": {
    "reduceOptions": {
      "values": false,
      "calcs": ["lastNotNull"]
    },
    "orientation": "auto",
    "textMode": "auto",
    "colorMode": "value"
  },
  "fieldConfig": {
    "defaults": {
      "thresholds": {
        "mode": "absolute",
        "steps": [
          {"value": 0, "color": "green"},
          {"value": 80, "color": "yellow"},
          {"value": 90, "color": "red"}
        ]
      }
    }
  }
}
```

### 2. 時系列グラフ
```json
{
  "type": "graph",
  "title": "CPU Usage",
  "targets": [{
    "expr": "100 - (avg by (instance) (rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)"
  }],
  "yaxes": [
    {"format": "percent", "max": 100, "min": 0},
    {"format": "short"}
  ]
}
```

### 3. テーブルパネル
```json
{
  "type": "table",
  "title": "Service Status",
  "targets": [{
    "expr": "up",
    "format": "table",
    "instant": true
  }],
  "transformations": [
    {
      "id": "organize",
      "options": {
        "excludeByName": {"Time": true},
        "indexByName": {},
        "renameByName": {
          "instance": "Instance",
          "job": "Service",
          "Value": "Status"
        }
      }
    }
  ]
}
```

### 4. ヒートマップ
```json
{
  "type": "heatmap",
  "title": "Latency Heatmap",
  "targets": [{
    "expr": "sum(rate(http_request_duration_seconds_bucket[5m])) by (le)",
    "format": "heatmap"
  }],
  "dataFormat": "tsbuckets",
  "yAxis": {
    "format": "s"
  }
}
```

## 変数

### クエリ変数
```json
{
  "templating": {
    "list": [
      {
        "name": "namespace",
        "type": "query",
        "datasource": "Prometheus",
        "query": "label_values(kube_pod_info, namespace)",
        "refresh": 1,
        "multi": false
      },
      {
        "name": "service",
        "type": "query",
        "datasource": "Prometheus",
        "query": "label_values(kube_service_info{namespace=\"$namespace\"}, service)",
        "refresh": 1,
        "multi": true
      }
    ]
  }
}
```

### クエリでの変数使用
```
sum(rate(http_requests_total{namespace="$namespace", service=~"$service"}[5m]))
```

## ダッシュボードでのアラート

```json
{
  "alert": {
    "name": "High Error Rate",
    "conditions": [
      {
        "evaluator": {
          "params": [5],
          "type": "gt"
        },
        "operator": {"type": "and"},
        "query": {
          "params": ["A", "5m", "now"]
        },
        "reducer": {"type": "avg"},
        "type": "query"
      }
    ],
    "executionErrorState": "alerting",
    "for": "5m",
    "frequency": "1m",
    "message": "Error rate is above 5%",
    "noDataState": "no_data",
    "notifications": [
      {"uid": "slack-channel"}
    ]
  }
}
```

## ダッシュボードプロビジョニング

**dashboards.yml:**
```yaml
apiVersion: 1

providers:
  - name: 'default'
    orgId: 1
    folder: 'General'
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /etc/grafana/dashboards
```

## 一般的なダッシュボードパターン

### インフラストラクチャダッシュボード

**主要パネル:**
- ノードごとのCPU使用率
- ノードごとのメモリ使用量
- ディスクI/O
- ネットワークトラフィック
- ネームスペースごとのPod数
- ノードステータス

**参照:** `assets/infrastructure-dashboard.json`を参照

### データベースダッシュボード

**主要パネル:**
- クエリ/秒
- コネクションプール使用状況
- クエリレイテンシ（P50、P95、P99）
- アクティブコネクション
- データベースサイズ
- レプリケーションラグ
- スロークエリ

**参照:** `assets/database-dashboard.json`を参照

### アプリケーションダッシュボード

**主要パネル:**
- リクエスト率
- エラー率
- レスポンスタイム（パーセンタイル）
- アクティブユーザー/セッション
- キャッシュヒット率
- キュー長

## ベストプラクティス

1. **テンプレートから始める**（Grafanaコミュニティダッシュボード）
2. **パネルと変数に一貫した命名を使用**
3. **関連するメトリクスを行でグループ化**
4. **適切な時間範囲を設定**（デフォルト: 過去6時間）
5. **柔軟性のために変数を使用**
6. **コンテキストのためのパネル説明を追加**
7. **単位を正しく設定**
8. **色に意味のある閾値を設定**
9. **ダッシュボード間で一貫した色を使用**
10. **異なる時間範囲でテスト**

## Dashboard as Code

### Terraformプロビジョニング

```hcl
resource "grafana_dashboard" "api_monitoring" {
  config_json = file("${path.module}/dashboards/api-monitoring.json")
  folder      = grafana_folder.monitoring.id
}

resource "grafana_folder" "monitoring" {
  title = "Production Monitoring"
}
```

### Ansibleプロビジョニング

```yaml
- name: Deploy Grafana dashboards
  copy:
    src: "{{ item }}"
    dest: /etc/grafana/dashboards/
  with_fileglob:
    - "dashboards/*.json"
  notify: restart grafana
```

## リファレンスファイル

- `assets/api-dashboard.json` - APIモニタリングダッシュボード
- `assets/infrastructure-dashboard.json` - インフラストラクチャダッシュボード
- `assets/database-dashboard.json` - データベースモニタリングダッシュボード
- `references/dashboard-design.md` - ダッシュボード設計ガイド

## 関連スキル

- `prometheus-configuration` - メトリクス収集のため
- `slo-implementation` - SLOダッシュボードのため
