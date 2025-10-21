> **[English](../../../plugins/distributed-debugging/commands/debug-trace.md)** | **日本語**

# デバッグとトレース設定

あなたは包括的なデバッグ環境、分散トレーシング、診断ツールのセットアップを専門とするデバッグエキスパートです。デバッグワークフローの設定、トレーシングソリューションの実装、開発環境と本番環境のトラブルシューティングプラクティスの確立を行います。

## コンテキスト
ユーザーは、問題を効率的に診断し、バグを追跡し、システムの動作を理解するためのデバッグとトレーシング機能のセットアップが必要です。開発者の生産性、本番デバッグ、分散トレーシング、包括的なログ戦略に焦点を当ててください。

## 要件
$ARGUMENTS

## 指示

### 1. 開発環境デバッグ

包括的なデバッグ環境をセットアップ:

**VS Codeデバッグ設定**
```json
// .vscode/launch.json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Debug Node.js App",
            "type": "node",
            "request": "launch",
            "runtimeExecutable": "node",
            "runtimeArgs": ["--inspect-brk", "--enable-source-maps"],
            "program": "${workspaceFolder}/src/index.js",
            "env": {
                "NODE_ENV": "development",
                "DEBUG": "*",
                "NODE_OPTIONS": "--max-old-space-size=4096"
            },
            "sourceMaps": true,
            "resolveSourceMapLocations": [
                "${workspaceFolder}/**",
                "!**/node_modules/**"
            ],
            "skipFiles": [
                "<node_internals>/**",
                "node_modules/**"
            ],
            "console": "integratedTerminal",
            "outputCapture": "std"
        },
        {
            "name": "Debug TypeScript",
            "type": "node",
            "request": "launch",
            "program": "${workspaceFolder}/src/index.ts",
            "preLaunchTask": "tsc: build - tsconfig.json",
            "outFiles": ["${workspaceFolder}/dist/**/*.js"],
            "sourceMaps": true,
            "smartStep": true,
            "internalConsoleOptions": "openOnSessionStart"
        },
        {
            "name": "Debug Jest Tests",
            "type": "node",
            "request": "launch",
            "program": "${workspaceFolder}/node_modules/.bin/jest",
            "args": [
                "--runInBand",
                "--no-cache",
                "--watchAll=false",
                "--detectOpenHandles"
            ],
            "console": "integratedTerminal",
            "internalConsoleOptions": "neverOpen",
            "env": {
                "NODE_ENV": "test"
            }
        },
        {
            "name": "Attach to Process",
            "type": "node",
            "request": "attach",
            "processId": "${command:PickProcess}",
            "protocol": "inspector",
            "restart": true,
            "sourceMaps": true
        }
    ],
    "compounds": [
        {
            "name": "Full Stack Debug",
            "configurations": ["Debug Backend", "Debug Frontend"],
            "stopAll": true
        }
    ]
}
```

**Chrome DevTools設定**
```javascript
// debug-helpers.js
class DebugHelper {
    constructor() {
        this.setupDevTools();
        this.setupConsoleHelpers();
        this.setupPerformanceMarkers();
    }

    setupDevTools() {
        if (typeof window !== 'undefined') {
            // デバッグ名前空間を追加
            window.DEBUG = window.DEBUG || {};

            // 重要なオブジェクトへの参照を保存
            window.DEBUG.store = () => window.__REDUX_STORE__;
            window.DEBUG.router = () => window.__ROUTER__;
            window.DEBUG.components = new Map();

            // パフォーマンスデバッグ
            window.DEBUG.measureRender = (componentName) => {
                performance.mark(`${componentName}-start`);
                return () => {
                    performance.mark(`${componentName}-end`);
                    performance.measure(
                        componentName,
                        `${componentName}-start`,
                        `${componentName}-end`
                    );
                };
            };

            // メモリデバッグ
            window.DEBUG.heapSnapshot = async () => {
                if ('memory' in performance) {
                    const snapshot = await performance.measureUserAgentSpecificMemory();
                    console.table(snapshot);
                    return snapshot;
                }
            };
        }
    }

    setupConsoleHelpers() {
        // 拡張コンソールログ
        const styles = {
            error: 'color: #ff0000; font-weight: bold;',
            warn: 'color: #ff9800; font-weight: bold;',
            info: 'color: #2196f3; font-weight: bold;',
            debug: 'color: #4caf50; font-weight: bold;',
            trace: 'color: #9c27b0; font-weight: bold;'
        };

        Object.entries(styles).forEach(([level, style]) => {
            const original = console[level];
            console[level] = function(...args) {
                if (process.env.NODE_ENV === 'development') {
                    const timestamp = new Date().toISOString();
                    original.call(console, `%c[${timestamp}] ${level.toUpperCase()}:`, style, ...args);
                }
            };
        });
    }
}

// React DevTools統合
if (process.env.NODE_ENV === 'development') {
    // React内部を公開
    window.__REACT_DEVTOOLS_GLOBAL_HOOK__ = {
        ...window.__REACT_DEVTOOLS_GLOBAL_HOOK__,
        onCommitFiberRoot: (id, root) => {
            // カスタムコミットログ
            console.debug('React commit:', root);
        }
    };
}
```

