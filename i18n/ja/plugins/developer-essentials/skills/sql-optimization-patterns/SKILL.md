---
name: sql-optimization-patterns
description: SQLクエリ最適化、インデックス戦略、EXPLAIN分析をマスターし、データベースパフォーマンスを劇的に向上させ、遅いクエリを排除。遅いクエリのデバッグ、データベーススキーマの設計、アプリケーションパフォーマンスの最適化時に使用。
---

> **[English](../../../../../../plugins/developer-essentials/skills/sql-optimization-patterns/SKILL.md)** | **日本語**

# SQL最適化パターン

体系的な最適化、適切なインデックス作成、クエリプラン分析を通じて、遅いデータベースクエリを超高速操作に変革します。

## このスキルを使用するタイミング

- 遅い実行クエリのデバッグ
- パフォーマンスの高いデータベーススキーマの設計
- アプリケーション応答時間の最適化
- データベース負荷とコストの削減
- 増加するデータセットのスケーラビリティ向上
- EXPLAINクエリプランの分析
- 効率的なインデックスの実装
- N+1クエリ問題の解決

## コア概念

### 1. クエリ実行プラン（EXPLAIN）

EXPLAIN出力の理解は最適化の基本です。

**PostgreSQL EXPLAIN：**
```sql
-- 基本的なexplain
EXPLAIN SELECT * FROM users WHERE email = 'user@example.com';

-- 実際の実行統計付き
EXPLAIN ANALYZE
SELECT * FROM users WHERE email = 'user@example.com';

-- より詳細な冗長出力
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT u.*, o.order_total
FROM users u
JOIN orders o ON u.id = o.user_id
WHERE u.created_at > NOW() - INTERVAL '30 days';
```

**注視すべき主要メトリクス：**
- **Seq Scan**：フルテーブルスキャン（大きなテーブルでは通常遅い）
- **Index Scan**：インデックスを使用（良い）
- **Index Only Scan**：テーブルに触れずにインデックスを使用（最良）
- **Nested Loop**：結合方法（小さなデータセットには問題なし）
- **Hash Join**：結合方法（大きなデータセットに良い）
- **Merge Join**：結合方法（ソート済みデータに良い）
- **Cost**：推定クエリコスト（低いほど良い）
- **Rows**：推定返却行数
- **Actual Time**：実際の実行時間

### 2. インデックス戦略

インデックスは最も強力な最適化ツールです。

**インデックスタイプ：**
- **B-Tree**：デフォルト、等価性と範囲クエリに良い
- **Hash**：等価性（=）比較のみ
- **GIN**：全文検索、配列クエリ、JSONB
- **GiST**：幾何データ、全文検索
- **BRIN**：相関のある非常に大きなテーブル用のブロック範囲インデックス

```sql
-- 標準B-Treeインデックス
CREATE INDEX idx_users_email ON users(email);

-- 複合インデックス（順序が重要！）
CREATE INDEX idx_orders_user_status ON orders(user_id, status);

-- 部分インデックス（行のサブセットをインデックス化）
CREATE INDEX idx_active_users ON users(email)
WHERE status = 'active';

-- 式インデックス
CREATE INDEX idx_users_lower_email ON users(LOWER(email));

-- カバリングインデックス（追加カラムを含む）
CREATE INDEX idx_users_email_covering ON users(email)
INCLUDE (name, created_at);

-- 全文検索インデックス
CREATE INDEX idx_posts_search ON posts
USING GIN(to_tsvector('english', title || ' ' || body));

-- JSONBインデックス
CREATE INDEX idx_metadata ON events USING GIN(metadata);
```

### 3. クエリ最適化パターン

**SELECT \* を避ける：**
```sql
-- 悪い例：不要なカラムを取得
SELECT * FROM users WHERE id = 123;

-- 良い例：必要なものだけを取得
SELECT id, email, name FROM users WHERE id = 123;
```

**WHERE句を効率的に使用：**
```sql
-- 悪い例：関数がインデックス使用を妨げる
SELECT * FROM users WHERE LOWER(email) = 'user@example.com';

-- 良い例：関数インデックスを作成するか正確な一致を使用
CREATE INDEX idx_users_email_lower ON users(LOWER(email));
-- その後：
SELECT * FROM users WHERE LOWER(email) = 'user@example.com';

-- または正規化されたデータを保存
SELECT * FROM users WHERE email = 'user@example.com';
```

