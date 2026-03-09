# Reference: Plan Feature Templates v4.0

> Mỗi feature trong Phase file PHẢI dùng template phù hợp bên dưới.
> Template = khung sườn BẮT BUỘC, thêm section nếu cần, KHÔNG ĐƯỢC bỏ section.

---

## Template 1: 🎨 UI/Frontend Feature

```markdown
## Feature [X.Y]: [Tên Feature]

### Tóm tắt
[1-2 câu mô tả]

### User Story
Là [vai trò], tôi muốn [hành động], để [lợi ích].

### Acceptance Criteria

| # | Given | When | Then |
|:-:|-------|------|------|
| 1 | [điều kiện cụ thể] | [hành động cụ thể] | [kết quả đo lường] |
| 2 | [error case] | [trigger] | [error handling] |
| 3 | [empty state] | [first visit] | [empty UI + CTA] |

### UI Description (BẮT BUỘC)

```
┌─────────────────────────────────────────────┐
│ [Header / Navigation]                        │
│                                              │
│ [Content Area — layout chi tiết]             │
│ ┌──────────┐  ┌──────────┐                  │
│ │ Component│  │ Component│                  │
│ │          │  │          │                  │
│ └──────────┘  └──────────┘                  │
│                                              │
│ [Actions: buttons, links]                    │
└─────────────────────────────────────────────┘
```

### States (BẮT BUỘC — tối thiểu 5)

| State | UI | User Action | Next State |
|-------|-----|-------------|-----------|
| Idle | [mô tả bình thường] | [click/type] | Loading |
| Loading | Skeleton shimmer / Spinner | — | Success/Error |
| Success | [data hiển thị] | [action tiếp] | Idle |
| Error | Toast "Lỗi..." + [Retry] btn | Retry | Loading |
| Empty | Illustration + "Chưa có..." + CTA | [Tạo mới] | Loading |

### Validation Rules (nếu có form)

| Field | Type | Required | Rules | Error Message |
|-------|------|:--------:|-------|---------------|
| email | string | ✅ | valid email format | "Email không hợp lệ" |
| name | string | ✅ | 2-50 chars | "Tên 2-50 ký tự" |

### Edge Cases (BẮT BUỘC ≥ 5)

| Case | Behavior |
|------|----------|
| Double-click button | Debounce, chỉ trigger 1 lần |
| Token expired giữa chừng | Redirect login, save draft |
| Null/undefined data | Fallback text, không crash |
| Data quá dài (1000+ items) | Pagination hoặc virtual scroll |
| Offline | Queue action, sync khi online |
| Screen < 320px | Responsive, không bị vỡ layout |

### Effort: ⭐⭐ | Timeline: X ngày
```

---

## Template 2: ⚙️ Backend/API Feature

```markdown
## Feature [X.Y]: [Tên Feature]

### Tóm tắt
[1-2 câu]

### User Story
Là [vai trò], tôi muốn [hành động], để [lợi ích].

### Acceptance Criteria

| # | Given | When | Then |
|:-:|-------|------|------|
| 1 | [input hợp lệ] | [API call] | [200 + response data] |
| 2 | [input sai] | [API call] | [400 + error message] |
| 3 | [không quyền] | [API call] | [403 + "Không có quyền"] |

### Processing Contract

| Input | Output | Side Effects |
|-------|--------|-------------|
| [params/body] | [return data] | [DB write? Event emit?] |

### API Contract (gRPC hoặc REST)

```protobuf
// gRPC
service [ServiceName] {
  rpc [MethodName]([Request]) returns ([Response]);
}

message [Request] {
  string field = 1;  // description
}

