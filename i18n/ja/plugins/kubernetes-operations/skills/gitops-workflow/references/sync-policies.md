> **[English](../../../../../plugins/kubernetes-operations/skills/gitops-workflow/references/sync-policies.md)** | **日本語**

# GitOps同期ポリシー

## ArgoCD同期ポリシー

### 自動同期
```yaml
syncPolicy:
  automated:
    prune: true       # Gitから削除されたリソースを削除
    selfHeal: true    # 手動変更を調整
    allowEmpty: false # 空の同期を防止
```

### 手動同期
```yaml
syncPolicy:
  syncOptions:
  - PrunePropagationPolicy=foreground
  - CreateNamespace=true
```

### 同期ウィンドウ
```yaml
syncWindows:
- kind: allow
  schedule: "0 8 * * *"
  duration: 1h
  applications:
  - my-app
- kind: deny
  schedule: "0 22 * * *"
  duration: 8h
  applications:
  - '*'
```

### リトライポリシー
```yaml
syncPolicy:
  retry:
    limit: 5
    backoff:
      duration: 5s
      factor: 2
      maxDuration: 3m
```

## Flux同期ポリシー

### Kustomization同期
```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: my-app
spec:
  interval: 5m
  prune: true
  wait: true
  timeout: 5m
  retryInterval: 1m
  force: false
```

### ソース同期間隔
```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: my-app
spec:
  interval: 1m
  timeout: 60s
```

## ヘルス評価

### カスタムヘルスチェック
```yaml
# ArgoCD
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cm
  namespace: argocd
data:
  resource.customizations.health.MyCustomResource: |
    hs = {}
    if obj.status ~= nil then
      if obj.status.conditions ~= nil then
        for i, condition in ipairs(obj.status.conditions) do
          if condition.type == "Ready" and condition.status == "False" then
            hs.status = "Degraded"
            hs.message = condition.message
            return hs
          end
          if condition.type == "Ready" and condition.status == "True" then
            hs.status = "Healthy"
            hs.message = condition.message
            return hs
          end
        end
      end
    end
    hs.status = "Progressing"
    hs.message = "Waiting for status"
    return hs
```

## 同期オプション

### 共通の同期オプション
- `PrunePropagationPolicy=foreground` - 削除されたリソースの削除を待つ
- `CreateNamespace=true` - 名前空間を自動作成
- `Validate=false` - kubectlの検証をスキップ
- `PruneLast=true` - 同期後にリソースを削除
- `RespectIgnoreDifferences=true` - 差分の無視を尊重
- `ApplyOutOfSyncOnly=true` - 非同期リソースのみ適用

## ベストプラクティス

1. 非本番環境では自動同期を使用
2. 本番環境では手動承認を要求
3. メンテナンス用の同期ウィンドウを構成
4. カスタムリソースのヘルスチェックを実装
5. 大規模アプリケーションには選択的同期を使用
6. 適切なリトライポリシーを構成
7. アラート付きの同期失敗をモニタリング
8. 本番環境ではpruneを慎重に使用
9. ステージングで同期ポリシーをテスト
10. チームに同期動作を文書化
