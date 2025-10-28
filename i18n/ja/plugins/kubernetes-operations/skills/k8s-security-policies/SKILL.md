---
name: k8s-security-policies
description: 本番グレードのセキュリティのためのNetworkPolicy、PodSecurityPolicy、RBACを含むKubernetesセキュリティポリシーの実装。Kubernetesクラスタのセキュリティ確保、ネットワーク分離の実装、Podセキュリティ標準の強制に使用します。
---

> **[English](../../../../plugins/kubernetes-operations/skills/k8s-security-policies/SKILL.md)** | **日本語**

# Kubernetesセキュリティポリシー

KubernetesでのNetworkPolicy、PodSecurityPolicy、RBAC、Pod Security Standardsの実装に関する包括的なガイド。

## 目的

ネットワークポリシー、Podセキュリティ標準、RBACを使用したKubernetesクラスタの多層防御セキュリティを実装します。

## このスキルを使用する場面

- ネットワークセグメンテーションの実装
- Podセキュリティ標準の構成
- 最小権限アクセスのためのRBACのセットアップ
- コンプライアンスのためのセキュリティポリシーの作成
- アドミッションコントロールの実装
- マルチテナントクラスタのセキュリティ確保

## Pod Security Standards

### 1. Privileged（制限なし）
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: privileged-ns
  labels:
    pod-security.kubernetes.io/enforce: privileged
    pod-security.kubernetes.io/audit: privileged
    pod-security.kubernetes.io/warn: privileged
```

### 2. Baseline（最小限の制限）
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: baseline-ns
  labels:
    pod-security.kubernetes.io/enforce: baseline
    pod-security.kubernetes.io/audit: baseline
    pod-security.kubernetes.io/warn: baseline
```

### 3. Restricted（最も制限的）
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: restricted-ns
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

## ネットワークポリシー

### デフォルトで全拒否
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

### フロントエンドからバックエンドへの許可
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
```

### DNSの許可
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53
```

**参考:** `assets/network-policy-template.yaml` を参照してください

## RBAC構成

### Role（名前空間スコープ）
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: production
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
```

### ClusterRole（クラスタ全体）
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: secret-reader
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "watch", "list"]
```

### RoleBinding
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: production
subjects:
- kind: User
  name: jane
  apiGroup: rbac.authorization.k8s.io
- kind: ServiceAccount
  name: default
  namespace: production
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

**参考:** `references/rbac-patterns.md` を参照してください

## Podセキュリティコンテキスト

### 制限付きPod
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: app
    image: myapp:1.0
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
        - ALL
```

## OPA Gatekeeperによるポリシー強制

### ConstraintTemplate
```yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8srequiredlabels
spec:
  crd:
    spec:
      names:
        kind: K8sRequiredLabels
      validation:
        openAPIV3Schema:
          type: object
          properties:
            labels:
              type: array
              items:
                type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8srequiredlabels
        violation[{"msg": msg, "details": {"missing_labels": missing}}] {
          provided := {label | input.review.object.metadata.labels[label]}
          required := {label | label := input.parameters.labels[_]}
          missing := required - provided
          count(missing) > 0
          msg := sprintf("missing required labels: %v", [missing])
        }
```

### Constraint
```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: require-app-label
spec:
  match:
    kinds:
      - apiGroups: ["apps"]
        kinds: ["Deployment"]
  parameters:
    labels: ["app", "environment"]
```

## サービスメッシュセキュリティ（Istio）

### PeerAuthentication（mTLS）
```yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: production
spec:
  mtls:
    mode: STRICT
```

### AuthorizationPolicy
```yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: allow-frontend
  namespace: production
spec:
  selector:
    matchLabels:
      app: backend
  action: ALLOW
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/production/sa/frontend"]
```

## ベストプラクティス

1. **名前空間レベルでPod Security Standardsを実装**
2. **ネットワークセグメンテーションにNetwork Policiesを使用**
3. **すべてのサービスアカウントに最小権限RBACを適用**
4. **アドミッションコントロールを有効化**（OPA Gatekeeper/Kyverno）
5. **非rootとしてコンテナを実行**
6. **読み取り専用ルートファイルシステムを使用**
7. **必要でない限りすべてのケーパビリティをドロップ**
8. **リソースクォータと制限範囲を実装**
9. **セキュリティイベントの監査ログを有効化**
10. **イメージの定期的なセキュリティスキャン**

## コンプライアンスフレームワーク

### CIS Kubernetesベンチマーク
- RBAC認可を使用
- 監査ログを有効化
- Pod Security Standardsを使用
- ネットワークポリシーを構成
- 保管時のシークレット暗号化を実装
- ノード認証を有効化

### NISTサイバーセキュリティフレームワーク
- 多層防御を実装
- ネットワークセグメンテーションを使用
- セキュリティモニタリングを構成
- アクセス制御を実装
- ログとモニタリングを有効化

## トラブルシューティング

**NetworkPolicyが機能しない:**
```bash
# CNIがNetworkPolicyをサポートするか確認
kubectl get nodes -o wide
kubectl describe networkpolicy <name>
```

**RBAC権限拒否:**
```bash
# 有効な権限を確認
kubectl auth can-i list pods --as system:serviceaccount:default:my-sa
kubectl auth can-i '*' '*' --as system:serviceaccount:default:my-sa
```

## 参照ファイル

- `assets/network-policy-template.yaml` - ネットワークポリシーの例
- `assets/pod-security-template.yaml` - Podセキュリティポリシー
- `references/rbac-patterns.md` - RBAC構成パターン

## 関連スキル

- `k8s-manifest-generator` - セキュアなマニフェスト作成用
- `gitops-workflow` - 自動ポリシーデプロイメント用
