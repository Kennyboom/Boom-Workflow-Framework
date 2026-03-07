---
name: go-expert
description: Build production-grade services with Go. Covers goroutines/channels, error handling, generics, standard library, gRPC, Docker/Kubernetes patterns, OpenTelemetry, and testing (table-driven, benchmarks, fuzzing).
---

# Go Expert

Expert guidance for building scalable, cloud-native services with Go 1.22+.

## When to Use

- Building microservices and APIs
- Cloud-native applications (Docker, Kubernetes)
- CLI tools and system utilities
- High-concurrency network servers
- gRPC services

---

## 1. Project Structure (Standard Layout)

```
myservice/
├── cmd/
│   └── server/
│       └── main.go              # Entry point
├── internal/                    # Private packages
│   ├── handler/                 # HTTP/gRPC handlers
│   ├── service/                 # Business logic
│   ├── repository/              # Data access
│   ├── model/                   # Domain types
│   └── middleware/              # HTTP middleware
├── pkg/                         # Public packages (if any)
├── api/
│   └── proto/                   # Protobuf definitions
├── migrations/                  # SQL migrations
├── Dockerfile
├── docker-compose.yml
├── go.mod
└── go.sum
```

## 2. Error Handling

### Idiomatic Patterns
```go
// Custom error types
type NotFoundError struct {
    Resource string
    ID       string
}

func (e *NotFoundError) Error() string {
    return fmt.Sprintf("%s not found: %s", e.Resource, e.ID)
}

// Sentinel errors
var (
    ErrNotFound     = errors.New("not found")
    ErrUnauthorized = errors.New("unauthorized")
    ErrConflict     = errors.New("conflict")
)

// Wrap errors with context
func (r *UserRepo) GetByID(ctx context.Context, id string) (*User, error) {
    user, err := r.db.QueryRow(ctx, "SELECT ... WHERE id = $1", id)
    if err != nil {
        if errors.Is(err, sql.ErrNoRows) {
            return nil, fmt.Errorf("user %s: %w", id, ErrNotFound)
        }
        return nil, fmt.Errorf("query user %s: %w", id, err)
    }
    return user, nil
}

// Check wrapped errors
if errors.Is(err, ErrNotFound) { ... }
var nfe *NotFoundError
if errors.As(err, &nfe) { log.Printf("Missing: %s %s", nfe.Resource, nfe.ID) }
```

## 3. Goroutines & Channels

### Concurrency Patterns
```go
// Worker pool
func processItems(ctx context.Context, items []Item, workers int) []Result {
    jobs := make(chan Item, len(items))
    results := make(chan Result, len(items))

    // Start workers
    var wg sync.WaitGroup
    for i := 0; i < workers; i++ {
        wg.Add(1)
        go func() {
            defer wg.Done()
            for item := range jobs {
                results <- process(item)
            }
        }()
    }

    // Send jobs
    for _, item := range items {
        jobs <- item
    }
    close(jobs)

    // Wait and collect
    go func() { wg.Wait(); close(results) }()

    var out []Result
    for r := range results {
        out = append(out, r)
    }
    return out
}
```

### errgroup (Structured Concurrency)
```go
import "golang.org/x/sync/errgroup"

func fetchAll(ctx context.Context, ids []string) ([]User, error) {
    g, ctx := errgroup.WithContext(ctx)
    users := make([]User, len(ids))

    for i, id := range ids {
        i, id := i, id  // capture loop vars
        g.Go(func() error {
            user, err := fetchUser(ctx, id)
            if err != nil { return err }
            users[i] = user
            return nil
        })
    }

    if err := g.Wait(); err != nil {
        return nil, err
    }
    return users, nil
}
```

### Context & Cancellation
```go
func longOperation(ctx context.Context) error {
    for i := 0; i < 100; i++ {
        select {
        case <-ctx.Done():
            return ctx.Err()  // context.Canceled or context.DeadlineExceeded
        default:
            doWork(i)
        }
    }
    return nil
}

// Usage with timeout
ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
defer cancel()
err := longOperation(ctx)
```

## 4. Generics (Go 1.18+)

```go
// Generic data structures
type Set[T comparable] struct {
    items map[T]struct{}
}

func NewSet[T comparable]() *Set[T] {
    return &Set[T]{items: make(map[T]struct{})}
}

func (s *Set[T]) Add(item T)           { s.items[item] = struct{}{} }
func (s *Set[T]) Contains(item T) bool { _, ok := s.items[item]; return ok }
func (s *Set[T]) Size() int            { return len(s.items) }

// Generic functions
func Map[T, U any](slice []T, fn func(T) U) []U {
    result := make([]U, len(slice))
    for i, v := range slice {
        result[i] = fn(v)
    }
    return result
}

func Filter[T any](slice []T, pred func(T) bool) []T {
    var result []T
    for _, v := range slice {
        if pred(v) { result = append(result, v) }
    }
    return result
}

// Type constraints
type Number interface {
    ~int | ~int32 | ~int64 | ~float32 | ~float64
}

func Sum[T Number](nums []T) T {
    var total T
    for _, n := range nums { total += n }
    return total
}
```

## 5. HTTP Server (Standard Library)

