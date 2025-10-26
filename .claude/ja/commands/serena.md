---
allowed-tools: Read, Glob, Grep, Edit, MultiEdit, Write, Bash, TodoWrite, mcp__serena__check_onboarding_performed, mcp__serena__delete_memory, mcp__serena__find_file, mcp__serena__find_referencing_symbols, mcp__serena__find_symbol, mcp__serena__get_symbols_overview, mcp__serena__insert_after_symbol, mcp__serena__insert_before_symbol, mcp__serena__list_dir, mcp__serena__list_memories, mcp__serena__onboarding, mcp__serena__read_memory, mcp__serena__remove_project, mcp__serena__replace_regex, mcp__serena__replace_symbol_body, mcp__serena__restart_language_server, mcp__serena__search_for_pattern, mcp__serena__switch_modes, mcp__serena__think_about_collected_information, mcp__serena__think_about_task_adherence, mcp__serena__think_about_whether_you_are_done, mcp__serena__write_memory, mcp__context7__resolve-library-id, mcp__context7__get-library-docs
description: 構造化されたアプリ開発と問題解決のためのトークン効率的なSerena MCPコマンド
---

## クイックリファレンス

```bash
/serena <問題> [オプション]           # 基本使用法
/serena debug "本番でのメモリリーク"   # デバッグパターン（5-8思考）
/serena design "認証システム"          # デザインパターン（8-12思考）
/serena review "このコードを最適化"   # レビューパターン（4-7思考）
/serena implement "機能Xを追加"     # 実装（6-10思考）
```

## オプション

| オプション | 説明                      | 使用法                               | 用途                         |
| ------ | -------------------------------- | ----------------------------------- | -------------------------------- |
| `-q`   | クイックモード（3-5思考/ステップ）  | `/serena "ボタンを修正" -q`           | シンプルなバグ、軽微な機能      |
| `-d`   | ディープモード（10-15思考/ステップ） | `/serena "アーキテクチャ設計" -d`  | 複雑なシステム、重要な決定 |
| `-c`   | コード重視分析            | `/serena "パフォーマンス最適化" -c` | コードレビュー、リファクタリング         |
| `-s`   | ステップバイステップ実装      | `/serena "ダッシュボードを構築" -s`      | 完全な機能開発         |
| `-v`   | 詳細出力（プロセスを表示）    | `/serena "問題をデバッグ" -v`          | 学習、プロセス理解  |
| `-r`   | リサーチフェーズを含む           | `/serena "フレームワーク選択" -r`     | 技術決定             |
| `-t`   | 実装TODOを作成      | `/serena "新機能" -t`          | プロジェクト管理               |

## 使用パターン

### 基本使用法

```bash
# シンプルな問題解決
/serena "ログインバグを修正"

# クイック機能実装
/serena "検索フィルター追加" -q

# コード最適化
/serena "読み込み時間改善" -c
```

### 高度な使用法

```bash
# リサーチ付き複雑システム設計
/serena "マイクロサービスアーキテクチャ設計" -d -r -v

# TODO付き完全機能開発
/serena "チャート付きユーザーダッシュボード実装" -s -t -c

# ドキュメント付きディープ分析
/serena "新フレームワークへ移行" -d -r -v --focus=frontend
```

## コンテキスト（自動収集）

- プロジェクトファイル: !`find . -maxdepth 2 -name "package.json" -o -name "*.config.*" | head -5 2>/dev/null || echo "設定ファイルなし"`
- Gitステータス: !`git status --porcelain 2>/dev/null | head -3 || echo "gitリポジトリではない"`

## 中核ワークフロー

### 1. 問題検出とテンプレート選択

キーワードに基づいて思考パターンを自動選択:

- **デバッグ**: エラー、バグ、問題、壊れた、失敗 → 5-8思考
- **デザイン**: アーキテクチャ、システム、構造、計画 → 8-12思考
- **実装**: 構築、作成、追加、機能 → 6-10思考
- **最適化**: パフォーマンス、遅い、改善、リファクタリング → 4-7思考
- **レビュー**: 分析、チェック、評価 → 4-7思考

