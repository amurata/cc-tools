---
name: deployment-pipeline-design
description: 承認ゲート、セキュリティチェック、デプロイメントオーケストレーションを備えたマルチステージCI/CDパイプラインを設計。デプロイメントワークフローのアーキテクチャ設計、継続的デリバリーのセットアップ、またはGitOpsプラクティスの実装時に使用。
---

> **[English](../../../../../plugins/cicd-automation/skills/deployment-pipeline-design/SKILL.md)** | **日本語**

# デプロイメントパイプライン設計

承認ゲートとデプロイメント戦略を備えたマルチステージCI/CDパイプラインのアーキテクチャパターン。

## 目的

適切なステージ構成と承認ワークフローを通じて、スピードと安全性のバランスを取る堅牢で安全なデプロイメントパイプラインを設計する。

## 使用タイミング

- CI/CDアーキテクチャの設計
- デプロイメントゲートの実装
- マルチ環境パイプラインの設定
- デプロイメントベストプラクティスの確立
- プログレッシブデリバリーの実装

## パイプラインステージ

### 標準パイプラインフロー

```
┌─────────┐   ┌──────┐   ┌─────────┐   ┌────────┐   ┌──────────┐
│ ビルド  │ → │テスト│ → │ステージ │ → │承認    │ → │本番環境  │
└─────────┘   └──────┘   └─────────┘   └────────┘   └──────────┘
```

### 詳細なステージ分解

1. **ソース** - コードチェックアウト
2. **ビルド** - コンパイル、パッケージ化、コンテナ化
3. **テスト** - ユニット、統合、セキュリティスキャン
4. **ステージングデプロイ** - ステージング環境へのデプロイ
5. **統合テスト** - E2E、スモークテスト
6. **承認ゲート** - 手動承認が必要
7. **本番デプロイ** - カナリア、ブルー/グリーン、ローリング
8. **検証** - ヘルスチェック、監視
9. **ロールバック** - 失敗時の自動ロールバック

## 承認ゲートパターン

### パターン1: 手動承認

```yaml
# GitHub Actions
production-deploy:
  needs: staging-deploy
  environment:
    name: production
    url: https://app.example.com
  runs-on: ubuntu-latest
  steps:
    - name: Deploy to production
      run: |
        # デプロイメントコマンド
```

### パターン2: 時間ベース承認

```yaml
# GitLab CI
deploy:production:
  stage: deploy
  script:
    - deploy.sh production
  environment:
    name: production
  when: delayed
  start_in: 30 minutes
  only:
    - main
```

### パターン3: 複数承認者

```yaml
# Azure Pipelines
stages:
- stage: Production
  dependsOn: Staging
  jobs:
  - deployment: Deploy
    environment:
      name: production
      resourceType: Kubernetes
    strategy:
      runOnce:
        preDeploy:
          steps:
          - task: ManualValidation@0
            inputs:
              notifyUsers: 'team-leads@example.com'
              instructions: '承認前にステージングメトリクスを確認'
```

**参照:** `assets/approval-gate-template.yml`を参照

## デプロイメント戦略

### 1. ローリングデプロイメント

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 10
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 2
      maxUnavailable: 1
```

**特性:**
- 段階的ロールアウト
- ゼロダウンタイム
- 簡単なロールバック
- ほとんどのアプリケーションに最適

### 2. ブルー/グリーンデプロイメント

```yaml
# Blue（現行）
kubectl apply -f blue-deployment.yaml
kubectl label service my-app version=blue

# Green（新規）
kubectl apply -f green-deployment.yaml
# Green環境をテスト
kubectl label service my-app version=green

# 必要に応じてロールバック
kubectl label service my-app version=blue
```

**特性:**
- 即座の切り替え
- 簡単なロールバック
- インフラストラクチャコストが一時的に2倍
- 高リスクデプロイメントに適している

### 3. カナリアデプロイメント

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: my-app
spec:
  replicas: 10
  strategy:
    canary:
      steps:
      - setWeight: 10
      - pause: {duration: 5m}
      - setWeight: 25
      - pause: {duration: 5m}
      - setWeight: 50
      - pause: {duration: 5m}
      - setWeight: 100
```

**特性:**
- 段階的トラフィックシフト
- リスク軽減
- 実ユーザーテスト
- サービスメッシュなどが必要

### 4. フィーチャーフラグ

