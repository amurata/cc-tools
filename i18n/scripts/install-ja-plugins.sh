#!/usr/bin/env bash
#
# Claude Code Workflows - 日本語版プラグイン インストールスクリプト
#
# 使い方:
#   ./install-ja-plugins.sh [オプション] <インストール先ディレクトリ>
#
# 例:
#   ./install-ja-plugins.sh ~/my-project
#   ./install-ja-plugins.sh --dry-run .
#   ./install-ja-plugins.sh --force ~/my-project
#
# 逆にプロジェクトのディレクトリからこのプラグインをインストールする場合:
#   # cc-tools が /path/to/cc-tools にあるケース
#   /path/to/cc-tools/i18n/scripts/install-ja-plugins.sh .
#

set -euo pipefail

# =============================================================================
# カラーコード設定
# =============================================================================

if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    BOLD=''
    NC=''
fi

# =============================================================================
# 出力関数
# =============================================================================

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_header() {
    echo -e "\n${BOLD}$1${NC}"
}

# =============================================================================
# ヘルプメッセージ
# =============================================================================

show_help() {
    cat << EOF
${BOLD}Claude Code Workflows - 日本語版プラグイン インストーラー${NC}

${BOLD}使い方:${NC}
    $0 [オプション] <インストール先ディレクトリ>

${BOLD}オプション:${NC}
    -h, --help          このヘルプメッセージを表示
    -f, --force         既存ファイルを確認なしで上書き
    -n, --dry-run       実際にはコピーせず、何が起こるかを表示
    --no-backup         既存ファイルのバックアップを作成しない

${BOLD}例:${NC}
    # カレントディレクトリにインストール
    $0 .

    # 指定したディレクトリにインストール
    $0 ~/my-project

    # ドライラン（何が起こるか確認）
    $0 --dry-run ~/my-project

    # 強制上書き（確認なし）
    $0 --force ~/my-project

${BOLD}説明:${NC}
    このスクリプトは、Claude Code Workflows の日本語翻訳版プラグインを
    指定したディレクトリにインストールします。

    以下のディレクトリがコピーされます:
    - .claude-plugin/  (プラグインマーケットプレイス設定)
    - plugins/         (翻訳済みプラグイン本体)

    既存のファイルがある場合は、自動的にバックアップが作成されます。

EOF
}

# =============================================================================
# エラーハンドリング
# =============================================================================

error_exit() {
    print_error "$1"
    exit 1
}

cleanup() {
    if [ -n "${TEMP_DIR:-}" ] && [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
}

trap cleanup EXIT

# =============================================================================
# 変数初期化
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$(cd "$SCRIPT_DIR/../ja" && pwd)"
TARGET_DIR=""
DRY_RUN=false
FORCE=false
NO_BACKUP=false
TEMP_DIR=""

# =============================================================================
# コマンドライン引数の解析
# =============================================================================

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            -n|--dry-run)
                DRY_RUN=true
                shift
                ;;
            --no-backup)
                NO_BACKUP=true
                shift
                ;;
            -*)
                error_exit "不明なオプション: $1"
                ;;
            *)
                if [ -z "$TARGET_DIR" ]; then
                    TARGET_DIR="$1"
                else
                    error_exit "インストール先は1つだけ指定してください"
                fi
                shift
                ;;
        esac
    done

    # インストール先が指定されていない場合
    if [ -z "$TARGET_DIR" ]; then
        error_exit "インストール先ディレクトリを指定してください。使い方: $0 --help"
    fi

    # インストール先の絶対パス化
    TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd)" || \
        error_exit "インストール先ディレクトリが存在しません: $TARGET_DIR"
}

# =============================================================================
# 環境チェック
# =============================================================================

check_environment() {
    print_header "環境チェック"

    # ソースディレクトリの確認
    if [ ! -d "$SOURCE_DIR/.claude-plugin" ]; then
        error_exit "ソースディレクトリが見つかりません: $SOURCE_DIR/.claude-plugin"
    fi

    if [ ! -d "$SOURCE_DIR/plugins" ]; then
        error_exit "ソースディレクトリが見つかりません: $SOURCE_DIR/plugins"
    fi

    print_success "ソースディレクトリ: $SOURCE_DIR"
    print_success "インストール先: $TARGET_DIR"

    # 必要なコマンドの確認
    for cmd in cp mv mkdir; do
        if ! command -v "$cmd" &> /dev/null; then
            error_exit "必要なコマンドが見つかりません: $cmd"
        fi
    done
}

