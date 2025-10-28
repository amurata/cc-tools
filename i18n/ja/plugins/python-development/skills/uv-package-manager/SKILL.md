---
name: uv-package-manager
description: 高速Python依存関係管理、仮想環境、モダンなPythonプロジェクトワークフローのためのuvパッケージマネージャーをマスター。Pythonプロジェクトのセットアップ、依存関係の管理、uvによるPython開発ワークフローの最適化時に使用。
---

> **[English](../../../../../../plugins/python-development/skills/uv-package-manager/SKILL.md)** | **日本語**

# UVパッケージマネージャー

Rustで書かれた非常に高速なPythonパッケージインストーラーとリゾルバーであるuvを使用した、モダンなPythonプロジェクト管理と依存関係ワークフローに関する包括的なガイド。

## このスキルを使用するタイミング

- 新しいPythonプロジェクトの迅速なセットアップ
- pipよりも高速なPython依存関係の管理
- 仮想環境の作成と管理
- Pythonインタープリターのインストール
- 依存関係の競合の効率的な解決
- pip/pip-tools/poetryからの移行
- CI/CDパイプラインの高速化
- モノレポPythonプロジェクトの管理
- 再現可能なビルドのためのロックファイルの使用
- Python依存関係によるDockerビルドの最適化

## コア概念

### 1. uvとは何か？
- **超高速パッケージインストーラー**: pipより10〜100倍高速
- **Rustで記述**: Rustのパフォーマンスを活用
- **pipのドロップイン置き換え**: pipワークフローと互換性あり
- **仮想環境マネージャー**: venvの作成と管理
- **Pythonインストーラー**: Pythonバージョンのダウンロードと管理
- **リゾルバー**: 高度な依存関係解決
- **ロックファイルサポート**: 再現可能なインストール

### 2. 主な機能
- 驚異的に速いインストール速度
- グローバルキャッシュによるディスク容量効率
- pip、pip-tools、poetryと互換性
- 包括的な依存関係解決
- クロスプラットフォームサポート（Linux、macOS、Windows）
- インストールにPythonが不要
- 組み込み仮想環境サポート

### 3. UV vs 従来のツール
- **vs pip**: 10〜100倍高速、より良いリゾルバー
- **vs pip-tools**: より高速、よりシンプル、より良いUX
- **vs poetry**: より高速、意見が少ない、より軽量
- **vs conda**: より高速、Pythonに焦点

## インストール

### クイックインストール

```bash
# macOS/Linux
curl -LsSf https://astral.sh/uv/install.sh | sh

# Windows (PowerShell)
powershell -c "irm https://astral.sh/uv/install.ps1 | iex"

# pipを使用（すでにPythonがある場合）
pip install uv

# Homebrewを使用（macOS）
brew install uv

# cargoを使用（Rustがある場合）
cargo install --git https://github.com/astral-sh/uv uv
```

### インストールの確認

```bash
uv --version
# uv 0.x.x
```

## クイックスタート

### 新しいプロジェクトを作成

```bash
# 仮想環境付きの新しいプロジェクトを作成
uv init my-project
cd my-project

# または現在のディレクトリで作成
uv init .

# 初期化により作成される：
# - .python-version（Pythonバージョン）
# - pyproject.toml（プロジェクト設定）
# - README.md
# - .gitignore
```

### 依存関係をインストール

```bash
# パッケージをインストール（必要に応じてvenvを作成）
uv add requests pandas

# dev依存関係をインストール
uv add --dev pytest black ruff

# requirements.txtからインストール
uv pip install -r requirements.txt

# pyproject.tomlからインストール
uv sync
```

## 仮想環境管理

### パターン1: 仮想環境の作成

```bash
# uvで仮想環境を作成
uv venv

# 特定のPythonバージョンで作成
uv venv --python 3.12

# カスタム名で作成
uv venv my-env

# システムサイトパッケージ付きで作成
uv venv --system-site-packages

# 場所を指定
uv venv /path/to/venv
```

### パターン2: 仮想環境のアクティベート

```bash
# Linux/macOS
source .venv/bin/activate

# Windows (コマンドプロンプト)
.venv\Scripts\activate.bat

# Windows (PowerShell)
.venv\Scripts\Activate.ps1

# またはuv runを使用（アクティベーション不要）
uv run python script.py
uv run pytest
```

### パターン3: uv runの使用

```bash
# Pythonスクリプトを実行（venvを自動アクティベート）
uv run python app.py

# インストールされたCLIツールを実行
uv run black .
uv run pytest

# 特定のPythonバージョンで実行
uv run --python 3.11 python script.py

# 引数を渡す
uv run python script.py --arg value
```

