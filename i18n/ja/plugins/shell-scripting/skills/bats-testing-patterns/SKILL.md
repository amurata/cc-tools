---
name: bats-testing-patterns
description: シェルスクリプトの包括的なテストのためのBash自動化テストシステム（Bats）をマスター。シェルスクリプトのテスト作成、CI/CDパイプライン、またはシェルユーティリティのテスト駆動開発が必要な場合に使用してください。
---

> **[English](../../../../plugins/shell-scripting/skills/bats-testing-patterns/SKILL.md)** | **日本語**

# Batsテストパターン

Bats（Bash自動化テストシステム）を使用したシェルスクリプトの包括的な単体テストの作成に関する包括的なガイダンス。本番グレードのシェルテストのためのテストパターン、フィクスチャ、ベストプラクティスを含みます。

## このスキルを使用する場合

- シェルスクリプトの単体テストを作成
- スクリプトのテスト駆動開発（TDD）を実装
- CI/CDパイプラインで自動テストを設定
- エッジケースとエラー条件をテスト
- 異なるシェル環境間で動作を検証
- スクリプトの保守可能なテストスイートを構築
- 複雑なテストシナリオのフィクスチャを作成
- 複数のシェル方言（bash、sh、dash）をテスト

## Bats基礎

### Batsとは？

Bats（Bash自動化テストシステム）は、シェルスクリプトのためのTAP（Test Anything Protocol）準拠テストフレームワークで、以下を提供します：
- シンプルで自然なテスト構文
- CIシステムと互換性のあるTAP出力形式
- フィクスチャとsetup/teardownサポート
- アサーションヘルパー
- 並列テスト実行

### インストール

```bash
# macOS with Homebrew
brew install bats-core

# Ubuntu/Debian
git clone https://github.com/bats-core/bats-core.git
cd bats-core
./install.sh /usr/local

# From npm (Node.js)
npm install --global bats

# インストールを確認
bats --version
```

### ファイル構造

```
project/
├── bin/
│   ├── script.sh
│   └── helper.sh
├── tests/
│   ├── test_script.bats
│   ├── test_helper.sh
│   ├── fixtures/
│   │   ├── input.txt
│   │   └── expected_output.txt
│   └── helpers/
│       └── mocks.bash
└── README.md
```

## 基本テスト構造

### シンプルなテストファイル

```bash
#!/usr/bin/env bats

# 存在する場合はテストヘルパーをロード
load test_helper

# setupは各テストの前に実行
setup() {
    export TMPDIR=$(mktemp -d)
}

# teardownは各テストの後に実行
teardown() {
    rm -rf "$TMPDIR"
}

# テスト: シンプルなアサーション
@test "Function returns 0 on success" {
    run my_function "input"
    [ "$status" -eq 0 ]
}

# テスト: 出力検証
@test "Function outputs correct result" {
    run my_function "test"
    [ "$output" = "expected output" ]
}

# テスト: エラーハンドリング
@test "Function returns 1 on missing argument" {
    run my_function
    [ "$status" -eq 1 ]
}
```

## アサーションパターン

### 終了コードアサーション

```bash
#!/usr/bin/env bats

@test "Command succeeds" {
    run true
    [ "$status" -eq 0 ]
}

@test "Command fails as expected" {
    run false
    [ "$status" -ne 0 ]
}

@test "Command returns specific exit code" {
    run my_function --invalid
    [ "$status" -eq 127 ]
}

@test "Can capture command result" {
    run echo "hello"
    [ $status -eq 0 ]
    [ "$output" = "hello" ]
}
```

### 出力アサーション

