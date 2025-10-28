---
name: git-advanced-workflows
description: rebase、cherry-pick、bisect、worktree、reflogを含む高度なGitワークフローをマスターし、クリーンな履歴を維持し、あらゆる状況から回復。複雑なGit履歴の管理、フィーチャーブランチでの協働、リポジトリ問題のトラブルシューティング時に使用。
---

> **[English](../../../../../../plugins/developer-essentials/skills/git-advanced-workflows/SKILL.md)** | **日本語**

# Git高度なワークフロー

高度なGitテクニックをマスターして、クリーンな履歴を維持し、効果的に協力し、自信を持ってあらゆる状況から回復します。

## このスキルを使用するタイミング

- マージ前のコミット履歴のクリーンアップ
- ブランチ間での特定コミットの適用
- バグを導入したコミットの発見
- 複数の機能を同時に作業
- Gitの間違いや失われたコミットからの回復
- 複雑なブランチワークフローの管理
- レビュー用のクリーンなPRの準備
- 分岐したブランチの同期

## コア概念

### 1. インタラクティブRebase

インタラクティブrebaseは、Git履歴編集のスイスアーミーナイフです。

**一般的な操作：**
- `pick`：コミットをそのまま保持
- `reword`：コミットメッセージを変更
- `edit`：コミット内容を修正
- `squash`：前のコミットと結合
- `fixup`：squashと同様だがメッセージを破棄
- `drop`：コミットを完全に削除

**基本的な使用法：**
```bash
# 最後の5コミットをrebase
git rebase -i HEAD~5

# 現在のブランチの全コミットをrebase
git rebase -i $(git merge-base HEAD main)

# 特定のコミットにrebase
git rebase -i abc123
```

### 2. Cherry-Pick

ブランチ全体をマージせずに、一つのブランチから別のブランチへ特定のコミットを適用。

```bash
# 単一コミットをcherry-pick
git cherry-pick abc123

# コミット範囲をcherry-pick（開始は含まない）
git cherry-pick abc123..def456

# コミットせずにcherry-pick（変更をステージングのみ）
git cherry-pick -n abc123

# コミットメッセージを編集してcherry-pick
git cherry-pick -e abc123
```

### 3. Git Bisect

コミット履歴を二分探索して、バグを導入したコミットを見つける。

```bash
# bisectを開始
git bisect start

# 現在のコミットを不良としてマーク
git bisect bad

# 既知の正常なコミットをマーク
git bisect good v1.0.0

# Gitが中間のコミットをチェックアウト - テスト
# その後、正常または不良としてマーク
git bisect good  # または：git bisect bad

# バグが見つかるまで継続
# 完了時
git bisect reset
```

**自動Bisect：**
```bash
# スクリプトを使って自動テスト
git bisect start HEAD v1.0.0
git bisect run ./test.sh

# test.shは正常時0、不良時1-127（125を除く）で終了すべき
```

### 4. Worktree

スタッシュやブランチ切り替えなしで、複数のブランチを同時に作業。

```bash
# 既存のworktreeをリスト
git worktree list

# フィーチャーブランチ用の新しいworktreeを追加
git worktree add ../project-feature feature/new-feature

# worktreeを追加し、新しいブランチを作成
git worktree add -b bugfix/urgent ../project-hotfix main

# worktreeを削除
git worktree remove ../project-feature

# 古いworktreeを整理
git worktree prune
```

### 5. Reflog

あなたのセーフティネット - 削除されたコミットも含め、すべての参照移動を追跡。

```bash
# reflogを表示
git reflog

# 特定ブランチのreflogを表示
git reflog show feature/branch

# 削除されたコミットを復元
git reflog
# コミットハッシュを見つける
git checkout abc123
git branch recovered-branch

# 削除されたブランチを復元
git reflog
git branch deleted-branch abc123
```

## 実践的ワークフロー

### ワークフロー1：PR前のフィーチャーブランチクリーンアップ

```bash
# フィーチャーブランチから開始
git checkout feature/user-auth

# インタラクティブrebaseで履歴をクリーンアップ
git rebase -i main

# rebase操作の例：
# - 「fix typo」コミットをsquash
# - 明確性のためにコミットメッセージをreword
# - コミットを論理的に並べ替え
# - 不要なコミットをdrop

# クリーンなブランチをforce push（他に誰も使っていなければ安全）
git push --force-with-lease origin feature/user-auth
```

### ワークフロー2：複数リリースへのホットフィックス適用

```bash
# mainで修正を作成
git checkout main
git commit -m \"fix: critical security patch\"

# リリースブランチに適用
git checkout release/2.0
git cherry-pick abc123

git checkout release/1.9
git cherry-pick abc123

# コンフリクトが発生した場合の処理
git cherry-pick --continue
# または
git cherry-pick --abort
```

### ワークフロー3：バグ導入の発見

```bash
# bisectを開始
git bisect start
git bisect bad HEAD
git bisect good v2.1.0

# Gitが中間コミットをチェックアウト - テスト実行
npm test

# テストが失敗した場合
git bisect bad

# テストが通った場合
git bisect good

# Gitが自動的に次のテスト対象コミットをチェックアウト
# バグが見つかるまで繰り返し

# 自動版
git bisect start HEAD v2.1.0
git bisect run npm test
```

### ワークフロー4：マルチブランチ開発

