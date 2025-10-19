# Python Async Patterns

Python非同期プログラミングのパターンとベストプラクティス。

## 基本的な非同期パターン

### async/await 基礎
```python
import asyncio
from typing import List, Optional, Any
import aiohttp
import time

# 基本的な非同期関数
async def fetch_data(url: str) -> dict:
    async with aiohttp.ClientSession() as session:
        async with session.get(url) as response:
            response.raise_for_status()
            return await response.json()

# 複数の非同期処理を並行実行
async def fetch_multiple_urls(urls: List[str]) -> List[dict]:
    async with aiohttp.ClientSession() as session:
        tasks = []
        for url in urls:
            task = asyncio.create_task(fetch_with_session(session, url))
            tasks.append(task)
        
        # 全てのタスクを待機
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        # エラー処理
        valid_results = []
        for result in results:
            if isinstance(result, Exception):
                print(f"Error fetching data: {result}")
            else:
                valid_results.append(result)
        
        return valid_results

async def fetch_with_session(session: aiohttp.ClientSession, url: str) -> dict:
    async with session.get(url) as response:
        response.raise_for_status()
        return await response.json()
```

### 並行処理制御
```python
import asyncio
from asyncio import Semaphore, Queue
from typing import TypeVar, Callable, Awaitable

T = TypeVar('T')

class ConcurrencyLimiter:
    """並行実行数を制限するユーティリティ"""
    
    def __init__(self, max_concurrent: int = 10):
        self.semaphore = Semaphore(max_concurrent)
    
    async def run_with_limit(
        self, 
        func: Callable[..., Awaitable[T]], 
        *args, 
        **kwargs
    ) -> T:
        async with self.semaphore:
            return await func(*args, **kwargs)
    
    async def run_multiple(
        self,
        tasks: List[Callable[[], Awaitable[T]]]
    ) -> List[T]:
        """複数のタスクを並行実行数制限付きで実行"""
        async def wrapped_task(task):
            async with self.semaphore:
                return await task()
        
        return await asyncio.gather(
            *[wrapped_task(task) for task in tasks]
        )

# 使用例
async def process_items(items: List[str]) -> List[str]:
    limiter = ConcurrencyLimiter(max_concurrent=5)
    
    async def process_single_item(item: str) -> str:
        # 重い処理をシミュレート
        await asyncio.sleep(1)
        return item.upper()
    
    tasks = [
        lambda i=item: process_single_item(i) 
        for item in items
    ]
    
    return await limiter.run_multiple(tasks)
```

## 非同期コンテキストマネージャー

### リソース管理
```python
from contextlib import asynccontextmanager
import asyncpg
from typing import AsyncIterator, Optional

class AsyncDatabasePool:
    """非同期データベース接続プール"""
    
    def __init__(self, dsn: str, min_size: int = 10, max_size: int = 20):
        self.dsn = dsn
        self.min_size = min_size
        self.max_size = max_size
        self.pool: Optional[asyncpg.Pool] = None
    
    async def __aenter__(self):
        self.pool = await asyncpg.create_pool(
            self.dsn,
            min_size=self.min_size,
            max_size=self.max_size
        )
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self.pool:
            await self.pool.close()
    
    @asynccontextmanager
    async def acquire(self) -> AsyncIterator[asyncpg.Connection]:
        """接続を取得するコンテキストマネージャー"""
        if not self.pool:
            raise RuntimeError("Pool not initialized")
        
        async with self.pool.acquire() as connection:
            yield connection
    
    async def execute(self, query: str, *args) -> str:
        """クエリを実行"""
        async with self.acquire() as conn:
            return await conn.execute(query, *args)
    
    async def fetch(self, query: str, *args) -> List[asyncpg.Record]:
        """データを取得"""
        async with self.acquire() as conn:
            return await conn.fetch(query, *args)

# 使用例
async def main():
    async with AsyncDatabasePool('postgresql://localhost/db') as db:
        # トランザクション内で実行
        async with db.acquire() as conn:
            async with conn.transaction():
                await conn.execute(
                    "INSERT INTO users (name, email) VALUES ($1, $2)",
                    "Alice", "alice@example.com"
                )
                await conn.execute(
                    "UPDATE stats SET user_count = user_count + 1"
                )
```

## 非同期イテレーター

