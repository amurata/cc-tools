# Streaming Data Patterns

Real-time data streaming and event processing patterns.

## Stream Processing Fundamentals

### Basic Stream Processor
```python
from typing import Any, Callable, Optional
from dataclasses import dataclass
from abc import ABC, abstractmethod
import asyncio
from collections import deque

@dataclass
class Event:
    id: str
    timestamp: float
    data: Any
    metadata: dict = None

class StreamProcessor(ABC):
    @abstractmethod
    async def process(self, event: Event) -> Optional[Event]:
        pass

class Pipeline:
    def __init__(self):
        self.processors = []
    
    def add_processor(self, processor: StreamProcessor):
        self.processors.append(processor)
        return self
    
    async def process_event(self, event: Event) -> Optional[Event]:
        for processor in self.processors:
            event = await processor.process(event)
            if event is None:
                break
        return event
```

## Kafka Patterns

### Producer Pattern
```python
from kafka import KafkaProducer
import json

class EventProducer:
    def __init__(self, bootstrap_servers: str):
        self.producer = KafkaProducer(
            bootstrap_servers=bootstrap_servers,
            value_serializer=lambda v: json.dumps(v).encode('utf-8'),
            key_serializer=lambda k: k.encode('utf-8') if k else None,
            compression_type='gzip',
            batch_size=16384,
            linger_ms=10,
            buffer_memory=33554432,
            retries=3
        )
    
    def send_event(self, topic: str, event: dict, key: str = None):
        future = self.producer.send(
            topic=topic,
            value=event,
            key=key,
            timestamp_ms=int(time.time() * 1000)
        )
        return future
    
    def send_batch(self, topic: str, events: list):
        futures = []
        for event in events:
            future = self.send_event(topic, event)
            futures.append(future)
        
        # Wait for all messages to be sent
        for future in futures:
            future.get(timeout=10)
    
    def close(self):
        self.producer.flush()
        self.producer.close()
```

### Consumer Pattern
```python
from kafka import KafkaConsumer, TopicPartition
from kafka.errors import KafkaError

class EventConsumer:
    def __init__(self, topics: list, bootstrap_servers: str, group_id: str):
        self.consumer = KafkaConsumer(
            *topics,
            bootstrap_servers=bootstrap_servers,
            group_id=group_id,
            auto_offset_reset='earliest',
            enable_auto_commit=False,
            value_deserializer=lambda m: json.loads(m.decode('utf-8')),
            session_timeout_ms=30000,
            heartbeat_interval_ms=10000,
            max_poll_records=100
        )
        self.running = True
    
    async def consume(self, handler: Callable):
        while self.running:
            try:
                messages = self.consumer.poll(timeout_ms=1000)
                
                for topic_partition, records in messages.items():
                    for record in records:
                        try:
                            await handler(record.value)
                            
                            # Commit offset after successful processing
                            self.consumer.commit_async()
                        except Exception as e:
                            # Handle processing error
                            await self.handle_error(e, record)
                            
            except KafkaError as e:
                print(f"Kafka error: {e}")
    
    async def handle_error(self, error: Exception, record):
        # Send to DLQ or retry
        pass
```

## Window Operations

### Time Windows
```python
from collections import defaultdict
from datetime import datetime, timedelta

class WindowAggregator:
    def __init__(self, window_size_seconds: int):
        self.window_size = timedelta(seconds=window_size_seconds)
        self.windows = defaultdict(list)
    
    def add_event(self, event: Event):
        # Determine window
        window_start = self._get_window_start(event.timestamp)
        self.windows[window_start].append(event)
        
        # Clean old windows
        self._cleanup_old_windows()
    
    def _get_window_start(self, timestamp: float) -> datetime:
        dt = datetime.fromtimestamp(timestamp)
        window_seconds = self.window_size.total_seconds()
        window_start_timestamp = (int(timestamp / window_seconds) * window_seconds)
        return datetime.fromtimestamp(window_start_timestamp)
    
    def _cleanup_old_windows(self):
        current_time = datetime.now()
        cutoff_time = current_time - self.window_size * 2
        
        old_windows = [
            window for window in self.windows
            if window < cutoff_time
        ]
        
        for window in old_windows:
            del self.windows[window]
    
    def get_window_aggregates(self):
        aggregates = {}
        
        for window, events in self.windows.items():
            aggregates[window] = {
                'count': len(events),
                'sum': sum(e.data.get('value', 0) for e in events),
                'avg': sum(e.data.get('value', 0) for e in events) / len(events) if events else 0
            }
        
        return aggregates
```

### Sliding Windows
```python
class SlidingWindow:
    def __init__(self, window_size: int, slide_interval: int):
        self.window_size = window_size
        self.slide_interval = slide_interval
        self.buffer = deque()
    
    def process(self, event: Event):
        current_time = event.timestamp
        
        # Add event to buffer
        self.buffer.append(event)
        
        # Remove old events
        while self.buffer and self.buffer[0].timestamp < current_time - self.window_size:
            self.buffer.popleft()
        
        # Check if we should emit window
        if self._should_emit(current_time):
            return self._compute_window_result()
        
        return None
    
    def _should_emit(self, current_time: float) -> bool:
        # Emit based on slide interval
        return int(current_time / self.slide_interval) > self.last_emit_time / self.slide_interval
    
    def _compute_window_result(self):
        return {
            'window_start': self.buffer[0].timestamp if self.buffer else None,
            'window_end': self.buffer[-1].timestamp if self.buffer else None,
            'count': len(self.buffer),
            'events': list(self.buffer)
        }
```