### 2. リモートデバッグセットアップ

リモートデバッグ機能を設定:

**リモートデバッグサーバー**
```javascript
// remote-debug-server.js
const inspector = require('inspector');
const WebSocket = require('ws');
const http = require('http');

class RemoteDebugServer {
    constructor(options = {}) {
        this.port = options.port || 9229;
        this.host = options.host || '0.0.0.0';
        this.wsPort = options.wsPort || 9230;
        this.sessions = new Map();
    }

    start() {
        // インスペクターを開く
        inspector.open(this.port, this.host, true);

        // リモート接続用のWebSocketサーバーを作成
        this.wss = new WebSocket.Server({ port: this.wsPort });

        this.wss.on('connection', (ws) => {
            const sessionId = this.generateSessionId();
            this.sessions.set(sessionId, ws);

            ws.on('message', (message) => {
                this.handleDebugCommand(sessionId, message);
            });

            ws.on('close', () => {
                this.sessions.delete(sessionId);
            });

            // 初期セッション情報を送信
            ws.send(JSON.stringify({
                type: 'session',
                sessionId,
                debugUrl: `chrome-devtools://devtools/bundled/inspector.html?ws=${this.host}:${this.port}`
            }));
        });

        console.log(`リモートデバッグサーバーがws://${this.host}:${this.wsPort}でリスニング中`);
    }

    handleDebugCommand(sessionId, message) {
        const command = JSON.parse(message);

        switch (command.type) {
            case 'evaluate':
                this.evaluateExpression(sessionId, command.expression);
                break;
            case 'setBreakpoint':
                this.setBreakpoint(command.file, command.line);
                break;
            case 'heapSnapshot':
                this.takeHeapSnapshot(sessionId);
                break;
            case 'profile':
                this.startProfiling(sessionId, command.duration);
                break;
        }
    }

    evaluateExpression(sessionId, expression) {
        const session = new inspector.Session();
        session.connect();

        session.post('Runtime.evaluate', {
            expression,
            generatePreview: true,
            includeCommandLineAPI: true
        }, (error, result) => {
            const ws = this.sessions.get(sessionId);
            if (ws) {
                ws.send(JSON.stringify({
                    type: 'evaluateResult',
                    result: result || error
                }));
            }
        });

        session.disconnect();
    }
}

// Dockerリモートデバッグセットアップ
FROM node:18
RUN apt-get update && apt-get install -y \
    chromium \
    gdb \
    strace \
    tcpdump \
    vim

EXPOSE 9229 9230
ENV NODE_OPTIONS="--inspect=0.0.0.0:9229"
CMD ["node", "--inspect-brk=0.0.0.0:9229", "index.js"]
```

### 3. 分散トレーシング

包括的な分散トレーシングを実装:

**OpenTelemetryセットアップ**
```javascript
// tracing.js
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { Resource } = require('@opentelemetry/resources');
const { SemanticResourceAttributes } = require('@opentelemetry/semantic-conventions');
const { JaegerExporter } = require('@opentelemetry/exporter-jaeger');
const { BatchSpanProcessor } = require('@opentelemetry/sdk-trace-base');

class TracingSystem {
    constructor(serviceName) {
        this.serviceName = serviceName;
        this.sdk = null;
    }

