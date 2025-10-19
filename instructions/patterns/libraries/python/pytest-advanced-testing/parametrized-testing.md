## Parametrized Testing

### 1. Advanced Parametrized Testing

```python
import pytest
from typing import List, Dict, Any, Union
import itertools
from dataclasses import dataclass
from enum import Enum

class TestCategory(Enum):
    POSITIVE = "positive"
    NEGATIVE = "negative"
    EDGE_CASE = "edge_case"
    PERFORMANCE = "performance"

@dataclass
class TestCase:
    """Structured test case"""
    name: str
    input_data: Dict[str, Any]
    expected_result: Any
    category: TestCategory
    should_raise: Exception = None
    marks: List[str] = None
    timeout: float = None

# Complex parametrization patterns
class TestDataBuilder:
    """Test data builder"""
    
    def __init__(self):
        self.test_cases: List[TestCase] = []
    
    def add_positive_case(self, name: str, input_data: Dict[str, Any], expected: Any, **kwargs):
        """Add positive test case"""
        self.test_cases.append(TestCase(
            name=name,
            input_data=input_data,
            expected_result=expected,
            category=TestCategory.POSITIVE,
            **kwargs
        ))
        return self
    
    def add_negative_case(self, name: str, input_data: Dict[str, Any], exception: Exception, **kwargs):
        """Add negative test case"""
        self.test_cases.append(TestCase(
            name=name,
            input_data=input_data,
            expected_result=None,
            category=TestCategory.NEGATIVE,
            should_raise=exception,
            **kwargs
        ))
        return self
    
    def add_edge_case(self, name: str, input_data: Dict[str, Any], expected: Any, **kwargs):
        """Add edge case"""
        self.test_cases.append(TestCase(
            name=name,
            input_data=input_data,
            expected_result=expected,
            category=TestCategory.EDGE_CASE,
            **kwargs
        ))
        return self
    
    def add_performance_case(self, name: str, input_data: Dict[str, Any], expected: Any, timeout: float, **kwargs):
        """Add performance test case"""
        self.test_cases.append(TestCase(
            name=name,
            input_data=input_data,
            expected_result=expected,
            category=TestCategory.PERFORMANCE,
            timeout=timeout,
            marks=["performance"] + (kwargs.get("marks", [])),
            **kwargs
        ))
        return self
    
    def build(self) -> List[TestCase]:
        """Build test case list"""
        return self.test_cases

# Mathematical function test case example
def create_math_function_test_cases():
    """Create mathematical function test cases"""
    builder = TestDataBuilder()
    
    # Positive cases
    builder.add_positive_case(
        "basic_addition",
        {"a": 2, "b": 3},
        5
    ).add_positive_case(
        "large_numbers",
        {"a": 1000000, "b": 2000000},
        3000000
    ).add_positive_case(
        "decimal_numbers",
        {"a": 1.5, "b": 2.7},
        4.2
    )
    
    # Negative cases
    builder.add_negative_case(
        "invalid_type_string",
        {"a": "invalid", "b": 3},
        TypeError
    ).add_negative_case(
        "invalid_type_none",
        {"a": None, "b": 3},
        TypeError
    )
    
    # Edge cases
    builder.add_edge_case(
        "zero_values",
        {"a": 0, "b": 0},
        0
    ).add_edge_case(
        "negative_numbers",
        {"a": -5, "b": -3},
        -8
    ).add_edge_case(
        "very_small_numbers",
        {"a": 1e-10, "b": 2e-10},
        3e-10
    )
    
    # Performance cases
    builder.add_performance_case(
        "large_computation",
        {"a": 10**6, "b": 10**6},
        2 * 10**6,
        timeout=1.0
    )
    
    return builder.build()

# Parametrized test implementation
math_test_cases = create_math_function_test_cases()

@pytest.mark.parametrize(
    "test_case",
    math_test_cases,
    ids=[case.name for case in math_test_cases]
)
def test_math_function(test_case: TestCase):
    """Comprehensive mathematical function test"""
    from myapp.math_utils import add_numbers
    
    # Timeout configuration
    if test_case.timeout:
        pytest.mark.timeout(test_case.timeout)
    
    # Process according to test category
    if test_case.category == TestCategory.NEGATIVE:
        with pytest.raises(test_case.should_raise):
            add_numbers(**test_case.input_data)
    else:
        result = add_numbers(**test_case.input_data)
        
        if test_case.category == TestCategory.POSITIVE:
            assert result == test_case.expected_result
        elif test_case.category == TestCategory.EDGE_CASE:
            # Consider tolerance for edge cases
            if isinstance(result, float):
                assert abs(result - test_case.expected_result) < 1e-10
            else:
                assert result == test_case.expected_result
        elif test_case.category == TestCategory.PERFORMANCE:
            assert result == test_case.expected_result
            # Performance requirements controlled by @pytest.mark.timeout

# Category filtering
@pytest.mark.parametrize(
    "test_case",
    [case for case in math_test_cases if case.category == TestCategory.POSITIVE],
    ids=[case.name for case in math_test_cases if case.category == TestCategory.POSITIVE]
)
def test_math_function_positive_only(test_case: TestCase):
    """Positive test cases only"""
    from myapp.math_utils import add_numbers
    result = add_numbers(**test_case.input_data)
    assert result == test_case.expected_result

# Combinatorial testing
@pytest.mark.parametrize("method", ["GET", "POST", "PUT", "DELETE"])
@pytest.mark.parametrize("status_code", [200, 404, 500])
@pytest.mark.parametrize("content_type", ["application/json", "text/html"])
def test_api_combinations(method, status_code, content_type):
    """API endpoint combination testing"""
    # Test all combinations (4 × 3 × 2 = 24 test cases)
    response = simulate_api_call(method, status_code, content_type)
    
    # Basic validation
    assert response.method == method
    assert response.status_code == status_code
    assert response.content_type == content_type

# Conditional parametrization
def pytest_generate_tests(metafunc):
    """Dynamic parametrization"""
    if "database_config" in metafunc.fixturenames:
        # Change database configuration based on environment variables
        import os
        
        configs = []
        if os.getenv("TEST_SQLITE"):
            configs.append(("sqlite", "sqlite:///:memory:"))
        if os.getenv("TEST_POSTGRESQL"):
            configs.append(("postgresql", "postgresql://localhost/testdb"))
        if os.getenv("TEST_MYSQL"):
            configs.append(("mysql", "mysql://localhost/testdb"))
        
        if not configs:
            configs = [("sqlite", "sqlite:///:memory:")]  # Default
        
        metafunc.parametrize("database_config", configs, ids=[config[0] for config in configs])

# Data-driven testing
@pytest.mark.parametrize(
    "user_data,expected_validation",
    [
        # Valid user data
        (
            {"username": "validuser", "email": "user@example.com", "age": 25},
            {"valid": True, "errors": []}
        ),
        # Invalid user data
        (
            {"username": "", "email": "invalid-email", "age": -1},
            {"valid": False, "errors": ["username_required", "invalid_email", "invalid_age"]}
        ),
        # Edge cases
        (
            {"username": "a" * 100, "email": "edge@example.com", "age": 0},
            {"valid": False, "errors": ["username_too_long", "invalid_age"]}
        )
    ]
)
def test_user_validation(user_data, expected_validation):
    """User data validation test"""
    from myapp.validators import validate_user
    
    result = validate_user(user_data)
    
    assert result["valid"] == expected_validation["valid"]
    assert set(result["errors"]) == set(expected_validation["errors"])
```

