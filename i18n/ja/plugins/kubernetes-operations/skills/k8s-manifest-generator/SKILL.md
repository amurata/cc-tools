> **[English](../../../../plugins/kubernetes-operations/skills/k8s-manifest-generator/SKILL.md)** | **日本語**

---
name: k8s-manifest-generator
description: ベストプラクティスとセキュリティ標準に従った、Deployment、Service、ConfigMap、Secret用の本番環境対応Kubernetesマニフェストの作成。KubernetesYAMLマニフェストの生成、K8sリソースの作成、本番グレードのKubernetes構成の実装に使用します。
---

# Kubernetesマニフェストジェネレーター

Deployment、Service、ConfigMap、Secret、PersistentVolumeClaimを含む本番環境対応のKubernetesマニフェスト作成のためのステップバイステップガイダンス。

## 目的

このスキルは、クラウドネイティブのベストプラクティスとKubernetes規約に従った、適切に構造化され、安全で、本番環境対応のKubernetesマニフェストを生成するための包括的なガイダンスを提供します。

## このスキルを使用する場面

このスキルは以下の場合に使用します：
- 新しいKubernetes Deploymentマニフェストの作成
- ネットワーク接続用のServiceリソースの定義
- 構成管理用のConfigMapとSecretリソースの生成
- ステートフルワークロード用のPersistentVolumeClaimマニフェストの作成
- Kubernetesのベストプラクティスと命名規則に従う
- リソース制限、ヘルスチェック、セキュリティコンテキストの実装
- マルチ環境デプロイメント用のマニフェスト設計

## ステップバイステップのワークフロー

### 1. 要件の収集

**ワークロードを理解する:**
- アプリケーションタイプ（ステートレス/ステートフル）
- コンテナイメージとバージョン
- 環境変数と構成のニーズ
- ストレージ要件
- ネットワーク露出要件（内部/外部）
- リソース要件（CPU、メモリ）
- スケーリング要件
- ヘルスチェックエンドポイント

**質問事項:**
- アプリケーション名と目的は何ですか？
- 使用するコンテナイメージとタグは何ですか？
- アプリケーションは永続ストレージが必要ですか？
- アプリケーションが公開するポートは何ですか？
- 必要なシークレットや構成ファイルはありますか？
- CPUとメモリの要件は何ですか？
- アプリケーションを外部に公開する必要がありますか？

### 2. Deploymentマニフェストの作成

**この構造に従います:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: <app-name>
  namespace: <namespace>
  labels:
    app: <app-name>
    version: <version>
spec:
  replicas: 3
  selector:
    matchLabels:
      app: <app-name>
  template:
    metadata:
      labels:
        app: <app-name>
        version: <version>
    spec:
      containers:
      - name: <container-name>
        image: <image>:<tag>
        ports:
        - containerPort: <port>
          name: http
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: http
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: http
          initialDelaySeconds: 5
          periodSeconds: 5
        env:
        - name: ENV_VAR
          value: "value"
        envFrom:
        - configMapRef:
            name: <app-name>-config
        - secretRef:
            name: <app-name>-secret
```

**適用するベストプラクティス:**
- 常にリソースのrequestsとlimitsを設定
- livenessとreadinessプローブの両方を実装
- 特定のイメージタグを使用（決して`:latest`を使用しない）
- 非rootユーザー用のセキュリティコンテキストを適用
- 組織と選択にラベルを使用
- 可用性ニーズに基づいて適切なレプリカ数を設定

**参考:** 詳細なデプロイメントオプションについては `references/deployment-spec.md` を参照してください

### 3. Serviceマニフェストの作成

**適切なServiceタイプを選択:**

**ClusterIP（内部のみ）:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: <app-name>
  namespace: <namespace>
  labels:
    app: <app-name>
spec:
  type: ClusterIP
  selector:
    app: <app-name>
  ports:
  - name: http
    port: 80
    targetPort: 8080
    protocol: TCP
```

**LoadBalancer（外部アクセス）:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: <app-name>
  namespace: <namespace>
  labels:
    app: <app-name>
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: nlb
spec:
  type: LoadBalancer
  selector:
    app: <app-name>
  ports:
  - name: http
    port: 80
    targetPort: 8080
    protocol: TCP
```

**参考:** サービスタイプとネットワーキングについては `references/service-spec.md` を参照してください

### 4. ConfigMapの作成

**アプリケーション構成用:**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: <app-name>-config
  namespace: <namespace>
data:
  APP_MODE: production
  LOG_LEVEL: info
  DATABASE_HOST: db.example.com
  # 構成ファイル用
  app.properties: |
    server.port=8080
    server.host=0.0.0.0
    logging.level=INFO
```

