---
name: debugging-strategies
description: 体系的なデバッグ技術、プロファイリングツール、根本原因分析をマスターし、あらゆるコードベースや技術スタックでバグを効率的に追跡。バグ調査、パフォーマンス問題、予期しない動作の調査時に使用。
---

> **[English](../../../../../../plugins/developer-essentials/skills/debugging-strategies/SKILL.md)** | **日本語**

# デバッグ戦略

実証済みの戦略、強力なツール、体系的なアプローチで、デバッグをイライラする当てずっぽうから体系的な問題解決へと変革します。

## このスキルを使用するタイミング

- とらえどころのないバグの追跡
- パフォーマンス問題の調査
- 不慣れなコードベースの理解
- 本番環境の問題のデバッグ
- クラッシュダンプとスタックトレースの分析
- アプリケーションパフォーマンスのプロファイリング
- メモリリークの調査
- 分散システムのデバッグ

## コア原則

### 1. 科学的手法

**1. 観察**：実際の動作は何か？
**2. 仮説**：何が原因の可能性があるか？
**3. 実験**：仮説をテスト
**4. 分析**：理論が証明/反証されたか？
**5. 繰り返し**：根本原因を見つけるまで

### 2. デバッグマインドセット

**思い込まないこと：**
- 「Xのはずがない」 - いや、可能性はある
- 「Yは変更していない」 - とにかく確認
- 「自分の環境では動く」 - なぜかを調べる

**すべきこと：**
- 一貫して再現
- 問題を分離
- 詳細なメモを取る
- すべてに疑問を持つ
- 詰まったら休憩

### 3. ラバーダックデバッグ

コードと問題を声に出して説明する（ラバーダック、同僚、または自分自身に）。多くの場合、問題が明らかになります。

## 体系的デバッグプロセス

### フェーズ1：再現

```markdown
## 再現チェックリスト

1. **再現できるか？**
   - 常に？時々？ランダムに？
   - 特定の条件が必要？
   - 他の人も再現できる？

2. **最小限の再現ケースを作成**
   - 最小の例に簡素化
   - 無関係なコードを削除
   - 問題を分離

3. **手順を文書化**
   - 正確な手順を書き留める
   - 環境の詳細を記録
   - エラーメッセージをキャプチャ
```

### フェーズ2：情報収集

```markdown
## 情報収集

1. **エラーメッセージ**
   - 完全なスタックトレース
   - エラーコード
   - コンソール/ログ出力

2. **環境**
   - OSバージョン
   - 言語/ランタイムバージョン
   - 依存関係のバージョン
   - 環境変数

3. **最近の変更**
   - Git履歴
   - デプロイメントタイムライン
   - 設定変更

4. **範囲**
   - すべてのユーザーに影響？特定のユーザーのみ？
   - すべてのブラウザ？特定のブラウザのみ？
   - 本番環境のみ？開発環境でも？
```

### フェーズ3：仮説形成

```markdown
## 仮説形成

収集した情報に基づいて質問：

1. **何が変わった？**
   - 最近のコード変更
   - 依存関係の更新
   - インフラの変更

2. **何が違う？**
   - 動作する環境 vs 壊れた環境
   - 動作するユーザー vs 壊れたユーザー
   - 変更前 vs 変更後

3. **どこで失敗する可能性がある？**
   - 入力検証
   - ビジネスロジック
   - データ層
   - 外部サービス
```

### フェーズ4：テストと検証

```markdown
## テスト戦略

1. **二分探索**
   - コードの半分をコメントアウト
   - 問題のあるセクションを絞り込む
   - 見つかるまで繰り返し

2. **ログ追加**
   - 戦略的なconsole.log/print
   - 変数値を追跡
   - 実行フローをトレース

3. **コンポーネントを分離**
   - 各部分を個別にテスト
   - 依存関係をモック
   - 複雑さを削減

4. **動作するものと壊れたものを比較**
   - 設定の差分
   - 環境の差分
   - データの差分
```

## デバッグツール

### JavaScript/TypeScriptデバッグ

```typescript
// Chrome DevTools デバッガー
function processOrder(order: Order) {
    debugger;  // ここで実行が一時停止

    const total = calculateTotal(order);
    console.log('合計:', total);

    // 条件付きブレークポイント
    if (order.items.length > 10) {
        debugger;  // 条件がtrueの場合のみ中断
    }

    return total;
}

// コンソールデバッグテクニック
console.log('値:', value);                       // 基本
console.table(arrayOfObjects);                   // テーブル形式
console.time('操作'); /* コード */ console.timeEnd('操作');  // タイミング
console.trace();                                 // スタックトレース
console.assert(value > 0, '値は正の数である必要があります');  // アサーション

// パフォーマンスプロファイリング
performance.mark('操作開始');
// ... 操作コード
performance.mark('操作終了');
performance.measure('操作', '操作開始', '操作終了');
console.log(performance.getEntriesByType('measure'));
```

