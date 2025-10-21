> **[English](../../../../../plugins/kubernetes-operations/skills/helm-chart-scaffolding/references/chart-structure.md)** | **日本語**

# Helmチャート構造リファレンス

Helmチャートの構成、ファイル規約、ベストプラクティスの完全ガイド。

## 標準チャートディレクトリ構造

```
my-app/
├── Chart.yaml              # チャートメタデータ（必須）
├── Chart.lock              # 依存関係ロックファイル（生成）
├── values.yaml             # デフォルト構成値（必須）
├── values.schema.json      # values検証用のJSONスキーマ
├── .helmignore             # パッケージング時に無視するパターン
├── README.md               # チャートドキュメント
├── LICENSE                 # チャートライセンス
├── charts/                 # チャート依存関係（バンドル済み）
│   └── postgresql-12.0.0.tgz
├── crds/                   # カスタムリソース定義
│   └── my-crd.yaml
├── templates/              # Kubernetesマニフェストテンプレート（必須）
│   ├── NOTES.txt          # インストール後の手順
│   ├── _helpers.tpl       # テンプレートヘルパー関数
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── serviceaccount.yaml
│   ├── hpa.yaml
│   ├── pdb.yaml
│   ├── networkpolicy.yaml
│   └── tests/
│       └── test-connection.yaml
└── files/                  # 含める追加ファイル
    └── config/
        └── app.conf
```

## Chart.yaml仕様

### APIバージョンv2（Helm 3+）

```yaml
apiVersion: v2                    # 必須: APIバージョン
name: my-application              # 必須: チャート名
version: 1.2.3                    # 必須: チャートバージョン（SemVer）
appVersion: "2.5.0"              # アプリケーションバージョン
description: A Helm chart for my application  # 必須
type: application                 # チャートタイプ: application または library
keywords:                         # 検索キーワード
  - web
  - api
  - backend
home: https://example.com         # プロジェクトホームページ
sources:                          # ソースコードURL
  - https://github.com/example/my-app
maintainers:                      # メンテナリスト
  - name: John Doe
    email: john@example.com
    url: https://github.com/johndoe
icon: https://example.com/icon.png  # チャートアイコンURL
kubeVersion: ">=1.24.0"          # 互換性のあるKubernetesバージョン
deprecated: false                 # チャートを非推奨としてマーク
annotations:                      # 任意のアノテーション
  example.com/release-notes: https://example.com/releases/v1.2.3
dependencies:                     # チャート依存関係
  - name: postgresql
    version: "12.0.0"
    repository: "https://charts.bitnami.com/bitnami"
    condition: postgresql.enabled
    tags:
      - database
    import-values:
      - child: database
        parent: database
    alias: db
```

## チャートタイプ

### アプリケーションチャート
```yaml
type: application
```
- 標準のKubernetesアプリケーション
- インストールおよび管理可能
- K8sリソース用のテンプレートを含む

### ライブラリチャート
```yaml
type: library
```
- 共有テンプレートヘルパー
- 直接インストール不可
- 他のチャートの依存関係として使用
- templates/ディレクトリなし

## Valuesファイルの構成

### values.yaml（デフォルト）
```yaml
# グローバル値（サブチャートと共有）
global:
  imageRegistry: docker.io
  imagePullSecrets: []

# イメージ構成
image:
  registry: docker.io
  repository: myapp/web
  tag: ""  # デフォルトは .Chart.AppVersion
  pullPolicy: IfNotPresent

# デプロイメント設定
replicaCount: 1
revisionHistoryLimit: 10

# Pod構成
podAnnotations: {}
podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000

# コンテナセキュリティ
securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop:
    - ALL

# サービス
service:
  type: ClusterIP
  port: 80
  targetPort: http
  annotations: {}

# リソース
resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 100m
    memory: 128Mi

# オートスケーリング
autoscaling:
  enabled: false
  minReplicas: 1
  maxReplicas: 100
  targetCPUUtilizationPercentage: 80

# ノード選択
nodeSelector: {}
tolerations: []
affinity: {}

# モニタリング
serviceMonitor:
  enabled: false
  interval: 30s
```

### values.schema.json（検証）
```json
{
  "$schema": "https://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "replicaCount": {
      "type": "integer",
      "minimum": 1
    },
    "image": {
      "type": "object",
      "required": ["repository"],
      "properties": {
        "repository": {
          "type": "string"
        },
        "tag": {
          "type": "string"
        },
        "pullPolicy": {
          "type": "string",
          "enum": ["Always", "IfNotPresent", "Never"]
        }
      }
    }
  },
  "required": ["image"]
}
```

## テンプレートファイル

### テンプレート命名規則

- **ハイフン付き小文字**: `deployment.yaml`、`service-account.yaml`
- **部分テンプレート**: アンダースコア接頭辞 `_helpers.tpl`
- **テスト**: `templates/tests/`に配置
- **CRD**: `crds/`に配置（テンプレート化されない）

### 共通テンプレート

#### _helpers.tpl
```yaml
{{/*
標準命名ヘルパー
*/}}
{{- define "my-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "my-app.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "my-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

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
{{- end -}}

{{- define "my-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "my-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
イメージ名ヘルパー
*/}}
{{- define "my-app.image" -}}
{{- $registry := .Values.global.imageRegistry | default .Values.image.registry -}}
{{- $repository := .Values.image.repository -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion -}}
{{- printf "%s/%s:%s" $registry $repository $tag -}}
{{- end -}}
```

