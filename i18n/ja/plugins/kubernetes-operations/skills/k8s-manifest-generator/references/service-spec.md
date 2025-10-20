> **[English](../../../../../../../kubernetes-operations/skills/k8s-manifest-generator/references/service-spec.md)** | **日本語**

# Kubernetes Service 仕様リファレンス

Kubernetes Serviceリソースの包括的なリファレンスです。サービスタイプ、ネットワーキング、ロードバランシング、およびサービス検出パターンをカバーしています。

## 概要

ServiceはPodにアクセスするための安定したネットワークエンドポイントを提供します。Serviceはサービス検出とロードバランシングを提供することで、マイクロサービス間の疎結合を可能にします。

## サービスタイプ

### 1. ClusterIP (デフォルト)

クラスター内部のIPでサービスを公開します。クラスター内からのみアクセス可能です。

```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: production
spec:
  type: ClusterIP
  selector:
    app: backend
  ports:
  - name: http
    port: 80
    targetPort: 8080
    protocol: TCP
  sessionAffinity: None
```

**ユースケース:**
- 内部マイクロサービス通信
- データベースサービス
- 内部API
- メッセージキュー

### 2. NodePort

各ノードのIPで静的ポート (30000-32767の範囲) でサービスを公開します。

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  type: NodePort
  selector:
    app: frontend
  ports:
  - name: http
    port: 80
    targetPort: 8080
    nodePort: 30080  # オプション、省略時は自動割り当て
    protocol: TCP
```

**ユースケース:**
- 開発/テスト用の外部アクセス
- ロードバランサーなしの小規模デプロイメント
- 直接ノードアクセスが必要な場合

**制限事項:**
- 限定されたポート範囲 (30000-32767)
- ノードの障害を処理する必要がある
- ノード間の組み込みロードバランシングがない

### 3. LoadBalancer

クラウドプロバイダーのロードバランサーを使用してサービスを公開します。

```yaml
apiVersion: v1
kind: Service
metadata:
  name: public-api
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
spec:
  type: LoadBalancer
  selector:
    app: api
  ports:
  - name: https
    port: 443
    targetPort: 8443
    protocol: TCP
  loadBalancerSourceRanges:
  - 203.0.113.0/24
```

**クラウド固有のアノテーション:**

**AWS:**
```yaml
annotations:
  service.beta.kubernetes.io/aws-load-balancer-type: "nlb"  # or "external"
  service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
  service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
  service.beta.kubernetes.io/aws-load-balancer-ssl-cert: "arn:aws:acm:..."
  service.beta.kubernetes.io/aws-load-balancer-backend-protocol: "http"
```

**Azure:**
```yaml
annotations:
  service.beta.kubernetes.io/azure-load-balancer-internal: "true"
  service.beta.kubernetes.io/azure-pip-name: "my-public-ip"
```

**GCP:**
```yaml
annotations:
  cloud.google.com/load-balancer-type: "Internal"
  cloud.google.com/backend-config: '{"default": "my-backend-config"}'
```

### 4. ExternalName

サービスを外部DNS名 (CNAMEレコード) にマッピングします。

```yaml
apiVersion: v1
kind: Service
metadata:
  name: external-db
spec:
  type: ExternalName
  externalName: db.external.example.com
  ports:
  - port: 5432
```

**ユースケース:**
- 外部サービスへのアクセス
- サービス移行シナリオ
- マルチクラスタサービス参照

## 完全なService仕様

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
  namespace: production
  labels:
    app: my-app
    tier: backend
  annotations:
    description: "Main application service"
    prometheus.io/scrape: "true"
spec:
  # Service type
  type: ClusterIP

  # Pod selector
  selector:
    app: my-app
    version: v1

  # Ports configuration
  ports:
  - name: http
    port: 80           # Service port
    targetPort: 8080   # Container port (or named port)
    protocol: TCP      # TCP, UDP, or SCTP

  # Session affinity
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 10800

  # IP configuration
  clusterIP: 10.0.0.10  # Optional: specific IP
  clusterIPs:
  - 10.0.0.10
  ipFamilies:
  - IPv4
  ipFamilyPolicy: SingleStack

  # External traffic policy
  externalTrafficPolicy: Local

  # Internal traffic policy
  internalTrafficPolicy: Local

  # Health check
  healthCheckNodePort: 30000

  # Load balancer config (for type: LoadBalancer)
  loadBalancerIP: 203.0.113.100
  loadBalancerSourceRanges:
  - 203.0.113.0/24

  # External IPs
  externalIPs:
  - 80.11.12.10

  # Publishing strategy
  publishNotReadyAddresses: false
```

## ポート設定

### 名前付きポート

柔軟性のためにPodで名前付きポートを使用します:

**Deployment:**
```yaml
spec:
  template:
    spec:
      containers:
      - name: app
        ports:
        - name: http
          containerPort: 8080
        - name: metrics
          containerPort: 9090
```

**Service:**
```yaml
spec:
  ports:
  - name: http
    port: 80
    targetPort: http  # 名前付きポートを参照
  - name: metrics
    port: 9090
    targetPort: metrics
```

### 複数ポート

```yaml
spec:
  ports:
  - name: http
    port: 80
    targetPort: 8080
    protocol: TCP
  - name: https
    port: 443
    targetPort: 8443
    protocol: TCP
  - name: grpc
    port: 9090
    targetPort: 9090
    protocol: TCP
```

## セッションアフィニティ

### None (デフォルト)

リクエストをPod間でランダムに分散します。

```yaml
spec:
  sessionAffinity: None
```

### ClientIP

同じクライアントIPからのリクエストを同じPodにルーティングします。

```yaml
spec:
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 10800  # 3時間
```

**ユースケース:**
- ステートフルアプリケーション
- セッションベースのアプリケーション
- WebSocket接続

## トラフィックポリシー

### 外部トラフィックポリシー

**Cluster (デフォルト):**
```yaml
spec:
  externalTrafficPolicy: Cluster
```
- すべてのノード間でロードバランス
- 追加のネットワークホップが発生する可能性がある
- ソースIPがマスクされる

**Local:**
```yaml
spec:
  externalTrafficPolicy: Local
```
- トラフィックは受信ノード上のPodにのみ送られる
- クライアントソースIPを保持
- パフォーマンスが向上 (追加ホップなし)
- 負荷が不均衡になる可能性がある

### 内部トラフィックポリシー

```yaml
spec:
  internalTrafficPolicy: Local  # or Cluster
```

クラスター内部のクライアントに対するトラフィックルーティングを制御します。

## ヘッドレスサービス

直接Podアクセス用のクラスターIPを持たないサービスです。

```yaml
apiVersion: v1
kind: Service
metadata:
  name: database
spec:
  clusterIP: None  # ヘッドレス
  selector:
    app: database
  ports:
  - port: 5432
    targetPort: 5432
```

**ユースケース:**
- StatefulSet Podの検出
- 直接Pod間通信
- カスタムロードバランシング
- データベースクラスター

**DNSが返すもの:**
- サービスIPではなく個々のPod IP
- フォーマット: `<pod-name>.<service-name>.<namespace>.svc.cluster.local`

## サービス検出

### DNS

**ClusterIP Service:**
```
<service-name>.<namespace>.svc.cluster.local
```

例:
```bash
curl http://backend-service.production.svc.cluster.local
```

**同じnamespace内:**
```bash
curl http://backend-service
```

**ヘッドレスサービス (Pod IPを返す):**
```
<pod-name>.<service-name>.<namespace>.svc.cluster.local
```

### 環境変数

KubernetesはPodにサービス情報を注入します:

```bash
# サービスホストとポート
BACKEND_SERVICE_SERVICE_HOST=10.0.0.100
BACKEND_SERVICE_SERVICE_PORT=80

# 名前付きポート用
BACKEND_SERVICE_SERVICE_PORT_HTTP=80
```

**注意:** 環境変数が注入されるには、Podがサービスの後に作成される必要があります。

## ロードバランシング

### アルゴリズム

Kubernetesはデフォルトでランダム選択を使用します。高度なロードバランシングには:

**サービスメッシュ (Istioの例):**
```yaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: my-destination-rule
spec:
  host: my-service
  trafficPolicy:
    loadBalancer:
      simple: LEAST_REQUEST  # or ROUND_ROBIN, RANDOM, PASSTHROUGH
    connectionPool:
      tcp:
        maxConnections: 100
```

### 接続制限

Pod disruption budgetとリソースlimitsを使用します:

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: my-app-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: my-app
```

## サービスメッシュ統合

### Istio VirtualService

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: my-service
spec:
  hosts:
  - my-service
  http:
  - match:
    - headers:
        version:
          exact: v2
    route:
    - destination:
        host: my-service
        subset: v2
  - route:
    - destination:
        host: my-service
        subset: v1
      weight: 90
    - destination:
        host: my-service
        subset: v2
      weight: 10
```

## 一般的なパターン

### パターン1: 内部マイクロサービス

```yaml
apiVersion: v1
kind: Service
metadata:
  name: user-service
  namespace: backend
  labels:
    app: user-service
    tier: backend
spec:
  type: ClusterIP
  selector:
    app: user-service
  ports:
  - name: http
    port: 8080
    targetPort: http
    protocol: TCP
  - name: grpc
    port: 9090
    targetPort: grpc
    protocol: TCP
```