```python
from flagsmith import Flagsmith

flagsmith = Flagsmith(environment_key="API_KEY")

if flagsmith.has_feature("new_checkout_flow"):
    # 新しいコードパス
    process_checkout_v2()
else:
    # 既存のコードパス
    process_checkout_v1()
```

**特性:**
- リリースせずにデプロイ
- A/Bテスト
- 即座のロールバック
- きめ細かな制御

## パイプラインオーケストレーション

### マルチステージパイプラインの例

```yaml
name: Production Pipeline

on:
  push:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build application
        run: make build
      - name: Build Docker image
        run: docker build -t myapp:${{ github.sha }} .
      - name: Push to registry
        run: docker push myapp:${{ github.sha }}

  test:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - name: Unit tests
        run: make test
      - name: Security scan
        run: trivy image myapp:${{ github.sha }}

  deploy-staging:
    needs: test
    runs-on: ubuntu-latest
    environment:
      name: staging
    steps:
      - name: Deploy to staging
        run: kubectl apply -f k8s/staging/

  integration-test:
    needs: deploy-staging
    runs-on: ubuntu-latest
    steps:
      - name: Run E2E tests
        run: npm run test:e2e

  deploy-production:
    needs: integration-test
    runs-on: ubuntu-latest
    environment:
      name: production
    steps:
      - name: Canary deployment
        run: |
          kubectl apply -f k8s/production/
          kubectl argo rollouts promote my-app

  verify:
    needs: deploy-production
    runs-on: ubuntu-latest
    steps:
      - name: Health check
        run: curl -f https://app.example.com/health
      - name: Notify team
        run: |
          curl -X POST ${{ secrets.SLACK_WEBHOOK }} \
            -d '{"text":"本番デプロイメント成功!"}'
```

## パイプラインベストプラクティス

1. **早期失敗** - 迅速なテストを最初に実行
2. **並列実行** - 独立したジョブを同時実行
3. **キャッシング** - 実行間で依存関係をキャッシュ
4. **アーティファクト管理** - ビルドアーティファクトを保存
5. **環境パリティ** - 環境を一貫して保つ
6. **シークレット管理** - シークレットストアを使用（Vaultなど）
7. **デプロイメントウィンドウ** - 適切にデプロイメントをスケジュール
8. **監視統合** - デプロイメントメトリクスを追跡
9. **ロールバック自動化** - 失敗時の自動ロールバック
10. **ドキュメント** - パイプラインステージを文書化

## ロールバック戦略

### 自動ロールバック

```yaml
deploy-and-verify:
  steps:
    - name: Deploy new version
      run: kubectl apply -f k8s/

    - name: Wait for rollout
      run: kubectl rollout status deployment/my-app

    - name: Health check
      id: health
      run: |
        for i in {1..10}; do
          if curl -sf https://app.example.com/health; then
            exit 0
          fi
          sleep 10
        done
        exit 1

    - name: Rollback on failure
      if: failure()
      run: kubectl rollout undo deployment/my-app
```

### 手動ロールバック

```bash
# リビジョン履歴を一覧表示
kubectl rollout history deployment/my-app

# 前のバージョンにロールバック
kubectl rollout undo deployment/my-app

# 特定のリビジョンにロールバック
kubectl rollout undo deployment/my-app --to-revision=3
```

## 監視とメトリクス

### 主要パイプラインメトリクス

- **デプロイメント頻度** - デプロイメントが発生する頻度
- **リードタイム** - コミットから本番までの時間
- **変更失敗率** - 失敗したデプロイメントの割合
- **平均復旧時間（MTTR）** - 障害からの復旧時間
- **パイプライン成功率** - 成功した実行の割合
- **平均パイプライン時間** - パイプライン完了までの時間

### 監視との統合

```yaml
- name: Post-deployment verification
  run: |
    # メトリクスの安定化を待つ
    sleep 60

    # エラー率をチェック
    ERROR_RATE=$(curl -s "$PROMETHEUS_URL/api/v1/query?query=rate(http_errors_total[5m])" | jq '.data.result[0].value[1]')

    if (( $(echo "$ERROR_RATE > 0.01" | bc -l) )); then
      echo "エラー率が高すぎます: $ERROR_RATE"
      exit 1
    fi
```

## 参照ファイル

- `references/pipeline-orchestration.md` - 複雑なパイプラインパターン
- `assets/approval-gate-template.yml` - 承認ワークフローテンプレート

## 関連スキル

- `github-actions-templates` - GitHub Actions実装用
- `gitlab-ci-patterns` - GitLab CI実装用
- `secrets-management` - シークレット処理用
