> **[English](../../../../../plugins/kubernetes-operations/skills/k8s-security-policies/references/rbac-patterns.md)** | **日本語**

# RBACパターンとベストプラクティス

## 一般的なRBACパターン

### パターン1: 読み取り専用アクセス
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: read-only
rules:
- apiGroups: ["", "apps", "batch"]
  resources: ["*"]
  verbs: ["get", "list", "watch"]
```

### パターン2: 名前空間管理者
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: namespace-admin
  namespace: production
rules:
- apiGroups: ["", "apps", "batch", "extensions"]
  resources: ["*"]
  verbs: ["*"]
```

### パターン3: デプロイメントマネージャー
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: deployment-manager
  namespace: production
rules:
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
```

### パターン4: シークレットリーダー（ServiceAccount）
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: secret-reader
  namespace: production
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get"]
  resourceNames: ["app-secrets"]  # 特定のシークレットのみ
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-secret-reader
  namespace: production
subjects:
- kind: ServiceAccount
  name: my-app
  namespace: production
roleRef:
  kind: Role
  name: secret-reader
  apiGroup: rbac.authorization.k8s.io
```

### パターン5: CI/CDパイプラインアクセス
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cicd-deployer
rules:
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "create", "update", "patch"]
- apiGroups: [""]
  resources: ["services", "configmaps"]
  verbs: ["get", "list", "create", "update", "patch"]
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
```

## ServiceAccountのベストプラクティス

### 専用ServiceAccountの作成
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-app
  namespace: production
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    spec:
      serviceAccountName: my-app
      automountServiceAccountToken: false  # 不要な場合は無効化
```

### 最小権限ServiceAccount
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: my-app-role
  namespace: production
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get"]
  resourceNames: ["my-app-config"]
```

## セキュリティベストプラクティス

1. **可能な限りClusterRoleよりRoleを使用**
2. **きめ細かいアクセスのためにresourceNamesを指定**
3. **本番環境でワイルドカード権限（`*`）を避ける**
4. **各アプリ用の専用ServiceAccountを作成**
5. **不要な場合はトークンの自動マウントを無効化**
6. **未使用の権限を削除するために定期的なRBAC監査**
7. **ユーザー管理にグループを使用**
8. **名前空間の分離を実装**
9. **監査ログでRBAC使用をモニタリング**
10. **メタデータにロールの目的をドキュメント化**

## RBACのトラブルシューティング

### ユーザー権限の確認
```bash
kubectl auth can-i list pods --as john@example.com
kubectl auth can-i '*' '*' --as system:serviceaccount:default:my-app
```

### 有効な権限の表示
```bash
kubectl describe clusterrole cluster-admin
kubectl describe rolebinding -n production
```

### アクセス問題のデバッグ
```bash
kubectl get rolebindings,clusterrolebindings --all-namespaces -o wide | grep my-user
```

## 一般的なRBAC動詞

- `get` - 特定のリソースを読み取る
- `list` - タイプのすべてのリソースをリストする
- `watch` - リソースの変更を監視
- `create` - 新しいリソースを作成
- `update` - 既存のリソースを更新
- `patch` - リソースを部分的に更新
- `delete` - リソースを削除
- `deletecollection` - 複数のリソースを削除
- `*` - すべての動詞（本番環境では避ける）

## リソースのスコープ

### クラスタスコープのリソース
- Nodes
- PersistentVolumes
- ClusterRoles
- ClusterRoleBindings
- Namespaces

### 名前空間スコープのリソース
- Pods
- Services
- Deployments
- ConfigMaps
- Secrets
- Roles
- RoleBindings
