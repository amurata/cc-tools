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

# 新規ファイルの検出 (英語版にあって日本語版にないファイル)
find plugins -type f -name "*.md" | while read -r file; do
    ja_file="i18n/ja/$file"
    if [ ! -f "$ja_file" ]; then
        echo "- [ ] \`$file\`" >> "$TODO_FILE"
    fi
done

echo -e "\n## 🔄 更新が必要なファイル (英語版が更新済み)" >> "$TODO_FILE"

# 更新ファイルの検出 (check-outdated.shのロジックを流用・拡張)
find plugins -type f -name "*.md" | while read -r source_file; do
    ja_file="i18n/ja/$source_file"
    
    if [ -f "$ja_file" ]; then
        # gitの更新時刻で比較
        source_time=$(git log -1 --format=%ct -- "$source_file" 2>/dev/null || echo "0")
        ja_time=$(git log -1 --format=%ct -- "$ja_file" 2>/dev/null || echo "0")

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