```bash
#!/usr/bin/env bats

@test "Output matches string" {
    result=$(echo "hello world")
    [ "$result" = "hello world" ]
}

@test "Output contains substring" {
    result=$(echo "hello world")
    [[ "$result" == *"world"* ]]
}

@test "Output matches pattern" {
    result=$(date +%Y)
    [[ "$result" =~ ^[0-9]{4}$ ]]
}

@test "Multi-line output" {
    run printf "line1\\nline2\\nline3"
    [ "$output" = "line1
line2
line3" ]
}

@test "Lines variable contains output" {
    run printf "line1\\nline2\\nline3"
    [ "${lines[0]}" = "line1" ]
    [ "${lines[1]}" = "line2" ]
    [ "${lines[2]}" = "line3" ]
}
```

### ファイルアサーション

```bash
#!/usr/bin/env bats

@test "File is created" {
    [ ! -f "$TMPDIR/output.txt" ]
    my_function > "$TMPDIR/output.txt"
    [ -f "$TMPDIR/output.txt" ]
}

@test "File contents match expected" {
    my_function > "$TMPDIR/output.txt"
    [ "$(cat "$TMPDIR/output.txt")" = "expected content" ]
}

@test "File is readable" {
    touch "$TMPDIR/test.txt"
    [ -r "$TMPDIR/test.txt" ]
}

@test "File has correct permissions" {
    touch "$TMPDIR/test.txt"
    chmod 644 "$TMPDIR/test.txt"
    [ "$(stat -f %OLp "$TMPDIR/test.txt")" = "644" ]
}

@test "File size is correct" {
    echo -n "12345" > "$TMPDIR/test.txt"
    [ "$(wc -c < "$TMPDIR/test.txt")" -eq 5 ]
}
```

## SetupとTeardownパターン

### 基本SetupとTeardown

```bash
#!/usr/bin/env bats

setup() {
    # テストディレクトリを作成
    TEST_DIR=$(mktemp -d)
    export TEST_DIR

    # テスト対象のスクリプトをソース
    source "${BATS_TEST_DIRNAME}/../bin/script.sh"
}

teardown() {
    # 一時ディレクトリをクリーンアップ
    rm -rf "$TEST_DIR"
}

@test "Test using TEST_DIR" {
    touch "$TEST_DIR/file.txt"
    [ -f "$TEST_DIR/file.txt" ]
}
```

### リソースを伴うSetup

```bash
#!/usr/bin/env bats

setup() {
    # ディレクトリ構造を作成
    mkdir -p "$TMPDIR/data/input"
    mkdir -p "$TMPDIR/data/output"

    # テストフィクスチャを作成
    echo "line1" > "$TMPDIR/data/input/file1.txt"
    echo "line2" > "$TMPDIR/data/input/file2.txt"

    # 環境を初期化
    export DATA_DIR="$TMPDIR/data"
    export INPUT_DIR="$DATA_DIR/input"
    export OUTPUT_DIR="$DATA_DIR/output"
}

teardown() {
    rm -rf "$TMPDIR/data"
}

@test "Processes input files" {
    run my_process_script "$INPUT_DIR" "$OUTPUT_DIR"
    [ "$status" -eq 0 ]
    [ -f "$OUTPUT_DIR/file1.txt" ]
}
```

### グローバルSetup/Teardown

```bash
#!/usr/bin/env bats

# test_helper.shから共有setupをロード
load test_helper

# setup_fileはすべてのテストの前に一度実行
setup_file() {
    export SHARED_RESOURCE=$(mktemp -d)
    echo "Expensive setup" > "$SHARED_RESOURCE/data.txt"
}

# teardown_fileはすべてのテストの後に一度実行
teardown_file() {
    rm -rf "$SHARED_RESOURCE"
}

@test "First test uses shared resource" {
    [ -f "$SHARED_RESOURCE/data.txt" ]
}

@test "Second test uses shared resource" {
    [ -d "$SHARED_RESOURCE" ]
}
```

## モッキングとスタブパターン

### 関数モッキング

