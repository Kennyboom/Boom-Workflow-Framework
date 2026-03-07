---
name: ios-native
description: Build production-grade iOS apps with Swift and SwiftUI. Covers MVVM + TCA architecture, Swift concurrency (async/await, Actors), SwiftData, UIKit interop, Human Interface Guidelines, and Swift Package Manager.
---

# iOS Native Expert

Expert guidance for native iOS development with Swift 5.10+, SwiftUI, and modern Apple platform patterns.

## When to Use

- Building native iOS / iPadOS / watchOS / visionOS apps
- SwiftUI views and navigation
- Swift concurrency (async/await, Actors)
- Data persistence (SwiftData, Core Data, Keychain)
- App Store submission and guidelines

---

## 1. Project Structure

```
MyApp/
├── App/
│   ├── MyAppApp.swift           # @main entry point
│   └── ContentView.swift
├── Features/
│   └── Auth/
│       ├── Views/
│       │   ├── LoginView.swift
│       │   └── RegisterView.swift
│       ├── ViewModels/
│       │   └── AuthViewModel.swift
│       ├── Models/
│       │   └── User.swift
│       └── Services/
│           └── AuthService.swift
├── Core/
│   ├── Network/
│   │   ├── APIClient.swift
│   │   └── Endpoints.swift
│   ├── Storage/
│   │   └── KeychainManager.swift
│   ├── Theme/
│   │   ├── Colors.swift
│   │   └── Typography.swift
│   └── Extensions/
├── Resources/
│   └── Assets.xcassets
└── Package.swift               # If using SPM modularization
```

## 2. SwiftUI Essentials

### Views & Modifiers
```swift
struct ProductCard: View {
    let product: Product
    var onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: product.imageURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                ProgressView()
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(product.name)
                .font(.headline)
            Text(product.price, format: .currency(code: "USD"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .onTapGesture(perform: onTap)
    }
}
```

### Property Wrappers (State Management)
```swift
// @State — owned by this view, value types
@State private var searchText = ""
@State private var isPresented = false

// @Binding — reference to parent's @State
struct ChildView: View {
    @Binding var isOn: Bool
}

// @StateObject — owned by this view, reference types (create once)
@StateObject private var viewModel = ProductViewModel()

// @ObservedObject — NOT owned, passed from parent
struct DetailView: View {
    @ObservedObject var viewModel: DetailViewModel
}

// @EnvironmentObject — injected via .environmentObject()
@EnvironmentObject var authManager: AuthManager

// @Environment — system values
@Environment(\.colorScheme) var colorScheme
@Environment(\.dismiss) var dismiss
```

### iOS 17+ Observation Framework
```swift
@Observable
class ProductViewModel {
    var products: [Product] = []
    var isLoading = false
    var errorMessage: String?

    private let service: ProductService

    init(service: ProductService = .shared) {
        self.service = service
    }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            products = try await service.fetchProducts()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// Usage — no @StateObject needed with @Observable
struct ProductListView: View {
    @State private var viewModel = ProductViewModel()

    var body: some View {
        List(viewModel.products) { product in
            ProductRow(product: product)
        }
        .overlay { if viewModel.isLoading { ProgressView() } }
        .task { await viewModel.loadProducts() }
    }
}
```

## 3. Navigation

### NavigationStack (iOS 16+)
```swift
struct AppNavigation: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            HomeView()
                .navigationDestination(for: Product.self) { product in
                    ProductDetailView(product: product)
                }
                .navigationDestination(for: UserRoute.self) { route in
                    switch route {
                    case .profile(let id): ProfileView(userId: id)
                    case .settings: SettingsView()
                    }
                }
        }
    }
}

enum UserRoute: Hashable {
    case profile(String)
    case settings
}

// Programmatic navigation
Button("View Profile") { path.append(UserRoute.profile("123")) }
```

### TabView
```swift
TabView {
    Tab("Home", systemImage: "house") { HomeView() }
    Tab("Search", systemImage: "magnifyingglass") { SearchView() }
    Tab("Profile", systemImage: "person") { ProfileView() }
}
```

## 4. Swift Concurrency

### async/await
```swift
func fetchUser(id: String) async throws -> User {
    let url = URL(string: "\(baseURL)/users/\(id)")!
    let (data, response) = try await URLSession.shared.data(from: url)
    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
        throw APIError.invalidResponse
    }
    return try JSONDecoder().decode(User.self, from: data)
}

// Parallel execution
async let user = fetchUser(id: "123")
async let posts = fetchPosts(userId: "123")
let (userData, userPosts) = try await (user, posts)
```

