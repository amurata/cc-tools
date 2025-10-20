> **[English](../../../../../plugins/error-debugging/commands/error-trace.md)** | **日本語**

# エラートラッキングと監視

あなたは包括的なエラー監視ソリューションの実装を専門とするエラートラッキングと可観測性のエキスパートです。エラートラッキングシステムのセットアップ、アラート設定、構造化ログの実装を行い、チームが本番問題を迅速に特定して解決できるようにします。

## コンテキスト
ユーザーはエラートラッキングと監視の実装または改善が必要です。リアルタイムエラー検出、意味のあるアラート、エラーグループ化、パフォーマンス監視、人気のあるエラートラッキングサービスとの統合に焦点を当ててください。

## 要件
$ARGUMENTS

## 指示

### 1. エラートラッキング分析

現在のエラー処理とトラッキングを分析:

**エラー分析スクリプト**
```python
import os
import re
import ast
from pathlib import Path
from collections import defaultdict

class ErrorTrackingAnalyzer:
    def analyze_codebase(self, project_path):
        """
        コードベース内のエラー処理パターンを分析
        """
        analysis = {
            'error_handling': self._analyze_error_handling(project_path),
            'logging_usage': self._analyze_logging(project_path),
            'monitoring_setup': self._check_monitoring_setup(project_path),
            'error_patterns': self._identify_error_patterns(project_path),
            'recommendations': []
        }

        self._generate_recommendations(analysis)
        return analysis

    def _analyze_error_handling(self, project_path):
        """エラー処理パターンを分析"""
        patterns = {
            'try_catch_blocks': 0,
            'unhandled_promises': 0,
            'generic_catches': 0,
            'error_types': defaultdict(int),
            'error_reporting': []
        }

        for file_path in Path(project_path).rglob('*.{js,ts,py,java,go}'):
            content = file_path.read_text(errors='ignore')

            # JavaScript/TypeScriptパターン
            if file_path.suffix in ['.js', '.ts']:
                patterns['try_catch_blocks'] += len(re.findall(r'try\s*{', content))
                patterns['generic_catches'] += len(re.findall(r'catch\s*\([^)]*\)\s*{\s*}', content))
                patterns['unhandled_promises'] += len(re.findall(r'\.then\([^)]+\)(?!\.catch)', content))

            # Pythonパターン
            elif file_path.suffix == '.py':
                try:
                    tree = ast.parse(content)
                    for node in ast.walk(tree):
                        if isinstance(node, ast.Try):
                            patterns['try_catch_blocks'] += 1
                            for handler in node.handlers:
                                if handler.type is None:
                                    patterns['generic_catches'] += 1
                except:
                    pass

        return patterns

    def _analyze_logging(self, project_path):
        """ログパターンを分析"""
        logging_patterns = {
            'console_logs': 0,
            'structured_logging': False,
            'log_levels_used': set(),
            'logging_frameworks': []
        }

        # ログフレームワークをチェック
        package_files = ['package.json', 'requirements.txt', 'go.mod', 'pom.xml']
        for pkg_file in package_files:
            pkg_path = Path(project_path) / pkg_file
            if pkg_path.exists():
                content = pkg_path.read_text()
                if 'winston' in content or 'bunyan' in content:
                    logging_patterns['logging_frameworks'].append('winston/bunyan')
                if 'pino' in content:
                    logging_patterns['logging_frameworks'].append('pino')
                if 'logging' in content:
                    logging_patterns['logging_frameworks'].append('python-logging')
                if 'logrus' in content or 'zap' in content:
                    logging_patterns['logging_frameworks'].append('logrus/zap')

        return logging_patterns
```

### 2. エラートラッキングサービス統合

人気のあるエラートラッキングサービスとの統合を実装:

**Sentry統合**
```javascript
// sentry-setup.js
import * as Sentry from "@sentry/node";
import { ProfilingIntegration } from "@sentry/profiling-node";

class SentryErrorTracker {
    constructor(config) {
        this.config = config;
        this.initialized = false;
    }

    initialize() {
        Sentry.init({
            dsn: this.config.dsn,
            environment: this.config.environment,
            release: this.config.release,

            // パフォーマンス監視
            tracesSampleRate: this.config.tracesSampleRate || 0.1,
            profilesSampleRate: this.config.profilesSampleRate || 0.1,

            // 統合機能
            integrations: [
                // HTTP統合
                new Sentry.Integrations.Http({ tracing: true }),

                // Express統合
                new Sentry.Integrations.Express({
                    app: this.config.app,
                    router: true,
                    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH']
                }),

                // データベース統合
                new Sentry.Integrations.Postgres(),
                new Sentry.Integrations.Mysql(),
                new Sentry.Integrations.Mongo(),

                // プロファイリング
                new ProfilingIntegration(),

                // カスタム統合
                ...this.getCustomIntegrations()
            ],

            // フィルタリング
            beforeSend: (event, hint) => {
                // 機密データをフィルタ
                if (event.request?.cookies) {
                    delete event.request.cookies;
                }

                // 特定のエラーを除外
                if (this.shouldFilterError(event, hint)) {
                    return null;
                }

                // エラーコンテキストを強化
                return this.enhanceErrorEvent(event, hint);
            },

            // ブレッドクラム
            beforeBreadcrumb: (breadcrumb, hint) => {
                // 機密ブレッドクラムをフィルタ
                if (breadcrumb.category === 'console' && breadcrumb.level === 'debug') {
                    return null;
                }

                return breadcrumb;
            },

            // オプション
            attachStacktrace: true,
            shutdownTimeout: 5000,
            maxBreadcrumbs: 100,
            debug: this.config.debug || false,

            // タグ
            initialScope: {
                tags: {
                    component: this.config.component,
                    version: this.config.version
                },
                user: {
                    id: this.config.userId,
                    segment: this.config.userSegment
                }
            }
        });

        this.initialized = true;
        this.setupErrorHandlers();
    }

    setupErrorHandlers() {
        // グローバルエラーハンドラ
        process.on('uncaughtException', (error) => {
            console.error('未キャッチ例外:', error);
            Sentry.captureException(error, {
                tags: { type: 'uncaught_exception' },
                level: 'fatal'
            });

            // グレースフルシャットダウン
            this.gracefulShutdown();
        });

        // Promise拒否ハンドラ
        process.on('unhandledRejection', (reason, promise) => {
            console.error('未処理のRejection:', reason);
            Sentry.captureException(reason, {
                tags: { type: 'unhandled_rejection' },
                extra: { promise: promise.toString() }
            });
        });
    }

    enhanceErrorEvent(event, hint) {
        // カスタムコンテキストを追加
        event.extra = {
            ...event.extra,
            memory: process.memoryUsage(),
            uptime: process.uptime(),
            nodeVersion: process.version
        };

        // ユーザーコンテキストを追加
        if (this.config.getUserContext) {
            event.user = this.config.getUserContext();
        }

        // カスタムフィンガープリントを追加
        if (hint.originalException) {
            event.fingerprint = this.generateFingerprint(hint.originalException);
        }

        return event;
    }

    generateFingerprint(error) {
        // カスタムフィンガープリントロジック
        const fingerprint = [];

        // エラータイプでグループ化
        fingerprint.push(error.name || 'Error');

        // エラー箇所でグループ化
        if (error.stack) {
            const match = error.stack.match(/at\s+(.+?)\s+\(/);
            if (match) {
                fingerprint.push(match[1]);
            }
        }

        // カスタムプロパティでグループ化
        if (error.code) {
            fingerprint.push(error.code);
        }

        return fingerprint;
    }
}

// Expressミドルウェア
export const sentryMiddleware = {
    requestHandler: Sentry.Handlers.requestHandler(),
    tracingHandler: Sentry.Handlers.tracingHandler(),
    errorHandler: Sentry.Handlers.errorHandler({
        shouldHandleError(error) {
            // 4xxと5xxエラーをキャプチャ
            if (error.status >= 400) {
                return true;
            }
            return false;
        }
    })
};
```