```bash
#!/usr/bin/env bats

# 外部コマンドをモック
my_external_tool() {
    echo "mocked output"
    return 0
}

@test "Function uses mocked tool" {
    export -f my_external_tool
    run my_function
    [[ "$output" == *"mocked output"* ]]
}
```

### コマンドスタブ

```bash
#!/usr/bin/env bats

setup() {
    # スタブディレクトリを作成
    STUBS_DIR="$TMPDIR/stubs"
    mkdir -p "$STUBS_DIR"

    # PATHに追加
    export PATH="$STUBS_DIR:$PATH"
}

create_stub() {
    local cmd="$1"
    local output="$2"
    local code="${3:-0}"

    cat > "$STUBS_DIR/$cmd" <<EOF
#!/bin/bash
echo "$output"
exit $code
EOF
    chmod +x "$STUBS_DIR/$cmd"
}

@test "Function works with stubbed curl" {
    create_stub curl "{ \"status\": \"ok\" }" 0
    run my_api_function
    [ "$status" -eq 0 ]
}
```

### 変数スタブ

```bash
#!/usr/bin/env bats

@test "Function handles environment override" {
    export MY_SETTING="override_value"
    run my_function
    [ "$status" -eq 0 ]
    [[ "$output" == *"override_value"* ]]
}

@test "Function uses default when var unset" {
    unset MY_SETTING
    run my_function
    [ "$status" -eq 0 ]
    [[ "$output" == *"default"* ]]
}
```

## フィクスチャ管理

### フィクスチャファイルの使用

```bash
#!/usr/bin/env bats

# フィクスチャディレクトリ: tests/fixtures/

setup() {
    FIXTURES_DIR="${BATS_TEST_DIRNAME}/fixtures"
    WORK_DIR=$(mktemp -d)
    export WORK_DIR
}

teardown() {
    rm -rf "$WORK_DIR"
}

@test "Process fixture file" {
    # フィクスチャを作業ディレクトリにコピー
    cp "$FIXTURES_DIR/input.txt" "$WORK_DIR/input.txt"

    # 関数を実行
    run my_process_function "$WORK_DIR/input.txt"

    # 出力を比較
    diff "$WORK_DIR/output.txt" "$FIXTURES_DIR/expected_output.txt"
}
```

### 動的フィクスチャ生成

```bash
#!/usr/bin/env bats

generate_fixture() {
    local lines="$1"
    local file="$2"

    for i in $(seq 1 "$lines"); do
        echo "Line $i content" >> "$file"
    done
}

@test "Handle large input file" {
    generate_fixture 1000 "$TMPDIR/large.txt"
    run my_function "$TMPDIR/large.txt"
    [ "$status" -eq 0 ]
    [ "$(wc -l < "$TMPDIR/large.txt")" -eq 1000 ]
}
```

## 高度なパターン

### エラー条件のテスト

```bash
#!/usr/bin/env bats

@test "Function fails with missing file" {
    run my_function "/nonexistent/file.txt"
    [ "$status" -ne 0 ]
    [[ "$output" == *"not found"* ]]
}

@test "Function fails with invalid input" {
    run my_function ""
    [ "$status" -ne 0 ]
}

@test "Function fails with permission denied" {
    touch "$TMPDIR/readonly.txt"
    chmod 000 "$TMPDIR/readonly.txt"
    run my_function "$TMPDIR/readonly.txt"
    [ "$status" -ne 0 ]
    chmod 644 "$TMPDIR/readonly.txt"  # クリーンアップ
}

@test "Function provides helpful error message" {
    run my_function --invalid-option
    [ "$status" -ne 0 ]
    [[ "$output" == *"Usage:"* ]]
}
```

### 依存関係を伴うテスト

```bash
#!/usr/bin/env bats

setup() {
    # 必要なツールをチェック
    if ! command -v jq &>/dev/null; then
        skip "jq is not installed"
    fi

    export SCRIPT="${BATS_TEST_DIRNAME}/../bin/script.sh"
}

@test "JSON parsing works" {
    skip_if ! command -v jq &>/dev/null
    run my_json_parser '{"key": "value"}'
    [ "$status" -eq 0 ]
}
```

