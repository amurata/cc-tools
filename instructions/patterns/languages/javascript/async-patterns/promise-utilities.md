# Promise Utilities

## Custom Promise Utilities

```javascript
class PromiseUtils {
  // Resolve when n promises succeed
  static async some(promises, count) {
    if (count <= 0) return [];
    if (count >= promises.length) return Promise.all(promises);
    
    return new Promise((resolve, reject) => {
      const results = [];
      let completed = 0;
      
      promises.forEach((promise, index) => {
        Promise.resolve(promise)
          .then(value => {
            results[index] = value;
            if (++completed >= count) {
              resolve(results.filter(Boolean).slice(0, count));
            }
          })
          .catch(() => {
            if (++completed === promises.length && results.filter(Boolean).length < count) {
              reject(new Error(`Only ${results.filter(Boolean).length} resolved`));
            }
          });
      });
    });
  }
  
  // Map with concurrency limit
  static async map(items, mapper, { concurrency = Infinity } = {}) {
    if (concurrency === Infinity) {
      return Promise.all(items.map(mapper));
    }
    
    const results = [];
    const executing = [];
    
    for (const [index, item] of items.entries()) {
      const promise = mapper(item, index).then(result => {
        results[index] = result;
      });
      
      if (concurrency <= items.length) {
        executing.push(promise);
        if (executing.length >= concurrency) {
          await Promise.race(executing);
          executing.splice(executing.findIndex(p => p === promise), 1);
        }
      }
    }
    
    await Promise.all(executing);
    return results;
  }
  
  // Resolve object properties
  static async props(obj) {
    const keys = Object.keys(obj);
    const values = await Promise.all(Object.values(obj));
    return keys.reduce((result, key, i) => {
      result[key] = values[i];
      return result;
    }, {});
  }
  
  // Progress tracking
  static withProgress(promises, onProgress) {
    let completed = 0;
    const total = promises.length;
    
    return Promise.allSettled(
      promises.map((promise, index) =>
        Promise.resolve(promise).finally(() => {
          onProgress({
            completed: ++completed,
            total,
            percentage: Math.round((completed / total) * 100),
            index
          });
        })
      )
    );
  }
}
```

## Async Event Emitter

```javascript
class AsyncEventEmitter {
  constructor() {
    this.listeners = new Map();
  }
  
  once(event) {
    return new Promise(resolve => {
      const listener = (data) => {
        this.off(event, listener);
        resolve(data);
      };
      this.on(event, listener);
    });
  }
  
  async waitFor(event, predicate, timeout = 30000) {
    return new Promise((resolve, reject) => {
      const timeoutId = setTimeout(() => {
        this.off(event, listener);
        reject(new Error(`Timeout waiting for ${event}`));
      }, timeout);
      
      const listener = (data) => {
        if (!predicate || predicate(data)) {
          clearTimeout(timeoutId);
          this.off(event, listener);
          resolve(data);
        }
      };
      
      this.on(event, listener);
    });
  }
  
  async *iterate(event) {
    const queue = [];
    let resolve;
    let promise = new Promise(r => resolve = r);
    
    const listener = (data) => {
      queue.push(data);
      resolve();
      promise = new Promise(r => resolve = r);
    };
    
    this.on(event, listener);
    
    try {
      while (true) {
        if (queue.length === 0) await promise;
        while (queue.length > 0) yield queue.shift();
      }
    } finally {
      this.off(event, listener);
    }
  }
}
```

## Resource Loader

```javascript
class AsyncResourceLoader {
  constructor() {
    this.cache = new Map();
    this.loading = new Map();
  }
  
  async load(key, loader, options = {}) {
    const { cache = true, force = false, timeout, retry = 0 } = options;
    
    if (!force && cache && this.cache.has(key)) {
      return this.cache.get(key);
    }
    
    if (this.loading.has(key)) {
      return this.loading.get(key);
    }
    
    const loadingPromise = this.performLoad(key, loader, { timeout, retry });
    this.loading.set(key, loadingPromise);
    
    try {
      const resource = await loadingPromise;
      if (cache) this.cache.set(key, resource);
      return resource;
    } finally {
      this.loading.delete(key);
    }
  }
  
  async performLoad(key, loader, { timeout, retry }) {
    for (let attempt = 0; attempt <= retry; attempt++) {
      try {
        let promise = loader(key);
        if (timeout) {
          promise = Promise.race([
            promise,
            new Promise((_, reject) => 
              setTimeout(() => reject(new Error('Timeout')), timeout)
            )
          ]);
        }
        return await promise;
      } catch (error) {
        if (attempt === retry) throw error;
        await new Promise(r => setTimeout(r, 1000 * (attempt + 1)));
      }
    }
  }
}

// Usage example
const loader = new AsyncResourceLoader();
const config = await loader.load('config', 
  () => fetch('/api/config').then(r => r.json()),
  { cache: true, timeout: 5000, retry: 2 }
);
```