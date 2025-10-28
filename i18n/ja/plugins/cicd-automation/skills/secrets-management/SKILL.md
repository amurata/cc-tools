---
name: secrets-management
description: Vault、AWS Secrets Manager、またはネイティブプラットフォームソリューションを使用したCI/CDパイプライン用の安全なシークレット管理を実装。機密認証情報の処理、シークレットのローテーション、またはCI/CD環境の保護時に使用。
---

> **[English](../../../../../plugins/cicd-automation/skills/secrets-management/SKILL.md)** | **日本語**

# シークレット管理

Vault、AWS Secrets Manager、その他のツールを使用したCI/CDパイプライン用の安全なシークレット管理プラクティス。

## 目的

機密情報をハードコーディングせずにCI/CDパイプラインで安全なシークレット管理を実装する。

## 使用タイミング

- APIキーと認証情報の保存
- データベースパスワードの管理
- TLS証明書の処理
- シークレットの自動ローテーション
- 最小権限アクセスの実装

## シークレット管理ツール

### HashiCorp Vault
- 集中シークレット管理
- 動的シークレット生成
- シークレットローテーション
- 監査ログ
- きめ細かなアクセス制御

### AWS Secrets Manager
- AWSネイティブソリューション
- 自動ローテーション
- RDSとの統合
- CloudFormationサポート

### Azure Key Vault
- Azureネイティブソリューション
- HSMバックアップキー
- 証明書管理
- RBAC統合

### Google Secret Manager
- GCPネイティブソリューション
- バージョニング
- IAM統合

## HashiCorp Vault統合

### Vaultのセットアップ

```bash
# Vault開発サーバーを起動
vault server -dev

# 環境を設定
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='root'

# シークレットエンジンを有効化
vault secrets enable -path=secret kv-v2

# シークレットを保存
vault kv put secret/database/config username=admin password=secret
```

### GitHub ActionsとVault

```yaml
name: Deploy with Vault Secrets

on: [push]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4

    - name: Import Secrets from Vault
      uses: hashicorp/vault-action@v2
      with:
        url: https://vault.example.com:8200
        token: ${{ secrets.VAULT_TOKEN }}
        secrets: |
          secret/data/database username | DB_USERNAME ;
          secret/data/database password | DB_PASSWORD ;
          secret/data/api key | API_KEY

    - name: Use secrets
      run: |
        echo "データベースに$DB_USERNAMEとして接続"
        # $DB_PASSWORD、$API_KEYを使用
```

### GitLab CIとVault

```yaml
deploy:
  image: vault:latest
  before_script:
    - export VAULT_ADDR=https://vault.example.com:8200
    - export VAULT_TOKEN=$VAULT_TOKEN
    - apk add curl jq
  script:
    - |
      DB_PASSWORD=$(vault kv get -field=password secret/database/config)
      API_KEY=$(vault kv get -field=key secret/api/credentials)
      echo "シークレットでデプロイ中..."
      # $DB_PASSWORD、$API_KEYを使用
```

**参照:** `references/vault-setup.md`を参照

## AWS Secrets Manager

### シークレットの保存

```bash
aws secretsmanager create-secret \
  --name production/database/password \
  --secret-string "super-secret-password"
```

### GitHub Actionsでの取得

```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    aws-region: us-west-2

- name: Get secret from AWS
  run: |
    SECRET=$(aws secretsmanager get-secret-value \
      --secret-id production/database/password \
      --query SecretString \
      --output text)
    echo "::add-mask::$SECRET"
    echo "DB_PASSWORD=$SECRET" >> $GITHUB_ENV

- name: Use secret
  run: |
    # $DB_PASSWORDを使用
    ./deploy.sh
```

### TerraformとAWS Secrets Manager

```hcl
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "production/database/password"
}

resource "aws_db_instance" "main" {
  allocated_storage    = 100
  engine              = "postgres"
  instance_class      = "db.t3.large"
  username            = "admin"
  password            = jsondecode(data.aws_secretsmanager_secret_version.db_password.secret_string)["password"]
}
```