**VS Code デバッガー設定：**
```json
// .vscode/launch.json
{
    "version": "0.2.0",
    "configurations": [
        {
            "type": "node",
            "request": "launch",
            "name": "プログラムをデバッグ",
            "program": "${workspaceFolder}/src/index.ts",
            "preLaunchTask": "tsc: build - tsconfig.json",
            "outFiles": ["${workspaceFolder}/dist/**/*.js"],
            "skipFiles": ["<node_internals>/**"]
        },
        {
            "type": "node",
            "request": "launch",
            "name": "テストをデバッグ",
            "program": "${workspaceFolder}/node_modules/jest/bin/jest",
            "args": ["--runInBand", "--no-cache"],
            "console": "integratedTerminal"
        }
    ]
}
```

### Pythonデバッグ

```python
# 組み込みデバッガー（pdb）
import pdb

def calculate_total(items):
    total = 0
    pdb.set_trace()  # デバッガーがここから開始

    for item in items:
        total += item.price * item.quantity

    return total

# ブレークポイント（Python 3.7+）
def process_order(order):
    breakpoint()  # pdb.set_trace()より便利
    # ... コード

# 事後デバッグ
try:
    risky_operation()
except Exception:
    import pdb
    pdb.post_mortem()  # 例外発生時点でデバッグ

# IPythonデバッグ（ipdb）
from ipdb import set_trace
set_trace()  # pdbより優れたインターフェース

# デバッグ用ログ記録
import logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

def fetch_user(user_id):
    logger.debug(f'ユーザー取得中: {user_id}')
    user = db.query(User).get(user_id)
    logger.debug(f'ユーザー発見: {user}')
    return user

# パフォーマンスプロファイル
import cProfile
import pstats

cProfile.run('slow_function()', 'profile_stats')
stats = pstats.Stats('profile_stats')
stats.sort_stats('cumulative')
stats.print_stats(10)  # 上位10個の遅い処理
```

### Goデバッグ

```go
// Delveデバッガー
// インストール: go install github.com/go-delve/delve/cmd/dlv@latest
// 実行: dlv debug main.go

import (
    "fmt"
    "runtime"
    "runtime/debug"
)

// スタックトレースを出力
func debugStack() {
    debug.PrintStack()
}

// デバッグ付きパニック回復
func processRequest() {
    defer func() {
        if r := recover(); r != nil {
            fmt.Println("パニック:", r)
            debug.PrintStack()
        }
    }()

    // ... パニックする可能性のあるコード
}

// メモリプロファイリング
import _ "net/http/pprof"
// http://localhost:6060/debug/pprof/ にアクセス

// CPUプロファイリング
import (
    "os"
    "runtime/pprof"
)

f, _ := os.Create("cpu.prof")
pprof.StartCPUProfile(f)
defer pprof.StopCPUProfile()
// ... プロファイル対象コード
```

## 高度なデバッグテクニック

### テクニック1：二分探索デバッグ

```bash
# リグレッションを見つけるためのGit bisect
git bisect start
git bisect bad                    # 現在のコミットは不良
git bisect good v1.0.0            # v1.0.0は正常だった

# Gitが中間のコミットをチェックアウト
# テストして、次に：
git bisect good   # 動作する場合
git bisect bad    # 壊れている場合

# バグが見つかるまで続ける
git bisect reset  # 完了時
```

### テクニック2：差分デバッグ

動作するものと壊れたものを比較：

```markdown
## 何が違う？

| 側面         | 動作する        | 壊れている      |
|--------------|-----------------|-----------------|
| 環境         | 開発環境        | 本番環境        |
| Nodeバージョン | 18.16.0       | 18.15.0         |
| データ       | 空のDB          | 100万レコード   |
| ユーザー     | 管理者          | 一般ユーザー    |
| ブラウザ     | Chrome          | Safari          |
| 時刻         | 日中            | 深夜以降        |

仮説：時刻ベースの問題？タイムゾーン処理を確認。
```

### テクニック3：トレースデバッグ

```typescript
// 関数呼び出しトレース
function trace(target: any, propertyKey: string, descriptor: PropertyDescriptor) {
    const originalMethod = descriptor.value;

    descriptor.value = function(...args: any[]) {
        console.log(`${propertyKey} を呼び出し中、引数:`, args);
        const result = originalMethod.apply(this, args);
        console.log(`${propertyKey} が返却:`, result);
        return result;
    };

    return descriptor;
}

class OrderService {
    @trace
    calculateTotal(items: Item[]): number {
        return items.reduce((sum, item) => sum + item.price, 0);
    }
}
```

