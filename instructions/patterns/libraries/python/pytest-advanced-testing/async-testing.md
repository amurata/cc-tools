## Async Testing Patterns

### 1. Advanced Asynchronous Testing

```python
import pytest
import asyncio
import aiohttp
import asyncpg
from typing import AsyncGenerator, List, Dict, Any
import time
from unittest.mock import AsyncMock, patch
import logging

# Asynchronous fixtures
@pytest.fixture(scope="session")
def event_loop():
    """Event loop shared across entire session"""
    try:
        loop = asyncio.get_running_loop()
    except RuntimeError:
        loop = asyncio.new_event_loop()
    yield loop
    loop.close()

@pytest.fixture
async def async_database():
    """Asynchronous database connection"""
    connection = await asyncpg.connect(
        "postgresql://testuser:testpass@localhost/testdb"
    )
    
    # Initialize tables
    await connection.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id SERIAL PRIMARY KEY,
            username VARCHAR(50) UNIQUE NOT NULL,
            email VARCHAR(100) NOT NULL,
            created_at TIMESTAMP DEFAULT NOW()
        )
    """)
    
    yield connection
    
    # Cleanup
    await connection.execute("DROP TABLE IF EXISTS users")
    await connection.close()

@pytest.fixture
async def async_http_client():
    """Asynchronous HTTP client"""
    async with aiohttp.ClientSession() as session:
        yield session

@pytest.fixture
async def async_test_data(async_database):
    """Asynchronous test data creation"""
    users = []
    
    for i in range(5):
        user_id = await async_database.fetchval(
            "INSERT INTO users (username, email) VALUES ($1, $2) RETURNING id",
            f"user{i}",
            f"user{i}@example.com"
        )
        users.append(user_id)
    
    yield users
    
    # Cleanup
    for user_id in users:
        await async_database.execute("DELETE FROM users WHERE id = $1", user_id)

# Asynchronous test cases
@pytest.mark.asyncio
async def test_async_database_operations(async_database):
    """Test asynchronous database operations"""
    # Create user
    user_id = await async_database.fetchval(
        "INSERT INTO users (username, email) VALUES ($1, $2) RETURNING id",
        "asyncuser",
        "async@example.com"
    )
    
    assert user_id is not None
    
    # Retrieve user
    user = await async_database.fetchrow(
        "SELECT * FROM users WHERE id = $1", user_id
    )
    
    assert user["username"] == "asyncuser"
    assert user["email"] == "async@example.com"
    
    # Update user
    await async_database.execute(
        "UPDATE users SET email = $1 WHERE id = $2",
        "updated@example.com",
        user_id
    )
    
    updated_user = await async_database.fetchrow(
        "SELECT * FROM users WHERE id = $1", user_id
    )
    
    assert updated_user["email"] == "updated@example.com"
    
    # Delete user
    deleted_count = await async_database.execute(
        "DELETE FROM users WHERE id = $1", user_id
    )
    
    assert "DELETE 1" in deleted_count

@pytest.mark.asyncio
async def test_async_http_requests(async_http_client):
    """Test asynchronous HTTP requests"""
    # Multiple concurrent requests
    urls = [
        "https://httpbin.org/json",
        "https://httpbin.org/user-agent",
        "https://httpbin.org/headers"
    ]
    
    tasks = []
    for url in urls:
        task = asyncio.create_task(async_http_client.get(url))
        tasks.append(task)
    
    responses = await asyncio.gather(*tasks)
    
    # Validate responses
    assert len(responses) == len(urls)
    for response in responses:
        assert response.status == 200

# Test asynchronous context managers
class AsyncResourceManager:
    """Asynchronous resource management class"""
    
    def __init__(self, resource_name: str):
        self.resource_name = resource_name
        self.is_acquired = False
    
    async def __aenter__(self):
        await asyncio.sleep(0.1)  # Simulate resource acquisition
        self.is_acquired = True
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        await asyncio.sleep(0.1)  # Simulate resource release
        self.is_acquired = False

@pytest.mark.asyncio
async def test_async_context_manager():
    """Test asynchronous context manager"""
    manager = AsyncResourceManager("test_resource")
    
    assert not manager.is_acquired
    
    async with manager:
        assert manager.is_acquired
    
    assert not manager.is_acquired

# Test asynchronous generators
async def async_number_generator(start: int, end: int) -> AsyncGenerator[int, None]:
    """Asynchronous number generator"""
    for i in range(start, end):
        await asyncio.sleep(0.01)  # Simulate async processing
        yield i

@pytest.mark.asyncio
async def test_async_generator():
    """Test asynchronous generator"""
    numbers = []
    
    async for number in async_number_generator(1, 6):
        numbers.append(number)
    
    assert numbers == [1, 2, 3, 4, 5]

# Test asynchronous exception handling
async def async_function_with_exception():
    """Async function that raises exception"""
    await asyncio.sleep(0.1)
    raise ValueError("Async error occurred")

@pytest.mark.asyncio
async def test_async_exception_handling():
    """Test asynchronous exception handling"""
    with pytest.raises(ValueError, match="Async error occurred"):
        await async_function_with_exception()

# Timeout testing
@pytest.mark.asyncio
@pytest.mark.timeout(2)
async def test_async_timeout():
    """Test asynchronous timeout"""
    # Operation completing within timeout (1 second)
    await asyncio.sleep(1)
    assert True

@pytest.mark.asyncio
async def test_async_operation_timeout():
    """Test asynchronous operation timeout"""
    async def slow_operation():
        await asyncio.sleep(5)  # 5-second operation
        return "completed"
    
    # Timeout after 2 seconds
    with pytest.raises(asyncio.TimeoutError):
        await asyncio.wait_for(slow_operation(), timeout=2.0)

# Test asynchronous mocks
@pytest.mark.asyncio
async def test_async_mock():
    """Test asynchronous mocks"""
    # Using AsyncMock
    mock_service = AsyncMock()
    mock_service.get_data.return_value = {"result": "mocked_data"}
    
    result = await mock_service.get_data("test_param")
    
    assert result == {"result": "mocked_data"}
    mock_service.get_data.assert_awaited_once_with("test_param")

# Asynchronous performance testing
@pytest.mark.asyncio
async def test_async_performance():
    """Test asynchronous performance"""
    async def cpu_bound_task(n: int) -> int:
        """CPU-intensive task"""
        await asyncio.sleep(0)  # Yield control to other tasks
        return sum(i**2 for i in range(n))
    
    # Concurrent execution
    start_time = time.time()
    
    tasks = [cpu_bound_task(1000) for _ in range(10)]
    results = await asyncio.gather(*tasks)
    
    execution_time = time.time() - start_time
    
    assert len(results) == 10
    assert all(isinstance(result, int) for result in results)
    assert execution_time < 1.0  # Expect completion within 1 second

# Asynchronous error aggregation testing
@pytest.mark.asyncio
async def test_async_error_aggregation():
    """Test asynchronous error aggregation"""
    async def failing_task(task_id: int):
        await asyncio.sleep(0.1)
        if task_id % 2 == 0:
            raise ValueError(f"Task {task_id} failed")
        return f"Task {task_id} succeeded"
    
    tasks = [failing_task(i) for i in range(5)]
    results = await asyncio.gather(*tasks, return_exceptions=True)
    
    # Analyze results
    successes = [r for r in results if isinstance(r, str)]
    failures = [r for r in results if isinstance(r, Exception)]
    
    assert len(successes) == 3  # Odd tasks succeed
    assert len(failures) == 2   # Even tasks fail
    
    for failure in failures:
        assert isinstance(failure, ValueError)

# Advanced async testing with cancellation
@pytest.mark.asyncio
async def test_async_task_cancellation():
    """Test asynchronous task cancellation"""
    async def long_running_task():
        try:
            await asyncio.sleep(10)  # Long operation
            return "completed"
        except asyncio.CancelledError:
            return "cancelled"
    
    # Start task and cancel it
    task = asyncio.create_task(long_running_task())
    await asyncio.sleep(0.1)  # Let task start
    
    task.cancel()
    
    try:
        result = await task
    except asyncio.CancelledError:
        result = "task_cancelled"
    
    assert result == "task_cancelled"
    assert task.cancelled()
```

