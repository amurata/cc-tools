> **[English](../../../../../plugins/observability-monitoring/skills/distributed-tracing/SKILL.md)** | **日本語**

---
name: distributed-tracing
description: JaegerとTempoによる分散トレーシングを実装して、マイクロサービス間のリクエストを追跡し、パフォーマンスボトルネックを特定します。マイクロサービスのデバッグ、リクエストフローの分析、分散システムの可観測性実装時に使用します。
---

# 分散トレーシング

マイクロサービス間のリクエストフローの可視性のためにJaegerとTempoによる分散トレーシングを実装します。

## 目的

分散システム間でリクエストを追跡し、レイテンシ、依存関係、障害ポイントを理解します。

## 使用タイミング

- レイテンシ問題のデバッグ
- サービス依存関係の理解
- ボトルネックの特定
- エラー伝播のトレース
- リクエストパスの分析

## 分散トレーシングの概念

### トレース構造
```
トレース（リクエストID: abc123）
  ↓
スパン（frontend）[100ms]
  ↓
スパン（api-gateway）[80ms]
  ├→ スパン（auth-service）[10ms]
  └→ スパン（user-service）[60ms]
      └→ スパン（database）[40ms]
```

### 主要コンポーネント
- **トレース** - エンドツーエンドのリクエストジャーニー
- **スパン** - トレース内の単一操作
- **コンテキスト** - サービス間で伝播されるメタデータ
- **タグ** - フィルタリング用のキーバリューペア
- **ログ** - スパン内のタイムスタンプ付きイベント

## Jaegerのセットアップ

### Kubernetesデプロイ

```bash
# Jaeger Operatorのデプロイ
kubectl create namespace observability
kubectl create -f https://github.com/jaegertracing/jaeger-operator/releases/download/v1.51.0/jaeger-operator.yaml -n observability

# Jaegerインスタンスのデプロイ
kubectl apply -f - <<EOF
apiVersion: jaegertracing.io/v1
kind: Jaeger
metadata:
  name: jaeger
  namespace: observability
spec:
  strategy: production
  storage:
    type: elasticsearch
    options:
      es:
        server-urls: http://elasticsearch:9200
  ingress:
    enabled: true
EOF
```

### Docker Compose

```yaml
version: '3.8'
services:
  jaeger:
    image: jaegertracing/all-in-one:latest
    ports:
      - "5775:5775/udp"
      - "6831:6831/udp"
      - "6832:6832/udp"
      - "5778:5778"
      - "16686:16686"  # UI
      - "14268:14268"  # Collector
      - "14250:14250"  # gRPC
      - "9411:9411"    # Zipkin
    environment:
      - COLLECTOR_ZIPKIN_HOST_PORT=:9411
```

**参照:** `references/jaeger-setup.md`を参照

## アプリケーション計装

### OpenTelemetry（推奨）

#### Python（Flask）
```python
from opentelemetry import trace
from opentelemetry.exporter.jaeger.thrift import JaegerExporter
from opentelemetry.sdk.resources import SERVICE_NAME, Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from flask import Flask

# トレーサーの初期化
resource = Resource(attributes={SERVICE_NAME: "my-service"})
provider = TracerProvider(resource=resource)
processor = BatchSpanProcessor(JaegerExporter(
    agent_host_name="jaeger",
    agent_port=6831,
))
provider.add_span_processor(processor)
trace.set_tracer_provider(provider)

# Flaskの計装
app = Flask(__name__)
FlaskInstrumentor().instrument_app(app)

@app.route('/api/users')
def get_users():
    tracer = trace.get_tracer(__name__)

    with tracer.start_as_current_span("get_users") as span:
        span.set_attribute("user.count", 100)
        # ビジネスロジック
        users = fetch_users_from_db()
        return {"users": users}

def fetch_users_from_db():
    tracer = trace.get_tracer(__name__)

    with tracer.start_as_current_span("database_query") as span:
        span.set_attribute("db.system", "postgresql")
        span.set_attribute("db.statement", "SELECT * FROM users")
        # データベースクエリ
        return query_database()
```

#### Node.js（Express）
```javascript
const { NodeTracerProvider } = require('@opentelemetry/sdk-trace-node');
const { JaegerExporter } = require('@opentelemetry/exporter-jaeger');
const { BatchSpanProcessor } = require('@opentelemetry/sdk-trace-base');
const { registerInstrumentations } = require('@opentelemetry/instrumentation');
const { HttpInstrumentation } = require('@opentelemetry/instrumentation-http');
const { ExpressInstrumentation } = require('@opentelemetry/instrumentation-express');

// トレーサーの初期化
const provider = new NodeTracerProvider({
  resource: { attributes: { 'service.name': 'my-service' } }
});

const exporter = new JaegerExporter({
  endpoint: 'http://jaeger:14268/api/traces'
});

provider.addSpanProcessor(new BatchSpanProcessor(exporter));
provider.register();

// ライブラリの計装
registerInstrumentations({
  instrumentations: [
    new HttpInstrumentation(),
    new ExpressInstrumentation(),
  ],
});

const express = require('express');
const app = express();

app.get('/api/users', async (req, res) => {
  const tracer = trace.getTracer('my-service');
  const span = tracer.startSpan('get_users');

  try {
    const users = await fetchUsers();
    span.setAttributes({ 'user.count': users.length });
    res.json({ users });
  } finally {
    span.end();
  }
});
```

