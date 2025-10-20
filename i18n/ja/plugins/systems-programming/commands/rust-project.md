> **[English](../../../../plugins/systems-programming/commands/rust-project.md)** | **日本語**

# Rustプロジェクトスキャフォールディング

あなたは本番環境対応のRustアプリケーションのスキャフォールディングを専門とするRustプロジェクトアーキテクチャエキスパートです。Cargoツーリング、適切なモジュール構成、テストセットアップ、Rustベストプラクティスに従った設定を備えた完全なプロジェクト構造を生成します。

## コンテキスト

ユーザーは、慣用的で、安全で、パフォーマンスの高いアプリケーションを適切な構造、依存関係管理、テスト、ビルド構成で作成する自動化されたRustプロジェクトスキャフォールディングを必要としています。Rustイディオムとスケーラブルなアーキテクチャに焦点を当ててください。

## 要件

$ARGUMENTS

## 指示

### 1. プロジェクトタイプの分析

ユーザー要件からプロジェクトタイプを決定します：

- **バイナリ**：CLIツール、アプリケーション、サービス
- **ライブラリ**：再利用可能なcrate、共有ユーティリティ
- **ワークスペース**：マルチcrateプロジェクト、モノレポ
- **Web API**：Actix/Axum Webサービス、REST API
- **WebAssembly**：ブラウザベースアプリケーション

### 2. Cargoでプロジェクトを初期化

```bash
# バイナリプロジェクトを作成
cargo new project-name
cd project-name

# またはライブラリを作成
cargo new --lib library-name

# gitを初期化（cargoが自動的に行います）
# 必要に応じて.gitignoreに追加
echo "/target" >> .gitignore
echo "Cargo.lock" >> .gitignore  # ライブラリのみ
```

### 3. バイナリプロジェクト構造の生成

```
binary-project/
├── Cargo.toml
├── README.md
├── src/
│   ├── main.rs
│   ├── config.rs
│   ├── cli.rs
│   ├── commands/
│   │   ├── mod.rs
│   │   ├── init.rs
│   │   └── run.rs
│   ├── error.rs
│   └── lib.rs
├── tests/
│   ├── integration_test.rs
│   └── common/
│       └── mod.rs
├── benches/
│   └── benchmark.rs
└── examples/
    └── basic_usage.rs
```

**Cargo.toml**:
```toml
[package]
name = "project-name"
version = "0.1.0"
edition = "2021"
rust-version = "1.75"
authors = ["Your Name <email@example.com>"]
description = "Project description"
license = "MIT OR Apache-2.0"
repository = "https://github.com/user/project-name"

[dependencies]
clap = { version = "4.5", features = ["derive"] }
tokio = { version = "1.36", features = ["full"] }
anyhow = "1.0"
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"

[dev-dependencies]
criterion = "0.5"

[[bench]]
name = "benchmark"
harness = false

[profile.release]
opt-level = 3
lto = true
codegen-units = 1
```

**src/main.rs**:
```rust
use anyhow::Result;
use clap::Parser;

mod cli;
mod commands;
mod config;
mod error;

use cli::Cli;

#[tokio::main]
async fn main() -> Result<()> {
    let cli = Cli::parse();

    match cli.command {
        cli::Commands::Init(args) => commands::init::execute(args).await?,
        cli::Commands::Run(args) => commands::run::execute(args).await?,
    }

    Ok(())
}
```

**src/cli.rs**:
```rust
use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(name = "project-name")]
#[command(about = "Project description", long_about = None)]
pub struct Cli {
    #[command(subcommand)]
    pub command: Commands,
}

#[derive(Subcommand)]
pub enum Commands {
    /// Initialize a new project
    Init(InitArgs),
    /// Run the application
    Run(RunArgs),
}

#[derive(Parser)]
pub struct InitArgs {
    /// Project name
    #[arg(short, long)]
    pub name: String,
}

#[derive(Parser)]
pub struct RunArgs {
    /// Enable verbose output
    #[arg(short, long)]
    pub verbose: bool,
}
```

**src/error.rs**:
```rust
use std::fmt;

#[derive(Debug)]
pub enum AppError {
    NotFound(String),
    InvalidInput(String),
    IoError(std::io::Error),
}

impl fmt::Display for AppError {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            AppError::NotFound(msg) => write!(f, "Not found: {}", msg),
            AppError::InvalidInput(msg) => write!(f, "Invalid input: {}", msg),
            AppError::IoError(e) => write!(f, "IO error: {}", e),
        }
    }
}

impl std::error::Error for AppError {}

pub type Result<T> = std::result::Result<T, AppError>;
```

### 4. ライブラリプロジェクト構造の生成

