> **[English](../../../../../plugins/observability-monitoring/skills/slo-implementation/SKILL.md)** | **日本語**

---
name: slo-implementation
description: エラーバジェットとアラートを用いたサービスレベルインジケーター（SLI）とサービスレベル目標（SLO）を定義・実装します。信頼性ターゲットの確立、SREプラクティスの実装、サービスパフォーマンスの測定時に使用します。
---

# SLO実装

サービスレベルインジケーター（SLI）、サービスレベル目標（SLO）、エラーバジェットを定義・実装するフレームワーク。

## 目的

SLI、SLO、エラーバジェットを使用して測定可能な信頼性ターゲットを実装し、信頼性とイノベーション速度のバランスを取ります。

## 使用タイミング

- サービス信頼性ターゲットの定義
- ユーザーが認識する信頼性の測定
- エラーバジェットの実装
- SLOベースのアラートの作成
- 信頼性目標の追跡

## SLI/SLO/SLAの階層

```
SLA（サービスレベル契約）
  ↓ 顧客との契約
SLO（サービスレベル目標）
  ↓ 内部信頼性ターゲット
SLI（サービスレベルインジケーター）
  ↓ 実際の測定
```

## SLIの定義

### 一般的なSLIタイプ

#### 1. 可用性SLI
```promql
# 成功したリクエスト / 総リクエスト数
sum(rate(http_requests_total{status!~"5.."}[28d]))
/
sum(rate(http_requests_total[28d]))
```

#### 2. レイテンシSLI
```promql
# レイテンシ閾値以下のリクエスト / 総リクエスト数
sum(rate(http_request_duration_seconds_bucket{le="0.5"}[28d]))
/
sum(rate(http_request_duration_seconds_count[28d]))
```

#### 3. 耐久性SLI
```
# 成功した書き込み / 総書き込み数
sum(storage_writes_successful_total)
/
sum(storage_writes_total)
```

**参照:** `references/slo-definitions.md`を参照

## SLOターゲットの設定

### 可用性SLOの例

| SLO % | ダウンタイム/月 | ダウンタイム/年 |
|-------|----------------|----------------|
| 99%   | 7.2時間        | 3.65日         |
| 99.9% | 43.2分         | 8.76時間       |
| 99.95%| 21.6分         | 4.38時間       |
| 99.99%| 4.32分         | 52.56分        |

### 適切なSLOの選択

**考慮事項:**
- ユーザーの期待
- ビジネス要件
- 現在のパフォーマンス
- 信頼性のコスト
- 競合他社のベンチマーク

**SLOの例:**
```yaml
slos:
  - name: api_availability
    target: 99.9
    window: 28d
    sli: |
      sum(rate(http_requests_total{status!~"5.."}[28d]))
      /
      sum(rate(http_requests_total[28d]))

  - name: api_latency_p95
    target: 99
    window: 28d
    sli: |
      sum(rate(http_request_duration_seconds_bucket{le="0.5"}[28d]))
      /
      sum(rate(http_request_duration_seconds_count[28d]))
```

## エラーバジェット計算

### エラーバジェットの公式

```
エラーバジェット = 1 - SLOターゲット
```

**例:**
- SLO: 99.9%の可用性
- エラーバジェット: 0.1% = 43.2分/月
- 現在のエラー: 0.05% = 21.6分/月
- 残りのバジェット: 50%

### エラーバジェットポリシー

```yaml
error_budget_policy:
  - remaining_budget: 100%
    action: 通常の開発速度
  - remaining_budget: 50%
    action: リスクの高い変更の延期を検討
  - remaining_budget: 10%
    action: 非クリティカルな変更を凍結
  - remaining_budget: 0%
    action: 機能凍結、信頼性に焦点
```

**参照:** `references/error-budget.md`を参照

## SLO実装

### Prometheusレコーディングルール

```yaml
# SLIレコーディングルール
groups:
  - name: sli_rules
    interval: 30s
    rules:
      # 可用性SLI
      - record: sli:http_availability:ratio
        expr: |
          sum(rate(http_requests_total{status!~"5.."}[28d]))
          /
          sum(rate(http_requests_total[28d]))

      # レイテンシSLI（リクエスト < 500ms）
      - record: sli:http_latency:ratio
        expr: |
          sum(rate(http_request_duration_seconds_bucket{le="0.5"}[28d]))
          /
          sum(rate(http_request_duration_seconds_count[28d]))

  - name: slo_rules
    interval: 5m
    rules:
      # SLOコンプライアンス（1 = SLO達成、0 = SLO違反）
      - record: slo:http_availability:compliance
        expr: sli:http_availability:ratio >= bool 0.999

      - record: slo:http_latency:compliance
        expr: sli:http_latency:ratio >= bool 0.99

      # エラーバジェット残量（パーセンテージ）
      - record: slo:http_availability:error_budget_remaining
        expr: |
          (sli:http_availability:ratio - 0.999) / (1 - 0.999) * 100

      # エラーバジェットバーンレート
      - record: slo:http_availability:burn_rate_5m
        expr: |
          (1 - (
            sum(rate(http_requests_total{status!~"5.."}[5m]))
            /
            sum(rate(http_requests_total[5m]))
          )) / (1 - 0.999)
```

