> **[English](../../../../plugins/kubernetes-operations/skills/gitops-workflow/SKILL.md)** | **日本語**

---
name: gitops-workflow
description: 継続的な調整を伴う自動化された宣言的Kubernetesデプロイメント用のArgoCDとFluxを使用したGitOpsワークフローの実装。GitOps実践の実装、Kubernetesデプロイメントの自動化、宣言的インフラストラクチャ管理のセットアップに使用します。
---

# GitOpsワークフロー

ArgoCDとFlux CDを使用した自動化Kubernetesデプロイメント向けのGitOpsワークフロー実装の完全ガイド。

## 目的

ArgoCDまたはFlux CDを使用して、OpenGitOps原則に従ったKubernetes向けの宣言的でGitベースの継続的デリバリーを実装します。

## このスキルを使用する場面

- Kubernetesクラスタ用のGitOpsのセットアップ
- Gitからのアプリケーションデプロイメントの自動化
- プログレッシブデリバリー戦略の実装
- マルチクラスタデプロイメントの管理
- 自動同期ポリシーの構成
- GitOpsでのシークレット管理のセットアップ

## OpenGitOps原則

1. **宣言的** - システム全体が宣言的に記述される
2. **バージョン管理され不変** - 望ましい状態はGitに保存される
3. **自動的にプル** - ソフトウェアエージェントが望ましい状態をプルする
4. **継続的に調整** - エージェントは実際の状態と望ましい状態を調整する

## ArgoCDのセットアップ

### 1. インストール

```bash
# 名前空間を作成
kubectl create namespace argocd

# ArgoCDをインストール
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 管理者パスワードを取得
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

**参考:** 詳細なセットアップについては `references/argocd-setup.md` を参照してください

### 2. リポジトリ構造

```
gitops-repo/
├── apps/
│   ├── production/
│   │   ├── app1/
│   │   │   ├── kustomization.yaml
│   │   │   └── deployment.yaml
│   │   └── app2/
│   └── staging/
├── infrastructure/
│   ├── ingress-nginx/
│   ├── cert-manager/
│   └── monitoring/
└── argocd/
    ├── applications/
    └── projects/
```

### 3. アプリケーションの作成

```yaml
# argocd/applications/my-app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/org/gitops-repo
    targetRevision: main
    path: apps/production/my-app
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

### 4. App of Appsパターン

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: applications
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/org/gitops-repo
    targetRevision: main
    path: argocd/applications
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated: {}
```

## Flux CDのセットアップ

### 1. インストール

```bash
# Flux CLIをインストール
curl -s https://fluxcd.io/install.sh | sudo bash

# Fluxをブートストラップ
flux bootstrap github \
  --owner=org \
  --repository=gitops-repo \
  --branch=main \
  --path=clusters/production \
  --personal
```

### 2. GitRepositoryの作成

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: my-app
  namespace: flux-system
spec:
  interval: 1m
  url: https://github.com/org/my-app
  ref:
    branch: main
```

### 3. Kustomizationの作成

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: my-app
  namespace: flux-system
spec:
  interval: 5m
  path: ./deploy
  prune: true
  sourceRef:
    kind: GitRepository
    name: my-app
```

## 同期ポリシー

### 自動同期構成

**ArgoCD:**
```yaml
syncPolicy:
  automated:
    prune: true      # Gitにないリソースを削除
    selfHeal: true   # 手動変更を調整
    allowEmpty: false
  retry:
    limit: 5
    backoff:
      duration: 5s
      factor: 2
      maxDuration: 3m
```

**Flux:**
```yaml
spec:
  interval: 1m
  prune: true
  wait: true
  timeout: 5m
```

**参考:** `references/sync-policies.md` を参照してください

## プログレッシブデリバリー

### ArgoCD Rolloutsを使用したカナリアデプロイメント

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: my-app
spec:
  replicas: 5
  strategy:
    canary:
      steps:
      - setWeight: 20
      - pause: {duration: 1m}
      - setWeight: 50
      - pause: {duration: 2m}
      - setWeight: 100
```

### ブルー/グリーンデプロイメント

```yaml
strategy:
  blueGreen:
    activeService: my-app
    previewService: my-app-preview
    autoPromotionEnabled: false
```

## シークレット管理

### External Secrets Operator

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: db-credentials
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-manager
    kind: SecretStore
  target:
    name: db-credentials
  data:
  - secretKey: password
    remoteRef:
      key: prod/db/password
```

### Sealed Secrets

```bash
# シークレットを暗号化
kubeseal --format yaml < secret.yaml > sealed-secret.yaml

# sealed-secret.yamlをGitにコミット
```

## ベストプラクティス

1. **異なる環境には別のリポジトリまたはブランチを使用**
2. **Gitリポジトリ用のRBACを実装**
3. **同期失敗の通知を有効化**
4. **カスタムリソースのヘルスチェックを使用**
5. **本番環境の承認ゲートを実装**
6. **シークレットをGitから除外**（External Secretsを使用）
7. **App of Appsパターンを使用**して組織化
8. **簡単なロールバックのためにリリースをタグ付け**
9. **アラート付きの同期ステータスをモニタリング**
10. **まずステージングで変更をテスト**

## トラブルシューティング

**同期の失敗:**
```bash
argocd app get my-app
argocd app sync my-app --prune
```

**非同期ステータス:**
```bash
argocd app diff my-app
argocd app sync my-app --force
```

## 関連スキル

- `k8s-manifest-generator` - マニフェスト作成用
- `helm-chart-scaffolding` - アプリケーションパッケージング用
