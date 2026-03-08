# Reference: Database Design + API Contract

## Database Schema Template

```
┌─────────────────────────────────────────────────────┐
│  👤 users                                           │
├──────────────┬──────────────┬───────────────────────┤
│ Column       │ Type         │ Constraints           │
├──────────────┼──────────────┼───────────────────────┤
│ id           │ UUID         │ PK, DEFAULT uuid()    │
│ email        │ VARCHAR(255) │ UNIQUE, NOT NULL       │
│ name         │ VARCHAR(100) │ NOT NULL               │
│ password     │ VARCHAR(255) │ NOT NULL (hashed)      │
│ role         │ ENUM         │ DEFAULT 'user'         │
│ avatar_url   │ TEXT         │ NULLABLE               │
│ created_at   │ TIMESTAMP    │ DEFAULT NOW()          │
│ updated_at   │ TIMESTAMP    │ AUTO UPDATE            │
│ deleted_at   │ TIMESTAMP    │ NULLABLE (soft delete) │
├──────────────┴──────────────┴───────────────────────┤
│ INDEXES: idx_users_email (UNIQUE), idx_users_role   │
│ RELATIONS: users.id → orders.user_id (1:N)          │
└─────────────────────────────────────────────────────┘
```

## DB Optimization Checklist
```
□ Mọi foreign key đều có index
□ Cột trong WHERE/ORDER BY có index
□ Soft delete (deleted_at) thay vì hard delete
□ Timestamps trên mọi bảng
□ UUID/ULID (nếu distributed)
□ ENUM cho giá trị cố định
□ JSON/JSONB cho dữ liệu linh hoạt
□ Partitioning cho bảng >1M rows
□ Migration strategy (up/down)
```

## API Endpoint Template

```
┌────────────────────────────────────────────────────────────┐
│  📡 POST /api/v1/auth/login                                │
│  Mô tả: Đăng nhập và nhận JWT token                       │
│  Auth: ❌ Public | Rate Limit: 5 req/min/IP                │
├────────────────────────────────────────────────────────────┤
│  📥 REQUEST:                                                │
│  { "email": "string, required", "password": "string, min8" }│
├────────────────────────────────────────────────────────────┤
│  📤 200: { "success": true, "data": { "token", "user" } }  │
│  📤 401: { "success": false, "error": { "code", "message" }}│
└────────────────────────────────────────────────────────────┘
```

## API Design Checklist
```
□ Versioning (/api/v1/...)
□ Auth requirement per endpoint
□ Rate Limit per endpoint
□ Validation rules (type, required, min, max)
□ Success AND Error response schemas
□ Error code (machine) + message (human)
□ Pagination (page, limit, total, hasMore)
□ Filtering + Sorting
□ Envelope: { success, data, error, meta }
□ CORS policy
```
