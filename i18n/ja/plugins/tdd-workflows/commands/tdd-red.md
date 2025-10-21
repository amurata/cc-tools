---
description: TDDのレッド(失敗)フェーズの原則に従って、包括的な失敗するテストを記述します。
---

> **[English](../../../plugins/tdd-workflows/commands/tdd-red.md)** | **日本語**

TDDのレッド(失敗)フェーズの原則に従って、包括的な失敗するテストを記述します。

[拡張思考: test-automatorエージェントを使用して、期待される動作を適切に定義する失敗するテストを生成します。]

## 役割

Taskツールを使用し、subagent_type="unit-testing::test-automator"で失敗するテストを生成します。

## プロンプトテンプレート

"以下に対する包括的な失敗するテストを生成してください: $ARGUMENTS

## 中核要件

1. **テスト構造**
   - フレームワークに適したセットアップ(Jest/pytest/JUnit/Go/RSpec)
   - Arrange-Act-Assertパターン
   - should_X_when_Y命名規則
   - 相互依存のない独立したフィクスチャ

2. **動作カバレッジ**
   - ハッピーパスシナリオ
   - エッジケース(空、null、境界値)
   - エラーハンドリングと例外
   - 並行アクセス(該当する場合)

3. **失敗の検証**
   - テストは実行時に必ず失敗しなければならない
   - 正しい理由での失敗(構文エラーやインポートエラーではない)
   - 意味のある診断エラーメッセージ
   - カスケード失敗なし

4. **テストカテゴリ**
   - ユニット: 独立したコンポーネントの動作
   - インテグレーション: コンポーネント間の相互作用
   - コントラクト: API/インターフェースの契約
   - プロパティ: 数学的不変条件

## フレームワークパターン

**JavaScript/TypeScript (Jest/Vitest)**
- `vi.fn()`または`jest.fn()`で依存関係をモック化
- Reactコンポーネントには`@testing-library`を使用
- `fast-check`でプロパティテスト

**Python (pytest)**
- 適切なスコープのフィクスチャ
- 複数のテストケースにはParametrizeを使用
- プロパティベーステストにはHypothesisを使用

**Go**
- サブテストを使ったテーブル駆動テスト
- 並列実行には`t.Parallel()`
- よりクリーンなアサーションには`testify/assert`を使用

**Ruby (RSpec)**
- 遅延読み込みには`let`、即時読み込みには`let!`
- 異なるシナリオにはコンテキストを使用
- 共通の動作には共有サンプルを使用

## 品質チェックリスト

- 意図を文書化する読みやすいテスト名
- テストごとに1つの動作
- 実装の漏洩なし
- 意味のあるテストデータ('foo'/'bar'ではない)
- テストが生きたドキュメントとして機能

## 避けるべきアンチパターン

- すぐに成功するテスト
- 動作ではなく実装をテスト
- 複雑なセットアップコード
- テストごとに複数の責任
- 具体的な内容に依存した脆弱なテスト

## エッジケースのカテゴリ

- **Null/空**: undefined、null、空の文字列/配列/オブジェクト
- **境界**: 最小/最大値、単一要素、容量制限
- **特殊ケース**: Unicode、空白、特殊文字
- **状態**: 無効な遷移、同時変更
- **エラー**: ネットワーク障害、タイムアウト、権限

## 出力要件

- インポートを含む完全なテストファイル
- テストの目的の文書化
- 失敗を実行・検証するコマンド
- メトリクス: テスト数、カバレッジ領域
- グリーンフェーズへの次のステップ"

## 検証

生成後:
1. テストを実行 - 失敗することを確認
2. 有用な失敗メッセージを検証
3. テストの独立性をチェック
4. 包括的なカバレッジを確保

## 例(最小限)

```typescript
// auth.service.test.ts
describe('AuthService', () => {
  let authService: AuthService;
  let mockUserRepo: jest.Mocked<UserRepository>;

  beforeEach(() => {
    mockUserRepo = { findByEmail: jest.fn() } as any;
    authService = new AuthService(mockUserRepo);
  });

  it('should_return_token_when_valid_credentials', async () => {
    const user = { id: '1', email: 'test@example.com', passwordHash: 'hashed' };
    mockUserRepo.findByEmail.mockResolvedValue(user);

    const result = await authService.authenticate('test@example.com', 'pass');

    expect(result.success).toBe(true);
    expect(result.token).toBeDefined();
  });

  it('should_fail_when_user_not_found', async () => {
    mockUserRepo.findByEmail.mockResolvedValue(null);

    const result = await authService.authenticate('none@example.com', 'pass');

    expect(result.success).toBe(false);
    expect(result.error).toBe('INVALID_CREDENTIALS');
  });
});
```

テスト要件: $ARGUMENTS