### ストリーミング処理
```python
from typing import AsyncIterator, Optional
import asyncio

class AsyncDataStreamer:
    """大量データの非同期ストリーミング"""
    
    def __init__(self, source_url: str, chunk_size: int = 1024):
        self.source_url = source_url
        self.chunk_size = chunk_size
    
    async def __aiter__(self) -> AsyncIterator[bytes]:
        async with aiohttp.ClientSession() as session:
            async with session.get(self.source_url) as response:
                async for chunk in response.content.iter_chunked(self.chunk_size):
                    yield chunk
    
    async def process_stream(self) -> int:
        """ストリームを処理"""
        total_bytes = 0
        async for chunk in self:
            # チャンクごとに処理
            processed = await self.process_chunk(chunk)
            total_bytes += len(processed)
        return total_bytes
    
    async def process_chunk(self, chunk: bytes) -> bytes:
        # 何らかの処理
        await asyncio.sleep(0.01)  # I/O処理をシミュレート
        return chunk.upper() if isinstance(chunk, str) else chunk

class AsyncPaginator:
    """ページネーション付きデータの非同期イテレーター"""
    
    def __init__(self, fetch_func: Callable, page_size: int = 100):
        self.fetch_func = fetch_func
        self.page_size = page_size
        self.current_page = 1
        self.has_more = True
    
    def __aiter__(self):
        return self
    
    async def __anext__(self):
        if not self.has_more:
            raise StopAsyncIteration
        
        data = await self.fetch_func(
            page=self.current_page,
            page_size=self.page_size
        )
        
        if not data or len(data) < self.page_size:
            self.has_more = False
        
        self.current_page += 1
        
        if data:
            return data
        else:
            raise StopAsyncIteration

# 使用例
async def fetch_all_users():
    async def fetch_page(page: int, page_size: int) -> List[dict]:
        # API呼び出しをシミュレート
        await asyncio.sleep(0.1)
        if page > 3:  # 3ページまで
            return []
        return [{"id": i, "page": page} for i in range(page_size)]
    
    paginator = AsyncPaginator(fetch_page)
    all_users = []
    
    async for page_data in paginator:
        all_users.extend(page_data)
    
    return all_users
```

## タスク管理

### タスクキューとワーカー
```python
from dataclasses import dataclass
from enum import Enum
from typing import Any, Callable, Awaitable
import uuid

class TaskStatus(Enum):
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"

@dataclass
class Task:
    id: str
    func: Callable[..., Awaitable[Any]]
    args: tuple
    kwargs: dict
    status: TaskStatus = TaskStatus.PENDING
    result: Any = None
    error: Optional[Exception] = None

class AsyncTaskQueue:
    """非同期タスクキュー"""
    
    def __init__(self, max_workers: int = 5):
        self.queue: Queue[Task] = Queue()
        self.max_workers = max_workers
        self.workers: List[asyncio.Task] = []
        self.results: dict[str, Any] = {}
        self.running = False
    
    async def submit(
        self, 
        func: Callable[..., Awaitable[Any]], 
        *args, 
        **kwargs
    ) -> str:
        """タスクをキューに追加"""
        task_id = str(uuid.uuid4())
        task = Task(
            id=task_id,
            func=func,
            args=args,
            kwargs=kwargs
        )
        await self.queue.put(task)
        return task_id
    
    async def worker(self):
        """ワーカータスク"""
        while self.running:
            try:
                # タイムアウト付きでタスクを取得
                task = await asyncio.wait_for(
                    self.queue.get(), 
                    timeout=1.0
                )
                
                task.status = TaskStatus.RUNNING
                
                try:
                    # タスクを実行
                    result = await task.func(*task.args, **task.kwargs)
                    task.result = result
                    task.status = TaskStatus.COMPLETED
                    self.results[task.id] = result
                    
                except Exception as e:
                    task.error = e
                    task.status = TaskStatus.FAILED
                    print(f"Task {task.id} failed: {e}")
                
            except asyncio.TimeoutError:
                continue
    
    async def start(self):
        """ワーカーを開始"""
        self.running = True
        for _ in range(self.max_workers):
            worker_task = asyncio.create_task(self.worker())
            self.workers.append(worker_task)
    
    async def stop(self):
        """ワーカーを停止"""
        self.running = False
        await asyncio.gather(*self.workers, return_exceptions=True)
        self.workers.clear()
    
    async def get_result(self, task_id: str, timeout: float = None) -> Any:
        """タスクの結果を取得"""
        start_time = time.time()
        
        while task_id not in self.results:
            if timeout and (time.time() - start_time) > timeout:
                raise TimeoutError(f"Task {task_id} did not complete in {timeout}s")
            await asyncio.sleep(0.1)
        
        return self.results[task_id]
```

## エラーハンドリング