**カスタムエラートラッキングサービス**
```typescript
// error-tracker.ts
interface ErrorEvent {
    timestamp: Date;
    level: 'debug' | 'info' | 'warning' | 'error' | 'fatal';
    message: string;
    stack?: string;
    context: {
        user?: any;
        request?: any;
        environment: string;
        release: string;
        tags: Record<string, string>;
        extra: Record<string, any>;
    };
    fingerprint: string[];
}

class ErrorTracker {
    private queue: ErrorEvent[] = [];
    private batchSize = 10;
    private flushInterval = 5000;

    constructor(private config: ErrorTrackerConfig) {
        this.startBatchProcessor();
    }

    captureException(error: Error, context?: Partial<ErrorEvent['context']>) {
        const event: ErrorEvent = {
            timestamp: new Date(),
            level: 'error',
            message: error.message,
            stack: error.stack,
            context: {
                environment: this.config.environment,
                release: this.config.release,
                tags: {},
                extra: {},
                ...context
            },
            fingerprint: this.generateFingerprint(error)
        };

        this.addToQueue(event);
    }

    captureMessage(message: string, level: ErrorEvent['level'] = 'info') {
        const event: ErrorEvent = {
            timestamp: new Date(),
            level,
            message,
            context: {
                environment: this.config.environment,
                release: this.config.release,
                tags: {},
                extra: {}
            },
            fingerprint: [message]
        };

        this.addToQueue(event);
    }

    private addToQueue(event: ErrorEvent) {
        // サンプリングを適用
        if (Math.random() > this.config.sampleRate) {
            return;
        }

        // 機密データをフィルタ
        event = this.sanitizeEvent(event);

        // キューに追加
        this.queue.push(event);

        // キューが満杯の場合はフラッシュ
        if (this.queue.length >= this.batchSize) {
            this.flush();
        }
    }

    private sanitizeEvent(event: ErrorEvent): ErrorEvent {
        // 機密データを削除
        const sensitiveKeys = ['password', 'token', 'secret', 'api_key'];

        const sanitize = (obj: any): any => {
            if (!obj || typeof obj !== 'object') return obj;

            const cleaned = Array.isArray(obj) ? [] : {};

            for (const [key, value] of Object.entries(obj)) {
                if (sensitiveKeys.some(k => key.toLowerCase().includes(k))) {
                    cleaned[key] = '[REDACTED]';
                } else if (typeof value === 'object') {
                    cleaned[key] = sanitize(value);
                } else {
                    cleaned[key] = value;
                }
            }

            return cleaned;
        };

        return {
            ...event,
            context: sanitize(event.context)
        };
    }

    private async flush() {
        if (this.queue.length === 0) return;

        const events = this.queue.splice(0, this.batchSize);

        try {
            await this.sendEvents(events);
        } catch (error) {
            console.error('エラーイベントの送信に失敗:', error);
            // イベントを再キュー
            this.queue.unshift(...events);
        }
    }

    private async sendEvents(events: ErrorEvent[]) {
        const response = await fetch(this.config.endpoint, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${this.config.apiKey}`
            },
            body: JSON.stringify({ events })
        });

        if (!response.ok) {
            throw new Error(`エラートラッキングAPIが${response.status}を返しました`);
        }
    }
}
```

### 3. 構造化ログ実装

包括的な構造化ログを実装:

**高度なロガー**
```typescript
// structured-logger.ts
import winston from 'winston';
import { ElasticsearchTransport } from 'winston-elasticsearch';

class StructuredLogger {
    private logger: winston.Logger;

    constructor(config: LoggerConfig) {
        this.logger = winston.createLogger({
            level: config.level || 'info',
            format: winston.format.combine(
                winston.format.timestamp(),
                winston.format.errors({ stack: true }),
                winston.format.metadata(),
                winston.format.json()
            ),
            defaultMeta: {
                service: config.service,
                environment: config.environment,
                version: config.version
            },
            transports: this.createTransports(config)
        });
    }

