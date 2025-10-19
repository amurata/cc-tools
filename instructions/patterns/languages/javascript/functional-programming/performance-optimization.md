# Performance Optimization

## Lazy Evaluation Patterns

```javascript
// Lazy evaluation sequence
class LazySequence {
  constructor(generator) {
    this.generator = generator;
  }
  
  static of(iterable) {
    return new LazySequence(function* () {
      yield* iterable;
    });
  }
  
  map(fn) {
    const generator = this.generator;
    return new LazySequence(function* () {
      for (const item of generator()) {
        yield fn(item);
      }
    });
  }
  
  filter(predicate) {
    const generator = this.generator;
    return new LazySequence(function* () {
      for (const item of generator()) {
        if (predicate(item)) {
          yield item;
        }
      }
    });
  }
  
  take(count) {
    const generator = this.generator;
    return new LazySequence(function* () {
      let taken = 0;
      for (const item of generator()) {
        if (taken >= count) break;
        yield item;
        taken++;
      }
    });
  }
  
  takeWhile(predicate) {
    const generator = this.generator;
    return new LazySequence(function* () {
      for (const item of generator()) {
        if (!predicate(item)) break;
        yield item;
      }
    });
  }
  
  collect() {
    return Array.from(this.generator());
  }
  
  reduce(reducer, initial) {
    let accumulator = initial;
    for (const item of this.generator()) {
      accumulator = reducer(accumulator, item);
    }
    return accumulator;
  }
  
  forEach(fn) {
    for (const item of this.generator()) {
      fn(item);
    }
  }
}

// Efficient processing of large datasets
const processLargeDataset = (data) =>
  LazySequence.of(data)
    .filter(x => x % 2 === 0)
    .map(x => x * x)
    .take(1000)
    .collect();

// Infinite sequences
const fibonacci = new LazySequence(function* () {
  let [a, b] = [0, 1];
  while (true) {
    yield a;
    [a, b] = [b, a + b];
  }
});

const first10Fibs = fibonacci.take(10).collect();
console.log(first10Fibs); // [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]
```

## Memoization Optimization

```javascript
// High-performance memoization
const createMemoizedFunction = (fn, options = {}) => {
  const {
    maxSize = 100,
    ttl = Infinity,
    keyGenerator = (...args) => JSON.stringify(args)
  } = options;
  
  const cache = new Map();
  const accessTimes = new Map();
  
  const evictOldEntries = () => {
    if (cache.size >= maxSize) {
      // LRU eviction
      const oldestKey = Array.from(accessTimes.entries())
        .sort(([, a], [, b]) => a - b)[0][0];
      cache.delete(oldestKey);
      accessTimes.delete(oldestKey);
    }
  };
  
  const memoized = (...args) => {
    const key = keyGenerator(...args);
    const now = Date.now();
    
    if (cache.has(key)) {
      const entry = cache.get(key);
      if (now - entry.timestamp <= ttl) {
        accessTimes.set(key, now);
        return entry.value;
      } else {
        cache.delete(key);
        accessTimes.delete(key);
      }
    }
    
    evictOldEntries();
    
    const result = fn(...args);
    cache.set(key, { value: result, timestamp: now });
    accessTimes.set(key, now);
    
    return result;
  };
  
  memoized.cache = cache;
  memoized.clear = () => {
    cache.clear();
    accessTimes.clear();
  };
  
  return memoized;
};

// Fast Fibonacci calculation
const fastFibonacci = createMemoizedFunction((n) => {
  if (n <= 1) return n;
  return fastFibonacci(n - 1) + fastFibonacci(n - 2);
});

console.time('fibonacci');
console.log(fastFibonacci(40)); // Fast execution
console.timeEnd('fibonacci');
```

## Function Composition Optimization

```javascript
// Optimized pipe implementation
const optimizedPipe = (...fns) => {
  if (fns.length === 0) return identity;
  if (fns.length === 1) return fns[0];
  
  // Optimize consecutive same transformations
  const optimizedFns = fns.reduce((acc, fn) => {
    const last = acc[acc.length - 1];
    if (last && canCompose(last, fn)) {
      acc[acc.length - 1] = composeFunctions(last, fn);
    } else {
      acc.push(fn);
    }
    return acc;
  }, []);
  
  return (value) => optimizedFns.reduce((acc, fn) => fn(acc), value);
};

// Optimize specific transformation patterns
const canCompose = (f1, f2) => {
  return (f1.name === 'map' && f2.name === 'map') ||
         (f1.name === 'filter' && f2.name === 'filter');
};

const composeFunctions = (f1, f2) => {
  if (f1.name === 'map' && f2.name === 'map') {
    return createMapFunction(x => f2.fn(f1.fn(x)));
  }
  if (f1.name === 'filter' && f2.name === 'filter') {
    return createFilterFunction(x => f1.fn(x) && f2.fn(x));
  }
  return (value) => f2(f1(value));
};

const createMapFunction = (fn) => {
  const mapFn = (array) => array.map(fn);
  mapFn.name = 'map';
  mapFn.fn = fn;
  return mapFn;
};

const createFilterFunction = (fn) => {
  const filterFn = (array) => array.filter(fn);
  filterFn.name = 'filter';
  filterFn.fn = fn;
  return filterFn;
};
```

