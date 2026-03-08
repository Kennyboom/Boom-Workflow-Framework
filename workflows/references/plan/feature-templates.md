# Reference: Plan Feature Templates & Spec Format

## Template 1: 🎨 UI/Frontend Feature

```markdown
### 🎯 Feature: [Tên]

#### UI States (BẮT BUỘC đủ 5):
| State | Hiển thị | User Action | Next State |
|-------|---------|-------------|------------|
| Idle | [Mô tả] | [Action] | Loading |
| Loading | [Spinner/Skeleton ở đâu] | Không tương tác | Success/Error |
| Success | [Data hiển thị] | [Action tiếp] | ... |
| Error | [Thông báo lỗi, nút Retry?] | Retry/Dismiss | Loading/Idle |
| Empty | [Khi không có data] | [Tạo mới] | ... |

#### Acceptance Criteria (Given/When/Then):
- [ ] Happy path: Given [context], When [action], Then [result]
- [ ] Error path: Given [context], When [lỗi], Then [xử lý]
- [ ] Edge case: Given [tình huống cực đoan], When [action], Then [result]

#### Validation Rules (if form):
| Field | Type | Required | Rules | Error Message |
|-------|------|----------|-------|---------------|
```

## Template 2: ⚙️ Backend/Logic Feature

```markdown
### 🎯 Feature: [Tên]

#### Processing Contract:
| Input | Output | Side Effects |
|-------|--------|-------------|
| [Params/Body] | [Return] | [DB write? Event?] |

#### Business Rules: [Rule 1: formula/logic] [Rule 2: constraints]

#### API Contract:
  Endpoint: [METHOD] [PATH]
  Request:  { [field]: [type] (required/optional) }
  Response 200: { [field]: [type] }
  Response 4xx: { error: "[CODE]", message: "[msg]" }

#### Error Cases:
- [ ] Invalid input → [ERROR_CODE]
- [ ] Not found → [ERROR_CODE]
- [ ] Permission denied → [ERROR_CODE]
```

## Template 3: 🔗 Full-stack = Template 1 + Template 2

## Template 4: 🤖 AI/LLM Pipeline

```markdown
#### Pipeline States:
| State | Mô tả | Transition | Timeout |
|-------|--------|-----------|---------| 
| Cold | Chưa load model | → Loading | — |
| Loading | Load model vào RAM | → Ready/Failed | 60s |
| Ready | Sẵn sàng | → Inferencing | — |
| Inferencing | Đang xử lý | → Streaming/Error | 30s |
| Streaming | Stream tokens | → Complete/Timeout | 120s |
| Fallback | Chuyển backup model | → Ready (khác) | — |

#### Fallback Chain: Primary → Secondary → Cloud API → Error
```

## Template 5: 🔌 System/IPC

```markdown
#### Protocol Definition:
| Message Type | Direction | Payload | Response |
|-------------|-----------|---------|----------|

#### Connection Lifecycle: Disconnected → Connecting → Connected → Reconnecting
#### Reconnection: Max retries [N], Backoff [strategy], On failure [action]
```

## Template 6: 🌐 Integration/Protocol

```markdown
#### Handshake: [Step 1-3]
#### Data Flow: | Direction | Format | Encoding | Compression |
#### Performance: Latency <[X]ms, Throughput [X]/sec
```

## Template 7: 🛡️ Security/Sandbox

```markdown
#### Permission Model: | Permission | Scope | Default | Override |
#### Security Boundary: Trust, Encryption, Key management
#### Attack Surface: [Vector] → [Mitigation]
```

## Spec Template (docs/specs/[feature]_spec.md)

```markdown
# SPEC: [Feature Name]
## 1. User Stories (BDD: As [role], I want [action], So that [benefit])
## 2. UI State Machine (5 states)
## 3. Processing Contract (Input/Output)
## 4. API Contract (METHOD PATH + Request + Response)
## 5. Database Schema (Tables + relationships)
## 6. Validation Rules (field/type/rules/error)
## 7. Edge Cases (≥5 items: double-click, token expired, null, large data, offline)
## 8. Flowchart (Mermaid)
## 9. Scheduled Tasks
## 10. Third-party Integrations
## 11. Tech Stack
## 12. Build Checklist
```
