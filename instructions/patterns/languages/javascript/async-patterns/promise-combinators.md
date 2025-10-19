# Promise Combinator Patterns

## Enhanced Promise.allSettled

```javascript
// Promise.all with error handling per promise
async function allSettledWithDetails(promises) {
  const results = await Promise.allSettled(promises);
  
  return {
    fulfilled: results
      .filter(result => result.status === 'fulfilled')
      .map(result => result.value),
    rejected: results
      .filter(result => result.status === 'rejected')
      .map(result => result.reason),
    success: results.every(result => result.status === 'fulfilled'),
    count: {
      total: results.length,
      fulfilled: results.filter(r => r.status === 'fulfilled').length,
      rejected: results.filter(r => r.status === 'rejected').length
    }
  };
}
```

## Race with Timeout

```javascript
// Promise.race with timeout
function raceWithTimeout(promises, timeoutMs, timeoutValue) {
  const timeout = new Promise(resolve => 
    setTimeout(() => resolve(timeoutValue), timeoutMs)
  );
  
  return Promise.race([...promises, timeout]);
}
```

## Enhanced Promise.any

```javascript
// Promise.any with detailed error
async function anyWithDetails(promises) {
  try {
    const result = await Promise.any(promises);
    return { success: true, value: result };
  } catch (aggregateError) {
    return {
      success: false,
      errors: aggregateError.errors,
      message: 'All promises rejected'
    };
  }
}
```

## Sequential Processing Patterns

```javascript
// Sequential processing with Promise.reduce equivalent
async function promiseReduce(array, reducerFn, initialValue) {
  let accumulator = initialValue;
  
  for (const item of array) {
    accumulator = await reducerFn(accumulator, item);
  }
  
  return accumulator;
}

// Conditional Promise execution
async function conditionalPromise(condition, promiseFn, fallbackValue) {
  if (await condition()) {
    return promiseFn();
  }
  return fallbackValue;
}
```

## Promise Pipeline

```javascript
// Promise pipeline
function promisePipe(...fns) {
  return (value) => fns.reduce((promise, fn) => promise.then(fn), Promise.resolve(value));
}

// Usage examples
const fetchOperations = [
  fetch('/api/users'),
  fetch('/api/posts'),
  fetch('/api/comments')
];

const results = await allSettledWithDetails(fetchOperations);
console.log(`${results.count.fulfilled}/${results.count.total} requests succeeded`);

const fastestResponse = await raceWithTimeout(
  fetchOperations,
  5000,
  { error: 'Timeout after 5 seconds' }
);

const pipeline = promisePipe(
  (data) => fetch('/api/process', { method: 'POST', body: JSON.stringify(data) }),
  (response) => response.json(),
  (data) => ({ ...data, timestamp: Date.now() })
);

const processedData = await pipeline({ input: 'test' });
```