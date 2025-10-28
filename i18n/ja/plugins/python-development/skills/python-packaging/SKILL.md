---
name: python-packaging
description: 適切なプロジェクト構造、setup.py/pyproject.toml、PyPIへの公開を使用して配布可能なPythonパッケージを作成。Pythonライブラリのパッケージング、CLIツールの作成、Pythonコードの配布時に使用。
---

> **[English](../../../../../../plugins/python-development/skills/python-packaging/SKILL.md)** | **日本語**

# Pythonパッケージング

モダンなパッケージングツール、pyproject.toml、PyPIへの公開を使用した、Pythonパッケージの作成、構造化、配布に関する包括的なガイド。

## このスキルを使用するタイミング

- 配布用のPythonライブラリの作成
- エントリーポイント付きコマンドラインツールの構築
- PyPIまたはプライベートリポジトリへのパッケージの公開
- Pythonプロジェクト構造のセットアップ
- 依存関係を含むインストール可能なパッケージの作成
- ホイールとソースディストリビューションの構築
- Pythonパッケージのバージョニングとリリース
- 名前空間パッケージの作成
- パッケージメタデータとclassifierの実装

## コア概念

### 1. パッケージ構造
- **ソースレイアウト**: `src/package_name/`（推奨）
- **フラットレイアウト**: `package_name/`（よりシンプルだが柔軟性が低い）
- **パッケージメタデータ**: pyproject.toml、setup.py、またはsetup.cfg
- **配布フォーマット**: wheel（.whl）とソースディストリビューション（.tar.gz）

### 2. モダンなパッケージング標準
- **PEP 517/518**: ビルドシステム要件
- **PEP 621**: pyproject.tomlのメタデータ
- **PEP 660**: 編集可能インストール
- **pyproject.toml**: 設定の単一ソース

### 3. ビルドバックエンド
- **setuptools**: 従来型、広く使用されている
- **hatchling**: モダン、意見が固定的
- **flit**: 軽量、純粋Python用
- **poetry**: 依存関係管理 + パッケージング

### 4. 配布
- **PyPI**: Python Package Index（公開）
- **TestPyPI**: 本番前のテスト
- **プライベートリポジトリ**: JFrog、AWS CodeArtifactなど

## クイックスタート

### 最小限のパッケージ構造

```
my-package/
├── pyproject.toml
├── README.md
├── LICENSE
├── src/
│   └── my_package/
│       ├── __init__.py
│       └── module.py
└── tests/
    └── test_module.py
```

### 最小限のpyproject.toml

```toml
[build-system]
requires = ["setuptools>=61.0"]
build-backend = "setuptools.build_meta"

[project]
name = "my-package"
version = "0.1.0"
description = "A short description"
authors = [{name = "Your Name", email = "you@example.com"}]
readme = "README.md"
requires-python = ">=3.8"
dependencies = [
    "requests>=2.28.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=7.0",
    "black>=22.0",
]
```

## パッケージ構造パターン

### パターン1: ソースレイアウト（推奨）

```
my-package/
├── pyproject.toml
├── README.md
├── LICENSE
├── .gitignore
├── src/
│   └── my_package/
│       ├── __init__.py
│       ├── core.py
│       ├── utils.py
│       └── py.typed          # 型ヒント用
├── tests/
│   ├── __init__.py
│   ├── test_core.py
│   └── test_utils.py
└── docs/
    └── index.md
```

**利点：**
- ソースから誤ってインポートするのを防ぐ
- よりクリーンなテストインポート
- より良い分離

**ソースレイアウト用のpyproject.toml：**
```toml
[tool.setuptools.packages.find]
where = ["src"]
```

### パターン2: フラットレイアウト

```
my-package/
├── pyproject.toml
├── README.md
├── my_package/
│   ├── __init__.py
│   └── module.py
└── tests/
    └── test_module.py
```

**よりシンプルですが：**
- インストールせずにパッケージをインポートできる
- ライブラリにとってはあまりプロフェッショナルではない