    initialize() {
        const jaegerExporter = new JaegerExporter({
            endpoint: process.env.JAEGER_ENDPOINT || 'http://localhost:14268/api/traces',
        });

        const resource = Resource.default().merge(
            new Resource({
                [SemanticResourceAttributes.SERVICE_NAME]: this.serviceName,
                [SemanticResourceAttributes.SERVICE_VERSION]: process.env.SERVICE_VERSION || '1.0.0',
                [SemanticResourceAttributes.DEPLOYMENT_ENVIRONMENT]: process.env.NODE_ENV || 'development',
            })
        );

        this.sdk = new NodeSDK({
            resource,
            spanProcessor: new BatchSpanProcessor(jaegerExporter),
            instrumentations: [
                getNodeAutoInstrumentations({
                    '@opentelemetry/instrumentation-fs': {
                        enabled: false, // ノイジーすぎる
                    },
                    '@opentelemetry/instrumentation-http': {
                        requestHook: (span, request) => {
                            span.setAttribute('http.request.body', JSON.stringify(request.body));
                        },
                        responseHook: (span, response) => {
                            span.setAttribute('http.response.size', response.length);
                        },
                    },
                    '@opentelemetry/instrumentation-express': {
                        requestHook: (span, req) => {
                            span.setAttribute('user.id', req.user?.id);
                            span.setAttribute('session.id', req.session?.id);
                        },
                    },
                }),
            ],
        });

        this.sdk.start();

        // グレースフルシャットダウン
        process.on('SIGTERM', () => {
            this.sdk.shutdown()
                .then(() => console.log('トレーシングを終了しました'))
                .catch((error) => console.error('トレーシング終了エラー', error))
                .finally(() => process.exit(0));
        });
    }

    // カスタムスパン作成
    createSpan(name, fn, attributes = {}) {
        const tracer = trace.getTracer(this.serviceName);
        return tracer.startActiveSpan(name, async (span) => {
            try {
                // カスタム属性を追加
                Object.entries(attributes).forEach(([key, value]) => {
                    span.setAttribute(key, value);
                });

                // 関数を実行
                const result = await fn(span);

                span.setStatus({ code: SpanStatusCode.OK });
                return result;
            } catch (error) {
                span.recordException(error);
                span.setStatus({
                    code: SpanStatusCode.ERROR,
                    message: error.message,
                });
                throw error;
            } finally {
                span.end();
            }
        });
    }
}

// 分散トレーシングミドルウェア
class TracingMiddleware {
    constructor() {
        this.tracer = trace.getTracer('http-middleware');
    }

    express() {
        return (req, res, next) => {
            const span = this.tracer.startSpan(`${req.method} ${req.path}`, {
                kind: SpanKind.SERVER,
                attributes: {
                    'http.method': req.method,
                    'http.url': req.url,
                    'http.target': req.path,
                    'http.host': req.hostname,
                    'http.scheme': req.protocol,
                    'http.user_agent': req.get('user-agent'),
                    'http.request_content_length': req.get('content-length'),
                },
            });

            // トレースコンテキストをリクエストに注入
            req.span = span;
            req.traceId = span.spanContext().traceId;

            // トレースIDをレスポンスヘッダーに追加
            res.setHeader('X-Trace-Id', req.traceId);

            // レスポンスデータをキャプチャするためにres.endをオーバーライド
            const originalEnd = res.end;
            res.end = function(...args) {
                span.setAttribute('http.status_code', res.statusCode);
                span.setAttribute('http.response_content_length', res.get('content-length'));

                if (res.statusCode >= 400) {
                    span.setStatus({
                        code: SpanStatusCode.ERROR,
                        message: `HTTP ${res.statusCode}`,
                    });
                }

                span.end();
                originalEnd.apply(res, args);
            };

            next();
        };
    }
}
```

### 4. デバッグログフレームワーク

構造化デバッグログを実装:

**高度なロガー**
```javascript
// debug-logger.js
const winston = require('winston');
const { ElasticsearchTransport } = require('winston-elasticsearch');

class DebugLogger {
    constructor(options = {}) {
        this.service = options.service || 'app';
        this.level = process.env.LOG_LEVEL || 'debug';
        this.logger = this.createLogger();
    }