## パッケージ管理

### パターン4: 依存関係の追加

```bash
# パッケージを追加（pyproject.tomlに追加）
uv add requests

# バージョン制約付きで追加
uv add "django>=4.0,<5.0"

# 複数のパッケージを追加
uv add numpy pandas matplotlib

# dev依存関係を追加
uv add --dev pytest pytest-cov

# オプションの依存関係グループを追加
uv add --optional docs sphinx

# gitから追加
uv add git+https://github.com/user/repo.git

# 特定のrefでgitから追加
uv add git+https://github.com/user/repo.git@v1.0.0

# ローカルパスから追加
uv add ./local-package

# 編集可能なローカルパッケージを追加
uv add -e ./local-package
```

### パターン5: 依存関係の削除

```bash
# パッケージを削除
uv remove requests

# dev依存関係を削除
uv remove --dev pytest

# 複数のパッケージを削除
uv remove numpy pandas matplotlib
```

### パターン6: 依存関係のアップグレード

```bash
# 特定のパッケージをアップグレード
uv add --upgrade requests

# すべてのパッケージをアップグレード
uv sync --upgrade

# パッケージを最新にアップグレード
uv add --upgrade requests

# アップグレードされるものを表示
uv tree --outdated
```

### パターン7: 依存関係のロック

```bash
# uv.lockファイルを生成
uv lock

# ロックファイルを更新
uv lock --upgrade

# インストールせずにロック
uv lock --no-install

# 特定のパッケージをロック
uv lock --upgrade-package requests
```

## Pythonバージョン管理

### パターン8: Pythonバージョンのインストール

```bash
# Pythonバージョンをインストール
uv python install 3.12

# 複数のバージョンをインストール
uv python install 3.11 3.12 3.13

# 最新バージョンをインストール
uv python install

# インストールされたバージョンをリスト
uv python list

# 利用可能なバージョンを検索
uv python list --all-versions
```

### パターン9: Pythonバージョンの設定

```bash
# プロジェクトのPythonバージョンを設定
uv python pin 3.12

# これにより.python-versionファイルが作成/更新される

# コマンドに特定のPythonバージョンを使用
uv --python 3.11 run python script.py

# 特定のバージョンでvenvを作成
uv venv --python 3.12
```

## プロジェクト設定

### パターン10: uvによるpyproject.toml

```toml
[project]
name = "my-project"
version = "0.1.0"
description = "My awesome project"
readme = "README.md"
requires-python = ">=3.8"
dependencies = [
    "requests>=2.31.0",
    "pydantic>=2.0.0",
    "click>=8.1.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=7.4.0",
    "pytest-cov>=4.1.0",
    "black>=23.0.0",
    "ruff>=0.1.0",
    "mypy>=1.5.0",
]
docs = [
    "sphinx>=7.0.0",
    "sphinx-rtd-theme>=1.3.0",
]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.uv]
dev-dependencies = [
    # uvで管理される追加のdev依存関係
]

[tool.uv.sources]
# カスタムパッケージソース
my-package = { git = "https://github.com/user/repo.git" }
```

### パターン11: 既存プロジェクトでuvを使用

```bash
# requirements.txtから移行
uv add -r requirements.txt

# poetryから移行
# すでにpyproject.tomlがある場合、使用するだけ：
uv sync

# requirements.txtにエクスポート
uv pip freeze > requirements.txt

# ハッシュ付きでエクスポート
uv pip freeze --require-hashes > requirements.txt
```

## 高度なワークフロー

### パターン12: モノレポサポート

```bash
# プロジェクト構造
# monorepo/
#   packages/
#     package-a/
#       pyproject.toml
#     package-b/
#       pyproject.toml
#   pyproject.toml（ルート）

# ルートpyproject.toml
[tool.uv.workspace]
members = ["packages/*"]

# すべてのワークスペースパッケージをインストール
uv sync

# ワークスペース依存関係を追加
uv add --path ./packages/package-a
```

### パターン13: CI/CD統合

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Install uv
        uses: astral-sh/setup-uv@v2
        with:
          enable-cache: true

      - name: Set up Python
        run: uv python install 3.12

      - name: Install dependencies
        run: uv sync --all-extras --dev

      - name: Run tests
        run: uv run pytest

      - name: Run linting
        run: |
          uv run ruff check .
          uv run black --check .
```

### パターン14: Docker統合

```dockerfile
# Dockerfile
FROM python:3.12-slim

# uvをインストール
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

# 作業ディレクトリを設定
WORKDIR /app

# 依存関係ファイルをコピー
COPY pyproject.toml uv.lock ./

