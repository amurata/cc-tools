> **[English](../../../../../plugins/observability-monitoring/skills/prometheus-configuration/SKILL.md)** | **日本語**

---
name: prometheus-configuration
description: インフラストラクチャとアプリケーションの包括的なメトリクス収集、ストレージ、モニタリングのためのPrometheusをセットアップします。メトリクス収集の実装、モニタリングインフラストラクチャのセットアップ、アラートシステムの設定時に使用します。
---

# Prometheus設定

Prometheusのセットアップ、メトリクス収集、スクレイプ設定、レコーディングルールの完全ガイド。

## 目的

インフラストラクチャとアプリケーションの包括的なメトリクス収集、アラート、モニタリングのためのPrometheusを設定します。

## 使用タイミング

- Prometheusモニタリングのセットアップ
- メトリクススクレイピングの設定
- レコーディングルールの作成
- アラートルールの設計
- サービスディスカバリーの実装

## Prometheusアーキテクチャ

```
┌──────────────┐
│ Applications │ ← クライアントライブラリで計装
└──────┬───────┘
       │ /metricsエンドポイント
       ↓
┌──────────────┐
│  Prometheus  │ ← 定期的にメトリクスをスクレイプ
│    Server    │
└──────┬───────┘
       │
       ├─→ AlertManager（アラート）
       ├─→ Grafana（可視化）
       └─→ 長期ストレージ（Thanos/Cortex）
```

## インストール

### Helmを使用したKubernetes

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set prometheus.prometheusSpec.retention=30d \
  --set prometheus.prometheusSpec.storageVolumeSize=50Gi
```

### Docker Compose

```yaml
version: '3.8'
services:
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus-data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=30d'

volumes:
  prometheus-data:
```

## 設定ファイル

**prometheus.yml:**
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: 'production'
    region: 'us-west-2'

# Alertmanager設定
alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

# ルールファイルの読み込み
rule_files:
  - /etc/prometheus/rules/*.yml

# スクレイプ設定
scrape_configs:
  # Prometheus自身
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  # Nodeエクスポーター
  - job_name: 'node-exporter'
    static_configs:
      - targets:
        - 'node1:9100'
        - 'node2:9100'
        - 'node3:9100'
    relabel_configs:
      - source_labels: [__address__]
        target_label: instance
        regex: '([^:]+)(:[0-9]+)?'
        replacement: '${1}'

  # アノテーション付きKubernetes Pod
  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
        action: replace
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $1:$2
        target_label: __address__
      - source_labels: [__meta_kubernetes_namespace]
        action: replace
        target_label: namespace
      - source_labels: [__meta_kubernetes_pod_name]
        action: replace
        target_label: pod

  # アプリケーションメトリクス
  - job_name: 'my-app'
    static_configs:
      - targets:
        - 'app1.example.com:9090'
        - 'app2.example.com:9090'
    metrics_path: '/metrics'
    scheme: 'https'
    tls_config:
      ca_file: /etc/prometheus/ca.crt
      cert_file: /etc/prometheus/client.crt
      key_file: /etc/prometheus/client.key
```

**参照:** `assets/prometheus.yml.template`を参照

## スクレイプ設定

### 静的ターゲット

```yaml
scrape_configs:
  - job_name: 'static-targets'
    static_configs:
      - targets: ['host1:9100', 'host2:9100']
        labels:
          env: 'production'
          region: 'us-west-2'
```

### ファイルベースのサービスディスカバリー

```yaml
scrape_configs:
  - job_name: 'file-sd'
    file_sd_configs:
      - files:
        - /etc/prometheus/targets/*.json
        - /etc/prometheus/targets/*.yml
        refresh_interval: 5m
```

**targets/production.json:**
```json
[
  {
    "targets": ["app1:9090", "app2:9090"],
    "labels": {
      "env": "production",
      "service": "api"
    }
  }
]
```

### Kubernetesサービスディスカバリー

```yaml
scrape_configs:
  - job_name: 'kubernetes-services'
    kubernetes_sd_configs:
      - role: service
    relabel_configs:
      - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scheme]
        action: replace
        target_label: __scheme__
        regex: (https?)
      - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
```

**参照:** `references/scrape-configs.md`を参照

## レコーディングルール

頻繁にクエリされる式のために事前計算されたメトリクスを作成します：