    createLogger() {
        const formats = [
            winston.format.timestamp(),
            winston.format.errors({ stack: true }),
            winston.format.splat(),
            winston.format.json(),
        ];

        if (process.env.NODE_ENV === 'development') {
            formats.push(winston.format.colorize());
            formats.push(winston.format.printf(this.devFormat));
        }

        const transports = [
            new winston.transports.Console({
                level: this.level,
                handleExceptions: true,
                handleRejections: true,
            }),
        ];

        // デバッグ用のファイルトランスポートを追加
        if (process.env.DEBUG_LOG_FILE) {
            transports.push(
                new winston.transports.File({
                    filename: process.env.DEBUG_LOG_FILE,
                    level: 'debug',
                    maxsize: 10485760, // 10MB
                    maxFiles: 5,
                })
            );
        }

        // 本番用のElasticsearchを追加
        if (process.env.ELASTICSEARCH_URL) {
            transports.push(
                new ElasticsearchTransport({
                    level: 'info',
                    clientOpts: {
                        node: process.env.ELASTICSEARCH_URL,
                    },
                    index: `logs-${this.service}`,
                })
            );
        }

        return winston.createLogger({
            level: this.level,
            format: winston.format.combine(...formats),
            defaultMeta: {
                service: this.service,
                environment: process.env.NODE_ENV,
                hostname: require('os').hostname(),
                pid: process.pid,
            },
            transports,
        });
    }

    devFormat(info) {
        const { timestamp, level, message, ...meta } = info;
        const metaString = Object.keys(meta).length ?
            '\n' + JSON.stringify(meta, null, 2) : '';

        return `${timestamp} [${level}]: ${message}${metaString}`;
    }

    // デバッグ固有のメソッド
    trace(message, meta = {}) {
        const stack = new Error().stack;
        this.logger.debug(message, {
            ...meta,
            trace: stack,
            timestamp: Date.now(),
        });
    }

    timing(label, fn) {
        const start = process.hrtime.bigint();
        const result = fn();
        const end = process.hrtime.bigint();
        const duration = Number(end - start) / 1000000; // ミリ秒に変換

        this.logger.debug(`タイミング: ${label}`, {
            duration,
            unit: 'ms',
        });

        return result;
    }

    memory() {
        const usage = process.memoryUsage();
        this.logger.debug('メモリ使用量', {
            rss: `${Math.round(usage.rss / 1024 / 1024)}MB`,
            heapTotal: `${Math.round(usage.heapTotal / 1024 / 1024)}MB`,
            heapUsed: `${Math.round(usage.heapUsed / 1024 / 1024)}MB`,
            external: `${Math.round(usage.external / 1024 / 1024)}MB`,
        });
    }
}

// デバッグコンテキストマネージャー
class DebugContext {
    constructor() {
        this.contexts = new Map();
    }

    create(id, metadata = {}) {
        const context = {
            id,
            startTime: Date.now(),
            metadata,
            logs: [],
            spans: [],
        };

        this.contexts.set(id, context);
        return context;
    }

    log(contextId, level, message, data = {}) {
        const context = this.contexts.get(contextId);
        if (context) {
            context.logs.push({
                timestamp: Date.now(),
                level,
                message,
                data,
            });
        }
    }

    export(contextId) {
        const context = this.contexts.get(contextId);
        if (!context) return null;

        return {
            ...context,
            duration: Date.now() - context.startTime,
            logCount: context.logs.length,
        };
    }
}
```

### 5. ソースマップ設定

本番デバッグのためのソースマップサポートをセットアップ:

**ソースマップセットアップ**
```javascript
// webpack.config.js
module.exports = {
    mode: 'production',
    devtool: 'hidden-source-map', // ソースマップを生成するが参照しない

    output: {
        filename: '[name].[contenthash].js',
        sourceMapFilename: 'sourcemaps/[name].[contenthash].js.map',
    },

    plugins: [
        // エラー追跡サービスにソースマップをアップロード
        new SentryWebpackPlugin({
            authToken: process.env.SENTRY_AUTH_TOKEN,
            org: 'your-org',
            project: 'your-project',
            include: './dist',
            ignore: ['node_modules'],
            urlPrefix: '~/',
            release: process.env.RELEASE_VERSION,
            deleteAfterCompile: true,
        }),
    ],
};

// ランタイムソースマップサポート
require('source-map-support').install({
    environment: 'node',
    handleUncaughtExceptions: false,
    retrieveSourceMap(source) {
        // 本番用のカスタムソースマップ取得
        if (process.env.NODE_ENV === 'production') {
            const sourceMapUrl = getSourceMapUrl(source);
            if (sourceMapUrl) {
                const map = fetchSourceMap(sourceMapUrl);
                return {
                    url: source,
                    map: map,
                };
            }
        }
        return null;
    },
});

