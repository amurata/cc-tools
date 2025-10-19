# Hybrid Concurrency Patterns

## 1. Async + Threading Hybrid

```python
import asyncio
import threading
import concurrent.futures
from typing import Awaitable, Callable, Any, Dict, List, Optional
import time
import queue
import weakref

class AsyncThreadBridge:
    """Bridge between async and threading"""
    
    def __init__(self, max_thread_workers: int = 10):
        self.max_thread_workers = max_thread_workers
        self.thread_executor = concurrent.futures.ThreadPoolExecutor(
            max_workers=max_thread_workers
        )
        
        # Manage thread execution results in async context
        self.pending_tasks: Dict[str, asyncio.Future] = {}
        self.task_counter = 0
        
    async def run_in_thread(
        self, 
        func: Callable, 
        *args, 
        **kwargs
    ) -> Any:
        """Run thread function in async context"""
        
        loop = asyncio.get_event_loop()
        return await loop.run_in_executor(
            self.thread_executor, 
            func, 
            *args, 
            **kwargs
        )
    
    def run_async_in_thread(
        self, 
        coro: Awaitable, 
        callback: Optional[Callable[[Any], None]] = None
    ) -> str:
        """Run async function in thread context"""
        
        task_id = f"async_task_{self.task_counter}"
        self.task_counter += 1
        
        def thread_runner():
            # Create new event loop
            new_loop = asyncio.new_event_loop()
            asyncio.set_event_loop(new_loop)
            
            try:
                result = new_loop.run_until_complete(coro)
                if callback:
                    callback(result)
                return result
            finally:
                new_loop.close()
        
        future = self.thread_executor.submit(thread_runner)
        return task_id
    
    async def cpu_intensive_with_progress(
        self, 
        func: Callable,
        data: List[Any],
        chunk_size: int = 10,
        progress_callback: Optional[Callable[[int, int], None]] = None
    ) -> List[Any]:
        """Parallel execution of CPU-intensive tasks with progress monitoring"""
        
        chunks = [data[i:i + chunk_size] for i in range(0, len(data), chunk_size)]
        completed = 0
        results = []
        
        # Process chunks in threads
        async def process_chunk(chunk):
            nonlocal completed
            
            chunk_result = await self.run_in_thread(
                lambda: [func(item) for item in chunk]
            )
            
            completed += len(chunk)
            if progress_callback:
                progress_callback(completed, len(data))
                
            return chunk_result
        
        # Parallel execution
        tasks = [process_chunk(chunk) for chunk in chunks]
        chunk_results = await asyncio.gather(*tasks)
        
        # Flatten results
        for chunk_result in chunk_results:
            results.extend(chunk_result)
        
        return results
    
    def shutdown(self, wait: bool = True):
        """Shutdown executor"""
        self.thread_executor.shutdown(wait=wait)

class HybridWorkerPool:
    """Hybrid worker pool (async + thread)"""
    
    def __init__(
        self, 
        async_workers: int = 5,
        thread_workers: int = 5
    ):
        self.async_workers = async_workers
        self.thread_workers = thread_workers
        
        self.bridge = AsyncThreadBridge(max_thread_workers=thread_workers)
        self.async_semaphore = asyncio.Semaphore(async_workers)
        
        # Task queues
        self.async_queue: asyncio.Queue = asyncio.Queue()
        self.thread_queue: queue.Queue = queue.Queue()
        
        # Worker management
        self.async_worker_tasks: List[asyncio.Task] = []
        self.thread_workers_active = threading.Event()
        self.thread_worker_threads: List[threading.Thread] = []
        
        # Statistics
        self.stats = {
            "async_tasks_completed": 0,
            "thread_tasks_completed": 0,
            "errors": 0
        }
        
    async def start_workers(self):
        """Start workers"""
        
        # Start async workers
        for i in range(self.async_workers):
            task = asyncio.create_task(self._async_worker(f"async_worker_{i}"))
            self.async_worker_tasks.append(task)
        
        # Start thread workers
        self.thread_workers_active.set()
        for i in range(self.thread_workers):
            thread = threading.Thread(
                target=self._thread_worker,
                args=(f"thread_worker_{i}",),
                daemon=True
            )
            thread.start()
            self.thread_worker_threads.append(thread)
    
    async def _async_worker(self, worker_id: str):
        """Async worker"""
        
        while True:
            try:
                # Control concurrent execution with semaphore
                async with self.async_semaphore:
                    try:
                        task_data = await asyncio.wait_for(
                            self.async_queue.get(), 
                            timeout=1.0
                        )
                    except asyncio.TimeoutError:
                        continue
                    
                    if task_data is None:  # Shutdown signal
                        break
                    
                    func, args, kwargs, callback = task_data
                    
                    try:
                        if asyncio.iscoroutinefunction(func):
                            result = await func(*args, **kwargs)
                        else:
                            result = func(*args, **kwargs)
                        
                        if callback:
                            await callback(result)
                            
                        self.stats["async_tasks_completed"] += 1
                        
                    except Exception as e:
                        self.stats["errors"] += 1
                        logger.error(f"Async task error in {worker_id}: {e}")
                        
                    finally:
                        self.async_queue.task_done()
                        
            except Exception as e:
                logger.error(f"Async worker {worker_id} error: {e}")
    
    def _thread_worker(self, worker_id: str):
        """Thread worker"""
        
        while self.thread_workers_active.is_set():
            try:
                try:
                    task_data = self.thread_queue.get(timeout=1.0)
                except queue.Empty:
                    continue
                
                if task_data is None:  # Shutdown signal
                    break
                
                func, args, kwargs, callback = task_data
                
                try:
                    result = func(*args, **kwargs)
                    
                    if callback:
                        callback(result)
                        
                    self.stats["thread_tasks_completed"] += 1
                    
                except Exception as e:
                    self.stats["errors"] += 1
                    logger.error(f"Thread task error in {worker_id}: {e}")
                    
                finally:
                    self.thread_queue.task_done()
                    
            except Exception as e:
                logger.error(f"Thread worker {worker_id} error: {e}")
    
    async def submit_async_task(
        self, 
        func: Callable,
        *args,
        callback: Optional[Callable] = None,
        **kwargs
    ):
        """Submit async task"""
        await self.async_queue.put((func, args, kwargs, callback))
    
    def submit_thread_task(
        self, 
        func: Callable,
        *args,
        callback: Optional[Callable] = None,
        **kwargs
    ):
        """Submit thread task"""
        self.thread_queue.put((func, args, kwargs, callback))
    
    async def submit_cpu_intensive(
        self, 
        func: Callable,
        *args,
        **kwargs
    ) -> Any:
        """Submit CPU-intensive task (returns result)"""
        return await self.bridge.run_in_thread(func, *args, **kwargs)
    
    async def wait_completion(self, timeout: Optional[float] = None):
        """Wait for all tasks to complete"""
        
        async_wait = self.async_queue.join()
        thread_wait = asyncio.create_task(
            asyncio.to_thread(self.thread_queue.join)
        )
        
        if timeout:
            await asyncio.wait_for(
                asyncio.gather(async_wait, thread_wait),
                timeout=timeout
            )
        else:
            await asyncio.gather(async_wait, thread_wait)
    
    async def shutdown(self):
        """Shutdown pool"""
        
        # Stop async workers
        for _ in range(self.async_workers):
            await self.async_queue.put(None)
        
        await asyncio.gather(*self.async_worker_tasks, return_exceptions=True)
        
        # Stop thread workers
        self.thread_workers_active.clear()
        
        for _ in range(self.thread_workers):
            self.thread_queue.put(None)
        
        for thread in self.thread_worker_threads:
            thread.join(timeout=5.0)
        
        self.bridge.shutdown()
    
    def get_stats(self) -> Dict[str, Any]:
        """Get statistics"""
        return {
            **self.stats,
            "async_queue_size": self.async_queue.qsize(),
            "thread_queue_size": self.thread_queue.qsize(),
            "active_async_workers": len([t for t in self.async_worker_tasks if not t.done()]),
            "active_thread_workers": len([t for t in self.thread_worker_threads if t.is_alive()])
        }

# CPU-intensive function example
def fibonacci_cpu(n: int) -> int:
    """CPU-intensive Fibonacci calculation"""
    if n <= 1:
        return n
    return fibonacci_cpu(n - 1) + fibonacci_cpu(n - 2)

async def network_request(url: str) -> dict:
    """Network request simulation"""
    await asyncio.sleep(0.1)  # Simulate network delay
    return {"url": url, "status": 200, "data": f"response_from_{url}"}

# Usage example
async def hybrid_example():
    pool = HybridWorkerPool(async_workers=3, thread_workers=2)
    
    # Start workers
    await pool.start_workers()
    
    # Submit async tasks (I/O bound)
    urls = [f"https://api{i}.example.com" for i in range(10)]
    
    results = []
    
    def collect_result(result):
        results.append(result)
    
    for url in urls:
        await pool.submit_async_task(
            network_request, 
            url, 
            callback=collect_result
        )
    
    # Submit CPU-intensive tasks (separate thread execution)
    cpu_results = []
    
    def collect_cpu_result(result):
        cpu_results.append(result)
    
    for n in range(5, 15):
        pool.submit_thread_task(
            fibonacci_cpu, 
            n, 
            callback=collect_cpu_result
        )
    
    # Mixed task example (get results directly)
    mixed_tasks = []
    for i in range(5):
        if i % 2 == 0:
            # Async task
            task = asyncio.create_task(network_request(f"https://mixed{i}.example.com"))
        else:
            # CPU-intensive task
            task = asyncio.create_task(pool.submit_cpu_intensive(fibonacci_cpu, 10 + i))
        
        mixed_tasks.append(task)
    
    # Wait for all tasks to complete
    await pool.wait_completion(timeout=10.0)
    
    # Get mixed task results
    mixed_results = await asyncio.gather(*mixed_tasks)
    
    # Display statistics
    stats = pool.get_stats()
    logger.info(f"Pool statistics: {stats}")
    logger.info(f"Async results: {len(results)}")
    logger.info(f"CPU results: {len(cpu_results)}")
    logger.info(f"Mixed results: {len(mixed_results)}")
    
    # Shutdown pool
    await pool.shutdown()
    
    return results, cpu_results, mixed_results
```