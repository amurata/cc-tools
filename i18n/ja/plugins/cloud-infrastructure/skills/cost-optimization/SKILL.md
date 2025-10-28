---
name: cost-optimization
description: リソース適正サイジング、タグ付け戦略、リザーブドインスタンス、支出分析を通じてクラウドコストを最適化します。クラウド費用削減、インフラコスト分析、コストガバナンスポリシー実装時に使用します。
---

> **[English](../../../../../../plugins/cloud-infrastructure/skills/cost-optimization/SKILL.md)** | **日本語**

# クラウドコスト最適化

AWS、Azure、GCPにまたがるクラウドコスト最適化のための戦略とパターン。

## 目的

パフォーマンスと信頼性を維持しながらクラウド支出を削減するための体系的なコスト最適化戦略を実装します。

## 使用タイミング

- クラウド支出削減
- リソース適正サイジング
- コストガバナンス実装
- マルチクラウドコスト最適化
- 予算制約達成

## コスト最適化フレームワーク

### 1. 可視化
- コスト配分タグの実装
- クラウドコスト管理ツールの使用
- 予算アラートの設定
- コストダッシュボードの作成

### 2. 適正サイジング
- リソース使用率の分析
- オーバープロビジョニングされたリソースのダウンサイジング
- オートスケーリングの使用
- アイドルリソースの削除

### 3. 価格モデル
- リザーブドキャパシティの使用
- スポット/プリエンプティブルインスタンスの活用
- セービングプランの実装
- コミット使用割引の使用

### 4. アーキテクチャ最適化
- マネージドサービスの使用
- キャッシングの実装
- データ転送の最適化
- ライフサイクルポリシーの使用

## AWSコスト最適化

### リザーブドインスタンス
```
節約: オンデマンドの30-72%
期間: 1年または3年
支払い: 全額前払い/一部前払い/前払いなし
柔軟性: スタンダードまたはコンバーティブル
```

### セービングプラン
```
コンピュートセービングプラン: 66%節約
EC2インスタンスセービングプラン: 72%節約
適用対象: EC2、Fargate、Lambda
柔軟性: インスタンスファミリー、リージョン、OS横断
```

### スポットインスタンス
```
節約: オンデマンドの最大90%
最適な用途: バッチジョブ、CI/CD、ステートレスワークロード
リスク: 2分間の中断通知
戦略: レジリエンスのためオンデマンドと混在
```

### S3コスト最適化
```hcl
resource "aws_s3_bucket_lifecycle_configuration" "example" {
  bucket = aws_s3_bucket.example.id

  rule {
    id     = "transition-to-ia"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}
```

## Azureコスト最適化

### リザーブドVMインスタンス
- 1年または3年の期間
- 最大72%節約
- 柔軟なサイジング
- 交換可能

### Azure Hybrid Benefit
- 既存のWindows Serverライセンスを使用
- RIと組み合わせて最大80%節約
- Windows ServerとSQL Serverで利用可能

### Azure Advisor推奨事項
- VMの適正サイジング
- 未使用リソースの削除
- リザーブドキャパシティの使用
- ストレージの最適化

## GCPコスト最適化

### コミット使用割引
- 1年または3年のコミットメント
- 最大57%節約
- vCPUとメモリに適用
- リソースベースまたは支出ベース

### 継続使用割引
- 自動割引
- 実行中インスタンスに対して最大30%
- コミットメント不要
- Compute Engine、GKEに適用

### プリエンプティブルVM
- 最大80%節約
- 最大24時間のランタイム
- バッチワークロードに最適

## タグ付け戦略

### AWSタグ付け
```hcl
locals {
  common_tags = {
    Environment = "production"
    Project     = "my-project"
    CostCenter  = "engineering"
    Owner       = "team@example.com"
    ManagedBy   = "terraform"
  }
}

resource "aws_instance" "example" {
  ami           = "ami-12345678"
  instance_type = "t3.medium"

  tags = merge(
    local.common_tags,
    {
      Name = "web-server"
    }
  )
}
```

**参照:** `references/tagging-standards.md`参照

## コスト監視

### 予算アラート
```hcl
# AWS予算
resource "aws_budgets_budget" "monthly" {
  name              = "monthly-budget"
  budget_type       = "COST"
  limit_amount      = "1000"
  limit_unit        = "USD"
  time_period_start = "2024-01-01_00:00"
  time_unit         = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = ["team@example.com"]
  }
}
```

### コスト異常検出
- AWSコスト異常検出
- Azureコスト管理アラート
- GCP予算アラート

## アーキテクチャパターン

### パターン1: サーバーレスファースト
- イベント駆動にLambda/Functionsを使用
- 実行時間のみ支払い
- オートスケーリングを含む
- アイドルコストなし

### パターン2: 適正サイズデータベース
```
開発: t3.small RDS
ステージング: t3.large RDS
本番: リードレプリカ付きr6g.2xlarge RDS
```

### パターン3: マルチティアストレージ
```
ホットデータ: S3 Standard
ウォームデータ: S3 Standard-IA（30日）
コールドデータ: S3 Glacier（90日）
アーカイブ: S3 Deep Archive（365日）
```

### パターン4: オートスケーリング
```hcl
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale-up"
  scaling_adjustment     = 2
  adjustment_type        = "ChangeInCapacity"
  cooldown              = 300
  autoscaling_group_name = aws_autoscaling_group.main.name
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]
}
```

## コスト最適化チェックリスト

- [ ] コスト配分タグの実装
- [ ] 未使用リソースの削除（EBS、EIP、スナップショット）
- [ ] 使用率に基づくインスタンスの適正サイジング
- [ ] 安定したワークロード用リザーブドキャパシティの使用
- [ ] オートスケーリングの実装
- [ ] ストレージクラスの最適化
- [ ] ライフサイクルポリシーの使用
- [ ] コスト異常検出の有効化
- [ ] 予算アラートの設定
- [ ] 週次コストレビュー
- [ ] スポット/プリエンプティブルインスタンスの使用
- [ ] データ転送コストの最適化
- [ ] キャッシング層の実装
- [ ] マネージドサービスの使用
- [ ] 継続的な監視と最適化

## ツール

- **AWS:** Cost Explorer、コスト異常検出、Compute Optimizer
- **Azure:** コスト管理、Advisor
- **GCP:** コスト管理、Recommender
- **マルチクラウド:** CloudHealth、Cloudability、Kubecost

## 参照ファイル

- `references/tagging-standards.md` - タグ付け規約
- `assets/cost-analysis-template.xlsx` - コスト分析スプレッドシート

## 関連スキル

- `terraform-module-library` - リソースプロビジョニング用
- `multi-cloud-architecture` - クラウド選択用