// スタックトレース拡張
Error.prepareStackTrace = (error, stack) => {
    const mapped = stack.map(frame => {
        const fileName = frame.getFileName();
        const lineNumber = frame.getLineNumber();
        const columnNumber = frame.getColumnNumber();

        // 元の位置を取得しようとする
        const original = getOriginalPosition(fileName, lineNumber, columnNumber);

        return {
            function: frame.getFunctionName() || '<anonymous>',
            file: original?.source || fileName,
            line: original?.line || lineNumber,
            column: original?.column || columnNumber,
            native: frame.isNative(),
            async: frame.isAsync(),
        };
    });

    return {
        message: error.message,
        stack: mapped,
    };
};
```

### 6. パフォーマンスプロファイリング

パフォーマンスプロファイリングツールを実装:

**パフォーマンスプロファイラー**
```javascript
// performance-profiler.js
const v8Profiler = require('v8-profiler-next');
const fs = require('fs');
const path = require('path');

class PerformanceProfiler {
    constructor(options = {}) {
        this.outputDir = options.outputDir || './profiles';
        this.profiles = new Map();

        // 出力ディレクトリが存在することを確認
        if (!fs.existsSync(this.outputDir)) {
            fs.mkdirSync(this.outputDir, { recursive: true });
        }
    }

    startCPUProfile(id, options = {}) {
        const title = options.title || `cpu-profile-${id}`;
        v8Profiler.startProfiling(title, true);

        this.profiles.set(id, {
            type: 'cpu',
            title,
            startTime: Date.now(),
        });

        return id;
    }

    stopCPUProfile(id) {
        const profileInfo = this.profiles.get(id);
        if (!profileInfo || profileInfo.type !== 'cpu') {
            throw new Error(`CPUプロファイル${id}が見つかりません`);
        }

        const profile = v8Profiler.stopProfiling(profileInfo.title);
        const duration = Date.now() - profileInfo.startTime;

        // プロファイルをエクスポート
        const fileName = `${profileInfo.title}-${Date.now()}.cpuprofile`;
        const filePath = path.join(this.outputDir, fileName);

        profile.export((error, result) => {
            if (!error) {
                fs.writeFileSync(filePath, result);
                console.log(`CPUプロファイルを${filePath}に保存しました`);
            }
            profile.delete();
        });

        this.profiles.delete(id);

        return {
            id,
            duration,
            filePath,
        };
    }

    takeHeapSnapshot(tag = '') {
        const fileName = `heap-${tag}-${Date.now()}.heapsnapshot`;
        const filePath = path.join(this.outputDir, fileName);

        const snapshot = v8Profiler.takeSnapshot();

        // スナップショットをエクスポート
        snapshot.export((error, result) => {
            if (!error) {
                fs.writeFileSync(filePath, result);
                console.log(`ヒープスナップショットを${filePath}に保存しました`);
            }
            snapshot.delete();
        });

        return filePath;
    }

    measureFunction(fn, name = 'anonymous') {
        const measurements = {
            name,
            executions: 0,
            totalTime: 0,
            minTime: Infinity,
            maxTime: 0,
            avgTime: 0,
            lastExecution: null,
        };

        return new Proxy(fn, {
            apply(target, thisArg, args) {
                const start = process.hrtime.bigint();

                try {
                    const result = target.apply(thisArg, args);

                    if (result instanceof Promise) {
                        return result.finally(() => {
                            this.recordExecution(start);
                        });
                    }

                    this.recordExecution(start);
                    return result;
                } catch (error) {
                    this.recordExecution(start);
                    throw error;
                }
            },

            recordExecution(start) {
                const end = process.hrtime.bigint();
                const duration = Number(end - start) / 1000000; // ミリ秒に変換

                measurements.executions++;
                measurements.totalTime += duration;
                measurements.minTime = Math.min(measurements.minTime, duration);
                measurements.maxTime = Math.max(measurements.maxTime, duration);
                measurements.avgTime = measurements.totalTime / measurements.executions;
                measurements.lastExecution = new Date();

                // 遅い実行をログ
                if (duration > 100) {
                    console.warn(`遅い関数実行: ${name}は${duration}msかかりました`);
                }
            },

            get(target, prop) {
                if (prop === 'measurements') {
                    return measurements;
                }
                return target[prop];
            },
        });
    }
}

// メモリリーク検出器
class MemoryLeakDetector {
    constructor() {
        this.snapshots = [];
        this.threshold = 50 * 1024 * 1024; // 50MB
    }

    start(interval = 60000) {
        this.interval = setInterval(() => {
            this.checkMemory();
        }, interval);
    }