# 依存関係をインストール
RUN uv sync --frozen --no-dev

# アプリケーションコードをコピー
COPY . .

# アプリケーションを実行
CMD ["uv", "run", "python", "app.py"]
```

**最適化されたマルチステージビルド：**

```dockerfile
# マルチステージDockerfile
FROM python:3.12-slim AS builder

# uvをインストール
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

WORKDIR /app

# venvに依存関係をインストール
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev --no-editable

# ランタイムステージ
FROM python:3.12-slim

WORKDIR /app

# ビルダーからvenvをコピー
COPY --from=builder /app/.venv .venv
COPY . .

# venvを使用
ENV PATH="/app/.venv/bin:$PATH"

CMD ["python", "app.py"]
```

### パターン15: ロックファイルワークフロー

```bash
# ロックファイル（uv.lock）を作成
uv lock

# ロックファイルからインストール（正確なバージョン）
uv sync --frozen

# インストールせずにロックファイルを更新
uv lock --no-install

# ロック内の特定のパッケージをアップグレード
uv lock --upgrade-package requests

# ロックファイルが最新かチェック
uv lock --check

# ロックファイルをrequirements.txtにエクスポート
uv export --format requirements-txt > requirements.txt

# セキュリティのためにハッシュ付きでエクスポート
uv export --format requirements-txt --hash > requirements.txt
```

## パフォーマンス最適化

### パターン16: グローバルキャッシュの使用

```bash
# UVは自動的にグローバルキャッシュを使用：
# Linux: ~/.cache/uv
# macOS: ~/Library/Caches/uv
# Windows: %LOCALAPPDATA%\uv\cache

# キャッシュをクリア
uv cache clean

# キャッシュサイズをチェック
uv cache dir
```

### パターン17: 並列インストール

```bash
# UVはデフォルトでパッケージを並列インストール

# 並列性を制御
uv pip install --jobs 4 package1 package2

# 並列なし（順次）
uv pip install --jobs 1 package
```

### パターン18: オフラインモード

```bash
# キャッシュのみからインストール（ネットワークなし）
uv pip install --offline package

# ロックファイルからオフライン同期
uv sync --frozen --offline
```

## 他のツールとの比較

### uv vs pip

```bash
# pip
python -m venv .venv
source .venv/bin/activate
pip install requests pandas numpy
# 〜30秒

# uv
uv venv
uv add requests pandas numpy
# 〜2秒（10〜15倍高速）
```

### uv vs poetry

```bash
# poetry
poetry init
poetry add requests pandas
poetry install
# 〜20秒

# uv
uv init
uv add requests pandas
uv sync
# 〜3秒（6〜7倍高速）
```

### uv vs pip-tools

```bash
# pip-tools
pip-compile requirements.in
pip-sync requirements.txt
# 〜15秒

# uv
uv lock
uv sync --frozen
# 〜2秒（7〜8倍高速）
```

## 共通ワークフロー

### パターン19: 新しいプロジェクトの開始

```bash
# 完全なワークフロー
uv init my-project
cd my-project

# Pythonバージョンを設定
uv python pin 3.12

# 依存関係を追加
uv add fastapi uvicorn pydantic

# dev依存関係を追加
uv add --dev pytest black ruff mypy

# 構造を作成
mkdir -p src/my_project tests

# テストを実行
uv run pytest

# コードをフォーマット
uv run black .
uv run ruff check .
```

### パターン20: 既存プロジェクトの保守

```bash
# リポジトリをクローン
git clone https://github.com/user/project.git
cd project

# 依存関係をインストール（venvを自動作成）
uv sync

# dev依存関係付きでインストール
uv sync --all-extras

# 依存関係を更新
uv lock --upgrade

# アプリケーションを実行
uv run python app.py

# テストを実行
uv run pytest

# 新しい依存関係を追加
uv add new-package

# 更新されたファイルをコミット
git add pyproject.toml uv.lock
git commit -m "Add new-package dependency"
```

## ツール統合

### パターン21: Pre-commitフック

```yaml
# .pre-commit-config.yaml
repos:
  - repo: local
    hooks:
      - id: uv-lock
        name: uv lock
        entry: uv lock
        language: system
        pass_filenames: false

      - id: ruff
        name: ruff
        entry: uv run ruff check --fix
        language: system
        types: [python]

      - id: black
        name: black
        entry: uv run black
        language: system
        types: [python]