#### NOTES.txt
```
{{ .Chart.Name }}をインストールいただきありがとうございます。

リリース名は{{ .Release.Name }}です。

リリースの詳細については、以下を試してください：

  $ helm status {{ .Release.Name }}
  $ helm get all {{ .Release.Name }}

{{- if .Values.ingress.enabled }}

アプリケーションURL：
{{- range .Values.ingress.hosts }}
  http{{ if $.Values.ingress.tls }}s{{ end }}://{{ .host }}{{ .path }}
{{- end }}
{{- else }}

次のコマンドを実行してアプリケーションURLを取得します：
  export POD_NAME=$(kubectl get pods --namespace {{ .Release.Namespace }} -l "app.kubernetes.io/name={{ include "my-app.name" . }}" -o jsonpath="{.items[0].metadata.name}")
  kubectl port-forward $POD_NAME 8080:80
  echo "http://127.0.0.1:8080にアクセスしてください"
{{- end }}
```

## 依存関係管理

### 依存関係の宣言

```yaml
# Chart.yaml
dependencies:
  - name: postgresql
    version: "12.0.0"
    repository: "https://charts.bitnami.com/bitnami"
    condition: postgresql.enabled  # values経由で有効/無効化
    tags:                          # 依存関係をグループ化
      - database
    import-values:                 # サブチャートから値をインポート
      - child: database
        parent: database
    alias: db                      # .Values.dbとして参照
```

### 依存関係の管理

```bash
# 依存関係を更新
helm dependency update

# 依存関係をリスト
helm dependency list

# 依存関係をビルド
helm dependency build
```

### Chart.lock

`helm dependency update`によって自動生成：

```yaml
dependencies:
- name: postgresql
  repository: https://charts.bitnami.com/bitnami
  version: 12.0.0
digest: sha256:abcd1234...
generated: "2024-01-01T00:00:00Z"
```

## .helmignore

チャートパッケージからファイルを除外：

```
# 開発ファイル
.git/
.gitignore
*.md
docs/

# ビルドアーティファクト
*.swp
*.bak
*.tmp
*.orig

# CI/CD
.travis.yml
.gitlab-ci.yml
Jenkinsfile

# テスト
test/
*.test

# IDE
.vscode/
.idea/
*.iml
```

## カスタムリソース定義（CRD）

CRDを`crds/`ディレクトリに配置：

```
crds/
├── my-app-crd.yaml
└── another-crd.yaml
```

**重要なCRD注意事項:**
- CRDは任意のテンプレートの前にインストールされる
- CRDはテンプレート化されない（`{{ }}`構文なし）
- CRDはチャートでアップグレードまたは削除されない
- インストールをスキップするには `helm install --skip-crds` を使用
- インストールをスキップするには `helm install --skip-crds` を使用

## チャートのバージョニング

### セマンティックバージョニング

- **チャートバージョン**: チャート変更時に増分
  - MAJOR: 破壊的変更
  - MINOR: 新機能、後方互換性あり
  - PATCH: バグ修正

- **アプリバージョン**: デプロイされているアプリケーションのバージョン
  - 任意の文字列が可能
  - SemVerに従う必要なし

```yaml
version: 2.3.1      # チャートバージョン
appVersion: "1.5.0" # アプリケーションバージョン
```

## チャートテスト

### テストファイル

```yaml
# templates/tests/test-connection.yaml
apiVersion: v1
kind: Pod
metadata:
  name: "{{ include "my-app.fullname" . }}-test-connection"
  annotations:
    "helm.sh/hook": test
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded
spec:
  containers:
  - name: wget
    image: busybox
    command: ['wget']
    args: ['{{ include "my-app.fullname" . }}:{{ .Values.service.port }}']
  restartPolicy: Never
```

### テストの実行

```bash
helm test my-release
helm test my-release --logs
```

## フック

Helmフックは特定のポイントでの介入を可能にします：

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ include "my-app.fullname" . }}-migration
  annotations:
    "helm.sh/hook": pre-upgrade,pre-install
    "helm.sh/hook-weight": "-5"
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded
```

### フックタイプ

- `pre-install`: テンプレートレンダリング前
- `post-install`: すべてのリソースロード後
- `pre-delete`: リソース削除前
- `post-delete`: すべてのリソース削除後
- `pre-upgrade`: アップグレード前
- `post-upgrade`: アップグレード後
- `pre-rollback`: ロールバック前
- `post-rollback`: ロールバック後
- `test`: `helm test`で実行

### フックの重み

フックの実行順序を制御（-5から5、低い方が先に実行）

### フック削除ポリシー

- `before-hook-creation`: 新しいフック前に以前のフックを削除
- `hook-succeeded`: 成功した実行後に削除
- `hook-failed`: フック失敗時に削除

## ベストプラクティス

1. **繰り返しテンプレートロジックにヘルパーを使用**
2. **テンプレート内の文字列を引用**: `{{ .Values.name | quote }}`
3. **values.schema.jsonで値を検証**
4. **values.yamlですべての値をドキュメント化**
5. **チャートバージョンにセマンティックバージョニングを使用**
6. **依存関係のバージョンを正確にピン留め**
7. **使用方法付きのNOTES.txtを含める**
8. **重要な機能のテストを追加**
9. **データベース移行にフックを使用**
10. **チャートを焦点を絞ったままに** - チャートごとに1つのアプリケーション

## チャートリポジトリ構造

```
helm-charts/
├── index.yaml
├── my-app-1.0.0.tgz
├── my-app-1.1.0.tgz
├── my-app-1.2.0.tgz
└── another-chart-2.0.0.tgz
```

### リポジトリインデックスの作成

```bash
helm repo index . --url https://charts.example.com
```

## 関連リソース

- [Helmドキュメント](https://helm.sh/docs/)
- [チャートテンプレートガイド](https://helm.sh/docs/chart_template_guide/)
- [ベストプラクティス](https://helm.sh/docs/chart_best_practices/)