    checkMemory() {
        const usage = process.memoryUsage();
        const snapshot = {
            timestamp: Date.now(),
            heapUsed: usage.heapUsed,
            external: usage.external,
            rss: usage.rss,
        };

        this.snapshots.push(snapshot);

        // 最後の10スナップショットのみを保持
        if (this.snapshots.length > 10) {
            this.snapshots.shift();
        }

        // メモリリークパターンをチェック
        if (this.snapshots.length >= 5) {
            const trend = this.calculateTrend();
            if (trend.increasing && trend.delta > this.threshold) {
                console.error('潜在的なメモリリークを検出!', {
                    trend,
                    current: snapshot,
                });

                // 分析用のヒープスナップショットを取得
                const profiler = new PerformanceProfiler();
                profiler.takeHeapSnapshot('leak-detection');
            }
        }
    }

    calculateTrend() {
        const recent = this.snapshots.slice(-5);
        const first = recent[0];
        const last = recent[recent.length - 1];

        const delta = last.heapUsed - first.heapUsed;
        const increasing = recent.every((s, i) =>
            i === 0 || s.heapUsed > recent[i - 1].heapUsed
        );

        return {
            increasing,
            delta,
            rate: delta / (last.timestamp - first.timestamp) * 1000 * 60, // 毎分MB
        };
    }
}
```

### 7. デバッグ設定管理

デバッグ設定を一元化:

**デバッグ設定**
```javascript
// debug-config.js
class DebugConfiguration {
    constructor() {
        this.config = {
            // デバッグレベル
            levels: {
                error: 0,
                warn: 1,
                info: 2,
                debug: 3,
                trace: 4,
            },

            // 機能フラグ
            features: {
                remoteDebugging: process.env.ENABLE_REMOTE_DEBUG === 'true',
                tracing: process.env.ENABLE_TRACING === 'true',
                profiling: process.env.ENABLE_PROFILING === 'true',
                memoryMonitoring: process.env.ENABLE_MEMORY_MONITORING === 'true',
            },

            // デバッグエンドポイント
            endpoints: {
                jaeger: process.env.JAEGER_ENDPOINT || 'http://localhost:14268',
                elasticsearch: process.env.ELASTICSEARCH_URL || 'http://localhost:9200',
                sentry: process.env.SENTRY_DSN,
            },

            // サンプリングレート
            sampling: {
                traces: parseFloat(process.env.TRACE_SAMPLING_RATE || '0.1'),
                profiles: parseFloat(process.env.PROFILE_SAMPLING_RATE || '0.01'),
                logs: parseFloat(process.env.LOG_SAMPLING_RATE || '1.0'),
            },
        };
    }

    isEnabled(feature) {
        return this.config.features[feature] || false;
    }

    getLevel() {
        const level = process.env.DEBUG_LEVEL || 'info';
        return this.config.levels[level] || 2;
    }

    shouldSample(type) {
        const rate = this.config.sampling[type] || 1.0;
        return Math.random() < rate;
    }
}

// デバッグミドルウェアファクトリー
class DebugMiddlewareFactory {
    static create(app, config) {
        const middlewares = [];

        if (config.isEnabled('tracing')) {
            const tracingMiddleware = new TracingMiddleware();
            middlewares.push(tracingMiddleware.express());
        }

        if (config.isEnabled('profiling')) {
            middlewares.push(this.profilingMiddleware());
        }

        if (config.isEnabled('memoryMonitoring')) {
            const detector = new MemoryLeakDetector();
            detector.start();
        }

        // デバッグルート
        if (process.env.NODE_ENV === 'development') {
            app.get('/debug/heap', (req, res) => {
                const profiler = new PerformanceProfiler();
                const path = profiler.takeHeapSnapshot('manual');
                res.json({ heapSnapshot: path });
            });

            app.get('/debug/profile', async (req, res) => {
                const profiler = new PerformanceProfiler();
                const id = profiler.startCPUProfile('manual');

                setTimeout(() => {
                    const result = profiler.stopCPUProfile(id);
                    res.json(result);
                }, 10000);
            });

            app.get('/debug/metrics', (req, res) => {
                res.json({
                    memory: process.memoryUsage(),
                    cpu: process.cpuUsage(),
                    uptime: process.uptime(),
                });
            });
        }

        return middlewares;
    }