## State Management

### Stateful Processing
```python
class StatefulProcessor:
    def __init__(self):
        self.state = {}
        self.checkpoints = []
    
    async def process_with_state(self, event: Event):
        key = event.data.get('key')
        
        # Get current state
        current_state = self.state.get(key, self._initial_state())
        
        # Process event and update state
        new_state = await self._update_state(current_state, event)
        self.state[key] = new_state
        
        # Checkpoint periodically
        if self._should_checkpoint():
            await self._save_checkpoint()
        
        return new_state
    
    def _initial_state(self):
        return {
            'count': 0,
            'sum': 0,
            'last_seen': None
        }
    
    async def _update_state(self, state: dict, event: Event):
        return {
            'count': state['count'] + 1,
            'sum': state['sum'] + event.data.get('value', 0),
            'last_seen': event.timestamp
        }
    
    def _should_checkpoint(self) -> bool:
        # Checkpoint every 1000 events or 60 seconds
        return len(self.state) % 1000 == 0
    
    async def _save_checkpoint(self):
        checkpoint = {
            'timestamp': time.time(),
            'state': self.state.copy()
        }
        self.checkpoints.append(checkpoint)
```

## Complex Event Processing

### Pattern Detection
```python
class PatternDetector:
    def __init__(self, pattern_rules: dict):
        self.pattern_rules = pattern_rules
        self.event_buffer = deque(maxlen=1000)
        self.detected_patterns = []
    
    def detect(self, event: Event):
        self.event_buffer.append(event)
        
        for pattern_name, rule in self.pattern_rules.items():
            if self._match_pattern(rule):
                self.detected_patterns.append({
                    'pattern': pattern_name,
                    'timestamp': event.timestamp,
                    'events': self._get_matching_events(rule)
                })
    
    def _match_pattern(self, rule: dict) -> bool:
        # Simple sequence pattern matching
        sequence = rule.get('sequence', [])
        timeout = rule.get('timeout', 60)
        
        matched_events = []
        current_time = time.time()
        
        for event in reversed(self.event_buffer):
            if current_time - event.timestamp > timeout:
                break
            
            for pattern_event in sequence:
                if self._event_matches(event, pattern_event):
                    matched_events.append(event)
                    break
        
        return len(matched_events) == len(sequence)
```

## Stream Joins

### Stream-Stream Join
```python
class StreamJoiner:
    def __init__(self, join_window_seconds: int):
        self.join_window = join_window_seconds
        self.left_buffer = deque()
        self.right_buffer = deque()
    
    def join(self, left_event: Event = None, right_event: Event = None):
        current_time = time.time()
        
        # Add events to buffers
        if left_event:
            self.left_buffer.append(left_event)
        if right_event:
            self.right_buffer.append(right_event)
        
        # Clean old events
        self._cleanup_buffers(current_time)
        
        # Perform join
        results = []
        for l_event in self.left_buffer:
            for r_event in self.right_buffer:
                if self._can_join(l_event, r_event):
                    results.append(self._join_events(l_event, r_event))
        
        return results
    
    def _can_join(self, left: Event, right: Event) -> bool:
        # Join on key and within time window
        return (left.data.get('join_key') == right.data.get('join_key') and
                abs(left.timestamp - right.timestamp) <= self.join_window)
    
    def _join_events(self, left: Event, right: Event) -> dict:
        return {
            'left': left.data,
            'right': right.data,
            'join_timestamp': max(left.timestamp, right.timestamp)
        }
```

## Backpressure Handling

### Rate Limiting
```python
class RateLimiter:
    def __init__(self, max_rate: int, window_seconds: int = 1):
        self.max_rate = max_rate
        self.window = window_seconds
        self.tokens = max_rate
        self.last_refill = time.time()
    
    async def acquire(self):
        while True:
            current_time = time.time()
            
            # Refill tokens
            time_passed = current_time - self.last_refill
            self.tokens = min(
                self.max_rate,
                self.tokens + (time_passed * self.max_rate / self.window)
            )
            self.last_refill = current_time
            
            # Check if we can proceed
            if self.tokens >= 1:
                self.tokens -= 1
                return
            
            # Wait before retry
            wait_time = (1 - self.tokens) * self.window / self.max_rate
            await asyncio.sleep(wait_time)
```

## Exactly-Once Processing

### Idempotent Processing
```python
class IdempotentProcessor:
    def __init__(self):
        self.processed_ids = set()
        self.results_cache = {}
    
    async def process_once(self, event: Event, processor: Callable):
        # Check if already processed
        if event.id in self.processed_ids:
            return self.results_cache.get(event.id)
        
        # Process event
        result = await processor(event)
        
        # Mark as processed
        self.processed_ids.add(event.id)
        self.results_cache[event.id] = result
        
        # Cleanup old entries periodically
        if len(self.processed_ids) > 10000:
            self._cleanup_old_entries()
        
        return result
    
    def _cleanup_old_entries(self):
        # Keep only recent entries
        if len(self.processed_ids) > 5000:
            # In production, use time-based cleanup
            old_ids = list(self.processed_ids)[:5000]
            for id in old_ids:
                self.processed_ids.remove(id)
                self.results_cache.pop(id, None)
```

## Checklist
- [ ] Choose appropriate streaming platform
- [ ] Define event schema
- [ ] Implement proper windowing
- [ ] Handle state management
- [ ] Add backpressure control
- [ ] Ensure exactly-once processing
- [ ] Monitor lag and throughput
- [ ] Implement error handling and DLQ