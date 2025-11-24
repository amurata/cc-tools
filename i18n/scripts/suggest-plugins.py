#!/usr/bin/env python3
import json
import os
import sys
import re

# カラーコード
GREEN = '\033[0;32m'
YELLOW = '\033[1;33m'
BLUE = '\033[0;34m'
BOLD = '\033[1m'
NC = '\033[0m'

def load_plugins():
    """プラグイン定義ファイルを読み込む"""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    # 日本語版のmarketplace.jsonを探す
    marketplace_path = os.path.join(script_dir, '../ja/.claude-plugin/marketplace.json')
    
    if not os.path.exists(marketplace_path):
        print(f"{re.RED}エラー: marketplace.json が見つかりません: {marketplace_path}{NC}")
        sys.exit(1)
        
    try:
        with open(marketplace_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
            return data.get('plugins', [])
    except Exception as e:
        print(f"{re.RED}エラー: JSONの読み込みに失敗しました: {e}{NC}")
        sys.exit(1)

def search_plugins(plugins, query):
    """クエリに基づいてプラグインを検索する"""
    query = query.lower()
    results = []
    
    for plugin in plugins:
        score = 0
        name = plugin.get('name', '').lower()
        description = plugin.get('description', '').lower()
        keywords = [k.lower() for k in plugin.get('keywords', [])]
        category = plugin.get('category', '').lower()
        
        # スコアリングロジック
        if query in name:
            score += 10
        if query in description:
            score += 5
        if query in category:
            score += 5
        for keyword in keywords:
            if query in keyword:
                score += 3
                
        # 複数単語のクエリ対応（簡易的）
        query_words = query.split()
        if len(query_words) > 1:
            match_count = 0
            for word in query_words:
                if word in name or word in description or any(word in k for k in keywords):
                    match_count += 1
            if match_count == len(query_words):
                score += 5
        
        if score > 0:
            results.append((score, plugin))
            
    # スコア順にソート
    results.sort(key=lambda x: x[0], reverse=True)
    return [r[1] for r in results]

def print_plugin(plugin):
    """プラグイン情報を表示する"""
    name = plugin.get('name')
    description = plugin.get('description')
    category = plugin.get('category')
    
    print(f"{BOLD}{GREEN}📦 {name}{NC} ({category})")
    print(f"   {description}")
    print(f"   {BLUE}インストールコマンド:{NC} /plugin install {name}")
    print("")

def main():
    print(f"{BOLD}🔍 Claude Code プラグイン検索ツール{NC}")
    print("やりたいことやキーワードを入力してください（終了するには 'exit' または 'q'）")
    print("-" * 50)
    
    plugins = load_plugins()
    print(f"読み込み完了: {len(plugins)} 個のプラグイン")
    
    while True:
        try:
            query = input(f"\n{YELLOW}検索キーワード > {NC}").strip()
        except KeyboardInterrupt:
            print("\n終了します")
            break
            
        if query.lower() in ('exit', 'q', 'quit'):
            break
            
        if not query:
            continue
            
        results = search_plugins(plugins, query)
        
        if results:
            print(f"\n{len(results)} 件見つかりました:\n")
            for plugin in results:
                print_plugin(plugin)
        else:
            print(f"\n{re.RED}該当するプラグインが見つかりませんでした。別のキーワードを試してください。{NC}")
            print("ヒント: 'python', 'test', 'debug', 'git' などの単語で検索してみてください")

if __name__ == "__main__":
    # カラーコード用（Windows対応など簡易的）
    if os.name == 'nt':
        os.system('color')
        
    # reモジュールがインポートされていない場合のフォールバック（実際には冒頭でインポート済み）
    class re_mock:
        RED = '\033[0;31m'
    re = re_mock
    
    main()