```yaml
# /etc/prometheus/rules/recording_rules.yml
groups:
  - name: api_metrics
    interval: 15s
    rules:
      # サービスごとのHTTPリクエスト率
      - record: job:http_requests:rate5m
        expr: sum by (job) (rate(http_requests_total[5m]))

      # エラー率パーセンテージ
      - record: job:http_requests_errors:rate5m
        expr: sum by (job) (rate(http_requests_total{status=~"5.."}[5m]))

      - record: job:http_requests_error_rate:percentage
        expr: |
          (job:http_requests_errors:rate5m / job:http_requests:rate5m) * 100

      # P95レイテンシ
      - record: job:http_request_duration:p95
        expr: |
          histogram_quantile(0.95,
            sum by (job, le) (rate(http_request_duration_seconds_bucket[5m]))
          )

  - name: resource_metrics
    interval: 30s
    rules:
      # CPU使用率パーセンテージ
      - record: instance:node_cpu:utilization
        expr: |
          100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

      # メモリ使用率パーセンテージ
      - record: instance:node_memory:utilization
        expr: |
          100 - ((node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100)

      # ディスク使用率パーセンテージ
      - record: instance:node_disk:utilization
        expr: |
          100 - ((node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100)
```

**参照:** `references/recording-rules.md`を参照

## アラートルール

```yaml
# /etc/prometheus/rules/alert_rules.yml
groups:
  - name: availability
    interval: 30s
    rules:
      - alert: ServiceDown
        expr: up{job="my-app"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Service {{ $labels.instance }} is down"
          description: "{{ $labels.job }} has been down for more than 1 minute"

      - alert: HighErrorRate
        expr: job:http_requests_error_rate:percentage > 5
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High error rate for {{ $labels.job }}"
          description: "Error rate is {{ $value }}% (threshold: 5%)"

      - alert: HighLatency
        expr: job:http_request_duration:p95 > 1
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High latency for {{ $labels.job }}"
          description: "P95 latency is {{ $value }}s (threshold: 1s)"

  - name: resources
    interval: 1m
    rules:
      - alert: HighCPUUsage
        expr: instance:node_cpu:utilization > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage on {{ $labels.instance }}"
          description: "CPU usage is {{ $value }}%"

      - alert: HighMemoryUsage
        expr: instance:node_memory:utilization > 85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage on {{ $labels.instance }}"
          description: "Memory usage is {{ $value }}%"

      - alert: DiskSpaceLow
        expr: instance:node_disk:utilization > 90
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Low disk space on {{ $labels.instance }}"
          description: "Disk usage is {{ $value }}%"
```

## 検証

```bash
# 設定の検証
promtool check config prometheus.yml

# ルールの検証
promtool check rules /etc/prometheus/rules/*.yml

# クエリのテスト
promtool query instant http://localhost:9090 'up'
```

**参照:** `scripts/validate-prometheus.sh`を参照

## ベストプラクティス

1. **メトリクスに一貫した命名を使用**（prefix_name_unit）
2. **適切なスクレイプ間隔を設定**（通常15-60秒）
3. **高コストなクエリにはレコーディングルールを使用**
4. **高可用性を実装**（複数のPrometheusインスタンス）
5. **ストレージ容量に基づいて保持期間を設定**
6. **メトリクスのクリーンアップにリラベリングを使用**
7. **Prometheus自身を監視**
8. **大規模デプロイにはフェデレーションを実装**
9. **長期ストレージにThanos/Cortexを使用**
10. **カスタムメトリクスを文書化**

## トラブルシューティング

**スクレイプターゲットを確認:**
```bash
curl http://localhost:9090/api/v1/targets
```

**設定を確認:**
```bash
curl http://localhost:9090/api/v1/status/config
```

**クエリをテスト:**
```bash
curl 'http://localhost:9090/api/v1/query?query=up'
```

## リファレンスファイル

- `assets/prometheus.yml.template` - 完全な設定テンプレート
- `references/scrape-configs.md` - スクレイプ設定パターン
- `references/recording-rules.md` - レコーディングルールの例
- `scripts/validate-prometheus.sh` - 検証スクリプト

## 関連スキル

- `grafana-dashboards` - 可視化のため
- `slo-implementation` - SLOモニタリングのため
- `distributed-tracing` - リクエストトレーシングのため
