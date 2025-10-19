# Error Handling Patterns

## Safe Async Wrapper

```javascript
function safeAsync(asyncFn) {
  return async (...args) => {
    try {
      const result = await asyncFn(...args);
      return [null, result];
    } catch (error) {
      return [error, null];
    }
  };
}

// Usage example
const safeApiCall = safeAsync(async (url) => {
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`HTTP ${response.status}: ${response.statusText}`);
  }
  return response.json();
});

const [error, data] = await safeApiCall('/api/users');
if (error) {
  console.error('API call failed:', error.message);
} else {
  console.log('Data received:', data);
}
```

## Advanced Error Handler

```javascript
class AsyncErrorHandler {
  static async withRetry(asyncFn, options = {}) {
    const { maxRetries = 3, delay = 1000, shouldRetry = () => true } = options;
    let lastError;
    
    for (let i = 0; i <= maxRetries; i++) {
      try {
        return await asyncFn();
      } catch (error) {
        lastError = error;
        if (i === maxRetries || !shouldRetry(error, i)) break;
        await new Promise(resolve => setTimeout(resolve, delay * (i + 1)));
      }
    }
    throw lastError;
  }
  
  static async withFallback(asyncFn, fallbackFn) {
    try {
      return await asyncFn();
    } catch (error) {
      console.warn('Primary function failed, using fallback:', error.message);
      return await fallbackFn(error);
    }
  }
  
  static async withTimeout(asyncFn, timeoutMs, timeoutMessage = 'Operation timed out') {
    const timeoutPromise = new Promise((_, reject) => {
      setTimeout(() => reject(new Error(timeoutMessage)), timeoutMs);
    });
    return Promise.race([asyncFn(), timeoutPromise]);
  }
}
```

## Circuit Breaker Pattern

```javascript
class CircuitBreaker {
  constructor(options = {}) {
    this.failureThreshold = options.failureThreshold || 5;
    this.resetTimeout = options.resetTimeout || 60000;
    this.state = 'CLOSED';
    this.failureCount = 0;
    this.lastFailureTime = null;
    this.successCount = 0;
  }
  
  async execute(asyncFn) {
    if (this.state === 'OPEN') {
      if (Date.now() - this.lastFailureTime >= this.resetTimeout) {
        this.state = 'HALF_OPEN';
        this.successCount = 0;
      } else {
        throw new Error('Circuit breaker is OPEN');
      }
    }
    
    try {
      const result = await asyncFn();
      
      if (this.state === 'HALF_OPEN') {
        this.successCount++;
        if (this.successCount >= 3) {
          this.state = 'CLOSED';
          this.failureCount = 0;
        }
      } else {
        this.failureCount = 0;
      }
      
      return result;
    } catch (error) {
      this.failureCount++;
      this.lastFailureTime = Date.now();
      
      if (this.failureCount >= this.failureThreshold) {
        this.state = 'OPEN';
      }
      
      throw error;
    }
  }
}

// Usage example
const breaker = new CircuitBreaker({ failureThreshold: 3, resetTimeout: 10000 });
const protectedApiCall = () => breaker.execute(() => fetch('/api/data').then(r => r.json()));
```