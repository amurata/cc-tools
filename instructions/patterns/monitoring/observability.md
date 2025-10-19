# Observability Patterns

観測可能性（Observability）の実装パターンとベストプラクティス。

## 三本柱: Logs, Metrics, Traces

### 構造化ロギング
```typescript
import winston from 'winston';
import { LoggingWinston } from '@google-cloud/logging-winston';

// ロガー設定
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: {
    service: 'api-service',
    version: process.env.APP_VERSION,
    environment: process.env.NODE_ENV
  },
  transports: [
    // コンソール出力（開発環境）
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.simple()
      ),
      silent: process.env.NODE_ENV === 'test'
    }),
    // ファイル出力
    new winston.transports.File({
      filename: 'logs/error.log',
      level: 'error',
      maxsize: 5242880, // 5MB
      maxFiles: 5
    }),
    new winston.transports.File({
      filename: 'logs/combined.log',
      maxsize: 5242880,
      maxFiles: 5
    })
  ]
});

// Production: Cloud Logging
if (process.env.NODE_ENV === 'production') {
  logger.add(new LoggingWinston({
    projectId: process.env.GCP_PROJECT_ID,
    keyFilename: process.env.GCP_KEY_FILE
  }));
}

// コンテキスト付きロギング
export class ContextLogger {
  constructor(private context: Record<string, any>) {}
  
  info(message: string, meta?: Record<string, any>) {
    logger.info(message, { ...this.context, ...meta });
  }
  
  error(message: string, error?: Error, meta?: Record<string, any>) {
    logger.error(message, {
      ...this.context,
      ...meta,
      error: {
        message: error?.message,
        stack: error?.stack,
        name: error?.name
      }
    });
  }
  
  child(context: Record<string, any>) {
    return new ContextLogger({ ...this.context, ...context });
  }
}

// リクエストロギングミドルウェア
export const requestLogger = (req: Request, res: Response, next: NextFunction) => {
  const requestId = crypto.randomUUID();
  const startTime = Date.now();
  
  // リクエスト情報をログ
  const requestLogger = new ContextLogger({
    requestId,
    method: req.method,
    path: req.path,
    ip: req.ip,
    userAgent: req.get('user-agent')
  });
  
  req.logger = requestLogger;
  
  // レスポンス時にログ
  res.on('finish', () => {
    const duration = Date.now() - startTime;
    requestLogger.info('Request completed', {
      statusCode: res.statusCode,
      duration,
      contentLength: res.get('content-length')
    });
  });
  
  next();
};
```

### メトリクス収集
```typescript
import { register, Counter, Histogram, Gauge, Summary } from 'prom-client';

// メトリクス定義
const httpRequestsTotal = new Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status']
});

const httpRequestDuration = new Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status'],
  buckets: [0.1, 0.5, 1, 2, 5]
});

const activeConnections = new Gauge({
  name: 'active_connections',
  help: 'Number of active connections'
});

const dbQueryDuration = new Summary({
  name: 'db_query_duration_seconds',
  help: 'Duration of database queries',
  labelNames: ['operation', 'table'],
  percentiles: [0.5, 0.9, 0.95, 0.99]
});

// カスタムメトリクス
const businessMetrics = {
  ordersCreated: new Counter({
    name: 'orders_created_total',
    help: 'Total number of orders created',
    labelNames: ['payment_method', 'region']
  }),
  
  cartValue: new Histogram({
    name: 'cart_value_dollars',
    help: 'Shopping cart value in dollars',
    buckets: [10, 50, 100, 500, 1000, 5000]
  }),
  
  userRegistrations: new Counter({
    name: 'user_registrations_total',
    help: 'Total number of user registrations',
    labelNames: ['source', 'plan']
  })
};

// メトリクスミドルウェア
export const metricsMiddleware = (req: Request, res: Response, next: NextFunction) => {
  const start = Date.now();
  
  activeConnections.inc();
  
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    const route = req.route?.path || req.path;
    
    httpRequestsTotal.inc({
      method: req.method,
      route,
      status: res.statusCode.toString()
    });
    
    httpRequestDuration.observe(
      { method: req.method, route, status: res.statusCode.toString() },
      duration
    );
    
    activeConnections.dec();
  });
  
  next();
};

// メトリクスエンドポイント
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});
```

