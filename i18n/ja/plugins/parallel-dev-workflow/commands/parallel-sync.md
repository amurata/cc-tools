# /parallel-sync

並行開発中のWorktree間の同期と進捗確認。

---

## 使い方

```
/parallel-sync [--rebase] [--status]
```

## 実行内容

### ステータス確認（デフォルト）
```
/parallel-sync --status
```

出力:
```
並行開発ステータス

Worktree一覧:
┌────────────────────┬─────────────┬──────────┬─────────┐
│ Worktree           │ ブランチ    │ 状態     │ main差分│
├────────────────────┼─────────────┼──────────┼─────────┤
│ _wt-task-003-auth  │ task/003... │ 開発中   │ +5 commits│
│ _wt-task-004-user  │ task/004... │ 開発中   │ 同期済み │
│ _wt-task-005-api   │ task/005... │ 要rebase │ -3 commits│
└────────────────────┴─────────────┴──────────┴─────────┘

推奨アクション:
- _wt-task-005-api: mainからrebaseが必要
```

### main同期（rebase）
```
/parallel-sync --rebase
```

各Worktreeをmainの最新に同期:
1. mainをfetch
2. 各ブランチをrebase
3. コンフリクト検出時は警告

## オプション

- `--status`: ステータス表示のみ（変更なし）
- `--rebase`: 全Worktreeをmainにrebase
- `--worktree NAME`: 特定のWorktreeのみ対象
- `--force`: 警告を無視して実行

## コンフリクト対応

コンフリクト検出時:
```
⚠️ コンフリクト検出: _wt-task-005-api

対象ファイル:
- src/models/user.ts

対応方法:
1. cd ../_wt-task-005-api
2. git status で状況確認
3. コンフリクト解決
4. git rebase --continue
```

## 関連

- [parallel-coordinator Agent](../agents/parallel-coordinator.md)
- [進捗トラッカー](../templates/progress-tracker.md)

## 次のステップ

全タスク完了後は `/completion-check` で最終確認。
