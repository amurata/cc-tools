# Android Development Patterns

Native Android development patterns using Kotlin and Jetpack Compose.

## Jetpack Compose Architecture

### MVVM with Compose
```kotlin
import androidx.compose.runtime.*
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch

// Model
data class User(
    val id: String,
    val name: String,
    val email: String,
    val avatarUrl: String? = null
)

// UI State
data class UserListUiState(
    val users: List<User> = emptyList(),
    val isLoading: Boolean = false,
    val error: String? = null
)

// ViewModel
class UserListViewModel(
    private val repository: UserRepository
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(UserListUiState())
    val uiState: StateFlow<UserListUiState> = _uiState.asStateFlow()
    
    init {
        loadUsers()
    }
    
    fun loadUsers() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }
            
            repository.getUsers()
                .onSuccess { users ->
                    _uiState.update { 
                        it.copy(users = users, isLoading = false)
                    }
                }
                .onFailure { exception ->
                    _uiState.update { 
                        it.copy(
                            error = exception.message,
                            isLoading = false
                        )
                    }
                }
        }
    }
}

// Composable UI
@Composable
fun UserListScreen(
    viewModel: UserListViewModel = viewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    
    Scaffold(
        topBar = {
            TopAppBar(title = { Text("Users") })
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            when {
                uiState.isLoading -> {
                    CircularProgressIndicator(
                        modifier = Modifier.align(Alignment.Center)
                    )
                }
                uiState.error != null -> {
                    ErrorMessage(
                        message = uiState.error,
                        onRetry = { viewModel.loadUsers() }
                    )
                }
                else -> {
                    LazyColumn {
                        items(uiState.users) { user ->
                            UserItem(user = user)
                        }
                    }
                }
            }
        }
    }
}
```

## Dependency Injection with Hilt

### Hilt Setup
```kotlin
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.HiltAndroidApp
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@HiltAndroidApp
class MyApplication : Application()

// Network Module
@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {
    
    @Provides
    @Singleton
    fun provideOkHttpClient(): OkHttpClient {
        return OkHttpClient.Builder()
            .addInterceptor(AuthInterceptor())
            .addInterceptor(HttpLoggingInterceptor().apply {
                level = HttpLoggingInterceptor.Level.BODY
            })
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .build()
    }
    
    @Provides
    @Singleton
    fun provideRetrofit(okHttpClient: OkHttpClient): Retrofit {
        return Retrofit.Builder()
            .baseUrl("https://api.example.com/")
            .client(okHttpClient)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
    }
    
    @Provides
    @Singleton
    fun provideApiService(retrofit: Retrofit): ApiService {
        return retrofit.create(ApiService::class.java)
    }
}

// Repository Module
@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {
    
    @Binds
    abstract fun bindUserRepository(
        userRepositoryImpl: UserRepositoryImpl
    ): UserRepository
}

// ViewModel with Hilt
@HiltViewModel
class UserListViewModel @Inject constructor(
    private val repository: UserRepository,
    savedStateHandle: SavedStateHandle
) : ViewModel() {
    // ViewModel implementation
}
```

## Navigation

### Compose Navigation
```kotlin
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController

// Navigation routes
sealed class Screen(val route: String) {
    object Home : Screen("home")
    object Profile : Screen("profile/{userId}") {
        fun createRoute(userId: String) = "profile/$userId"
    }
    object Settings : Screen("settings")
}

// Navigation setup
@Composable
fun AppNavigation(
    navController: NavHostController = rememberNavController()
) {
    NavHost(
        navController = navController,
        startDestination = Screen.Home.route
    ) {
        composable(Screen.Home.route) {
            HomeScreen(
                onNavigateToProfile = { userId ->
                    navController.navigate(Screen.Profile.createRoute(userId))
                }
            )
        }
        
        composable(
            route = Screen.Profile.route,
            arguments = listOf(
                navArgument("userId") {
                    type = NavType.StringType
                }
            )
        ) { backStackEntry ->
            val userId = backStackEntry.arguments?.getString("userId") ?: ""
            ProfileScreen(userId = userId)
        }
        
        composable(Screen.Settings.route) {
            SettingsScreen()
        }
    }
}
```