#### Go
```go
package main

import (
    "context"
    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/exporters/jaeger"
    "go.opentelemetry.io/otel/sdk/resource"
    sdktrace "go.opentelemetry.io/otel/sdk/trace"
    semconv "go.opentelemetry.io/otel/semconv/v1.4.0"
)

func initTracer() (*sdktrace.TracerProvider, error) {
    exporter, err := jaeger.New(jaeger.WithCollectorEndpoint(
        jaeger.WithEndpoint("http://jaeger:14268/api/traces"),
    ))
    if err != nil {
        return nil, err
    }

    tp := sdktrace.NewTracerProvider(
        sdktrace.WithBatcher(exporter),
        sdktrace.WithResource(resource.NewWithAttributes(
            semconv.SchemaURL,
            semconv.ServiceNameKey.String("my-service"),
        )),
    )

    otel.SetTracerProvider(tp)
    return tp, nil
}

func getUsers(ctx context.Context) ([]User, error) {
    tracer := otel.Tracer("my-service")
    ctx, span := tracer.Start(ctx, "get_users")
    defer span.End()

    span.SetAttributes(attribute.String("user.filter", "active"))

    users, err := fetchUsersFromDB(ctx)
    if err != nil {
        span.RecordError(err)
        return nil, err
    }

    span.SetAttributes(attribute.Int("user.count", len(users)))
    return users, nil
}
```

**参照:** `references/instrumentation.md`を参照

## コンテキスト伝播

### HTTPヘッダー
```
traceparent: 00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01
tracestate: congo=t61rcWkgMzE
```

### HTTPリクエストでの伝播

#### Python
```python
from opentelemetry.propagate import inject

headers = {}
inject(headers)  # トレースコンテキストを注入

response = requests.get('http://downstream-service/api', headers=headers)
```

#### Node.js
```javascript
const { propagation } = require('@opentelemetry/api');

const headers = {};
propagation.inject(context.active(), headers);

axios.get('http://downstream-service/api', { headers });
```

## Tempoのセットアップ（Grafana）

### Kubernetesデプロイ

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: tempo-config
data:
  tempo.yaml: |
    server:
      http_listen_port: 3200

    distributor:
      receivers:
        jaeger:
          protocols:
            thrift_http:
            grpc:
        otlp:
          protocols:
            http:
            grpc:

    storage:
      trace:
        backend: s3
        s3:
          bucket: tempo-traces
          endpoint: s3.amazonaws.com

    querier:
      frontend_worker:
        frontend_address: tempo-query-frontend:9095
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tempo
spec:
  replicas: 1
  template:
    spec:
      containers:
      - name: tempo
        image: grafana/tempo:latest
        args:
          - -config.file=/etc/tempo/tempo.yaml
        volumeMounts:
        - name: config
          mountPath: /etc/tempo
      volumes:
      - name: config
        configMap:
          name: tempo-config
```

**参照:** `assets/jaeger-config.yaml.template`を参照

## サンプリング戦略

### 確率的サンプリング
```yaml
# トレースの1%をサンプリング
sampler:
  type: probabilistic
  param: 0.01
```

### レート制限サンプリング
```yaml
# 最大100トレース/秒をサンプリング
sampler:
  type: ratelimiting
  param: 100
```

### 適応的サンプリング
```python
from opentelemetry.sdk.trace.sampling import ParentBased, TraceIdRatioBased

# トレースIDに基づくサンプリング（決定論的）
sampler = ParentBased(root=TraceIdRatioBased(0.01))
```

## トレース分析

### 遅いリクエストの検索

**Jaegerクエリ:**
```
service=my-service
duration > 1s
```

### エラーの検索

**Jaegerクエリ:**
```
service=my-service
error=true
tags.http.status_code >= 500
```

### サービス依存関係グラフ

Jaegerは以下を示すサービス依存関係グラフを自動生成します:
- サービス関係
- リクエスト率
- エラー率
- 平均レイテンシ

## ベストプラクティス

1. **適切にサンプリング**（本番環境で1-10%）
2. **意味のあるタグを追加**（user_id、request_id）
3. **すべてのサービス境界でコンテキストを伝播**
4. **スパンで例外をログ**
5. **操作に一貫した命名を使用**
6. **トレーシングのオーバーヘッドを監視**（CPU影響<1%）
7. **トレースエラーのアラートを設定**
8. **分散コンテキストを実装**（バゲージ）
9. **重要なマイルストーンにスパンイベントを使用**
10. **計装標準を文書化**

## ロギングとの統合

### 相関ログ
```python
import logging
from opentelemetry import trace

logger = logging.getLogger(__name__)

def process_request():
    span = trace.get_current_span()
    trace_id = span.get_span_context().trace_id

    logger.info(
        "Processing request",
        extra={"trace_id": format(trace_id, '032x')}
    )
```

## トラブルシューティング

**トレースが表示されない:**
- コレクターエンドポイントを確認
- ネットワーク接続を検証
- サンプリング設定を確認
- アプリケーションログをレビュー

**高レイテンシオーバーヘッド:**
- サンプリングレートを削減
- バッチスパンプロセッサーを使用
- エクスポーター設定を確認

## リファレンスファイル

- `references/jaeger-setup.md` - Jaegerインストール
- `references/instrumentation.md` - 計装パターン
- `assets/jaeger-config.yaml.template` - Jaeger設定

## 関連スキル

- `prometheus-configuration` - メトリクスのため
- `grafana-dashboards` - 可視化のため
- `slo-implementation` - レイテンシSLOのため
