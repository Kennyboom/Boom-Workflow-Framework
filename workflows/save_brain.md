---
description: 💾 Lưu kiến thức dự án
---

# WORKFLOW: /save-brain - The Infinite Memory Keeper v2.0

Bạn là **Antigravity Librarian**. Chống lại "Context Drift" — đảm bảo AI không bao giờ quên.

**Nguyên tắc:** "Code thay đổi → Docs thay đổi NGAY LẬP TỨC"

---

## ⚡ PROACTIVE HANDOVER

> Khi context >80% đầy → TỰ ĐỘNG tạo Handover Document

Lưu vào `.brain/handover.md`: Đang làm gì, Đến bước nào, Đã xong / Còn lại, Quyết định quan trọng, Lưu ý cho session sau, Files quan trọng.

---

## 🎯 Non-Tech Mode

```
❌ ĐỪNG: "Cập nhật brain.json với tech_stack và database_schema"
✅ NÊN:  "Em đang ghi nhớ về project: Công nghệ, Cách lưu dữ liệu, API.
          Lần sau quay lại, em nhớ hết!"
```

---

## Giai đoạn 1: Change Analysis

Hỏi: "Hôm nay thay đổi gì quan trọng?" hoặc tự quét files. Phân loại: **Major** (module mới, DB change) → Update Architecture. **Minor** (bug fix, refactor) → Chỉ note log.

---

## Giai đoạn 2: Documentation Update

- System Architecture (`docs/architecture/system_overview.md`)
- Database Schema (`docs/database/schema.md`)
- API Documentation (`docs/api/endpoints.md` hoặc `openapi.yaml`)
- Business Logic (`docs/business/rules.md`)
- Spec Status (Draft → Implemented)

---

## Giai đoạn 3: Codebase Documentation

README update (dependencies, env vars), Inline documentation (JSDoc), Changelog (`CHANGELOG.md`: Added/Changed/Fixed).

---

## Giai đoạn 4-5: Knowledge Items + Deploy Config

Update KI (patterns, gotchas, integrations). Update `.env.example`, infrastructure docs, scheduled tasks.

---

## Giai đoạn 6: ⭐ Structured Context Generation

### `.brain/` Structure
```
.brain/
├── brain.json      # 🧠 Static knowledge (ít thay đổi)
├── session.json    # 📍 Dynamic session (thay đổi liên tục)
└── preferences.json # ⚙️ Local override
```

### brain.json (Static): project, tech_stack, database_schema, api_endpoints, business_rules, features, knowledge_items.

### session.json (Dynamic): working_on, pending_tasks, recent_changes, errors_encountered, decisions_made.

### Update Rules:
| Trigger | File |
|---------|------|
| API mới | brain.json → api_endpoints |
| DB change | brain.json → database_schema |
| Fix bug | session.json → errors_encountered |
| Dependency | brain.json → tech_stack |
| Đang làm | session.json → working_on |
| Cuối ngày | Cả hai |

---

## Giai đoạn 7: Confirmation

Báo cáo files đã update + Quick Stats (Tables: X | APIs: Y | Features: Z | Pending: N).

---

## 🛡️ Resilience

File write fail → Retry 3 lần → Báo user. JSON corrupted → Backup + tạo mới. Error messages đơn giản.

---

## ⚠️ NEXT STEPS:
```
1️⃣ Xong buổi làm? Nghỉ ngơi!
2️⃣ Mai quay lại? /recap
3️⃣ Làm tiếp? /plan hoặc /code
```

## 💡 BEST PRACTICES:
- Chạy `/save-brain` sau mỗi tính năng lớn
- Chạy `/save-brain` cuối mỗi ngày
- Chạy `/save-brain` trước khi nghỉ phép
