# Promise State Management

## StatefulPromise

```javascript
class StatefulPromise {
  constructor(executor) {
    this.state = 'pending';
    this.value = undefined;
    this.reason = undefined;
    this.startTime = Date.now();
    this.endTime = null;
    
    this.promise = new Promise((resolve, reject) => {
      const wrappedResolve = (value) => {
        this.state = 'fulfilled';
        this.value = value;
        this.endTime = Date.now();
        resolve(value);
      };
      
      const wrappedReject = (reason) => {
        this.state = 'rejected';
        this.reason = reason;
        this.endTime = Date.now();
        reject(reason);
      };
      
      executor(wrappedResolve, wrappedReject);
    });
  }
  
  get duration() {
    return this.endTime ? this.endTime - this.startTime : Date.now() - this.startTime;
  }
  
  get isPending() { return this.state === 'pending'; }
  get isFulfilled() { return this.state === 'fulfilled'; }
  get isRejected() { return this.state === 'rejected'; }
  get isSettled() { return this.state !== 'pending'; }
}
```

## Promise Pool

```javascript
class PromisePool {
  constructor(concurrency = 3) {
    this.concurrency = concurrency;
    this.running = 0;
    this.queue = [];
  }
  
  async add(promiseFactory) {
    return new Promise((resolve, reject) => {
      this.queue.push({ promiseFactory, resolve, reject });
      this.process();
    });
  }
  
  async process() {
    if (this.running >= this.concurrency || this.queue.length === 0) return;
    
    this.running++;
    const { promiseFactory, resolve, reject } = this.queue.shift();
    
    try {
      const result = await promiseFactory();
      resolve(result);
    } catch (error) {
      reject(error);
    } finally {
      this.running--;
      this.process();
    }
  }
}
```

## Cancellable Promise

```javascript
class CancellablePromise {
  constructor(executor) {
    this.cancelled = false;
    this.cancelCallbacks = [];
    
    this.promise = new Promise((resolve, reject) => {
      const cancel = () => {
        this.cancelled = true;
        this.cancelCallbacks.forEach(cb => cb());
        reject(new Error('Promise cancelled'));
      };
      
      executor(
        value => !this.cancelled && resolve(value),
        reason => !this.cancelled && reject(reason),
        cancel
      );
    });
  }
  
  cancel() {
    if (!this.cancelled) {
      this.cancelled = true;
      this.cancelCallbacks.forEach(cb => cb());
    }
  }
  
  onCancel(callback) {
    this.cancelCallbacks.push(callback);
  }
}
```

## Promise Memoization

```javascript
class PromiseCache {
  constructor() {
    this.cache = new Map();
  }
  
  memoize(fn, options = {}) {
    const { ttl = 60000, keyGenerator = (...args) => JSON.stringify(args) } = options;
    
    return (...args) => {
      const key = keyGenerator(...args);
      const now = Date.now();
      
      if (this.cache.has(key)) {
        const cached = this.cache.get(key);
        if (now - cached.timestamp < ttl) {
          return cached.promise;
        }
        this.cache.delete(key);
      }
      
      const promise = fn(...args).catch(error => {
        this.cache.delete(key);
        throw error;
      });
      
      this.cache.set(key, { promise, timestamp: now });
      return promise;
    };
  }
}

// Usage example
const cache = new PromiseCache();
const cachedFetch = cache.memoize(
  async (url) => fetch(url).then(r => r.json()),
  { ttl: 30000 }
);
```