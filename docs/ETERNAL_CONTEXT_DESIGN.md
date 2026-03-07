# Eternal Context System - BWF 4.1

> Auto-save context thong minh, khong bao gio mat du lieu.

---

## 1. Van De

- Context window gioi han (128K tokens)
- Khi day, AI "quen" thong tin cu (auto compact)
- User phai nho go `/save-brain` thu cong
- Load lai toan bo brain = ton token

---

## 2. Giai Phap: 3-Tier System

### Tier 1: CRITICAL (Khong bao gio xoa)
```yaml
# ~200-500 tokens
project:
  name: "MyApp"
  tech_stack: ["Next.js", "Prisma"]

key_decisions:
  - decision: "Use NextAuth"
    reason: "Simple, team familiar"
```

### Tier 2: IMPORTANT (Giu trong session)
```yaml
# ~300-800 tokens
working_on:
  feature: "Authentication"
  task: "Login form"
  progress: 65%

errors_history:
  - error: "CORS"
    fixed: true
```

### Tier 3: CONTEXT (Tam thoi)
```yaml
# ~500-2000 tokens
conversation_summary:
  - "Discussed auth options, picked NextAuth"

recent_files:
  - "src/app/login/page.tsx"
```

---

## 3. Auto-Save Triggers

| Trigger | Hanh dong |
|---------|-----------|
| Workflow hoan thanh | Save Tier 1+2 |
| Quyet dinh duoc dua ra | Append vao decisions |
| Loi duoc fix | Log vao errors_history |
| Moi 15 tin nhan | Background checkpoint |
| User roi di ("bye", "tam nghi") | Full save + summary |
| Context > 80% (uoc tinh) | Emergency save |

### Pattern Detection
```yaml
user_leaving:
  - "toi di", "tam nghi", "bye", "het gio"

decision_made:
  - "chon", "dung cai nay", "ok lam vay", "dong y"

milestone:
  - "xong", "done", "hoan thanh", "pass test"
```

### Token Estimation (Heuristic)
```
tokens = messages * 150 + code_lines * 5 + errors * 300

if tokens > 100000:  # 80% of 128K
    emergency_save()
    warn("Context sap day, da save. Go /recap de tiep tuc.")
```

---

## 4. File Structure

```
.brain/
├── brain.json              # Tier 1: Static knowledge
├── session.json            # Tier 2: Current state
├── session_log.txt         # Append-only log
│
├── snapshots/              # Historical
│   └── 2024-01-15_1430.json
│
├── summaries/
│   ├── project_summary.md  # Human-readable
│   └── context_digest.json # Quick reload
│
└── cache/                  # Temporary
    └── last_conversation.json
```

---

## 5. Lazy Loading

### Level 1: Instant (<500 tokens) - LUON LOAD
- Project name, tech stack
- Current task/feature
- Active errors

### Level 2: On-Demand (~1000 tokens) - KHI CAN
- Key decisions lien quan
- Recent files
- Pending tasks

### Level 3: Deep Dive (~2000+ tokens) - KHI YEU CAU
- Full decision history
- All summaries
- Error history

### /recap Redesign
```
/recap         → Level 1 only (nhanh)
/recap full    → Level 1 + 2
/recap [topic] → Smart search ("recap auth")
```

---

## 6. Token Optimization

### Summarization (10:1 compression)
```
Before: "User asked about auth options. I explained JWT vs Session..."
After:  "Decision: Use NextAuth (simple > flexible)"
```

### Delta Updates
```json
{
  "deltas": [
    { "time": "09:30", "action": "started_task", "data": "login" },
    { "time": "09:45", "action": "error_fixed", "data": "CORS" }
  ]
}
```

### Reference Pattern
```yaml
# Khong lap lai
task_1:
  uses: "$project.tech_stack"  # Reference
```

### Token Budget
```
128K total
├── System: 10K (fixed)
├── Conversation: 100K
├── Brain Load: 8K max
│   ├── L1: 500
│   ├── L2: 2000
│   └── L3: 5500
└── Buffer: 10K
```

---

## 7. Edge Cases

| Case | Xu ly |
|------|-------|
| File corrupted | Load snapshot → Ask user rebuild |
| Conflicting info | Show conflict → User chon |
| Project qua dai | Archive old snapshots (>7 ngay) |
| Context day | Warn user → User quyet dinh |

### Emergency Protocol (Warn Only)
```
1. Detect context > 80% (estimate)
2. Auto-save current state
3. Show warning: "⚠️ Context sap day. Go /save-brain roi bat dau session moi."
4. User tu quyet dinh khi nao reset
```

---

## 8. Auto-Inject (Session Start)

```markdown
# System prompt addition

## Project Context
- Project: MyApp (E-commerce)
- Stack: Next.js, Prisma
- Current: Authentication
- Task: Login validation (65%)
- Errors: None

[User message continues...]
```

---

## 9. Implementation Phases

### Phase 1: Core (P0)
- [ ] 3-Tier brain.json structure
- [ ] Auto-save on workflow end
- [ ] Basic /recap levels

### Phase 2: Smart Triggers (P1)
- [ ] Pattern detection
- [ ] Token estimation
- [ ] Decision extraction

### Phase 3: Optimization (P2)
- [ ] Summarization
- [ ] Delta updates
- [ ] Snapshot management

### Phase 4: Polish (P3)
- [ ] Edge cases
- [ ] User-friendly messages
- [ ] Testing

---

## 10. Commands

| Command | Chuc nang |
|---------|-----------|
| `/recap` | Load Level 1, tom tat nhanh |
| `/recap full` | Load Level 1+2, chi tiet |
| `/recap [topic]` | Tim theo chu de |
| `/save-brain` | Manual save (existing) |

---

## 11. User Messages (Co thong bao)

```
[Auto-save - workflow end]
"💾 Da luu tien do. Ban co the dong app an toan."

[Auto-save - user leaving detected]
"💾 Thay ban chuan bi di, da auto-save session."

[Context warning - 80%]
"⚠️ Context sap day. Da save backup. Nen go /save-brain roi bat dau session moi."

[Session restore]
"👋 Chao mung tro lai! Ban dang lam [feature], task: [task]."
```

## 12. Config

```yaml
# Quyet dinh da duoc dua ra:
notifications: true          # Hien thong bao khi auto-save
snapshot_retention: 7        # Giu snapshots 7 ngay
emergency_protocol: "warn"   # Chi warn, khong auto reset
```

---

## Summary

| Aspect | Solution |
|--------|----------|
| What | 3-tier (Critical/Important/Context) |
| When | Pattern + Workflow + Heuristic triggers |
| Where | brain.json + session.json + snapshots (7 ngay) |
| Load | Lazy (Level 1/2/3) |
| Optimize | Summarize + Delta + Reference |
| Edge | Warn only, user quyet dinh |
| Notification | Co thong bao khi save |

**Token overhead: <5% cua conversation binh thuong**

---

*Version: 1.0 - BWF 4.1 Design*
*Decisions: notifications=true, retention=7d, emergency=warn*