### パターン3: マルチパッケージプロジェクト

```
project/
├── pyproject.toml
├── packages/
│   ├── package-a/
│   │   └── src/
│   │       └── package_a/
│   └── package-b/
│       └── src/
│           └── package_b/
└── tests/
```

## 完全なpyproject.toml例

### パターン4: 全機能pyproject.toml

```toml
[build-system]
requires = ["setuptools>=61.0", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "my-awesome-package"
version = "1.0.0"
description = "An awesome Python package"
readme = "README.md"
requires-python = ">=3.8"
license = {text = "MIT"}
authors = [
    {name = "Your Name", email = "you@example.com"},
]
maintainers = [
    {name = "Maintainer Name", email = "maintainer@example.com"},
]
keywords = ["example", "package", "awesome"]
classifiers = [
    "Development Status :: 4 - Beta",
    "Intended Audience :: Developers",
    "License :: OSI Approved :: MIT License",
    "Programming Language :: Python :: 3",
    "Programming Language :: Python :: 3.8",
    "Programming Language :: Python :: 3.9",
    "Programming Language :: Python :: 3.10",
    "Programming Language :: Python :: 3.11",
    "Programming Language :: Python :: 3.12",
]

dependencies = [
    "requests>=2.28.0,<3.0.0",
    "click>=8.0.0",
    "pydantic>=2.0.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=7.0.0",
    "pytest-cov>=4.0.0",
    "black>=23.0.0",
    "ruff>=0.1.0",
    "mypy>=1.0.0",
]
docs = [
    "sphinx>=5.0.0",
    "sphinx-rtd-theme>=1.0.0",
]
all = [
    "my-awesome-package[dev,docs]",
]

[project.urls]
Homepage = "https://github.com/username/my-awesome-package"
Documentation = "https://my-awesome-package.readthedocs.io"
Repository = "https://github.com/username/my-awesome-package"
"Bug Tracker" = "https://github.com/username/my-awesome-package/issues"
Changelog = "https://github.com/username/my-awesome-package/blob/main/CHANGELOG.md"

[project.scripts]
my-cli = "my_package.cli:main"
awesome-tool = "my_package.tools:run"

[project.entry-points."my_package.plugins"]
plugin1 = "my_package.plugins:plugin1"

[tool.setuptools]
package-dir = {"" = "src"}
zip-safe = false

[tool.setuptools.packages.find]
where = ["src"]
include = ["my_package*"]
exclude = ["tests*"]

[tool.setuptools.package-data]
my_package = ["py.typed", "*.pyi", "data/*.json"]

# Black設定
[tool.black]
line-length = 100
target-version = ["py38", "py39", "py310", "py311"]
include = '\.pyi?$'

# Ruff設定
[tool.ruff]
line-length = 100
target-version = "py38"

[tool.ruff.lint]
select = ["E", "F", "I", "N", "W", "UP"]

# MyPy設定
[tool.mypy]
python_version = "3.8"
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true

# Pytest設定
[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
addopts = "-v --cov=my_package --cov-report=term-missing"

# Coverage設定
[tool.coverage.run]
source = ["src"]
omit = ["*/tests/*"]

[tool.coverage.report]
exclude_lines = [
    "pragma: no cover",
    "def __repr__",
    "raise AssertionError",
    "raise NotImplementedError",
]
```

### パターン5: 動的バージョニング

```toml
[build-system]
requires = ["setuptools>=61.0", "setuptools-scm>=8.0"]
build-backend = "setuptools.build_meta"

[project]
name = "my-package"
dynamic = ["version"]
description = "Package with dynamic version"

[tool.setuptools.dynamic]
version = {attr = "my_package.__version__"}

# またはgitベースのバージョニングにsetuptools-scmを使用
[tool.setuptools_scm]
write_to = "src/my_package/_version.py"
```

**__init__.py内：**
```python
# src/my_package/__init__.py
__version__ = "1.0.0"

# またはsetuptools-scmで
from importlib.metadata import version
__version__ = version("my-package")
```

