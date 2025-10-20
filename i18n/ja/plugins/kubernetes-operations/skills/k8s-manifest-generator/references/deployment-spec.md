> **[English](../../../../../../../kubernetes-operations/skills/k8s-manifest-generator/references/deployment-spec.md)** | **日本語**

# Kubernetes Deployment 仕様リファレンス

Kubernetes Deploymentリソースの包括的なリファレンスです。すべての主要なフィールド、ベストプラクティス、および一般的なパターンをカバーしています。

## 概要

Deploymentは、PodとReplicaSetの宣言的な更新を提供します。アプリケーションの望ましい状態を管理し、ロールアウト、ロールバック、およびスケーリング操作を処理します。

## 完全なDeployment仕様

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  namespace: production
  labels:
    app.kubernetes.io/name: my-app
    app.kubernetes.io/version: "1.0.0"
    app.kubernetes.io/component: backend
    app.kubernetes.io/part-of: my-system
  annotations:
    description: "Main application deployment"
    contact: "backend-team@example.com"
spec:
  # Replica management
  replicas: 3
  revisionHistoryLimit: 10

  # Pod selection
  selector:
    matchLabels:
      app: my-app
      version: v1

  # Update strategy
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0

  # Minimum time for pod to be ready
  minReadySeconds: 10

  # Deployment will fail if it doesn't progress in this time
  progressDeadlineSeconds: 600

  # Pod template
  template:
    metadata:
      labels:
        app: my-app
        version: v1
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "9090"
    spec:
      # Service account for RBAC
      serviceAccountName: my-app

      # Security context for the pod
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
        seccompProfile:
          type: RuntimeDefault

      # Init containers run before main containers
      initContainers:
      - name: init-db
        image: busybox:1.36
        command: ['sh', '-c', 'until nc -z db-service 5432; do sleep 1; done']
        securityContext:
          allowPrivilegeEscalation: false
          runAsNonRoot: true
          runAsUser: 1000

      # Main containers
      containers:
      - name: app
        image: myapp:1.0.0
        imagePullPolicy: IfNotPresent

        # Container ports
        ports:
        - name: http
          containerPort: 8080
          protocol: TCP
        - name: metrics
          containerPort: 9090
          protocol: TCP

        # Environment variables
        env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: url

        # ConfigMap and Secret references
        envFrom:
        - configMapRef:
            name: app-config
        - secretRef:
            name: app-secrets

        # Resource requests and limits
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"

        # Liveness probe
        livenessProbe:
          httpGet:
            path: /health/live
            port: http
            httpHeaders:
            - name: Custom-Header
              value: Awesome
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          successThreshold: 1
          failureThreshold: 3

        # Readiness probe
        readinessProbe:
          httpGet:
            path: /health/ready
            port: http
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
          successThreshold: 1
          failureThreshold: 3

        # Startup probe (for slow-starting containers)
        startupProbe:
          httpGet:
            path: /health/startup
            port: http
          initialDelaySeconds: 0
          periodSeconds: 10
          timeoutSeconds: 3
          successThreshold: 1
          failureThreshold: 30

        # Volume mounts
        volumeMounts:
        - name: data
          mountPath: /var/lib/app
        - name: config
          mountPath: /etc/app
          readOnly: true
        - name: tmp
          mountPath: /tmp

        # Security context for container
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          runAsUser: 1000
          capabilities:
            drop:
            - ALL

        # Lifecycle hooks
        lifecycle:
          postStart:
            exec:
              command: ["/bin/sh", "-c", "echo Container started > /tmp/started"]
          preStop:
            exec:
              command: ["/bin/sh", "-c", "sleep 15"]

      # Volumes
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: app-data
      - name: config
        configMap:
          name: app-config
      - name: tmp
        emptyDir: {}

      # DNS configuration
      dnsPolicy: ClusterFirst
      dnsConfig:
        options:
        - name: ndots
          value: "2"

      # Scheduling
      nodeSelector:
        disktype: ssd

      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - my-app
              topologyKey: kubernetes.io/hostname

      tolerations:
      - key: "app"
        operator: "Equal"
        value: "my-app"
        effect: "NoSchedule"

      # Termination
      terminationGracePeriodSeconds: 30

      # Image pull secrets
      imagePullSecrets:
      - name: regcred
