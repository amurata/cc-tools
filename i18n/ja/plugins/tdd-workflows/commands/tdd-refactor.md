---
description: 包括的なテストのセーフティネットを使用して、自信を持ってコードをリファクタリングします。
---

> **[English](../../../plugins/tdd-workflows/commands/tdd-refactor.md)** | **日本語**

包括的なテストのセーフティネットを使用して、自信を持ってコードをリファクタリングします。

[拡張思考: このツールは、すべてのテストをグリーンに保ちながら洗練されたリファクタリングを行うために、tdd-orchestratorエージェント(opusモデル)を使用します。デザインパターンを適用し、コード品質を向上させ、包括的なテストカバレッジの安全性の下でパフォーマンスを最適化します。]

## 使用方法

Taskツールを使用し、subagent_type="tdd-orchestrator"で安全なリファクタリングを実行します。

プロンプト: "すべてのテストをグリーンに保ちながらこのコードをリファクタリングしてください: $ARGUMENTS。TDDリファクタフェーズを適用:

## コアプロセス

**1. 事前評価**
- テストを実行してグリーンベースラインを確立
- コードスメルとテストカバレッジを分析
- 現在のパフォーマンスメトリクスを文書化
- 段階的なリファクタリング計画を作成

**2. コードスメル検出**
- 重複コード → メソッド/クラスを抽出
- 長いメソッド → 集中した関数に分解
- 大きなクラス → 責任を分割
- 長いパラメータリスト → パラメータオブジェクト
- 機能の横恋慕 → 適切なクラスにメソッドを移動
- プリミティブ偏重 → 値オブジェクト
- Switch文 → ポリモーフィズム
- デッドコード → 削除

**3. デザインパターン**
- 生成パターンを適用(Factory、Builder、Singleton)
- 構造パターンを適用(Adapter、Facade、Decorator)
- 振る舞いパターンを適用(Strategy、Observer、Command)
- ドメインパターンを適用(Repository、Service、Value Objects)
- 明確な価値を追加する場合にのみパターンを使用

**4. SOLID原則**
- 単一責任原則: 変更する理由は1つ
- 開放閉鎖原則: 拡張には開き、修正には閉じる
- リスコフの置換原則: サブタイプは置換可能
- インターフェース分離原則: 小さく集中したインターフェース
- 依存性逆転原則: 抽象に依存

**5. リファクタリング技法**
- メソッド/変数/インターフェースの抽出
- 不要な間接化をインライン化
- 明確性のためのリネーム
- メソッド/フィールドを適切なクラスに移動
- マジックナンバーを定数に置き換え
- フィールドのカプセル化
- 条件分岐をポリモーフィズムに置き換え
- Nullオブジェクトの導入

**6. パフォーマンス最適化**
- プロファイリングでボトルネックを特定
- アルゴリズムとデータ構造を最適化
- 有益な場合はキャッシングを実装
- データベースクエリを削減(N+1問題の解消)
- 遅延ロードとページネーション
- 常に前後で測定

**7. 段階的ステップ**
- 小さく、原子的な変更を行う
- 各修正後にテストを実行
- 各成功したリファクタリング後にコミット
- リファクタリングを動作変更から分離
- 必要に応じて足場を使用

**8. アーキテクチャの進化**
- レイヤー分離と依存性管理
- モジュール境界とインターフェース定義
- 疎結合のためのイベント駆動パターン
- データベースアクセスパターンの最適化

**9. 安全性検証**
- 各変更後にフルテストスイートを実行
- パフォーマンス回帰テスト
- テスト有効性のためのミューテーションテスト
- 大規模変更のためのロールバック計画

**10. 高度なパターン**
- ストラングラーフィグ: 段階的なレガシー置換
- 抽象によるブランチング: 大規模変更
- 並列変更: 拡張-縮小パターン
- ミカドメソッド: 依存関係グラフのナビゲーション

## 出力要件

- 改善を適用したリファクタリング済みコード
- テスト結果(すべてグリーン)
- 前後のメトリクス比較
- 適用したリファクタリング技法のリスト
- パフォーマンス改善測定
- 残りの技術的負債評価

## 安全性チェックリスト

コミット前:
- ✓ すべてのテストが成功(100%グリーン)
- ✓ 機能の退行なし
- ✓ パフォーマンスメトリクスが許容範囲
- ✓ コードカバレッジが維持/改善
- ✓ ドキュメントが更新

## リカバリプロトコル

テストが失敗した場合:
- 最後の変更を即座に元に戻す
- 破壊的なリファクタリングを特定
- より小さな段階的変更を適用
- 安全な実験のためにバージョン管理を使用

## 例: メソッド抽出パターン

**リファクタリング前:**
```typescript
class OrderProcessor {
  processOrder(order: Order): ProcessResult {
    // 検証
    if (!order.customerId || order.items.length === 0) {
      return { success: false, error: "Invalid order" };
    }

    // 合計計算
    let subtotal = 0;
    for (const item of order.items) {
      subtotal += item.price * item.quantity;
    }
    let total = subtotal + (subtotal * 0.08) + (subtotal > 100 ? 0 : 15);

    // 支払い処理...
    // 在庫更新...
    // 確認送信...
  }
}
```

**リファクタリング後:**
```typescript
class OrderProcessor {
  async processOrder(order: Order): Promise<ProcessResult> {
    const validation = this.validateOrder(order);
    if (!validation.isValid) return ProcessResult.failure(validation.error);

    const orderTotal = OrderTotal.calculate(order);
    const inventoryCheck = await this.inventoryService.checkAvailability(order.items);
    if (!inventoryCheck.available) return ProcessResult.failure(inventoryCheck.reason);

    await this.paymentService.processPayment(order.paymentMethod, orderTotal.total);
    await this.inventoryService.reserveItems(order.items);
    await this.notificationService.sendOrderConfirmation(order, orderTotal);

    return ProcessResult.success(order.id, orderTotal.total);
  }

  private validateOrder(order: Order): ValidationResult {
    if (!order.customerId) return ValidationResult.invalid("Customer ID required");
    if (order.items.length === 0) return ValidationResult.invalid("Order must contain items");
    return ValidationResult.valid();
  }
}
```

**適用した技法:** メソッド抽出、値オブジェクト、依存性注入、非同期パターン

リファクタリングするコード: $ARGUMENTS"
