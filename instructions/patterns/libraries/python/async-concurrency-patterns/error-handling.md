# Error Handling Strategies

## 1. Comprehensive Error Handling for Concurrent Systems

```python
import asyncio
import threading
import time
import traceback
from typing import Dict, Any, List, Optional, Callable, Union, Type
from dataclasses import dataclass, field
from enum import Enum
import logging
from collections import deque
import functools

class ErrorSeverity(Enum):
    """Error severity levels for prioritizing responses"""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"

@dataclass
class ErrorInfo:
    """Comprehensive error information container"""
    timestamp: float
    error_type: str
    error_message: str
    severity: ErrorSeverity
    traceback_str: str
    context: Dict[str, Any] = field(default_factory=dict)
    recovery_attempted: bool = False
    recovery_successful: bool = False

class ConcurrencyErrorHandler:
    """Advanced error handling system for concurrent applications"""
    
    def __init__(self, max_error_history: int = 1000):
        self.max_error_history = max_error_history
        self.error_history: deque = deque(maxlen=max_error_history)
        
        # Error statistics tracking
        self.error_counts: Dict[str, int] = {}
        self.error_rates: Dict[str, deque] = {}
        
        # Recovery and retry strategies
        self.recovery_strategies: Dict[Type[Exception], Callable] = {}
        self.retry_strategies: Dict[Type[Exception], Dict[str, Any]] = {}
        
        # Notification system
        self.error_callbacks: List[Callable[[ErrorInfo], None]] = []
        
        # Circuit breaker pattern implementation
        self.circuit_breakers: Dict[str, Dict[str, Any]] = {}
        
        # Thread safety
        self.lock = threading.RLock()
    
    def register_recovery_strategy(
        self, 
        exception_type: Type[Exception],
        recovery_func: Callable[[Exception, Dict[str, Any]], Any]
    ):
        """Register automated recovery strategy for specific exception types"""
        self.recovery_strategies[exception_type] = recovery_func
    
    def register_retry_strategy(
        self, 
        exception_type: Type[Exception],
        max_retries: int = 3,
        delay: float = 1.0,
        backoff_factor: float = 2.0,
        jitter: bool = True
    ):
        """Register retry strategy with exponential backoff for exception types"""
        self.retry_strategies[exception_type] = {
            "max_retries": max_retries,
            "delay": delay,
            "backoff_factor": backoff_factor,
            "jitter": jitter
        }
    
    def handle_error(
        self, 
        exception: Exception,
        context: Dict[str, Any] = None,
        severity: ErrorSeverity = ErrorSeverity.MEDIUM
    ) -> ErrorInfo:
        """Comprehensive error handling with recovery attempts and notifications"""
        
        if context is None:
            context = {}
        
        error_info = ErrorInfo(
            timestamp=time.time(),
            error_type=type(exception).__name__,
            error_message=str(exception),
            severity=severity,
            traceback_str=traceback.format_exc(),
            context=context
        )
        
        with self.lock:
            # Record error in history
            self.error_history.append(error_info)
            
            # Update error statistics
            self._update_error_stats(error_info)
            
            # Attempt automated recovery
            self._attempt_recovery(exception, error_info, context)
            
            # Send notifications
            self._notify_error(error_info)
        
        return error_info
    
    def _update_error_stats(self, error_info: ErrorInfo):
        """Update error statistics and rate tracking"""
        error_type = error_info.error_type
        
        # Cumulative count
        self.error_counts[error_type] = self.error_counts.get(error_type, 0) + 1
        
        # Rate tracking (last 5 minutes)
        if error_type not in self.error_rates:
            self.error_rates[error_type] = deque(maxlen=300)  # 5-minute window
        
        self.error_rates[error_type].append(error_info.timestamp)
    
    def _attempt_recovery(
        self, 
        exception: Exception, 
        error_info: ErrorInfo,
        context: Dict[str, Any]
    ):
        """Attempt automated recovery using registered strategies"""
        
        exception_type = type(exception)
        
        # Search for matching recovery strategy
        for registered_type, recovery_func in self.recovery_strategies.items():
            if issubclass(exception_type, registered_type):
                try:
                    recovery_func(exception, context)
                    error_info.recovery_attempted = True
                    error_info.recovery_successful = True
                    logging.info(f"Recovery successful for {exception_type.__name__}")
                    break
                except Exception as recovery_error:
                    logging.error(f"Recovery failed: {recovery_error}")
                    error_info.recovery_attempted = True
                    error_info.recovery_successful = False
    
    def _notify_error(self, error_info: ErrorInfo):
        """Send error notifications to registered callbacks"""
        for callback in self.error_callbacks:
            try:
                callback(error_info)
            except Exception as e:
                logging.error(f"Error callback failed: {e}")
    
    def add_error_callback(self, callback: Callable[[ErrorInfo], None]):
        """Add callback function for error notifications"""
        self.error_callbacks.append(callback)
    
    def get_error_rate(self, error_type: str, window_seconds: int = 300) -> float:
        """Calculate error rate per minute for specified time window"""
        if error_type not in self.error_rates:
            return 0.0
        
        current_time = time.time()
        cutoff_time = current_time - window_seconds
        
        recent_errors = [
            ts for ts in self.error_rates[error_type] 
            if ts >= cutoff_time
        ]
        
        return len(recent_errors) / window_seconds * 60  # errors per minute
    
    def create_circuit_breaker(
        self, 
        name: str,
        failure_threshold: int = 5,
        recovery_timeout: float = 60.0,
        expected_exception: Type[Exception] = Exception
    ):
        """Create circuit breaker for preventing cascade failures"""
        self.circuit_breakers[name] = {
            "failure_threshold": failure_threshold,
            "recovery_timeout": recovery_timeout,
            "expected_exception": expected_exception,
            "failure_count": 0,
            "last_failure_time": 0,
            "state": "closed"  # closed, open, half_open
        }
    
    def circuit_breaker_call(self, name: str, func: Callable, *args, **kwargs):
        """Execute function through circuit breaker protection"""
        if name not in self.circuit_breakers:
            raise ValueError(f"Circuit breaker {name} not found")
        
        cb = self.circuit_breakers[name]
        current_time = time.time()
        
        # Check if circuit breaker is open
        if cb["state"] == "open":
            if current_time - cb["last_failure_time"] > cb["recovery_timeout"]:
                cb["state"] = "half_open"
            else:
                raise RuntimeError(f"Circuit breaker {name} is open")
        
        try:
            result = func(*args, **kwargs)
            
            # Handle successful execution
            if cb["state"] == "half_open":
                cb["state"] = "closed"
                cb["failure_count"] = 0
            
            return result
            
        except cb["expected_exception"] as e:
            cb["failure_count"] += 1
            cb["last_failure_time"] = current_time
            
            if cb["failure_count"] >= cb["failure_threshold"]:
                cb["state"] = "open"
                logging.warning(f"Circuit breaker {name} opened due to {cb['failure_count']} failures")
            
            # Handle error through error handler
            self.handle_error(e, {"circuit_breaker": name})
            raise
    
    def get_error_summary(self) -> Dict[str, Any]:
        """Generate comprehensive error summary and statistics"""
        with self.lock:
            total_errors = len(self.error_history)
            
            if total_errors == 0:
                return {"total_errors": 0}
            
            # Statistics by severity
            severity_counts = {}
            for error in self.error_history:
                severity = error.severity.value
                severity_counts[severity] = severity_counts.get(severity, 0) + 1
            
            # Recent error rates
            recent_rates = {}
            for error_type in self.error_counts.keys():
                recent_rates[error_type] = self.get_error_rate(error_type)
            
            return {
                "total_errors": total_errors,
                "error_counts_by_type": self.error_counts.copy(),
                "error_counts_by_severity": severity_counts,
                "recent_error_rates": recent_rates,
                "circuit_breaker_states": {
                    name: cb["state"] for name, cb in self.circuit_breakers.items()
                }
            }

class RetryDecorator:
    """Intelligent retry decorator with exponential backoff and jitter"""
    
    def __init__(
        self, 
        max_retries: int = 3,
        delay: float = 1.0,
        backoff_factor: float = 2.0,
        jitter: bool = True,
        exceptions: tuple = (Exception,),
        error_handler: Optional[ConcurrencyErrorHandler] = None
    ):
        self.max_retries = max_retries
        self.delay = delay
        self.backoff_factor = backoff_factor
        self.jitter = jitter
        self.exceptions = exceptions
        self.error_handler = error_handler
    
    def __call__(self, func: Callable) -> Callable:
        if asyncio.iscoroutinefunction(func):
            return self._async_wrapper(func)
        else:
            return self._sync_wrapper(func)
    
    def _sync_wrapper(self, func: Callable) -> Callable:
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            last_exception = None
            
            for attempt in range(self.max_retries + 1):
                try:
                    return func(*args, **kwargs)
                except self.exceptions as e:
                    last_exception = e
                    
                    if self.error_handler:
                        self.error_handler.handle_error(
                            e, 
                            {"attempt": attempt, "function": func.__name__}
                        )
                    
                    if attempt < self.max_retries:
                        sleep_time = self._calculate_delay(attempt)
                        time.sleep(sleep_time)
                    else:
                        break
            
            raise last_exception
        
        return wrapper
    
    def _async_wrapper(self, func: Callable) -> Callable:
        @functools.wraps(func)
        async def wrapper(*args, **kwargs):
            last_exception = None
            
            for attempt in range(self.max_retries + 1):
                try:
                    return await func(*args, **kwargs)
                except self.exceptions as e:
                    last_exception = e
                    
                    if self.error_handler:
                        self.error_handler.handle_error(
                            e, 
                            {"attempt": attempt, "function": func.__name__}
                        )
                    
                    if attempt < self.max_retries:
                        sleep_time = self._calculate_delay(attempt)
                        await asyncio.sleep(sleep_time)
                    else:
                        break
            
            raise last_exception
        
        return wrapper
    
    def _calculate_delay(self, attempt: int) -> float:
        """Calculate delay with exponential backoff and optional jitter"""
        delay = self.delay * (self.backoff_factor ** attempt)
        
        if self.jitter:
            import random
            delay *= (0.5 + random.random())
        
        return delay

# Usage Example
def error_handling_example():
    """Demonstration of comprehensive error handling strategies"""
    error_handler = ConcurrencyErrorHandler()
    
    # Configure error notification callback
    def error_notification(error_info: ErrorInfo):
        if error_info.severity in [ErrorSeverity.HIGH, ErrorSeverity.CRITICAL]:
            print(f"🚨 CRITICAL ERROR: {error_info.error_message}")
            print(f"Context: {error_info.context}")
    
    error_handler.add_error_callback(error_notification)
    
    # Register recovery strategy
    def connection_recovery(exception: Exception, context: Dict[str, Any]):
        print(f"🔄 Attempting connection recovery for: {exception}")
        # Simulate recovery process
        time.sleep(0.1)
        print("✅ Connection recovery completed")
    
    error_handler.register_recovery_strategy(ConnectionError, connection_recovery)
    
    # Create circuit breaker
    error_handler.create_circuit_breaker(
        "database_calls",
        failure_threshold=3,
        recovery_timeout=30.0,
        expected_exception=ConnectionError
    )
    
    # Define functions with retry decorator
    @RetryDecorator(
        max_retries=3,
        delay=0.5,
        exceptions=(ValueError, ConnectionError),
        error_handler=error_handler
    )
    def unreliable_function(success_rate: float = 0.7) -> str:
        """Function that randomly fails to test retry behavior"""
        import random
        if random.random() < success_rate:
            return "✅ Success!"
        else:
            if random.random() < 0.5:
                raise ValueError("Random value error")
            else:
                raise ConnectionError("Random connection error")
    
    def circuit_breaker_function():
        """Function for testing circuit breaker behavior"""
        import random
        if random.random() < 0.3:
            raise ConnectionError("Database connection failed")
        return "✅ Database query successful"
    
    # Test execution
    async def run_error_handling_tests():
        print("🧪 Starting error handling tests...\n")
        
        # Test retry decorator
        print("📝 Testing retry decorator:")
        for i in range(10):
            try:
                result = unreliable_function(success_rate=0.5)
                print(f"Call {i}: {result}")
            except Exception as e:
                print(f"❌ Call {i} failed: {e}")
        
        print("\n📝 Testing circuit breaker:")
        # Test circuit breaker
        for i in range(15):
            try:
                result = error_handler.circuit_breaker_call(
                    "database_calls",
                    circuit_breaker_function
                )
                print(f"Call {i}: {result}")
            except Exception as e:
                print(f"❌ Circuit breaker call {i} failed: {e}")
            
            await asyncio.sleep(0.1)
        
        # Display error summary
        print("\n📊 Error Summary:")
        summary = error_handler.get_error_summary()
        for key, value in summary.items():
            print(f"  {key}: {value}")
        
        print("\n✅ Error handling tests completed")
    
    # Execute the tests
    asyncio.run(run_error_handling_tests())

if __name__ == "__main__":
    error_handling_example()
```