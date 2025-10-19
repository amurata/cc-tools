# Database Query Optimization

データベースクエリ最適化とパフォーマンスパターン。

## インデックス戦略

### インデックス設計
```sql
-- 単一カラムインデックス
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_posts_user_id ON posts(user_id);

-- 複合インデックス（順序重要）
CREATE INDEX idx_orders_user_date ON orders(user_id, created_at DESC);

-- 部分インデックス（条件付き）
CREATE INDEX idx_orders_pending ON orders(status) 
WHERE status = 'pending';

-- カバリングインデックス
CREATE INDEX idx_products_search ON products(category, name, price)
INCLUDE (description, stock);

-- 全文検索インデックス
CREATE INDEX idx_articles_search ON articles 
USING gin(to_tsvector('english', title || ' ' || content));
```

### インデックス使用状況の分析
```sql
-- PostgreSQL: 未使用インデックスの検出
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE idx_scan = 0
ORDER BY pg_relation_size(indexrelid) DESC;

-- MySQL: インデックス使用状況
SHOW INDEX FROM orders;
EXPLAIN SELECT * FROM orders WHERE user_id = 123;
```

## N+1問題の解決

### ORM での Eager Loading
```typescript
// ❌ N+1問題が発生
const posts = await db.post.findMany();
for (const post of posts) {
  const author = await db.user.findUnique({
    where: { id: post.authorId }
  });
  post.author = author;
}

// ✅ Eager Loading で解決
const posts = await db.post.findMany({
  include: {
    author: true,
    comments: {
      include: {
        user: true
      }
    },
    tags: true
  }
});

// Prisma の select で必要なフィールドのみ
const posts = await db.post.findMany({
  select: {
    id: true,
    title: true,
    author: {
      select: {
        name: true,
        email: true
      }
    }
  }
});
```

### データローダーパターン
```typescript
import DataLoader from 'dataloader';

// バッチ処理でN+1を回避
class UserLoader {
  private loader: DataLoader<string, User>;
  
  constructor() {
    this.loader = new DataLoader(async (userIds) => {
      const users = await db.user.findMany({
        where: { id: { in: userIds as string[] } }
      });
      
      // 順序を保持してマッピング
      const userMap = new Map(users.map(u => [u.id, u]));
      return userIds.map(id => userMap.get(id) || null);
    });
  }
  
  async load(userId: string): Promise<User | null> {
    return this.loader.load(userId);
  }
  
  async loadMany(userIds: string[]): Promise<(User | null)[]> {
    return this.loader.loadMany(userIds);
  }
}

// GraphQL リゾルバーでの使用
const resolvers = {
  Post: {
    author: (post, args, context) => {
      return context.userLoader.load(post.authorId);
    }
  }
};
```

## クエリ最適化テクニック

### SELECT最適化
```sql
-- ❌ 悪い例: SELECT *
SELECT * FROM users WHERE status = 'active';

-- ✅ 良い例: 必要なカラムのみ
SELECT id, name, email FROM users WHERE status = 'active';

-- ❌ 悪い例: サブクエリ
SELECT name, 
  (SELECT COUNT(*) FROM orders WHERE user_id = users.id) as order_count
FROM users;

-- ✅ 良い例: JOIN
SELECT u.name, COUNT(o.id) as order_count
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
GROUP BY u.id, u.name;
```

### JOIN最適化
```sql
-- 適切なJOIN順序（小さいテーブルから大きいテーブルへ）
SELECT o.*, u.name, p.name as product_name
FROM users u
INNER JOIN orders o ON o.user_id = u.id
INNER JOIN order_items oi ON oi.order_id = o.id
INNER JOIN products p ON p.id = oi.product_id
WHERE u.status = 'active'
  AND o.created_at >= '2024-01-01';

-- EXISTS vs IN（EXISTSの方が高速な場合が多い）
-- ✅ EXISTS使用
SELECT * FROM users u
WHERE EXISTS (
  SELECT 1 FROM orders o 
  WHERE o.user_id = u.id 
  AND o.status = 'completed'
);

-- ❌ IN使用（サブクエリが大きい場合は遅い）
SELECT * FROM users
WHERE id IN (
  SELECT user_id FROM orders WHERE status = 'completed'
);
```

## ページネーション戦略

### OFFSET vs Cursor
```typescript
// ❌ OFFSET（大きなオフセットで遅い）
const getPage = async (page: number, limit: number) => {
  return await db.product.findMany({
    skip: (page - 1) * limit,
    take: limit,
    orderBy: { createdAt: 'desc' }
  });
};

// ✅ Cursorベース（高速）
const getCursorPage = async (cursor?: string, limit: number = 20) => {
  const products = await db.product.findMany({
    take: limit + 1,
    cursor: cursor ? { id: cursor } : undefined,
    orderBy: { createdAt: 'desc' }
  });
  
  const hasMore = products.length > limit;
  const items = hasMore ? products.slice(0, -1) : products;
  const nextCursor = hasMore ? items[items.length - 1].id : null;
  
  return { items, nextCursor, hasMore };
};

// Keyset Pagination
const getKeysetPage = async (lastId?: string, lastDate?: Date) => {
  const where = lastId && lastDate ? {
    OR: [
      { createdAt: { lt: lastDate } },
      { createdAt: lastDate, id: { lt: lastId } }
    ]
  } : {};
  
  return await db.product.findMany({
    where,
    orderBy: [
      { createdAt: 'desc' },
      { id: 'desc' }
    ],
    take: 20
  });
};
```

## 集計クエリ最適化