### パターン2: ロードバランサーを持つパブリックAPI

```yaml
apiVersion: v1
kind: Service
metadata:
  name: api-gateway
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    service.beta.kubernetes.io/aws-load-balancer-ssl-cert: "arn:aws:acm:..."
spec:
  type: LoadBalancer
  externalTrafficPolicy: Local
  selector:
    app: api-gateway
  ports:
  - name: https
    port: 443
    targetPort: 8443
    protocol: TCP
  loadBalancerSourceRanges:
  - 0.0.0.0/0
```

### パターン3: ヘッドレスサービスを持つStatefulSet

```yaml
apiVersion: v1
kind: Service
metadata:
  name: cassandra
spec:
  clusterIP: None
  selector:
    app: cassandra
  ports:
  - port: 9042
    targetPort: 9042
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: cassandra
spec:
  serviceName: cassandra
  replicas: 3
  selector:
    matchLabels:
      app: cassandra
  template:
    metadata:
      labels:
        app: cassandra
    spec:
      containers:
      - name: cassandra
        image: cassandra:4.0
```

### パターン4: 外部サービスマッピング

```yaml
apiVersion: v1
kind: Service
metadata:
  name: external-database
spec:
  type: ExternalName
  externalName: prod-db.cxyz.us-west-2.rds.amazonaws.com
---
# または、IPベースの外部サービス用のEndpoints
apiVersion: v1
kind: Service
metadata:
  name: external-api
spec:
  ports:
  - port: 443
    targetPort: 443
    protocol: TCP
---
apiVersion: v1
kind: Endpoints
metadata:
  name: external-api
subsets:
- addresses:
  - ip: 203.0.113.100
  ports:
  - port: 443
```

### パターン5: メトリクスを持つマルチポートサービス

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-app
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "9090"
    prometheus.io/path: "/metrics"
spec:
  type: ClusterIP
  selector:
    app: web-app
  ports:
  - name: http
    port: 80
    targetPort: 8080
  - name: metrics
    port: 9090
    targetPort: 9090
```

## ネットワークポリシー

サービスへのトラフィックを制御します:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
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

## ベストプラクティス

### サービス設定

1. **柔軟性のために名前付きポートを使用**
2. **公開ニーズに基づいて適切なサービスタイプを設定**
3. **DeploymentとService間でラベルとセレクターを一貫して使用**
4. **ステートフルアプリにはセッションアフィニティを設定**
5. **IP保持のために外部トラフィックポリシーをLocalに設定**
6. **StatefulSetにはヘッドレスサービスを使用**
7. **セキュリティのためにネットワークポリシーを実装**
8. **可観測性のために監視アノテーションを追加**

### 本番環境チェックリスト

- [ ] ユースケースに適したサービスタイプ
- [ ] セレクターがPodラベルにマッチ
- [ ] 明確性のために名前付きポートを使用
- [ ] 必要に応じてセッションアフィニティを設定
- [ ] トラフィックポリシーを適切に設定
- [ ] ロードバランサーアノテーションを設定 (該当する場合)
- [ ] ソースIP範囲を制限 (パブリックサービスの場合)
- [ ] ヘルスチェック設定を検証
- [ ] 監視アノテーションを追加
- [ ] ネットワークポリシーを定義

### パフォーマンスチューニング

**高トラフィック用:**
```yaml
spec:
  externalTrafficPolicy: Local
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 3600
```

**WebSocket/長時間接続用:**
```yaml
spec:
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 86400  # 24時間
```

## トラブルシューティング

### サービスにアクセスできない

```bash
# サービスが存在するか確認
kubectl get service <service-name>

# エンドポイントを確認 (Pod IPが表示されるはず)
kubectl get endpoints <service-name>

# サービスを詳細表示
kubectl describe service <service-name>

# Podがセレクターにマッチするか確認
kubectl get pods -l app=<app-name>
```

**一般的な問題:**
- セレクターがPodラベルにマッチしない
- Podが実行されていない (エンドポイントが空)
- ポートの設定ミス
- ネットワークポリシーがトラフィックをブロック

### DNS解決の失敗

```bash
# PodからDNSをテスト
kubectl run debug --rm -it --image=busybox -- nslookup <service-name>

# CoreDNSを確認
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system -l k8s-app=kube-dns
```

### ロードバランサーの問題

```bash
# ロードバランサーのステータスを確認
kubectl describe service <service-name>

# イベントを確認
kubectl get events --sort-by='.lastTimestamp'

# クラウドプロバイダーの設定を検証
kubectl describe node
```

## 関連リソース

- [Kubernetes Service API リファレンス](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.28/#service-v1-core)
- [サービスネットワーキング](https://kubernetes.io/docs/concepts/services-networking/service/)
- [サービスとPodのDNS](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/)
