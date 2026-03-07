---
name: rust-expert
description: Build high-performance, memory-safe systems with Rust. Covers ownership/borrowing, async with Tokio, traits/generics, error handling, Cargo workspaces, web backends with Axum, and WebAssembly compilation.
---

# Rust Expert

Expert guidance for systems programming with Rust — performance, safety, and modern patterns.

## When to Use

- Systems programming (CLI tools, servers, engines)
- High-performance web backends (Axum, Actix)
- WebAssembly compilation
- Concurrent/parallel programming
- When memory safety without GC is required

---

## 1. Project Structure (Cargo Workspace)

```
my-project/
├── Cargo.toml              # Workspace root
├── crates/
│   ├── core/               # Domain logic (no I/O)
│   │   ├── Cargo.toml
│   │   └── src/lib.rs
│   ├── api/                # HTTP server (Axum)
│   │   ├── Cargo.toml
│   │   └── src/main.rs
│   ├── db/                 # Database layer (SQLx)
│   │   ├── Cargo.toml
│   │   └── src/lib.rs
│   └── cli/                # CLI tool (Clap)
│       ├── Cargo.toml
│       └── src/main.rs
└── tests/                  # Integration tests
```

### Workspace Cargo.toml
```toml
[workspace]
members = ["crates/*"]
resolver = "2"

[workspace.dependencies]
tokio = { version = "1", features = ["full"] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
anyhow = "1"
thiserror = "2"
tracing = "0.1"
```

## 2. Ownership, Borrowing & Lifetimes

### Core Rules
```rust
// Ownership — each value has exactly one owner
let s1 = String::from("hello");
let s2 = s1;           // s1 is MOVED, can no longer use s1
// println!("{s1}");    // ❌ compile error

// Borrowing — temporary access without ownership
fn greet(name: &str) {  // immutable borrow
    println!("Hello, {name}!");
}

fn append(buf: &mut String) {  // mutable borrow (exclusive)
    buf.push_str(" world");
}

// Rules:
// - Many &T (shared) OR one &mut T (exclusive), never both
// - References must always be valid (no dangling)
```

### Lifetimes
```rust
// Explicit lifetime when compiler can't infer
fn longest<'a>(x: &'a str, y: &'a str) -> &'a str {
    if x.len() > y.len() { x } else { y }
}

// Struct with references
struct Config<'a> {
    name: &'a str,
    database_url: &'a str,
}

// 'static — lives for entire program
const APP_NAME: &str = "MyApp";  // &'static str
```

## 3. Error Handling

### thiserror (Library Errors)
```rust
use thiserror::Error;

#[derive(Error, Debug)]
pub enum AppError {
    #[error("User not found: {id}")]
    UserNotFound { id: String },

    #[error("Database error: {0}")]
    Database(#[from] sqlx::Error),

    #[error("Validation failed: {0}")]
    Validation(String),

    #[error("Unauthorized")]
    Unauthorized,
}

// Auto-converts sqlx::Error → AppError via From trait
let user = sqlx::query_as!(User, "SELECT * FROM users WHERE id = $1", id)
    .fetch_one(&pool)
    .await?;  // ? converts sqlx::Error to AppError::Database
```

### anyhow (Application Errors)
```rust
use anyhow::{Context, Result, bail};

fn load_config(path: &str) -> Result<Config> {
    let content = std::fs::read_to_string(path)
        .context(format!("Failed to read config file: {path}"))?;
    let config: Config = toml::from_str(&content)
        .context("Failed to parse config TOML")?;
    if config.port == 0 {
        bail!("Port must be non-zero");
    }
    Ok(config)
}
```

## 4. Traits & Generics

```rust
// Define behavior
trait Repository {
    type Entity;
    type Error;

    async fn find_by_id(&self, id: &str) -> Result<Self::Entity, Self::Error>;
    async fn save(&self, entity: &Self::Entity) -> Result<(), Self::Error>;
    async fn delete(&self, id: &str) -> Result<(), Self::Error>;
}

// Implement for concrete type
impl Repository for PostgresUserRepo {
    type Entity = User;
    type Error = AppError;

    async fn find_by_id(&self, id: &str) -> Result<User, AppError> {
        sqlx::query_as!(User, "SELECT * FROM users WHERE id = $1", id)
            .fetch_one(&self.pool)
            .await
            .map_err(AppError::from)
    }
    // ...
}

// Generic function with trait bounds
fn process<T: Serialize + Debug>(items: &[T]) -> String {
    items.iter()
        .map(|item| format!("{item:?}"))
        .collect::<Vec<_>>()
        .join(", ")
}

// Alternative syntax with where clause
fn merge<A, B>(a: A, b: B) -> String
where
    A: Display + Clone,
    B: Display + Into<String>,
{
    format!("{a} + {b}")
}
```

## 5. Async with Tokio

```rust
use tokio::{task, sync::Mutex, time};
use std::sync::Arc;

#[tokio::main]
async fn main() -> Result<()> {
    // Concurrent tasks
    let (users, products) = tokio::join!(
        fetch_users(),
        fetch_products(),
    );

    // Spawn background task
    let handle = task::spawn(async {
        process_queue().await
    });

    // Select — first to complete wins
    tokio::select! {
        result = long_operation() => println!("Completed: {result:?}"),
        _ = time::sleep(Duration::from_secs(5)) => println!("Timeout!"),
    }

    Ok(())
}

// Shared state with Arc<Mutex<T>>
async fn shared_counter() {
    let counter = Arc::new(Mutex::new(0));

    let mut handles = vec![];
    for _ in 0..10 {
        let counter = Arc::clone(&counter);
        handles.push(task::spawn(async move {
            let mut num = counter.lock().await;
            *num += 1;
        }));
    }

    for handle in handles { handle.await.unwrap(); }
}
```

