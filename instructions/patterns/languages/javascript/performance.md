# JavaScriptパフォーマンス最適化

## コード最適化

### メモリリークの回避
適切なクリーンアップでメモリ問題を防止。

```javascript
// 良い例
class EventManager {
  constructor() {
    this.listeners = new WeakMap();
  }
  
  addEventListener(element, callback) {
    const controller = new AbortController();
    element.addEventListener('click', callback, { signal: controller.signal });
    this.listeners.set(element, controller);
  }
  
  removeEventListener(element) {
    const controller = this.listeners.get(element);
    controller?.abort();
    this.listeners.delete(element);
  }
  
  cleanup() {
    // WeakMapはガベージコレクションを許可
  }
}

// 悪い例 - メモリリーク
const handlers = [];
element.addEventListener('click', handler);
handlers.push(handler); // クリーンアップされない
```

### デバウンスとスロットル
関数実行頻度を制御。

```javascript
// 良い例 - 検索入力のデバウンス
const debounce = (fn, delay) => {
  let timeoutId;
  return (...args) => {
    clearTimeout(timeoutId);
    timeoutId = setTimeout(() => fn(...args), delay);
  };
};

const search = debounce(async (query) => {
  const results = await searchAPI(query);
  displayResults(results);
}, 300);

// スクロールイベントのスロットル
const throttle = (fn, limit) => {
  let inThrottle;
  return (...args) => {
    if (!inThrottle) {
      fn(...args);
      inThrottle = true;
      setTimeout(() => inThrottle = false, limit);
    }
  };
};

const handleScroll = throttle(() => {
  updateScrollPosition();
}, 100);
```

## Reactパフォーマンス

### メモ化
不要な再レンダリングと再計算を防止。

```javascript
// 良い例
import { memo, useMemo, useCallback } from 'react';

const ExpensiveList = memo(({ items, onItemClick }) => {
  const sortedItems = useMemo(
    () => items.sort((a, b) => b.priority - a.priority),
    [items]
  );
  
  const handleClick = useCallback((id) => {
    onItemClick(id);
  }, [onItemClick]);
  
  return sortedItems.map(item => (
    <Item key={item.id} {...item} onClick={handleClick} />
  ));
});

// 悪い例 - 毎回再作成
const ExpensiveList = ({ items, onItemClick }) => {
  const sortedItems = items.sort((a, b) => b.priority - a.priority);
  
  return sortedItems.map(item => (
    <Item 
      key={item.id} 
      {...item} 
      onClick={() => onItemClick(item.id)} 
    />
  ));
};
```

### 仮想化
大規模リストで表示項目のみレンダリング。

```javascript
// 良い例 - React Window
import { FixedSizeList } from 'react-window';

const VirtualList = ({ items }) => {
  const Row = ({ index, style }) => (
    <div style={style}>
      {items[index].name}
    </div>
  );
  
  return (
    <FixedSizeList
      height={600}
      itemCount={items.length}
      itemSize={50}
      width="100%"
    >
      {Row}
    </FixedSizeList>
  );
};

// 悪い例 - 10000項目をレンダリング
const List = ({ items }) => (
  <div>
    {items.map(item => <Item key={item.id} {...item} />)}
  </div>
);
```

## バンドル最適化

### コード分割
必要な時のみコードを読み込み。

```javascript
// 良い例 - 動的インポート
const loadHeavyComponent = () => import('./HeavyComponent');

// ルートベースの分割
const routes = [
  {
    path: '/dashboard',
    component: lazy(() => import('./pages/Dashboard'))
  },
  {
    path: '/analytics',
    component: lazy(() => import('./pages/Analytics'))
  }
];

// 条件付き読み込み
if (userWantsAdvancedFeatures) {
  const { AdvancedEditor } = await import('./AdvancedEditor');
  renderEditor(AdvancedEditor);
}
```

### ツリーシェイキング
未使用コードをバンドルから削除。

```javascript
// 良い例 - ツリーシェイキング用の名前付きエクスポート
export { formatDate } from './formatters';
export { validateEmail } from './validators';

// 必要なものだけインポート
import { formatDate } from './utils';

// 悪い例 - すべてのデフォルトエクスポート
export default {
  formatDate,
  formatTime,
  validateEmail,
  validatePhone
};

import utils from './utils'; // すべてインポート
```

## 非同期操作

### APIコールのバッチ処理
ネットワークオーバーヘッドを削減。