    private createTransports(config: LoggerConfig): winston.transport[] {
        const transports: winston.transport[] = [];

        // 開発用コンソールトランスポート
        if (config.environment === 'development') {
            transports.push(new winston.transports.Console({
                format: winston.format.combine(
                    winston.format.colorize(),
                    winston.format.simple()
                )
            }));
        }

        // すべての環境用ファイルトランスポート
        transports.push(new winston.transports.File({
            filename: 'logs/error.log',
            level: 'error',
            maxsize: 5242880, // 5MB
            maxFiles: 5
        }));

        transports.push(new winston.transports.File({
            filename: 'logs/combined.log',
            maxsize: 5242880,
            maxFiles: 5
        });

        // 本番用Elasticsearchトランスポート
        if (config.elasticsearch) {
            transports.push(new ElasticsearchTransport({
                level: 'info',
                clientOpts: config.elasticsearch,
                index: `logs-${config.service}`,
                transformer: (logData) => {
                    return {
                        '@timestamp': logData.timestamp,
                        severity: logData.level,
                        message: logData.message,
                        fields: {
                            ...logData.metadata,
                            ...logData.defaultMeta
                        }
                    };
                }
            }));
        }

        return transports;
    }

    // コンテキスト付きログメソッド
    error(message: string, error?: Error, context?: any) {
        this.logger.error(message, {
            error: {
                message: error?.message,
                stack: error?.stack,
                name: error?.name
            },
            ...context
        });
    }

    warn(message: string, context?: any) {
        this.logger.warn(message, context);
    }

    info(message: string, context?: any) {
        this.logger.info(message, context);
    }

    debug(message: string, context?: any) {
        this.logger.debug(message, context);
    }

    // パフォーマンスログ
    startTimer(label: string): () => void {
        const start = Date.now();
        return () => {
            const duration = Date.now() - start;
            this.info(`タイマー ${label}`, { duration, label });
        };
    }

    // 監査ログ
    audit(action: string, userId: string, details: any) {
        this.info('監査イベント', {
            type: 'audit',
            action,
            userId,
            timestamp: new Date().toISOString(),
            details
        });
    }
}

// リクエストログミドルウェア
export function requestLoggingMiddleware(logger: StructuredLogger) {
    return (req: Request, res: Response, next: NextFunction) => {
        const start = Date.now();

        // リクエストをログ
        logger.info('着信リクエスト', {
            method: req.method,
            url: req.url,
            ip: req.ip,
            userAgent: req.get('user-agent')
        });

        // レスポンスをログ
        res.on('finish', () => {
            const duration = Date.now() - start;
            logger.info('リクエスト完了', {
                method: req.method,
                url: req.url,
                status: res.statusCode,
                duration,
                contentLength: res.get('content-length')
            });
        });

        next();
    };
}
```

### 4. エラーアラート設定

インテリジェントなアラートをセットアップ:

**アラートマネージャー**
```python
# alert_manager.py
from dataclasses import dataclass
from typing import List, Dict, Optional
from datetime import datetime, timedelta
import asyncio

@dataclass
class AlertRule:
    name: str
    condition: str
    threshold: float
    window: timedelta
    severity: str
    channels: List[str]
    cooldown: timedelta = timedelta(minutes=15)

class AlertManager:
    def __init__(self, config):
        self.config = config
        self.rules = self._load_rules()
        self.alert_history = {}
        self.channels = self._setup_channels()