```bash
# メインプロジェクトディレクトリ
cd ~/projects/myapp

# 緊急バグ修正用のworktreeを作成
git worktree add ../myapp-hotfix hotfix/critical-bug

# 別ディレクトリでhotfixに作業
cd ../myapp-hotfix
# 変更を加え、コミット
git commit -m \"fix: resolve critical bug\"
git push origin hotfix/critical-bug

# 中断せずにメイン作業に戻る
cd ~/projects/myapp
git fetch origin
git cherry-pick hotfix/critical-bug

# 完了時にクリーンアップ
git worktree remove ../myapp-hotfix
```

### ワークフロー5：間違いからの回復

```bash
# 間違ったコミットに誤ってreset
git reset --hard HEAD~5  # しまった！

# reflogを使って失われたコミットを見つける
git reflog
# 出力：
# abc123 HEAD@{0}: reset: moving to HEAD~5
# def456 HEAD@{1}: commit: my important changes

# 失われたコミットを回復
git reset --hard def456

# または失われたコミットからブランチを作成
git branch recovery def456
```

## 高度なテクニック

### RebaseとMerge戦略

**Rebaseを使用するとき：**
- プッシュ前のローカルコミットのクリーンアップ
- フィーチャーブランチをmainと最新状態に保つ
- レビューしやすい直線的な履歴の作成

**Mergeを使用するとき：**
- 完成した機能をmainに統合
- 協力の正確な履歴を保持
- 他者が使用している公開ブランチ

```bash
# mainの変更でフィーチャーブランチを更新（rebase）
git checkout feature/my-feature
git fetch origin
git rebase origin/main

# コンフリクトを処理
git status
# ファイル内のコンフリクトを修正
git add .
git rebase --continue

# または代わりにmerge
git merge origin/main
```

### Autosquashワークフロー

rebase中にfixupコミットを自動的にsquash。

```bash
# 初期コミットを作成
git commit -m \"feat: add user authentication\"

# 後でそのコミットの何かを修正
# 変更をステージ
git commit --fixup HEAD  # またはコミットハッシュを指定

# さらに変更を加える
git commit --fixup abc123

# autosquashでrebase
git rebase -i --autosquash main

# Gitが自動的にfixupコミットをマーク
```

### コミット分割

一つのコミットを複数の論理的なコミットに分割。

```bash
# インタラクティブrebaseを開始
git rebase -i HEAD~3

# 分割するコミットを'edit'でマーク
# Gitがそのコミットで停止

# コミットをリセットするが変更は保持
git reset HEAD^

# 論理的なチャンクでステージとコミット
git add file1.py
git commit -m \"feat: add validation\"

git add file2.py
git commit -m \"feat: add error handling\"

# rebaseを継続
git rebase --continue
```

### 部分的Cherry-Pick

コミットから特定のファイルのみをcherry-pick。

```bash
# コミット内のファイルを表示
git show --name-only abc123

# コミットから特定ファイルをチェックアウト
git checkout abc123 -- path/to/file1.py path/to/file2.py

# ステージとコミット
git commit -m \"cherry-pick: apply specific changes from abc123\"
```

## ベストプラクティス

1. **常に--force-with-leaseを使用**：--forceより安全、他者の作業を上書きしない
2. **ローカルコミットのみRebase**：プッシュ・共有済みのコミットをrebaseしない
3. **説明的なコミットメッセージ**：未来の自分が現在の自分に感謝
4. **アトミックなコミット**：各コミットは単一の論理的変更であるべき
5. **Force Push前にテスト**：履歴書き換えが何も壊していないことを確認
6. **Reflogを意識**：reflogは90日間のセーフティネットであることを覚えておく
7. **危険な操作前にブランチ**：複雑なrebase前にバックアップブランチを作成

```bash
# 安全なforce push
git push --force-with-lease origin feature/branch

# 危険な操作前にバックアップを作成
git branch backup-branch
git rebase -i main
# 何か問題が起きた場合
git reset --hard backup-branch
```

## よくある落とし穴

- **公開ブランチのRebase**：協力者に履歴コンフリクトを引き起こす
- **Leaseなしのforce push**：チームメイトの作業を上書きする可能性
- **Rebaseで作業を失う**：慎重にコンフリクトを解決、rebase後にテスト
- **Worktreeクリーンアップを忘れる**：孤立したworktreeがディスクを消費
- **実験前のバックアップを忘れる**：常にセーフティブランチを作成
- **Dirty作業ディレクトリでBisect**：bisect前にコミットまたはstash

## 回復コマンド

```bash
# 進行中の操作を中止
git rebase --abort
git merge --abort
git cherry-pick --abort
git bisect reset

# 特定コミットからファイルを復元
git restore --source=abc123 path/to/file

# 最後のコミットを取り消すが変更は保持
git reset --soft HEAD^

# 最後のコミットを取り消し、変更を破棄
git reset --hard HEAD^

# 削除されたブランチを回復（90日以内）
git reflog
git branch recovered-branch abc123
```

## リソース

- **references/git-rebase-guide.md**：インタラクティブrebaseの詳細
- **references/git-conflict-resolution.md**：高度なコンフリクト解決戦略
- **references/git-history-rewriting.md**：Git履歴の安全な書き換え
- **assets/git-workflow-checklist.md**：PR前クリーンアップチェックリスト
- **assets/git-aliases.md**：高度なワークフロー用の便利なGitエイリアス
- **scripts/git-clean-branches.sh**：マージ済みと古いブランチのクリーンアップ
