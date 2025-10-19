# Concurrent Futures Patterns

## 1. Advanced ThreadPoolExecutor Usage

```python
import concurrent.futures
import threading
import time
from typing import Callable, List, Any, Dict, Optional
import queue
import psutil
import os

class AdaptiveThreadPool:
    """Adaptive thread pool"""
    
    def __init__(
        self, 
        min_workers: int = 2,
        max_workers: Optional[int] = None,
        cpu_threshold: float = 80.0
    ):
        self.min_workers = min_workers
        self.max_workers = max_workers or (os.cpu_count() * 2)
        self.cpu_threshold = cpu_threshold
        self.current_workers = min_workers
        
        self.executor = concurrent.futures.ThreadPoolExecutor(
            max_workers=self.current_workers
        )
        
        self.monitoring_thread = threading.Thread(
            target=self._monitor_performance,
            daemon=True
        )
        self.monitoring_thread.start()
        
        self.task_queue = queue.Queue()
        self.performance_metrics = {
            "cpu_usage": [],
            "queue_size": [],
            "completed_tasks": 0,
            "failed_tasks": 0
        }
        
    def _monitor_performance(self):
        """Performance monitoring and dynamic adjustment"""
        
        while True:
            try:
                cpu_percent = psutil.cpu_percent(interval=1)
                queue_size = self.task_queue.qsize()
                
                self.performance_metrics["cpu_usage"].append(cpu_percent)
                self.performance_metrics["queue_size"].append(queue_size)
                
                # Keep latest 10 samples
                if len(self.performance_metrics["cpu_usage"]) > 10:
                    self.performance_metrics["cpu_usage"].pop(0)
                    self.performance_metrics["queue_size"].pop(0)
                
                avg_cpu = sum(self.performance_metrics["cpu_usage"]) / len(self.performance_metrics["cpu_usage"])
                avg_queue = sum(self.performance_metrics["queue_size"]) / len(self.performance_metrics["queue_size"])
                
                # Dynamic scaling
                if avg_cpu < self.cpu_threshold and avg_queue > 5 and self.current_workers < self.max_workers:
                    self._scale_up()
                elif avg_cpu > self.cpu_threshold and self.current_workers > self.min_workers:
                    self._scale_down()
                    
            except Exception as e:
                logger.error(f"Performance monitoring error: {e}")
                
            time.sleep(5)
    
    def _scale_up(self):
        """Scale up thread pool"""
        new_workers = min(self.current_workers + 1, self.max_workers)
        if new_workers != self.current_workers:
            old_executor = self.executor
            self.executor = concurrent.futures.ThreadPoolExecutor(max_workers=new_workers)
            self.current_workers = new_workers
            
            # Gracefully shutdown old executor
            threading.Thread(target=old_executor.shutdown, args=(True,), daemon=True).start()
            logger.info(f"Scaled up to {new_workers} workers")
    
    def _scale_down(self):
        """Scale down thread pool"""
        new_workers = max(self.current_workers - 1, self.min_workers)
        if new_workers != self.current_workers:
            old_executor = self.executor
            self.executor = concurrent.futures.ThreadPoolExecutor(max_workers=new_workers)
            self.current_workers = new_workers
            
            # Gracefully shutdown old executor
            threading.Thread(target=old_executor.shutdown, args=(True,), daemon=True).start()
            logger.info(f"Scaled down to {new_workers} workers")
    
    def submit(self, fn: Callable, *args, **kwargs) -> concurrent.futures.Future:
        """Submit task"""
        future = self.executor.submit(fn, *args, **kwargs)
        self.task_queue.put(future)
        
        # Completion callback
        future.add_done_callback(self._task_completed)
        
        return future
    
    def _task_completed(self, future: concurrent.futures.Future):
        """Task completion handler"""
        try:
            self.task_queue.get_nowait()
        except queue.Empty:
            pass
            
        if future.exception() is None:
            self.performance_metrics["completed_tasks"] += 1
        else:
            self.performance_metrics["failed_tasks"] += 1
    
    def shutdown(self, wait: bool = True):
        """Shutdown pool"""
        self.executor.shutdown(wait=wait)
        
    def get_stats(self) -> Dict[str, Any]:
        """Get performance statistics"""
        return {
            "current_workers": self.current_workers,
            "queue_size": self.task_queue.qsize(),
            "completed_tasks": self.performance_metrics["completed_tasks"],
            "failed_tasks": self.performance_metrics["failed_tasks"],
            "avg_cpu_usage": sum(self.performance_metrics["cpu_usage"]) / len(self.performance_metrics["cpu_usage"]) if self.performance_metrics["cpu_usage"] else 0,
            "avg_queue_size": sum(self.performance_metrics["queue_size"]) / len(self.performance_metrics["queue_size"]) if self.performance_metrics["queue_size"] else 0
        }

def cpu_intensive_computation(data: int) -> int:
    """CPU-intensive computation example"""
    result = 0
    for i in range(data * 1000):
        result += i ** 0.5
    return int(result)

# Usage example
def adaptive_pool_example():
    pool = AdaptiveThreadPool(min_workers=2, max_workers=8)
    
    futures = []
    for i in range(100):
        future = pool.submit(cpu_intensive_computation, i % 10 + 1)
        futures.append(future)
    
    # Get results
    results = []
    for future in concurrent.futures.as_completed(futures, timeout=60):
        try:
            result = future.result()
            results.append(result)
        except Exception as e:
            logger.error(f"Task failed: {e}")
    
    stats = pool.get_stats()
    logger.info(f"Pool statistics: {stats}")
    
    pool.shutdown()
    return results
```