### シェル互換性のテスト

```bash
#!/usr/bin/env bats

@test "Script works in bash" {
    bash "${BATS_TEST_DIRNAME}/../bin/script.sh" arg1
}

@test "Script works in sh (POSIX)" {
    sh "${BATS_TEST_DIRNAME}/../bin/script.sh" arg1
}

@test "Script works in dash" {
    if command -v dash &>/dev/null; then
        dash "${BATS_TEST_DIRNAME}/../bin/script.sh" arg1
    else
        skip "dash not installed"
    fi
}
```

### 並列実行

```bash
#!/usr/bin/env bats

@test "Multiple independent operations" {
    run bash -c 'for i in {1..10}; do
        my_operation "$i" &
    done
    wait'
    [ "$status" -eq 0 ]
}

@test "Concurrent file operations" {
    for i in {1..5}; do
        my_function "$TMPDIR/file$i" &
    done
    wait
    [ -f "$TMPDIR/file1" ]
    [ -f "$TMPDIR/file5" ]
}
```

## テストヘルパーパターン

### test_helper.sh

```bash
#!/usr/bin/env bash

# テスト対象のスクリプトをソース
export SCRIPT_DIR="${BATS_TEST_DIRNAME%/*}/bin"

# 共通テストユーティリティ
assert_file_exists() {
    if [ ! -f "$1" ]; then
        echo "Expected file to exist: $1"
        return 1
    fi
}

assert_file_equals() {
    local file="$1"
    local expected="$2"

    if [ ! -f "$file" ]; then
        echo "File does not exist: $file"
        return 1
    fi

    local actual=$(cat "$file")
    if [ "$actual" != "$expected" ]; then
        echo "File contents do not match"
        echo "Expected: $expected"
        echo "Actual: $actual"
        return 1
    fi
}

# 一時テストディレクトリを作成
setup_test_dir() {
    export TEST_DIR=$(mktemp -d)
}

cleanup_test_dir() {
    rm -rf "$TEST_DIR"
}
```

## CI/CDとの統合

### GitHub Actionsワークフロー

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Install Bats
        run: |
          npm install --global bats

      - name: Run Tests
        run: |
          bats tests/*.bats

      - name: Run Tests with Tap Reporter
        run: |
          bats tests/*.bats --tap | tee test_output.tap
```

### Makefile統合

```makefile
.PHONY: test test-verbose test-tap

test:
\tbats tests/*.bats

test-verbose:
\tbats tests/*.bats --verbose

test-tap:
\tbats tests/*.bats --tap

test-parallel:
\tbats tests/*.bats --parallel 4

coverage: test
\t# オプション: カバレッジレポートを生成
```

## ベストプラクティス

1. **テストごとに1つをテスト** - 単一責任原則
2. **説明的なテスト名を使用** - テストされるものを明確に記述
3. **テスト後にクリーンアップ** - teardownで常に一時ファイルを削除
4. **成功と失敗の両方のパスをテスト** - ハッピーパスだけテストしない
5. **外部依存関係をモック** - テスト対象のユニットを分離
6. **複雑なデータにはフィクスチャを使用** - テストがより読みやすくなる
7. **CI/CDでテストを実行** - リグレッションを早期に捕捉
8. **シェル方言をまたいでテスト** - 移植性を確保
9. **テストを高速に保つ** - 可能な場合は並列実行
10. **複雑なテストセットアップを文書化** - 異常なパターンを説明

## リソース

- **Bats GitHub**: https://github.com/bats-core/bats-core
- **Batsドキュメント**: https://bats-core.readthedocs.io/
- **TAPプロトコル**: https://testanything.org/
- **テスト駆動開発**: https://en.wikipedia.org/wiki/Test-driven_development
