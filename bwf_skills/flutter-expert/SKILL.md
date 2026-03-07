---
name: flutter-expert
description: Build production-grade cross-platform apps with Flutter and Dart 3+. Covers Clean Architecture, BLoC/Riverpod state management, GoRouter navigation, platform channels, widget optimization, and testing strategies.
---

# Flutter Expert

Expert guidance for building cross-platform mobile applications with Flutter 3.24+ and Dart 3.5+.

## When to Use

- Building cross-platform apps (iOS, Android, Web, Desktop)
- Dart programming best practices
- Flutter widget architecture and optimization
- State management with BLoC or Riverpod
- Platform-specific integrations

---

## 1. Project Structure (Clean Architecture)

```
lib/
├── main.dart
├── app.dart                    # MaterialApp + Router
├── core/
│   ├── constants/
│   ├── errors/                 # Failure classes
│   ├── network/                # Dio client, interceptors
│   ├── theme/                  # AppTheme, colors, typography
│   └── utils/                  # Extensions, helpers
├── features/
│   └── auth/
│       ├── data/
│       │   ├── datasources/    # Remote + Local
│       │   ├── models/         # JSON serializable (Freezed)
│       │   └── repositories/   # Impl of domain repos
│       ├── domain/
│       │   ├── entities/       # Pure Dart classes
│       │   ├── repositories/   # Abstract interfaces
│       │   └── usecases/       # Single-responsibility
│       └── presentation/
│           ├── bloc/           # BLoC / Cubit
│           ├── pages/
│           └── widgets/
└── injection_container.dart    # GetIt / Injectable setup
```

## 2. Dart 3+ Features

### Records & Patterns
```dart
// Records — lightweight tuples
(String, int) getUserInfo() => ('Alice', 30);

final (name, age) = getUserInfo();

// Pattern matching with switch
String describeShape(Shape shape) => switch (shape) {
  Circle(radius: var r) when r > 10 => 'Large circle',
  Circle(radius: var r)             => 'Circle with radius $r',
  Rectangle(width: var w, height: var h) => 'Rect ${w}x$h',
};

// Sealed classes (exhaustive switch)
sealed class AuthState {}
class Authenticated extends AuthState { final User user; ... }
class Unauthenticated extends AuthState {}
class Loading extends AuthState {}

Widget build(BuildContext context) => switch (state) {
  Authenticated(:final user) => HomeScreen(user: user),
  Unauthenticated()          => LoginScreen(),
  Loading()                   => const LoadingSpinner(),
};
```

### Class Modifiers
```dart
// interface — can only be implemented, not extended
interface class Authenticator { Future<User> login(String token); }

// final — cannot be extended or implemented outside library
final class DatabaseConfig { final String url; ... }

// base — can be extended but not implemented
base class Repository { void dispose() { ... } }

// mixin — composable behavior
mixin Loggable { void log(String msg) => print('[$runtimeType] $msg'); }
```

## 3. State Management

### BLoC / Cubit (Recommended for Large Apps)
```dart
// Cubit — simpler, function-based state changes
class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);
  void increment() => emit(state + 1);
  void decrement() => emit(state - 1);
}

// BLoC — event-driven, complex logic
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase _loginUseCase;

  AuthBloc(this._loginUseCase) : super(AuthInitial()) {
    on<LoginRequested>(_onLogin);
    on<LogoutRequested>(_onLogout);
  }

  Future<void> _onLogin(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _loginUseCase(event.credentials);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user)    => emit(AuthSuccess(user)),
    );
  }
}

// Usage in widget
BlocBuilder<AuthBloc, AuthState>(
  builder: (context, state) => switch (state) {
    AuthLoading()        => const CircularProgressIndicator(),
    AuthSuccess(:final user) => Text('Welcome ${user.name}'),
    AuthError(:final message) => Text('Error: $message'),
    _                    => const LoginForm(),
  },
)
```

### Riverpod (Alternative — Compile-Safe)
```dart
// Provider definition
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepoProvider));
});

// Auto-dispose async provider
final productsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  final repo = ref.watch(productRepoProvider);
  return repo.getProducts();
});

// Usage
class ProductList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    return products.when(
      data: (list)   => ListView.builder(...),
      loading: ()    => const CircularProgressIndicator(),
      error: (e, st) => Text('Error: $e'),
    );
  }
}
```

## 4. Navigation (GoRouter)

