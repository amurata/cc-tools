# /spec-create

SPECドキュメントを作成する。タスク分割の前提となる仕様書を生成。

---

## 使い方

```
/spec-create {プロジェクト名または機能名}
```

## 実行内容

1. **ヒアリング**
   - プロジェクトの目的
   - 主要な機能要件
   - 技術的制約
   - 非機能要件

2. **SPEC生成**
   - テンプレートに基づいてSPEC文書を生成
   - 受け入れ条件を明確化
   - 技術スタック決定

3. **出力**
   - `docs/specs/{name}.md` にSPEC文書を作成

## オプション

- `--template`: カスタムテンプレートを指定
- `--output`: 出力先を指定

## 関連

- [spec-architect Agent](../agents/spec-architect.md)
- [SPECテンプレート](../templates/spec-template.md)

## 次のステップ

SPEC作成後は `/task-divide` でタスク分割を実行。