# =============================================================================
# バックアップ作成
# =============================================================================

create_backup() {
    local target_path="$1"
    local backup_suffix="backup.$(date +%Y%m%d_%H%M%S)"

    if [ -e "$target_path" ]; then
        local backup_path="${target_path}.${backup_suffix}"
        
        if [ "$DRY_RUN" = true ]; then
            print_info "[DRY-RUN] バックアップを作成: $backup_path"
        else
            mv "$target_path" "$backup_path"
            print_success "バックアップを作成: $backup_path"
        fi
    fi
}

# =============================================================================
# ファイルコピー
# =============================================================================

copy_files() {
    print_header "ファイルのコピー"

    local plugin_target="$TARGET_DIR/.claude-plugin"
    local plugins_target="$TARGET_DIR/plugins"

    # .claude-plugin/ のコピー
    if [ -d "$plugin_target" ]; then
        if [ "$FORCE" = false ]; then
            print_warning "既存の .claude-plugin/ が見つかりました"
            read -p "上書きしますか? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_info "インストールをキャンセルしました"
                exit 0
            fi
        fi

        if [ "$NO_BACKUP" = false ]; then
            create_backup "$plugin_target"
        else
            if [ "$DRY_RUN" = false ]; then
                rm -rf "$plugin_target"
            fi
        fi
    fi

    if [ "$DRY_RUN" = true ]; then
        print_info "[DRY-RUN] コピー: $SOURCE_DIR/.claude-plugin → $plugin_target"
    else
        cp -r "$SOURCE_DIR/.claude-plugin" "$plugin_target"
        print_success "コピー完了: .claude-plugin/"
    fi

    # plugins/ のコピー
    if [ -d "$plugins_target" ]; then
        if [ "$FORCE" = false ]; then
            print_warning "既存の plugins/ が見つかりました"
            read -p "上書きしますか? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_info "インストールをキャンセルしました"
                exit 0
            fi
        fi

        if [ "$NO_BACKUP" = false ]; then
            create_backup "$plugins_target"
        else
            if [ "$DRY_RUN" = false ]; then
                rm -rf "$plugins_target"
            fi
        fi
    fi

    if [ "$DRY_RUN" = true ]; then
        print_info "[DRY-RUN] コピー: $SOURCE_DIR/plugins → $plugins_target"
    else
        cp -r "$SOURCE_DIR/plugins" "$plugins_target"
        print_success "コピー完了: plugins/"
    fi

    # README.plugins.md のコピー
    local readme_source="$SOURCE_DIR/README.plugins.md"
    local readme_target="$TARGET_DIR/README.plugins.md"

    if [ -f "$readme_source" ]; then
        if [ "$DRY_RUN" = true ]; then
            print_info "[DRY-RUN] コピー: $readme_source → $readme_target"
        else
            cp "$readme_source" "$readme_target"
            print_success "コピー完了: README.plugins.md"
        fi
    fi
}

# =============================================================================
# インストール完了メッセージ
# =============================================================================

show_completion_message() {
    print_header "インストール完了"

    if [ "$DRY_RUN" = true ]; then
        print_info "これはドライランです。実際のファイルは変更されていません。"
        print_info "実際にインストールするには、--dry-run オプションを外して実行してください。"
    else
        print_success "日本語版プラグインのインストールが完了しました！"
        echo
        print_info "インストール先: $TARGET_DIR"
        print_info "プラグイン数: 64個"
        echo
        print_info "次のステップ:"
        print_info "  1. Claude Code を起動してください"
        print_info "  2. プラグインが自動的に読み込まれます"
        print_info "  3. /help コマンドで使用可能なプラグインを確認できます"
    fi
}

# =============================================================================
# メイン処理
# =============================================================================

main() {
    parse_arguments "$@"
    check_environment
    copy_files
    show_completion_message
}

main "$@"