message [Response] {
  string field = 1;
  int32 status = 2;
}
```

### Business Rules

| # | Rule | Formula/Logic |
|:-:|------|---------------|
| 1 | [Rule name] | [Cụ thể: if X then Y] |
| 2 | [Constraint] | [Limit/validation] |

### Data Model

```sql
CREATE TABLE [table_name] (
  id TEXT PRIMARY KEY,
  [column] [TYPE] [CONSTRAINTS],
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX idx_[name] ON [table]([column]);
```

### Error Cases

| Error | Code | Response | Action |
|-------|------|----------|--------|
| Input sai | INVALID_INPUT | "{field} không hợp lệ" | Return 400 |
| Không tìm thấy | NOT_FOUND | "Không tồn tại" | Return 404 |
| Không quyền | PERMISSION_DENIED | "Cần quyền X" | Return 403 |
| Server lỗi | INTERNAL | "Lỗi hệ thống" | Log + return 500 |

### Edge Cases (BẮT BUỘC ≥ 5)

| Case | Behavior |
|------|----------|
| Concurrent writes | Optimistic locking |
| Payload quá lớn | Reject > 10MB |
| Rate limit | 429 + retry-after header |
| DB connection lost | Retry 3x → circuit breaker |
| Null/missing fields | Validation → specific error |

### Effort: ⭐⭐⭐ | Timeline: X ngày
```

---

## Template 3: 🔗 Full-stack Feature

> Kết hợp Template 1 (UI) + Template 2 (Backend).
> File phase phải có CẢ HAI phần: UI Description + API Contract.

---

## Template 4: 🤖 AI/LLM Pipeline Feature

```markdown
## Feature [X.Y]: [Tên Feature]

### Tóm tắt
[1-2 câu]

### User Story
Là [vai trò], tôi muốn [hành động], để [lợi ích].

### Acceptance Criteria

| # | Given | When | Then |
|:-:|-------|------|------|
| 1 | [model available] | [task submit] | [result trong < Xs] |
| 2 | [model unavailable] | [task submit] | [fallback to tier N] |
| 3 | [output quality < threshold] | [after inference] | [retry hoặc escalate tier] |

### AI Tier Routing

| Task Complexity | AI Tier | Model | Latency | Cost |
|----------------|:-------:|-------|:-------:|:----:|
| Simple | Tier 1 | PicoLM (1.1B) | < 2s | $0 |
| Medium | Tier 2 | Ollama Light (2-4B) | < 5s | $0 |
| Complex | Tier 3 | Ollama Full (32B+) | < 15s | $0 |
| Fallback | Tier 4 | Cloud (Gemini/GPT) | < 3s | $$ |

### Pipeline States

| State | Mô tả | Transition | Timeout |
|-------|--------|-----------|:-------:|
| Cold | Chưa load model | → Loading | — |
| Loading | Load model vào RAM | → Ready / Failed | 60s |
| Ready | Sẵn sàng | → Inferencing | — |
| Inferencing | Đang xử lý | → Streaming / Error | 30s |
| Streaming | Stream tokens | → Complete / Timeout | 120s |
| Fallback | Chuyển backup | → Ready (tier khác) | — |

### Prompt Template

```
[System] You are...
[User] Given: {context}
Task: {task}
Return: {expected_format}
```

### Fallback Chain

```
Primary (Tier 2) → retry 1x
  → fail → Secondary (Tier 3)
    → fail → Cloud (Tier 4)
      → fail → Error: "Không xử lý được"
```

### Edge Cases (BẮT BUỘC ≥ 5)

| Case | Behavior |
|------|----------|
| Model OOM | Unload other models → retry |
| Output hallucination | Validation check → retry with stricter prompt |
| Streaming interrupted | Resume from last token |
| No GPU available | CPU fallback (slower) |
| User cancels mid-inference | Abort, cleanup RAM |

### Effort: ⭐⭐⭐⭐ | Timeline: X ngày
```

---

## Template 5: 🔌 System/IPC Feature

```markdown
## Feature [X.Y]: [Tên Feature]

### Acceptance Criteria (Given/When/Then table)

### Protocol Definition

| Message Type | Direction | Payload | Response |
|-------------|-----------|---------|----------|
| [type] | Client → Server | {fields} | {result} |

### Connection Lifecycle

| State | Transition | Timeout | Retry |
|-------|-----------|:-------:|:-----:|
| Disconnected | → Connecting | — | — |
| Connecting | → Connected / Failed | 10s | 3x |
| Connected | → Active | — | — |
| Reconnecting | → Connected / Failed | 5s | 5x backoff |

### Edge Cases (BẮT BUỘC ≥ 5)

| Case | Behavior |
|------|----------|
| Connection dropped | Auto-reconnect backoff |
| Message queue full | Block sender, drain oldest |
| Protocol version mismatch | Negotiate or reject |
| Payload too large | Chunk or reject > limit |
| Deadlock detection | Timeout + force-close |
```

---

## Template 6: 🛡️ Security/Permission Feature

```markdown
## Feature [X.Y]: [Tên Feature]

### Acceptance Criteria (Given/When/Then table)

### Permission Model

| Permission | Scope | Default | Override |
|-----------|-------|:-------:|:--------:|
| [action] | [resource] | ❌ Deny | Admin |

### Security Boundary

| Layer | Protection | Implementation |
|-------|-----------|----------------|
| Transport | TLS 1.3 | [lib/config] |
| Data at rest | AES-256 | [storage config] |
| Auth | JWT / Session | [method] |

### Attack Surface

| Vector | Severity | Mitigation |
|--------|:--------:|-----------|
| [attack] | 🔴/🟡/🟢 | [defense] |

### Edge Cases (BẮT BUỘC ≥ 5)
```

---

## ⚠️ Quy tắc chọn Template

```
Feature có UI?
├── YES → Template 1 (UI)
│        Feature cũng có API?
│        ├── YES → Template 3 (Full-stack)
│        └── NO → Template 1 only
├── Feature là API/Backend? → Template 2
├── Feature dùng AI/LLM? → Template 4
├── Feature là protocol/IPC? → Template 5
└── Feature liên quan security? → Template 6

⚠️ Có thể kết hợp nhiều templates cho 1 feature phức tạp.
   VD: AI feature có UI = Template 4 + Template 1
```
