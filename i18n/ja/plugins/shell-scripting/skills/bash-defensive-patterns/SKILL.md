> **[English](../../../../plugins/shell-scripting/skills/bash-defensive-patterns/SKILL.md)** | **日本語**

---
name: bash-defensive-patterns
description: 本番グレードスクリプトのための防御的Bashプログラミング技術をマスター。堅牢なシェルスクリプト、CI/CDパイプライン、または耐障害性と安全性を必要とするシステムユーティリティを作成する際に使用してください。
---

# Bash防御的パターン

防御的プログラミング技術、エラーハンドリング、安全性のベストプラクティスを使用して本番対応Bashスクリプトを作成するための包括的なガイダンス。一般的な落とし穴を防ぎ、信頼性を確保します。

## このスキルを使用する場合

- 本番自動化スクリプトを作成
- CI/CDパイプラインスクリプトを構築
- システム管理ユーティリティを作成
- エラーに強いデプロイメント自動化を開発
- エッジケースを安全に処理する必要があるスクリプトを作成
- 保守可能なシェルスクリプトライブラリを構築
- 包括的なロギングと監視を実装
- 異なるプラットフォーム間で動作する必要があるスクリプトを作成

## コア防御的原則

### 1. 厳格モード
エラーを早期に検出するため、すべてのスクリプトの開始時にbash厳格モードを有効化します。

```bash
#!/bin/bash
set -Eeuo pipefail  # エラー時に終了、未設定変数、パイプ失敗
```

**主要フラグ:**
- `set -E`: 関数でERRトラップを継承
- `set -e`: 任意のエラーで終了（コマンドが非ゼロを返す）
- `set -u`: 未定義変数参照で終了
- `set -o pipefail`: 任意のコマンドが失敗したらパイプが失敗（最後だけでなく）

### 2. エラートラップとクリーンアップ
スクリプト終了またはエラー時の適切なクリーンアップを実装します。

```bash
#!/bin/bash
set -Eeuo pipefail

trap 'echo "Error on line $LINENO"' ERR
trap 'echo "Cleaning up..."; rm -rf "$TMPDIR"' EXIT

TMPDIR=$(mktemp -d)
# ここにスクリプトコード
```

### 3. 変数安全性
単語分割とグロビング問題を防ぐため、常に変数をクォートします。

```bash
# 誤り - 安全でない
cp $source $dest

# 正解 - 安全
cp "$source" "$dest"

# 必須変数 - 未設定の場合メッセージで失敗
: "${REQUIRED_VAR:?REQUIRED_VAR is not set}"
```

### 4. 配列処理
複雑なデータ処理のため配列を安全に使用します。

```bash
# 安全な配列反復
declare -a items=("item 1" "item 2" "item 3")

for item in "${items[@]}"; do
    echo "Processing: $item"
done

# 出力を配列に安全に読み込み
mapfile -t lines < <(some_command)
readarray -t numbers < <(seq 1 10)
```

### 5. 条件安全性
Bash固有機能には`[[ ]]`を、POSIXには`[ ]`を使用します。

```bash
# Bash - より安全
if [[ -f "$file" && -r "$file" ]]; then
    content=$(<"$file")
fi

# POSIX - ポータブル
if [ -f "$file" ] && [ -r "$file" ]; then
    content=$(cat "$file")
fi

# 操作前に存在をテスト
if [[ -z "${VAR:-}" ]]; then
    echo "VAR is not set or is empty"
fi
```

## 基本パターン

### パターン1: 安全なスクリプトディレクトリ検出

```bash
#!/bin/bash
set -Eeuo pipefail

# スクリプトディレクトリを正しく決定
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
SCRIPT_NAME="$(basename -- "${BASH_SOURCE[0]}")"

echo "Script location: $SCRIPT_DIR/$SCRIPT_NAME"
```

### パターン2: 包括的な関数テンプレート

```bash
#!/bin/bash
set -Eeuo pipefail

# 関数のプレフィックス: handle_*, process_*, check_*, validate_*
# ドキュメントとエラーハンドリングを含む

validate_file() {
    local -r file="$1"
    local -r message="${2:-File not found: $file}"

    if [[ ! -f "$file" ]]; then
        echo "ERROR: $message" >&2
        return 1
    fi
    return 0
}

process_files() {
    local -r input_dir="$1"
    local -r output_dir="$2"

    # 入力を検証
    [[ -d "$input_dir" ]] || { echo "ERROR: input_dir not a directory" >&2; return 1; }

    # 必要に応じて出力ディレクトリを作成
    mkdir -p "$output_dir" || { echo "ERROR: Cannot create output_dir" >&2; return 1; }

    # ファイルを安全に処理
    while IFS= read -r -d '' file; do
        echo "Processing: $file"
        # 作業を行う
    done < <(find "$input_dir" -maxdepth 1 -type f -print0)

    return 0
}
```

