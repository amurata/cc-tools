# Caching Strategies

キャッシング戦略とパフォーマンス最適化パターン。

## キャッシングレベル

### 多層キャッシングアーキテクチャ
```
[Browser Cache] → [CDN] → [Reverse Proxy] → [Application Cache] → [Database Cache]
     L1             L2           L3                L4                   L5
```

## ブラウザキャッシング

### Cache-Control ヘッダー
```typescript
// Express.js での実装
app.use('/static', express.static('public', {
  maxAge: '1y', // 静的ファイルは1年
  etag: true,
  lastModified: true,
  setHeaders: (res, path) => {
    if (path.endsWith('.html')) {
      // HTMLは再検証
      res.setHeader('Cache-Control', 'no-cache, must-revalidate');
    } else if (path.match(/\.(js|css)$/)) {
      // JSとCSSはバージョニングで管理
      res.setHeader('Cache-Control', 'public, max-age=31536000, immutable');
    } else if (path.match(/\.(jpg|jpeg|png|gif|webp)$/)) {
      // 画像は1ヶ月
      res.setHeader('Cache-Control', 'public, max-age=2592000');
    }
  }
}));

// APIレスポンスのキャッシング
app.get('/api/products', (req, res) => {
  res.set({
    'Cache-Control': 'public, max-age=300, s-maxage=600',
    'Vary': 'Accept-Encoding, Accept-Language',
    'ETag': generateETag(products)
  });
  
  // 条件付きリクエスト処理
  if (req.headers['if-none-match'] === generateETag(products)) {
    return res.status(304).end();
  }
  
  res.json(products);
});
```

### Service Worker キャッシング
```javascript
// service-worker.js
const CACHE_NAME = 'app-v1.0.0';
const urlsToCache = [
  '/',
  '/styles/main.css',
  '/scripts/main.js'
];

// インストール時にキャッシュ
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(urlsToCache))
  );
});

// キャッシュファースト戦略
self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request)
      .then(response => {
        if (response) {
          return response; // キャッシュから返す
        }
        
        return fetch(event.request).then(response => {
          // レスポンスをキャッシュに追加
          if (!response || response.status !== 200) {
            return response;
          }
          
          const responseToCache = response.clone();
          caches.open(CACHE_NAME)
            .then(cache => {
              cache.put(event.request, responseToCache);
            });
          
          return response;
        });
      })
  );
});
```

## アプリケーションキャッシング

### メモリキャッシュ
```typescript
// シンプルなインメモリキャッシュ
class MemoryCache<T> {
  private cache = new Map<string, { data: T; expiry: number }>();
  
  set(key: string, value: T, ttl: number = 3600): void {
    const expiry = Date.now() + (ttl * 1000);
    this.cache.set(key, { data: value, expiry });
  }
  
  get(key: string): T | null {
    const item = this.cache.get(key);
    
    if (!item) return null;
    
    if (Date.now() > item.expiry) {
      this.cache.delete(key);
      return null;
    }
    
    return item.data;
  }
  
  delete(key: string): void {
    this.cache.delete(key);
  }
  
  clear(): void {
    this.cache.clear();
  }
  
  // 自動クリーンアップ
  startCleanup(interval: number = 60000): void {
    setInterval(() => {
      const now = Date.now();
      for (const [key, item] of this.cache.entries()) {
        if (now > item.expiry) {
          this.cache.delete(key);
        }
      }
    }, interval);
  }
}

// LRU (Least Recently Used) キャッシュ
class LRUCache<T> {
  private cache = new Map<string, T>();
  private readonly maxSize: number;
  
  constructor(maxSize: number = 100) {
    this.maxSize = maxSize;
  }
  
  get(key: string): T | undefined {
    const item = this.cache.get(key);
    if (item) {
      // 最新にする
      this.cache.delete(key);
      this.cache.set(key, item);
    }
    return item;
  }
  
  set(key: string, value: T): void {
    // 既存のキーを削除
    if (this.cache.has(key)) {
      this.cache.delete(key);
    }
    // サイズ制限チェック
    else if (this.cache.size >= this.maxSize) {
      // 最も古いものを削除
      const firstKey = this.cache.keys().next().value;
      this.cache.delete(firstKey);
    }
    
    this.cache.set(key, value);
  }
}
```

