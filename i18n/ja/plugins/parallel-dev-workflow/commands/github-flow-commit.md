# /github-flow-commit

GitHub Flowに準拠したコミット・PR作成を支援。

---

## 使い方

```
/github-flow-commit [--type TYPE] [--scope SCOPE]
```

## 実行内容

### 1. 変更確認
```
変更ファイル:
  M src/services/auth.ts
  A src/services/auth.test.ts
  M package.json
```

### 2. コミットメッセージ生成
```
提案コミットメッセージ:

feat(auth): add authentication service

- Implement login/logout functionality
- Add JWT token handling
- Include unit tests

Refs: Task-003
```

### 3. コミット実行
```bash
git add .
git commit -m "feat(auth): add authentication service..."
```

### 4. PR作成（オプション）
```
PR作成しますか？ [y/N]
```

## コミットタイプ

| Type | 説明 |
|------|------|
| feat | 新機能 |
| fix | バグ修正 |
| docs | ドキュメント |
| style | フォーマット（機能変更なし） |
| refactor | リファクタリング |
| test | テスト追加・修正 |
| chore | ビルド・補助ツール |

## オプション

- `--type TYPE`: コミットタイプを指定
- `--scope SCOPE`: スコープを指定
- `--no-verify`: pre-commitフックをスキップ（非推奨）
- `--pr`: コミット後に自動でPR作成
- `--draft`: ドラフトPRとして作成

## コミットメッセージ形式

```
<type>(<scope>): <subject>

<body>

<footer>
```

### 例
```
feat(auth): implement JWT authentication

- Add JWT token generation and validation
- Implement refresh token rotation
- Add middleware for protected routes

Refs: Task-003
Breaking Change: Auth header format changed to Bearer
```

## PR作成

```
/github-flow-commit --pr
```

自動生成されるPR:
```
Title: feat(auth): implement JWT authentication

## 概要
認証機能を実装。

## 変更内容
- JWT認証の実装
- リフレッシュトークン対応
- 保護ルート用ミドルウェア

## テスト
- [ ] 単体テスト通過
- [ ] 統合テスト通過

## 関連
- Task-003
- Closes #12
```

## GitHub Flow遵守事項

1. **mainは常にデプロイ可能**
   - mainへの直接コミット禁止
   - PRを通じてのみマージ

2. **機能ブランチで開発**
   - `task/XXX_description` 形式
   - 小さく頻繁なコミット

3. **PRでレビュー**
   - CIチェック必須
   - レビュー承認後マージ

4. **マージ後すぐデプロイ可能**
   - 不完全な機能はマージしない
   - フィーチャーフラグで制御

## 関連

- [README - GitHub Flow](../README.md)

## 次のステップ

PR作成後、CIチェック通過を待ってマージ。
マージ後は `/completion-check` で最終確認。