## 2. Advanced ProcessPoolExecutor Usage

```python
import concurrent.futures
import multiprocessing
import pickle
import os
import sys
from typing import List, Dict, Any, Callable, Optional
import numpy as np
import time

class OptimizedProcessPool:
    """Optimized process pool"""
    
    def __init__(
        self, 
        max_workers: Optional[int] = None,
        initializer: Optional[Callable] = None,
        initargs: tuple = (),
        chunk_size: int = 1
    ):
        self.max_workers = max_workers or multiprocessing.cpu_count()
        self.chunk_size = chunk_size
        
        # Optimize inter-process communication
        multiprocessing.set_start_method('spawn', force=True)
        
        self.executor = concurrent.futures.ProcessPoolExecutor(
            max_workers=self.max_workers,
            initializer=initializer,
            initargs=initargs
        )
        
        self.shared_state = multiprocessing.Manager().dict()
        
    def map_chunked(
        self, 
        func: Callable, 
        iterable: List[Any],
        chunk_size: Optional[int] = None
    ) -> List[Any]:
        """Parallel mapping with chunking"""
        
        chunk_size = chunk_size or self.chunk_size
        chunks = [iterable[i:i + chunk_size] for i in range(0, len(iterable), chunk_size)]
        
        # Chunk processing function
        def process_chunk(chunk):
            return [func(item) for item in chunk]
        
        # Parallel execution
        futures = [self.executor.submit(process_chunk, chunk) for chunk in chunks]
        
        results = []
        for future in concurrent.futures.as_completed(futures):
            try:
                chunk_results = future.result()
                results.extend(chunk_results)
            except Exception as e:
                logger.error(f"Chunk processing failed: {e}")
                raise
        
        return results
    
    def map_with_progress(
        self, 
        func: Callable, 
        iterable: List[Any],
        progress_callback: Optional[Callable[[int, int], None]] = None
    ) -> List[Any]:
        """Mapping with progress monitoring"""
        
        total_items = len(iterable)
        completed = 0
        
        futures = [self.executor.submit(func, item) for item in iterable]
        
        results = []
        for future in concurrent.futures.as_completed(futures):
            try:
                result = future.result()
                results.append(result)
                completed += 1
                
                if progress_callback:
                    progress_callback(completed, total_items)
                    
            except Exception as e:
                logger.error(f"Task failed: {e}")
                completed += 1
                
                if progress_callback:
                    progress_callback(completed, total_items)
                    
                raise
        
        return results
    
    def reduce_distributed(
        self, 
        map_func: Callable,
        reduce_func: Callable,
        iterable: List[Any],
        chunk_size: Optional[int] = None
    ) -> Any:
        """Distributed MapReduce"""
        
        # Map phase
        mapped_results = self.map_chunked(map_func, iterable, chunk_size)
        
        # Reduce phase (progressive reduction)
        while len(mapped_results) > 1:
            chunk_size = max(1, len(mapped_results) // self.max_workers)
            chunks = [
                mapped_results[i:i + chunk_size] 
                for i in range(0, len(mapped_results), chunk_size)
            ]
            
            def reduce_chunk(chunk):
                result = chunk[0]
                for item in chunk[1:]:
                    result = reduce_func(result, item)
                return result
            
            futures = [self.executor.submit(reduce_chunk, chunk) for chunk in chunks]
            mapped_results = [future.result() for future in futures]
        
        return mapped_results[0] if mapped_results else None
    
    def shutdown(self, wait: bool = True):
        """Shutdown pool"""
        self.executor.shutdown(wait=wait)

# Heavy computation examples
def matrix_multiplication(matrices_data):
    """Matrix multiplication computation"""
    a, b = matrices_data
    return np.dot(a, b)

def fibonacci(n):
    """Fibonacci sequence (CPU-intensive)"""
    if n <= 1:
        return n
    return fibonacci(n - 1) + fibonacci(n - 2)

def sum_reducer(a, b):
    """Sum reduction function"""
    return a + b

# Usage example
def process_pool_example():
    pool = OptimizedProcessPool(max_workers=4)
    
    # Parallel matrix calculations
    matrices = []
    for _ in range(20):
        a = np.random.rand(100, 100)
        b = np.random.rand(100, 100)
        matrices.append((a, b))
    
    def progress_callback(completed, total):
        print(f"Progress: {completed}/{total} ({completed/total*100:.1f}%)")
    
    start_time = time.time()
    results = pool.map_with_progress(
        matrix_multiplication, 
        matrices,
        progress_callback=progress_callback
    )
    
    execution_time = time.time() - start_time
    logger.info(f"Matrix calculations completed in {execution_time:.2f} seconds")
    
    # MapReduce example
    numbers = list(range(1, 101))
    
    # Square each number (Map function)
    def square_map(x):
        return x ** 2
    
    total_sum = pool.reduce_distributed(
        map_func=square_map,
        reduce_func=sum_reducer,
        iterable=numbers,
        chunk_size=10
    )
    
    logger.info(f"Sum of squares (1-100): {total_sum}")
    
    pool.shutdown()
    return results, total_sum
```