### 分散トレーシング
```typescript
import { NodeTracerProvider } from '@opentelemetry/sdk-trace-node';
import { Resource } from '@opentelemetry/resources';
import { SemanticResourceAttributes } from '@opentelemetry/semantic-conventions';
import { JaegerExporter } from '@opentelemetry/exporter-jaeger';
import { BatchSpanProcessor } from '@opentelemetry/sdk-trace-base';
import { registerInstrumentations } from '@opentelemetry/instrumentation';
import { HttpInstrumentation } from '@opentelemetry/instrumentation-http';
import { ExpressInstrumentation } from '@opentelemetry/instrumentation-express';

// トレーサー設定
const provider = new NodeTracerProvider({
  resource: new Resource({
    [SemanticResourceAttributes.SERVICE_NAME]: 'api-service',
    [SemanticResourceAttributes.SERVICE_VERSION]: process.env.APP_VERSION,
    [SemanticResourceAttributes.DEPLOYMENT_ENVIRONMENT]: process.env.NODE_ENV
  })
});

// Jaeger エクスポーター
const jaegerExporter = new JaegerExporter({
  endpoint: process.env.JAEGER_ENDPOINT || 'http://localhost:14268/api/traces'
});

provider.addSpanProcessor(new BatchSpanProcessor(jaegerExporter));
provider.register();

// 自動インストルメンテーション
registerInstrumentations({
  instrumentations: [
    new HttpInstrumentation({
      requestHook: (span, request) => {
        span.setAttributes({
          'http.request.body': JSON.stringify(request.body),
          'http.request.headers': JSON.stringify(request.headers)
        });
      }
    }),
    new ExpressInstrumentation(),
    new DatabaseInstrumentation()
  ]
});

// カスタムスパン
import { trace, context, SpanStatusCode } from '@opentelemetry/api';

const tracer = trace.getTracer('api-service');

export async function processOrder(orderId: string) {
  const span = tracer.startSpan('process-order', {
    attributes: {
      'order.id': orderId
    }
  });
  
  try {
    // 子スパン作成
    await context.with(trace.setSpan(context.active(), span), async () => {
      const validationSpan = tracer.startSpan('validate-order');
      await validateOrder(orderId);
      validationSpan.end();
      
      const paymentSpan = tracer.startSpan('process-payment');
      await processPayment(orderId);
      paymentSpan.end();
      
      const shipmentSpan = tracer.startSpan('create-shipment');
      await createShipment(orderId);
      shipmentSpan.end();
    });
    
    span.setStatus({ code: SpanStatusCode.OK });
  } catch (error) {
    span.recordException(error);
    span.setStatus({
      code: SpanStatusCode.ERROR,
      message: error.message
    });
    throw error;
  } finally {
    span.end();
  }
}
```

## エラートラッキング

### Sentry統合
```typescript
import * as Sentry from '@sentry/node';
import { ProfilingIntegration } from '@sentry/profiling-node';

// Sentry初期化
Sentry.init({
  dsn: process.env.SENTRY_DSN,
  environment: process.env.NODE_ENV,
  release: process.env.APP_VERSION,
  integrations: [
    new Sentry.Integrations.Http({ tracing: true }),
    new Sentry.Integrations.Express({ app }),
    new ProfilingIntegration()
  ],
  tracesSampleRate: process.env.NODE_ENV === 'production' ? 0.1 : 1.0,
  profilesSampleRate: 0.1,
  
  beforeSend(event, hint) {
    // センシティブ情報のフィルタリング
    if (event.request) {
      delete event.request.cookies;
      delete event.request.headers?.authorization;
    }
    return event;
  }
});

// エラーハンドリング
app.use(Sentry.Handlers.requestHandler());
app.use(Sentry.Handlers.tracingHandler());

// カスタムエラー報告
export function reportError(error: Error, context?: Record<string, any>) {
  Sentry.withScope((scope) => {
    if (context) {
      scope.setContext('additional', context);
    }
    scope.setLevel('error');
    Sentry.captureException(error);
  });
}

// パフォーマンス監視
export function measurePerformance<T>(
  name: string,
  operation: () => Promise<T>
): Promise<T> {
  const transaction = Sentry.startTransaction({
    op: 'function',
    name
  });
  
  Sentry.getCurrentHub().configureScope(scope => scope.setSpan(transaction));
  
  return operation()
    .then(result => {
      transaction.setStatus('ok');
      return result;
    })
    .catch(error => {
      transaction.setStatus('internal_error');
      throw error;
    })
    .finally(() => {
      transaction.finish();
    });
}
```

## アプリケーションパフォーマンス監視 (APM)

