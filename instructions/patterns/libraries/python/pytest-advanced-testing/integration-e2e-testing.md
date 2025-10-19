## Integration & E2E Testing

### 1. Integration Test Patterns

```python
import pytest
import docker
import requests
import time
import subprocess
import signal
import os
from pathlib import Path
from typing import Dict, Any, List
import psycopg2
import redis
import tempfile
import shutil
import json

class TestEnvironmentManager:
    """Test environment management class"""
    
    def __init__(self):
        self.docker_client = docker.from_env()
        self.containers = {}
        self.processes = {}
        self.temp_dirs = []
    
    def start_postgres(self, container_name: str = "test_postgres") -> Dict[str, Any]:
        """Start PostgreSQL container"""
        try:
            # Stop and remove existing container
            existing = self.docker_client.containers.get(container_name)
            existing.stop()
            existing.remove()
        except docker.errors.NotFound:
            pass
        
        container = self.docker_client.containers.run(
            "postgres:14",
            name=container_name,
            environment={
                "POSTGRES_DB": "testdb",
                "POSTGRES_USER": "testuser",
                "POSTGRES_PASSWORD": "testpass"
            },
            ports={"5432/tcp": None},
            detach=True,
            remove=True
        )
        
        self.containers[container_name] = container
        
        # Wait for connection
        self._wait_for_postgres(container)
        
        port = container.attrs['NetworkSettings']['Ports']['5432/tcp'][0]['HostPort']
        
        return {
            "host": "localhost",
            "port": int(port),
            "database": "testdb",
            "username": "testuser",
            "password": "testpass",
            "connection_string": f"postgresql://testuser:testpass@localhost:{port}/testdb"
        }
    
    def start_redis(self, container_name: str = "test_redis") -> Dict[str, Any]:
        """Start Redis container"""
        try:
            existing = self.docker_client.containers.get(container_name)
            existing.stop()
            existing.remove()
        except docker.errors.NotFound:
            pass
        
        container = self.docker_client.containers.run(
            "redis:7",
            name=container_name,
            ports={"6379/tcp": None},
            detach=True,
            remove=True
        )
        
        self.containers[container_name] = container
        
        # Wait for connection
        self._wait_for_redis(container)
        
        port = container.attrs['NetworkSettings']['Ports']['6379/tcp'][0]['HostPort']
        
        return {
            "host": "localhost",
            "port": int(port),
            "connection_string": f"redis://localhost:{port}"
        }
    
    def start_web_application(self, app_path: str, env_vars: Dict[str, str] = None) -> Dict[str, Any]:
        """Start web application"""
        if env_vars is None:
            env_vars = {}
        
        # Set environment variables
        env = os.environ.copy()
        env.update(env_vars)
        
        # Start application
        process = subprocess.Popen(
            ["python", app_path],
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        
        self.processes["web_app"] = process
        
        # Wait for application startup
        self._wait_for_web_app("http://localhost:8000")
        
        return {
            "base_url": "http://localhost:8000",
            "process": process
        }
    
    def _wait_for_postgres(self, container, timeout: int = 30):
        """Wait for PostgreSQL connection"""
        port = container.attrs['NetworkSettings']['Ports']['5432/tcp'][0]['HostPort']
        
        for _ in range(timeout):
            try:
                conn = psycopg2.connect(
                    host="localhost",
                    port=port,
                    database="testdb",
                    user="testuser",
                    password="testpass"
                )
                conn.close()
                return
            except psycopg2.OperationalError:
                time.sleep(1)
        
        raise TimeoutError("PostgreSQL failed to start within timeout")
    
    def _wait_for_redis(self, container, timeout: int = 30):
        """Wait for Redis connection"""
        port = container.attrs['NetworkSettings']['Ports']['6379/tcp'][0]['HostPort']
        
        for _ in range(timeout):
            try:
                r = redis.Redis(host="localhost", port=port)
                r.ping()
                return
            except redis.ConnectionError:
                time.sleep(1)
        
        raise TimeoutError("Redis failed to start within timeout")
    
    def _wait_for_web_app(self, base_url: str, timeout: int = 30):
        """Wait for web application startup"""
        for _ in range(timeout):
            try:
                response = requests.get(f"{base_url}/health", timeout=5)
                if response.status_code == 200:
                    return
            except requests.RequestException:
                time.sleep(1)
        
        raise TimeoutError("Web application failed to start within timeout")
    
    def create_temp_directory(self) -> Path:
        """Create temporary directory"""
        temp_dir = Path(tempfile.mkdtemp())
        self.temp_dirs.append(temp_dir)
        return temp_dir
    
    def cleanup(self):
        """Clean up resources"""
        # Terminate processes
        for name, process in self.processes.items():
            if process.poll() is None:
                process.terminate()
                try:
                    process.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    process.kill()
        
        # Stop containers
        for name, container in self.containers.items():
            try:
                container.stop()
                container.remove()
            except docker.errors.NotFound:
                pass
        
        # Delete temporary directories
        for temp_dir in self.temp_dirs:
            if temp_dir.exists():
                shutil.rmtree(temp_dir, ignore_errors=True)

@pytest.fixture(scope="session")
def test_environment():
    """Test environment fixture"""
    manager = TestEnvironmentManager()
    yield manager
    manager.cleanup()

@pytest.fixture(scope="session")
def integration_setup(test_environment):
    """Integration test environment setup"""
    # Start PostgreSQL
    postgres_config = test_environment.start_postgres()
    
    # Start Redis
    redis_config = test_environment.start_redis()
    
    # Create configuration file
    config_dir = test_environment.create_temp_directory()
    config_file = config_dir / "test_config.json"
    
    config_data = {
        "database": {
            "url": postgres_config["connection_string"]
        },
        "redis": {
            "url": redis_config["connection_string"]
        },
        "logging": {
            "level": "INFO"
        }
    }
    
    config_file.write_text(json.dumps(config_data, indent=2))
    
    # Start web application
    app_config = test_environment.start_web_application(
        "myapp/main.py",
        {
            "CONFIG_FILE": str(config_file),
            "PORT": "8000"
        }
    )
    
    return {
        "postgres": postgres_config,
        "redis": redis_config,
        "web_app": app_config,
        "config_file": config_file
    }

# Integration test cases
@pytest.mark.integration
def test_user_registration_flow(integration_setup):
    """User registration flow integration test"""
    base_url = integration_setup["web_app"]["base_url"]
    
    # 1. User registration
    user_data = {
        "username": "integration_user",
        "email": "integration@example.com",
        "password": "password123"
    }
    
    response = requests.post(f"{base_url}/api/register", json=user_data)
    assert response.status_code == 201
    
    registration_result = response.json()
    assert "user_id" in registration_result
    assert registration_result["username"] == user_data["username"]
    
    user_id = registration_result["user_id"]
    
    # 2. User login
    login_data = {
        "username": user_data["username"],
        "password": user_data["password"]
    }
    
    response = requests.post(f"{base_url}/api/login", json=login_data)
    assert response.status_code == 200
    
    login_result = response.json()
    assert "access_token" in login_result
    
    access_token = login_result["access_token"]
    
    # 3. Authenticated API access
    headers = {"Authorization": f"Bearer {access_token}"}
    
    response = requests.get(f"{base_url}/api/profile", headers=headers)
    assert response.status_code == 200
    
    profile_data = response.json()
    assert profile_data["user_id"] == user_id
    assert profile_data["username"] == user_data["username"]
    
    # 4. Profile update
    update_data = {
        "email": "updated@example.com",
        "first_name": "Integration",
        "last_name": "Test"
    }
    
    response = requests.put(
        f"{base_url}/api/profile",
        json=update_data,
        headers=headers
    )
    assert response.status_code == 200
    
    # 5. Verify updated profile
    response = requests.get(f"{base_url}/api/profile", headers=headers)
    assert response.status_code == 200
    
    updated_profile = response.json()
    assert updated_profile["email"] == update_data["email"]
    assert updated_profile["first_name"] == update_data["first_name"]

@pytest.mark.integration
def test_data_consistency_across_services(integration_setup):
    """Data consistency test across services"""
    base_url = integration_setup["web_app"]["base_url"]
    
    # Create user
    user_data = {
        "username": "consistency_user",
        "email": "consistency@example.com",
        "password": "password123"
    }
    
    response = requests.post(f"{base_url}/api/register", json=user_data)
    user_id = response.json()["user_id"]
    
    # Login and get token
    login_response = requests.post(f"{base_url}/api/login", json={
        "username": user_data["username"],
        "password": user_data["password"]
    })
    
    access_token = login_response.json()["access_token"]
    headers = {"Authorization": f"Bearer {access_token}"}
    
    # Verify user in database directly
    postgres_config = integration_setup["postgres"]
    conn = psycopg2.connect(postgres_config["connection_string"])
    cursor = conn.cursor()
    
    cursor.execute("SELECT username, email FROM users WHERE id = %s", (user_id,))
    db_user = cursor.fetchone()
    
    assert db_user[0] == user_data["username"]
    assert db_user[1] == user_data["email"]
    
    # Verify user info in cache
    redis_config = integration_setup["redis"]
    r = redis.Redis.from_url(redis_config["connection_string"])
    
    cached_user_key = f"user:{user_id}"
    cached_data = r.get(cached_user_key)
    
    if cached_data:
        cached_user = json.loads(cached_data)
        assert cached_user["username"] == user_data["username"]
        assert cached_user["email"] == user_data["email"]
    
    # Verify info via API
    api_response = requests.get(f"{base_url}/api/profile", headers=headers)
    api_user = api_response.json()
    
    assert api_user["username"] == user_data["username"]
    assert api_user["email"] == user_data["email"]
    
    # Cleanup
    cursor.close()
    conn.close()

@pytest.mark.integration
def test_error_handling_across_services(integration_setup):
    """Error handling test across services"""
    base_url = integration_setup["web_app"]["base_url"]
    
    # 1. User registration with invalid data
    invalid_user_data = {
        "username": "",  # Invalid username
        "email": "invalid-email",  # Invalid email format
        "password": "123"  # Short password
    }
    
    response = requests.post(f"{base_url}/api/register", json=invalid_user_data)
    assert response.status_code == 400
    
    error_response = response.json()
    assert "errors" in error_response
    assert len(error_response["errors"]) > 0
    
    # 2. Login with non-existent user
    response = requests.post(f"{base_url}/api/login", json={
        "username": "nonexistent",
        "password": "password"
    })
    assert response.status_code == 401
    
    # 3. API access with invalid token
    invalid_headers = {"Authorization": "Bearer invalid_token"}
    
    response = requests.get(f"{base_url}/api/profile", headers=invalid_headers)
    assert response.status_code == 401
    
    # 4. Unauthorized resource access
    # First create normal user
    user_data = {
        "username": "normal_user",
        "email": "normal@example.com",
        "password": "password123"
    }
    
    requests.post(f"{base_url}/api/register", json=user_data)
    
    login_response = requests.post(f"{base_url}/api/login", json={
        "username": user_data["username"],
        "password": user_data["password"]
    })
    
    user_token = login_response.json()["access_token"]
    user_headers = {"Authorization": f"Bearer {user_token}"}
    
    # Attempt to access admin-only endpoint
    response = requests.get(f"{base_url}/api/admin/users", headers=user_headers)
    assert response.status_code == 403
```