```

## フィールドリファレンス

### メタデータフィールド

#### 必須フィールド
- `apiVersion`: `apps/v1` (現在の安定バージョン)
- `kind`: `Deployment`
- `metadata.name`: namespace内で一意の名前

#### 推奨されるメタデータ
- `metadata.namespace`: ターゲットnamespace (デフォルトは `default`)
- `metadata.labels`: 組織化のためのキーバリューペア
- `metadata.annotations`: 識別用ではないメタデータ

### Specフィールド

#### レプリカ管理

**`replicas`** (整数, デフォルト: 1)
- 望ましいPodインスタンス数
- ベストプラクティス: 本番環境の高可用性には3以上を使用
- 手動またはHorizontalPodAutoscalerでスケール可能

**`revisionHistoryLimit`** (整数, デフォルト: 10)
- ロールバック用に保持する古いReplicaSetの数
- 0に設定するとロールバック機能を無効化
- 長期実行されるデプロイメントのストレージオーバーヘッドを削減

#### 更新戦略

**`strategy.type`** (文字列)
- `RollingUpdate` (デフォルト): 段階的なPod置換
- `Recreate`: 新しいPodを作成する前にすべてのPodを削除

**`strategy.rollingUpdate.maxSurge`** (整数またはパーセント, デフォルト: 25%)
- 更新中に望ましいレプリカ数を超える最大Pod数
- 例: 3レプリカでmaxSurge=1の場合、更新中は最大4Podまで

**`strategy.rollingUpdate.maxUnavailable`** (整数またはパーセント, デフォルト: 25%)
- 更新中に望ましいレプリカ数を下回る最大Pod数
- ゼロダウンタイムデプロイメントには0に設定
- maxSurgeが0の場合は0にできない

**ベストプラクティス:**
```yaml
# ゼロダウンタイムデプロイメント
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1
    maxUnavailable: 0

# 高速デプロイメント (短時間のダウンタイムの可能性あり)
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 2
    maxUnavailable: 1

# 完全置換
strategy:
  type: Recreate
```

#### Podテンプレート

**`template.metadata.labels`**
- `spec.selector.matchLabels`にマッチするラベルを含める必要がある
- ブルー/グリーンデプロイメント用にバージョンラベルを追加
- 標準的なKubernetesラベルを含める

**`template.spec.containers`** (必須)
- コンテナ仕様の配列
- 少なくとも1つのコンテナが必要
- 各コンテナには一意の名前が必要

#### コンテナ設定

**イメージ管理:**
```yaml
containers:
- name: app
  image: registry.example.com/myapp:1.0.0
  imagePullPolicy: IfNotPresent  # or Always, Never
```

イメージプルポリシー:
- `IfNotPresent`: キャッシュされていない場合にプル (タグ付きイメージのデフォルト)
- `Always`: 常にプル (:latestのデフォルト)
- `Never`: プルしない、キャッシュされていない場合は失敗

**ポート宣言:**
```yaml
ports:
- name: http      # Serviceで参照するために名前を付ける
  containerPort: 8080
  protocol: TCP   # TCP (デフォルト), UDP, または SCTP
  hostPort: 8080  # オプション: ホストポートにバインド (めったに使用されない)
```

#### リソース管理

**リクエスト vs リミット:**

```yaml
resources:
  requests:
    memory: "256Mi"  # 保証されるリソース
    cpu: "250m"      # 0.25 CPUコア
  limits:
    memory: "512Mi"  # 許可される最大値
    cpu: "500m"      # 0.5 CPUコア