**JOINを最適化：**
```sql
-- 悪い例：デカルト積の後にフィルター
SELECT u.name, o.total
FROM users u, orders o
WHERE u.id = o.user_id AND u.created_at > '2024-01-01';

-- 良い例：結合前にフィルター
SELECT u.name, o.total
FROM users u
JOIN orders o ON u.id = o.user_id
WHERE u.created_at > '2024-01-01';

-- より良い例：両方のテーブルをフィルター
SELECT u.name, o.total
FROM (SELECT * FROM users WHERE created_at > '2024-01-01') u
JOIN orders o ON u.id = o.user_id;
```

## 最適化パターン

### パターン1：N+1クエリの排除

**問題：N+1クエリアンチパターン**
```python
# 悪い例：N+1クエリを実行
users = db.query(\"SELECT * FROM users LIMIT 10\")
for user in users:
    orders = db.query(\"SELECT * FROM orders WHERE user_id = ?\", user.id)
    # 注文を処理
```

**解決策：JOINまたはバッチロードを使用**
```sql
-- 解決策1：JOIN
SELECT
    u.id, u.name,
    o.id as order_id, o.total
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
WHERE u.id IN (1, 2, 3, 4, 5);

-- 解決策2：バッチクエリ
SELECT * FROM orders
WHERE user_id IN (1, 2, 3, 4, 5);
```

```python
# 良い例：JOINまたはバッチロードで単一クエリ
# JOINを使用
results = db.query(\"\"\"
    SELECT u.id, u.name, o.id as order_id, o.total
    FROM users u
    LEFT JOIN orders o ON u.id = o.user_id
    WHERE u.id IN (1, 2, 3, 4, 5)
\"\"\")

# またはバッチロード
users = db.query(\"SELECT * FROM users LIMIT 10\")
user_ids = [u.id for u in users]
orders = db.query(
    \"SELECT * FROM orders WHERE user_id IN (?)\",
    user_ids
)
# user_idで注文をグループ化
orders_by_user = {}
for order in orders:
    orders_by_user.setdefault(order.user_id, []).append(order)
```

### パターン2：ページネーションの最適化

**悪い例：大きなテーブルでのOFFSET**
```sql
-- 大きなオフセットでは遅い
SELECT * FROM users
ORDER BY created_at DESC
LIMIT 20 OFFSET 100000;  -- 非常に遅い！
```

**良い例：カーソルベースのページネーション**
```sql
-- はるかに高速：カーソル（最後に見たID）を使用
SELECT * FROM users
WHERE created_at < '2024-01-15 10:30:00'  -- 最後のカーソル
ORDER BY created_at DESC
LIMIT 20;

-- 複合ソートで
SELECT * FROM users
WHERE (created_at, id) < ('2024-01-15 10:30:00', 12345)
ORDER BY created_at DESC, id DESC
LIMIT 20;

-- インデックスが必要
CREATE INDEX idx_users_cursor ON users(created_at DESC, id DESC);
```

### パターン3：効率的な集約

**COUNTクエリの最適化：**
```sql
-- 悪い例：すべての行をカウント
SELECT COUNT(*) FROM orders;  -- 大きなテーブルでは遅い

-- 良い例：概算カウントに推定値を使用
SELECT reltuples::bigint AS estimate
FROM pg_class
WHERE relname = 'orders';

-- 良い例：カウント前にフィルター
SELECT COUNT(*) FROM orders
WHERE created_at > NOW() - INTERVAL '7 days';

-- より良い例：インデックスのみスキャンを使用
CREATE INDEX idx_orders_created ON orders(created_at);
SELECT COUNT(*) FROM orders
WHERE created_at > NOW() - INTERVAL '7 days';
```

