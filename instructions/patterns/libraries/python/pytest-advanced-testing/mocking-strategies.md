## Mocking Strategies

### 1. Advanced Mocking Patterns

```python
import pytest
from unittest.mock import Mock, MagicMock, patch, call, AsyncMock
from unittest.mock import PropertyMock, mock_open
import requests
import asyncio
from typing import Any, Dict, List
import json
import os
import tempfile

# Basic mock patterns
class EmailService:
    """Email service (mock target)"""
    
    def __init__(self, smtp_server: str, port: int = 587):
        self.smtp_server = smtp_server
        self.port = port
        self.connection = None
    
    def connect(self) -> bool:
        """SMTP connection"""
        # Actual SMTP connection logic
        return True
    
    def send_email(self, to: str, subject: str, body: str) -> bool:
        """Send email"""
        if not self.connection:
            if not self.connect():
                return False
        
        # Actual email sending logic
        return True
    
    def disconnect(self):
        """Disconnect"""
        self.connection = None

class UserService:
    """User service"""
    
    def __init__(self, email_service: EmailService):
        self.email_service = email_service
    
    def register_user(self, username: str, email: str) -> Dict[str, Any]:
        """User registration"""
        # User registration logic
        user_id = 12345  # Assume retrieved from database
        
        # Send welcome email
        welcome_sent = self.email_service.send_email(
            to=email,
            subject="Welcome to our service!",
            body=f"Hello {username}, welcome to our platform!"
        )
        
        return {
            "user_id": user_id,
            "username": username,
            "email": email,
            "welcome_email_sent": welcome_sent
        }

# Testing with mocks
def test_user_registration_with_mock():
    """User registration test using mocks"""
    # Create email service mock
    mock_email_service = Mock(spec=EmailService)
    mock_email_service.send_email.return_value = True
    
    # Create user service
    user_service = UserService(mock_email_service)
    
    # Execute user registration
    result = user_service.register_user("testuser", "test@example.com")
    
    # Assertions
    assert result["user_id"] == 12345
    assert result["username"] == "testuser"
    assert result["email"] == "test@example.com"
    assert result["welcome_email_sent"] is True
    
    # Verify mock calls
    mock_email_service.send_email.assert_called_once_with(
        to="test@example.com",
        subject="Welcome to our service!",
        body="Hello testuser, welcome to our platform!"
    )

# Testing with patch decorator
@patch('requests.get')
def test_api_client_with_patch(mock_get):
    """API client test using patch decorator"""
    # Configure mock response
    mock_response = Mock()
    mock_response.status_code = 200
    mock_response.json.return_value = {
        "id": 1,
        "name": "Test User",
        "email": "test@example.com"
    }
    mock_get.return_value = mock_response
    
    # Execute API client
    from myapp.api_client import get_user
    result = get_user(user_id=1)
    
    # Assertions
    assert result["name"] == "Test User"
    assert result["email"] == "test@example.com"
    
    # Verify HTTP request
    mock_get.assert_called_once_with("https://api.example.com/users/1")

# Using context manager for patching
def test_file_operations_with_context_patch():
    """Test with context manager patch"""
    from myapp.file_utils import save_user_data
    
    # Mock file writing
    mock_file_content = ""
    
    def mock_write(content):
        nonlocal mock_file_content
        mock_file_content += content
    
    with patch('builtins.open', mock_open()) as mock_file:
        mock_file.return_value.write = mock_write
        
        # Execute file operation
        save_user_data({"name": "John", "age": 30})
        
        # Verify file operation
        mock_file.assert_called_once_with("/tmp/user_data.json", "w")

# Complex mock scenarios
class DatabaseManager:
    """Database management class"""
    
    def __init__(self, connection_string: str):
        self.connection_string = connection_string
        self.connection = None
    
    def connect(self):
        """Database connection"""
        pass
    
    def execute_query(self, query: str, params: List[Any] = None) -> List[Dict[str, Any]]:
        """Execute query"""
        pass
    
    def begin_transaction(self):
        """Begin transaction"""
        pass
    
    def commit_transaction(self):
        """Commit transaction"""
        pass
    
    def rollback_transaction(self):
        """Rollback transaction"""
        pass

class UserRepository:
    """User repository"""
    
    def __init__(self, db_manager: DatabaseManager):
        self.db_manager = db_manager
    
    def create_user(self, user_data: Dict[str, Any]) -> int:
        """Create user"""
        try:
            self.db_manager.begin_transaction()
            
            # Check for duplicate user
            existing_users = self.db_manager.execute_query(
                "SELECT id FROM users WHERE email = ?",
                [user_data["email"]]
            )
            
            if existing_users:
                raise ValueError("User already exists")
            
            # Create user
            result = self.db_manager.execute_query(
                "INSERT INTO users (username, email) VALUES (?, ?) RETURNING id",
                [user_data["username"], user_data["email"]]
            )
            
            self.db_manager.commit_transaction()
            return result[0]["id"]
            
        except Exception:
            self.db_manager.rollback_transaction()
            raise

def test_user_repository_complex_mock():
    """Test complex mock scenario"""
    # Mock database manager
    mock_db = Mock(spec=DatabaseManager)
    
    # Configure mock behavior
    mock_db.execute_query.side_effect = [
        [],  # Duplicate check (no results)
        [{"id": 456}]  # INSERT result
    ]
    
    # Create repository and test
    repo = UserRepository(mock_db)
    
    user_data = {"username": "newuser", "email": "new@example.com"}
    user_id = repo.create_user(user_data)
    
    # Assertions
    assert user_id == 456
    
    # Verify mock call details
    expected_calls = [
        call("SELECT id FROM users WHERE email = ?", ["new@example.com"]),
        call("INSERT INTO users (username, email) VALUES (?, ?) RETURNING id", ["newuser", "new@example.com"])
    ]
    mock_db.execute_query.assert_has_calls(expected_calls)
    
    # Verify transaction processing
    mock_db.begin_transaction.assert_called_once()
    mock_db.commit_transaction.assert_called_once()
    mock_db.rollback_transaction.assert_not_called()

def test_user_repository_exception_handling():
    """Test exception handling with mocks"""
    mock_db = Mock(spec=DatabaseManager)
    
    # Duplicate user scenario
    mock_db.execute_query.return_value = [{"id": 123}]  # Existing user found
    
    repo = UserRepository(mock_db)
    
    user_data = {"username": "duplicate", "email": "duplicate@example.com"}
    
    # Verify exception raised
    with pytest.raises(ValueError, match="User already exists"):
        repo.create_user(user_data)
    
    # Verify rollback called
    mock_db.rollback_transaction.assert_called_once()
    mock_db.commit_transaction.assert_not_called()

# Property mocking
class User:
    """User class"""
    
    def __init__(self, username: str, email: str):
        self._username = username
        self._email = email
        self._is_verified = False
    
    @property
    def username(self) -> str:
        return self._username
    
    @property
    def email(self) -> str:
        return self._email
    
    @property
    def is_verified(self) -> bool:
        # Actually has external API verification logic
        return self._is_verified
    
    def verify_email(self) -> bool:
        """Email verification"""
        # External API call
        self._is_verified = True
        return True

def test_user_property_mock():
    """Test property mocking"""
    user = User("testuser", "test@example.com")
    
    # Mock property
    with patch.object(User, 'is_verified', new_callable=PropertyMock) as mock_verified:
        mock_verified.return_value = True
        
        # Verify property
        assert user.is_verified is True
        
        # Verify property access
        mock_verified.assert_called()

# Environment variable mocking
def test_environment_variables_mock():
    """Test environment variable mocking"""
    from myapp.config import get_database_url
    
    # Mock environment variables
    with patch.dict(os.environ, {
        'DATABASE_URL': 'postgresql://test:test@localhost/testdb',
        'DEBUG': 'true'
    }):
        db_url = get_database_url()
        assert db_url == 'postgresql://test:test@localhost/testdb'

# File system mocking
def test_file_system_mock():
    """Test file system mocking"""
    from myapp.file_manager import load_config
    
    # Mock file content
    mock_config = {
        "database": {"host": "localhost", "port": 5432},
        "redis": {"host": "localhost", "port": 6379}
    }
    
    with patch('builtins.open', mock_open(read_data=json.dumps(mock_config))):
        config = load_config('/path/to/config.json')
        
        assert config["database"]["host"] == "localhost"
        assert config["redis"]["port"] == 6379

# Time mocking
def test_time_mock():
    """Test time mocking"""
    from myapp.utils import get_timestamp
    import time
    
    fixed_time = 1609459200.0  # 2021-01-01 00:00:00 UTC
    
    with patch('time.time', return_value=fixed_time):
        timestamp = get_timestamp()
        assert timestamp == fixed_time

# Asynchronous mocking
@pytest.mark.asyncio
async def test_async_mock_example():
    """Asynchronous mock example"""
    
    async def async_api_call(url: str) -> Dict[str, Any]:
        """Async API call (mock target)"""
        async with aiohttp.ClientSession() as session:
            async with session.get(url) as response:
                return await response.json()
    
    # Mock async function
    with patch('myapp.api.async_api_call', new_callable=AsyncMock) as mock_api:
        mock_api.return_value = {"status": "success", "data": [1, 2, 3]}
        
        from myapp.service import process_data
        result = await process_data()
        
        assert result["status"] == "success"
        mock_api.assert_awaited_once()

# Mock class inheritance
class MockEmailService(EmailService):
    """Mock implementation of EmailService"""
    
    def __init__(self):
        super().__init__("mock_server")
        self.sent_emails = []
        self.connected = False
    
    def connect(self) -> bool:
        self.connected = True
        return True
    
    def send_email(self, to: str, subject: str, body: str) -> bool:
        if not self.connected:
            return False
        
        self.sent_emails.append({
            "to": to,
            "subject": subject,
            "body": body
        })
        return True
    
    def disconnect(self):
        self.connected = False

def test_custom_mock_class():
    """Test custom mock class"""
    mock_email_service = MockEmailService()
    user_service = UserService(mock_email_service)
    
    result = user_service.register_user("testuser", "test@example.com")
    
    assert result["welcome_email_sent"] is True
    assert len(mock_email_service.sent_emails) == 1
    
    sent_email = mock_email_service.sent_emails[0]
    assert sent_email["to"] == "test@example.com"
    assert "testuser" in sent_email["body"]

# Advanced mock configuration
def test_advanced_mock_configuration():
    """Test advanced mock configuration"""
    # Create mock with spec
    mock_service = Mock(spec=EmailService)
    
    # Configure multiple return values
    mock_service.connect.side_effect = [True, False, True]
    
    # First call returns True
    assert mock_service.connect() is True
    # Second call returns False
    assert mock_service.connect() is False
    # Third call returns True
    assert mock_service.connect() is True
    
    # Configure exception raising
    mock_service.send_email.side_effect = ConnectionError("Network error")
    
    with pytest.raises(ConnectionError, match="Network error"):
        mock_service.send_email("test@example.com", "Subject", "Body")

# Mock with side effects
def test_mock_with_side_effects():
    """Test mock with side effects"""
    counter = {"value": 0}
    
    def increment_counter(*args, **kwargs):
        counter["value"] += 1
        return counter["value"]
    
    mock_func = Mock(side_effect=increment_counter)
    
    assert mock_func() == 1
    assert mock_func() == 2
    assert mock_func() == 3
    assert counter["value"] == 3

# Spy pattern (partial mock)
def test_spy_pattern():
    """Test spy pattern (partial mock)"""
    real_service = EmailService("smtp.gmail.com")
    
    # Spy on specific method
    with patch.object(real_service, 'send_email', wraps=real_service.send_email) as spy:
        # Method still executes normally
        real_service.send_email("test@example.com", "Subject", "Body")
        
        # But we can verify it was called
        spy.assert_called_once_with("test@example.com", "Subject", "Body")

# Mock chaining
def test_mock_chaining():
    """Test mock chaining"""
    mock = Mock()
    mock.method1.return_value.method2.return_value.method3.return_value = "final_result"
    
    result = mock.method1().method2().method3()
    assert result == "final_result"
    
    # Verify call chain
    mock.method1.assert_called_once()
    mock.method1.return_value.method2.assert_called_once()
    mock.method1.return_value.method2.return_value.method3.assert_called_once()

# Context-aware mocking
class ContextAwareMock:
    """Context-aware mock for complex scenarios"""
    
    def __init__(self):
        self.call_history = []
        self.state = "initial"
    
    def process(self, action: str) -> str:
        self.call_history.append((action, self.state))
        
        if action == "start" and self.state == "initial":
            self.state = "running"
            return "started"
        elif action == "stop" and self.state == "running":
            self.state = "stopped"
            return "stopped"
        else:
            return "invalid_action"
    
    def get_history(self) -> List[tuple]:
        return self.call_history

def test_context_aware_mock():
    """Test context-aware mock"""
    mock = ContextAwareMock()
    
    assert mock.process("start") == "started"
    assert mock.state == "running"
    
    assert mock.process("stop") == "stopped"
    assert mock.state == "stopped"
    
    assert mock.process("start") == "invalid_action"
    
    history = mock.get_history()
    assert len(history) == 3
    assert history[0] == ("start", "initial")
    assert history[1] == ("stop", "running")
    assert history[2] == ("start", "stopped")

# Mock factory pattern
class MockFactory:
    """Factory for creating configured mocks"""
    
    @staticmethod
    def create_database_mock(query_results: List[Any] = None) -> Mock:
        """Create configured database mock"""
        mock_db = Mock()
        mock_db.execute_query.return_value = query_results or []
        mock_db.is_connected.return_value = True
        return mock_db
    
    @staticmethod
    def create_api_mock(response_data: Dict[str, Any] = None) -> Mock:
        """Create configured API mock"""
        mock_api = Mock()
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = response_data or {}
        mock_api.get.return_value = mock_response
        return mock_api

def test_mock_factory():
    """Test mock factory pattern"""
    # Create database mock
    db_mock = MockFactory.create_database_mock([{"id": 1, "name": "Test"}])
    result = db_mock.execute_query("SELECT * FROM users")
    assert result[0]["name"] == "Test"
    
    # Create API mock
    api_mock = MockFactory.create_api_mock({"status": "success"})
    response = api_mock.get("/api/status")
    assert response.json()["status"] == "success"
```