```

### パターン22: VS Code統合

```json
// .vscode/settings.json
{
  "python.defaultInterpreterPath": "${workspaceFolder}/.venv/bin/python",
  "python.terminal.activateEnvironment": true,
  "python.testing.pytestEnabled": true,
  "python.testing.pytestArgs": ["-v"],
  "python.linting.enabled": true,
  "python.formatting.provider": "black",
  "[python]": {
    "editor.defaultFormatter": "ms-python.black-formatter",
    "editor.formatOnSave": true
  }
}
```

## トラブルシューティング

### よくある問題

```bash
# 問題: uvが見つからない
# 解決策: PATHに追加または再インストール
echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc

# 問題: 間違ったPythonバージョン
# 解決策: バージョンを明示的にピン留め
uv python pin 3.12
uv venv --python 3.12

# 問題: 依存関係の競合
# 解決策: 解決をチェック
uv lock --verbose

# 問題: キャッシュの問題
# 解決策: キャッシュをクリア
uv cache clean

# 問題: ロックファイルが同期していない
# 解決策: 再生成
uv lock --upgrade
```

## ベストプラクティス

### プロジェクトセットアップ

1. **常にロックファイルを使用** 再現性のため
2. **.python-versionでPythonバージョンをピン留め**
3. **dev依存関係を本番から分離**
4. **venvをアクティベートする代わりにuv runを使用**
5. **uv.lockをバージョン管理にコミット**
6. **CIで--frozenを使用** 一貫したビルドのため
7. **グローバルキャッシュを活用** 速度のため
8. **モノレポにワークスペースを使用**
9. **互換性のためにrequirements.txtをエクスポート**
10. **uvを最新に保つ** 最新機能のため

### パフォーマンスのヒント

```bash
# CIで凍結されたインストールを使用
uv sync --frozen

# 可能な場合はオフラインモードを使用
uv sync --offline

# 並列操作（自動）
# uvはデフォルトでこれを行う

# 環境間でキャッシュを再利用
# uvはグローバルにキャッシュを共有

# 解決をスキップするためにロックファイルを使用
uv sync --frozen  # 解決をスキップ
```

## 移行ガイド

### pip + requirements.txtから

```bash
# 以前
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# 以後
uv venv
uv pip install -r requirements.txt
# またはより良い方法：
uv init
uv add -r requirements.txt
```

### Poetryから

```bash
# 以前
poetry install
poetry add requests

# 以後
uv sync
uv add requests

# 既存のpyproject.tomlを保持
# uvは[project]と[tool.poetry]セクションを読む
```

### pip-toolsから

```bash
# 以前
pip-compile requirements.in
pip-sync requirements.txt

# 以後
uv lock
uv sync --frozen
```

## コマンドリファレンス

### 必須コマンド

```bash
# プロジェクト管理
uv init [PATH]              # プロジェクトを初期化
uv add PACKAGE              # 依存関係を追加
uv remove PACKAGE           # 依存関係を削除
uv sync                     # 依存関係をインストール
uv lock                     # ロックファイルを作成/更新

# 仮想環境
uv venv [PATH]              # venvを作成
uv run COMMAND              # venv内で実行

# Python管理
uv python install VERSION   # Pythonをインストール
uv python list              # インストールされたPythonをリスト
uv python pin VERSION       # Pythonバージョンをピン留め

# パッケージインストール（pip互換）
uv pip install PACKAGE      # パッケージをインストール
uv pip uninstall PACKAGE    # パッケージをアンインストール
uv pip freeze               # インストール済みをリスト
uv pip list                 # パッケージをリスト

# ユーティリティ
uv cache clean              # キャッシュをクリア
uv cache dir                # キャッシュ場所を表示
uv --version                # バージョンを表示
```

## リソース

- **公式ドキュメント**: https://docs.astral.sh/uv/
- **GitHubリポジトリ**: https://github.com/astral-sh/uv
- **Astralブログ**: https://astral.sh/blog
- **移行ガイド**: https://docs.astral.sh/uv/guides/
- **他のツールとの比較**: https://docs.astral.sh/uv/pip/compatibility/

## ベストプラクティス概要

1. **すべての新しいプロジェクトにuvを使用** - `uv init`で開始
2. **ロックファイルをコミット** - 再現可能なビルドを確保
3. **Pythonバージョンをピン留め** - .python-versionを使用
4. **uv runを使用** - 手動のvenvアクティベーションを避ける
5. **キャッシングを活用** - uvにグローバルキャッシュを管理させる
6. **CIで--frozenを使用** - 正確な再現のため
7. **uvを最新に保つ** - 急速に進化するプロジェクト
8. **ワークスペースを使用** - モノレポプロジェクト用
9. **互換性のためにエクスポート** - 必要に応じてrequirements.txtを生成
10. **ドキュメントを読む** - uvは機能豊富で進化中