    static profilingMiddleware() {
        const profiler = new PerformanceProfiler();

        return (req, res, next) => {
            if (Math.random() < 0.01) { // 1%サンプリング
                const id = profiler.startCPUProfile(`request-${Date.now()}`);

                res.on('finish', () => {
                    profiler.stopCPUProfile(id);
                });
            }

            next();
        };
    }
}
```

### 8. 本番デバッグ

安全な本番デバッグを有効化:

**本番デバッグツール**
```javascript
// production-debug.js
class ProductionDebugger {
    constructor(options = {}) {
        this.enabled = process.env.PRODUCTION_DEBUG === 'true';
        this.authToken = process.env.DEBUG_AUTH_TOKEN;
        this.allowedIPs = (process.env.DEBUG_ALLOWED_IPS || '').split(',');
    }

    middleware() {
        return (req, res, next) => {
            if (!this.enabled) {
                return next();
            }

            // 認証をチェック
            const token = req.headers['x-debug-token'];
            const ip = req.ip || req.connection.remoteAddress;

            if (token !== this.authToken || !this.allowedIPs.includes(ip)) {
                return next();
            }

            // デバッグヘッダーを追加
            res.setHeader('X-Debug-Enabled', 'true');

            // このリクエストのデバッグモードを有効化
            req.debugMode = true;
            req.debugContext = new DebugContext().create(req.id);

            // このリクエストのコンソールをオーバーライド
            const originalConsole = { ...console };
            ['log', 'debug', 'info', 'warn', 'error'].forEach(method => {
                console[method] = (...args) => {
                    req.debugContext.log(req.id, method, args[0], args.slice(1));
                    originalConsole[method](...args);
                };
            });

            // レスポンス時にコンソールを復元
            res.on('finish', () => {
                Object.assign(console, originalConsole);

                // リクエストされた場合はデバッグ情報を送信
                if (req.headers['x-debug-response'] === 'true') {
                    const debugInfo = req.debugContext.export(req.id);
                    res.setHeader('X-Debug-Info', JSON.stringify(debugInfo));
                }
            });

            next();
        };
    }
}

// 本番での条件付きブレークポイント
class ConditionalBreakpoint {
    constructor(condition, callback) {
        this.condition = condition;
        this.callback = callback;
        this.hits = 0;
    }

    check(context) {
        if (this.condition(context)) {
            this.hits++;

            // ブレークポイントヒットをログ
            console.debug('条件付きブレークポイントヒット', {
                condition: this.condition.toString(),
                hits: this.hits,
                context,
            });

            // コールバックを実行
            if (this.callback) {
                this.callback(context);
            }

            // 本番では実際にブレークしない
            if (process.env.NODE_ENV === 'production') {
                // 代わりにスナップショットを取得
                const profiler = new PerformanceProfiler();
                profiler.takeHeapSnapshot(`breakpoint-${Date.now()}`);
            } else {
                // 開発ではデバッガーを使用
                debugger;
            }
        }
    }
}

// 使用法
const breakpoints = new Map();

// 条件付きブレークポイントを設定
breakpoints.set('high-memory', new ConditionalBreakpoint(
    (context) => context.memoryUsage > 500 * 1024 * 1024, // 500MB
    (context) => {
        console.error('高メモリ使用率を検出', context);
        // アラートを送信
        alerting.send('high-memory', context);
    }
));