## コマンドラインインターフェース（CLI）パターン

### パターン6: ClickによるCLI

```python
# src/my_package/cli.py
import click

@click.group()
@click.version_option()
def cli():
    """私の素晴らしいCLIツール。"""
    pass

@cli.command()
@click.argument("name")
@click.option("--greeting", default="Hello", help="使用する挨拶")
def greet(name: str, greeting: str):
    """誰かに挨拶する。"""
    click.echo(f"{greeting}, {name}!")

@cli.command()
@click.option("--count", default=1, help="繰り返す回数")
def repeat(count: int):
    """メッセージを繰り返す。"""
    for i in range(count):
        click.echo(f"Message {i + 1}")

def main():
    """CLIのエントリーポイント。"""
    cli()

if __name__ == "__main__":
    main()
```

**pyproject.tomlに登録：**
```toml
[project.scripts]
my-tool = "my_package.cli:main"
```

**使用法：**
```bash
pip install -e .
my-tool greet World
my-tool greet Alice --greeting="Hi"
my-tool repeat --count=3
```

### パターン7: argparseによるCLI

```python
# src/my_package/cli.py
import argparse
import sys

def main():
    """メインCLIエントリーポイント。"""
    parser = argparse.ArgumentParser(
        description="私の素晴らしいツール",
        prog="my-tool"
    )

    parser.add_argument(
        "--version",
        action="version",
        version="%(prog)s 1.0.0"
    )

    subparsers = parser.add_subparsers(dest="command", help="コマンド")

    # サブコマンドを追加
    process_parser = subparsers.add_parser("process", help="データを処理")
    process_parser.add_argument("input_file", help="入力ファイルパス")
    process_parser.add_argument(
        "--output", "-o",
        default="output.txt",
        help="出力ファイルパス"
    )

    args = parser.parse_args()

    if args.command == "process":
        process_data(args.input_file, args.output)
    else:
        parser.print_help()
        sys.exit(1)

def process_data(input_file: str, output_file: str):
    """入力から出力へデータを処理。"""
    print(f"Processing {input_file} -> {output_file}")

if __name__ == "__main__":
    main()
```

## ビルドと公開

### パターン8: ローカルでパッケージをビルド

```bash
# ビルドツールをインストール
pip install build twine

# ディストリビューションをビルド
python -m build

# これにより作成される：
# dist/
#   my-package-1.0.0.tar.gz (ソースディストリビューション)
#   my_package-1.0.0-py3-none-any.whl (wheel)

# ディストリビューションをチェック
twine check dist/*
```

### パターン9: PyPIへの公開

```bash
# 公開ツールをインストール
pip install twine

# まずTestPyPIでテスト
twine upload --repository testpypi dist/*

# TestPyPIからインストールしてテスト
pip install --index-url https://test.pypi.org/simple/ my-package

# 問題なければ、PyPIに公開
twine upload dist/*
```

**APIトークンの使用（推奨）：**
```bash
# ~/.pypircを作成
[distutils]
index-servers =
    pypi
    testpypi

[pypi]
username = __token__
password = pypi-...your-token...

[testpypi]
username = __token__
password = pypi-...your-test-token...
```

### パターン10: GitHub Actionsによる自動公開

```yaml
# .github/workflows/publish.yml
name: Publish to PyPI

on:
  release:
    types: [created]

jobs:
  publish:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: "3.11"

      - name: Install dependencies
        run: |
          pip install build twine

      - name: Build package
        run: python -m build

      - name: Check package
        run: twine check dist/*

      - name: Publish to PyPI
        env:
          TWINE_USERNAME: __token__
          TWINE_PASSWORD: ${{ secrets.PYPI_API_TOKEN }}
        run: twine upload dist/*
```

## 高度なパターン

### パターン11: データファイルの含める

```toml
[tool.setuptools.package-data]
my_package = [
    "data/*.json",
    "templates/*.html",
    "static/css/*.css",
    "py.typed",
]
```