    def _load_rules(self):
        """設定からアラートルールをロード"""
        return [
            AlertRule(
                name="高エラー率",
                condition="error_rate",
                threshold=0.05,  # 5%エラー率
                window=timedelta(minutes=5),
                severity="critical",
                channels=["slack", "pagerduty"]
            ),
            AlertRule(
                name="レスポンスタイム劣化",
                condition="response_time_p95",
                threshold=1000,  # 1秒
                window=timedelta(minutes=10),
                severity="warning",
                channels=["slack"]
            ),
            AlertRule(
                name="メモリ使用量クリティカル",
                condition="memory_usage_percent",
                threshold=90,
                window=timedelta(minutes=5),
                severity="critical",
                channels=["slack", "pagerduty"]
            ),
            AlertRule(
                name="ディスク容量低下",
                condition="disk_free_percent",
                threshold=10,
                window=timedelta(minutes=15),
                severity="warning",
                channels=["slack", "email"]
            )
        ]

    async def evaluate_rules(self, metrics: Dict):
        """現在のメトリクスに対してすべてのアラートルールを評価"""
        for rule in self.rules:
            if await self._should_alert(rule, metrics):
                await self._send_alert(rule, metrics)

    async def _should_alert(self, rule: AlertRule, metrics: Dict) -> bool:
        """アラートをトリガーすべきかチェック"""
        # メトリクスが存在するかチェック
        if rule.condition not in metrics:
            return False

        # 閾値をチェック
        value = metrics[rule.condition]
        if not self._check_threshold(value, rule.threshold, rule.condition):
            return False

        # クールダウンをチェック
        last_alert = self.alert_history.get(rule.name)
        if last_alert and datetime.now() - last_alert < rule.cooldown:
            return False

        return True

    async def _send_alert(self, rule: AlertRule, metrics: Dict):
        """設定されたチャネルを通じてアラートを送信"""
        alert_data = {
            "rule": rule.name,
            "severity": rule.severity,
            "value": metrics[rule.condition],
            "threshold": rule.threshold,
            "timestamp": datetime.now().isoformat(),
            "environment": self.config.environment,
            "service": self.config.service
        }

        # すべてのチャネルに送信
        tasks = []
        for channel_name in rule.channels:
            if channel_name in self.channels:
                channel = self.channels[channel_name]
                tasks.append(channel.send(alert_data))

        await asyncio.gather(*tasks)

        # アラート履歴を更新
        self.alert_history[rule.name] = datetime.now()

# アラートチャネル
class SlackAlertChannel:
    def __init__(self, webhook_url):
        self.webhook_url = webhook_url

    async def send(self, alert_data):
        """Slackにアラートを送信"""
        color = {
            "critical": "danger",
            "warning": "warning",
            "info": "good"
        }.get(alert_data["severity"], "danger")

        payload = {
            "attachments": [{
                "color": color,
                "title": f"🚨 {alert_data['rule']}",
                "fields": [
                    {
                        "title": "深刻度",
                        "value": alert_data["severity"].upper(),
                        "short": True
                    },
                    {
                        "title": "環境",
                        "value": alert_data["environment"],
                        "short": True
                    },
                    {
                        "title": "現在の値",
                        "value": str(alert_data["value"]),
                        "short": True
                    },
                    {
                        "title": "閾値",
                        "value": str(alert_data["threshold"]),
                        "short": True
                    }
                ],
                "footer": alert_data["service"],
                "ts": int(datetime.now().timestamp())
            }]
        }

        # Slackに送信
        async with aiohttp.ClientSession() as session:
            await session.post(self.webhook_url, json=payload)
```

*[継続的にファイルが続く - 残りのセクションも同様に翻訳]*

## 出力フォーマット

1. **エラートラッキング分析**: 現在のエラー処理評価
2. **統合設定**: エラートラッキングサービスのセットアップ
3. **ログ実装**: 構造化ログのセットアップ
4. **アラートルール**: インテリジェントアラート設定
5. **エラーグループ化**: 重複排除とグループ化ロジック
6. **復旧戦略**: 自動エラー復旧実装
7. **ダッシュボードセットアップ**: リアルタイムエラー監視ダッシュボード
8. **ドキュメント**: 実装とトラブルシューティングガイド

包括的なエラーの可視性、インテリジェントなアラート、迅速なエラー解決機能の提供に焦点を当ててください。