## Data Layer

### Repository Pattern with Flow
```kotlin
interface UserRepository {
    fun getUsers(): Flow<List<User>>
    suspend fun getUserById(id: String): Result<User>
    suspend fun updateUser(user: User): Result<Unit>
}

@Singleton
class UserRepositoryImpl @Inject constructor(
    private val apiService: ApiService,
    private val userDao: UserDao,
    private val dispatcher: CoroutineDispatcher = Dispatchers.IO
) : UserRepository {
    
    override fun getUsers(): Flow<List<User>> = flow {
        // Emit cached data first
        emit(userDao.getAllUsers())
        
        // Fetch fresh data
        try {
            val remoteUsers = apiService.getUsers()
            userDao.insertAll(remoteUsers)
            emit(remoteUsers)
        } catch (e: Exception) {
            // Emit error but keep cached data
            // Error handling
        }
    }.flowOn(dispatcher)
    
    override suspend fun getUserById(id: String): Result<User> = 
        withContext(dispatcher) {
            try {
                val user = apiService.getUserById(id)
                userDao.insert(user)
                Result.success(user)
            } catch (e: Exception) {
                // Try to get from cache
                val cachedUser = userDao.getUserById(id)
                if (cachedUser != null) {
                    Result.success(cachedUser)
                } else {
                    Result.failure(e)
                }
            }
        }
}
```

## Room Database

### Room Setup with Kotlin
```kotlin
import androidx.room.*
import kotlinx.coroutines.flow.Flow

// Entity
@Entity(tableName = "users")
data class UserEntity(
    @PrimaryKey val id: String,
    val name: String,
    val email: String,
    @ColumnInfo(name = "avatar_url") val avatarUrl: String?,
    @ColumnInfo(name = "created_at") val createdAt: Long,
    @ColumnInfo(name = "updated_at") val updatedAt: Long
)

// DAO
@Dao
interface UserDao {
    @Query("SELECT * FROM users ORDER BY name ASC")
    fun getAllUsers(): Flow<List<UserEntity>>
    
    @Query("SELECT * FROM users WHERE id = :userId")
    suspend fun getUserById(userId: String): UserEntity?
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(user: UserEntity)
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(users: List<UserEntity>)
    
    @Delete
    suspend fun delete(user: UserEntity)
    
    @Query("DELETE FROM users")
    suspend fun deleteAll()
}

// Database
@Database(
    entities = [UserEntity::class],
    version = 1,
    exportSchema = false
)
@TypeConverters(Converters::class)
abstract class AppDatabase : RoomDatabase() {
    abstract fun userDao(): UserDao
}

// Type Converters
class Converters {
    @TypeConverter
    fun fromTimestamp(value: Long?): Date? {
        return value?.let { Date(it) }
    }
    
    @TypeConverter
    fun dateToTimestamp(date: Date?): Long? {
        return date?.time
    }
}

// Database Module
@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {
    
    @Provides
    @Singleton
    fun provideAppDatabase(
        @ApplicationContext context: Context
    ): AppDatabase {
        return Room.databaseBuilder(
            context,
            AppDatabase::class.java,
            "app_database"
        )
        .fallbackToDestructiveMigration()
        .build()
    }
    
    @Provides
    fun provideUserDao(database: AppDatabase): UserDao {
        return database.userDao()
    }
}
```

## State Management