```

**QoSクラス (自動的に決定される):**

1. **Guaranteed**: すべてのコンテナでrequests = limits
   - 最高優先度
   - 最後に退去される

2. **Burstable**: requests < limits または requestsのみ設定
   - 中間優先度
   - Guaranteedの前に退去される

3. **BestEffort**: requestsまたはlimitsが設定されていない
   - 最低優先度
   - 最初に退去される

**ベストプラクティス:**
- 本番環境では常にrequestsを設定
- リソース独占を防ぐためにlimitsを設定
- メモリlimitsはrequestsの1.5-2倍にする
- バースト性のワークロードにはCPU limitsを高めに設定可能

#### ヘルスチェック

**プローブタイプ:**

1. **startupProbe** - 起動が遅いアプリケーション用
   ```yaml
   startupProbe:
     httpGet:
       path: /health/startup
       port: 8080
     initialDelaySeconds: 0
     periodSeconds: 10
     failureThreshold: 30  # 起動に5分 (10s * 30)
   ```

2. **livenessProbe** - 不健全なコンテナを再起動
   ```yaml
   livenessProbe:
     httpGet:
       path: /health/live
       port: 8080
     initialDelaySeconds: 30
     periodSeconds: 10
     timeoutSeconds: 5
     failureThreshold: 3  # 3回の失敗後に再起動
   ```

3. **readinessProbe** - トラフィックルーティングを制御
   ```yaml
   readinessProbe:
     httpGet:
       path: /health/ready
       port: 8080
     initialDelaySeconds: 5
     periodSeconds: 5
     failureThreshold: 3  # 3回の失敗後にサービスから除外
   ```

**プローブメカニズム:**

```yaml
# HTTP GET
httpGet:
  path: /health
  port: 8080
  httpHeaders:
  - name: Authorization
    value: Bearer token

# TCPソケット
tcpSocket:
  port: 3306

# コマンド実行
exec:
  command:
  - cat
  - /tmp/healthy

# gRPC (Kubernetes 1.24+)
grpc:
  port: 9090
  service: my.service.health.v1.Health
```

**プローブタイミングパラメータ:**

- `initialDelaySeconds`: 最初のプローブ前の待機時間
- `periodSeconds`: プローブの実行頻度
- `timeoutSeconds`: プローブのタイムアウト
- `successThreshold`: 健全とマークするために必要な成功回数 (liveness/startupでは1)
- `failureThreshold`: アクションを取る前の失敗回数

#### セキュリティコンテキスト

**Pod レベルのセキュリティコンテキスト:**
```yaml
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    runAsGroup: 1000
    fsGroup: 1000
    fsGroupChangePolicy: OnRootMismatch
    seccompProfile:
      type: RuntimeDefault
```

**コンテナレベルのセキュリティコンテキスト:**
```yaml
containers:
- name: app
  securityContext:
    allowPrivilegeEscalation: false
    readOnlyRootFilesystem: true
    runAsNonRoot: true
    runAsUser: 1000
    capabilities:
      drop:
      - ALL
      add:
      - NET_BIND_SERVICE  # 必要な場合のみ
```

**セキュリティベストプラクティス:**
- 常に非rootで実行 (`runAsNonRoot: true`)
- すべてのケーパビリティを削除し、必要なもののみ追加
- 可能な限り読み取り専用ルートファイルシステムを使用
- seccompプロファイルを有効化
- 特権昇格を無効化

#### ボリューム

**ボリュームタイプ:**

```yaml
volumes:
# PersistentVolumeClaim
- name: data
  persistentVolumeClaim:
    claimName: app-data

# ConfigMap
- name: config
  configMap:
    name: app-config
    items:
    - key: app.properties
      path: application.properties

# Secret
- name: secrets
  secret:
    secretName: app-secrets
    defaultMode: 0400

# EmptyDir (エフェメラル)
- name: cache
  emptyDir:
    sizeLimit: 1Gi

# HostPath (本番環境では避ける)
- name: host-data
  hostPath:
    path: /data
    type: DirectoryOrCreate
```

#### スケジューリング

**ノード選択:**

```yaml
# シンプルなノードセレクター
nodeSelector:
  disktype: ssd
  zone: us-west-1a

# ノードアフィニティ (より表現力が高い)
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/arch
          operator: In
          values:
          - amd64
          - arm64