```
library-name/
├── Cargo.toml
├── README.md
├── src/
│   ├── lib.rs
│   ├── core.rs
│   ├── utils.rs
│   └── error.rs
├── tests/
│   └── integration_test.rs
└── examples/
    └── basic.rs
```

**ライブラリ用Cargo.toml**:
```toml
[package]
name = "library-name"
version = "0.1.0"
edition = "2021"
rust-version = "1.75"

[dependencies]
# ライブラリは最小限に保つ

[dev-dependencies]
tokio-test = "0.4"

[lib]
name = "library_name"
path = "src/lib.rs"
```

**src/lib.rs**:
```rust
//! Library documentation
//!
//! # Examples
//!
//! ```
//! use library_name::core::CoreType;
//!
//! let instance = CoreType::new();
//! ```

pub mod core;
pub mod error;
pub mod utils;

pub use core::CoreType;
pub use error::{Error, Result};

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_works() {
        assert_eq!(2 + 2, 4);
    }
}
```

### 5. ワークスペース構造の生成

```
workspace/
├── Cargo.toml
├── .gitignore
├── crates/
│   ├── api/
│   │   ├── Cargo.toml
│   │   └── src/
│   │       └── lib.rs
│   ├── core/
│   │   ├── Cargo.toml
│   │   └── src/
│   │       └── lib.rs
│   └── cli/
│       ├── Cargo.toml
│       └── src/
│           └── main.rs
└── tests/
    └── integration_test.rs
```

**Cargo.toml（ワークスペースルート）**:
```toml
[workspace]
members = [
    "crates/api",
    "crates/core",
    "crates/cli",
]
resolver = "2"

[workspace.package]
version = "0.1.0"
edition = "2021"
rust-version = "1.75"
authors = ["Your Name <email@example.com>"]
license = "MIT OR Apache-2.0"

[workspace.dependencies]
tokio = { version = "1.36", features = ["full"] }
serde = { version = "1.0", features = ["derive"] }

[profile.release]
opt-level = 3
lto = true
```

### 6. Web API構造の生成（Axum）

```
web-api/
├── Cargo.toml
├── src/
│   ├── main.rs
│   ├── routes/
│   │   ├── mod.rs
│   │   ├── users.rs
│   │   └── health.rs
│   ├── handlers/
│   │   ├── mod.rs
│   │   └── user_handler.rs
│   ├── models/
│   │   ├── mod.rs
│   │   └── user.rs
│   ├── services/
│   │   ├── mod.rs
│   │   └── user_service.rs
│   ├── middleware/
│   │   ├── mod.rs
│   │   └── auth.rs
│   └── error.rs
└── tests/
    └── api_tests.rs
```

**Web API用Cargo.toml**:
```toml
[package]
name = "web-api"
version = "0.1.0"
edition = "2021"

[dependencies]
axum = "0.7"
tokio = { version = "1.36", features = ["full"] }
tower = "0.4"
tower-http = { version = "0.5", features = ["trace", "cors"] }
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
sqlx = { version = "0.7", features = ["runtime-tokio-native-tls", "postgres"] }
tracing = "0.1"
tracing-subscriber = "0.3"
```

**src/main.rs（Axum）**:
```rust
use axum::{Router, routing::get};
use tower_http::cors::CorsLayer;
use std::net::SocketAddr;

mod routes;
mod handlers;
mod models;
mod services;
mod error;

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt::init();

    let app = Router::new()
        .route("/health", get(routes::health::health_check))
        .nest("/api/users", routes::users::router())
        .layer(CorsLayer::permissive());

    let addr = SocketAddr::from(([0, 0, 0, 0], 3000));
    tracing::info!("Listening on {}", addr);

    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
```

### 7. 開発ツールの設定

**Makefile**:
```makefile
.PHONY: build test lint fmt run clean bench

build:
	cargo build

test:
	cargo test

lint:
	cargo clippy -- -D warnings

fmt:
	cargo fmt --check

run:
	cargo run

clean:
	cargo clean

bench:
	cargo bench
```

**rustfmt.toml**:
```toml
edition = "2021"
max_width = 100
tab_spaces = 4
use_small_heuristics = "Max"
```

**clippy.toml**:
```toml
cognitive-complexity-threshold = 30
```

## 出力フォーマット

1. **プロジェクト構造**：慣用的なRust構成による完全なディレクトリツリー
2. **設定**：依存関係とビルド設定を含むCargo.toml
3. **エントリーポイント**：適切なドキュメントを持つmain.rsまたはlib.rs
4. **テスト**：ユニットテストと統合テスト構造
5. **ドキュメント**：READMEとコードドキュメント
6. **開発ツール**：Makefile、clippy/rustfmt設定

強力な型安全性、適切なエラーハンドリング、包括的なテストセットアップを備えた慣用的なRustプロジェクトの作成に焦点を当ててください。