### リトライとサーキットブレーカー
```python
import asyncio
from typing import TypeVar, Callable, Awaitable, Optional
from functools import wraps
import time

T = TypeVar('T')

class AsyncRetry:
    """非同期リトライデコレーター"""
    
    def __init__(
        self,
        max_attempts: int = 3,
        delay: float = 1.0,
        backoff: float = 2.0,
        exceptions: tuple = (Exception,)
    ):
        self.max_attempts = max_attempts
        self.delay = delay
        self.backoff = backoff
        self.exceptions = exceptions
    
    def __call__(self, func: Callable[..., Awaitable[T]]) -> Callable[..., Awaitable[T]]:
        @wraps(func)
        async def wrapper(*args, **kwargs) -> T:
            attempt = 1
            delay = self.delay
            
            while attempt <= self.max_attempts:
                try:
                    return await func(*args, **kwargs)
                except self.exceptions as e:
                    if attempt == self.max_attempts:
                        raise
                    
                    print(f"Attempt {attempt} failed: {e}. Retrying in {delay}s...")
                    await asyncio.sleep(delay)
                    delay *= self.backoff
                    attempt += 1
            
            raise Exception(f"Max attempts ({self.max_attempts}) exceeded")
        
        return wrapper

class AsyncCircuitBreaker:
    """非同期サーキットブレーカー"""
    
    def __init__(
        self,
        failure_threshold: int = 5,
        recovery_timeout: float = 60.0,
        expected_exception: type = Exception
    ):
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.expected_exception = expected_exception
        self.failure_count = 0
        self.last_failure_time: Optional[float] = None
        self.state = "closed"  # closed, open, half-open
    
    async def call(
        self, 
        func: Callable[..., Awaitable[T]], 
        *args, 
        **kwargs
    ) -> T:
        if self.state == "open":
            if self.last_failure_time and \
               (time.time() - self.last_failure_time) > self.recovery_timeout:
                self.state = "half-open"
            else:
                raise Exception("Circuit breaker is open")
        
        try:
            result = await func(*args, **kwargs)
            
            if self.state == "half-open":
                self.state = "closed"
                self.failure_count = 0
            
            return result
            
        except self.expected_exception as e:
            self.failure_count += 1
            self.last_failure_time = time.time()
            
            if self.failure_count >= self.failure_threshold:
                self.state = "open"
                print(f"Circuit breaker opened after {self.failure_count} failures")
            
            raise e
```

## パフォーマンス最適化

### 非同期キャッシング
```python
from functools import wraps
import hashlib
import json
from typing import Any, Optional

class AsyncCache:
    """非同期関数用キャッシュ"""
    
    def __init__(self, ttl: float = 3600):
        self.cache: dict[str, tuple[Any, float]] = {}
        self.ttl = ttl
    
    def _make_key(self, func_name: str, args: tuple, kwargs: dict) -> str:
        """キャッシュキーを生成"""
        key_data = {
            'func': func_name,
            'args': args,
            'kwargs': kwargs
        }
        key_str = json.dumps(key_data, sort_keys=True, default=str)
        return hashlib.md5(key_str.encode()).hexdigest()
    
    def cached(self, func: Callable[..., Awaitable[T]]) -> Callable[..., Awaitable[T]]:
        """キャッシュデコレーター"""
        @wraps(func)
        async def wrapper(*args, **kwargs) -> T:
            key = self._make_key(func.__name__, args, kwargs)
            
            # キャッシュチェック
            if key in self.cache:
                value, timestamp = self.cache[key]
                if time.time() - timestamp < self.ttl:
                    return value
            
            # 関数実行
            result = await func(*args, **kwargs)
            
            # キャッシュ保存
            self.cache[key] = (result, time.time())
            
            return result
        
        return wrapper
    
    def clear(self):
        """キャッシュクリア"""
        self.cache.clear()
    
    async def cleanup(self):
        """期限切れエントリを削除"""
        current_time = time.time()
        expired_keys = [
            key for key, (_, timestamp) in self.cache.items()
            if current_time - timestamp >= self.ttl
        ]
        for key in expired_keys:
            del self.cache[key]

# 使用例
cache = AsyncCache(ttl=300)

@cache.cached
async def expensive_api_call(user_id: str) -> dict:
    async with aiohttp.ClientSession() as session:
        async with session.get(f"https://api.example.com/users/{user_id}") as resp:
            return await resp.json()
```

## チェックリスト
- [ ] async/await正しく使用
- [ ] 並行実行数制御
- [ ] 適切なエラーハンドリング
- [ ] リソース管理（コンテキストマネージャー）
- [ ] タスクキャンセレーション対応
- [ ] デッドロック回避
- [ ] メモリリーク防止
- [ ] パフォーマンス最適化
- [ ] テスト容易性確保