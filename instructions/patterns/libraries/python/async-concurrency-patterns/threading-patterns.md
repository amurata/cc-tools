# Threading Patterns

## 1. Advanced Thread Synchronization

```python
import threading
import time
import queue
from typing import Dict, Any, List, Optional, Callable
from dataclasses import dataclass
from enum import Enum
import weakref

class ThreadState(Enum):
    CREATED = "created"
    RUNNING = "running"
    PAUSED = "paused"
    STOPPED = "stopped"
    ERROR = "error"

@dataclass
class ThreadMetrics:
    thread_id: str
    state: ThreadState
    start_time: Optional[float] = None
    end_time: Optional[float] = None
    cpu_time: float = 0.0
    tasks_completed: int = 0
    errors: int = 0

class AdvancedThreadManager:
    """Advanced thread management system"""
    
    def __init__(self):
        self.threads: Dict[str, threading.Thread] = {}
        self.thread_metrics: Dict[str, ThreadMetrics] = {}
        self.shutdown_event = threading.Event()
        self.condition = threading.Condition()
        
        # Inter-thread communication
        self.message_queues: Dict[str, queue.Queue] = {}
        self.broadcast_queue: queue.Queue = queue.Queue()
        
        # Monitoring
        self.monitor_thread = threading.Thread(
            target=self._monitor_threads,
            daemon=True
        )
        self.monitor_thread.start()
    
    def create_worker_thread(
        self, 
        thread_id: str,
        target: Callable,
        args: tuple = (),
        kwargs: Dict[str, Any] = None,
        daemon: bool = True
    ) -> str:
        """Create worker thread"""
        
        if kwargs is None:
            kwargs = {}
            
        if thread_id in self.threads:
            raise ValueError(f"Thread {thread_id} already exists")
        
        # Create message queue
        self.message_queues[thread_id] = queue.Queue()
        
        # Initialize metrics
        self.thread_metrics[thread_id] = ThreadMetrics(
            thread_id=thread_id,
            state=ThreadState.CREATED
        )
        
        # Wrapped target function
        def wrapped_target():
            try:
                self.thread_metrics[thread_id].state = ThreadState.RUNNING
                self.thread_metrics[thread_id].start_time = time.time()
                
                # Execute actual task
                target(*args, **kwargs)
                
                self.thread_metrics[thread_id].state = ThreadState.STOPPED
                
            except Exception as e:
                self.thread_metrics[thread_id].state = ThreadState.ERROR
                self.thread_metrics[thread_id].errors += 1
                logger.error(f"Thread {thread_id} error: {e}")
                
            finally:
                self.thread_metrics[thread_id].end_time = time.time()
        
        # Create thread
        thread = threading.Thread(
            target=wrapped_target,
            name=thread_id,
            daemon=daemon
        )
        
        self.threads[thread_id] = thread
        return thread_id
    
    def start_thread(self, thread_id: str):
        """Start thread"""
        if thread_id in self.threads:
            self.threads[thread_id].start()
        else:
            raise ValueError(f"Thread {thread_id} not found")
    
    def pause_thread(self, thread_id: str):
        """Pause thread (cooperative)"""
        if thread_id in self.thread_metrics:
            self.thread_metrics[thread_id].state = ThreadState.PAUSED
    
    def resume_thread(self, thread_id: str):
        """Resume thread"""
        if thread_id in self.thread_metrics:
            self.thread_metrics[thread_id].state = ThreadState.RUNNING
            
        with self.condition:
            self.condition.notify_all()
    
    def send_message(self, thread_id: str, message: Any):
        """Send message to specific thread"""
        if thread_id in self.message_queues:
            self.message_queues[thread_id].put(message)
        else:
            raise ValueError(f"Thread {thread_id} not found")
    
    def broadcast_message(self, message: Any):
        """Broadcast message to all threads"""
        self.broadcast_queue.put(message)
    
    def get_message(self, thread_id: str, timeout: Optional[float] = None) -> Any:
        """Receive message"""
        if thread_id in self.message_queues:
            try:
                return self.message_queues[thread_id].get(timeout=timeout)
            except queue.Empty:
                return None
        else:
            raise ValueError(f"Thread {thread_id} not found")
    
    def check_pause_point(self, thread_id: str):
        """Check pause point (called within thread)"""
        if thread_id in self.thread_metrics:
            metrics = self.thread_metrics[thread_id]
            
            if metrics.state == ThreadState.PAUSED:
                with self.condition:
                    while metrics.state == ThreadState.PAUSED and not self.shutdown_event.is_set():
                        self.condition.wait(timeout=1.0)
    
    def _monitor_threads(self):
        """Thread monitoring loop"""
        while not self.shutdown_event.is_set():
            try:
                # Cleanup dead threads
                dead_threads = []
                for thread_id, thread in self.threads.items():
                    if not thread.is_alive() and thread.ident is not None:
                        dead_threads.append(thread_id)
                
                for thread_id in dead_threads:
                    self._cleanup_thread(thread_id)
                
                # Distribute broadcast messages
                try:
                    message = self.broadcast_queue.get_nowait()
                    for thread_id in self.message_queues:
                        self.message_queues[thread_id].put(message)
                except queue.Empty:
                    pass
                
            except Exception as e:
                logger.error(f"Thread monitoring error: {e}")
                
            time.sleep(1.0)
    
    def _cleanup_thread(self, thread_id: str):
        """Thread cleanup"""
        if thread_id in self.threads:
            del self.threads[thread_id]
        if thread_id in self.message_queues:
            del self.message_queues[thread_id]
        
        logger.info(f"Cleaned up thread {thread_id}")
    
    def get_thread_metrics(self, thread_id: Optional[str] = None) -> Dict[str, ThreadMetrics]:
        """Get thread metrics"""
        if thread_id:
            return {thread_id: self.thread_metrics.get(thread_id)}
        return self.thread_metrics.copy()
    
    def shutdown(self, timeout: float = 10.0):
        """Shutdown all threads"""
        self.shutdown_event.set()
        
        # Wait for all threads to terminate
        for thread_id, thread in self.threads.items():
            if thread.is_alive():
                thread.join(timeout=timeout / len(self.threads))
                
                if thread.is_alive():
                    logger.warning(f"Thread {thread_id} did not terminate gracefully")

# Worker function example
def data_processor_worker(thread_manager: AdvancedThreadManager, thread_id: str, data_source: str):
    """Data processing worker example"""
    
    processed_count = 0
    
    while not thread_manager.shutdown_event.is_set():
        # Check pause point
        thread_manager.check_pause_point(thread_id)
        
        # Check messages
        message = thread_manager.get_message(thread_id, timeout=0.1)
        if message:
            if message == "pause":
                thread_manager.pause_thread(thread_id)
                continue
            elif message == "shutdown":
                break
        
        # Simulate data processing
        time.sleep(0.1)
        processed_count += 1
        
        if processed_count % 10 == 0:
            logger.info(f"Thread {thread_id} processed {processed_count} items")
            
        # Update metrics
        thread_manager.thread_metrics[thread_id].tasks_completed = processed_count

# Usage example
def threading_example():
    manager = AdvancedThreadManager()
    
    # Create multiple worker threads
    thread_ids = []
    for i in range(3):
        thread_id = f"worker_{i}"
        manager.create_worker_thread(
            thread_id,
            data_processor_worker,
            args=(manager, thread_id, f"data_source_{i}")
        )
        thread_ids.append(thread_id)
    
    # Start threads
    for thread_id in thread_ids:
        manager.start_thread(thread_id)
    
    # Pause one thread after 5 seconds
    time.sleep(5)
    manager.send_message("worker_1", "pause")
    
    # Resume after 3 more seconds
    time.sleep(3)
    manager.resume_thread("worker_1")
    
    # Run for 10 seconds total then shutdown
    time.sleep(7)
    manager.broadcast_message("shutdown")
    
    # Display metrics
    metrics = manager.get_thread_metrics()
    for thread_id, metric in metrics.items():
        logger.info(f"Thread {thread_id}: {metric.tasks_completed} tasks completed")
    
    manager.shutdown()
```