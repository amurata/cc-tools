# Claude Code Plugins (日本語版)

このディレクトリには、インストールされた日本語版プラグインが含まれています。

## 🎯 このリポジトリのオリジナルプラグイン

このディレクトリには、claude-code-workflows の日本語翻訳版プラグインに加えて、**このリポジトリで独自に開発されたオリジナルプラグイン**も含まれています。

### parallel-dev-workflow

Git Worktree + 複数AI開発インスタンスによる並行開発ワークフロープラグインです。

**主な特徴:**
- **SPECファースト**: 仕様書に基づいたタスク分割（仕様書なしでタスク分割を始めることを防止）
- **TFDD/IDD両対応**: タスクファイル駆動開発とGitHub Issue駆動開発の両方に対応
- **意味のあるテスト**: カバレッジ数値追求ではなく、テストの意味を重視
- **完了チェック徹底**: 「追加は半分、削除で完了」の原則を強制

**コンポーネント:**

| カテゴリ | 名前 |
|---------|------|
| エージェント | `spec-architect`, `task-divider`, `parallel-coordinator`, `quality-guardian` |
| コマンド | `/spec-create`, `/task-divide`, `/wave-setup`, `/parallel-sync`, `/completion-check`, `/github-flow-commit` |
| スキル | `tdd-meaningful-test`, `deep-thinking`, `worktree-management` |

詳細は [`plugins/parallel-dev-workflow/README.md`](plugins/parallel-dev-workflow/README.md) を参照してください。

## ⚠️ 重要: まだ有効化されていません

`install-ja-plugins.sh` スクリプトを実行しただけでは、プラグインは **インストール（配置）されただけ** の状態です。
Claude Code で使用するには、必要なプラグインを **有効化（アクティベーション）** する必要があります。

## 🚀 使い方

### 1. 利用可能なプラグインを確認する

Claude Code を起動し、以下のコマンドを入力して利用可能なプラグイン一覧を表示します。

```bash
/plugin
```

または、このディレクトリ内の `plugins/` フォルダを直接参照して、どのようなプラグインがあるか確認することもできます。

### 2. プラグインを有効化する

使いたいプラグインが見つかったら、`/plugin install` コマンドで有効化します。

**例:**
```bash
# Python開発用プラグインを有効化
/plugin install python-development

# Gitワークフロー用プラグインを有効化
/plugin install git-pr-workflows
```

### 3. プラグインを使用する

有効化すると、そのプラグインに含まれるエージェントやコマンドが使用可能になります。

```bash
# Pythonプロジェクトの作成（python-development プラグイン）
/python-development:python-scaffold my-api

# プルリクエストの作成（git-pr-workflows プラグイン）
/git-pr-workflows:pr-create
```

## 💡 ヒント

- **必要なものだけ有効化**: すべてのプラグインを有効化するとコンテキストが圧迫される可能性があります。現在のタスクに必要なものだけを選んで有効化することをお勧めします。
- **プラグインの探し方**: 何をインストールすればいいかわからない場合は、同梱の `suggest-plugins.py` ツール（もしあれば）を使用するか、ディレクトリ名を眺めて直感的に選んでください。

## 📂 ディレクトリ構成

- `plugins/`: 各プラグインの実体（エージェント定義、コマンド定義など）
- `.claude-plugin/`: プラグインカタログ定義ファイル