### パターン3: 安全な一時ファイル処理

```bash
#!/bin/bash
set -Eeuo pipefail

trap 'rm -rf -- "$TMPDIR"' EXIT

# 一時ディレクトリを作成
TMPDIR=$(mktemp -d) || { echo "ERROR: Failed to create temp directory" >&2; exit 1; }

# ディレクトリ内に一時ファイルを作成
TMPFILE1="$TMPDIR/temp1.txt"
TMPFILE2="$TMPDIR/temp2.txt"

# 一時ファイルを使用
touch "$TMPFILE1" "$TMPFILE2"

echo "Temp files created in: $TMPDIR"
```

### パターン4: 堅牢な引数解析

```bash
#!/bin/bash
set -Eeuo pipefail

# デフォルト値
VERBOSE=false
DRY_RUN=false
OUTPUT_FILE=""
THREADS=4

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Options:
    -v, --verbose       Enable verbose output
    -d, --dry-run       Run without making changes
    -o, --output FILE   Output file path
    -j, --jobs NUM      Number of parallel jobs
    -h, --help          Show this help message
EOF
    exit "${1:-0}"
}

# 引数を解析
while [[ $# -gt 0 ]]; do
    case "$1" in
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -j|--jobs)
            THREADS="$2"
            shift 2
            ;;
        -h|--help)
            usage 0
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "ERROR: Unknown option: $1" >&2
            usage 1
            ;;
    esac
done

# 必須引数を検証
[[ -n "$OUTPUT_FILE" ]] || { echo "ERROR: -o/--output is required" >&2; usage 1; }
```

### パターン5: 構造化ロギング

```bash
#!/bin/bash
set -Eeuo pipefail

# ロギング関数
log_info() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $*" >&2
}

log_warn() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] WARN: $*" >&2
}

log_error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2
}

log_debug() {
    if [[ "${DEBUG:-0}" == "1" ]]; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] DEBUG: $*" >&2
    fi
}

# 使用法
log_info "Starting script"
log_debug "Debug information"
log_warn "Warning message"
log_error "Error occurred"
```

### パターン6: シグナルを使用したプロセスオーケストレーション

```bash
#!/bin/bash
set -Eeuo pipefail

# バックグラウンドプロセスを追跡
PIDS=()

cleanup() {
    log_info "Shutting down..."

    # すべてのバックグラウンドプロセスを終了
    for pid in "${PIDS[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
            kill -TERM "$pid" 2>/dev/null || true
        fi
    done

    # グレースフルシャットダウンを待機
    for pid in "${PIDS[@]}"; do
        wait "$pid" 2>/dev/null || true
    done
}

trap cleanup SIGTERM SIGINT

# バックグラウンドタスクを開始
background_task &
PIDS+=($!)

another_task &
PIDS+=($!)

# すべてのバックグラウンドプロセスを待機
wait
```

### パターン7: 安全なファイル操作

```bash
#!/bin/bash
set -Eeuo pipefail

# 上書きせずに安全に移動するため-iフラグを使用
safe_move() {
    local -r source="$1"
    local -r dest="$2"

    if [[ ! -e "$source" ]]; then
        echo "ERROR: Source does not exist: $source" >&2
        return 1
    fi

    if [[ -e "$dest" ]]; then
        echo "ERROR: Destination already exists: $dest" >&2
        return 1
    fi

    mv "$source" "$dest"
}

# 安全なディレクトリクリーンアップ
safe_rmdir() {
    local -r dir="$1"

    if [[ ! -d "$dir" ]]; then
        echo "ERROR: Not a directory: $dir" >&2
        return 1
    fi

    # rm前にプロンプトを出すため-Iフラグを使用（BSD/GNU互換）
    rm -rI -- "$dir"
}

# アトミックファイル書き込み
atomic_write() {
    local -r target="$1"
    local -r tmpfile
    tmpfile=$(mktemp) || return 1

    # まず一時ファイルに書き込み
    cat > "$tmpfile"

    # アトミックリネーム
    mv "$tmpfile" "$target"
}
```