### SLOアラートルール

```yaml
groups:
  - name: slo_alerts
    interval: 1m
    rules:
      # 高速バーン: 14.4倍レート、1時間ウィンドウ
      # 1時間でエラーバジェットの2%を消費
      - alert: SLOErrorBudgetBurnFast
        expr: |
          slo:http_availability:burn_rate_1h > 14.4
          and
          slo:http_availability:burn_rate_5m > 14.4
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Fast error budget burn detected"
          description: "Error budget burning at {{ $value }}x rate"

      # 低速バーン: 6倍レート、6時間ウィンドウ
      # 6時間でエラーバジェットの5%を消費
      - alert: SLOErrorBudgetBurnSlow
        expr: |
          slo:http_availability:burn_rate_6h > 6
          and
          slo:http_availability:burn_rate_30m > 6
        for: 15m
        labels:
          severity: warning
        annotations:
          summary: "Slow error budget burn detected"
          description: "Error budget burning at {{ $value }}x rate"

      # エラーバジェット枯渇
      - alert: SLOErrorBudgetExhausted
        expr: slo:http_availability:error_budget_remaining < 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "SLO error budget exhausted"
          description: "Error budget remaining: {{ $value }}%"
```

## SLOダッシュボード

**Grafanaダッシュボード構造:**

```
┌────────────────────────────────────┐
│ SLOコンプライアンス（現在）         │
│ ✓ 99.95%（ターゲット: 99.9%）      │
├────────────────────────────────────┤
│ エラーバジェット残量: 65%           │
│ ████████░░ 65%                     │
├────────────────────────────────────┤
│ SLIトレンド（28日間）               │
│ [時系列グラフ]                     │
├────────────────────────────────────┤
│ バーンレート分析                    │
│ [時間ウィンドウごとのバーンレート]  │
└────────────────────────────────────┘
```

**クエリの例:**

```promql
# 現在のSLOコンプライアンス
sli:http_availability:ratio * 100

# エラーバジェット残量
slo:http_availability:error_budget_remaining

# エラーバジェット枯渇までの日数（現在のバーンレートで）
(slo:http_availability:error_budget_remaining / 100)
*
28
/
(1 - sli:http_availability:ratio) * (1 - 0.999)
```

## マルチウィンドウバーンレートアラート

```yaml
# 短期と長期ウィンドウの組み合わせで誤検知を削減
rules:
  - alert: SLOBurnRateHigh
    expr: |
      (
        slo:http_availability:burn_rate_1h > 14.4
        and
        slo:http_availability:burn_rate_5m > 14.4
      )
      or
      (
        slo:http_availability:burn_rate_6h > 6
        and
        slo:http_availability:burn_rate_30m > 6
      )
    labels:
      severity: critical
```

## SLOレビュープロセス

### 週次レビュー
- 現在のSLOコンプライアンス
- エラーバジェット状態
- トレンド分析
- インシデント影響

### 月次レビュー
- SLO達成
- エラーバジェット使用
- インシデント事後報告
- SLO調整

### 四半期レビュー
- SLOの関連性
- ターゲット調整
- プロセス改善
- ツール強化

## ベストプラクティス

1. **ユーザー向けサービスから始める**
2. **複数のSLIを使用**（可用性、レイテンシなど）
3. **達成可能なSLOを設定**（100%を目指さない）
4. **ノイズを減らすためにマルチウィンドウアラートを実装**
5. **エラーバジェットを一貫して追跡**
6. **定期的にSLOをレビュー**
7. **SLOの決定を文書化**
8. **ビジネス目標と整合**
9. **SLOレポートを自動化**
10. **優先順位付けにSLOを使用**

## リファレンスファイル

- `assets/slo-template.md` - SLO定義テンプレート
- `references/slo-definitions.md` - SLO定義パターン
- `references/error-budget.md` - エラーバジェット計算

## 関連スキル

- `prometheus-configuration` - メトリクス収集のため
- `grafana-dashboards` - SLO可視化のため
