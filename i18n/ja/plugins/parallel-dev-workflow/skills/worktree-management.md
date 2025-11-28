---
name: worktree-management
description: Git Worktree操作のガイダンスを提供するスキル。Worktreeの作成、同期、削除、トラブルシューティングを支援。並行開発の基盤となるWorktree管理を円滑にする。
---

# Worktree管理スキル

Git Worktreeを使った並行開発の基盤操作を支援します。

## Worktreeとは

1つのリポジトリで複数のブランチを別ディレクトリで同時にチェックアウトできる機能。

### 利点
- ブランチ切り替え不要
- コンテキストスイッチ削減
- 複数AI Sessionの独立動作

### 制限
- 同じブランチを複数worktreeでチェックアウト不可
- ディスク容量消費増加
- `.git`ディレクトリは全worktreeで共有

## 命名規則

### Worktreeディレクトリ

```
../_wt-task-XXX-{short-name}
```

**規則**:
- プレフィックス `_wt-` を使用（ソートで上位表示）
- 親ディレクトリ（`../`）に配置（リポジトリ外）
- タスク番号と短い説明を含む

**例**:
```
../_wt-task-002-guideline
../_wt-task-003-api-design
../_wt-task-010-auth-impl
```

### ブランチ名

```
task/{task-number}_{description}
```

**例**:
```
task/002_guideline-mgmt
task/003_api-design
task/010_auth-implementation
```

## 基本操作

### 作成

```bash
# 1. mainを最新に更新
git checkout main
git pull origin main

# 2. worktreeを作成（新しいブランチと共に）
git worktree add ../_wt-task-XXX-{name} -b task/XXX_{description}

# 3. worktreeに移動
cd ../_wt-task-XXX-{name}
```

### 一覧確認

```bash
git worktree list
```

出力例:
```
/path/to/repo                  abc1234 [main]
/path/to/_wt-task-002-guideline def5678 [task/002_guideline-mgmt]
/path/to/_wt-task-003-api       ghi9012 [task/003_api-design]
```

### 同期（重要）

**マージ後は必ず全worktreeで同期**:

```bash
# 各worktreeで実行
cd ../_wt-task-002-guideline && git pull origin main
cd ../_wt-task-003-api && git pull origin main
```

### 削除

```bash
# 1. worktreeを削除
git worktree remove ../_wt-task-XXX-{name}

# 2. ローカルブランチを削除（マージ済みの場合）
git branch -d task/XXX_{description}

# 3. マージ前のブランチを強制削除する場合
git branch -D task/XXX_{description}
```

### クリーンアップ

```bash
# 孤立したworktree情報を削除
git worktree prune
```

## 配置場所のベストプラクティス

### 推奨: 親ディレクトリ

```
project-root/
  ├── src/
  ├── docs/
  └── .git/
../_wt-task-002-guideline/     ← ✅ 推奨
  ├── src/
  └── docs/
```

**理由**:
- リポジトリ外に配置 → `.gitignore`不要
- ディレクトリ汚染回避 → メインworktreeがクリーン
- IDE干渉防止 → エディタがworktreeをインデックスしない

### 非推奨

```
# ❌ リポジトリ内配置（.gitignore必須、IDEが認識）
project-root/_wt-task-002-guideline/

# ❌ /tmpディレクトリ（再起動で削除）
/tmp/_wt-task-002-guideline/

# ❌ ホームディレクトリ直下（散らかる）
~/_wt-task-002-guideline/
```

## 並行開発でのワークフロー

### 1. Wave実行時のセットアップ

```bash
# mainを最新に
git checkout main && git pull origin main

# Wave 1のworktreeを作成
git worktree add ../_wt-task-001-setup -b task/001_project-setup
git worktree add ../_wt-task-002-cicd -b task/002_cicd-config

# 各worktreeでAI Sessionを起動
# Terminal 1: cd ../_wt-task-001-setup && code .
# Terminal 2: cd ../_wt-task-002-cicd && code .
```

### 2. タスク完了後

```bash
# PR作成・マージ

# 全worktreeで同期（必須）
cd ../_wt-task-001-setup && git pull origin main
cd ../_wt-task-002-cicd && git pull origin main

# 完了したworktreeを削除
git worktree remove ../_wt-task-001-setup
git branch -d task/001_project-setup
```

### 3. 次のWaveへ

```bash
# Wave 2のworktreeを作成
git worktree add ../_wt-task-003-domain -b task/003_domain-model
git worktree add ../_wt-task-004-api -b task/004_api-design
```

## トラブルシューティング

### worktreeが削除できない

```bash
# 強制削除（未コミットの変更は失われる）
git worktree remove --force ../_wt-task-XXX-{name}
```

### 「already checked out」エラー

```bash
# 同じブランチが別のworktreeでチェックアウト済み
git worktree list  # どこでチェックアウトされているか確認

# 解決策1: 既存のworktreeを削除
git worktree remove ../_wt-old

# 解決策2: 別のブランチ名を使う
git worktree add ../_wt-task-XXX-new -b task/XXX_new
```

### 孤立したworktree情報

```bash
# 物理ディレクトリを手動削除した後
rm -rf ../_wt-task-XXX-{name}  # 物理削除

# Git管理情報のクリーンアップ
git worktree prune
```

### マージコンフリクト

```bash
# コンフリクトファイルを確認
git status

# 手動で解決後
git add .
git commit -m "resolve: merge conflict in XXX"
```

## 注意事項

### DO ✅

- worktreeは親ディレクトリに配置
- 意味のあるworktree名を使用
- マージ後は必ず全worktreeで同期
- 定期的に`git worktree prune`
- 完了したworktreeは即削除

### DON'T ❌

- worktreeディレクトリを手動で移動（`mv`禁止）
- 同じブランチを複数worktreeでチェックアウト
- 長期間使用しないworktreeを放置
- 同期せずに作業継続
- mainブランチをworktreeでチェックアウト

## クイックリファレンス

```bash
# 作成
git worktree add ../_wt-task-XXX-name -b task/XXX_desc

# 一覧
git worktree list

# 同期
git pull origin main

# 削除
git worktree remove ../_wt-task-XXX-name
git branch -d task/XXX_desc

# クリーンアップ
git worktree prune
```
