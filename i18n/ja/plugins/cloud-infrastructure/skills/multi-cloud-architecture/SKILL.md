---
name: multi-cloud-architecture
description: AWS、Azure、GCPにまたがるサービスを選択・統合するための意思決定フレームワークを使用してマルチクラウドアーキテクチャを設計します。マルチクラウドシステム構築、ベンダーロックイン回避、複数プロバイダーからのベストオブブリードサービス活用時に使用します。
---

> **[English](../../../../../../plugins/cloud-infrastructure/skills/multi-cloud-architecture/SKILL.md)** | **日本語**

# マルチクラウドアーキテクチャ

AWS、Azure、GCPにまたがるアプリケーションをアーキテクチングするための意思決定フレームワークとパターン。

## 目的

クラウドプロバイダー間でクラウドアグノスティックアーキテクチャを設計し、サービス選択について情報に基づいた決定を行います。

## 使用タイミング

- マルチクラウド戦略の設計
- クラウドプロバイダー間のマイグレーション
- 特定ワークロード用クラウドサービスの選択
- クラウドアグノスティックアーキテクチャの実装
- プロバイダー間のコスト最適化

## クラウドサービス比較

### コンピュートサービス

| AWS | Azure | GCP | ユースケース |
|-----|-------|-----|----------|
| EC2 | Virtual Machines | Compute Engine | IaaS VM |
| ECS | Container Instances | Cloud Run | コンテナ |
| EKS | AKS | GKE | Kubernetes |
| Lambda | Functions | Cloud Functions | サーバーレス |
| Fargate | Container Apps | Cloud Run | マネージドコンテナ |

### ストレージサービス

| AWS | Azure | GCP | ユースケース |
|-----|-------|-----|----------|
| S3 | Blob Storage | Cloud Storage | オブジェクトストレージ |
| EBS | Managed Disks | Persistent Disk | ブロックストレージ |
| EFS | Azure Files | Filestore | ファイルストレージ |
| Glacier | Archive Storage | Archive Storage | コールドストレージ |

### データベースサービス

| AWS | Azure | GCP | ユースケース |
|-----|-------|-----|----------|
| RDS | SQL Database | Cloud SQL | マネージドSQL |
| DynamoDB | Cosmos DB | Firestore | NoSQL |
| Aurora | PostgreSQL/MySQL | Cloud Spanner | 分散SQL |
| ElastiCache | Cache for Redis | Memorystore | キャッシング |

**参照:** 完全な比較は`references/service-comparison.md`参照

## マルチクラウドパターン

### パターン1: DR付き単一プロバイダー

- 1つのクラウドでプライマリワークロード
- 別のクラウドで災害復旧
- クラウド間のデータベースレプリケーション
- 自動フェイルオーバー

### パターン2: ベストオブブリード

- 各プロバイダーから最適なサービスを使用
- GCPでAI/ML
- Azureでエンタープライズアプリケーション
- AWSで一般的なコンピュート

### パターン3: 地理的分散

- 最寄りのクラウドリージョンからユーザーを提供
- データ主権コンプライアンス
- グローバルロードバランシング
- リージョナルフェイルオーバー

### パターン4: クラウドアグノスティック抽象化

- コンピュートにKubernetes
- データベースにPostgreSQL
- S3互換ストレージ（MinIO）
- オープンソースツール

## クラウドアグノスティックアーキテクチャ

### クラウドネイティブ代替の使用

- **コンピュート:** Kubernetes（EKS/AKS/GKE）
- **データベース:** PostgreSQL/MySQL（RDS/SQL Database/Cloud SQL）
- **メッセージキュー:** Apache Kafka（MSK/Event Hubs/Confluent）
- **キャッシュ:** Redis（ElastiCache/Azure Cache/Memorystore）
- **オブジェクトストレージ:** S3互換API
- **監視:** Prometheus/Grafana
- **サービスメッシュ:** Istio/Linkerd

### 抽象化層

```
アプリケーション層
    ↓
インフラ抽象化（Terraform）
    ↓
クラウドプロバイダーAPI
    ↓
AWS / Azure / GCP
```

## コスト比較

### コンピュート価格要因

- **AWS:** オンデマンド、リザーブド、スポット、セービングプラン
- **Azure:** 従量課金、リザーブド、スポット
- **GCP:** オンデマンド、コミット使用、プリエンプティブル

### コスト最適化戦略

1. リザーブド/コミットキャパシティの使用（30-70%節約）
2. スポット/プリエンプティブルインスタンスの活用
3. リソースの適正サイジング
4. 変動ワークロードにサーバーレスを使用
5. データ転送コストの最適化
6. ライフサイクルポリシーの実装
7. コスト配分タグの使用
8. クラウドコストツールで監視

**参照:** `references/multi-cloud-patterns.md`参照

## マイグレーション戦略

### フェーズ1: 評価
- 現在のインフラのインベントリ
- 依存関係の特定
- クラウド互換性の評価
- コストの見積もり

### フェーズ2: パイロット
- パイロットワークロードの選択
- ターゲットクラウドでの実装
- 徹底的なテスト
- 学習の文書化

### フェーズ3: マイグレーション
- ワークロードの段階的マイグレーション
- デュアルラン期間の維持
- パフォーマンスの監視
- 機能の検証

### フェーズ4: 最適化
- リソースの適正サイズ化
- クラウドネイティブサービスの実装
- コストの最適化
- セキュリティの強化

## ベストプラクティス

1. **Infrastructure as Codeの使用**（Terraform/OpenTofu）
2. **CI/CDパイプラインの実装**でデプロイ
3. **クラウド間の障害設計**
4. **可能な場合マネージドサービスを使用**
5. **包括的な監視の実装**
6. **コスト最適化の自動化**
7. **セキュリティベストプラクティスに従う**
8. **クラウド固有の設定を文書化**
9. **災害復旧手順をテスト**
10. **複数クラウドでチームをトレーニング**

## 参照ファイル

- `references/service-comparison.md` - 完全なサービス比較
- `references/multi-cloud-patterns.md` - アーキテクチャパターン

## 関連スキル

- `terraform-module-library` - IaC実装用
- `cost-optimization` - コスト管理用
- `hybrid-cloud-networking` - 接続用
