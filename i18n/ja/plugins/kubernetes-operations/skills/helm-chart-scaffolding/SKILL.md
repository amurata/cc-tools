> **[English](../../../../plugins/kubernetes-operations/skills/helm-chart-scaffolding/SKILL.md)** | **日本語**

---
name: helm-chart-scaffolding
description: 再利用可能な構成でKubernetesアプリケーションをテンプレート化およびパッケージ化するためのHelmチャートの設計、整理、管理。Helmチャートの作成、Kubernetesアプリケーションのパッケージング、テンプレート化されたデプロイメントの実装に使用します。
---

# Helmチャートスキャフォールディング

Kubernetesアプリケーションをパッケージ化してデプロイするためのHelmチャートの作成、整理、管理に関する包括的なガイダンス。

## 目的

このスキルは、チャート構造、テンプレートパターン、values管理、検証戦略を含む、本番環境対応のHelmチャートを構築するためのステップバイステップの手順を提供します。

## このスキルを使用する場面

このスキルは以下の場合に使用します：
- ゼロから新しいHelmチャートを作成する
- 配布用のKubernetesアプリケーションをパッケージ化する
- Helmでマルチ環境デプロイメントを管理する
- 再利用可能なKubernetesマニフェスト用のテンプレート化を実装する
- Helmチャートリポジトリをセットアップする
- Helmのベストプラクティスと規約に従う

## Helmの概要

**Helm**はKubernetesのパッケージマネージャーであり、以下を実現します：
- 再利用性のためにKubernetesマニフェストをテンプレート化
- アプリケーションのリリースとロールバックを管理
- チャート間の依存関係を処理
- デプロイメントのバージョン管理を提供
- 環境間での構成管理を簡素化

## ステップバイステップのワークフロー

### 1. チャート構造の初期化

**新しいチャートを作成:**
```bash
helm create my-app
```

**標準チャート構造:**
```
my-app/
├── Chart.yaml           # チャートメタデータ
├── values.yaml          # デフォルト構成値
├── charts/              # チャート依存関係
├── templates/           # Kubernetesマニフェストテンプレート
│   ├── NOTES.txt       # インストール後の注意事項
│   ├── _helpers.tpl    # テンプレートヘルパー
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── serviceaccount.yaml
│   ├── hpa.yaml
│   └── tests/
│       └── test-connection.yaml
└── .helmignore         # 無視するファイル
```

### 2. Chart.yamlの構成

**チャートメタデータはパッケージを定義します:**

```yaml
apiVersion: v2
name: my-app
description: My Applicationのためのヘルムチャート
type: application
version: 1.0.0      # チャートバージョン
appVersion: "2.1.0" # アプリケーションバージョン

# チャート検索用のキーワード
keywords:
  - web
  - api
  - backend

# メンテナ情報
maintainers:
  - name: DevOps Team
    email: devops@example.com
    url: https://github.com/example/my-app

# ソースコードリポジトリ
sources:
  - https://github.com/example/my-app

# ホームページ
home: https://example.com

# チャートアイコン
icon: https://example.com/icon.png

# 依存関係
dependencies:
  - name: postgresql
    version: "12.0.0"
    repository: "https://charts.bitnami.com/bitnami"
    condition: postgresql.enabled
  - name: redis
    version: "17.0.0"
    repository: "https://charts.bitnami.com/bitnami"
    condition: redis.enabled
```

**参考:** 完全な例については `assets/Chart.yaml.template` を参照してください

### 3. values.yaml構造の設計

**値を階層的に整理:**

```yaml
# イメージ構成
image:
  repository: myapp
  tag: "1.0.0"
  pullPolicy: IfNotPresent

# レプリカ数
replicaCount: 3

# サービス構成
service:
  type: ClusterIP
  port: 80
  targetPort: 8080

# Ingress構成
ingress:
  enabled: false
  className: nginx
  hosts:
    - host: app.example.com
      paths:
        - path: /
          pathType: Prefix

# リソース
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"

# オートスケーリング
autoscaling:
  enabled: false
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80

# 環境変数
env:
  - name: LOG_LEVEL
    value: "info"

# ConfigMapデータ
configMap:
  data:
    APP_MODE: production

# 依存関係
postgresql:
  enabled: true
  auth:
    database: myapp
    username: myapp

redis:
  enabled: false
```

**参考:** 完全な構造については `assets/values.yaml.template` を参照してください

### 4. テンプレートファイルの作成

**Helm関数でGoテンプレートを使用:**

**templates/deployment.yaml:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "my-app.fullname" . }}
  labels:
    {{- include "my-app.labels" . | nindent 4 }}
spec:
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "my-app.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "my-app.selectorLabels" . | nindent 8 }}
    spec:
      containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        ports:
        - name: http
          containerPort: {{ .Values.service.targetPort }}
        resources:
          {{- toYaml .Values.resources | nindent 12 }}
        env:
          {{- toYaml .Values.env | nindent 12 }}