**データファイルへのアクセス：**
```python
# src/my_package/loader.py
from importlib.resources import files
import json

def load_config():
    """パッケージデータから設定をロード。"""
    config_file = files("my_package").joinpath("data/config.json")
    with config_file.open() as f:
        return json.load(f)

# Python 3.9+
from importlib.resources import files

data = files("my_package").joinpath("data/file.txt").read_text()
```

### パターン12: 名前空間パッケージ

**複数のリポジトリに分割された大規模プロジェクト用：**

```
# パッケージ1: company-core
company/
└── core/
    ├── __init__.py
    └── models.py

# パッケージ2: company-api
company/
└── api/
    ├── __init__.py
    └── routes.py
```

**名前空間ディレクトリ（company/）に__init__.pyを含めないでください：**

```toml
# company-core/pyproject.toml
[project]
name = "company-core"

[tool.setuptools.packages.find]
where = ["."]
include = ["company.core*"]

# company-api/pyproject.toml
[project]
name = "company-api"

[tool.setuptools.packages.find]
where = ["."]
include = ["company.api*"]
```

**使用法：**
```python
# 両方のパッケージを同じ名前空間でインポート可能
from company.core import models
from company.api import routes
```

### パターン13: C拡張

```toml
[build-system]
requires = ["setuptools>=61.0", "wheel", "Cython>=0.29"]
build-backend = "setuptools.build_meta"

[tool.setuptools]
ext-modules = [
    {name = "my_package.fast_module", sources = ["src/fast_module.c"]},
]
```

**またはsetup.pyで：**
```python
# setup.py
from setuptools import setup, Extension

setup(
    ext_modules=[
        Extension(
            "my_package.fast_module",
            sources=["src/fast_module.c"],
            include_dirs=["src/include"],
        )
    ]
)
```

## バージョン管理

### パターン14: セマンティックバージョニング

```python
# src/my_package/__init__.py
__version__ = "1.2.3"

# セマンティックバージョニング: MAJOR.MINOR.PATCH
# MAJOR: 破壊的変更
# MINOR: 新機能（後方互換）
# PATCH: バグ修正
```

**依存関係のバージョン制約：**
```toml
dependencies = [
    "requests>=2.28.0,<3.0.0",  # 互換範囲
    "click~=8.1.0",              # 互換リリース（~= 8.1.0は>=8.1.0,<8.2.0を意味）
    "pydantic>=2.0",             # 最小バージョン
    "numpy==1.24.3",             # 正確なバージョン（可能なら避ける）
]
```

### パターン15: Gitベースのバージョニング

```toml
[build-system]
requires = ["setuptools>=61.0", "setuptools-scm>=8.0"]
build-backend = "setuptools.build_meta"

[project]
name = "my-package"
dynamic = ["version"]

[tool.setuptools_scm]
write_to = "src/my_package/_version.py"
version_scheme = "post-release"
local_scheme = "dirty-tag"
```

**次のようなバージョンを作成：**
- `1.0.0`（gitタグから）
- `1.0.1.dev3+g1234567`（タグ後3コミット）

## インストールのテスト

### パターン16: 編集可能インストール

```bash
# 開発モードでインストール
pip install -e .

# オプション依存関係付き
pip install -e ".[dev]"
pip install -e ".[dev,docs]"

# これでソースコードの変更がすぐに反映される
```

### パターン17: 隔離環境でのテスト

```bash
# 仮想環境を作成
python -m venv test-env
source test-env/bin/activate  # Linux/Mac
# test-env\Scripts\activate  # Windows

# パッケージをインストール
pip install dist/my_package-1.0.0-py3-none-any.whl

# 動作をテスト
python -c "import my_package; print(my_package.__version__)"

# CLIをテスト
my-tool --help

# クリーンアップ
deactivate
rm -rf test-env
```

## ドキュメント

### パターン18: README.mdテンプレート

