# Async Python Concurrency Patterns

Advanced Python asynchronous, concurrent, and parallel processing patterns for production environments. Provides practical solutions leveraging asyncio, threading, and multiprocessing.

## Table of Contents

1. [Asyncio Advanced Patterns](#asyncio-advanced-patterns) - This file
2. [Concurrent Futures Patterns](./concurrent-futures.md)
3. [Threading Patterns](./threading-patterns.md)
4. [Multiprocessing Patterns](./multiprocessing-patterns.md)
5. [Hybrid Concurrency Patterns](./hybrid-concurrency.md)
6. [Performance Monitoring](./performance-monitoring.md)
7. [Error Handling Strategies](./error-handling.md)
8. [Production Examples](./production-examples.md)

## Asyncio Advanced Patterns

### 1. Advanced Asynchronous Context Managers

```python
import asyncio
import aiohttp
import time
from contextlib import asynccontextmanager
from typing import AsyncGenerator, Optional, Dict, Any
import logging

logger = logging.getLogger(__name__)

class ConnectionPoolManager:
    """High-performance connection pool management"""
    
    def __init__(self, max_connections: int = 100):
        self.max_connections = max_connections
        self.session: Optional[aiohttp.ClientSession] = None
        self.connector: Optional[aiohttp.TCPConnector] = None
        
    async def __aenter__(self):
        self.connector = aiohttp.TCPConnector(
            limit=self.max_connections,
            limit_per_host=20,
            keepalive_timeout=60,
            enable_cleanup_closed=True
        )
        
        timeout = aiohttp.ClientTimeout(
            total=30,
            connect=10,
            sock_read=10
        )
        
        self.session = aiohttp.ClientSession(
            connector=self.connector,
            timeout=timeout
        )
        
        logger.info(f"Connection pool initialized with {self.max_connections} connections")
        return self.session
        
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self.session:
            await self.session.close()
        if self.connector:
            await self.connector.close()
        logger.info("Connection pool closed")

@asynccontextmanager
async def database_transaction() -> AsyncGenerator[Dict[str, Any], None]:
    """Asynchronous database transaction management"""
    connection = None
    transaction = None
    
    try:
        # Virtual database connection
        connection = await create_connection()
        transaction = await connection.begin()
        
        logger.info("Database transaction started")
        
        yield {"connection": connection, "transaction": transaction}
        
        await transaction.commit()
        logger.info("Database transaction committed")
        
    except Exception as e:
        if transaction:
            await transaction.rollback()
        logger.error(f"Database transaction failed: {e}")
        raise
        
    finally:
        if connection:
            await connection.close()

async def create_connection():
    """Virtual database connection creation"""
    await asyncio.sleep(0.1)  # Simulate connection time
    return type('Connection', (), {
        'begin': lambda: asyncio.create_task(asyncio.sleep(0.01)),
        'close': lambda: asyncio.create_task(asyncio.sleep(0.01))
    })()
```

### 2. Asynchronous Generators and Stream Processing

```python
import asyncio
from typing import AsyncGenerator, AsyncIterable, List, Callable, Any
import json
import aiofiles

class AsyncStreamProcessor:
    """Asynchronous stream processing engine"""
    
    def __init__(self, buffer_size: int = 1000):
        self.buffer_size = buffer_size
        
    async def process_file_stream(
        self, 
        file_path: str,
        processor: Callable[[str], Any]
    ) -> AsyncGenerator[Any, None]:
        """Asynchronous file stream processing"""
        
        async with aiofiles.open(file_path, 'r') as file:
            buffer = []
            
            async for line in file:
                line = line.strip()
                if line:
                    buffer.append(line)
                    
                if len(buffer) >= self.buffer_size:
                    # Buffer processing
                    tasks = [
                        asyncio.create_task(self._process_line(line, processor))
                        for line in buffer
                    ]
                    
                    results = await asyncio.gather(*tasks, return_exceptions=True)
                    
                    for result in results:
                        if not isinstance(result, Exception):
                            yield result
                            
                    buffer.clear()
            
            # Process remaining buffer
            if buffer:
                tasks = [
                    asyncio.create_task(self._process_line(line, processor))
                    for line in buffer
                ]
                
                results = await asyncio.gather(*tasks, return_exceptions=True)
                
                for result in results:
                    if not isinstance(result, Exception):
                        yield result
    
    async def _process_line(self, line: str, processor: Callable[[str], Any]) -> Any:
        """Single line asynchronous processing"""
        # Run CPU-intensive tasks in a separate thread
        loop = asyncio.get_event_loop()
        return await loop.run_in_executor(None, processor, line)

async def json_parser(line: str) -> dict:
    """JSON parsing example"""
    try:
        return json.loads(line)
    except json.JSONDecodeError:
        return {"error": "Invalid JSON", "line": line}

# Usage example
async def stream_example():
    processor = AsyncStreamProcessor(buffer_size=500)
    
    count = 0
    async for result in processor.process_file_stream(
        "large_file.jsonl", 
        json_parser
    ):
        count += 1
        if count % 1000 == 0:
            logger.info(f"Processed {count} lines")
```

### 3. Asynchronous Task Pool

```python
import asyncio
from typing import Callable, Any, List, Optional, Coroutine
import weakref
from dataclasses import dataclass
from enum import Enum

class TaskStatus(Enum):
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"

@dataclass
class TaskResult:
    task_id: str
    status: TaskStatus
    result: Any = None
    error: Optional[Exception] = None
    execution_time: float = 0.0

class AsyncTaskPool:
    """High-performance asynchronous task pool"""
    
    def __init__(self, max_workers: int = 10):
        self.max_workers = max_workers
        self.semaphore = asyncio.Semaphore(max_workers)
        self.active_tasks: Dict[str, asyncio.Task] = {}
        self.completed_tasks: Dict[str, TaskResult] = {}
        self.task_counter = 0
        
    async def submit(
        self, 
        coro: Coroutine,
        task_id: Optional[str] = None
    ) -> str:
        """Submit task to pool"""
        
        if task_id is None:
            self.task_counter += 1
            task_id = f"task_{self.task_counter}"
            
        task = asyncio.create_task(self._execute_task(coro, task_id))
        self.active_tasks[task_id] = task
        
        # Cleanup on task completion
        task.add_done_callback(
            lambda t: self.active_tasks.pop(task_id, None)
        )
        
        return task_id
        
    async def _execute_task(self, coro: Coroutine, task_id: str) -> TaskResult:
        """Task execution and monitoring"""
        
        start_time = time.time()
        
        async with self.semaphore:
            try:
                result = await coro
                execution_time = time.time() - start_time
                
                task_result = TaskResult(
                    task_id=task_id,
                    status=TaskStatus.COMPLETED,
                    result=result,
                    execution_time=execution_time
                )
                
            except asyncio.CancelledError:
                task_result = TaskResult(
                    task_id=task_id,
                    status=TaskStatus.CANCELLED,
                    execution_time=time.time() - start_time
                )
                raise
                
            except Exception as e:
                task_result = TaskResult(
                    task_id=task_id,
                    status=TaskStatus.FAILED,
                    error=e,
                    execution_time=time.time() - start_time
                )
                
            self.completed_tasks[task_id] = task_result
            return task_result
    
    async def get_result(self, task_id: str, timeout: Optional[float] = None) -> TaskResult:
        """Get task result"""
        
        if task_id in self.completed_tasks:
            return self.completed_tasks[task_id]
            
        if task_id in self.active_tasks:
            try:
                return await asyncio.wait_for(
                    self.active_tasks[task_id], 
                    timeout=timeout
                )
            except asyncio.TimeoutError:
                raise asyncio.TimeoutError(f"Task {task_id} did not complete within {timeout} seconds")
        
        raise ValueError(f"Task {task_id} not found")
    
    async def cancel_task(self, task_id: str) -> bool:
        """Cancel task"""
        
        if task_id in self.active_tasks:
            task = self.active_tasks[task_id]
            task.cancel()
            return True
        return False
    
    async def wait_all(self, timeout: Optional[float] = None) -> List[TaskResult]:
        """Wait for all tasks to complete"""
        
        if not self.active_tasks:
            return list(self.completed_tasks.values())
            
        try:
            await asyncio.wait_for(
                asyncio.gather(*self.active_tasks.values(), return_exceptions=True),
                timeout=timeout
            )
        except asyncio.TimeoutError:
            logger.warning(f"Not all tasks completed within {timeout} seconds")
            
        return list(self.completed_tasks.values())

# Usage example
async def cpu_intensive_task(data: int) -> int:
    """CPU-intensive task example"""
    # Simulate actual processing
    await asyncio.sleep(0.1)
    return data ** 2

async def task_pool_example():
    pool = AsyncTaskPool(max_workers=5)
    
    # Submit multiple tasks
    task_ids = []
    for i in range(20):
        task_id = await pool.submit(cpu_intensive_task(i))
        task_ids.append(task_id)
    
    # Get results
    results = await pool.wait_all(timeout=10.0)
    
    for result in results:
        if result.status == TaskStatus.COMPLETED:
            logger.info(f"Task {result.task_id}: {result.result} (took {result.execution_time:.2f}s)")
```