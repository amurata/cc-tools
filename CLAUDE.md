---
description: AI開発指示
alwaysApply: true
---

# AI開発指示

## 🎯 核心原則（必須読込）

### 品質基準
- **品質優先**: 速さより正確性と完全性
- **深層思考**: 表面的な理解を避け、本質を把握
- **価値提供**: 期待を超える成果を目指す

### 実行フロー
1. **分析** → 要求の本質を理解
2. **計画** → タスク分析・計画により最適なアプローチを選択
3. **実装** → 品質基準を満たす実行
4. **検証** → 結果の妥当性を確認
5. **忘却阻止** → この実行フローセクションを報告時に毎回1-5まで全て表示する

## 📚 必須参照

### コア指示（常時適用）
- [基本ルール](./instructions/core/base.md) - 絶対厳守事項
- [タスク分析・計画](./instructions/methodologies/task-analysis.md) - タスク実施前に必須

### 場面別指示（自動判断）
| 場面 | 参照ファイル | 適用条件 |
|------|------------|---------|
| Git操作 | [Git運用](./instructions/workflows/git-complete.md) | commit/PR/branch操作時 |
| TDD開発 | [TDD手法](./instructions/methodologies/tdd.md) | テスト駆動開発時 |
| デバッグ | [デバッグ思考](./instructions/core/debugging-thinking.md) | 問題調査・原因分析時 |
| 協働作業 | [協働インターフェース](./instructions/core/collaboration-interface.md) | 人間/AI間の情報交換時 |

## 🔧 ツール活用

### 優先順位
1. **専用ツール** → 利用可能なら最優先
2. **エージェント** → 複雑なタスクは適切に委任
3. **コマンド** → ツールがない場合のみ

### 記録管理
- 重要事項 → Issue/memoryに記録
- 作業記録 → [ノート形式](./instructions/note.md)で保存

## 📂 構造規約

```
project/
├── docs/          # ドキュメント集約
├── instructions/  # AI指示（このファイル群）
│   ├── core/     # 思考プロセス
│   ├── guidelines/ # 失敗防止ガイド
│   └── methodologies/ # 開発手法
├── references/    # 実装例（人間向け）
│   └── patterns/ # 具体的実装パターン
└── src/          # ソースコード
```

## 🎨 Kiro Spec-Driven Development

### 概要
Kiro仕様駆動開発システム - AI開発ライフサイクル（AI-DLC）における体系的な開発手法

### プロジェクト構成
- **ステアリング**: `.kiro/steering/` - プロジェクト全体のルールとコンテキスト
- **仕様**: `.kiro/specs/` - 個別機能の開発プロセスを形式化

### 基本ワークフロー
1. **Phase 0** (任意): ステアリング設定 (`/kiro:steering`)
2. **Phase 1** (仕様): 要件 → 設計 → タスク定義
3. **Phase 2** (実装): タスク実行と検証
4. **進捗確認**: `/kiro:spec-status {feature-name}`

### 開発原則
- 3フェーズ承認ワークフロー（要件 → 設計 → タスク → 実装）
- 各フェーズで人間のレビュー必須
- ステアリングを常に最新に保ち、`/kiro:spec-status`で整合性確認

詳細は [Kiro Spec-Driven Development](./docs/ai-dlc/kiro-spec-driven-development.md) を参照してください。


