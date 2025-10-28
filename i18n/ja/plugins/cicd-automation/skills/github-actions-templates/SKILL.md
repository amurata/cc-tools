---
name: github-actions-templates
description: アプリケーションの自動テスト、ビルド、デプロイのための本番環境対応GitHub Actionsワークフローを作成。GitHub Actionsでのci/CDセットアップ、開発ワークフローの自動化、または再利用可能なワークフローテンプレートの作成時に使用。
---

> **[English](../../../../../plugins/cicd-automation/skills/github-actions-templates/SKILL.md)** | **日本語**

# GitHub Actionsテンプレート

アプリケーションのテスト、ビルド、デプロイのための本番環境対応GitHub Actionsワークフローパターン。

## 目的

さまざまな技術スタックに対応した効率的で安全なGitHub Actionsワークフローを作成する。

## 使用タイミング

- テストとデプロイメントの自動化
- Dockerイメージのビルドとレジストリへのプッシュ
- Kubernetesクラスターへのデプロイ
- セキュリティスキャンの実行
- 複数環境のマトリックスビルド実装

## 一般的なワークフローパターン

### パターン1: テストワークフロー

```yaml
name: Test

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest

    strategy:
      matrix:
        node-version: [18.x, 20.x]

    steps:
    - uses: actions/checkout@v4

    - name: Use Node.js ${{ matrix.node-version }}
      uses: actions/setup-node@v4
      with:
        node-version: ${{ matrix.node-version }}
        cache: 'npm'

    - name: Install dependencies
      run: npm ci

    - name: Run linter
      run: npm run lint

    - name: Run tests
      run: npm test

    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        files: ./coverage/lcov.info
```

**参照:** `assets/test-workflow.yml`を参照

### パターン2: Dockerイメージのビルドとプッシュ

```yaml
name: Build and Push

on:
  push:
    branches: [ main ]
    tags: [ 'v*' ]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
    - uses: actions/checkout@v4

    - name: Log in to Container Registry
      uses: docker/login-action@v3
      with:
        registry: ${{ env.REGISTRY }}
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}

    - name: Extract metadata
      id: meta
      uses: docker/metadata-action@v5
      with:
        images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
        tags: |
          type=ref,event=branch
          type=ref,event=pr
          type=semver,pattern={{version}}
          type=semver,pattern={{major}}.{{minor}}

    - name: Build and push
      uses: docker/build-push-action@v5
      with:
        context: .
        push: true
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}
        cache-from: type=gha
        cache-to: type=gha,mode=max
```

**参照:** `assets/deploy-workflow.yml`を参照

### パターン3: Kubernetesへのデプロイ

```yaml
name: Deploy to Kubernetes

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v4

    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v4
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: us-west-2

    - name: Update kubeconfig
      run: |
        aws eks update-kubeconfig --name production-cluster --region us-west-2

    - name: Deploy to Kubernetes
      run: |
        kubectl apply -f k8s/
        kubectl rollout status deployment/my-app -n production
        kubectl get services -n production

    - name: Verify deployment
      run: |
        kubectl get pods -n production
        kubectl describe deployment my-app -n production
```

### パターン4: マトリックスビルド

```yaml
name: Matrix Build

on: [push, pull_request]

jobs:
  build:
    runs-on: ${{ matrix.os }}

    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest, windows-latest]
        python-version: ['3.9', '3.10', '3.11', '3.12']

    steps:
    - uses: actions/checkout@v4

    - name: Set up Python
      uses: actions/setup-python@v5
      with:
        python-version: ${{ matrix.python-version }}

    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements.txt

    - name: Run tests
      run: pytest
```

**参照:** `assets/matrix-build.yml`を参照

## ワークフローベストプラクティス

1. **特定のアクションバージョンを使用** (@v4、@latestではなく)
2. **依存関係をキャッシュ** してビルドを高速化
3. **シークレットを使用** して機密データを保護
4. **PRでステータスチェックを実装**
5. **マトリックスビルドを使用** してマルチバージョンテスト
6. **適切な権限を設定**
7. **再利用可能なワークフローを使用** して共通パターンを実装
8. **本番環境に承認ゲートを実装**
9. **失敗時の通知ステップを追加**
10. **機密ワークロードにセルフホストランナーを使用**

## 再利用可能なワークフロー

```yaml
# .github/workflows/reusable-test.yml
name: Reusable Test Workflow

on:
  workflow_call:
    inputs:
      node-version:
        required: true
        type: string
    secrets:
      NPM_TOKEN:
        required: true

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-node@v4
      with:
        node-version: ${{ inputs.node-version }}
    - run: npm ci
    - run: npm test
```

**再利用可能なワークフローの使用:**
```yaml
jobs:
  call-test:
    uses: ./.github/workflows/reusable-test.yml
    with:
      node-version: '20.x'
    secrets:
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

## セキュリティスキャン

```yaml
name: Security Scan

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  security:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v4

    - name: Run Trivy vulnerability scanner
      uses: aquasecurity/trivy-action@master
      with:
        scan-type: 'fs'
        scan-ref: '.'
        format: 'sarif'
        output: 'trivy-results.sarif'

    - name: Upload Trivy results to GitHub Security
      uses: github/codeql-action/upload-sarif@v2
      with:
        sarif_file: 'trivy-results.sarif'

    - name: Run Snyk Security Scan
      uses: snyk/actions/node@master
      env:
        SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
```

## 承認付きデプロイメント

```yaml
name: Deploy to Production

on:
  push:
    tags: [ 'v*' ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://app.example.com

    steps:
    - uses: actions/checkout@v4

    - name: Deploy application
      run: |
        echo "本番環境にデプロイ中..."
        # デプロイメントコマンド

    - name: Notify Slack
      if: success()
      uses: slackapi/slack-github-action@v1
      with:
        webhook-url: ${{ secrets.SLACK_WEBHOOK }}
        payload: |
          {
            "text": "本番環境へのデプロイが正常に完了しました！"
          }
```

## 参照ファイル

- `assets/test-workflow.yml` - テストワークフローテンプレート
- `assets/deploy-workflow.yml` - デプロイメントワークフローテンプレート
- `assets/matrix-build.yml` - マトリックスビルドテンプレート
- `references/common-workflows.md` - 一般的なワークフローパターン

## 関連スキル

- `gitlab-ci-patterns` - GitLab CIワークフロー用
- `deployment-pipeline-design` - パイプラインアーキテクチャ用
- `secrets-management` - シークレット処理用