### 2. Asynchronous Integration Testing

```python
import pytest
import asyncio
import aioredis
from unittest.mock import AsyncMock, patch
import json
from typing import Dict, Any

class AsyncTestService:
    """Asynchronous test service"""
    
    def __init__(self, db_pool, redis_client, http_client):
        self.db_pool = db_pool
        self.redis_client = redis_client
        self.http_client = http_client
    
    async def create_user_with_cache(self, user_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create user with caching"""
        # Create user in database
        async with self.db_pool.acquire() as connection:
            user_id = await connection.fetchval(
                "INSERT INTO users (username, email) VALUES ($1, $2) RETURNING id",
                user_data["username"],
                user_data["email"]
            )
        
        # Save to cache
        cache_key = f"user:{user_id}"
        user_data["id"] = user_id
        await self.redis_client.setex(
            cache_key, 
            3600,  # 1 hour
            json.dumps(user_data)
        )
        
        # Notify external API
        await self.http_client.post(
            "https://api.example.com/notifications",
            json={"event": "user_created", "user_id": user_id}
        )
        
        return user_data
    
    async def get_user_with_cache(self, user_id: int) -> Dict[str, Any]:
        """Get user with caching"""
        cache_key = f"user:{user_id}"
        
        # Try cache first
        cached_data = await self.redis_client.get(cache_key)
        if cached_data:
            return json.loads(cached_data)
        
        # Fetch from database
        async with self.db_pool.acquire() as connection:
            user = await connection.fetchrow(
                "SELECT * FROM users WHERE id = $1", user_id
            )
        
        if user:
            user_data = dict(user)
            # Save to cache
            await self.redis_client.setex(
                cache_key,
                3600,
                json.dumps(user_data)
            )
            return user_data
        
        return None

@pytest.fixture
async def async_service_dependencies():
    """Asynchronous service dependencies"""
    # Mock database pool
    db_pool = AsyncMock()
    
    # Mock Redis client
    redis_client = AsyncMock()
    
    # Mock HTTP client
    http_client = AsyncMock()
    
    return {
        "db_pool": db_pool,
        "redis_client": redis_client,
        "http_client": http_client
    }

@pytest.fixture
async def async_test_service(async_service_dependencies):
    """Asynchronous test service"""
    return AsyncTestService(**async_service_dependencies)

@pytest.mark.asyncio
async def test_async_service_user_creation(async_test_service, async_service_dependencies):
    """Test asynchronous service user creation"""
    # Configure mocks
    mock_connection = AsyncMock()
    mock_connection.fetchval.return_value = 123
    async_service_dependencies["db_pool"].acquire.return_value.__aenter__.return_value = mock_connection
    
    user_data = {
        "username": "testuser",
        "email": "test@example.com"
    }
    
    # Execute service method
    result = await async_test_service.create_user_with_cache(user_data)
    
    # Assertions
    assert result["id"] == 123
    assert result["username"] == "testuser"
    assert result["email"] == "test@example.com"
    
    # Verify mock calls
    mock_connection.fetchval.assert_awaited_once()
    async_service_dependencies["redis_client"].setex.assert_awaited_once()
    async_service_dependencies["http_client"].post.assert_awaited_once()

@pytest.mark.asyncio
async def test_async_service_cache_hit(async_test_service, async_service_dependencies):
    """Test cache hit scenario"""
    # Configure cache data
    cached_user = {
        "id": 123,
        "username": "cacheduser",
        "email": "cached@example.com"
    }
    async_service_dependencies["redis_client"].get.return_value = json.dumps(cached_user)
    
    # Execute service method
    result = await async_test_service.get_user_with_cache(123)
    
    # Assertions
    assert result == cached_user
    
    # Verify no database access
    async_service_dependencies["db_pool"].acquire.assert_not_awaited()

@pytest.mark.asyncio
async def test_async_service_cache_miss(async_test_service, async_service_dependencies):
    """Test cache miss scenario"""
    # Configure cache miss
    async_service_dependencies["redis_client"].get.return_value = None
    
    # Configure database data
    db_user = {
        "id": 123,
        "username": "dbuser",
        "email": "db@example.com"
    }
    mock_connection = AsyncMock()
    mock_connection.fetchrow.return_value = db_user
    async_service_dependencies["db_pool"].acquire.return_value.__aenter__.return_value = mock_connection
    
    # Execute service method
    result = await async_test_service.get_user_with_cache(123)
    
    # Assertions
    assert result == db_user
    
    # Verify database access and cache save
    mock_connection.fetchrow.assert_awaited_once()
    async_service_dependencies["redis_client"].setex.assert_awaited_once()

# Asynchronous integration test (using real services)
@pytest.mark.integration
@pytest.mark.asyncio
async def test_real_async_service_integration():
    """Integration test using real services"""
    # Real Redis connection
    redis_client = await aioredis.from_url("redis://localhost")
    
    # Real HTTP client
    async with aiohttp.ClientSession() as http_client:
        # Test key setup
        test_key = "integration_test"
        test_value = {"message": "integration test data"}
        
        # Redis write/read test
        await redis_client.setex(test_key, 60, json.dumps(test_value))
        
        cached_data = await redis_client.get(test_key)
        retrieved_value = json.loads(cached_data)
        
        assert retrieved_value == test_value
        
        # HTTP request test
        async with http_client.get("https://httpbin.org/json") as response:
            assert response.status == 200
            data = await response.json()
            assert "slideshow" in data
        
        # Cleanup
        await redis_client.delete(test_key)
    
    await redis_client.close()

# Concurrent asynchronous operations testing
@pytest.mark.asyncio
async def test_concurrent_async_operations():
    """Test concurrent asynchronous operations"""
    async def async_operation(operation_id: int, delay: float) -> Dict[str, Any]:
        """Simulate asynchronous operation"""
        await asyncio.sleep(delay)
        return {
            "operation_id": operation_id,
            "completed_at": time.time(),
            "delay": delay
        }
    
    # Execute multiple operations concurrently
    operations = [
        async_operation(i, 0.1 * i) for i in range(1, 6)
    ]
    
    start_time = time.time()
    results = await asyncio.gather(*operations)
    total_time = time.time() - start_time
    
    # Verify concurrent execution reduces total time
    assert total_time < 1.5  # Sequential execution would take 1.5 seconds
    assert len(results) == 5
    
    # Verify result order is preserved
    for i, result in enumerate(results, 1):
        assert result["operation_id"] == i

# Error handling and retry testing
@pytest.mark.asyncio
async def test_async_retry_mechanism():
    """Test asynchronous retry mechanism"""
    call_count = 0
    
    async def unreliable_async_function():
        nonlocal call_count
        call_count += 1
        
        if call_count < 3:
            raise ConnectionError("Temporary failure")
        
        return "Success after retries"
    
    async def retry_async_function(func, max_retries=3, delay=0.1):
        """Asynchronous retry function"""
        for attempt in range(max_retries):
            try:
                return await func()
            except Exception as e:
                if attempt == max_retries - 1:
                    raise e
                await asyncio.sleep(delay)
    
    # Test retry mechanism
    result = await retry_async_function(unreliable_async_function)
    
    assert result == "Success after retries"
    assert call_count == 3

# Advanced async testing with streaming data
@pytest.mark.asyncio
async def test_async_streaming_data_processing():
    """Test asynchronous streaming data processing"""
    async def data_stream():
        """Simulate streaming data source"""
        for i in range(10):
            await asyncio.sleep(0.01)
            yield {"id": i, "value": i * 2}
    
    async def process_stream(stream):
        """Process streaming data"""
        processed_items = []
        async for item in stream:
            processed_item = {
                "id": item["id"],
                "processed_value": item["value"] + 1,
                "timestamp": time.time()
            }
            processed_items.append(processed_item)
        return processed_items
    
    # Process the stream
    results = await process_stream(data_stream())
    
    assert len(results) == 10
    for i, result in enumerate(results):
        assert result["id"] == i
        assert result["processed_value"] == (i * 2) + 1
        assert "timestamp" in result

# Test async context manager with error handling
@pytest.mark.asyncio
async def test_async_context_manager_error_handling():
    """Test async context manager with error handling"""
    cleanup_called = False
    
    class AsyncResourceWithCleanup:
        async def __aenter__(self):
            return self
        
        async def __aexit__(self, exc_type, exc_val, exc_tb):
            nonlocal cleanup_called
            cleanup_called = True
            # Handle exceptions gracefully
            if exc_type:
                print(f"Exception occurred: {exc_val}")
            return False  # Don't suppress exceptions
    
    # Test with exception
    with pytest.raises(ValueError):
        async with AsyncResourceWithCleanup():
            raise ValueError("Test exception")
    
    assert cleanup_called

# Load testing with async
@pytest.mark.asyncio
@pytest.mark.performance
async def test_async_load_performance():
    """Test asynchronous load performance"""
    async def simulate_user_request(user_id: int):
        """Simulate user request"""
        await asyncio.sleep(0.01)  # Simulate processing time
        return {
            "user_id": user_id,
            "response_time": 0.01,
            "status": "success"
        }
    
    # Simulate 100 concurrent users
    concurrent_users = 100
    start_time = time.time()
    
    tasks = [simulate_user_request(i) for i in range(concurrent_users)]
    results = await asyncio.gather(*tasks)
    
    total_time = time.time() - start_time
    throughput = len(results) / total_time
    
    assert len(results) == concurrent_users
    assert all(result["status"] == "success" for result in results)
    assert throughput > 50  # Minimum 50 requests per second
    
    print(f"Load test: {concurrent_users} users, {throughput:.2f} req/s")
```