**ベストプラクティス:**
- ConfigMapは機密でないデータのみに使用
- 関連する構成をまとめて整理
- キーに意味のある名前を使用
- コンポーネントごとに1つのConfigMapの使用を検討
- 変更時にConfigMapをバージョン管理

**参考:** 例については `assets/configmap-template.yaml` を参照してください

### 5. Secretの作成

**機密データ用:**

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: <app-name>-secret
  namespace: <namespace>
type: Opaque
stringData:
  DATABASE_PASSWORD: "changeme"
  API_KEY: "secret-api-key"
  # 証明書ファイル用
  tls.crt: |
    -----BEGIN CERTIFICATE-----
    ...
    -----END CERTIFICATE-----
  tls.key: |
    -----BEGIN PRIVATE KEY-----
    ...
    -----END PRIVATE KEY-----
```

**セキュリティ上の考慮事項:**
- 平文のシークレットをGitにコミットしない
- Sealed Secrets、External Secrets Operator、またはVaultを使用
- シークレットを定期的にローテーション
- RBACを使用してシークレットアクセスを制限
- TLSシークレットにはSecretタイプ: `kubernetes.io/tls`の使用を検討

### 6. PersistentVolumeClaimの作成（必要な場合）

**ステートフルアプリケーション用:**

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: <app-name>-data
  namespace: <namespace>
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: gp3
  resources:
    requests:
      storage: 10Gi
```

**Deploymentにマウント:**
```yaml
spec:
  template:
    spec:
      containers:
      - name: app
        volumeMounts:
        - name: data
          mountPath: /var/lib/app
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: <app-name>-data
```

**ストレージの考慮事項:**
- パフォーマンスニーズに適したStorageClassを選択
- 単一Pod アクセスにはReadWriteOnceを使用
- マルチPod共有ストレージにはReadWriteManyを使用
- バックアップ戦略を検討
- 適切な保持ポリシーを設定

### 7. セキュリティベストプラクティスの適用

**Deploymentにセキュリティコンテキストを追加:**

```yaml
spec:
  template:
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
        seccompProfile:
          type: RuntimeDefault
      containers:
      - name: app
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
```

**セキュリティチェックリスト:**
- [ ] 非rootユーザーとして実行
- [ ] すべてのケーパビリティをドロップ
- [ ] 読み取り専用ルートファイルシステムを使用
- [ ] 特権昇格を無効化
- [ ] seccompプロファイルを設定
- [ ] Pod Security Standardsを使用

### 8. ラベルとアノテーションの追加

**標準ラベル（推奨）:**

```yaml
metadata:
  labels:
    app.kubernetes.io/name: <app-name>
    app.kubernetes.io/instance: <instance-name>
    app.kubernetes.io/version: "1.0.0"
    app.kubernetes.io/component: backend
    app.kubernetes.io/part-of: <system-name>
    app.kubernetes.io/managed-by: kubectl
```

**有用なアノテーション:**

```yaml
metadata:
  annotations:
    description: "アプリケーションの説明"
    contact: "team@example.com"
    prometheus.io/scrape: "true"
    prometheus.io/port: "9090"
    prometheus.io/path: "/metrics"
```

### 9. マルチリソースマニフェストの整理

**ファイル整理オプション:**

**オプション1: `---`区切り文字付きの単一ファイル**
```yaml
# app-name.yaml
---
apiVersion: v1
kind: ConfigMap
...
---
apiVersion: v1
kind: Secret
...
---
apiVersion: apps/v1
kind: Deployment
...
---
apiVersion: v1
kind: Service
...
```

**オプション2: 個別ファイル**
```
manifests/
├── configmap.yaml
├── secret.yaml
├── deployment.yaml
├── service.yaml
└── pvc.yaml
```

**オプション3: Kustomize構造**
```
base/
├── kustomization.yaml
├── deployment.yaml
├── service.yaml
└── configmap.yaml
overlays/
├── dev/
│   └── kustomization.yaml
└── prod/
    └── kustomization.yaml
```

### 10. 検証とテスト

**検証ステップ:**

```bash
# ドライラン検証
kubectl apply -f manifest.yaml --dry-run=client

# サーバーサイド検証
kubectl apply -f manifest.yaml --dry-run=server

# kubevalで検証
kubeval manifest.yaml

# kube-scoreで検証
kube-score score manifest.yaml

# kube-linterでチェック
kube-linter lint manifest.yaml
```