```

### 5. テンプレートヘルパーの作成

**templates/_helpers.tpl:**
```yaml
{{/*
チャート名を展開
*/}}
{{- define "my-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
デフォルトの完全修飾アプリ名を作成
*/}}
{{- define "my-app.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
共通ラベル
*/}}
{{- define "my-app.labels" -}}
helm.sh/chart: {{ include "my-app.chart" . }}
{{ include "my-app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
セレクタラベル
*/}}
{{- define "my-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "my-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
```

### 6. 依存関係の管理

**Chart.yamlに依存関係を追加:**
```yaml
dependencies:
  - name: postgresql
    version: "12.0.0"
    repository: "https://charts.bitnami.com/bitnami"
    condition: postgresql.enabled
```

**依存関係を更新:**
```bash
helm dependency update
helm dependency build
```

**依存関係の値を上書き:**
```yaml
# values.yaml
postgresql:
  enabled: true
  auth:
    database: myapp
    username: myapp
    password: changeme
  primary:
    persistence:
      enabled: true
      size: 10Gi
```

### 7. テストと検証

**検証コマンド:**
```bash
# チャートをリント
helm lint my-app/

# ドライランインストール
helm install my-app ./my-app --dry-run --debug

# テンプレートレンダリング
helm template my-app ./my-app

# valuesを使用したテンプレート
helm template my-app ./my-app -f values-prod.yaml

# 計算された値を表示
helm show values ./my-app
```

**検証スクリプト:**
```bash
#!/bin/bash
set -e

echo "チャートをリント中..."
helm lint .

echo "テンプレートレンダリングをテスト中..."
helm template test-release . --dry-run

echo "必要な値を確認中..."
helm template test-release . --validate

echo "すべての検証が成功しました！"
```

**参考:** `scripts/validate-chart.sh` を参照してください

### 8. パッケージ化と配布

**チャートをパッケージ化:**
```bash
helm package my-app/
# 作成: my-app-1.0.0.tgz
```

**チャートリポジトリを作成:**
```bash
# インデックスを作成
helm repo index .

# リポジトリにアップロード
# AWS S3の例
aws s3 sync . s3://my-helm-charts/ --exclude "*" --include "*.tgz" --include "index.yaml"
```

**チャートを使用:**
```bash
helm repo add my-repo https://charts.example.com
helm repo update
helm install my-app my-repo/my-app
```

### 9. マルチ環境構成

**環境固有のvaluesファイル:**

```
my-app/
├── values.yaml          # デフォルト
├── values-dev.yaml      # 開発
├── values-staging.yaml  # ステージング
└── values-prod.yaml     # 本番
```

**values-prod.yaml:**
```yaml
replicaCount: 5

image:
  tag: "2.1.0"

resources:
  requests:
    memory: "512Mi"
    cpu: "500m"
  limits:
    memory: "1Gi"
    cpu: "1000m"

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 20

ingress:
  enabled: true
  hosts:
    - host: app.example.com
      paths:
        - path: /
          pathType: Prefix

postgresql:
  enabled: true
  primary:
    persistence:
      size: 100Gi
```

**環境を指定してインストール:**
```bash
helm install my-app ./my-app -f values-prod.yaml --namespace production
```

### 10. フックとテストの実装

**プレインストールフック:**
```yaml
# templates/pre-install-job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ include "my-app.fullname" . }}-db-setup
  annotations:
    "helm.sh/hook": pre-install
    "helm.sh/hook-weight": "-5"
    "helm.sh/hook-delete-policy": hook-succeeded
spec:
  template:
    spec:
      containers:
      - name: db-setup
        image: postgres:15
        command: ["psql", "-c", "CREATE DATABASE myapp"]
      restartPolicy: Never
```

**接続テスト:**
```yaml
# templates/tests/test-connection.yaml
apiVersion: v1
kind: Pod
metadata:
  name: "{{ include "my-app.fullname" . }}-test-connection"
  annotations:
    "helm.sh/hook": test
spec:
  containers:
  - name: wget
    image: busybox
    command: ['wget']
    args: ['{{ include "my-app.fullname" . }}:{{ .Values.service.port }}']
  restartPolicy: Never
```

**テストを実行:**
```bash
helm test my-app
```

## 共通パターン

### パターン1: 条件付きリソース

```yaml
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "my-app.fullname" . }}
spec:
  # ...
{{- end }}
```

### パターン2: リストの反復処理

```yaml
env:
{{- range .Values.env }}
- name: {{ .name }}
  value: {{ .value | quote }}
{{- end }}
```

### パターン3: ファイルのインクルード

```yaml
data:
  config.yaml: |
    {{- .Files.Get "config/application.yaml" | nindent 4 }}
```

### パターン4: グローバル値

```yaml
global:
  imageRegistry: docker.io
  imagePullSecrets:
    - name: regcred

# テンプレートで使用:
image: {{ .Values.global.imageRegistry }}/{{ .Values.image.repository }}
```

## ベストプラクティス

1. **セマンティックバージョニングを使用** チャートとアプリのバージョンに
2. **すべての値をドキュメント化** values.yamlにコメント付きで
3. **テンプレートヘルパーを使用** 繰り返しロジックに
4. **パッケージ化前にチャートを検証**
5. **依存関係のバージョンを明示的にピン留め**
6. **オプションリソースに条件を使用**
7. **命名規則に従う**（小文字、ハイフン）
8. **NOTES.txtを含める** 使用方法の説明付きで
9. **ヘルパーを使用してラベルを一貫して追加**
10. **すべての環境でインストールをテスト**

## トラブルシューティング

**テンプレートレンダリングエラー:**
```bash
helm template my-app ./my-app --debug
```

**依存関係の問題:**
```bash
helm dependency update
helm dependency list
```

**インストール失敗:**
```bash
helm install my-app ./my-app --dry-run --debug
kubectl get events --sort-by='.lastTimestamp'
```

## 参照ファイル

- `assets/Chart.yaml.template` - チャートメタデータテンプレート
- `assets/values.yaml.template` - Values構造テンプレート
- `scripts/validate-chart.sh` - 検証スクリプト
- `references/chart-structure.md` - 詳細なチャート構成

## 関連スキル

- `k8s-manifest-generator` - ベースKubernetesマニフェスト作成用
- `gitops-workflow` - 自動化されたHelmチャートデプロイメント用