```dart
final router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final isLoggedIn = context.read<AuthBloc>().state is AuthSuccess;
    if (!isLoggedIn && !state.matchedLocation.startsWith('/auth')) {
      return '/auth/login';
    }
    return null;
  },
  routes: [
    ShellRoute(
      builder: (context, state, child) => ScaffoldWithNav(child: child),
      routes: [
        GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/profile/:id', builder: (_, state) =>
          ProfileScreen(id: state.pathParameters['id']!)),
      ],
    ),
    GoRoute(path: '/auth/login', builder: (_, __) => const LoginScreen()),
  ],
);

// Navigation
context.go('/profile/123');     // Replace
context.push('/details');       // Push
context.pop();                  // Back
```

## 5. Networking (Dio + Freezed)

### Dio Client with Interceptors
```dart
final dio = Dio(BaseOptions(
  baseUrl: 'https://api.example.com/v1',
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 10),
))
  ..interceptors.addAll([
    AuthInterceptor(tokenProvider: () => authStore.token),
    LogInterceptor(requestBody: true, responseBody: true),
    RetryInterceptor(retries: 3),
  ]);
```

### Freezed Models (Code Generation)
```dart
@freezed
class User with _$User {
  const factory User({
    required String id,
    required String name,
    required String email,
    @Default(false) bool isVerified,
    DateTime? lastLogin,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

## 6. Widget Optimization

### Performance Rules
```dart
// ✅ Use const constructors
const SizedBox(height: 16);
const Text('Static text');

// ✅ Extract widgets instead of methods
class UserAvatar extends StatelessWidget { ... }  // Rebuild independently
// ❌ Widget _buildAvatar() { ... }  // Rebuilds with parent

// ✅ Use keys for lists
ListView.builder(
  itemBuilder: (_, i) => UserTile(key: ValueKey(users[i].id), user: users[i]),
);

// ✅ Use RepaintBoundary for expensive widgets
RepaintBoundary(child: ComplexChart(data: chartData));

// ✅ Lazy loading with ListView.builder (not Column + map)
ListView.builder(itemCount: items.length, itemBuilder: ...);
```

### Responsive Design
```dart
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth > 900) return DesktopLayout();
    if (constraints.maxWidth > 600) return TabletLayout();
    return MobileLayout();
  },
);
```

## 7. Platform Channels

### Method Channel (Dart ↔ Native)
```dart
const channel = MethodChannel('com.app/battery');

// Call native code
Future<int> getBatteryLevel() async {
  final level = await channel.invokeMethod<int>('getBatteryLevel');
  return level ?? -1;
}

// Receive from native
channel.setMethodCallHandler((call) async {
  if (call.method == 'onBatteryChanged') {
    return handleBatteryChange(call.arguments);
  }
});
```

## 8. Testing

### Widget Test
```dart
testWidgets('Counter increments', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: CounterScreen()));

  expect(find.text('0'), findsOneWidget);
  await tester.tap(find.byIcon(Icons.add));
  await tester.pump();
  expect(find.text('1'), findsOneWidget);
});
```

### Golden Test (Screenshot Comparison)
```dart
testWidgets('UserCard golden', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: UserCard(user: testUser),
  ));
  await expectLater(
    find.byType(UserCard),
    matchesGoldenFile('goldens/user_card.png'),
  );
});
```

### BLoC Test
```dart
blocTest<AuthBloc, AuthState>(
  'emits [Loading, Success] on valid login',
  build: () => AuthBloc(mockLoginUseCase),
  act: (bloc) => bloc.add(LoginRequested(validCredentials)),
  expect: () => [AuthLoading(), AuthSuccess(testUser)],
);
```

## 9. Packages Ecosystem

| Category | Package | Purpose |
|----------|---------|---------|
| HTTP | `dio` | HTTP client with interceptors |
| Models | `freezed` + `json_serializable` | Immutable models + JSON |
| DI | `get_it` + `injectable` | Dependency injection |
| State | `flutter_bloc` or `riverpod` | State management |
| Router | `go_router` | Declarative routing |
| DB | `hive` or `isar` | Local NoSQL database |
| Secure | `flutter_secure_storage` | Encrypted key-value |
| Lint | `very_good_analysis` | Strict lint rules |

## 10. Best Practices

- **const everywhere**: Reduces rebuilds, improves performance
- **Composition over inheritance**: Prefer small widgets over large widget trees
- **Separate business logic**: Never put API calls in widgets
- **Use Either/Result**: `dartz` or `fpdart` for functional error handling
- **DevTools profiling**: Track rebuilds, frame rendering, memory
- **Shader warming**: Pre-compile shaders to avoid first-frame jank
- **Flavor/Env management**: Use `--dart-define` or `flutter_flavorizr`
