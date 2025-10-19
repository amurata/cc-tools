# Real-World Patterns

## Advanced API Client

```javascript
class AdvancedApiClient {
  constructor(options = {}) {
    this.baseUrl = options.baseUrl || '';
    this.timeout = options.timeout || 30000;
    this.cache = new Map();
    this.cacheTTL = options.cacheTTL || 300000;
    this.semaphore = new Semaphore(options.maxConcurrentRequests || 10);
    this.interceptors = { request: [], response: [], error: [] };
    this.retryOptions = {
      maxRetries: 3,
      baseDelay: 1000,
      backoffFactor: 2,
      ...options.retry
    };
  }
  
  async request(config) {
    return this.semaphore.use(async () => {
      // Apply request interceptors
      for (const interceptor of this.interceptors.request) {
        config = await interceptor(config);
      }
      
      // Check cache
      const cacheKey = this.getCacheKey(config);
      if (config.method === 'GET' && this.cache.has(cacheKey)) {
        const cached = this.cache.get(cacheKey);
        if (Date.now() - cached.timestamp < this.cacheTTL) {
          return cached.data;
        }
        this.cache.delete(cacheKey);
      }
      
      // Execute request with retry
      let lastError;
      for (let attempt = 0; attempt <= this.retryOptions.maxRetries; attempt++) {
        try {
          const controller = new AbortController();
          const timeoutId = setTimeout(() => controller.abort(), this.timeout);
          
          const response = await fetch(this.buildUrl(config.url), {
            method: config.method || 'GET',
            headers: config.headers,
            body: config.data ? JSON.stringify(config.data) : undefined,
            signal: controller.signal
          });
          
          clearTimeout(timeoutId);
          
          if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
          }
          
          // Cache on success
          if (config.method === 'GET') {
            const data = await response.clone().json();
            this.cache.set(cacheKey, { data, timestamp: Date.now() });
          }
          
          return response;
        } catch (error) {
          lastError = error;
          if (attempt < this.retryOptions.maxRetries) {
            const delay = this.retryOptions.baseDelay * 
              Math.pow(this.retryOptions.backoffFactor, attempt);
            await new Promise(r => setTimeout(r, delay));
          }
        }
      }
      throw lastError;
    });
  }
  
  getCacheKey(config) {
    return `${config.method}:${config.url}:${JSON.stringify(config.params)}`;
  }
  
  buildUrl(path) {
    return path.startsWith('http') ? path : `${this.baseUrl}${path}`;
  }
}
```

## Background Task Manager

```javascript
class BackgroundTaskManager {
  constructor(options = {}) {
    this.queues = new Map();
    this.running = new Map();
    this.completed = new Map();
    this.failed = new Map();
    this.maxRetries = options.maxRetries || 3;
    this.isProcessing = false;
  }
  
  addTask(queueName, taskFn, options = {}) {
    const task = {
      id: this.generateTaskId(),
      fn: taskFn,
      priority: options.priority || 0,
      retries: 0,
      maxRetries: options.maxRetries || this.maxRetries,
      createdAt: Date.now(),
      metadata: options.metadata || {}
    };
    
    if (!this.queues.has(queueName)) {
      this.queues.set(queueName, []);
    }
    
    const queue = this.queues.get(queueName);
    const insertIndex = queue.findIndex(t => t.priority < task.priority);
    
    if (insertIndex === -1) {
      queue.push(task);
    } else {
      queue.splice(insertIndex, 0, task);
    }
    
    this.startProcessing();
    return task.id;
  }
  
  async startProcessing() {
    if (this.isProcessing) return;
    this.isProcessing = true;
    
    while (this.hasTasksToProcess()) {
      const { queueName, task } = this.getNextTask();
      if (!task) break;
      
      this.running.set(task.id, { ...task, queueName, startedAt: Date.now() });
      
      try {
        const result = await task.fn();
        this.completed.set(task.id, {
          ...task,
          result,
          completedAt: Date.now()
        });
      } catch (error) {
        task.retries++;
        
        if (task.retries < task.maxRetries) {
          // Exponential backoff retry
          const retryDelay = Math.pow(2, task.retries) * 1000;
          setTimeout(() => {
            this.queues.get(queueName).unshift(task);
            this.startProcessing();
          }, retryDelay);
        } else {
          this.failed.set(task.id, {
            ...task,
            error,
            failedAt: Date.now()
          });
        }
      } finally {
        this.running.delete(task.id);
      }
    }
    
    this.isProcessing = false;
  }
  
  scheduleTask(queueName, taskFn, delay, options = {}) {
    const taskId = this.generateTaskId();
    setTimeout(() => {
      this.addTask(queueName, taskFn, { ...options, id: taskId });
    }, delay);
    return taskId;
  }
  
  scheduleRecurring(queueName, taskFn, interval, options = {}) {
    let isActive = true;
    const runTask = async () => {
      if (!isActive) return;
      await this.addTaskAndWait(queueName, taskFn, options);
      if (isActive) setTimeout(runTask, interval);
    };
    setTimeout(runTask, interval);
    return { stop: () => { isActive = false; } };
  }
  
  getQueueStats(queueName) {
    const queue = this.queues.get(queueName) || [];
    return {
      pending: queue.length,
      running: Array.from(this.running.values())
        .filter(t => t.queueName === queueName).length,
      completed: Array.from(this.completed.values())
        .filter(t => t.queueName === queueName).length,
      failed: Array.from(this.failed.values())
        .filter(t => t.queueName === queueName).length
    };
  }
  
  generateTaskId() {
    return `task_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
}
```