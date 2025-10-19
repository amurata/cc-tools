# Concurrency Patterns

## Semaphore

```javascript
class Semaphore {
  constructor(capacity) {
    this.capacity = capacity;
    this.current = 0;
    this.queue = [];
  }
  
  async acquire() {
    return new Promise((resolve) => {
      if (this.current < this.capacity) {
        this.current++;
        resolve();
      } else {
        this.queue.push(resolve);
      }
    });
  }
  
  release() {
    if (this.queue.length > 0) {
      this.queue.shift()();
    } else {
      this.current--;
    }
  }
  
  async use(asyncFn) {
    await this.acquire();
    try {
      return await asyncFn();
    } finally {
      this.release();
    }
  }
}
```

## Batch Processor

```javascript
class BatchProcessor {
  constructor(options = {}) {
    this.batchSize = options.batchSize || 10;
    this.concurrency = options.concurrency || 3;
    this.semaphore = new Semaphore(this.concurrency);
  }
  
  async process(items, processor) {
    const batches = [];
    for (let i = 0; i < items.length; i += this.batchSize) {
      batches.push(items.slice(i, i + this.batchSize));
    }
    
    const results = await Promise.all(
      batches.map(batch => 
        this.semaphore.use(() => processor(batch))
      )
    );
    
    return results.flat();
  }
}
```

## MapReduce Implementation

```javascript
class MapReduce {
  constructor(options = {}) {
    this.chunkSize = options.chunkSize || 1000;
    this.concurrency = options.concurrency || 4;
  }
  
  async execute(data, mapFn, reduceFn, initialValue) {
    const chunks = [];
    for (let i = 0; i < data.length; i += this.chunkSize) {
      chunks.push(data.slice(i, i + this.chunkSize));
    }
    
    const semaphore = new Semaphore(this.concurrency);
    const mapResults = await Promise.all(
      chunks.map(chunk => semaphore.use(() => mapFn(chunk)))
    );
    
    return mapResults.reduce(reduceFn, initialValue);
  }
}
```

## Fork-Join Pattern

```javascript
class ForkJoin {
  static async fork(tasks, concurrency = Infinity) {
    if (concurrency === Infinity) {
      return Promise.all(tasks.map(task => task()));
    }
    
    const semaphore = new Semaphore(concurrency);
    return Promise.all(
      tasks.map(task => semaphore.use(() => task()))
    );
  }
  
  static async forkMap(items, asyncMapper, concurrency = Infinity) {
    const tasks = items.map(item => () => asyncMapper(item));
    return this.fork(tasks, concurrency);
  }
  
  static async forkFilter(items, asyncPredicate, concurrency = Infinity) {
    const results = await this.forkMap(
      items,
      async item => {
        const shouldInclude = await asyncPredicate(item);
        return shouldInclude ? item : null;
      },
      concurrency
    );
    return results.filter(Boolean);
  }
}
```

## Parallel Pipeline

```javascript
class ParallelPipeline {
  constructor(concurrency = 3) {
    this.stages = [];
    this.concurrency = concurrency;
  }
  
  addStage(processor, options = {}) {
    this.stages.push({
      processor,
      batchSize: options.batchSize || 1,
      delay: options.delay || 0
    });
    return this;
  }
  
  async process(items) {
    let currentData = items;
    
    for (const stage of this.stages) {
      const semaphore = new Semaphore(this.concurrency);
      const batches = [];
      
      for (let i = 0; i < currentData.length; i += stage.batchSize) {
        batches.push(currentData.slice(i, i + stage.batchSize));
      }
      
      if (stage.delay > 0) {
        await new Promise(r => setTimeout(r, stage.delay));
      }
      
      const results = await Promise.all(
        batches.map(batch => 
          semaphore.use(() => stage.processor(batch))
        )
      );
      
      currentData = results.flat();
    }
    
    return currentData;
  }
}

// Usage example
const urls = ['/api/users', '/api/posts', '/api/comments'];
const [users, posts, comments] = await ForkJoin.fork([
  () => fetch('/api/users').then(r => r.json()),
  () => fetch('/api/posts').then(r => r.json()),
  () => fetch('/api/comments').then(r => r.json())
], 2);
```