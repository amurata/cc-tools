## Property-Based Testing

### 1. Property-Based Testing with Hypothesis

```python
import pytest
from hypothesis import given, strategies as st, assume, example, settings
from hypothesis.stateful import RuleBasedStateMachine, rule, invariant
import string
import re
from typing import List, Dict, Any
import json

# Basic property-based testing
@given(st.integers(min_value=0, max_value=1000))
def test_fibonacci_properties(n):
    """Property test for Fibonacci sequence"""
    from myapp.math_utils import fibonacci
    
    result = fibonacci(n)
    
    # Property 1: Result is non-negative integer
    assert isinstance(result, int)
    assert result >= 0
    
    # Property 2: Fibonacci sequence properties
    if n >= 2:
        assert result == fibonacci(n-1) + fibonacci(n-2)
    elif n == 1:
        assert result == 1
    elif n == 0:
        assert result == 0

@given(st.lists(st.integers(), min_size=1))
def test_sorting_properties(numbers):
    """Property test for sorting function"""
    from myapp.algorithms import custom_sort
    
    sorted_numbers = custom_sort(numbers.copy())
    
    # Property 1: Length is preserved
    assert len(sorted_numbers) == len(numbers)
    
    # Property 2: All elements are included
    assert sorted(sorted_numbers) == sorted(numbers)
    
    # Property 3: Result is sorted
    for i in range(len(sorted_numbers) - 1):
        assert sorted_numbers[i] <= sorted_numbers[i + 1]
    
    # Property 4: Idempotent (sorting already sorted list doesn't change it)
    assert custom_sort(sorted_numbers) == sorted_numbers

# String processing property tests
@given(st.text(alphabet=string.ascii_letters + string.digits, min_size=1, max_size=100))
def test_string_validation_properties(input_string):
    """Property test for string validation"""
    from myapp.validators import validate_username
    
    result = validate_username(input_string)
    
    # Property 1: Result is a dictionary
    assert isinstance(result, dict)
    assert "is_valid" in result
    assert "errors" in result
    
    # Property 2: If is_valid is True, errors is empty
    if result["is_valid"]:
        assert len(result["errors"]) == 0
    
    # Property 3: Validation under specific conditions
    if len(input_string) < 3:
        assert not result["is_valid"]
        assert "too_short" in result["errors"]
    
    if len(input_string) > 50:
        assert not result["is_valid"]
        assert "too_long" in result["errors"]

# Complex data type property testing
user_strategy = st.fixed_dictionaries({
    "username": st.text(alphabet=string.ascii_letters, min_size=3, max_size=20),
    "email": st.emails(),
    "age": st.integers(min_value=13, max_value=120),
    "is_active": st.booleans()
})

@given(user_strategy)
def test_user_serialization_properties(user_data):
    """Property test for user data serialization"""
    from myapp.serializers import UserSerializer
    
    serializer = UserSerializer(user_data)
    
    # Serialization
    serialized = serializer.serialize()
    
    # Property 1: Serialized data is JSON string
    assert isinstance(serialized, str)
    
    # Property 2: Parseable as JSON
    parsed_data = json.loads(serialized)
    
    # Property 3: Matches original data
    assert parsed_data["username"] == user_data["username"]
    assert parsed_data["email"] == user_data["email"]
    assert parsed_data["age"] == user_data["age"]
    assert parsed_data["is_active"] == user_data["is_active"]
    
    # Property 4: Deserialization
    deserialized = UserSerializer.deserialize(serialized)
    assert deserialized == user_data

# Property testing with preconditions
@given(st.lists(st.integers(), min_size=2))
def test_binary_search_properties(numbers):
    """Property test for binary search"""
    from myapp.algorithms import binary_search
    
    # Precondition: Sort the list
    sorted_numbers = sorted(numbers)
    
    # Select target element
    target = sorted_numbers[len(sorted_numbers) // 2]
    
    result = binary_search(sorted_numbers, target)
    
    # Property 1: Index when found
    if result is not None:
        assert 0 <= result < len(sorted_numbers)
        assert sorted_numbers[result] == target
    
    # Property 2: Non-existent element not found
    assume(target + 1 not in sorted_numbers)  # Assumption
    not_found_result = binary_search(sorted_numbers, target + 1)
    assert not_found_result is None

# Property testing with settings
@settings(max_examples=1000, deadline=None)
@given(
    st.lists(
        st.tuples(st.text(), st.integers()),
        min_size=1,
        max_size=100
    )
)
def test_database_operations_properties(records):
    """Property test for database operations"""
    from myapp.database import InMemoryDatabase
    
    db = InMemoryDatabase()
    
    # Insert records
    for name, value in records:
        db.insert(name, value)
    
    # Property 1: Inserted record count matches stored record count
    assert db.count() == len(set(name for name, _ in records))  # Excluding duplicates
    
    # Property 2: Can retrieve inserted values
    for name, value in records:
        retrieved_value = db.get(name)
        if retrieved_value is not None:  # May be overwritten by duplicate
            assert isinstance(retrieved_value, int)

# Exception handling property tests
@given(st.text())
def test_email_validation_properties(input_text):
    """Property test for email validation"""
    from myapp.validators import validate_email
    
    result = validate_email(input_text)
    
    # Property 1: Result is boolean
    assert isinstance(result, bool)
    
    # Property 2: Basic email format properties
    has_at_symbol = "@" in input_text
    has_domain_dot = "@" in input_text and "." in input_text.split("@")[-1]
    
    if result:
        # Valid email conditions
        assert has_at_symbol
        assert has_domain_dot
        assert len(input_text) > 5  # Minimum length
    
    # Property 3: Obviously invalid cases
    if not has_at_symbol or input_text.count("@") != 1:
        assert not result

# Stateful property testing
class ShoppingCartStateMachine(RuleBasedStateMachine):
    """Shopping cart state machine test"""
    
    def __init__(self):
        super().__init__()
        self.cart = ShoppingCart()
        self.expected_items = {}
    
    @rule(product_id=st.integers(min_value=1, max_value=100),
          quantity=st.integers(min_value=1, max_value=10))
    def add_item(self, product_id, quantity):
        """Add item rule"""
        self.cart.add_item(product_id, quantity)
        
        if product_id in self.expected_items:
            self.expected_items[product_id] += quantity
        else:
            self.expected_items[product_id] = quantity
    
    @rule(product_id=st.integers(min_value=1, max_value=100))
    def remove_item(self, product_id):
        """Remove item rule"""
        if product_id in self.expected_items:
            self.cart.remove_item(product_id)
            del self.expected_items[product_id]
    
    @rule(product_id=st.integers(min_value=1, max_value=100),
          new_quantity=st.integers(min_value=1, max_value=10))
    def update_quantity(self, product_id, new_quantity):
        """Update quantity rule"""
        if product_id in self.expected_items:
            self.cart.update_quantity(product_id, new_quantity)
            self.expected_items[product_id] = new_quantity
    
    @rule()
    def clear_cart(self):
        """Clear cart rule"""
        self.cart.clear()
        self.expected_items.clear()
    
    @invariant()
    def cart_consistency(self):
        """Cart consistency invariant"""
        # Item count matches
        assert len(self.cart.items) == len(self.expected_items)
        
        # Each item quantity matches
        for product_id, expected_quantity in self.expected_items.items():
            assert self.cart.get_quantity(product_id) == expected_quantity
        
        # Total quantity matches
        expected_total = sum(self.expected_items.values())
        assert self.cart.total_quantity() == expected_total
        
        # Total price is positive when not empty
        if self.expected_items:
            assert self.cart.total_price() > 0

class ShoppingCart:
    """Shopping cart (test target)"""
    
    def __init__(self):
        self.items = {}
        self.price_per_item = 10  # Fixed price
    
    def add_item(self, product_id: int, quantity: int):
        if product_id in self.items:
            self.items[product_id] += quantity
        else:
            self.items[product_id] = quantity
    
    def remove_item(self, product_id: int):
        if product_id in self.items:
            del self.items[product_id]
    
    def update_quantity(self, product_id: int, quantity: int):
        if product_id in self.items:
            self.items[product_id] = quantity
    
    def get_quantity(self, product_id: int) -> int:
        return self.items.get(product_id, 0)
    
    def clear(self):
        self.items.clear()
    
    def total_quantity(self) -> int:
        return sum(self.items.values())
    
    def total_price(self) -> float:
        return sum(quantity * self.price_per_item for quantity in self.items.values())

# Execute stateful test
TestShoppingCart = ShoppingCartStateMachine.TestCase

# Examples for regression testing
@given(st.lists(st.integers()))
@example([])  # Empty list case
@example([1])  # Single element case
@example([1, 2, 3, 4, 5])  # Ordered list case
@example([5, 4, 3, 2, 1])  # Reverse ordered list case
def test_list_operations_with_examples(numbers):
    """List operation test with concrete examples"""
    from myapp.list_utils import process_list
    
    result = process_list(numbers)
    
    # Basic properties
    assert isinstance(result, list)
    assert len(result) == len(numbers)
    
    # Special handling for empty list
    if not numbers:
        assert result == []
    
    # Single element processing
    if len(numbers) == 1:
        assert result[0] == numbers[0] * 2  # Hypothetical processing rule

# Database query property testing
@given(
    st.lists(
        st.fixed_dictionaries({
            "id": st.integers(min_value=1),
            "name": st.text(min_size=1, max_size=50),
            "category": st.sampled_from(["A", "B", "C"])
        }),
        min_size=0,
        max_size=100
    )
)
def test_database_query_properties(records):
    """Property test for database queries"""
    from myapp.database import QueryBuilder
    
    # Insert test data
    query_builder = QueryBuilder()
    
    for record in records:
        query_builder.insert("products", record)
    
    # Category search properties
    for category in ["A", "B", "C"]:
        results = query_builder.select("products").where("category", category).execute()
        
        # Property 1: All results have specified category
        for result in results:
            assert result["category"] == category
        
        # Property 2: Count matches expected
        expected_count = len([r for r in records if r["category"] == category])
        assert len(results) == expected_count
    
    # Range search properties
    if records:
        min_id = min(r["id"] for r in records)
        max_id = max(r["id"] for r in records)
        
        results = query_builder.select("products").where("id", ">=", min_id).execute()
        assert len(results) == len(records)
        
        # Search with middle value
        mid_id = (min_id + max_id) // 2
        results = query_builder.select("products").where("id", ">", mid_id).execute()
        expected_count = len([r for r in records if r["id"] > mid_id])
        assert len(results) == expected_count

# Advanced property testing patterns
@given(st.data())
def test_data_transformation_properties(data):
    """Test data transformation properties using data strategy"""
    from myapp.transformers import DataTransformer
    
    # Generate related data
    input_data = data.draw(st.lists(st.integers(), min_size=1))
    transformation_type = data.draw(st.sampled_from(["scale", "shift", "normalize"]))
    
    transformer = DataTransformer(transformation_type)
    transformed = transformer.transform(input_data)
    
    # General properties
    assert len(transformed) == len(input_data)
    
    # Transformation-specific properties
    if transformation_type == "scale":
        scale_factor = data.draw(st.floats(min_value=0.1, max_value=10))
        expected = [x * scale_factor for x in input_data]
        assert all(abs(a - b) < 0.001 for a, b in zip(transformed, expected))
    
    elif transformation_type == "shift":
        shift_amount = data.draw(st.integers())
        expected = [x + shift_amount for x in input_data]
        assert transformed == expected
    
    elif transformation_type == "normalize":
        # Check normalization properties
        if len(input_data) > 1:
            mean = sum(transformed) / len(transformed)
            assert abs(mean) < 0.001  # Mean should be close to 0
            
            variance = sum((x - mean) ** 2 for x in transformed) / len(transformed)
            assert abs(variance - 1.0) < 0.1  # Variance should be close to 1

# Composite strategies for complex testing
address_strategy = st.fixed_dictionaries({
    "street": st.text(min_size=5, max_size=50),
    "city": st.text(min_size=2, max_size=30),
    "state": st.text(alphabet=string.ascii_uppercase, min_size=2, max_size=2),
    "zip_code": st.text(alphabet=string.digits, min_size=5, max_size=5)
})

person_strategy = st.fixed_dictionaries({
    "name": st.text(alphabet=string.ascii_letters + " ", min_size=2, max_size=50),
    "age": st.integers(min_value=0, max_value=120),
    "email": st.emails(),
    "address": address_strategy,
    "phone_numbers": st.lists(
        st.text(alphabet=string.digits, min_size=10, max_size=10),
        min_size=0,
        max_size=3
    )
})

@given(person_strategy)
def test_person_validation_properties(person_data):
    """Test person data validation properties"""
    from myapp.validators import PersonValidator
    
    validator = PersonValidator()
    result = validator.validate(person_data)
    
    # Basic validation properties
    assert isinstance(result, dict)
    assert "is_valid" in result
    assert "errors" in result
    
    # Age-specific validations
    if person_data["age"] < 0:
        assert not result["is_valid"]
        assert "invalid_age" in result["errors"]
    
    if person_data["age"] > 120:
        assert not result["is_valid"]
        assert "age_too_high" in result["errors"]
    
    # Address validation
    if len(person_data["address"]["zip_code"]) != 5:
        assert not result["is_valid"]
        assert "invalid_zip_code" in result["errors"]
    
    # Phone number validation
    for phone in person_data["phone_numbers"]:
        if len(phone) != 10:
            assert not result["is_valid"]
            assert "invalid_phone_number" in result["errors"]
            break

# Custom strategies for domain-specific testing
@st.composite
def valid_url_strategy(draw):
    """Generate valid URLs"""
    protocol = draw(st.sampled_from(["http", "https"]))
    domain = draw(st.text(alphabet=string.ascii_lowercase, min_size=3, max_size=20))
    tld = draw(st.sampled_from(["com", "org", "net", "io"]))
    path = draw(st.text(alphabet=string.ascii_letters + "/", min_size=0, max_size=50))
    
    return f"{protocol}://{domain}.{tld}/{path}"

@given(valid_url_strategy())
def test_url_parsing_properties(url):
    """Test URL parsing properties"""
    from myapp.parsers import URLParser
    
    parser = URLParser()
    parsed = parser.parse(url)
    
    # Parsing properties
    assert parsed is not None
    assert "protocol" in parsed
    assert "domain" in parsed
    assert "path" in parsed
    
    # Protocol validation
    assert parsed["protocol"] in ["http", "https"]
    
    # Reconstruction property
    reconstructed = f"{parsed['protocol']}://{parsed['domain']}{parsed['path']}"
    assert reconstructed == url or reconstructed == url.rstrip("/")
```