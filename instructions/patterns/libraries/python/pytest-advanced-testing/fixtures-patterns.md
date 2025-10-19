## Advanced Fixtures Patterns

### 1. Hierarchical Fixture System

```python
import pytest
import asyncio
import docker
import psycopg2
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from typing import Generator, AsyncGenerator, Dict, Any
import tempfile
import shutil
from pathlib import Path

# Scope-based fixture construction
@pytest.fixture(scope="session")
def docker_client():
    """Docker client (shared across entire session)"""
    client = docker.from_env()
    yield client
    client.close()

@pytest.fixture(scope="session")
def postgres_container(docker_client):
    """PostgreSQL container (shared across entire session)"""
    container = docker_client.containers.run(
        "postgres:14",
        environment={
            "POSTGRES_DB": "testdb",
            "POSTGRES_USER": "testuser",
            "POSTGRES_PASSWORD": "testpass"
        },
        ports={"5432/tcp": None},
        detach=True,
        remove=True
    )
    
    # Wait for container startup
    import time
    time.sleep(5)
    
    # Get connection information
    port = container.attrs['NetworkSettings']['Ports']['5432/tcp'][0]['HostPort']
    container.connection_url = f"postgresql://testuser:testpass@localhost:{port}/testdb"
    
    yield container
    
    container.stop()

@pytest.fixture(scope="module")
def database_engine(postgres_container):
    """Database engine (shared across module)"""
    engine = create_engine(postgres_container.connection_url)
    
    # Create tables
    from myapp.models import Base
    Base.metadata.create_all(engine)
    
    yield engine
    
    # Table cleanup
    Base.metadata.drop_all(engine)
    engine.dispose()

@pytest.fixture(scope="function")
def db_session(database_engine):
    """Database session (created per test function)"""
    Session = sessionmaker(bind=database_engine)
    session = Session()
    
    # Begin transaction
    transaction = session.begin()
    
    yield session
    
    # Rollback (ensures test isolation)
    transaction.rollback()
    session.close()

@pytest.fixture(scope="function")
def temp_directory():
    """Temporary directory (created per test function)"""
    temp_dir = Path(tempfile.mkdtemp())
    yield temp_dir
    shutil.rmtree(temp_dir, ignore_errors=True)

# Fixtures with complex dependencies
@pytest.fixture
def test_user(db_session):
    """Test user creation"""
    from myapp.models import User
    
    user = User(
        username="testuser",
        email="test@example.com",
        is_active=True
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    
    yield user
    
    # User cleanup (if needed)
    db_session.delete(user)
    db_session.commit()

@pytest.fixture
def authenticated_client(test_user, client):
    """Authenticated client"""
    # Generate JWT token
    from myapp.auth import create_access_token
    
    token = create_access_token(data={"sub": test_user.username})
    client.headers.update({"Authorization": f"Bearer {token}"})
    
    yield client
    
    # Header cleanup
    if "Authorization" in client.headers:
        del client.headers["Authorization"]

# Fixture factory pattern
@pytest.fixture
def user_factory(db_session):
    """User factory"""
    created_users = []
    
    def _create_user(username=None, email=None, **kwargs):
        from myapp.models import User
        import uuid
        
        if username is None:
            username = f"user_{uuid.uuid4().hex[:8]}"
        if email is None:
            email = f"{username}@example.com"
        
        user = User(username=username, email=email, **kwargs)
        db_session.add(user)
        db_session.commit()
        db_session.refresh(user)
        
        created_users.append(user)
        return user
    
    yield _create_user
    
    # Cleanup created users
    for user in created_users:
        db_session.delete(user)
    db_session.commit()

# Parametrized fixtures
@pytest.fixture(params=["sqlite", "postgresql", "mysql"])
def database_url(request, postgres_container):
    """Test with multiple databases"""
    if request.param == "sqlite":
        return "sqlite:///:memory:"
    elif request.param == "postgresql":
        return postgres_container.connection_url
    elif request.param == "mysql":
        # MySQL configuration (implementation omitted)
        return "mysql://testuser:testpass@localhost/testdb"

# Conditional fixtures
@pytest.fixture
def redis_client():
    """Redis connection (only when Redis is available)"""
    pytest.importorskip("redis")
    
    try:
        import redis
        client = redis.Redis(host='localhost', port=6379, db=0)
        client.ping()  # Connection test
        yield client
    except redis.ConnectionError:
        pytest.skip("Redis server not available")

# Fixture combination patterns
@pytest.fixture
def complete_test_environment(
    db_session,
    authenticated_client,
    temp_directory,
    user_factory
):
    """Complete test environment"""
    # Create additional test data
    admin_user = user_factory(username="admin", is_admin=True)
    regular_users = [user_factory() for _ in range(5)]
    
    # Create test configuration file
    config_file = temp_directory / "test_config.json"
    config_file.write_text('{"test_mode": true}')
    
    return {
        "db_session": db_session,
        "client": authenticated_client,
        "temp_dir": temp_directory,
        "admin_user": admin_user,
        "regular_users": regular_users,
        "config_file": config_file
    }
```