**GROUP BYの最適化：**
```sql
-- 悪い例：グループ化してからフィルター
SELECT user_id, COUNT(*) as order_count
FROM orders
GROUP BY user_id
HAVING COUNT(*) > 10;

-- より良い例：まずフィルター、その後グループ化（可能な場合）
SELECT user_id, COUNT(*) as order_count
FROM orders
WHERE status = 'completed'
GROUP BY user_id
HAVING COUNT(*) > 10;

-- 最良の例：カバリングインデックスを使用
CREATE INDEX idx_orders_user_status ON orders(user_id, status);
```

### パターン4：サブクエリ最適化

**相関サブクエリの変換：**
```sql
-- 悪い例：相関サブクエリ（各行で実行）
SELECT u.name, u.email,
    (SELECT COUNT(*) FROM orders o WHERE o.user_id = u.id) as order_count
FROM users u;

-- 良い例：集約付きJOIN
SELECT u.name, u.email, COUNT(o.id) as order_count
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
GROUP BY u.id, u.name, u.email;

-- より良い例：ウィンドウ関数を使用
SELECT DISTINCT ON (u.id)
    u.name, u.email,
    COUNT(o.id) OVER (PARTITION BY u.id) as order_count
FROM users u
LEFT JOIN orders o ON o.user_id = u.id;
```

**明確性のためのCTE使用：**
```sql
-- 共通テーブル式の使用
WITH recent_users AS (
    SELECT id, name, email
    FROM users
    WHERE created_at > NOW() - INTERVAL '30 days'
),
user_order_counts AS (
    SELECT user_id, COUNT(*) as order_count
    FROM orders
    WHERE created_at > NOW() - INTERVAL '30 days'
    GROUP BY user_id
)
SELECT ru.name, ru.email, COALESCE(uoc.order_count, 0) as orders
FROM recent_users ru
LEFT JOIN user_order_counts uoc ON ru.id = uoc.user_id;
```

### パターン5：バッチ操作

**バッチINSERT：**
```sql
-- 悪い例：複数の個別insert
INSERT INTO users (name, email) VALUES ('Alice', 'alice@example.com');
INSERT INTO users (name, email) VALUES ('Bob', 'bob@example.com');
INSERT INTO users (name, email) VALUES ('Carol', 'carol@example.com');

-- 良い例：バッチinsert
INSERT INTO users (name, email) VALUES
    ('Alice', 'alice@example.com'),
    ('Bob', 'bob@example.com'),
    ('Carol', 'carol@example.com');

-- より良い例：一括insertにCOPYを使用（PostgreSQL）
COPY users (name, email) FROM '/tmp/users.csv' CSV HEADER;
```

**バッチUPDATE：**
```sql
-- 悪い例：ループでupdate
UPDATE users SET status = 'active' WHERE id = 1;
UPDATE users SET status = 'active' WHERE id = 2;
-- ... 多数のIDで繰り返し

-- 良い例：IN句で単一UPDATE
UPDATE users
SET status = 'active'
WHERE id IN (1, 2, 3, 4, 5, ...);

-- より良い例：大きなバッチには一時テーブルを使用
CREATE TEMP TABLE temp_user_updates (id INT, new_status VARCHAR);
INSERT INTO temp_user_updates VALUES (1, 'active'), (2, 'active'), ...;

UPDATE users u
SET status = t.new_status
FROM temp_user_updates t
WHERE u.id = t.id;
```

## 高度なテクニック

### マテリアライズドビュー

高コストなクエリを事前計算。

```sql
-- マテリアライズドビューを作成
CREATE MATERIALIZED VIEW user_order_summary AS
SELECT
    u.id,
    u.name,
    COUNT(o.id) as total_orders,
    SUM(o.total) as total_spent,
    MAX(o.created_at) as last_order_date
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
GROUP BY u.id, u.name;

-- マテリアライズドビューにインデックスを追加
CREATE INDEX idx_user_summary_spent ON user_order_summary(total_spent DESC);

-- マテリアライズドビューを更新
REFRESH MATERIALIZED VIEW user_order_summary;

-- 並行更新（PostgreSQL）
REFRESH MATERIALIZED VIEW CONCURRENTLY user_order_summary;

-- マテリアライズドビューをクエリ（非常に高速）
SELECT * FROM user_order_summary
WHERE total_spent > 1000
ORDER BY total_spent DESC;
```

### パーティショニング