```go
func main() {
    mux := http.NewServeMux()

    // Go 1.22+ pattern matching
    mux.HandleFunc("GET /users", listUsers)
    mux.HandleFunc("POST /users", createUser)
    mux.HandleFunc("GET /users/{id}", getUser)
    mux.HandleFunc("PUT /users/{id}", updateUser)
    mux.HandleFunc("DELETE /users/{id}", deleteUser)

    // Middleware chain
    handler := logging(recovery(cors(mux)))

    server := &http.Server{
        Addr:         ":8080",
        Handler:      handler,
        ReadTimeout:  15 * time.Second,
        WriteTimeout: 15 * time.Second,
        IdleTimeout:  60 * time.Second,
    }

    log.Printf("Server starting on :8080")
    log.Fatal(server.ListenAndServe())
}

func getUser(w http.ResponseWriter, r *http.Request) {
    id := r.PathValue("id")  // Go 1.22+

    user, err := userService.GetByID(r.Context(), id)
    if err != nil {
        if errors.Is(err, ErrNotFound) {
            http.Error(w, "User not found", http.StatusNotFound)
            return
        }
        http.Error(w, "Internal error", http.StatusInternalServerError)
        return
    }

    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(user)
}
```

### Middleware Pattern
```go
func logging(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        start := time.Now()
        wrapped := &responseWriter{ResponseWriter: w, statusCode: 200}
        next.ServeHTTP(wrapped, r)
        slog.Info("request",
            "method", r.Method,
            "path", r.URL.Path,
            "status", wrapped.statusCode,
            "duration", time.Since(start),
        )
    })
}
```

## 6. gRPC

### Proto Definition
```protobuf
syntax = "proto3";
package user.v1;
option go_package = "myservice/gen/user/v1";

service UserService {
  rpc GetUser(GetUserRequest) returns (GetUserResponse);
  rpc ListUsers(ListUsersRequest) returns (ListUsersResponse);
  rpc CreateUser(CreateUserRequest) returns (CreateUserResponse);
}

message GetUserRequest { string id = 1; }
message GetUserResponse { User user = 1; }
message User {
  string id = 1;
  string name = 2;
  string email = 3;
}
```

### Server Implementation
```go
type userServer struct {
    pb.UnimplementedUserServiceServer
    service *UserService
}

func (s *userServer) GetUser(ctx context.Context, req *pb.GetUserRequest) (*pb.GetUserResponse, error) {
    user, err := s.service.GetByID(ctx, req.Id)
    if err != nil {
        return nil, status.Errorf(codes.NotFound, "user not found: %s", req.Id)
    }
    return &pb.GetUserResponse{User: toProto(user)}, nil
}
```

## 7. Docker & Kubernetes

### Multi-Stage Dockerfile
```dockerfile
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /server ./cmd/server

FROM scratch
COPY --from=builder /server /server
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
EXPOSE 8080
ENTRYPOINT ["/server"]
```

### Kubernetes Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myservice
spec:
  replicas: 3
  selector:
    matchLabels: { app: myservice }
  template:
    spec:
      containers:
        - name: myservice
          image: myservice:latest
          ports: [{ containerPort: 8080 }]
          resources:
            requests: { memory: "64Mi", cpu: "100m" }
            limits: { memory: "128Mi", cpu: "250m" }
          readinessProbe:
            httpGet: { path: /healthz, port: 8080 }
          livenessProbe:
            httpGet: { path: /healthz, port: 8080 }
          env:
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef: { name: db-secret, key: url }
```

## 8. Observability (OpenTelemetry)

```go
import (
    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/trace"
)

var tracer = otel.Tracer("myservice")

func (s *UserService) GetByID(ctx context.Context, id string) (*User, error) {
    ctx, span := tracer.Start(ctx, "UserService.GetByID",
        trace.WithAttributes(attribute.String("user.id", id)),
    )
    defer span.End()

    user, err := s.repo.GetByID(ctx, id)
    if err != nil {
        span.RecordError(err)
        span.SetStatus(codes.Error, err.Error())
        return nil, err
    }
    return user, nil
}
```

### Structured Logging (slog)
```go
import "log/slog"

logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
    Level: slog.LevelInfo,
}))

logger.Info("user created",
    "user_id", user.ID,
    "email", user.Email,
    "duration_ms", time.Since(start).Milliseconds(),
)
```

## 9. Testing

### Table-Driven Tests
```go
func TestValidateEmail(t *testing.T) {
    tests := []struct {
        name  string
        email string
        want  bool
    }{
        {"valid email", "user@example.com", true},
        {"no at sign", "invalid", false},
        {"empty", "", false},
        {"with plus", "user+tag@example.com", true},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got := ValidateEmail(tt.email)
            if got != tt.want {
                t.Errorf("ValidateEmail(%q) = %v, want %v", tt.email, got, tt.want)
            }
        })
    }
}
```

### Benchmarks
```go
func BenchmarkSort(b *testing.B) {
    data := generateTestData(10000)
    b.ReportAllocs()
    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        sorted := make([]int, len(data))
        copy(sorted, data)
        sort.Ints(sorted)
    }
}
// Run: go test -bench=BenchmarkSort -benchmem
```

### Fuzzing
```go
func FuzzParseJSON(f *testing.F) {
    f.Add([]byte(`{"name": "test"}`))
    f.Add([]byte(`{}`))
    f.Fuzz(func(t *testing.T, data []byte) {
        var user User
        err := json.Unmarshal(data, &user)
        if err != nil { return }
        // If parsing succeeds, should roundtrip
        encoded, err := json.Marshal(user)
        if err != nil { t.Fatal(err) }
        _ = encoded
    })
}
// Run: go test -fuzz=FuzzParseJSON
```

## 10. Best Practices

- **Accept interfaces, return structs**: Maximum flexibility
- **Make zero values useful**: `var buf bytes.Buffer` works immediately
- **Don't panic**: Return errors, let caller decide
- **Context everywhere**: Pass `context.Context` as first parameter
- **`go vet` + `staticcheck`**: Run in CI, catch bugs early
- **`golangci-lint`**: Comprehensive linting (replaces dozens of linters)
- **Small interfaces**: `io.Reader` (1 method) > large interface
- **Structured concurrency**: Use `errgroup`, avoid bare `go` statements
- **`defer` for cleanup**: Close files, unlock mutexes, end spans
