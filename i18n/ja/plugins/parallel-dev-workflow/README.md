# parallel-dev-workflow

Git Worktree + 複数AI開発インスタンスによる並行開発ワークフロープラグイン。

## 概要

このプラグインは、大規模プロジェクト（10タスク以上）での並行開発を支援します。
SPECの策定からタスク分割、Wave実行、完了チェックまでの一連のワークフローを提供します。

## 特徴

- **SPECファースト**: 仕様書なしでタスク分割を始めることを防止
- **TFDD/IDD両対応**: タスクファイル駆動開発とGitHub Issue駆動開発の両方に対応
- **意味のあるテスト**: カバレッジ数値追求ではなく、テストの意味を重視
- **完了チェック徹底**: 「追加は半分、削除で完了」の原則を強制

## 開発フロー

```
Phase 1: 仕様策定
  /spec-create → spec-architect エージェント
  ↓
Phase 2: タスク分割
  /task-divide --mode=tfdd または --mode=idd
  → 依存関係グラフ生成 → Wave分割
  ↓
Phase 3: 並行開発準備
  /wave-setup → Worktree作成 → 進捗トラッカー初期化
  ↓
Phase 4: 開発実行
  - 意味のあるテストのみ（tdd-meaningful-test スキル）
  - 深層思考モード（deep-thinking スキル）
  - GitHub Flow準拠（github-flow-commit コマンド）
  ↓
Phase 5: 継続的統合
  /parallel-sync → 全Worktree同期 → 競合検出
  ↓
Phase 6: 完了確認
  /completion-check → 後片付け徹底
```

## コンポーネント

### エージェント

| エージェント | 説明 |
|------------|------|
| `spec-architect` | 仕様書作成の専門家。要件からSPEC作成、タスク分割の粒度アドバイス |
| `task-divider` | タスク分割の専門家。SPECからタスク作成（TFDD/IDD両対応）、依存関係グラフ作成 |
| `parallel-coordinator` | 並行開発の調整役。Worktree管理、進捗同期、競合検出 |
| `quality-guardian` | 品質守護者。完了チェックリスト、後片付け確認、意味のあるテスト判断 |

### コマンド

| コマンド | 説明 |
|---------|------|
| `/spec-create` | SPEC作成を開始 |
| `/task-divide` | タスク分割を実行（`--mode=tfdd` または `--mode=idd`） |
| `/wave-setup` | Wave分割とWorktree作成 |
| `/parallel-sync` | 全Worktree同期 |
| `/completion-check` | 完了チェック実行 |
| `/github-flow-commit` | GitHub Flow規約に従ったコミット |

### スキル

| スキル | 説明 |
|-------|------|
| `tdd-meaningful-test` | 意味のあるテストかどうかを判断。3つの基準で評価し、カバレッジ目標を設定 |
| `deep-thinking` | 深層思考モード。質優先、3層検証を実行 |
| `worktree-management` | Git Worktree操作のガイダンス |

### テンプレート

| テンプレート | 説明 |
|------------|------|
| `spec-template.md` | SPECのテンプレート |
| `task-template.md` | タスクファイルのテンプレート |
| `progress-tracker.md` | 進捗トラッカーのテンプレート |

## TDDとカバレッジの考え方

このプラグインでは、カバレッジ数値の追求ではなく「意味のあるテスト」を重視します。

### テストを書くべき3つの基準

1. **壊れたら困る**: ビジネスロジック、データ整合性、セキュリティ
2. **リファクタリング可能性**: 複雑なアルゴリズム、並行処理、状態管理
3. **モックの適切性**: 過度なモックは実際の動作を保証しない

### カバレッジ目標の決め方

```
カバレッジ目標 = f(テストの意味)

1. コアビジネスロジック層: 70%以上
2. プロジェクト全体: 実装の性質に応じて設定
   - 単純なCRUD: 25-40%
   - 複雑なドメインロジック: 50-70%
   - セキュリティクリティカル: 80%以上
```

**重要**: 数値は参考値。テストの意味を優先し、意味のないテストでカバレッジを稼ぐことは禁止。

## 適用条件

- ✅ タスク間の依存関係が明確に定義されている
- ✅ ファイル変更範囲の重複が最小限
- ✅ 複数のAI開発セッションが利用可能
- ✅ SPECが存在する（または作成する意思がある）

## 関連ドキュメント

- [GitHub Flow](../../docs/github-flow.md)
- [TDD方法論](../../docs/tdd.md)
- [Git Worktreeガイド](../../docs/git-worktree.md)

## ライセンス

MIT
