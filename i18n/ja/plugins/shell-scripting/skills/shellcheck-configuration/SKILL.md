---
name: shellcheck-configuration
description: シェルスクリプト品質のためのShellCheck静的解析の設定と使用をマスター。リンティングインフラの設定、コード問題の修正、またはスクリプトの移植性の確保時に使用してください。
---

> **[English](../../../../plugins/shell-scripting/skills/shellcheck-configuration/SKILL.md)** | **日本語**

# ShellCheck設定と静的解析

ShellCheckの設定と使用に関する包括的なガイダンス。静的コード解析を通じてシェルスクリプトの品質を改善し、一般的な落とし穴を捕捉し、ベストプラクティスを実施します。

## このスキルを使用する場合

- CI/CDパイプラインでシェルスクリプトのリンティングを設定
- 既存のシェルスクリプトの問題を分析
- ShellCheckエラーコードと警告を理解
- 特定のプロジェクト要件に応じてShellCheckを設定
- 開発ワークフローにShellCheckを統合
- 誤検出を抑制し、ルールセットを設定
- 一貫したコード品質標準を実施
- 品質ゲートを満たすためスクリプトを移行

## ShellCheck基礎

### ShellCheckとは？

ShellCheckは、シェルスクリプトを分析し問題のあるパターンを検出する静的解析ツールです。以下をサポートします：
- Bash、sh、dash、ksh、その他のPOSIXシェル
- 100以上の異なる警告とエラー
- ターゲットシェルとフラグの設定
- エディタとCI/CDシステムとの統合

### インストール

```bash
# macOS with Homebrew
brew install shellcheck

# Ubuntu/Debian
apt-get install shellcheck

# From source
git clone https://github.com/koalaman/shellcheck.git
cd shellcheck
make build
make install

# インストールを確認
shellcheck --version
```

## 設定ファイル

### .shellcheckrc（プロジェクトレベル）

プロジェクトルートに`.shellcheckrc`を作成：

```
# ターゲットシェルを指定
shell=bash

# オプションチェックを有効化
enable=avoid-nullary-conditions
enable=require-variable-braces

# 特定の警告を無効化
disable=SC1091
disable=SC2086
```

### 環境変数

```bash
# デフォルトシェルターゲットを設定
export SHELLCHECK_SHELL=bash

# 厳格モードを有効化
export SHELLCHECK_STRICT=true

# 設定ファイルの場所を指定
export SHELLCHECK_CONFIG=~/.shellcheckrc
```

## 一般的なShellCheckエラーコード

### SC1000-1099: パーサーエラー
```bash
# SC1004: バックスラッシュ継続が改行に続かない
echo hello\\\nworld  # エラー - 行継続が必要

# SC1008: 演算子`=='の無効なデータ
if [[ $var =  "value" ]]; then  # ==の前のスペース
    true
fi
```

### SC2000-2099: シェル問題

```bash
# SC2009: grepの代わりにpgrepまたはpidofの使用を検討
ps aux | grep -v grep | grep myprocess  # 代わりにpgrepを使用

# SC2012: `ls`は閲覧のみに使用。信頼性のある出力には`find`を使用
for file in $(ls -la)  # より良い方法: findまたはグロビングを使用

# SC2015: if-then-elseの代わりに&&と||を使用するのを避ける
[[ -f "$file" ]] && echo "found" || echo "not found"  # より明確でない

# SC2016: 式はシングルクォートで展開されない
echo '$VAR'  # リテラル$VAR、変数展開ではない

# SC2026: この単語は非標準。他のシェル用スクリプトで使用する場合はPOSIXLY_CORRECTを設定
```

### SC2100-2199: クォート問題

```bash
# SC2086: グロビングと単語分割を防ぐためダブルクォート
for i in $list; do  # 次であるべき: for i in $listまたはfor i in "$list"
    echo "$i"
done

# SC2115: パスのリテラルチルダは展開されない。代わりに$HOMEを使用
~/.bashrc  # 文字列内では、"$HOME/.bashrc"を使用

# SC2181: `if`で直接終了コードをチェック、リストで間接的ではない
some_command
if [ $? -eq 0 ]; then  # より良い方法: if some_command; then

# SC2206: 単語分割を防ぐためクォートまたはIFSを設定
array=( $items )  # 次を使用すべき: array=( $items )
```

### SC3000-3999: POSIX準拠問題

```bash
# SC3010: POSIX shでは、'cond && foo'の代わりに'case'を使用
[[ $var == "value" ]] && do_something  # POSIXでない

# SC3043: POSIX shでは、'local'は未定義
function my_func() {
    local var=value  # 一部のシェルではPOSIXでない
}
```

## 実用的な設定例

### 最小限の設定（厳格なPOSIX）

```bash
#!/bin/bash
# 最大の移植性のため設定

shellcheck \
  --shell=sh \
  --external-sources \
  --check-sourced \
  script.sh
```

### 開発設定（緩和されたルールのBash）

```bash
#!/bin/bash
# Bash開発のため設定

shellcheck \
  --shell=bash \
  --exclude=SC1091,SC2119 \
  --enable=all \
  script.sh
```

### CI/CD統合設定

```bash
#!/bin/bash
set -Eeuo pipefail

# すべてのシェルスクリプトを分析し、問題で失敗
find . -type f -name "*.sh" | while read -r script; do
    echo "Checking: $script"
    shellcheck \
        --shell=bash \
        --format=gcc \
        --exclude=SC1091 \
        "$script" || exit 1
done
```

### プロジェクト用.shellcheckrc

```
# 分析するシェル方言
shell=bash

