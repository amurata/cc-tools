---
name: gitlab-ci-patterns
description: スケーラブルな自動化のためのマルチステージワークフロー、キャッシング、分散ランナーを備えたGitLab CI/CDパイプラインを構築。GitLab CI/CDの実装、パイプラインパフォーマンスの最適化、または自動テストとデプロイメントのセットアップ時に使用。
---

> **[English](../../../../../plugins/cicd-automation/skills/gitlab-ci-patterns/SKILL.md)** | **日本語**

# GitLab CIパターン

自動テスト、ビルド、デプロイメント用の包括的なGitLab CI/CDパイプラインパターン。

## 目的

適切なステージ構成、キャッシング、デプロイメント戦略を備えた効率的なGitLab CIパイプラインを作成する。

## 使用タイミング

- GitLabベースのCI/CDを自動化
- マルチステージパイプラインを実装
- GitLab Runnersを設定
- GitLabからKubernetesへデプロイ
- GitOpsワークフローを実装

## 基本パイプライン構造

```yaml
stages:
  - build
  - test
  - deploy

variables:
  DOCKER_DRIVER: overlay2
  DOCKER_TLS_CERTDIR: "/certs"

build:
  stage: build
  image: node:20
  script:
    - npm ci
    - npm run build
  artifacts:
    paths:
      - dist/
    expire_in: 1 hour
  cache:
    key: ${CI_COMMIT_REF_SLUG}
    paths:
      - node_modules/

test:
  stage: test
  image: node:20
  script:
    - npm ci
    - npm run lint
    - npm test
  coverage: '/Lines\s*:\s*(\d+\.\d+)%/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura-coverage.xml

deploy:
  stage: deploy
  image: bitnami/kubectl:latest
  script:
    - kubectl apply -f k8s/
    - kubectl rollout status deployment/my-app
  only:
    - main
  environment:
    name: production
    url: https://app.example.com
```

## Dockerビルドとプッシュ

```yaml
build-docker:
  stage: build
  image: docker:24
  services:
    - docker:24-dind
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA .
    - docker build -t $CI_REGISTRY_IMAGE:latest .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    - docker push $CI_REGISTRY_IMAGE:latest
  only:
    - main
    - tags
```

## マルチ環境デプロイメント

```yaml
.deploy_template: &deploy_template
  image: bitnami/kubectl:latest
  before_script:
    - kubectl config set-cluster k8s --server="$KUBE_URL" --insecure-skip-tls-verify=true
    - kubectl config set-credentials admin --token="$KUBE_TOKEN"
    - kubectl config set-context default --cluster=k8s --user=admin
    - kubectl config use-context default

deploy:staging:
  <<: *deploy_template
  stage: deploy
  script:
    - kubectl apply -f k8s/ -n staging
    - kubectl rollout status deployment/my-app -n staging
  environment:
    name: staging
    url: https://staging.example.com
  only:
    - develop

deploy:production:
  <<: *deploy_template
  stage: deploy
  script:
    - kubectl apply -f k8s/ -n production
    - kubectl rollout status deployment/my-app -n production
  environment:
    name: production
    url: https://app.example.com
  when: manual
  only:
    - main
```

## Terraformパイプライン

```yaml
stages:
  - validate
  - plan
  - apply

variables:
  TF_ROOT: ${CI_PROJECT_DIR}/terraform
  TF_VERSION: "1.6.0"

before_script:
  - cd ${TF_ROOT}
  - terraform --version

validate:
  stage: validate
  image: hashicorp/terraform:${TF_VERSION}
  script:
    - terraform init -backend=false
    - terraform validate
    - terraform fmt -check

plan:
  stage: plan
  image: hashicorp/terraform:${TF_VERSION}
  script:
    - terraform init
    - terraform plan -out=tfplan
  artifacts:
    paths:
      - ${TF_ROOT}/tfplan
    expire_in: 1 day

apply:
  stage: apply
  image: hashicorp/terraform:${TF_VERSION}
  script:
    - terraform init
    - terraform apply -auto-approve tfplan
  dependencies:
    - plan
  when: manual
  only:
    - main
```

## セキュリティスキャン

```yaml
include:
  - template: Security/SAST.gitlab-ci.yml
  - template: Security/Dependency-Scanning.gitlab-ci.yml
  - template: Security/Container-Scanning.gitlab-ci.yml

trivy-scan:
  stage: test
  image: aquasec/trivy:latest
  script:
    - trivy image --exit-code 1 --severity HIGH,CRITICAL $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
  allow_failure: true
```

## キャッシング戦略

```yaml
# node_modulesをキャッシュ
build:
  cache:
    key: ${CI_COMMIT_REF_SLUG}
    paths:
      - node_modules/
    policy: pull-push

# グローバルキャッシュ
cache:
  key: ${CI_COMMIT_REF_SLUG}
  paths:
    - .cache/
    - vendor/

# ジョブごとに個別のキャッシュ
job1:
  cache:
    key: job1-cache
    paths:
      - build/

job2:
  cache:
    key: job2-cache
    paths:
      - dist/
```

## 動的子パイプライン

```yaml
generate-pipeline:
  stage: build
  script:
    - python generate_pipeline.py > child-pipeline.yml
  artifacts:
    paths:
      - child-pipeline.yml

trigger-child:
  stage: deploy
  trigger:
    include:
      - artifact: child-pipeline.yml
        job: generate-pipeline
    strategy: depend
```

## 参照ファイル

- `assets/gitlab-ci.yml.template` - 完全なパイプラインテンプレート
- `references/pipeline-stages.md` - ステージ構成パターン

## ベストプラクティス

1. **特定のイメージタグを使用**（node:20、node:latestではなく）
2. **依存関係を適切にキャッシュ**
3. **アーティファクトを使用**してビルド出力を保存
4. **本番環境に手動ゲートを実装**
5. **環境を使用**してデプロイメントを追跡
6. **マージリクエストパイプラインを有効化**
7. **パイプラインスケジュールを使用**して定期ジョブを実行
8. **セキュリティスキャンを実装**
9. **CI/CD変数を使用**してシークレットを管理
10. **パイプラインパフォーマンスを監視**

## 関連スキル

- `github-actions-templates` - GitHub Actions用
- `deployment-pipeline-design` - アーキテクチャ用
- `secrets-management` - シークレット処理用