### 2. Dynamic Fixture Generation

```python
import pytest
from typing import Dict, Any, List
import json
import yaml

class FixtureRegistry:
    """Dynamic fixture registry"""
    
    def __init__(self):
        self.fixtures: Dict[str, Any] = {}
        self.fixture_configs: Dict[str, Dict[str, Any]] = {}
    
    def register_fixture(self, name: str, factory_func, config: Dict[str, Any] = None):
        """Dynamic fixture registration"""
        self.fixtures[name] = factory_func
        self.fixture_configs[name] = config or {}
    
    def create_fixture(self, name: str, **kwargs):
        """Dynamic fixture creation"""
        if name not in self.fixtures:
            raise ValueError(f"Fixture {name} not registered")
        
        config = {**self.fixture_configs[name], **kwargs}
        return self.fixtures[name](**config)

# Global registry
fixture_registry = FixtureRegistry()

def pytest_generate_tests(metafunc):
    """Dynamic test case generation"""
    # Load parameters from test data file
    if "test_data" in metafunc.fixturenames:
        test_data_file = metafunc.config.getoption("--test-data-file")
        if test_data_file:
            with open(test_data_file, 'r') as f:
                if test_data_file.endswith('.json'):
                    test_data = json.load(f)
                else:
                    test_data = yaml.safe_load(f)
            
            metafunc.parametrize("test_data", test_data)

def pytest_configure(config):
    """Dynamic fixture registration during pytest configuration"""
    # Load fixtures from configuration file
    fixtures_config = config.getoption("--fixtures-config")
    if fixtures_config:
        with open(fixtures_config, 'r') as f:
            config_data = yaml.safe_load(f)
        
        for fixture_name, fixture_config in config_data.get("fixtures", {}).items():
            register_dynamic_fixture(fixture_name, fixture_config)

def register_dynamic_fixture(name: str, config: Dict[str, Any]):
    """Dynamic fixture registration"""
    fixture_type = config.get("type", "simple")
    
    if fixture_type == "database_record":
        def factory(**kwargs):
            return create_database_record(config["model"], {**config.get("defaults", {}), **kwargs})
        
        fixture_registry.register_fixture(name, factory, config)
    
    elif fixture_type == "api_mock":
        def factory(**kwargs):
            return create_api_mock(config["endpoints"], {**config.get("defaults", {}), **kwargs})
        
        fixture_registry.register_fixture(name, factory, config)

def create_database_record(model_name: str, data: Dict[str, Any]):
    """Dynamic database record creation"""
    # Dynamic model class retrieval
    from myapp.models import get_model_by_name
    
    model_class = get_model_by_name(model_name)
    return model_class(**data)

def create_api_mock(endpoints: List[Dict[str, Any]], config: Dict[str, Any]):
    """Dynamic API mock creation"""
    from unittest.mock import Mock
    
    mock = Mock()
    
    for endpoint in endpoints:
        method = endpoint["method"].lower()
        path = endpoint["path"]
        response_data = endpoint.get("response", {})
        
        # Configure mock method
        mock_method = getattr(mock, method)
        mock_method.return_value.json.return_value = response_data
        mock_method.return_value.status_code = endpoint.get("status_code", 200)
    
    return mock

# Configuration file-based test case generation
@pytest.fixture
def dynamic_test_case(request):
    """Configuration file-based dynamic test case"""
    # Get test case configuration from marker
    test_config = request.node.get_closest_marker("test_config")
    
    if test_config:
        config_data = test_config.args[0]
        
        # Dynamically create required fixtures
        fixtures = {}
        for fixture_name, fixture_config in config_data.get("fixtures", {}).items():
            fixtures[fixture_name] = fixture_registry.create_fixture(fixture_name, **fixture_config)
        
        return {
            "config": config_data,
            "fixtures": fixtures,
            "expected_results": config_data.get("expected_results", {}),
            "test_data": config_data.get("test_data", {})
        }
    
    return {}

# Usage example
@pytest.mark.test_config({
    "fixtures": {
        "test_user": {
            "type": "database_record",
            "model": "User",
            "username": "dynamic_user",
            "email": "dynamic@example.com"
        },
        "api_mock": {
            "type": "api_mock",
            "endpoints": [
                {
                    "method": "GET",
                    "path": "/api/users",
                    "response": {"users": []},
                    "status_code": 200
                }
            ]
        }
    },
    "test_data": {
        "input_value": 42,
        "expected_output": 84
    },
    "expected_results": {
        "status_code": 200,
        "response_contains": ["success"]
    }
})
def test_dynamic_configuration(dynamic_test_case):
    """Dynamic configuration-based test"""
    config = dynamic_test_case["config"]
    fixtures = dynamic_test_case["fixtures"]
    test_data = dynamic_test_case["test_data"]
    expected = dynamic_test_case["expected_results"]
    
    # Test logic
    assert fixtures["test_user"].username == "dynamic_user"
    assert test_data["input_value"] * 2 == test_data["expected_output"]

# Advanced fixture patterns for enterprise testing
@pytest.fixture
def enterprise_test_suite(request):
    """Enterprise-level test suite configuration"""
    suite_config = {
        "environment": request.config.getoption("--test-env", default="development"),
        "parallel_workers": request.config.getoption("--workers", default=1),
        "test_categories": request.config.getoption("--categories", default="unit,integration").split(","),
        "cleanup_strategy": request.config.getoption("--cleanup", default="auto")
    }
    
    # Environment-specific configurations
    if suite_config["environment"] == "production":
        suite_config.update({
            "read_only_mode": True,
            "anonymize_data": True,
            "audit_logging": True
        })
    
    return suite_config

@pytest.fixture
def performance_monitoring():
    """Performance monitoring for test execution"""
    import time
    import psutil
    import threading
    
    start_time = time.time()
    start_memory = psutil.virtual_memory().used
    monitoring_active = threading.Event()
    monitoring_active.set()
    
    def monitor_resources():
        peak_memory = start_memory
        while monitoring_active.is_set():
            current_memory = psutil.virtual_memory().used
            peak_memory = max(peak_memory, current_memory)
            time.sleep(0.1)
        return peak_memory
    
    monitor_thread = threading.Thread(target=monitor_resources, daemon=True)
    monitor_thread.start()
    
    yield {
        "start_time": start_time,
        "start_memory": start_memory
    }
    
    # Stop monitoring and collect metrics
    monitoring_active.clear()
    end_time = time.time()
    end_memory = psutil.virtual_memory().used
    
    execution_time = end_time - start_time
    memory_delta = end_memory - start_memory
    
    # Log performance metrics
    if execution_time > 5.0:  # Log slow tests
        print(f"\n⚠️ Slow test detected: {execution_time:.2f}s")
    
    if memory_delta > 100 * 1024 * 1024:  # 100MB threshold
        print(f"\n⚠️ High memory usage: {memory_delta / 1024 / 1024:.2f}MB")
```