### 2. External Data Source Parametrization

```python
import pytest
import csv
import json
import yaml
from pathlib import Path
from typing import List, Dict, Any
import pandas as pd

class ExternalTestDataLoader:
    """External test data loader"""
    
    @staticmethod
    def load_csv(file_path: str) -> List[Dict[str, Any]]:
        """Load test data from CSV file"""
        test_data = []
        with open(file_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                # Attempt type conversion
                converted_row = {}
                for key, value in row.items():
                    # Attempt numeric conversion
                    try:
                        if '.' in value:
                            converted_row[key] = float(value)
                        else:
                            converted_row[key] = int(value)
                    except ValueError:
                        # Attempt boolean conversion
                        if value.lower() in ('true', 'false'):
                            converted_row[key] = value.lower() == 'true'
                        # Handle NULL values
                        elif value.lower() in ('null', 'none', ''):
                            converted_row[key] = None
                        else:
                            converted_row[key] = value
                
                test_data.append(converted_row)
        
        return test_data
    
    @staticmethod
    def load_json(file_path: str) -> List[Dict[str, Any]]:
        """Load test data from JSON file"""
        with open(file_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    
    @staticmethod
    def load_yaml(file_path: str) -> List[Dict[str, Any]]:
        """Load test data from YAML file"""
        with open(file_path, 'r', encoding='utf-8') as f:
            return yaml.safe_load(f)
    
    @staticmethod
    def load_excel(file_path: str, sheet_name: str = None) -> List[Dict[str, Any]]:
        """Load test data from Excel file"""
        df = pd.read_excel(file_path, sheet_name=sheet_name)
        return df.to_dict('records')

# Test data file paths
TEST_DATA_DIR = Path(__file__).parent / "test_data"

# CSV data loading example
def load_api_test_data():
    """Load API test data"""
    csv_file = TEST_DATA_DIR / "api_test_cases.csv"
    if csv_file.exists():
        return ExternalTestDataLoader.load_csv(str(csv_file))
    else:
        # Fallback data
        return [
            {"endpoint": "/api/users", "method": "GET", "expected_status": 200},
            {"endpoint": "/api/users/1", "method": "GET", "expected_status": 200},
            {"endpoint": "/api/users/999", "method": "GET", "expected_status": 404}
        ]

# Complex test scenarios from JSON
def load_integration_test_scenarios():
    """Load integration test scenarios"""
    json_file = TEST_DATA_DIR / "integration_scenarios.json"
    if json_file.exists():
        return ExternalTestDataLoader.load_json(str(json_file))
    else:
        return []

# Parametrized test implementation
api_test_data = load_api_test_data()

@pytest.mark.parametrize(
    "test_data",
    api_test_data,
    ids=[f"{data['method']}_{data['endpoint']}" for data in api_test_data]
)
def test_api_endpoints(test_data, client):
    """External data-driven API test"""
    method = test_data["method"].lower()
    endpoint = test_data["endpoint"]
    expected_status = test_data["expected_status"]
    
    # Dynamic HTTP method invocation
    response = getattr(client, method)(endpoint)
    
    assert response.status_code == expected_status
    
    # Additional validation rules
    if "expected_keys" in test_data:
        response_json = response.json()
        for key in test_data["expected_keys"]:
            assert key in response_json
    
    if "response_validation" in test_data:
        validation_rules = test_data["response_validation"]
        response_json = response.json()
        
        for rule in validation_rules:
            field = rule["field"]
            condition = rule["condition"]
            value = rule["value"]
            
            if condition == "equals":
                assert response_json[field] == value
            elif condition == "contains":
                assert value in response_json[field]
            elif condition == "min_length":
                assert len(response_json[field]) >= value

# YAML-based test scenarios
@pytest.mark.parametrize(
    "scenario",
    load_integration_test_scenarios(),
    ids=lambda scenario: scenario.get("name", "unnamed_scenario")
)
def test_integration_scenarios(scenario, complete_test_environment):
    """YAML-defined integration test scenarios"""
    steps = scenario.get("steps", [])
    setup = scenario.get("setup", {})
    teardown = scenario.get("teardown", {})
    
    # Execute setup
    for setup_step in setup.get("actions", []):
        execute_test_action(setup_step, complete_test_environment)
    
    try:
        # Execute test steps
        for step in steps:
            execute_test_action(step, complete_test_environment)
    
    finally:
        # Execute teardown
        for teardown_step in teardown.get("actions", []):
            execute_test_action(teardown_step, complete_test_environment)

def execute_test_action(action: Dict[str, Any], test_env: Dict[str, Any]):
    """Execute test action"""
    action_type = action["type"]
    
    if action_type == "http_request":
        client = test_env["client"]
        method = action["method"].lower()
        url = action["url"]
        
        response = getattr(client, method)(url, **action.get("params", {}))
        
        # Assertions
        if "assertions" in action:
            for assertion in action["assertions"]:
                assert_type = assertion["type"]
                
                if assert_type == "status_code":
                    assert response.status_code == assertion["value"]
                elif assert_type == "response_contains":
                    assert assertion["value"] in response.text
    
    elif action_type == "database_query":
        db_session = test_env["db_session"]
        query = action["query"]
        
        result = db_session.execute(query)
        
        if "assertions" in action:
            for assertion in action["assertions"]:
                if assertion["type"] == "row_count":
                    assert result.rowcount == assertion["value"]
    
    elif action_type == "file_operation":
        temp_dir = test_env["temp_dir"]
        operation = action["operation"]
        
        if operation == "create_file":
            file_path = temp_dir / action["filename"]
            file_path.write_text(action["content"])
        elif operation == "check_file_exists":
            file_path = temp_dir / action["filename"]
            assert file_path.exists()

# Test data file generation helper
def generate_test_data_files():
    """Generate test data files (for development)"""
    # Generate CSV test data
    csv_data = [
        {"endpoint": "/api/users", "method": "GET", "expected_status": 200, "expected_keys": "id,username,email"},
        {"endpoint": "/api/users/1", "method": "GET", "expected_status": 200, "expected_keys": "id,username,email"},
        {"endpoint": "/api/users/999", "method": "GET", "expected_status": 404, "expected_keys": "error"},
        {"endpoint": "/api/users", "method": "POST", "expected_status": 201, "expected_keys": "id,username,email"}
    ]
    
    csv_file = TEST_DATA_DIR / "api_test_cases.csv"
    csv_file.parent.mkdir(exist_ok=True)
    
    with open(csv_file, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=csv_data[0].keys())
        writer.writeheader()
        writer.writerows(csv_data)
    
    # Generate JSON test scenarios
    scenarios = [
        {
            "name": "user_registration_flow",
            "description": "User registration flow test",
            "setup": {
                "actions": [
                    {"type": "database_query", "query": "DELETE FROM users WHERE username = 'testuser'"}
                ]
            },
            "steps": [
                {
                    "type": "http_request",
                    "method": "POST",
                    "url": "/api/register",
                    "params": {"json": {"username": "testuser", "email": "test@example.com", "password": "password123"}},
                    "assertions": [
                        {"type": "status_code", "value": 201},
                        {"type": "response_contains", "value": "testuser"}
                    ]
                },
                {
                    "type": "database_query",
                    "query": "SELECT COUNT(*) FROM users WHERE username = 'testuser'",
                    "assertions": [
                        {"type": "row_count", "value": 1}
                    ]
                }
            ],
            "teardown": {
                "actions": [
                    {"type": "database_query", "query": "DELETE FROM users WHERE username = 'testuser'"}
                ]
            }
        }
    ]
    
    json_file = TEST_DATA_DIR / "integration_scenarios.json"
    with open(json_file, 'w', encoding='utf-8') as f:
        json.dump(scenarios, f, indent=2, ensure_ascii=False)

# Advanced parametrization patterns for enterprise testing
@pytest.mark.parametrize("test_environment", ["development", "staging", "production"])
@pytest.mark.parametrize("user_role", ["admin", "user", "guest"])
@pytest.mark.parametrize("feature_flag", [True, False])
def test_feature_access_control(test_environment, user_role, feature_flag):
    """Feature access control testing across different environments and roles"""
    from myapp.access_control import check_feature_access
    
    # Environment-specific logic
    if test_environment == "production" and user_role == "guest":
        pytest.skip("Guest access not tested in production")
    
    access_granted = check_feature_access(
        environment=test_environment,
        user_role=user_role,
        feature_enabled=feature_flag
    )
    
    # Validate access logic
    if feature_flag and user_role in ["admin", "user"]:
        assert access_granted
    elif not feature_flag or user_role == "guest":
        assert not access_granted

@pytest.mark.parametrize(
    "load_config",
    [
        {"concurrent_users": 10, "duration": 30},
        {"concurrent_users": 50, "duration": 60},
        {"concurrent_users": 100, "duration": 120}
    ],
    ids=["light_load", "medium_load", "heavy_load"]
)
@pytest.mark.performance
def test_api_performance_under_load(load_config, api_client):
    """API performance testing under various load conditions"""
    import asyncio
    import time
    
    concurrent_users = load_config["concurrent_users"]
    duration = load_config["duration"]
    
    async def user_simulation():
        """Simulate user behavior"""
        start_time = time.time()
        requests_made = 0
        
        while time.time() - start_time < duration:
            response = await api_client.get("/api/health")
            assert response.status_code == 200
            requests_made += 1
            await asyncio.sleep(0.1)  # Small delay between requests
        
        return requests_made
    
    # Run concurrent user simulations
    loop = asyncio.get_event_loop()
    tasks = [user_simulation() for _ in range(concurrent_users)]
    results = loop.run_until_complete(asyncio.gather(*tasks))
    
    total_requests = sum(results)
    requests_per_second = total_requests / duration
    
    # Performance assertions
    assert requests_per_second > 10  # Minimum performance threshold
    print(f"Load test: {concurrent_users} users, {total_requests} requests, {requests_per_second:.2f} req/s")

if __name__ == "__main__":
    generate_test_data_files()
```