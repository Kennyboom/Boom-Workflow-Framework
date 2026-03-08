# Reference: Architecture C4 + ADR Templates

## C4 Level 1 — System Context
```
┌─────────────────────────────────────────────────────────┐
│                    🌐 INTERNET                          │
│  👤 User ──────► [📱 App Name] ──────► [💳 Stripe]     │
│                       │                                 │
│                       ├──────► [📧 SendGrid]            │
│                       ├──────► [🔐 Auth0 / Supabase]    │
│                       └──────► [🤖 OpenAI API]          │
└─────────────────────────────────────────────────────────┘
PHẢI GHI: Giao tiếp bằng gì (REST/gRPC/WebSocket), User types
```

## C4 Level 2 — Container
```
┌─────────────────── [App Name] ──────────────────────┐
│  ┌──────────┐    ┌──────────┐    ┌──────────────┐   │
│  │ Frontend │◄──►│ Backend  │◄──►│  Database    │   │
│  │ (Next.js)│    │ (Node.js)│    │ (PostgreSQL) │   │
│  └──────────┘    └────┬─────┘    └──────────────┘   │
│                  ┌────┴─────┐                        │
│                  │  Redis   │                        │
│                  └──────────┘                        │
└──────────────────────────────────────────────────────┘
PHẢI GHI: Công nghệ, version, vai trò, port
```

## C4 Level 3 — Component
```
┌─────────────────── Backend (Node.js) ───────────────┐
│  ┌─────────────┐  ┌──────────────┐  ┌───────────┐  │
│  │   Routes    │  │  Controllers │  │  Services  │  │
│  │ /api/users  │─►│ UserCtrl     │─►│ UserSvc    │  │
│  └─────────────┘  └──────────────┘  └─────┬──────┘  │
│  ┌─────────────┐  ┌──────────────┐  ┌─────┴──────┐  │
│  │ Middleware  │  │  Validators  │  │   Models   │  │
│  │ auth, cors  │  │ zod schemas  │  │ Prisma ORM │  │
│  └─────────────┘  └──────────────┘  └────────────┘  │
└──────────────────────────────────────────────────────┘
```

## ADR Template

```markdown
## ADR-001: Chọn [Công nghệ/Pattern/Giải pháp]

**Ngày:** [Date]
**Trạng thái:** ✅ Accepted / ⏳ Proposed / ❌ Rejected

### Bối cảnh (Context)
[Vấn đề gì cần giải quyết?]

### Quyết định (Decision)
[Chọn gì? Mô tả cụ thể]

### Lý do (Rationale)
[Tại sao chọn cái này?]

### Alternatives
| Phương án | Ưu điểm | Nhược điểm | Lý do loại |
|-----------|---------|-----------|-----------| 

### Hệ quả
- ✅ Tốt: [...]
- ⚠️ Trade-off: [...]
- ❌ Rủi ro: [...]
```

### ADR BẮT BUỘC:
□ ADR-001: Frontend framework
□ ADR-002: Backend framework
□ ADR-003: Database
□ ADR-004: Authentication
□ ADR-005: Hosting/Deployment
□ ADR-006: State management
□ ADR-007: CSS/Styling