### Channels
```rust
use tokio::sync::mpsc;

let (tx, mut rx) = mpsc::channel::<Message>(100);

// Producer
task::spawn(async move {
    tx.send(Message::new("hello")).await.unwrap();
});

// Consumer
while let Some(msg) = rx.recv().await {
    process(msg).await;
}
```

## 6. Web Backend (Axum)

```rust
use axum::{
    Router, Json, extract::{State, Path, Query},
    http::StatusCode, response::IntoResponse,
    middleware,
};
use std::sync::Arc;

#[derive(Clone)]
struct AppState {
    db: PgPool,
    cache: Arc<Cache>,
}

#[tokio::main]
async fn main() {
    let state = AppState { db: pool, cache: Arc::new(Cache::new()) };

    let app = Router::new()
        .route("/users", get(list_users).post(create_user))
        .route("/users/:id", get(get_user).put(update_user).delete(delete_user))
        .layer(middleware::from_fn(auth_middleware))
        .with_state(state);

    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

async fn list_users(
    State(state): State<AppState>,
    Query(params): Query<PaginationParams>,
) -> Result<Json<Vec<User>>, AppError> {
    let users = sqlx::query_as!(User,
        "SELECT * FROM users LIMIT $1 OFFSET $2",
        params.limit, params.offset
    )
    .fetch_all(&state.db)
    .await?;
    Ok(Json(users))
}

// Custom error → HTTP response
impl IntoResponse for AppError {
    fn into_response(self) -> axum::response::Response {
        let (status, message) = match &self {
            AppError::UserNotFound { .. } => (StatusCode::NOT_FOUND, self.to_string()),
            AppError::Unauthorized => (StatusCode::UNAUTHORIZED, self.to_string()),
            AppError::Validation(msg) => (StatusCode::BAD_REQUEST, msg.clone()),
            _ => (StatusCode::INTERNAL_SERVER_ERROR, "Internal error".into()),
        };
        (status, Json(serde_json::json!({ "error": message }))).into_response()
    }
}
```

## 7. Serialization (Serde)

```rust
use serde::{Serialize, Deserialize};
use chrono::{DateTime, Utc};

#[derive(Serialize, Deserialize, Debug)]
#[serde(rename_all = "camelCase")]
pub struct User {
    pub id: String,
    pub display_name: String,
    pub email: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub avatar_url: Option<String>,
    #[serde(with = "chrono::serde::ts_seconds")]
    pub created_at: DateTime<Utc>,
}

// Enum serialization
#[derive(Serialize, Deserialize)]
#[serde(tag = "type", content = "data")]
pub enum Event {
    UserCreated(User),
    UserDeleted { id: String },
    SystemAlert(String),
}
```

## 8. Testing

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_validate_email() {
        assert!(validate_email("user@example.com"));
        assert!(!validate_email("invalid"));
    }

    #[tokio::test]
    async fn test_create_user() {
        let pool = setup_test_db().await;
        let repo = PostgresUserRepo::new(pool);

        let user = User::new("Alice", "alice@example.com");
        repo.save(&user).await.unwrap();

        let found = repo.find_by_id(&user.id).await.unwrap();
        assert_eq!(found.name, "Alice");
    }

    // Property-based testing
    use proptest::prelude::*;
    proptest! {
        #[test]
        fn test_roundtrip_serialization(name in "[a-zA-Z]{1,50}") {
            let user = User::new(&name, "test@test.com");
            let json = serde_json::to_string(&user).unwrap();
            let decoded: User = serde_json::from_str(&json).unwrap();
            assert_eq!(user.name, decoded.name);
        }
    }
}
```

## 9. WebAssembly

```rust
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub fn process_image(data: &[u8], width: u32, height: u32) -> Vec<u8> {
    // Heavy computation runs at near-native speed in browser
    data.chunks(4)
        .flat_map(|pixel| {
            let gray = (pixel[0] as f32 * 0.299
                      + pixel[1] as f32 * 0.587
                      + pixel[2] as f32 * 0.114) as u8;
            [gray, gray, gray, pixel[3]]
        })
        .collect()
}

// Build: wasm-pack build --target web
```

## 10. Essential Crates

| Category | Crate | Purpose |
|----------|-------|---------|
| Web | `axum` | HTTP framework |
| Async | `tokio` | Async runtime |
| DB | `sqlx` | Async SQL (compile-time checked) |
| Serialization | `serde` + `serde_json` | JSON/TOML/YAML |
| Errors | `thiserror` + `anyhow` | Error handling |
| CLI | `clap` | Argument parsing |
| Logging | `tracing` | Structured logging |
| HTTP client | `reqwest` | HTTP requests |
| Validation | `validator` | Input validation |
| Wasm | `wasm-bindgen` | JS interop |

## 11. Best Practices

- **Clippy**: `cargo clippy -- -D warnings` — treat all warnings as errors
- **Rustfmt**: `cargo fmt` — consistent formatting
- **Deny unsafe**: `#![deny(unsafe_code)]` unless absolutely necessary
- **Compile-time guarantees**: Prefer `sqlx::query!` over runtime SQL
- **Zero-cost abstractions**: Traits and generics have no runtime overhead
- **Enum > Boolean**: `enum Visibility { Public, Private }` not `is_public: bool`
- **Builder pattern**: For complex constructors with many optional fields
- **Newtype pattern**: `struct UserId(String)` for type safety