### マテリアライズドビュー
```sql
-- PostgreSQL: マテリアライズドビュー作成
CREATE MATERIALIZED VIEW monthly_sales AS
SELECT 
    DATE_TRUNC('month', created_at) as month,
    product_id,
    COUNT(*) as total_orders,
    SUM(quantity) as total_quantity,
    SUM(price * quantity) as total_revenue
FROM orders o
JOIN order_items oi ON oi.order_id = o.id
GROUP BY DATE_TRUNC('month', created_at), product_id
WITH DATA;

-- インデックス作成
CREATE INDEX idx_monthly_sales_month ON monthly_sales(month);
CREATE INDEX idx_monthly_sales_product ON monthly_sales(product_id);

-- 定期的な更新
REFRESH MATERIALIZED VIEW CONCURRENTLY monthly_sales;
```

### 集計の事前計算
```typescript
// カウンターキャッシュ
class PostService {
  async addComment(postId: string, comment: Comment): Promise<void> {
    await db.$transaction([
      // コメント追加
      db.comment.create({
        data: { ...comment, postId }
      }),
      // カウンター更新
      db.post.update({
        where: { id: postId },
        data: { 
          commentCount: { increment: 1 },
          lastCommentAt: new Date()
        }
      })
    ]);
  }
}

// 定期的な集計バッチ
class AggregationService {
  async updateDailyStats(): Promise<void> {
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    yesterday.setHours(0, 0, 0, 0);
    
    const stats = await db.$queryRaw`
      INSERT INTO daily_stats (date, total_users, total_orders, revenue)
      SELECT 
        ${yesterday}::date,
        (SELECT COUNT(*) FROM users WHERE created_at < ${yesterday}),
        COUNT(o.id),
        SUM(o.total)
      FROM orders o
      WHERE o.created_at >= ${yesterday}
        AND o.created_at < ${yesterday}::date + INTERVAL '1 day'
      ON CONFLICT (date) DO UPDATE SET
        total_orders = EXCLUDED.total_orders,
        revenue = EXCLUDED.revenue;
    `;
  }
}
```

## データベース接続管理

### コネクションプール
```typescript
import { Pool } from 'pg';

const pool = new Pool({
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT!),
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  max: 20, // 最大接続数
  min: 5,  // 最小接続数
  idleTimeoutMillis: 30000, // アイドルタイムアウト
  connectionTimeoutMillis: 2000, // 接続タイムアウト
});

// 接続の再利用
export async function query(text: string, params?: any[]): Promise<any> {
  const start = Date.now();
  try {
    const res = await pool.query(text, params);
    const duration = Date.now() - start;
    console.log('Executed query', { text, duration, rows: res.rowCount });
    return res;
  } catch (error) {
    console.error('Database query error:', error);
    throw error;
  }
}

// グレースフルシャットダウン
process.on('SIGINT', async () => {
  await pool.end();
  process.exit(0);
});
```

### Read Replica の活用
```typescript
class DatabaseService {
  private primaryPool: Pool;
  private replicaPools: Pool[];
  private currentReplica = 0;
  
  constructor() {
    // プライマリDB
    this.primaryPool = new Pool({
      host: process.env.DB_PRIMARY_HOST,
      // ... 設定
    });
    
    // レプリカDB
    this.replicaPools = [
      new Pool({ host: process.env.DB_REPLICA1_HOST }),
      new Pool({ host: process.env.DB_REPLICA2_HOST })
    ];
  }
  
  // 書き込みはプライマリへ
  async write(query: string, params?: any[]): Promise<any> {
    return this.primaryPool.query(query, params);
  }
  
  // 読み込みはレプリカへ（ラウンドロビン）
  async read(query: string, params?: any[]): Promise<any> {
    const replica = this.replicaPools[this.currentReplica];
    this.currentReplica = (this.currentReplica + 1) % this.replicaPools.length;
    
    try {
      return await replica.query(query, params);
    } catch (error) {
      // フォールバック
      console.error('Replica error, falling back to primary:', error);
      return this.primaryPool.query(query, params);
    }
  }
}
```

## クエリ分析とモニタリング

### スロークエリログ
```typescript
// クエリパフォーマンス監視
class QueryMonitor {
  private slowQueryThreshold = 1000; // 1秒
  
  async executeWithMonitoring(
    query: string,
    params?: any[]
  ): Promise<any> {
    const start = Date.now();
    
    try {
      const result = await db.$queryRaw(query, params);
      const duration = Date.now() - start;
      
      if (duration > this.slowQueryThreshold) {
        console.warn('Slow query detected:', {
          query,
          duration,
          timestamp: new Date().toISOString()
        });
        
        // APMツールに送信
        await this.reportSlowQuery(query, duration);
      }
      
      return result;
    } catch (error) {
      console.error('Query error:', { query, error });
      throw error;
    }
  }
  
  private async reportSlowQuery(query: string, duration: number): Promise<void> {
    // Datadog, New Relic, etc.
    // apm.trackSlowQuery({ query, duration });
  }
}
```

### EXPLAIN 分析
```sql
-- PostgreSQL: 実行計画の分析
EXPLAIN (ANALYZE, BUFFERS) 
SELECT u.*, COUNT(o.id) as order_count
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
WHERE u.created_at >= '2024-01-01'
GROUP BY u.id;

-- インデックススキャンの確認
EXPLAIN (FORMAT JSON) SELECT * FROM products WHERE category = 'electronics';
```

## チェックリスト
- [ ] 適切なインデックス設計
- [ ] N+1問題の解決
- [ ] 必要なカラムのみSELECT
- [ ] JOIN順序の最適化
- [ ] ページネーション戦略選択
- [ ] 集計の事前計算
- [ ] コネクションプール設定
- [ ] Read Replica活用
- [ ] スロークエリ監視
- [ ] 定期的なEXPLAIN分析