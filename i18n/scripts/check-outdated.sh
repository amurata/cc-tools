#!/bin/bash
# 翻訳の陳腐化をチェックするスクリプト

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TRANSLATION_MAP="$PROJECT_ROOT/.translation-map.json"

cd "$PROJECT_ROOT"

# 翻訳対象ファイルのリストを取得（instructionsディレクトリを除外）
find . -type f \( -name "*.md" -o -name "*.json" \) \
  -not -path "./.git/*" \
  -not -path "./.serena/*" \
  -not -path "./instructions/*" \
  -not -path "./.claude/ja/*" \
  -not -path "./i18n/*" \
  -not -path "./node_modules/*" | while read -r source_file; do

  # 対応する日本語ファイルのパスを生成
  ja_file="i18n/ja/${source_file#./}"

  if [ -f "$ja_file" ]; then
    # ファイルが存在する場合、ハッシュを比較
    source_hash=$(git hash-object "$source_file" 2>/dev/null || echo "")
    ja_hash=$(git log -1 --format=%H -- "$ja_file" 2>/dev/null || echo "")

    # 英語ファイルの最終更新日時と日本語ファイルの最終更新日時を比較
    source_time=$(git log -1 --format=%ct -- "$source_file" 2>/dev/null || echo "0")
    ja_time=$(git log -1 --format=%ct -- "$ja_file" 2>/dev/null || echo "0")

    if [ "$source_time" -gt "$ja_time" ]; then
      echo "- [ ] $source_file (英語版が更新されています)"
    fi
  else
    echo "- [ ] $source_file (翻訳が未作成です)"
  fi
done
