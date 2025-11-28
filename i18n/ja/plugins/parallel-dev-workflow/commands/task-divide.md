# /task-divide

SPECからタスクを分割し、Wave構成を決定する。

---

## 使い方

```
/task-divide {specファイルパス} [--mode tfdd|idd]
```

## 実行内容

1. **SPEC解析**
   - 要件の抽出
   - 依存関係の特定
   - 作業単位の識別

2. **タスク生成**
   - 適切な粒度でタスク分割
   - 各タスクの受け入れ条件設定
   - 見積もり（S/M/L）

3. **Wave構成**
   - 依存関係に基づくDAG構築
   - 並行実行可能なタスクをWaveにグループ化
   - 実行順序の最適化

4. **出力**
   - TFDD: `tasks/todo/` 配下にタスクファイル生成
   - IDD: GitHub Issuesを作成

## モード

### TFDD（デフォルト）
```
/task-divide docs/specs/auth.md --mode tfdd
```
→ `tasks/todo/task-001.md`, `task-002.md`, ... を生成

### IDD（GitHub Issue駆動）
```
/task-divide docs/specs/auth.md --mode idd
```
→ GitHub Issuesを作成、ラベルでWave管理

## Wave出力例

```
Wave 1 (並行実行可能):
  - Task-001: 基盤セットアップ
  - Task-002: テスト環境構築

Wave 2 (Wave 1完了後):
  - Task-003: 認証モジュール
  - Task-004: ユーザーモデル

Wave 3 (Wave 2完了後):
  - Task-005: 統合テスト
```

## 関連

- [task-divider Agent](../agents/task-divider.md)
- [タスクテンプレート](../templates/task-template.md)

## 次のステップ

タスク分割後は `/wave-setup` でWorktree環境を準備。