パフォーマンス向上のために大きなテーブルを分割。

```sql
-- 日付による範囲パーティショニング（PostgreSQL）
CREATE TABLE orders (
    id SERIAL,
    user_id INT,
    total DECIMAL,
    created_at TIMESTAMP
) PARTITION BY RANGE (created_at);

-- パーティションを作成
CREATE TABLE orders_2024_q1 PARTITION OF orders
    FOR VALUES FROM ('2024-01-01') TO ('2024-04-01');

CREATE TABLE orders_2024_q2 PARTITION OF orders
    FOR VALUES FROM ('2024-04-01') TO ('2024-07-01');

-- クエリは自動的に適切なパーティションを使用
SELECT * FROM orders
WHERE created_at BETWEEN '2024-02-01' AND '2024-02-28';
-- orders_2024_q1パーティションのみスキャン
```

### クエリヒントと最適化

```sql
-- インデックス使用を強制（MySQL）
SELECT * FROM users
USE INDEX (idx_users_email)
WHERE email = 'user@example.com';

-- 並列クエリ（PostgreSQL）
SET max_parallel_workers_per_gather = 4;
SELECT * FROM large_table WHERE condition;

-- 結合ヒント（PostgreSQL）
SET enable_nestloop = OFF;  -- ハッシュまたはマージ結合を強制
```

## ベストプラクティス

1. **選択的にインデックス作成**：インデックスが多すぎると書き込みが遅くなる
2. **クエリパフォーマンスを監視**：スロークエリログを使用
3. **統計を最新に保つ**：定期的にANALYZEを実行
4. **適切なデータ型を使用**：小さい型 = より良いパフォーマンス
5. **慎重に正規化**：正規化とパフォーマンスのバランス
6. **頻繁にアクセスされるデータをキャッシュ**：アプリケーションレベルのキャッシュを使用
7. **コネクションプーリング**：データベース接続を再利用
8. **定期メンテナンス**：VACUUM、ANALYZE、インデックス再構築

```sql
-- 統計を更新
ANALYZE users;
ANALYZE VERBOSE orders;

-- Vacuum（PostgreSQL）
VACUUM ANALYZE users;
VACUUM FULL users;  -- スペースを回収（テーブルをロック）

-- 再インデックス
REINDEX INDEX idx_users_email;
REINDEX TABLE users;
```

## よくある落とし穴

- **過剰なインデックス作成**：各インデックスがINSERT/UPDATE/DELETEを遅くする
- **未使用のインデックス**：スペースを無駄にし、書き込みを遅くする
- **インデックスの欠落**：遅いクエリ、フルテーブルスキャン
- **暗黙的な型変換**：インデックス使用を妨げる
- **OR条件**：インデックスを効率的に使用できない
- **先頭ワイルドカードのLIKE**：`LIKE '%abc'`はインデックスを使用できない
- **WHERE内の関数**：関数インデックスがない限りインデックス使用を妨げる

## クエリの監視

```sql
-- 遅いクエリを見つける（PostgreSQL）
SELECT query, calls, total_time, mean_time
FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 10;

-- 欠落しているインデックスを見つける（PostgreSQL）
SELECT
    schemaname,
    tablename,
    seq_scan,
    seq_tup_read,
    idx_scan,
    seq_tup_read / seq_scan AS avg_seq_tup_read
FROM pg_stat_user_tables
WHERE seq_scan > 0
ORDER BY seq_tup_read DESC
LIMIT 10;

-- 未使用のインデックスを見つける（PostgreSQL）
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
WHERE idx_scan = 0
ORDER BY pg_relation_size(indexrelid) DESC;
```

## リソース

- **references/postgres-optimization-guide.md**：PostgreSQL固有の最適化
- **references/mysql-optimization-guide.md**：MySQL/MariaDB最適化
- **references/query-plan-analysis.md**：EXPLAINプランの詳細
- **assets/index-strategy-checklist.md**：インデックスを作成するタイミングと方法
- **assets/query-optimization-checklist.md**：ステップバイステップ最適化ガイド
- **scripts/analyze-slow-queries.sql**：データベース内の遅いクエリを特定
- **scripts/index-recommendations.sql**：インデックス推奨を生成