## GitHubシークレット

### 組織/リポジトリシークレット

```yaml
- name: Use GitHub secret
  run: |
    echo "API Key: ${{ secrets.API_KEY }}"
    echo "Database URL: ${{ secrets.DATABASE_URL }}"
```

### 環境シークレット

```yaml
deploy:
  runs-on: ubuntu-latest
  environment: production
  steps:
  - name: Deploy
    run: |
      echo "${{ secrets.PROD_API_KEY }}でデプロイ中"
```

**参照:** `references/github-secrets.md`を参照

## GitLab CI/CD変数

### プロジェクト変数

```yaml
deploy:
  script:
    - echo "$API_KEYでデプロイ中"
    - echo "Database: $DATABASE_URL"
```

### 保護されマスクされた変数
- 保護: 保護されたブランチでのみ利用可能
- マスク: ジョブログで非表示
- ファイルタイプ: ファイルとして保存

## ベストプラクティス

1. **シークレットをGitにコミットしない**
2. **環境ごとに異なるシークレットを使用**
3. **シークレットを定期的にローテーション**
4. **最小権限アクセスを実装**
5. **監査ログを有効化**
6. **シークレットスキャンを使用**（GitGuardian、TruffleHog）
7. **ログでシークレットをマスク**
8. **保管時にシークレットを暗号化**
9. **可能な限り短命トークンを使用**
10. **シークレット要件を文書化**

## シークレットローテーション

### AWSでの自動ローテーション

```python
import boto3
import json

def lambda_handler(event, context):
    client = boto3.client('secretsmanager')

    # 現在のシークレットを取得
    response = client.get_secret_value(SecretId='my-secret')
    current_secret = json.loads(response['SecretString'])

    # 新しいパスワードを生成
    new_password = generate_strong_password()

    # データベースパスワードを更新
    update_database_password(new_password)

    # シークレットを更新
    client.put_secret_value(
        SecretId='my-secret',
        SecretString=json.dumps({
            'username': current_secret['username'],
            'password': new_password
        })
    )

    return {'statusCode': 200}
```

### 手動ローテーションプロセス

1. 新しいシークレットを生成
2. シークレットストアでシークレットを更新
3. アプリケーションを更新して新しいシークレットを使用
4. 機能を検証
5. 古いシークレットを無効化

## External Secrets Operator

### Kubernetes統合

```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: vault-backend
  namespace: production
spec:
  provider:
    vault:
      server: "https://vault.example.com:8200"
      path: "secret"
      version: "v2"
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "production"

---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: database-credentials
  namespace: production
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: database-credentials
    creationPolicy: Owner
  data:
  - secretKey: username
    remoteRef:
      key: database/config
      property: username
  - secretKey: password
    remoteRef:
      key: database/config
      property: password
```

## シークレットスキャン

### プリコミットフック

```bash
#!/bin/bash
# .git/hooks/pre-commit

# TruffleHogでシークレットをチェック
docker run --rm -v "$(pwd):/repo" \
  trufflesecurity/trufflehog:latest \
  filesystem --directory=/repo

if [ $? -ne 0 ]; then
  echo "❌ シークレットが検出されました！コミットがブロックされました。"
  exit 1
fi
```

### CI/CDシークレットスキャン

```yaml
secret-scan:
  stage: security
  image: trufflesecurity/trufflehog:latest
  script:
    - trufflehog filesystem .
  allow_failure: false
```

## 参照ファイル

- `references/vault-setup.md` - HashiCorp Vault設定
- `references/github-secrets.md` - GitHubシークレットベストプラクティス

## 関連スキル

- `github-actions-templates` - GitHub Actions統合用
- `gitlab-ci-patterns` - GitLab CI統合用
- `deployment-pipeline-design` - パイプラインアーキテクチャ用
