# /wave-setup

指定したWaveのタスクに対してWorktree環境を一括セットアップ。

---

## 使い方

```
/wave-setup {wave番号} [--max-worktrees N]
```

## 実行内容

1. **Wave確認**
   - 指定Waveのタスク一覧取得
   - 前提Waveの完了確認

2. **Worktree作成**
   - 各タスク用のWorktreeを作成
   - ブランチを自動生成

3. **環境準備**
   - 依存関係インストール（必要に応じて）
   - 開発環境の初期化

## 例

```bash
# Wave 2のタスクをセットアップ（最大3並行）
/wave-setup 2 --max-worktrees 3
```

出力:
```
Wave 2 セットアップ完了

作成されたWorktree:
├── ../_wt-task-003-auth
│   └── branch: task/003_authentication
├── ../_wt-task-004-user
│   └── branch: task/004_user-model
└── ../_wt-task-005-api
    └── branch: task/005_api-endpoints

開始コマンド:
  cd ../_wt-task-003-auth && claude
  cd ../_wt-task-004-user && claude
  cd ../_wt-task-005-api && claude
```

## オプション

- `--max-worktrees N`: 同時に作成するWorktreeの最大数（デフォルト: 5）
- `--dry-run`: 実行せずに計画のみ表示
- `--skip-deps`: 依存関係インストールをスキップ

## 注意事項

- 前提Waveが完了していないと警告
- ディスク容量を確認してから実行推奨
- 各Worktreeは独立したnode_modulesを持つ場合あり

## 関連

- [parallel-coordinator Agent](../agents/parallel-coordinator.md)
- [worktree-management Skill](../skills/worktree-management.md)

## 次のステップ

セットアップ後、各Worktreeで開発を開始。
進捗確認は `/parallel-sync` を使用。
