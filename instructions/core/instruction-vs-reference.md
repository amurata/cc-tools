---
title: インストラクション vs リファレンス - 明確な分離
description: AIへの指示と人間向け参考資料の区別
---

# カスタムインストラクション vs 実装リファレンス

## 🎭 根本的な違い

### カスタムインストラクション（AIへの指示）
**目的**: AIの思考を導く
**読者**: AI
**内容**: 原則、アプローチ、判断基準
**例**: `instructions/core/`, `instructions/methodologies/`

### 実装リファレンス（人間向け資料）
**目的**: 具体的な実装例を提供
**読者**: 人間の開発者
**内容**: コードサンプル、設定例、具体的手順
**例**: 現在の`instructions/patterns/`の大部分

## 📂 推奨ディレクトリ構造

```
ai-instructions/
├── instructions/          # AIへの指示（本来のカスタムインストラクション）
│   ├── core/             # 必須の基本原則
│   │   ├── base.md       # 絶対的な行動規範
│   │   └── thinking.md   # 思考プロセスの導き方
│   ├── methodologies/    # 問題解決アプローチ
│   │   ├── tdd.md        # TDDの思考フロー
│   │   └── analysis.md   # 分析の進め方
│   └── guidance/         # 判断支援
│       ├── quality.md    # 品質判断基準
│       └── tradeoffs.md  # トレードオフの考え方
│
├── references/           # 人間向けリファレンス（別管理推奨）
│   ├── frameworks/       # フレームワーク別実装例
│   ├── languages/        # 言語別イディオム
│   └── patterns/         # デザインパターン実装例
│
└── CLAUDE.md            # エントリーポイント（軽量化版）
```

## ✂️ 分離の実践例

### Before（混在している状態）
```markdown
# NestJS エンタープライズパターン

## 実装例
\`\`\`typescript
@Injectable()
export class UserService {
  constructor(private readonly repo: UserRepository) {}
  
  async findAll(): Promise<User[]> {
    return this.repo.find();
  }
}
\`\`\`
[さらに1000行のコード例...]
```

### After（適切に分離）

#### instructions/guidance/service-design.md
```markdown
# サービス層の設計思考

## 判断基準
サービスを設計する際の優先順位：
1. 単一責任 - 一つの明確な役割
2. テスト可能性 - 依存性の注入
3. 再利用性 - 汎用的なインターフェース

## アプローチ
- ビジネスロジックとインフラの分離を意識
- 必要以上に抽象化しない（YAGNI）
```

#### references/frameworks/nestjs/services.md（別プロジェクト推奨）
```markdown
# NestJS サービス実装例
[具体的なコード例をここに配置]
```

## 🔄 移行戦略

### Phase 1: 分類（1日）
- [ ] 既存ファイルを「指示」と「参考」に分類
- [ ] 本質的な指示を抽出

### Phase 2: 再構築（2日）
- [ ] instructions/に思考プロセスを再編
- [ ] references/に実装例を移動（または削除）

### Phase 3: 検証（1日）
- [ ] 創造性テスト実施
- [ ] 不要な制約の除去確認

## 🎯 判定基準

このコンテンツはどちらに属するか？

| 質問 | Yes → Instructions | No → References |
|------|-------------------|-----------------|
| AIの判断を助けるか？ | ✓ | |
| 未知の問題に応用可能か？ | ✓ | |
| 思考プロセスを示しているか？ | ✓ | |
| 特定の実装に依存しているか？ | | ✓ |
| コード例が主体か？ | | ✓ |

## 💡 重要な気づき

**カスタムインストラクションは少ないほど良い**
- 本当に必要な原則だけを残す
- 具体例は創造性を制限する
- AIは文脈から学習できる

**参考資料は別で管理すべき**
- 人間が必要な時に参照
- AIには渡さない
- 更新頻度も異なる

---

*このファイル自体もカスタムインストラクションとして機能することを意識して書かれている*