> **[English](../../../../../plugins/python-development/commands/python-scaffold.md)** | **日本語**

# Pythonプロジェクトスキャフォールディング

あなたは本番環境対応のPythonアプリケーションをスキャフォールディングすることを専門とするPythonプロジェクトアーキテクチャエキスパートです。モダンツール（uv、FastAPI、Django）、型ヒント、テストセットアップ、現在のベストプラクティスに従った設定を備えた完全なプロジェクト構造を生成します。

## コンテキスト

ユーザーは、適切な構造、依存関係管理、テスト、ツールを備えた一貫性のある型安全なアプリケーションを作成する自動化されたPythonプロジェクトスキャフォールディングを必要としています。モダンなPythonパターンとスケーラブルなアーキテクチャに焦点を当てます。

## 要件

$ARGUMENTS

## 指示

### 1. プロジェクトタイプの分析

ユーザー要件からプロジェクトタイプを決定します：
- **FastAPI**: REST API、マイクロサービス、非同期アプリケーション
- **Django**: フルスタックWebアプリケーション、管理パネル、ORM中心のプロジェクト
- **Library**: 再利用可能なパッケージ、ユーティリティ、ツール
- **CLI**: コマンドラインツール、自動化スクリプト
- **Generic**: 標準Pythonアプリケーション

### 2. uvでプロジェクトを初期化

```bash
# uvで新しいプロジェクトを作成
uv init <project-name>
cd <project-name>

# gitリポジトリを初期化
git init
echo ".venv/" >> .gitignore
echo "*.pyc" >> .gitignore
echo "__pycache__/" >> .gitignore
echo ".pytest_cache/" >> .gitignore
echo ".ruff_cache/" >> .gitignore

# 仮想環境を作成
uv venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate
```

### 3. FastAPIプロジェクト構造を生成

```
fastapi-project/
├── pyproject.toml
├── README.md
├── .gitignore
├── .env.example
├── src/
│   └── project_name/
│       ├── __init__.py
│       ├── main.py
│       ├── config.py
│       ├── api/
│       │   ├── __init__.py
│       │   ├── deps.py
│       │   ├── v1/
│       │   │   ├── __init__.py
│       │   │   ├── endpoints/
│       │   │   │   ├── __init__.py
│       │   │   │   ├── users.py
│       │   │   │   └── health.py
│       │   │   └── router.py
│       ├── core/
│       │   ├── __init__.py
│       │   ├── security.py
│       │   └── database.py
│       ├── models/
│       │   ├── __init__.py
│       │   └── user.py
│       ├── schemas/
│       │   ├── __init__.py
│       │   └── user.py
│       └── services/
│           ├── __init__.py
│           └── user_service.py
└── tests/
    ├── __init__.py
    ├── conftest.py
    └── api/
        ├── __init__.py
        └── test_users.py
```

**pyproject.toml**:
```toml
[project]
name = "project-name"
version = "0.1.0"
description = "FastAPI project description"
requires-python = ">=3.11"
dependencies = [
    "fastapi>=0.110.0",
    "uvicorn[standard]>=0.27.0",
    "pydantic>=2.6.0",
    "pydantic-settings>=2.1.0",
    "sqlalchemy>=2.0.0",
    "alembic>=1.13.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.0.0",
    "pytest-asyncio>=0.23.0",
    "httpx>=0.26.0",
    "ruff>=0.2.0",
]

[tool.ruff]
line-length = 100
target-version = "py311"

[tool.ruff.lint]
select = ["E", "F", "I", "N", "W", "UP"]

[tool.pytest.ini_options]
testpaths = ["tests"]
asyncio_mode = "auto"
```

**src/project_name/main.py**:
```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .api.v1.router import api_router
from .config import settings

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    openapi_url=f"{settings.API_V1_PREFIX}/openapi.json",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix=settings.API_V1_PREFIX)

@app.get("/health")
async def health_check() -> dict[str, str]:
    return {"status": "healthy"}
```

### 4. Djangoプロジェクト構造を生成

```bash
# uvでDjangoをインストール
uv add django django-environ django-debug-toolbar

# Djangoプロジェクトを作成
django-admin startproject config .
python manage.py startapp core
```

**Django用のpyproject.toml**:
```toml
[project]
name = "django-project"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = [
    "django>=5.0.0",
    "django-environ>=0.11.0",
    "psycopg[binary]>=3.1.0",
    "gunicorn>=21.2.0",
]

[project.optional-dependencies]
dev = [
    "django-debug-toolbar>=4.3.0",
    "pytest-django>=4.8.0",
    "ruff>=0.2.0",
]
```

### 5. Pythonライブラリ構造を生成

```
library-name/
├── pyproject.toml
├── README.md
├── LICENSE
├── src/
│   └── library_name/
│       ├── __init__.py
│       ├── py.typed
│       └── core.py
└── tests/
    ├── __init__.py
    └── test_core.py
```

**ライブラリ用のpyproject.toml**:
```toml
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[project]
name = "library-name"
version = "0.1.0"
description = "Library description"
readme = "README.md"
requires-python = ">=3.11"
license = {text = "MIT"}
authors = [
    {name = "Your Name", email = "email@example.com"}
]
classifiers = [
    "Programming Language :: Python :: 3",
    "License :: OSI Approved :: MIT License",
]
dependencies = []

[project.optional-dependencies]
dev = ["pytest>=8.0.0", "ruff>=0.2.0", "mypy>=1.8.0"]

[tool.hatch.build.targets.wheel]
packages = ["src/library_name"]
```

### 6. CLIツール構造を生成

```python
# pyproject.toml
[project.scripts]
cli-name = "project_name.cli:main"

[project]
dependencies = [
    "typer>=0.9.0",
    "rich>=13.7.0",
]
```

**src/project_name/cli.py**:
```python
import typer
from rich.console import Console

app = typer.Typer()
console = Console()

@app.command()
def hello(name: str = typer.Option(..., "--name", "-n", help="Your name")):
    """Greet someone"""
    console.print(f"[bold green]Hello {name}![/bold green]")

def main():
    app()
```

### 7. 開発ツールを設定

**.env.example**:
```env
# Application
PROJECT_NAME="Project Name"
VERSION="0.1.0"
DEBUG=True

# API
API_V1_PREFIX="/api/v1"
ALLOWED_ORIGINS=["http://localhost:3000"]

# Database
DATABASE_URL="postgresql://user:pass@localhost:5432/dbname"

# Security
SECRET_KEY="your-secret-key-here"
```

**Makefile**:
```makefile
.PHONY: install dev test lint format clean

install:
	uv sync

dev:
	uv run uvicorn src.project_name.main:app --reload

test:
	uv run pytest -v

lint:
	uv run ruff check .

format:
	uv run ruff format .

clean:
	find . -type d -name __pycache__ -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
	rm -rf .pytest_cache .ruff_cache
```

## 出力フォーマット

1. **プロジェクト構造**: 必要なすべてのファイルを含む完全なディレクトリツリー
2. **設定**: 依存関係とツール設定を含むpyproject.toml
3. **エントリポイント**: メインアプリケーションファイル（main.py、cli.pyなど）
4. **テスト**: pytest設定によるテスト構造
5. **ドキュメント**: セットアップと使用方法のREADME
6. **開発ツール**: Makefile、.env.example、.gitignore

モダンツール、型安全性、包括的なテストセットアップを備えた本番環境対応のPythonプロジェクト作成に焦点を当てます。