```markdown
# My Package

[![PyPI version](https://badge.fury.io/py/my-package.svg)](https://pypi.org/project/my-package/)
[![Python versions](https://img.shields.io/pypi/pyversions/my-package.svg)](https://pypi.org/project/my-package/)
[![Tests](https://github.com/username/my-package/workflows/Tests/badge.svg)](https://github.com/username/my-package/actions)

パッケージの簡単な説明。

## インストール

```bash
pip install my-package
```

## クイックスタート

```python
from my_package import something

result = something.do_stuff()
```

## 機能

- 機能1
- 機能2
- 機能3

## ドキュメント

完全なドキュメント: https://my-package.readthedocs.io

## 開発

```bash
git clone https://github.com/username/my-package.git
cd my-package
pip install -e ".[dev]"
pytest
```

## ライセンス

MIT
```

## 共通パターン

### パターン19: マルチアーキテクチャホイール

```yaml
# .github/workflows/wheels.yml
name: Build wheels

on: [push, pull_request]

jobs:
  build_wheels:
    name: Build wheels on ${{ matrix.os }}
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]

    steps:
      - uses: actions/checkout@v3

      - name: Build wheels
        uses: pypa/cibuildwheel@v2.16.2

      - uses: actions/upload-artifact@v3
        with:
          path: ./wheelhouse/*.whl
```

### パターン20: プライベートパッケージインデックス

```bash
# プライベートインデックスからインストール
pip install my-package --index-url https://private.pypi.org/simple/

# またはpip.confに追加
[global]
index-url = https://private.pypi.org/simple/
extra-index-url = https://pypi.org/simple/

# プライベートインデックスにアップロード
twine upload --repository-url https://private.pypi.org/ dist/*
```

## ファイルテンプレート

### Pythonパッケージ用の.gitignore

```gitignore
# ビルド成果物
build/
dist/
*.egg-info/
*.egg
.eggs/

# Python
__pycache__/
*.py[cod]
*$py.class
*.so

# 仮想環境
venv/
env/
ENV/

# IDE
.vscode/
.idea/
*.swp

# テスト
.pytest_cache/
.coverage
htmlcov/

# 配布
*.whl
*.tar.gz
```

### MANIFEST.in

```
# MANIFEST.in
include README.md
include LICENSE
include pyproject.toml

recursive-include src/my_package/data *.json
recursive-include src/my_package/templates *.html
recursive-exclude * __pycache__
recursive-exclude * *.py[co]
```

## 公開チェックリスト

- [ ] コードがテストされている（pytestパス）
- [ ] ドキュメントが完全（README、docstring）
- [ ] バージョン番号が更新されている
- [ ] CHANGELOG.mdが更新されている
- [ ] ライセンスファイルが含まれている
- [ ] pyproject.tomlが完全
- [ ] パッケージがエラーなくビルドできる
- [ ] クリーンな環境でインストールがテストされている
- [ ] CLIツールが動作する（該当する場合）
- [ ] PyPIメタデータが正しい（classifier、keywords）
- [ ] GitHubリポジトリがリンクされている
- [ ] まずTestPyPIでテストされている
- [ ] リリース用のgitタグが作成されている

## リソース

- **Python Packaging Guide**: https://packaging.python.org/
- **PyPI**: https://pypi.org/
- **TestPyPI**: https://test.pypi.org/
- **setuptoolsドキュメント**: https://setuptools.pypa.io/
- **build**: https://pypa-build.readthedocs.io/
- **twine**: https://twine.readthedocs.io/

## ベストプラクティス概要

1. **src/レイアウトを使用**より、クリーンなパッケージ構造のため
2. **pyproject.tomlを使用**、モダンなパッケージングのため
3. **ビルド依存関係をピン留め**、build-system.requiresで
4. **適切にバージョン管理**、セマンティックバージョニングで
5. **すべてのメタデータを含める**（classifier、URLなど）
6. **クリーンな環境でインストールをテスト**
7. **PyPIに公開する前にTestPyPIを使用**
8. **READMEとdocstringで徹底的に文書化**
9. **LICENSEファイルを含める**
10. **CI/CDで公開を自動化**
