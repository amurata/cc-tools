# Streaming and Generators

## Async Generators

```javascript
// Pagination support
async function* fetchPaginatedData(baseUrl, pageSize = 10) {
  let page = 1;
  let hasMore = true;
  
  while (hasMore) {
    const response = await fetch(`${baseUrl}?page=${page}&limit=${pageSize}`);
    const data = await response.json();
    
    for (const item of data.items) {
      yield item;
    }
    
    hasMore = data.hasMore;
    page++;
    
    if (hasMore) {
      await new Promise(r => setTimeout(r, 100)); // Rate limiting
    }
  }
}

// Stream transformation
async function* transformStream(source, transformer) {
  for await (const item of source) {
    const transformed = await transformer(item);
    if (transformed !== undefined) {
      yield transformed;
    }
  }
}

// Batch processing
async function* batchStream(source, batchSize) {
  let batch = [];
  
  for await (const item of source) {
    batch.push(item);
    
    if (batch.length >= batchSize) {
      yield batch;
      batch = [];
    }
  }
  
  if (batch.length > 0) {
    yield batch;
  }
}

// Merge multiple streams
async function* mergeStreams(...sources) {
  const iterators = sources.map(s => s[Symbol.asyncIterator]());
  const promises = new Map();
  
  iterators.forEach((it, i) => promises.set(i, it.next()));
  
  while (promises.size > 0) {
    const entries = Array.from(promises.entries());
    const { value: [index, result] } = await Promise.race(
      entries.map(([i, p]) => p.then(r => ({ value: [i, r] })))
    );
    
    if (!result.done) {
      yield result.value;
      promises.set(index, iterators[index].next());
    } else {
      promises.delete(index);
    }
  }
}
```

## Stream Processor

```javascript
class StreamProcessor {
  constructor() {
    this.processors = [];
  }
  
  map(mapper) {
    this.processors.push({ type: 'map', fn: mapper });
    return this;
  }
  
  filter(predicate) {
    this.processors.push({ type: 'filter', fn: predicate });
    return this;
  }
  
  batch(size) {
    this.processors.push({ type: 'batch', size });
    return this;
  }
  
  take(count) {
    this.processors.push({ type: 'take', count });
    return this;
  }
  
  async *process(source) {
    let stream = source;
    
    for (const processor of this.processors) {
      stream = this.applyProcessor(stream, processor);
    }
    
    for await (const item of stream) {
      yield item;
    }
  }
  
  async *applyProcessor(source, processor) {
    switch (processor.type) {
      case 'map':
        for await (const item of source) {
          yield await processor.fn(item);
        }
        break;
      
      case 'filter':
        for await (const item of source) {
          if (await processor.fn(item)) {
            yield item;
          }
        }
        break;
      
      case 'batch':
        let batch = [];
        for await (const item of source) {
          batch.push(item);
          if (batch.length >= processor.size) {
            yield batch;
            batch = [];
          }
        }
        if (batch.length > 0) yield batch;
        break;
      
      case 'take':
        let taken = 0;
        for await (const item of source) {
          if (taken >= processor.count) break;
          yield item;
          taken++;
        }
        break;
    }
  }
  
  async collect(source) {
    const results = [];
    for await (const item of this.process(source)) {
      results.push(item);
    }
    return results;
  }
}
```

## Observable-style Stream

```javascript
class ObservableStream {
  constructor(source) {
    this.source = source;
    this.observers = new Set();
  }
  
  subscribe(observer) {
    this.observers.add(observer);
    if (this.observers.size === 1) this.start();
    
    return () => {
      this.observers.delete(observer);
      if (this.observers.size === 0) this.stop();
    };
  }
  
  async start() {
    try {
      for await (const item of this.source) {
        this.observers.forEach(observer => {
          try {
            observer.next(item);
          } catch (error) {
            console.error('Observer error:', error);
          }
        });
      }
      
      this.observers.forEach(o => o.complete?.());
    } catch (error) {
      this.observers.forEach(o => o.error?.(error));
    }
  }
  
  stop() {
    // Cancellation implementation
  }
}

// Usage example
const dataStream = fetchPaginatedData('/api/users');

const processor = new StreamProcessor()
  .filter(user => user.active)
  .map(async user => {
    const profile = await fetch(`/api/profiles/${user.id}`).then(r => r.json());
    return { ...user, profile };
  })
  .batch(10)
  .take(100);

const batches = await processor.collect(dataStream);
```