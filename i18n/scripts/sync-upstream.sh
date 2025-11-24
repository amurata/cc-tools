#!/bin/bash
# upstream同期と翻訳状況確認スクリプト

set -e

# カラーコード
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TODO_FILE="$PROJECT_ROOT/TRANSLATION_TODO.md"

cd "$PROJECT_ROOT"

echo -e "${GREEN}=== Upstream 同期と翻訳チェック ===${NC}"

# 1. UpstreamからPull
echo -e "\n${YELLOW}[1/3] Upstreamから更新を取得中...${NC}"
if git remote | grep -q "upstream"; then
    git fetch upstream
    git merge upstream/main
    echo -e "${GREEN}✓ Upstreamと同期しました${NC}"
else
    echo -e "${RED}⚠ upstream リモートが設定されていません。スキップします。${NC}"
    echo "設定するには: git remote add upstream https://github.com/wshobson/agents.git"
fi

# 2. 翻訳状況のチェック
echo -e "\n${YELLOW}[2/3] 翻訳状況をチェック中...${NC}"

# ヘッダー作成
cat << EOF > "$TODO_FILE"
# 翻訳タスクリスト

最終更新: $(date)

## 🆕 未翻訳のファイル (新規追加)
EOF

# 除外パターンの読み込み (簡易的なJSONパース)
# .translation-map.json から exclude_patterns 配列の中身を抽出
EXCLUDES=""
if [ -f ".translation-map.json" ]; then
    # grepとsedで簡易的に抽出（jq依存を避けるため）
    # "exclude_patterns": [ ... ] の中身を取り出す
    RAW_PATTERNS=$(sed -n '/"exclude_patterns": \[/,/\]/p' .translation-map.json | grep -v "exclude_patterns" | grep -v "\]" | sed 's/^[[:space:]]*"//;s/",\{0,1\}$//')
    
    for pattern in $RAW_PATTERNS; do
        # findコマンド用の除外オプションを構築
        # パターンがディレクトリの場合は /* を付与して中身を除外
        if [[ "$pattern" == *"/" ]]; then
            EXCLUDES="$EXCLUDES -not -path \"./$pattern*\""
        elif [[ "$pattern" == *"**"* ]]; then
             # ** を * に置換して簡易対応
             CLEAN_PATTERN=${pattern//\*\*/\*}
             EXCLUDES="$EXCLUDES -not -path \"./$CLEAN_PATTERN\""
        else
            EXCLUDES="$EXCLUDES -not -path \"./$pattern\""
        fi
    done
fi

# 新規ファイルの検出 (英語版にあって日本語版にないファイル)
# evalを使用してEXCLUDES変数を展開
eval "find plugins -type f -name \"*.md\" $EXCLUDES" | while read -r file; do
    ja_file="i18n/ja/$file"
    if [ ! -f "$ja_file" ]; then
        echo "- [ ] \`$file\`" >> "$TODO_FILE"
    fi
done

echo -e "\n## 🔄 更新が必要なファイル (英語版が更新済み)" >> "$TODO_FILE"

# 更新ファイルの検出
eval "find plugins -type f -name \"*.md\" $EXCLUDES" | while read -r source_file; do
    ja_file="i18n/ja/$source_file"
    
    if [ -f "$ja_file" ]; then
        # gitの更新時刻を取得 (空の場合は0)
        source_time=$(git log -1 --format=%ct -- "$source_file" 2>/dev/null)
        if [ -z "$source_time" ]; then source_time=0; fi
        
        ja_git_time=$(git log -1 --format=%ct -- "$ja_file" 2>/dev/null)
        if [ -z "$ja_git_time" ]; then ja_git_time=0; fi

        # ファイルシステムの更新時刻を取得 (macOS/Linux対応)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            ja_fs_time=$(stat -f %m "$ja_file" 2>/dev/null || echo "0")
        else
            ja_fs_time=$(stat -c %Y "$ja_file" 2>/dev/null || echo "0")
        fi
        
        # 日本語ファイルは、gitの時刻とFSの時刻の新しい方を採用 (未コミットの変更を反映するため)
        if [ "$ja_fs_time" -gt "$ja_git_time" ]; then
            ja_time=$ja_fs_time
        else
            ja_time=$ja_git_time
        fi

        if [ "$source_time" -gt "$ja_time" ]; then
            diff_days=$(( (source_time - ja_time) / 86400 ))
            echo "- [ ] \`$source_file\` (英語版が ${diff_days}日 新しい)" >> "$TODO_FILE"
        fi
    fi
done

# 3. 完了報告
echo -e "\n${YELLOW}[3/3] レポート作成完了${NC}"
echo -e "タスクリストを生成しました: ${GREEN}$TODO_FILE${NC}"
echo "このファイルを確認して翻訳作業を進めてください。"