**テストチェックリスト:**
- [ ] マニフェストがドライラン検証をパス
- [ ] すべての必須フィールドが存在
- [ ] リソース制限が適切
- [ ] ヘルスチェックが構成済み
- [ ] セキュリティコンテキストが設定済み
- [ ] ラベルが規約に従っている
- [ ] 名前空間が存在するか作成される

## 共通パターン

### パターン1: シンプルなステートレスWebアプリケーション

**ユースケース:** 標準のWeb APIまたはマイクロサービス

**必要なコンポーネント:**
- Deployment（HA用に3レプリカ）
- ClusterIP Service
- 構成用のConfigMap
- APIキー用のSecret
- HorizontalPodAutoscaler（オプション）

**参考:** `assets/deployment-template.yaml` を参照してください

### パターン2: ステートフルデータベースアプリケーション

**ユースケース:** データベースまたは永続ストレージアプリケーション

**必要なコンポーネント:**
- StatefulSet（Deploymentではなく）
- ヘッドレスService
- PersistentVolumeClaimテンプレート
- DB構成用のConfigMap
- 認証情報用のSecret

### パターン3: バックグラウンドジョブまたはCron

**ユースケース:** スケジュールされたタスクまたはバッチ処理

**必要なコンポーネント:**
- CronJobまたはJob
- ジョブパラメータ用のConfigMap
- 認証情報用のSecret
- RBAC付きのServiceAccount

### パターン4: マルチコンテナPod

**ユースケース:** サイドカーコンテナを持つアプリケーション

**必要なコンポーネント:**
- 複数コンテナを持つDeployment
- コンテナ間の共有ボリューム
- セットアップ用のInitコンテナ
- Service（必要な場合）

## テンプレート

以下のテンプレートは`assets/`ディレクトリで利用可能です：

- `deployment-template.yaml` - ベストプラクティス付きの標準デプロイメント
- `service-template.yaml` - サービス構成（ClusterIP、LoadBalancer、NodePort）
- `configmap-template.yaml` - 異なるデータタイプのConfigMap例
- `secret-template.yaml` - Secret例（生成、コミットされない）
- `pvc-template.yaml` - PersistentVolumeClaimテンプレート

## リファレンスドキュメント

- `references/deployment-spec.md` - 詳細なDeployment仕様
- `references/service-spec.md` - Serviceタイプとネットワーキング詳細

## ベストプラクティスのまとめ

1. **常にリソースのrequestsとlimitsを設定** - リソース枯渇を防止
2. **ヘルスチェックを実装** - Kubernetesがアプリケーションを管理できるようにする
3. **特定のイメージタグを使用** - 予測不能なデプロイメントを回避
4. **セキュリティコンテキストを適用** - 非rootで実行、ケーパビリティをドロップ
5. **ConfigMapとSecretsを使用** - 構成とコードを分離
6. **すべてにラベルを付ける** - フィルタリングと組織化を可能にする
7. **命名規則に従う** - 標準のKubernetesラベルを使用
8. **適用前に検証** - ドライランと検証ツールを使用
9. **マニフェストをバージョン管理** - バージョン管理付きのGitで保管
10. **アノテーションでドキュメント化** - 他の開発者のためのコンテキストを追加

## トラブルシューティング

**Podが起動しない:**
- イメージプルエラーをチェック: `kubectl describe pod <pod-name>`
- リソースの可用性を確認: `kubectl get nodes`
- イベントをチェック: `kubectl get events --sort-by='.lastTimestamp'`

**Serviceにアクセスできない:**
- セレクタがPodラベルと一致するか確認: `kubectl get endpoints <service-name>`
- サービスタイプとポート構成をチェック
- クラスタ内からテスト: `kubectl run debug --rm -it --image=busybox -- sh`

**ConfigMap/Secretがロードされない:**
- Deployment内の名前が一致するか確認
- 名前空間をチェック
- リソースが存在するか確認: `kubectl get configmap,secret`

## 次のステップ

マニフェスト作成後：
1. Gitリポジトリに保存
2. デプロイメント用のCI/CDパイプラインをセットアップ
3. テンプレート化にHelmまたはKustomizeの使用を検討
4. ArgoCDまたはFluxでGitOpsを実装
5. モニタリングとオブザーバビリティを追加

## 関連スキル

- `helm-chart-scaffolding` - テンプレート化とパッケージング用
- `gitops-workflow` - 自動デプロイメント用
- `k8s-security-policies` - 高度なセキュリティ構成用