### 2. E2E Test Patterns

```python
import pytest
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.chrome.options import Options
import time
from typing import Dict, Any
import os

class WebDriverManager:
    """WebDriver management class"""
    
    def __init__(self, headless: bool = True):
        self.headless = headless
        self.driver = None
    
    def get_driver(self) -> webdriver.Chrome:
        """Get WebDriver instance"""
        if self.driver is None:
            chrome_options = Options()
            
            if self.headless:
                chrome_options.add_argument("--headless")
            
            chrome_options.add_argument("--no-sandbox")
            chrome_options.add_argument("--disable-dev-shm-usage")
            chrome_options.add_argument("--window-size=1920,1080")
            
            self.driver = webdriver.Chrome(options=chrome_options)
            self.driver.implicitly_wait(10)
        
        return self.driver
    
    def quit(self):
        """Quit WebDriver"""
        if self.driver:
            self.driver.quit()
            self.driver = None

class PageObjectModel:
    """Base class for Page Object Model"""
    
    def __init__(self, driver: webdriver.Chrome, base_url: str):
        self.driver = driver
        self.base_url = base_url
        self.wait = WebDriverWait(driver, 10)
    
    def navigate_to(self, path: str = ""):
        """Navigate to page"""
        url = f"{self.base_url}{path}"
        self.driver.get(url)
    
    def wait_for_element(self, locator, timeout: int = 10):
        """Wait for element to be present"""
        wait = WebDriverWait(self.driver, timeout)
        return wait.until(EC.presence_of_element_located(locator))
    
    def wait_for_clickable(self, locator, timeout: int = 10):
        """Wait for element to be clickable"""
        wait = WebDriverWait(self.driver, timeout)
        return wait.until(EC.element_to_be_clickable(locator))

class LoginPage(PageObjectModel):
    """Login page"""
    
    # Locators
    USERNAME_INPUT = (By.ID, "username")
    PASSWORD_INPUT = (By.ID, "password")
    LOGIN_BUTTON = (By.ID, "login-button")
    ERROR_MESSAGE = (By.CLASS_NAME, "error-message")
    
    def navigate(self):
        """Navigate to login page"""
        self.navigate_to("/login")
    
    def enter_username(self, username: str):
        """Enter username"""
        username_field = self.wait_for_element(self.USERNAME_INPUT)
        username_field.clear()
        username_field.send_keys(username)
    
    def enter_password(self, password: str):
        """Enter password"""
        password_field = self.wait_for_element(self.PASSWORD_INPUT)
        password_field.clear()
        password_field.send_keys(password)
    
    def click_login(self):
        """Click login button"""
        login_button = self.wait_for_clickable(self.LOGIN_BUTTON)
        login_button.click()
    
    def get_error_message(self) -> str:
        """Get error message"""
        try:
            error_element = self.wait_for_element(self.ERROR_MESSAGE, timeout=5)
            return error_element.text
        except:
            return ""
    
    def login(self, username: str, password: str):
        """Perform login"""
        self.enter_username(username)
        self.enter_password(password)
        self.click_login()

class DashboardPage(PageObjectModel):
    """Dashboard page"""
    
    # Locators
    WELCOME_MESSAGE = (By.CLASS_NAME, "welcome-message")
    USER_MENU = (By.ID, "user-menu")
    LOGOUT_LINK = (By.ID, "logout-link")
    NAVIGATION_MENU = (By.CLASS_NAME, "nav-menu")
    
    def is_loaded(self) -> bool:
        """Check if page is loaded"""
        try:
            self.wait_for_element(self.WELCOME_MESSAGE, timeout=5)
            return True
        except:
            return False
    
    def get_welcome_message(self) -> str:
        """Get welcome message"""
        welcome_element = self.wait_for_element(self.WELCOME_MESSAGE)
        return welcome_element.text
    
    def logout(self):
        """Perform logout"""
        user_menu = self.wait_for_clickable(self.USER_MENU)
        user_menu.click()
        
        logout_link = self.wait_for_clickable(self.LOGOUT_LINK)
        logout_link.click()

class UserProfilePage(PageObjectModel):
    """User profile page"""
    
    # Locators
    EMAIL_INPUT = (By.ID, "email")
    FIRST_NAME_INPUT = (By.ID, "first-name")
    LAST_NAME_INPUT = (By.ID, "last-name")
    SAVE_BUTTON = (By.ID, "save-profile")
    SUCCESS_MESSAGE = (By.CLASS_NAME, "success-message")
    
    def navigate(self):
        """Navigate to profile page"""
        self.navigate_to("/profile")
    
    def update_profile(self, email: str = None, first_name: str = None, last_name: str = None):
        """Update profile"""
        if email:
            email_field = self.wait_for_element(self.EMAIL_INPUT)
            email_field.clear()
            email_field.send_keys(email)
        
        if first_name:
            first_name_field = self.wait_for_element(self.FIRST_NAME_INPUT)
            first_name_field.clear()
            first_name_field.send_keys(first_name)
        
        if last_name:
            last_name_field = self.wait_for_element(self.LAST_NAME_INPUT)
            last_name_field.clear()
            last_name_field.send_keys(last_name)
        
        save_button = self.wait_for_clickable(self.SAVE_BUTTON)
        save_button.click()
    
    def get_success_message(self) -> str:
        """Get success message"""
        try:
            success_element = self.wait_for_element(self.SUCCESS_MESSAGE, timeout=5)
            return success_element.text
        except:
            return ""

@pytest.fixture(scope="session")
def webdriver_manager():
    """WebDriver manager fixture"""
    manager = WebDriverManager(headless=os.getenv("HEADLESS", "true").lower() == "true")
    yield manager
    manager.quit()

@pytest.fixture
def driver(webdriver_manager):
    """WebDriver fixture"""
    return webdriver_manager.get_driver()

@pytest.fixture
def base_url():
    """Base URL fixture"""
    return os.getenv("BASE_URL", "http://localhost:8000")

@pytest.fixture
def login_page(driver, base_url):
    """Login page fixture"""
    return LoginPage(driver, base_url)

@pytest.fixture
def dashboard_page(driver, base_url):
    """Dashboard page fixture"""
    return DashboardPage(driver, base_url)

@pytest.fixture
def profile_page(driver, base_url):
    """Profile page fixture"""
    return UserProfilePage(driver, base_url)

# E2E test cases
@pytest.mark.e2e
def test_user_login_flow(login_page, dashboard_page):
    """User login flow E2E test"""
    # Navigate to login page
    login_page.navigate()
    
    # Perform login
    login_page.login("testuser", "password123")
    
    # Verify dashboard page
    assert dashboard_page.is_loaded()
    
    welcome_message = dashboard_page.get_welcome_message()
    assert "Welcome" in welcome_message
    assert "testuser" in welcome_message

@pytest.mark.e2e
def test_invalid_login(login_page):
    """Invalid login E2E test"""
    login_page.navigate()
    
    # Attempt login with invalid credentials
    login_page.login("invalid_user", "wrong_password")
    
    # Verify error message
    error_message = login_page.get_error_message()
    assert "Invalid username or password" in error_message

@pytest.mark.e2e
def test_profile_update_flow(login_page, dashboard_page, profile_page):
    """Profile update flow E2E test"""
    # Login
    login_page.navigate()
    login_page.login("testuser", "password123")
    
    # Verify dashboard
    assert dashboard_page.is_loaded()
    
    # Navigate to profile page
    profile_page.navigate()
    
    # Update profile
    profile_page.update_profile(
        email="updated@example.com",
        first_name="Updated",
        last_name="User"
    )
    
    # Verify success message
    success_message = profile_page.get_success_message()
    assert "Profile updated successfully" in success_message

@pytest.mark.e2e
def test_complete_user_journey(login_page, dashboard_page, profile_page):
    """Complete user journey E2E test"""
    # 1. Login
    login_page.navigate()
    login_page.login("journey_user", "password123")
    assert dashboard_page.is_loaded()
    
    # 2. Dashboard operations
    welcome_message = dashboard_page.get_welcome_message()
    assert "journey_user" in welcome_message
    
    # 3. Profile editing
    profile_page.navigate()
    profile_page.update_profile(
        email="journey@example.com",
        first_name="Journey",
        last_name="Test"
    )
    
    success_message = profile_page.get_success_message()
    assert success_message != ""
    
    # 4. Logout
    dashboard_page.navigate_to("/dashboard")
    dashboard_page.logout()
    
    # 5. Verify post-logout (redirect to login page)
    time.sleep(2)  # Wait for redirect
    current_url = login_page.driver.current_url
    assert "/login" in current_url

# Mobile browser E2E testing
@pytest.mark.e2e
@pytest.mark.mobile
def test_mobile_responsive_design(driver, base_url):
    """Mobile responsive design E2E test"""
    # Change to mobile size
    driver.set_window_size(375, 667)  # iPhone 6/7/8 size
    
    # Access page
    driver.get(f"{base_url}/login")
    
    # Verify mobile-specific elements
    mobile_menu_button = driver.find_element(By.CLASS_NAME, "mobile-menu-toggle")
    assert mobile_menu_button.is_displayed()
    
    # Verify form usability
    username_field = driver.find_element(By.ID, "username")
    assert username_field.size["height"] >= 44  # Touch-friendly size

# Accessibility testing
@pytest.mark.e2e
@pytest.mark.accessibility
def test_accessibility_features(driver, base_url):
    """Accessibility features E2E test"""
    driver.get(f"{base_url}/login")
    
    # Verify focusable elements
    username_field = driver.find_element(By.ID, "username")
    username_field.click()
    
    # Verify Tab key navigation
    username_field.send_keys(Keys.TAB)
    
    # Verify currently focused element
    focused_element = driver.switch_to.active_element
    assert focused_element.get_attribute("id") == "password"
    
    # Verify ARIA attributes
    login_button = driver.find_element(By.ID, "login-button")
    assert login_button.get_attribute("aria-label") is not None

# Performance testing
@pytest.mark.e2e
@pytest.mark.performance
def test_page_load_performance(driver, base_url):
    """Page load performance E2E test"""
    start_time = time.time()
    
    driver.get(f"{base_url}/dashboard")
    
    # Wait for complete DOM load
    WebDriverWait(driver, 10).until(
        lambda d: d.execute_script("return document.readyState") == "complete"
    )
    
    load_time = time.time() - start_time
    
    # Expect completion within 3 seconds
    assert load_time < 3.0
    
    # Verify page size
    page_source_size = len(driver.page_source.encode('utf-8'))
    assert page_source_size < 1024 * 1024  # Less than 1MB

# Cross-browser testing with parameterization
@pytest.mark.parametrize("browser", ["chrome", "firefox"])
@pytest.mark.e2e
def test_cross_browser_compatibility(browser, base_url):
    """Cross-browser compatibility E2E test"""
    if browser == "chrome":
        options = Options()
        options.add_argument("--headless")
        driver = webdriver.Chrome(options=options)
    elif browser == "firefox":
        from selenium.webdriver.firefox.options import Options as FirefoxOptions
        options = FirefoxOptions()
        options.add_argument("--headless")
        driver = webdriver.Firefox(options=options)
    
    try:
        driver.get(f"{base_url}/login")
        
        # Verify basic element presence
        username_field = driver.find_element(By.ID, "username")
        password_field = driver.find_element(By.ID, "password")
        login_button = driver.find_element(By.ID, "login-button")
        
        assert username_field.is_displayed()
        assert password_field.is_displayed()
        assert login_button.is_displayed()
        
        # Verify browser-specific JavaScript functionality
        js_result = driver.execute_script("return navigator.userAgent")
        assert js_result is not None
        
    finally:
        driver.quit()

# Data-driven E2E testing
@pytest.mark.e2e
@pytest.mark.parametrize("test_data", [
    {"username": "user1", "password": "pass1", "expected": "success"},
    {"username": "user2", "password": "pass2", "expected": "success"},
    {"username": "invalid", "password": "wrong", "expected": "failure"}
])
def test_login_scenarios(login_page, dashboard_page, test_data):
    """Data-driven login scenarios E2E test"""
    login_page.navigate()
    login_page.login(test_data["username"], test_data["password"])
    
    if test_data["expected"] == "success":
        assert dashboard_page.is_loaded()
    else:
        error_message = login_page.get_error_message()
        assert error_message != ""

# Visual regression testing
@pytest.mark.e2e
@pytest.mark.visual
def test_visual_regression(driver, base_url):
    """Visual regression E2E test"""
    driver.get(f"{base_url}/login")
    
    # Take screenshot for comparison
    screenshot_path = "screenshots/login_page.png"
    driver.save_screenshot(screenshot_path)
    
    # Compare with baseline (using image comparison library)
    from PIL import Image, ImageChops
    
    current_image = Image.open(screenshot_path)
    baseline_image = Image.open("screenshots/baseline/login_page.png")
    
    # Calculate difference
    diff = ImageChops.difference(current_image, baseline_image)
    
    # Check if images are similar enough
    bbox = diff.getbbox()
    assert bbox is None or calculate_difference_percentage(diff) < 5.0

def calculate_difference_percentage(diff_image):
    """Calculate percentage difference between images"""
    pixels = diff_image.getdata()
    total_pixels = len(pixels)
    different_pixels = sum(1 for pixel in pixels if sum(pixel) > 0)
    return (different_pixels / total_pixels) * 100

# Security testing
@pytest.mark.e2e
@pytest.mark.security
def test_security_headers(driver, base_url):
    """Security headers E2E test"""
    driver.get(f"{base_url}/login")
    
    # Check for security headers using JavaScript
    headers_check = driver.execute_script("""
        return {
            csp: document.querySelector('meta[http-equiv="Content-Security-Policy"]'),
            xframe: document.querySelector('meta[http-equiv="X-Frame-Options"]')
        }
    """)
    
    # Verify security policies are present
    assert headers_check["csp"] is not None or "Content-Security-Policy" in driver.page_source
    
    # Check for HTTPS redirect
    if "https" in base_url:
        assert driver.current_url.startswith("https://")
```

This comprehensive Pytest Advanced Testing Patterns document includes all enterprise-level testing implementation elements needed.