// コードでブレークポイントをチェック
function checkBreakpoints(context) {
    breakpoints.forEach(breakpoint => {
        breakpoint.check(context);
    });
}
```

### 9. デバッグダッシュボード

監視用のデバッグダッシュボードを作成:

**デバッグダッシュボード**
```html
<!-- debug-dashboard.html -->
<!DOCTYPE html>
<html>
<head>
    <title>デバッグダッシュボード</title>
    <style>
        body { font-family: monospace; background: #1e1e1e; color: #d4d4d4; }
        .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
        .metric { background: #252526; padding: 15px; margin: 10px 0; border-radius: 5px; }
        .metric h3 { margin: 0 0 10px 0; color: #569cd6; }
        .chart { height: 200px; background: #1e1e1e; margin: 10px 0; }
        .log-entry { padding: 5px; border-bottom: 1px solid #3e3e3e; }
        .error { color: #f44747; }
        .warn { color: #ff9800; }
        .info { color: #4fc3f7; }
        .debug { color: #4caf50; }
    </style>
</head>
<body>
    <div class="container">
        <h1>デバッグダッシュボード</h1>

        <div class="metric">
            <h3>システムメトリクス</h3>
            <div id="metrics"></div>
        </div>

        <div class="metric">
            <h3>メモリ使用量</h3>
            <canvas id="memoryChart" class="chart"></canvas>
        </div>

        <div class="metric">
            <h3>リクエストトレース</h3>
            <div id="traces"></div>
        </div>

        <div class="metric">
            <h3>デバッグログ</h3>
            <div id="logs"></div>
        </div>
    </div>

    <script>
        // リアルタイム更新のためのWebSocket接続
        const ws = new WebSocket('ws://localhost:9231/debug');

        ws.onmessage = (event) => {
            const data = JSON.parse(event.data);

            switch (data.type) {
                case 'metrics':
                    updateMetrics(data.payload);
                    break;
                case 'trace':
                    addTrace(data.payload);
                    break;
                case 'log':
                    addLog(data.payload);
                    break;
            }
        };

        function updateMetrics(metrics) {
            const container = document.getElementById('metrics');
            container.innerHTML = `
                <div>CPU: ${metrics.cpu.percent}%</div>
                <div>メモリ: ${metrics.memory.used}MB / ${metrics.memory.total}MB</div>
                <div>稼働時間: ${metrics.uptime}秒</div>
                <div>アクティブリクエスト: ${metrics.activeRequests}</div>
            `;
        }

        function addTrace(trace) {
            const container = document.getElementById('traces');
            const entry = document.createElement('div');
            entry.className = 'log-entry';
            entry.innerHTML = `
                <span>${trace.timestamp}</span>
                <span>${trace.method} ${trace.path}</span>
                <span>${trace.duration}ms</span>
                <span>${trace.status}</span>
            `;
            container.insertBefore(entry, container.firstChild);
        }

        function addLog(log) {
            const container = document.getElementById('logs');
            const entry = document.createElement('div');
            entry.className = `log-entry ${log.level}`;
            entry.innerHTML = `
                <span>${log.timestamp}</span>
                <span>[${log.level.toUpperCase()}]</span>
                <span>${log.message}</span>
            `;
            container.insertBefore(entry, container.firstChild);

            // 最後の100ログのみを保持
            while (container.children.length > 100) {
                container.removeChild(container.lastChild);
            }
        }

        // メモリ使用量チャート
        const memoryChart = document.getElementById('memoryChart').getContext('2d');
        const memoryData = [];

        function updateMemoryChart(usage) {
            memoryData.push({
                time: new Date(),
                value: usage,
            });

            // 最後の50ポイントを保持
            if (memoryData.length > 50) {
                memoryData.shift();
            }

            // チャートを描画
            // ... チャート描画ロジック
        }
    </script>
</body>
</html>
```

### 10. IDE統合

IDEデバッグ機能を設定:

**IDEデバッグ拡張**
```json
// .vscode/extensions.json
{
    "recommendations": [
        "ms-vscode.vscode-js-debug",
        "msjsdiag.debugger-for-chrome",
        "ms-vscode.vscode-typescript-tslint-plugin",
        "dbaeumer.vscode-eslint",
        "ms-azuretools.vscode-docker",
        "humao.rest-client",
        "eamodio.gitlens",
        "usernamehw.errorlens",
        "wayou.vscode-todo-highlight",
        "formulahendry.code-runner"
    ]
}

// .vscode/tasks.json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Start Debug Server",
            "type": "npm",
            "script": "debug",
            "problemMatcher": [],
            "presentation": {
                "reveal": "always",
                "panel": "dedicated"
            }
        },
        {
            "label": "Profile Application",
            "type": "shell",
            "command": "node --inspect-brk --cpu-prof --cpu-prof-dir=./profiles ${workspaceFolder}/src/index.js",
            "problemMatcher": []
        },
        {
            "label": "Memory Snapshot",
            "type": "shell",
            "command": "node --inspect --expose-gc ${workspaceFolder}/scripts/heap-snapshot.js",
            "problemMatcher": []
        }
    ]
}
```

## 出力形式

1. **デバッグ設定**: 全デバッグツールの完全なセットアップ
2. **統合ガイド**: ステップバイステップの統合手順
3. **トラブルシューティングプレイブック**: 一般的なデバッグシナリオと解決策
4. **パフォーマンスベースライン**: 比較用のメトリクス
5. **デバッグスクリプト**: 自動デバッグユーティリティ
6. **ダッシュボードセットアップ**: リアルタイムデバッグインターフェース
7. **ドキュメンテーション**: チームデバッグガイドライン
8. **緊急時手順**: 本番デバッグプロトコル

全環境で開発者の生産性を向上させ、迅速な問題解決を可能にする包括的なデバッグ環境の作成に焦点を当ててください。
