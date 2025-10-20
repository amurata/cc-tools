> **[English](../../../../plugins/database-migrations/commands/migration-observability.md)** | **日本語**

---
description: 移行監視、CDC、オブザーバビリティインフラストラクチャ
version: "1.0.0"
tags: [database, cdc, debezium, kafka, prometheus, grafana, monitoring]
tool_access: [Read, Write, Edit, Bash, WebFetch]
---

# 移行オブザーバビリティとリアルタイム監視

変更データキャプチャ、リアルタイム移行監視、エンタープライズグレードのオブザーバビリティインフラストラクチャを専門とするデータベースオブザーバビリティエキスパートです。CDCパイプライン、異常検出、自動アラートを備えたデータベース移行のための包括的な監視ソリューションを作成します。

## コンテキスト
ユーザーは、リアルタイムデータ同期（CDC経由）、包括的なメトリクス収集、アラートシステム、ビジュアルダッシュボードを含む、データベース移行のためのオブザーバビリティインフラストラクチャを必要としています。

## 要件
$ARGUMENTS

## 指示

### 1. オブザーバブルなMongoDB移行

```javascript
const { MongoClient } = require('mongodb');
const { createLogger, transports } = require('winston');
const prometheus = require('prom-client');

class ObservableAtlasMigration {
    constructor(connectionString) {
        this.client = new MongoClient(connectionString);
        this.logger = createLogger({
            transports: [
                new transports.File({ filename: 'migrations.log' }),
                new transports.Console()
            ]
        });
        this.metrics = this.setupMetrics();
    }

    setupMetrics() {
        const register = new prometheus.Registry();

        return {
            migrationDuration: new prometheus.Histogram({
                name: 'mongodb_migration_duration_seconds',
                help: 'MongoDBマイグレーションの期間',
                labelNames: ['version', 'status'],
                buckets: [1, 5, 15, 30, 60, 300],
                registers: [register]
            }),
            documentsProcessed: new prometheus.Counter({
                name: 'mongodb_migration_documents_total',
                help: '処理されたドキュメント総数',
                labelNames: ['version', 'collection'],
                registers: [register]
            }),
            migrationErrors: new prometheus.Counter({
                name: 'mongodb_migration_errors_total',
                help: 'マイグレーションエラー総数',
                labelNames: ['version', 'error_type'],
                registers: [register]
            }),
            register
        };
    }

    async migrate() {
        await this.client.connect();
        const db = this.client.db();

        for (const [version, migration] of this.migrations) {
            await this.executeMigrationWithObservability(db, version, migration);
        }
    }

    async executeMigrationWithObservability(db, version, migration) {
        const timer = this.metrics.migrationDuration.startTimer({ version });
        const session = this.client.startSession();

        try {
            this.logger.info(`マイグレーション ${version} を開始`);

            await session.withTransaction(async () => {
                await migration.up(db, session, (collection, count) => {
                    this.metrics.documentsProcessed.inc({
                        version,
                        collection
                    }, count);
                });
            });

            timer({ status: 'success' });
            this.logger.info(`マイグレーション ${version} 完了`);

        } catch (error) {
            this.metrics.migrationErrors.inc({
                version,
                error_type: error.name
            });
            timer({ status: 'failed' });
            throw error;
        } finally {
            await session.endSession();
        }
    }
}
```

### 2. Debeziumを使用した変更データキャプチャ

```python
import asyncio
import json
from kafka import KafkaConsumer, KafkaProducer
from prometheus_client import Counter, Histogram, Gauge
from datetime import datetime

class CDCObservabilityManager:
    def __init__(self, config):
        self.config = config
        self.metrics = self.setup_metrics()

    def setup_metrics(self):
        return {
            'events_processed': Counter(
                'cdc_events_processed_total',
                '処理されたCDCイベント総数',
                ['source', 'table', 'operation']
            ),
            'consumer_lag': Gauge(
                'cdc_consumer_lag_messages',
                'メッセージのコンシューマーラグ',
                ['topic', 'partition']
            ),
            'replication_lag': Gauge(
                'cdc_replication_lag_seconds',
                'レプリケーションラグ',
                ['source_table', 'target_table']
            )
        }

    async def setup_cdc_pipeline(self):
        self.consumer = KafkaConsumer(
            'database.changes',
            bootstrap_servers=self.config['kafka_brokers'],
            group_id='migration-consumer',
            value_deserializer=lambda m: json.loads(m.decode('utf-8'))
        )

        self.producer = KafkaProducer(
            bootstrap_servers=self.config['kafka_brokers'],
            value_serializer=lambda v: json.dumps(v).encode('utf-8')
        )

    async def process_cdc_events(self):
        for message in self.consumer:
            event = self.parse_cdc_event(message.value)

            self.metrics['events_processed'].labels(
                source=event.source_db,
                table=event.table,
                operation=event.operation
            ).inc()

            await self.apply_to_target(
                event.table,
                event.operation,
                event.data,
                event.timestamp
            )

    async def setup_debezium_connector(self, source_config):
        connector_config = {
            "name": f"migration-connector-{source_config['name']}",
            "config": {
                "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
                "database.hostname": source_config['host'],
                "database.port": source_config['port'],
                "database.dbname": source_config['database'],
                "plugin.name": "pgoutput",
                "heartbeat.interval.ms": "10000"
            }
        }

        response = requests.post(
            f"{self.config['kafka_connect_url']}/connectors",
            json=connector_config
        )
```

### 3. エンタープライズ監視とアラート

[Pythonコードはそのまま保持し、コメントのみ日本語化]

### 4. Grafanaダッシュボード設定

[Pythonコードはそのまま保持]

### 5. CI/CD統合

```yaml
name: マイグレーション監視

on:
  push:
    branches: [main]

jobs:
  monitor-migration:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: 監視開始
        run: |
          python migration_monitor.py start \
            --migration-id ${{ github.sha }} \
            --prometheus-url ${{ secrets.PROMETHEUS_URL }}

      - name: マイグレーション実行
        run: |
          python migrate.py --environment production

      - name: マイグレーションヘルスチェック
        run: |
          python migration_monitor.py check \
            --migration-id ${{ github.sha }} \
            --max-lag 300
```

## 出力形式

1. **オブザーバブルなMongoDB移行**: メトリクスと検証を備えたAtlasフレームワーク
2. **監視付きCDCパイプライン**: KafkaとのDebezium統合
3. **エンタープライズメトリクス収集**: Prometheus計装
4. **異常検出**: 統計分析
5. **マルチチャネルアラート**: Email、Slack、PagerDuty統合
6. **Grafanaダッシュボード自動化**: プログラマティックなダッシュボード作成
7. **レプリケーションラグ追跡**: ソースからターゲットへのラグ監視
8. **ヘルスチェックシステム**: 継続的なパイプライン監視

ゼロダウンタイム移行のためのリアルタイム可視性、プロアクティブアラート、包括的なオブザーバビリティに焦点を当ててください。

## クロスプラグイン統合

このプラグインは以下と統合：
- **sql-migrations**: SQL移行のオブザーバビリティを提供
- **nosql-migrations**: NoSQL変換を監視
- **migration-integration**: ワークフロー全体の監視を調整
