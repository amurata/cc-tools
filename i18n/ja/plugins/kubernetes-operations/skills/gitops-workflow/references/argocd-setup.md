> **[English](../../../../../plugins/kubernetes-operations/skills/gitops-workflow/references/argocd-setup.md)** | **日本語**

# ArgoCDのセットアップと構成

## インストール方法

### 1. 標準インストール
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### 2. 高可用性インストール
```bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/ha/install.yaml
```

### 3. Helmインストール
```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm install argocd argo/argo-cd -n argocd --create-namespace
```

## 初期構成

### ArgoCD UIへのアクセス
```bash
# ポートフォワード
kubectl port-forward svc/argocd-server -n argocd 8080:443

# 初期管理者パスワードを取得
argocd admin initial-password -n argocd
```

### Ingressの構成
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server-ingress
  namespace: argocd
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/ssl-passthrough: "true"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
spec:
  ingressClassName: nginx
  rules:
  - host: argocd.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              number: 443
  tls:
  - hosts:
    - argocd.example.com
    secretName: argocd-secret
```

## CLI構成

### ログイン
```bash
argocd login argocd.example.com --username admin
```

### リポジトリの追加
```bash
argocd repo add https://github.com/org/repo --username user --password token
```

### アプリケーションの作成
```bash
argocd app create my-app \
  --repo https://github.com/org/repo \
  --path apps/my-app \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace production
```

## SSO構成

### GitHub OAuth
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cm
  namespace: argocd
data:
  url: https://argocd.example.com
  dex.config: |
    connectors:
      - type: github
        id: github
        name: GitHub
        config:
          clientID: $GITHUB_CLIENT_ID
          clientSecret: $GITHUB_CLIENT_SECRET
          orgs:
          - name: my-org
```

## RBAC構成
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-rbac-cm
  namespace: argocd
data:
  policy.default: role:readonly
  policy.csv: |
    p, role:developers, applications, *, */dev, allow
    p, role:operators, applications, *, */*, allow
    g, my-org:devs, role:developers
    g, my-org:ops, role:operators
```

## ベストプラクティス

1. 本番環境でSSOを有効化
2. RBACポリシーを実装
3. チーム用の個別プロジェクトを使用
4. 監査ログを有効化
5. 通知を構成
6. マルチクラスタ用のApplicationSetsを使用
7. リソースフックを実装
8. ヘルスチェックを構成
9. メンテナンス用の同期ウィンドウを使用
10. Prometheusメトリクスでモニタリング