## Immutable Structure Optimization

```javascript
// Persistent Data Structure (simplified version)
class PersistentVector {
  constructor(items = [], shift = 0, length = items.length) {
    this.items = items;
    this.shift = shift;
    this.length = length;
  }
  
  get(index) {
    if (index < 0 || index >= this.length) {
      return undefined;
    }
    return this.items[this.shift + index];
  }
  
  set(index, value) {
    if (index < 0 || index >= this.length) {
      throw new Error('Index out of bounds');
    }
    
    const newItems = [...this.items];
    newItems[this.shift + index] = value;
    return new PersistentVector(newItems, this.shift, this.length);
  }
  
  push(value) {
    // Share structure when there's tail room
    if (this.shift + this.length < this.items.length) {
      const newItems = [...this.items];
      newItems[this.shift + this.length] = value;
      return new PersistentVector(newItems, this.shift, this.length + 1);
    }
    
    // Need new buffer
    const newItems = [...this.items, value];
    return new PersistentVector(newItems, this.shift, this.length + 1);
  }
  
  pop() {
    if (this.length === 0) {
      throw new Error('Cannot pop from empty vector');
    }
    return new PersistentVector(this.items, this.shift, this.length - 1);
  }
  
  slice(start = 0, end = this.length) {
    const actualStart = Math.max(0, start);
    const actualEnd = Math.min(this.length, end);
    const newShift = this.shift + actualStart;
    const newLength = actualEnd - actualStart;
    
    return new PersistentVector(this.items, newShift, newLength);
  }
  
  toArray() {
    return this.items.slice(this.shift, this.shift + this.length);
  }
}

// Copy-on-Write optimization
class COWMap {
  constructor(data = {}, isCopied = false) {
    this._data = data;
    this._isCopied = isCopied;
  }
  
  _ensureWritable() {
    if (!this._isCopied) {
      this._data = { ...this._data };
      this._isCopied = true;
    }
  }
  
  set(key, value) {
    if (this._data[key] === value) {
      return this; // Don't create new instance if value is the same
    }
    
    const newMap = new COWMap(this._data, false);
    newMap._ensureWritable();
    newMap._data[key] = value;
    return newMap;
  }
  
  delete(key) {
    if (!(key in this._data)) {
      return this; // Do nothing if key doesn't exist
    }
    
    const newMap = new COWMap(this._data, false);
    newMap._ensureWritable();
    delete newMap._data[key];
    return newMap;
  }
  
  get(key) {
    return this._data[key];
  }
  
  has(key) {
    return key in this._data;
  }
}
```

## Transducer Optimization

```javascript
// Efficient transducer implementation
const createTransducer = () => {
  const protocols = {
    '@@transducer/init': Symbol('init'),
    '@@transducer/result': Symbol('result'),
    '@@transducer/step': Symbol('step')
  };
  
  const map = (transform) => (reducer) => {
    return {
      [protocols['@@transducer/init']]() {
        return reducer[protocols['@@transducer/init']]();
      },
      [protocols['@@transducer/result']](acc) {
        return reducer[protocols['@@transducer/result']](acc);
      },
      [protocols['@@transducer/step']](acc, input) {
        return reducer[protocols['@@transducer/step']](acc, transform(input));
      }
    };
  };
  
  const filter = (predicate) => (reducer) => {
    return {
      [protocols['@@transducer/init']]() {
        return reducer[protocols['@@transducer/init']]();
      },
      [protocols['@@transducer/result']](acc) {
        return reducer[protocols['@@transducer/result']](acc);
      },
      [protocols['@@transducer/step']](acc, input) {
        return predicate(input) 
          ? reducer[protocols['@@transducer/step']](acc, input)
          : acc;
      }
    };
  };
  
  const take = (n) => (reducer) => {
    let taken = 0;
    return {
      [protocols['@@transducer/init']]() {
        return reducer[protocols['@@transducer/init']]();
      },
      [protocols['@@transducer/result']](acc) {
        return reducer[protocols['@@transducer/result']](acc);
      },
      [protocols['@@transducer/step']](acc, input) {
        if (taken >= n) return acc;
        taken++;
        return reducer[protocols['@@transducer/step']](acc, input);
      }
    };
  };
  
  return { map, filter, take, protocols };
};

// High-performance data processing pipeline
const { map, filter, take } = createTransducer();

const processLargeArray = (data) => {
  const xform = pipe(
    map(x => x * 2),
    filter(x => x > 10),
    take(1000)
  );
  
  return transduce(
    xform,
    (acc, value) => { acc.push(value); return acc; },
    [],
    data
  );
};

// Benchmark example
const largeArray = Array.from({ length: 1000000 }, (_, i) => i);

console.time('transducer');
const result = processLargeArray(largeArray);
console.timeEnd('transducer');

console.time('regular');
const regularResult = largeArray
  .map(x => x * 2)
  .filter(x => x > 10)
  .slice(0, 1000);
console.timeEnd('regular');
```