### State Hoisting
```kotlin
@Composable
fun SearchScreen() {
    var searchQuery by remember { mutableStateOf("") }
    var searchResults by remember { mutableStateOf(emptyList<SearchResult>()) }
    
    SearchContent(
        query = searchQuery,
        results = searchResults,
        onQueryChange = { searchQuery = it },
        onSearch = { 
            // Perform search
        }
    )
}

@Composable
fun SearchContent(
    query: String,
    results: List<SearchResult>,
    onQueryChange: (String) -> Unit,
    onSearch: () -> Unit
) {
    Column {
        SearchBar(
            query = query,
            onQueryChange = onQueryChange,
            onSearch = onSearch
        )
        
        LazyColumn {
            items(results) { result ->
                SearchResultItem(result)
            }
        }
    }
}
```

## Testing

### Unit Testing with MockK
```kotlin
import io.mockk.*
import kotlinx.coroutines.test.*
import org.junit.Before
import org.junit.Test
import kotlin.test.assertEquals

class UserRepositoryTest {
    
    private lateinit var repository: UserRepository
    private lateinit var apiService: ApiService
    private lateinit var userDao: UserDao
    private val testDispatcher = StandardTestDispatcher()
    
    @Before
    fun setup() {
        apiService = mockk()
        userDao = mockk()
        repository = UserRepositoryImpl(
            apiService = apiService,
            userDao = userDao,
            dispatcher = testDispatcher
        )
    }
    
    @Test
    fun `getUsers returns cached data when API fails`() = runTest {
        // Given
        val cachedUsers = listOf(
            User("1", "John", "john@example.com")
        )
        coEvery { userDao.getAllUsers() } returns cachedUsers
        coEvery { apiService.getUsers() } throws Exception("Network error")
        
        // When
        val result = repository.getUsers().first()
        
        // Then
        assertEquals(cachedUsers, result)
        coVerify { userDao.getAllUsers() }
    }
}
```

### UI Testing with Compose
```kotlin
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import org.junit.Rule
import org.junit.Test

class UserListScreenTest {
    
    @get:Rule
    val composeTestRule = createComposeRule()
    
    @Test
    fun userList_displaysUsers() {
        // Given
        val users = listOf(
            User("1", "John Doe", "john@example.com"),
            User("2", "Jane Doe", "jane@example.com")
        )
        
        // When
        composeTestRule.setContent {
            UserListScreen(
                uiState = UserListUiState(users = users),
                onUserClick = {}
            )
        }
        
        // Then
        composeTestRule.onNodeWithText("John Doe").assertIsDisplayed()
        composeTestRule.onNodeWithText("Jane Doe").assertIsDisplayed()
    }
    
    @Test
    fun userList_showsLoadingIndicator() {
        // When
        composeTestRule.setContent {
            UserListScreen(
                uiState = UserListUiState(isLoading = true),
                onUserClick = {}
            )
        }
        
        // Then
        composeTestRule.onNode(
            hasTestTag("loading_indicator")
        ).assertIsDisplayed()
    }
}
```

## Performance Optimization

### Compose Performance
```kotlin
// Stable data classes
@Stable
data class UserUiModel(
    val id: String,
    val name: String,
    val avatarUrl: String?
)

// Remember calculations
@Composable
fun ExpensiveComponent(data: List<Item>) {
    val processedData = remember(data) {
        data.filter { it.isVisible }
            .sortedBy { it.priority }
    }
    
    LazyColumn {
        items(
            items = processedData,
            key = { it.id } // Stable keys for recomposition
        ) { item ->
            ItemRow(item)
        }
    }
}

// Derivedstateof for expensive operations
@Composable
fun SearchResults(items: List<Item>, query: String) {
    val filteredItems by remember(items, query) {
        derivedStateOf {
            if (query.isEmpty()) items
            else items.filter { it.name.contains(query, ignoreCase = true) }
        }
    }
    
    LazyColumn {
        items(filteredItems) { item ->
            ItemCard(item)
        }
    }
}
```

## Checklist
- [ ] Set up Jetpack Compose
- [ ] Configure Hilt dependency injection
- [ ] Implement navigation
- [ ] Set up Room database
- [ ] Add repository pattern
- [ ] Configure Retrofit
- [ ] Write unit tests
- [ ] Add UI tests