```javascript
// 良い例 - バッチリクエスト
class BatchLoader {
  constructor(batchFn, delay = 10) {
    this.batchFn = batchFn;
    this.delay = delay;
    this.queue = [];
    this.timer = null;
  }
  
  load(id) {
    return new Promise((resolve, reject) => {
      this.queue.push({ id, resolve, reject });
      
      if (!this.timer) {
        this.timer = setTimeout(() => this.flush(), this.delay);
      }
    });
  }
  
  async flush() {
    const batch = this.queue.splice(0);
    this.timer = null;
    
    const ids = batch.map(item => item.id);
    const results = await this.batchFn(ids);
    
    batch.forEach((item, index) => {
      item.resolve(results[index]);
    });
  }
}

const userLoader = new BatchLoader(ids => fetchUsers(ids));
```

### リクエストキャンセル
古いリクエストをキャンセル。

```javascript
// 良い例
const fetchWithCancel = (url) => {
  const controller = new AbortController();
  
  const promise = fetch(url, { signal: controller.signal })
    .then(res => res.json());
  
  promise.cancel = () => controller.abort();
  
  return promise;
};

// Reactでの使用
useEffect(() => {
  const request = fetchWithCancel('/api/data');
  
  request.then(setData).catch(err => {
    if (err.name !== 'AbortError') {
      setError(err);
    }
  });
  
  return () => request.cancel();
}, []);
```

## キャッシュ戦略

### メモ化キャッシュ
高コストな計算をキャッシュ。

```javascript
// 良い例
const memoize = (fn) => {
  const cache = new Map();
  
  return (...args) => {
    const key = JSON.stringify(args);
    
    if (cache.has(key)) {
      return cache.get(key);
    }
    
    const result = fn(...args);
    cache.set(key, result);
    
    // LRUキャッシュ - サイズ制限
    if (cache.size > 100) {
      const firstKey = cache.keys().next().value;
      cache.delete(firstKey);
    }
    
    return result;
  };
};

const expensiveCalculation = memoize((n) => {
  // 複雑な計算
  return fibonacci(n);
});
```

### Service Workerキャッシュ
アセットとAPIレスポンスをキャッシュ。

```javascript
// 良い例 - キャッシュ戦略
self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request).then(response => {
      // キャッシュヒット - レスポンスを返す
      if (response) {
        return response;
      }
      
      // リクエストをクローン
      const fetchRequest = event.request.clone();
      
      return fetch(fetchRequest).then(response => {
        // 有効なレスポンスを確認
        if (!response || response.status !== 200) {
          return response;
        }
        
        // レスポンスをクローン
        const responseToCache = response.clone();
        
        caches.open('v1').then(cache => {
          cache.put(event.request, responseToCache);
        });
        
        return response;
      });
    })
  );
});
```

## DOM最適化

### DOM更新のバッチ処理
リフローとリペイントを最小化。

```javascript
// 良い例 - ドキュメントフラグメント
const fragment = document.createDocumentFragment();
items.forEach(item => {
  const li = document.createElement('li');
  li.textContent = item.name;
  fragment.appendChild(li);
});
list.appendChild(fragment);

// requestAnimationFrameを使用
const updatePositions = () => {
  requestAnimationFrame(() => {
    elements.forEach(el => {
      el.style.transform = `translateX(${el.dataset.x}px)`;
    });
  });
};

// 悪い例 - 複数のリフロー
items.forEach(item => {
  const li = document.createElement('li');
  li.textContent = item.name;
  list.appendChild(li); // 毎回リフローをトリガー
});
```

## Web Workers

### 重い計算をオフロード
バックグラウンドで高コストな操作を実行。

```javascript
// 良い例 - 重い処理用のWorker
// worker.js
self.addEventListener('message', (e) => {
  const { data, type } = e.data;
  
  if (type === 'PROCESS_DATA') {
    const result = heavyProcessing(data);
    self.postMessage({ type: 'RESULT', result });
  }
});

// main.js
const worker = new Worker('worker.js');

worker.postMessage({ type: 'PROCESS_DATA', data: largeDataset });

worker.addEventListener('message', (e) => {
  if (e.data.type === 'RESULT') {
    displayResults(e.data.result);
  }
});
```

## ベストプラクティスチェックリスト

- [ ] プロダクションビルドを使用（圧縮、最適化）
- [ ] gzip/brotli圧縮を有効化
- [ ] 画像とコンポーネントの遅延読み込みを実装
- [ ] 静的アセットにCDNを使用
- [ ] 画像を最適化（WebP、レスポンシブサイズ）
- [ ] ツリーシェイキングでバンドルサイズを最小化
- [ ] コード分割を実装
- [ ] APIレスポンスを適切にキャッシュ
- [ ] 高コストな操作をデバウンス/スロットル
- [ ] 重い計算にはWeb Workersを使用
- [ ] Lighthouseでパフォーマンスを監視
- [ ] パフォーマンス予算を設定