### Redis キャッシング
```typescript
import Redis from 'ioredis';

class RedisCache {
  private client: Redis;
  
  constructor() {
    this.client = new Redis({
      host: process.env.REDIS_HOST,
      port: parseInt(process.env.REDIS_PORT!),
      password: process.env.REDIS_PASSWORD,
      retryStrategy: (times) => Math.min(times * 50, 2000)
    });
  }
  
  async get<T>(key: string): Promise<T | null> {
    const data = await this.client.get(key);
    return data ? JSON.parse(data) : null;
  }
  
  async set(key: string, value: any, ttl?: number): Promise<void> {
    const serialized = JSON.stringify(value);
    if (ttl) {
      await this.client.setex(key, ttl, serialized);
    } else {
      await this.client.set(key, serialized);
    }
  }
  
  async delete(key: string): Promise<void> {
    await this.client.del(key);
  }
  
  // パターンマッチング削除
  async deletePattern(pattern: string): Promise<void> {
    const keys = await this.client.keys(pattern);
    if (keys.length > 0) {
      await this.client.del(...keys);
    }
  }
  
  // キャッシュ無効化戦略
  async invalidate(tags: string[]): Promise<void> {
    const pipeline = this.client.pipeline();
    for (const tag of tags) {
      pipeline.del(`tag:${tag}`);
    }
    await pipeline.exec();
  }
}

// キャッシュデコレーター
function Cacheable(ttl: number = 3600) {
  return function (target: any, propertyKey: string, descriptor: PropertyDescriptor) {
    const originalMethod = descriptor.value;
    
    descriptor.value = async function (...args: any[]) {
      const cache = new RedisCache();
      const cacheKey = `${target.constructor.name}:${propertyKey}:${JSON.stringify(args)}`;
      
      // キャッシュチェック
      const cached = await cache.get(cacheKey);
      if (cached) {
        console.log(`Cache hit: ${cacheKey}`);
        return cached;
      }
      
      // 実行してキャッシュ
      const result = await originalMethod.apply(this, args);
      await cache.set(cacheKey, result, ttl);
      console.log(`Cache miss: ${cacheKey}`);
      
      return result;
    };
    
    return descriptor;
  };
}

// 使用例
class ProductService {
  @Cacheable(600) // 10分キャッシュ
  async getProduct(id: string): Promise<Product> {
    return await db.product.findUnique({ where: { id } });
  }
}
```

## キャッシング戦略パターン

### Cache-Aside (Lazy Loading)
```typescript
class CacheAsideStrategy {
  constructor(
    private cache: RedisCache,
    private db: Database
  ) {}
  
  async get(key: string): Promise<any> {
    // 1. キャッシュチェック
    const cached = await this.cache.get(key);
    if (cached) return cached;
    
    // 2. DBから取得
    const data = await this.db.find(key);
    if (!data) return null;
    
    // 3. キャッシュに保存
    await this.cache.set(key, data, 3600);
    
    return data;
  }
  
  async update(key: string, data: any): Promise<void> {
    // 1. DB更新
    await this.db.update(key, data);
    
    // 2. キャッシュ無効化
    await this.cache.delete(key);
  }
}
```

### Write-Through
```typescript
class WriteThroughStrategy {
  constructor(
    private cache: RedisCache,
    private db: Database
  ) {}
  
  async write(key: string, data: any): Promise<void> {
    // 同時に書き込み
    await Promise.all([
      this.cache.set(key, data, 3600),
      this.db.save(key, data)
    ]);
  }
  
  async read(key: string): Promise<any> {
    // キャッシュから読み取り
    const cached = await this.cache.get(key);
    if (cached) return cached;
    
    // キャッシュミスの場合DBから
    const data = await this.db.find(key);
    if (data) {
      await this.cache.set(key, data, 3600);
    }
    
    return data;
  }
}
```