### テクニック4：メモリリーク検出

```typescript
// Chrome DevTools メモリプロファイラー
// 1. ヒープスナップショットを取得
// 2. アクションを実行
// 3. もう一つスナップショットを取得
// 4. スナップショットを比較

// Node.jsメモリデバッグ
if (process.memoryUsage().heapUsed > 500 * 1024 * 1024) {
    console.warn('メモリ使用量が高い:', process.memoryUsage());

    // ヒープダンプを生成
    require('v8').writeHeapSnapshot();
}

// テストでメモリリークを発見
let beforeMemory: number;

beforeEach(() => {
    beforeMemory = process.memoryUsage().heapUsed;
});

afterEach(() => {
    const afterMemory = process.memoryUsage().heapUsed;
    const diff = afterMemory - beforeMemory;

    if (diff > 10 * 1024 * 1024) {  // 10MBの閾値
        console.warn(`メモリリーク可能性: ${diff / 1024 / 1024}MB`);
    }
});
```

## 問題タイプ別デバッグパターン

### パターン1：断続的なバグ

```markdown
## 不安定なバグの戦略

1. **広範なログ記録を追加**
   - タイミング情報をログ
   - すべての状態遷移をログ
   - 外部とのやり取りをログ

2. **競合状態を探す**
   - 共有状態への同時アクセス
   - 非同期操作の順不同完了
   - 同期の欠落

3. **タイミング依存性を確認**
   - setTimeout/setInterval
   - Promise解決順序
   - アニメーションフレームタイミング

4. **ストレステスト**
   - 何度も実行
   - タイミングを変える
   - 負荷をシミュレート
```

### パターン2：パフォーマンス問題

```markdown
## パフォーマンスデバッグ

1. **まずプロファイル**
   - 盲目的に最適化しない
   - 前後で測定
   - ボトルネックを見つける

2. **よくある原因**
   - N+1クエリ
   - 不要な再レンダリング
   - 大規模データ処理
   - 同期I/O

3. **ツール**
   - ブラウザDevToolsパフォーマンスタブ
   - Lighthouse
   - Python: cProfile, line_profiler
   - Node: clinic.js, 0x
```

### パターン3：本番環境のバグ

```markdown
## 本番環境デバッグ

1. **証拠を収集**
   - エラートラッキング（Sentry、Bugsnag）
   - アプリケーションログ
   - ユーザーレポート
   - メトリクス/監視

2. **ローカルで再現**
   - 本番データを使用（匿名化）
   - 環境を合わせる
   - 正確な手順に従う

3. **安全な調査**
   - 本番環境を変更しない
   - フィーチャーフラグを使用
   - 監視/ログ記録を追加
   - ステージングで修正をテスト
```

## ベストプラクティス

1. **まず再現**：再現できないものは修正できない
2. **問題を分離**：最小ケースまで複雑さを削除
3. **エラーメッセージを読む**：通常は役立つ
4. **最近の変更を確認**：ほとんどのバグは最近のもの
5. **バージョン管理を使用**：Git bisect、blame、履歴
6. **休憩を取る**：新鮮な目でよく見える
7. **発見を文書化**：将来の自分を助ける
8. **根本原因を修正**：症状だけでなく

## よくあるデバッグの間違い

- **複数の変更を同時に行う**：一度に一つずつ変更
- **エラーメッセージを読まない**：完全なスタックトレースを読む
- **複雑だと思い込む**：多くの場合シンプル
- **本番環境にデバッグログ**：出荷前に削除
- **デバッガーを使わない**：console.logが常に最善とは限らない
- **早々に諦める**：粘り強さが報われる
- **修正をテストしない**：実際に動作することを確認

## クイックデバッグチェックリスト

```markdown
## 詰まったときの確認事項：

- [ ] スペルミス（変数名のタイポ）
- [ ] 大文字小文字の区別（fileName vs filename）
- [ ] Null/undefined値
- [ ] 配列インデックスのオフバイワン
- [ ] 非同期タイミング（競合状態）
- [ ] スコープの問題（クロージャ、ホイスティング）
- [ ] 型の不一致
- [ ] 依存関係の欠落
- [ ] 環境変数
- [ ] ファイルパス（絶対 vs 相対）
- [ ] キャッシュ問題（キャッシュクリア）
- [ ] 古いデータ（データベース更新）
```

## リソース

- **references/debugging-tools-guide.md**：包括的なツールドキュメント
- **references/performance-profiling.md**：パフォーマンスデバッグガイド
- **references/production-debugging.md**：本番システムのデバッグ
- **assets/debugging-checklist.md**：クイックリファレンスチェックリスト
- **assets/common-bugs.md**：よくあるバグパターン
- **scripts/debug-helper.ts**：デバッグユーティリティ関数
