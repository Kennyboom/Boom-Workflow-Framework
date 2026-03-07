---
name: android-native
description: Build production-grade Android apps with Kotlin and Jetpack Compose. Covers MVVM + Clean Architecture, Hilt DI, Coroutines/Flow, Room/DataStore, Material Design 3, and Gradle KTS configuration.
---

# Android Native Expert

Expert guidance for native Android development with Kotlin, Jetpack Compose, and modern Android architecture.

## When to Use

- Building native Android applications
- Jetpack Compose UI development
- Android architecture (MVVM + Clean Architecture)
- Kotlin patterns and coroutines
- Gradle build configuration

---

## 1. Project Structure (Clean Architecture)

```
app/src/main/java/com/example/app/
├── di/                          # Hilt modules
│   ├── AppModule.kt
│   ├── NetworkModule.kt
│   └── DatabaseModule.kt
├── data/
│   ├── remote/
│   │   ├── api/                 # Retrofit interfaces
│   │   └── dto/                 # Data Transfer Objects
│   ├── local/
│   │   ├── dao/                 # Room DAOs
│   │   ├── entity/              # Room entities
│   │   └── datastore/           # DataStore preferences
│   └── repository/              # Repository implementations
├── domain/
│   ├── model/                   # Domain models
│   ├── repository/              # Repository interfaces
│   └── usecase/                 # Use cases
└── presentation/
    ├── navigation/              # NavHost, routes
    ├── theme/                   # Material 3 theme
    └── feature/
        └── home/
            ├── HomeScreen.kt    # Composable
            └── HomeViewModel.kt
```

## 2. Jetpack Compose

### Composable Best Practices
```kotlin
@Composable
fun UserCard(
    user: User,
    onTap: (String) -> Unit,
    modifier: Modifier = Modifier  // Always accept modifier
) {
    Card(
        modifier = modifier
            .fillMaxWidth()
            .clickable { onTap(user.id) },
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                text = user.name,
                style = MaterialTheme.typography.titleMedium
            )
            Text(
                text = user.email,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}
```

### State Management in Compose
```kotlin
@Composable
fun CounterScreen(viewModel: CounterViewModel = hiltViewModel()) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

    // Derived state — only recomposes when condition changes
    val showWarning by remember { derivedStateOf { uiState.count > 10 } }

    Column {
        Text("Count: ${uiState.count}")
        if (showWarning) Text("Warning: count is high!", color = Color.Red)
        Button(onClick = viewModel::increment) { Text("Increment") }
    }
}
```

### Side Effects
```kotlin
@Composable
fun ProfileScreen(userId: String, viewModel: ProfileViewModel = hiltViewModel()) {
    // Run once when userId changes
    LaunchedEffect(userId) {
        viewModel.loadProfile(userId)
    }

    // Lifecycle-aware collection
    val profile by viewModel.profile.collectAsStateWithLifecycle()

    // Snackbar with SnackbarHostState
    val snackbarHost = remember { SnackbarHostState() }
    LaunchedEffect(viewModel.errorEvents) {
        viewModel.errorEvents.collect { message ->
            snackbarHost.showSnackbar(message)
        }
    }
}
```

## 3. Architecture (MVVM + Clean)

### ViewModel
```kotlin
@HiltViewModel
class ProductListViewModel @Inject constructor(
    private val getProducts: GetProductsUseCase,
    private val deleteProduct: DeleteProductUseCase,
) : ViewModel() {

    private val _uiState = MutableStateFlow(ProductListUiState())
    val uiState: StateFlow<ProductListUiState> = _uiState.asStateFlow()

    // One-time events (navigation, snackbar)
    private val _events = Channel<UiEvent>(Channel.BUFFERED)
    val events: Flow<UiEvent> = _events.receiveAsFlow()

    init { loadProducts() }

    private fun loadProducts() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            getProducts()
                .onSuccess { products ->
                    _uiState.update { it.copy(products = products, isLoading = false) }
                }
                .onFailure { error ->
                    _uiState.update { it.copy(isLoading = false) }
                    _events.send(UiEvent.ShowError(error.message ?: "Unknown error"))
                }
        }
    }

    fun onDelete(productId: String) {
        viewModelScope.launch {
            deleteProduct(productId)
                .onSuccess { loadProducts() }
                .onFailure { _events.send(UiEvent.ShowError(it.message!!)) }
        }
    }
}

data class ProductListUiState(
    val products: List<Product> = emptyList(),
    val isLoading: Boolean = false,
)

sealed interface UiEvent {
    data class ShowError(val message: String) : UiEvent
    data class Navigate(val route: String) : UiEvent
}
```

### Use Case
```kotlin
class GetProductsUseCase @Inject constructor(
    private val repository: ProductRepository
) {
    suspend operator fun invoke(): Result<List<Product>> {
        return repository.getProducts()
    }
}
```

### Repository Pattern
```kotlin
// Domain layer — interface
interface ProductRepository {
    suspend fun getProducts(): Result<List<Product>>
    suspend fun getProduct(id: String): Result<Product>
}

// Data layer — implementation
class ProductRepositoryImpl @Inject constructor(
    private val api: ProductApi,
    private val dao: ProductDao,
) : ProductRepository {

    override suspend fun getProducts(): Result<List<Product>> = runCatching {
        val remote = api.getProducts()
        dao.insertAll(remote.map { it.toEntity() })
        dao.getAll().map { it.toDomain() }
    }
}
```