# オプションチェックを有効化
enable=avoid-nullary-conditions,require-variable-braces,check-unassigned-uppercase

# 特定の警告を無効化
# SC1091: ソースされたファイルをフォローしない（多くの誤検出）
disable=SC1091

# SC2119: function_name--（引数）の代わりにfunction_nameを使用
disable=SC2119

# コンテキストのため外部ファイルをソース
external-sources=true
```

## 統合パターン

### Pre-commitフック設定

```bash
#!/bin/bash
# .git/hooks/pre-commit

#!/bin/bash
set -e

# このコミットで変更されたすべてのシェルスクリプトを検索
git diff --cached --name-only | grep '\\.sh$' | while read -r script; do
    echo "Linting: $script"

    if ! shellcheck "$script"; then
        echo "ShellCheck failed on $script"
        exit 1
    fi
done
```

### GitHub Actionsワークフロー

```yaml
name: ShellCheck

on: [push, pull_request]

jobs:
  shellcheck:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Run ShellCheck
        run: |
          sudo apt-get install shellcheck
          find . -type f -name "*.sh" -exec shellcheck {} \\;
```

### GitLab CIパイプライン

```yaml
shellcheck:
  stage: lint
  image: koalaman/shellcheck-alpine
  script:
    - find . -type f -name "*.sh" -exec shellcheck {} \\;
  allow_failure: false
```

## ShellCheck違反の処理

### 特定の警告を抑制

```bash
#!/bin/bash

# 行全体の警告を無効化
# shellcheck disable=SC2086
for file in $(ls -la); do
    echo "$file"
done

# スクリプト全体で無効化
# shellcheck disable=SC1091,SC2119

# 複数の警告を無効化（形式は異なる）
command_that_fails() {
    # shellcheck disable=SC2015
    [ -f "$1" ] && echo "found" || echo "not found"
}

# sourceディレクティブの特定のチェックを無効化
# shellcheck source=./helper.sh
source helper.sh
```

### 一般的な違反と修正

#### SC2086: 単語分割を防ぐためダブルクォート

```bash
# 問題
for i in $list; do done

# 解決策
for i in $list; do done  # $listが既にクォートされている場合、または
for i in "${list[@]}"; do done  # listが配列の場合
```

#### SC2181: 終了コードを直接チェック

```bash
# 問題
some_command
if [ $? -eq 0 ]; then
    echo "success"
fi

# 解決策
if some_command; then
    echo "success"
fi
```

#### SC2015: &&||の代わりにif-thenを使用

```bash
# 問題
[ -f "$file" ] && echo "exists" || echo "not found"

# 解決策 - より明確な意図
if [ -f "$file" ]; then
    echo "exists"
else
    echo "not found"
fi
```

#### SC2016: 式はシングルクォートで展開されない

```bash
# 問題
echo 'Variable value: $VAR'

# 解決策
echo "Variable value: $VAR"
```

#### SC2009: grepの代わりにpgrepを使用

```bash
# 問題
ps aux | grep -v grep | grep myprocess

# 解決策
pgrep -f myprocess
```

## パフォーマンス最適化

### 複数のファイルをチェック

```bash
#!/bin/bash

# シーケンシャルチェック
for script in *.sh; do
    shellcheck "$script"
done

# 並列チェック（より速い）
find . -name "*.sh" -print0 | \
    xargs -0 -P 4 -n 1 shellcheck
```

### 結果のキャッシング

```bash
#!/bin/bash

CACHE_DIR=".shellcheck_cache"
mkdir -p "$CACHE_DIR"

check_script() {
    local script="$1"
    local hash
    local cache_file

    hash=$(sha256sum "$script" | cut -d' ' -f1)
    cache_file="$CACHE_DIR/$hash"

    if [[ ! -f "$cache_file" ]]; then
        if shellcheck "$script" > "$cache_file" 2>&1; then
            touch "$cache_file.ok"
        else
            return 1
        fi
    fi

    [[ -f "$cache_file.ok" ]]
}

find . -name "*.sh" | while read -r script; do
    check_script "$script" || exit 1
done
```

## 出力形式

### デフォルト形式

```bash
shellcheck script.sh

# 出力:
# script.sh:1:3: warning: foo is referenced but not assigned. [SC2154]
```

### GCC形式（CI/CD用）

```bash
shellcheck --format=gcc script.sh

# 出力:
# script.sh:1:3: warning: foo is referenced but not assigned.
```

### JSON形式（解析用）

```bash
shellcheck --format=json script.sh

# 出力:
# [{"file": "script.sh", "line": 1, "column": 3, "level": "warning", "code": 2154, "message": "..."}]
```

### Quiet形式

```bash
shellcheck --format=quiet script.sh

# 問題が見つかった場合は非ゼロを返す、それ以外は出力なし
```

## ベストプラクティス

1. **CI/CDでShellCheckを実行** - マージ前に問題を捕捉
2. **ターゲットシェル用に設定** - bashをshとして分析しない
3. **除外を文書化** - 違反が抑制される理由を説明
4. **違反に対処** - 単に警告を無効にしない
5. **厳格モードを有効化** - 慎重な除外で`--enable=all`を使用
6. **定期的に更新** - 新しいチェックのためShellCheckを最新に保つ
7. **pre-commitフックを使用** - プッシュ前にローカルで問題を捕捉
8. **エディタと統合** - 開発中にリアルタイムフィードバックを取得

## リソース

- **ShellCheck GitHub**: https://github.com/koalaman/shellcheck
- **ShellCheck Wiki**: https://www.shellcheck.net/wiki/
- **エラーコードリファレンス**: https://www.shellcheck.net/
