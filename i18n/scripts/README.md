# インストールスクリプト

Claude Code Workflows 日本語版プラグインを簡単にインストールするためのスクリプトです。

## 📦 クイックスタート

```bash
# リポジトリをクローン
git clone https://github.com/amurata/cc-tools
cd cc-tools

# インストール（カレントディレクトリ）
./i18n/scripts/install-ja-plugins.sh .

# または、指定したディレクトリにインストール
./i18n/scripts/install-ja-plugins.sh ~/my-project
```

## 🚀 使い方

### 基本的な使用

```bash
./i18n/scripts/install-ja-plugins.sh <インストール先ディレクトリ>
```

### オプション

| オプション | 説明 |
|-----------|------|
| `-h, --help` | ヘルプメッセージを表示 |
| `-f, --force` | 既存ファイルを確認なしで上書き |
| `-n, --dry-run` | 実際にはコピーせず、何が起こるかを表示 |
| `--no-backup` | 既存ファイルのバックアップを作成しない |

### 使用例

```bash
# ドライラン（何が起こるか確認のみ）
./i18n/scripts/install-ja-plugins.sh --dry-run ~/my-project

# 強制上書き（確認プロンプトなし）
./i18n/scripts/install-ja-plugins.sh --force ~/my-project

# バックアップなしでインストール
./i18n/scripts/install-ja-plugins.sh --no-backup ~/my-project
```

## 📋 何がインストールされるか

スクリプトは以下のディレクトリをインストール先にコピーします：

```
インストール先/
├── .claude-plugin/
│   └── marketplace.json  (64個のプラグイン定義)
└── plugins/
    ├── code-documentation/
    ├── debugging-toolkit/
    ├── backend-development/
    └── ... (その他61個のプラグイン)
```

## 🔒 安全機能

### 自動バックアップ

既存のファイルがある場合、自動的にバックアップが作成されます：

```
.claude-plugin.backup.20250127_143022/
plugins.backup.20250127_143022/
```

### 確認プロンプト

既存ファイルを上書きする前に確認プロンプトが表示されます（`--force` オプション使用時を除く）。

## ❓ トラブルシューティング

### エラー: "Permission denied"

実行権限がない場合：

```bash
chmod +x i18n/scripts/install-ja-plugins.sh
```

### エラー: "ソースディレクトリが見つかりません"

スクリプトは `cc-tools` リポジトリのルートから実行する必要があります：

```bash
cd /path/to/cc-tools
./i18n/scripts/install-ja-plugins.sh <インストール先>
```

### バックアップを復元したい

バックアップディレクトリから復元：

```bash
# .claude-plugin を復元
mv .claude-plugin.backup.20250127_143022 .claude-plugin

# plugins を復元
mv plugins.backup.20250127_143022 plugins
```

## 🔄 アップデート

新しいバージョンにアップデートする場合：

```bash
# リポジトリを最新に更新
cd cc-tools
git pull origin main

# 再度インストール（既存ファイルは自動バックアップされます）
./i18n/scripts/install-ja-plugins.sh ~/my-project
```

## 💡 ヒント

### プロジェクトごとにインストール

各プロジェクトに個別にインストールすることを推奨します：

```bash
# プロジェクトAにインストール
./i18n/scripts/install-ja-plugins.sh ~/projects/project-a

# プロジェクトBにインストール
./i18n/scripts/install-ja-plugins.sh ~/projects/project-b
```

### グローバルインストールは非推奨

Claude Code の設定ディレクトリにグローバルインストールすることも可能ですが、
プロジェクトごとのインストールを推奨します。

## 📚 関連ドキュメント

- [日本語版プラグイン README](../ja/README.md)
- [元のプラグイン (wshobson/agents)](https://github.com/wshobson/agents)

## 📄 ライセンス

MIT License - 元のプラグインと同じライセンスです。