### カスタムAPM実装
```typescript
interface PerformanceMetric {
  name: string;
  value: number;
  unit: string;
  tags: Record<string, string>;
  timestamp: Date;
}

class APMCollector {
  private metrics: PerformanceMetric[] = [];
  private intervals: Map<string, NodeJS.Timeout> = new Map();
  
  // CPU使用率監視
  startCPUMonitoring() {
    const interval = setInterval(() => {
      const cpuUsage = process.cpuUsage();
      this.recordMetric('cpu.usage', cpuUsage.user + cpuUsage.system, 'microseconds');
    }, 10000);
    
    this.intervals.set('cpu', interval);
  }
  
  // メモリ使用量監視
  startMemoryMonitoring() {
    const interval = setInterval(() => {
      const memUsage = process.memoryUsage();
      this.recordMetric('memory.heap.used', memUsage.heapUsed, 'bytes');
      this.recordMetric('memory.heap.total', memUsage.heapTotal, 'bytes');
      this.recordMetric('memory.rss', memUsage.rss, 'bytes');
      this.recordMetric('memory.external', memUsage.external, 'bytes');
    }, 10000);
    
    this.intervals.set('memory', interval);
  }
  
  // イベントループ監視
  startEventLoopMonitoring() {
    let lastCheck = Date.now();
    
    const interval = setInterval(() => {
      const now = Date.now();
      const delay = now - lastCheck - 1000;
      this.recordMetric('eventloop.delay', Math.max(0, delay), 'ms');
      lastCheck = now;
    }, 1000);
    
    this.intervals.set('eventloop', interval);
  }
  
  recordMetric(name: string, value: number, unit: string, tags: Record<string, string> = {}) {
    this.metrics.push({
      name,
      value,
      unit,
      tags: {
        ...tags,
        hostname: os.hostname(),
        pid: process.pid.toString()
      },
      timestamp: new Date()
    });
    
    // バッチ送信
    if (this.metrics.length >= 100) {
      this.flush();
    }
  }
  
  async flush() {
    if (this.metrics.length === 0) return;
    
    const batch = this.metrics.splice(0, this.metrics.length);
    
    try {
      await fetch(process.env.METRICS_ENDPOINT!, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(batch)
      });
    } catch (error) {
      console.error('Failed to send metrics:', error);
      // メトリクスを戻す（再試行のため）
      this.metrics.unshift(...batch);
    }
  }
  
  stop() {
    for (const interval of this.intervals.values()) {
      clearInterval(interval);
    }
    this.intervals.clear();
    this.flush();
  }
}

// APM初期化
const apm = new APMCollector();
apm.startCPUMonitoring();
apm.startMemoryMonitoring();
apm.startEventLoopMonitoring();

// グレースフルシャットダウン
process.on('SIGTERM', () => {
  apm.stop();
});
```

## ダッシュボード設計

### Grafanaダッシュボード
```json
{
  "dashboard": {
    "title": "Application Monitoring",
    "panels": [
      {
        "title": "Request Rate",
        "targets": [
          {
            "expr": "rate(http_requests_total[5m])",
            "legendFormat": "{{method}} {{route}}"
          }
        ],
        "type": "graph"
      },
      {
        "title": "Response Time (p95)",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))",
            "legendFormat": "95th percentile"
          }
        ],
        "type": "graph"
      },
      {
        "title": "Error Rate",
        "targets": [
          {
            "expr": "rate(http_requests_total{status=~\"5..\"}[5m])",
            "legendFormat": "5xx errors"
          },
          {
            "expr": "rate(http_requests_total{status=~\"4..\"}[5m])",
            "legendFormat": "4xx errors"
          }
        ],
        "type": "graph"
      },
      {
        "title": "Database Query Performance",
        "targets": [
          {
            "expr": "db_query_duration_seconds",
            "legendFormat": "{{operation}} on {{table}}"
          }
        ],
        "type": "heatmap"
      }
    ]
  }
}
```

## アラート設定

### Prometheusアラートルール
```yaml
groups:
  - name: application
    rules:
      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate detected"
          description: "Error rate is {{ $value | humanizePercentage }} for {{ $labels.instance }}"
      
      - alert: SlowResponseTime
        expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 2
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Slow response time"
          description: "95th percentile response time is {{ $value }}s"
      
      - alert: HighMemoryUsage
        expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes > 0.9
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage"
          description: "Memory usage is {{ $value | humanizePercentage }}"
```

## チェックリスト
- [ ] 構造化ロギング実装
- [ ] メトリクス収集設定
- [ ] 分散トレーシング導入
- [ ] エラートラッキング設定
- [ ] APM ツール統合
- [ ] ダッシュボード作成
- [ ] アラートルール設定
- [ ] ログ集約設定
- [ ] パフォーマンス基準設定
- [ ] インシデント対応手順