### Actors (Thread Safety)
```swift
actor CacheManager {
    private var cache: [String: Data] = [:]

    func get(_ key: String) -> Data? { cache[key] }
    func set(_ key: String, data: Data) { cache[key] = data }
    func clear() { cache.removeAll() }
}

// Usage
let cache = CacheManager()
await cache.set("user_123", data: userData)
let cached = await cache.get("user_123")
```

### TaskGroup
```swift
func fetchAllImages(urls: [URL]) async throws -> [UIImage] {
    try await withThrowingTaskGroup(of: UIImage.self) { group in
        for url in urls {
            group.addTask { try await downloadImage(from: url) }
        }
        var images: [UIImage] = []
        for try await image in group {
            images.append(image)
        }
        return images
    }
}
```

## 5. Networking

### Modern URLSession + Codable
```swift
protocol APIClient: Sendable {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
}

struct URLSessionAPIClient: APIClient {
    private let session: URLSession
    private let decoder: JSONDecoder

    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        var request = URLRequest(url: endpoint.url)
        request.httpMethod = endpoint.method.rawValue
        request.allHTTPHeaderFields = endpoint.headers

        if let body = endpoint.body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }

        return try decoder.decode(T.self, from: data)
    }
}
```

## 6. Data Persistence

### SwiftData (iOS 17+)
```swift
@Model
class Product {
    var name: String
    var price: Double
    var category: String
    @Attribute(.unique) var sku: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade)
    var reviews: [Review] = []

    init(name: String, price: Double, category: String, sku: String) {
        self.name = name
        self.price = price
        self.category = category
        self.sku = sku
        self.createdAt = .now
    }
}

// Query in SwiftUI
struct ProductListView: View {
    @Query(sort: \Product.createdAt, order: .reverse)
    private var products: [Product]

    @Environment(\.modelContext) private var context

    var body: some View {
        List(products) { product in
            Text(product.name)
        }
    }

    func addProduct() {
        let product = Product(name: "New", price: 9.99, category: "General", sku: "SKU001")
        context.insert(product)
    }
}
```

### Keychain
```swift
struct KeychainManager {
    static func save(key: String, data: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.saveFailed }
    }

    static func load(key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
        ]
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        return result as? Data
    }
}
```

## 7. UIKit Interop

```swift
// Wrap UIKit view in SwiftUI
struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.setRegion(region, animated: true)
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, MKMapViewDelegate {
        let parent: MapView
        init(_ parent: MapView) { self.parent = parent }
    }
}
```

## 8. Testing

### Swift Testing (Modern)
```swift
import Testing

@Suite("Authentication Tests")
struct AuthTests {
    let sut: AuthService

    init() { sut = AuthService(client: MockAPIClient()) }

    @Test("Login with valid credentials returns user")
    func validLogin() async throws {
        let user = try await sut.login(email: "test@example.com", password: "pass123")
        #expect(user.email == "test@example.com")
        #expect(user.isVerified)
    }

    @Test("Login with invalid credentials throws error")
    func invalidLogin() async {
        await #expect(throws: AuthError.invalidCredentials) {
            try await sut.login(email: "wrong", password: "wrong")
        }
    }

    @Test(arguments: ["", " ", "invalid-email"])
    func invalidEmails(_ email: String) async {
        await #expect(throws: AuthError.self) {
            try await sut.login(email: email, password: "pass")
        }
    }
}
```

## 9. Swift Package Manager

### Modularization
```swift
// Package.swift
let package = Package(
    name: "AppModules",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "Core", targets: ["Core"]),
        .library(name: "Networking", targets: ["Networking"]),
        .library(name: "FeatureAuth", targets: ["FeatureAuth"]),
    ],
    targets: [
        .target(name: "Core"),
        .target(name: "Networking", dependencies: ["Core"]),
        .target(name: "FeatureAuth", dependencies: ["Core", "Networking"]),
        .testTarget(name: "CoreTests", dependencies: ["Core"]),
    ]
)
```

## 10. Best Practices

- **Preview-driven development**: Use `#Preview` macros extensively
- **@Observable over ObservableObject**: Simpler, better performance (iOS 17+)
- **Task cancellation**: Always handle `Task.isCancelled` in long operations
- **Sendable conformance**: Mark types crossing concurrency boundaries
- **Instruments profiling**: Use Time Profiler, Allocations, Leaks
- **Accessibility**: Always add `.accessibilityLabel()` and test with VoiceOver
- **HIG compliance**: Follow Apple Human Interface Guidelines for review approval
- **Privacy manifests**: Required since iOS 17 for App Store submission