### パターン8: 冪等スクリプト設計

```bash
#!/bin/bash
set -Eeuo pipefail

# リソースが既に存在するかチェック
ensure_directory() {
    local -r dir="$1"

    if [[ -d "$dir" ]]; then
        log_info "Directory already exists: $dir"
        return 0
    fi

    mkdir -p "$dir" || {
        log_error "Failed to create directory: $dir"
        return 1
    }

    log_info "Created directory: $dir"
}

# 設定状態を確保
ensure_config() {
    local -r config_file="$1"
    local -r default_value="$2"

    if [[ ! -f "$config_file" ]]; then
        echo "$default_value" > "$config_file"
        log_info "Created config: $config_file"
    fi
}

# スクリプトを複数回再実行しても安全であるべき
ensure_directory "/var/cache/myapp"
ensure_config "/etc/myapp/config" "DEBUG=false"
```

### パターン9: 安全なコマンド置換

```bash
#!/bin/bash
set -Eeuo pipefail

# バッククォートの代わりに$()を使用
name=$(<"$file")  # ファイルから変数への安全な割り当て
output=$(command -v python3)  # コマンドの場所を安全に取得

# エラーチェック付きコマンド置換を処理
result=$(command -v node) || {
    log_error "node command not found"
    return 1
}

# 複数行の場合
mapfile -t lines < <(grep "pattern" "$file")

# NUL安全反復
while IFS= read -r -d '' file; do
    echo "Processing: $file"
done < <(find /path -type f -print0)
```

### パターン10: ドライランサポート

```bash
#!/bin/bash
set -Eeuo pipefail

DRY_RUN="${DRY_RUN:-false}"

run_cmd() {
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY RUN] Would execute: $*"
        return 0
    fi

    "$@"
}

# 使用法
run_cmd cp "$source" "$dest"
run_cmd rm "$file"
run_cmd chown "$owner" "$target"
```

## 高度な防御的テクニック

### 名前付きパラメータパターン

```bash
#!/bin/bash
set -Eeuo pipefail

process_data() {
    local input_file=""
    local output_dir=""
    local format="json"

    # 名前付きパラメータを解析
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --input=*)
                input_file="${1#*=}"
                ;;
            --output=*)
                output_dir="${1#*=}"
                ;;
            --format=*)
                format="${1#*=}"
                ;;
            *)
                echo "ERROR: Unknown parameter: $1" >&2
                return 1
                ;;
        esac
        shift
    done

    # 必須パラメータを検証
    [[ -n "$input_file" ]] || { echo "ERROR: --input is required" >&2; return 1; }
    [[ -n "$output_dir" ]] || { echo "ERROR: --output is required" >&2; return 1; }
}
```

### 依存関係チェック

```bash
#!/bin/bash
set -Eeuo pipefail

check_dependencies() {
    local -a missing_deps=()
    local -a required=("jq" "curl" "git")

    for cmd in "${required[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            missing_deps+=("$cmd")
        fi
    done

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo "ERROR: Missing required commands: ${missing_deps[*]}" >&2
        return 1
    fi
}

check_dependencies
```

## ベストプラクティスまとめ

1. **常に厳格モードを使用** - `set -Eeuo pipefail`
2. **すべての変数をクォート** - `"$variable"`は単語分割を防ぐ
3. **[[ ]]条件文を使用** - [ ]よりも堅牢
4. **エラートラップを実装** - エラーを優雅に捕捉して処理
5. **すべての入力を検証** - ファイルの存在、権限、形式をチェック
6. **再利用性のため関数を使用** - 意味のある名前でプレフィックス
7. **構造化ロギングを実装** - タイムスタンプとレベルを含める
8. **ドライランモードをサポート** - ユーザーが変更をプレビューできるように
9. **一時ファイルを安全に処理** - mktempを使用、trapでクリーンアップ
10. **冪等性のために設計** - スクリプトは再実行しても安全であるべき
11. **要件を文書化** - 依存関係と最小バージョンをリスト
12. **エラーパスをテスト** - エラーハンドリングが正しく動作することを確認
13. **`command -v`を使用** - 実行可能ファイルのチェックには`which`より安全
14. **echoよりprintfを優先** - システム間でより予測可能

## リソース

- **Bash Strict Mode**: http://redsymbol.net/articles/unofficial-bash-strict-mode/
- **Google Shell Style Guide**: https://google.github.io/styleguide/shellguide.html
- **Defensive BASH Programming**: https://www.lifepipe.net/