```

**Podアフィニティ/アンチアフィニティ:**

```yaml
# Podをノード間に分散
affinity:
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
    - labelSelector:
        matchLabels:
          app: my-app
      topologyKey: kubernetes.io/hostname

# データベースと共同配置
affinity:
  podAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        labelSelector:
          matchLabels:
            app: database
        topologyKey: kubernetes.io/hostname
```

**トレレーション:**

```yaml
tolerations:
- key: "node.kubernetes.io/unreachable"
  operator: "Exists"
  effect: "NoExecute"
  tolerationSeconds: 30
- key: "dedicated"
  operator: "Equal"
  value: "database"
  effect: "NoSchedule"
```

## 一般的なパターン

### 高可用性Deployment

```yaml
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchLabels:
                app: my-app
            topologyKey: kubernetes.io/hostname
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app: my-app
```

### サイドカーコンテナパターン

```yaml
spec:
  template:
    spec:
      containers:
      - name: app
        image: myapp:1.0.0
        volumeMounts:
        - name: shared-logs
          mountPath: /var/log
      - name: log-forwarder
        image: fluent-bit:2.0
        volumeMounts:
        - name: shared-logs
          mountPath: /var/log
          readOnly: true
      volumes:
      - name: shared-logs
        emptyDir: {}
```

### 依存関係用のInitコンテナ

```yaml
spec:
  template:
    spec:
      initContainers:
      - name: wait-for-db
        image: busybox:1.36
        command:
        - sh
        - -c
        - |
          until nc -z database-service 5432; do
            echo "Waiting for database..."
            sleep 2
          done
      - name: run-migrations
        image: myapp:1.0.0
        command: ["./migrate", "up"]
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: url
      containers:
      - name: app
        image: myapp:1.0.0
```

## ベストプラクティス

### 本番環境チェックリスト

- [ ] リソースrequestsとlimitsを設定
- [ ] 3つのプローブタイプすべてを実装 (startup, liveness, readiness)
- [ ] 特定のイメージタグを使用 (:latestは使用しない)
- [ ] セキュリティコンテキストを設定 (非root、読み取り専用ファイルシステム)
- [ ] 高可用性のためにレプリカ数を3以上に設定
- [ ] 分散のためにPodアンチアフィニティを設定
- [ ] 適切な更新戦略を設定 (ゼロダウンタイムにはmaxUnavailable: 0)
- [ ] 設定にはConfigMapとSecretを使用
- [ ] 標準的なラベルとアノテーションを追加
- [ ] グレースフルシャットダウンを設定 (preStopフック、terminationGracePeriodSeconds)
- [ ] ロールバック機能のためにrevisionHistoryLimitを設定
- [ ] 最小限のRBAC権限を持つServiceAccountを使用

### パフォーマンスチューニング

**高速起動:**
```yaml
spec:
  minReadySeconds: 5
  strategy:
    rollingUpdate:
      maxSurge: 2
      maxUnavailable: 1
```

**ゼロダウンタイム更新:**
```yaml
spec:
  minReadySeconds: 10
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
```

**グレースフルシャットダウン:**
```yaml
spec:
  template:
    spec:
      terminationGracePeriodSeconds: 60
      containers:
      - name: app
        lifecycle:
          preStop:
            exec:
              command: ["/bin/sh", "-c", "sleep 15 && kill -SIGTERM 1"]
```

## トラブルシューティング

### 一般的な問題

**Podが起動しない:**
```bash
kubectl describe deployment <name>
kubectl get pods -l app=<app-name>
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

**ImagePullBackOff:**
- イメージ名とタグを確認
- imagePullSecretsを検証
- レジストリ認証情報を確認

**CrashLoopBackOff:**
- コンテナログを確認
- livenessProbeが積極的すぎないか検証
- リソースlimitsを確認
- アプリケーションの依存関係を検証

**Deploymentが進行中のままになる:**
- progressDeadlineSecondsを確認
- readinessProbesを検証
- リソースの可用性を確認

## 関連リソース

- [Kubernetes Deployment API リファレンス](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.28/#deployment-v1-apps)
- [Podセキュリティ標準](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [リソース管理](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