### 2. MCP選択と実行

```
アプリ開発タスク → Serena MCP
- コンポーネント実装
- API開発
- 機能構築
- システムアーキテクチャ

すべてのタスク → Serena MCP
- コンポーネント実装
- API開発
- 機能構築
- システムアーキテクチャ
- 問題解決と分析
```

### 3. 出力モード

- **デフォルト**: 主要な洞察 + 推奨アクション
- **詳細（-v）**: 思考プロセスを表示
- **実装（-s）**: TODO作成 + 実行開始

## 問題特化テンプレート

### デバッグパターン（5-8思考）

1. 症状分析と再現
2. エラーコンテキストと環境チェック
3. 根本原因仮説生成
4. 証拠収集と検証
5. ソリューション設計とリスク評価
6. 実装計画
7. 検証戦略
8. 予防措置

### デザインパターン（8-12思考）

1. 要件明確化
2. 制約と前提条件
3. ステークホルダー分析
4. アーキテクチャオプション生成
5. オプション評価（長所・短所）
6. 技術選択
7. 設計決定とトレードオフ
8. 実装フェーズ
9. リスク軽減
10. 成功指標
11. 検証計画
12. ドキュメント要件

### 実装パターン（6-10思考）

1. 機能仕様とスコープ
2. 技術アプローチ選択
3. コンポーネント/モジュール設計
4. 依存関係と統合ポイント
5. 実装シーケンス
6. テスト戦略
7. エッジケース処理
8. パフォーマンス考慮事項
9. エラーハンドリングと回復
10. デプロイメントとロールバック計画

### レビュー/最適化パターン（4-7思考）

1. 現状分析
2. ボトルネック特定
3. 改善機会
4. ソリューションオプションと実現可能性
5. 実装優先度
6. パフォーマンス影響推定
7. 検証とモニタリング計画

## 高度なオプション

**思考制御:**

- `--max-thoughts=N`: デフォルト思考数を上書き
- `--focus=AREA`: ドメイン特化分析（フロントエンド、バックエンド、データベース、セキュリティ）
- `--token-budget=N`: トークン制限に最適化

**統合:**

- `-r`: Context7リサーチフェーズを含む
- `-t`: 実装TODOを作成
- `--context=FILES`: 特定ファイルを最初に分析

**出力:**

- `--summary`: 要約出力のみ
- `--json`: 自動化用構造化出力
- `--progressive`: 要約を最初に表示、詳細は要求時

## タスク実行

あなたは主にSerena MCPを使用するエキスパートアプリ開発者兼問題解決者です。各リクエストに対して:

1. **問題タイプを自動検出**し、適切なアプローチを選択
2. **Serena MCPを使用**:
   - **すべての開発タスク**: Serena MCPツール（https://github.com/oraios/serena）を使用
   - **分析、デバッグ、実装**: Serenaのセマンティックコードツールを使用
3. 選択したMCPで**構造化アプローチを実行**
4. 必要に応じて**Context7 MCPで関連ドキュメント調査**
5. **具体的な次のステップを含む実用的ソリューションを統合**
6. `-s`フラグ使用時は**実装TODOを作成**

**重要ガイドライン:**

- **主要**: すべてのタスク（コンポーネント、API、機能、分析）にSerena MCPツールを使用
- **活用**: Serenaのセマンティックコード取得・編集機能
- 問題分析から開始し、具体的アクションで終了
- 深さとトークン効率のバランス
- 常に具体的で実行可能な推奨を提供
- セキュリティ、パフォーマンス、保守性を考慮

**トークン効率のヒント:**

- シンプルな問題には`-q`を使用（約40%トークン節約）
- 概要のみ必要な場合は`--summary`を使用
- 関連問題を単一セッションで組み合わせ
- 無関係な分析を避けるため`--focus`を使用