## 4. Dependency Injection (Hilt)

```kotlin
@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {
    @Provides
    @Singleton
    fun provideRetrofit(): Retrofit = Retrofit.Builder()
        .baseUrl(BuildConfig.API_BASE_URL)
        .addConverterFactory(GsonConverterFactory.create())
        .client(OkHttpClient.Builder()
            .addInterceptor(HttpLoggingInterceptor().apply {
                level = HttpLoggingInterceptor.Level.BODY
            })
            .connectTimeout(30, TimeUnit.SECONDS)
            .build()
        )
        .build()

    @Provides
    @Singleton
    fun provideProductApi(retrofit: Retrofit): ProductApi =
        retrofit.create(ProductApi::class.java)
}

@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {
    @Binds
    abstract fun bindProductRepository(impl: ProductRepositoryImpl): ProductRepository
}
```

## 5. Kotlin Patterns

### Coroutines & Flow
```kotlin
// Structured concurrency
viewModelScope.launch {
    val user = async { userRepo.getUser(id) }
    val posts = async { postRepo.getUserPosts(id) }
    _uiState.update { it.copy(user = user.await(), posts = posts.await()) }
}

// Flow operators
repository.observeProducts()
    .map { products -> products.filter { it.isActive } }
    .distinctUntilChanged()
    .catch { emit(emptyList()) }
    .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())
```

### Sealed Classes & Result
```kotlin
sealed class Resource<out T> {
    data class Success<T>(val data: T) : Resource<T>()
    data class Error(val exception: Throwable) : Resource<Nothing>()
    data object Loading : Resource<Nothing>()
}

// Extension for clean error handling
inline fun <T> safeApiCall(block: () -> T): Result<T> = runCatching { block() }
```

## 6. Data Layer

### Room Database
```kotlin
@Entity(tableName = "products")
data class ProductEntity(
    @PrimaryKey val id: String,
    val name: String,
    val price: Double,
    @ColumnInfo(name = "created_at") val createdAt: Long,
)

@Dao
interface ProductDao {
    @Query("SELECT * FROM products ORDER BY created_at DESC")
    fun observeAll(): Flow<List<ProductEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(products: List<ProductEntity>)

    @Query("DELETE FROM products WHERE id = :id")
    suspend fun deleteById(id: String)
}

@Database(entities = [ProductEntity::class], version = 1)
abstract class AppDatabase : RoomDatabase() {
    abstract fun productDao(): ProductDao
}
```

### DataStore Preferences
```kotlin
val Context.dataStore by preferencesDataStore(name = "settings")

object PrefsKeys {
    val DARK_MODE = booleanPreferencesKey("dark_mode")
    val LANGUAGE = stringPreferencesKey("language")
}

// Read
val isDarkMode: Flow<Boolean> = context.dataStore.data
    .map { it[PrefsKeys.DARK_MODE] ?: false }

// Write
suspend fun setDarkMode(enabled: Boolean) {
    context.dataStore.edit { it[PrefsKeys.DARK_MODE] = enabled }
}
```

## 7. Navigation (Compose)

```kotlin
@Composable
fun AppNavHost(navController: NavHostController = rememberNavController()) {
    NavHost(navController, startDestination = "home") {
        composable("home") {
            HomeScreen(onNavigateToDetail = { id ->
                navController.navigate("detail/$id")
            })
        }
        composable(
            route = "detail/{productId}",
            arguments = listOf(navArgument("productId") { type = NavType.StringType })
        ) { backStack ->
            val productId = backStack.arguments?.getString("productId")!!
            DetailScreen(productId)
        }
    }
}
```

## 8. Material Design 3

```kotlin
@Composable
fun AppTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = true,
    content: @Composable () -> Unit
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            if (darkTheme) dynamicDarkColorScheme(LocalContext.current)
            else dynamicLightColorScheme(LocalContext.current)
        }
        darkTheme -> darkColorScheme()
        else -> lightColorScheme()
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = AppTypography,
        content = content
    )
}
```

## 9. Gradle KTS

### Version Catalog (libs.versions.toml)
```toml
[versions]
kotlin = "2.0.21"
compose-bom = "2024.12.01"
hilt = "2.51.1"
room = "2.6.1"

[libraries]
compose-bom = { group = "androidx.compose", name = "compose-bom", version.ref = "compose-bom" }
compose-material3 = { group = "androidx.compose.material3", name = "material3" }
hilt-android = { group = "com.google.dagger", name = "hilt-android", version.ref = "hilt" }
room-runtime = { group = "androidx.room", name = "room-runtime", version.ref = "room" }
room-ktx = { group = "androidx.room", name = "room-ktx", version.ref = "room" }

[plugins]
kotlin-android = { id = "org.jetbrains.kotlin.android", version.ref = "kotlin" }
hilt = { id = "com.google.dagger.hilt.android", version.ref = "hilt" }
```

## 10. Best Practices

- **Baseline Profiles**: Pre-compile critical user paths for faster startup
- **R8 full mode**: Enable in `gradle.properties` for aggressive optimization
- **Lifecycle-aware collection**: Always use `collectAsStateWithLifecycle()`
- **Stable types**: Use `@Immutable` or `@Stable` to help Compose skip recomposition
- **ProGuard rules**: Keep data classes used with Gson/Moshi
- **Build variants**: Use `debug`, `staging`, `release` with different `buildConfigField`
- **LeakCanary**: Include in debug builds for memory leak detection