### Write-Behind (Write-Back)
```typescript
class WriteBehindStrategy {
  private writeQueue: Map<string, any> = new Map();
  private flushInterval: NodeJS.Timeout;
  
  constructor(
    private cache: RedisCache,
    private db: Database,
    flushIntervalMs: number = 5000
  ) {
    this.startFlush(flushIntervalMs);
  }
  
  async write(key: string, data: any): Promise<void> {
    // キャッシュにすぐ書き込み
    await this.cache.set(key, data);
    
    // キューに追加（後でDB書き込み）
    this.writeQueue.set(key, data);
  }
  
  private startFlush(interval: number): void {
    this.flushInterval = setInterval(async () => {
      if (this.writeQueue.size === 0) return;
      
      // バッチ書き込み
      const batch = Array.from(this.writeQueue.entries());
      this.writeQueue.clear();
      
      try {
        await this.db.batchSave(batch);
      } catch (error) {
        // エラー時は再度キューに追加
        batch.forEach(([key, data]) => {
          this.writeQueue.set(key, data);
        });
        throw error;
      }
    }, interval);
  }
  
  destroy(): void {
    clearInterval(this.flushInterval);
  }
}
```

## キャッシュ無効化

### タグベース無効化
```typescript
class TaggedCache {
  constructor(private cache: RedisCache) {}
  
  async setWithTags(key: string, value: any, tags: string[], ttl?: number): Promise<void> {
    // データを保存
    await this.cache.set(key, value, ttl);
    
    // タグとキーの関連を保存
    for (const tag of tags) {
      await this.cache.client.sadd(`tag:${tag}`, key);
    }
  }
  
  async invalidateByTag(tag: string): Promise<void> {
    // タグに関連するキーを取得
    const keys = await this.cache.client.smembers(`tag:${tag}`);
    
    if (keys.length > 0) {
      // 関連キーを削除
      await this.cache.client.del(...keys);
    }
    
    // タグ自体も削除
    await this.cache.client.del(`tag:${tag}`);
  }
}

// 使用例
const taggedCache = new TaggedCache(redisCache);

// 商品情報をタグ付きで保存
await taggedCache.setWithTags(
  'product:123',
  productData,
  ['products', 'category:electronics'],
  3600
);

// カテゴリの全商品キャッシュを無効化
await taggedCache.invalidateByTag('category:electronics');
```

### イベント駆動無効化
```typescript
import { EventEmitter } from 'events';

class CacheInvalidator extends EventEmitter {
  constructor(private cache: RedisCache) {
    super();
    this.setupListeners();
  }
  
  private setupListeners(): void {
    // エンティティ更新時
    this.on('entity:updated', async ({ type, id }) => {
      await this.cache.deletePattern(`${type}:${id}:*`);
    });
    
    // エンティティ削除時
    this.on('entity:deleted', async ({ type, id }) => {
      await this.cache.deletePattern(`${type}:${id}:*`);
    });
    
    // 関連エンティティ更新時
    this.on('relation:updated', async ({ parentType, parentId }) => {
      await this.cache.deletePattern(`${parentType}:${parentId}:*`);
    });
  }
  
  // 無効化トリガー
  async invalidate(event: string, data: any): Promise<void> {
    this.emit(event, data);
  }
}
```

## パフォーマンス測定

### キャッシュヒット率
```typescript
class CacheMetrics {
  private hits = 0;
  private misses = 0;
  
  recordHit(): void {
    this.hits++;
  }
  
  recordMiss(): void {
    this.misses++;
  }
  
  getHitRate(): number {
    const total = this.hits + this.misses;
    return total === 0 ? 0 : (this.hits / total) * 100;
  }
  
  getStats() {
    return {
      hits: this.hits,
      misses: this.misses,
      hitRate: `${this.getHitRate().toFixed(2)}%`,
      total: this.hits + this.misses
    };
  }
  
  reset(): void {
    this.hits = 0;
    this.misses = 0;
  }
}
```

## チェックリスト
- [ ] 適切なキャッシュレベル選択
- [ ] TTL設定の最適化
- [ ] キャッシュ無効化戦略
- [ ] キャッシュヒット率測定
- [ ] メモリ使用量監視
- [ ] キャッシュウォーミング実装
- [ ] スタンピード対策
- [ ] 分散キャッシュ考慮
- [ ] フォールバック処理