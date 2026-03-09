# Reference: Epic-Level Planning v4.0

> Dùng khi dự án lớn có nhiều modules/features cần tổ chức thành Epics.
> Mỗi Epic = 1 module lớn. Mỗi Phase = 1 file riêng (BẮT BUỘC).

---

## Folder Structure (BẮT BUỘC)

```
docs/specs/[feature-name]/
├── SPECS-[ID]-plan.md              ← Master overview (tổng quan)
├── phase-01-[tên-phase].md         ← Phase file chi tiết
├── phase-02-[tên-phase].md         ← Phase file chi tiết
├── phase-03-[tên-phase].md         ← Phase file chi tiết
└── phase-0N-[tên-phase].md         ← Phase file chi tiết
```

### ⚠️ Quy tắc đặt tên file:
- Master: `SPECS-[2 chữ viết tắt][số]-[kebab-case].md`
- Phase: `phase-[XX]-[tên-ngắn].md`
- VD: `SPECS-LE01-learning-engine-plan.md`, `phase-01-watch.md`

---

## Master Spec File Template (SPECS-[ID]-plan.md)

```markdown
# 📋 SPECS-[ID]: [Tên Feature]

> **Status:** Draft
> **Source:** [link BRIEF nếu có]
> **Scope:** [mô tả ngắn phạm vi]

## 1. TÓM TẮT
[1-2 câu mô tả feature — ai, làm gì, tại sao]

## 2. MỤC TIÊU
- [Mục tiêu ĐO LƯỜNG được]

## 3. USER STORIES

### User (người dùng)

| # | User Story |
|:-:|-----------|
| U1 | Là user, tôi muốn [hành động], để [lợi ích] |

### Developer

| # | User Story |
|:-:|-----------|
| D1 | Là developer, tôi muốn [hành động], để [lợi ích] |

### System

| # | User Story |
|:-:|-----------|
| S1 | Là system, tôi muốn [hành động], để [lợi ích] |

## 4. PHASES OVERVIEW

| Phase | Tên | Features | Effort | Timeline | Priority |
|:-----:|-----|:--------:|:------:|:--------:|:--------:|
| 01 | [Tên] | X | ⭐⭐⭐ | X tuần | 🔴 MVP |
| 02 | [Tên] | X | ⭐⭐⭐⭐ | X tuần | 🔴 MVP |
| 03 | [Tên] | X | ⭐⭐⭐ | X tuần | 🟡 P1 |

## 5. DEPENDENCY GRAPH

```
Phase 01 ─────► Phase 02 ─────► Phase 03
([tên])         ([tên])          ([tên])
```

## 6. EFFORT ESTIMATION

```
┌──────────┬──────────┬────────────┬──────────┬────────────┐
│ Phase    │ Features │ Raw Days   │ + Buffer │ Priority   │
├──────────┼──────────┼────────────┼──────────┼────────────┤
│ Phase 01 │ X        │ X ngày     │ X ngày   │ 🔴 MVP    │
│ TOTAL    │ X        │ X ngày     │ X ngày   │            │
└──────────┴──────────┴────────────┴──────────┴────────────┘
```

## 7. DATABASE — Bảng mới

```sql
CREATE TABLE ... ();
CREATE INDEX ... ;
```

## 8. MVP CUTOFF

> **MVP = Phase [01+02]**: ~X ngày (~X tháng with buffer)

## 9. BƯỚC TIẾP THEO

| # | Action | Command |
|---|--------|---------|
| 1 | Thiết kế kỹ thuật | `/design` |
| 2 | Xem mockup UI | `/visualize` |
```

---

## Phase File Template (phase-[XX]-[tên].md)

```markdown
# 📋 Phase [XX]: [Icon] [TÊN PHASE]

> **Parent:** [link SPECS master file]
> **Depends on:** [phase trước hoặc "None"]
> **Status:** Draft | **Effort:** ⭐⭐⭐ | **Timeline:** X tuần

---

## Feature [X.1]: [Tên Feature]

### Tóm tắt
[1-2 câu]

### User Story
Là [vai trò], tôi muốn [hành động], để [lợi ích].

### Acceptance Criteria

| # | Given | When | Then |
|:-:|-------|------|------|
| 1 | [điều kiện cụ thể] | [hành động cụ thể] | [kết quả đo lường] |

### UI Description (nếu có UI)

```
┌─────────────────────────────────────────────┐
│ [ASCII wireframe chi tiết]                   │
└─────────────────────────────────────────────┘
```

### States (nếu có UI)

| State | UI |
|-------|-----|
| Idle | [mô tả] |
| Loading | Skeleton shimmer |
| Success | [mô tả] |
| Error | Toast + Retry |
| Empty | Illustration + CTA |

### Data Model (nếu cần)

```sql
CREATE TABLE ...;
```

### Edge Cases (BẮT BUỘC ≥ 5)

| Case | Behavior |
|------|----------|
| [case 1] | [behavior] |

### Effort: ⭐⭐ | Timeline: X ngày

---

## Feature [X.2]: [Tiếp theo...]
[... lặp lại format trên ...]

---

## Dependency Matrix (cuối phase file)

```
┌──────────────────┬─────────────────────┬─────────────────┐
│ Feature          │ Depends On          │ Required By     │
├──────────────────┼─────────────────────┼─────────────────┤
│ X.1 [tên]       │ [deps]              │ [dependents]    │
└──────────────────┴─────────────────────┴─────────────────┘

Build order: X.1 → X.2 + X.3 (parallel) → X.4
```

## Tổng Effort Phase [XX]

```
┌──────────────────────┬────────┬──────────┐
│ Feature              │ Effort │ Timeline │
├──────────────────────┼────────┼──────────┤
│ X.1 [tên]           │ ⭐⭐   │ X ngày   │
├──────────────────────┼────────┼──────────┤
│ TOTAL (with parallel)│        │ ~X ngày  │
│ + Buffer ×1.5        │        │ ~X ngày  │
└──────────────────────┴────────┴──────────┘
```
```

---

## Cross-Epic Integration Matrix (dự án cực lớn)

```markdown
# Integration Matrix

## Module Dependencies

| Module | Depends On | Interface | Data Format | Status |
|--------|-----------|-----------|-------------|:------:|
| [A] | [B] | gRPC :50051 | protobuf | ⬜ |

## Cross-Module Contracts

### Module A cung cấp:
| Interface | Consumer | Format | Versioning |
|-----------|----------|--------|-----------|
| [API/Event] | [Module] | [format] | [semver] |

### Module A phụ thuộc:
| Interface | Provider | Format | Required By |
|-----------|----------|--------|------------|
| [API/Event] | [Module] | [format] | [deadline] |

## Integration Test Scenarios

| # | Modules | Scenario | Expected | Priority |
|:-:|---------|----------|----------|:--------:|
| 1 | A + B | [test case] | [result] | 🔴 P0 |
```

---

## ⚠️ Phase-01 Always Includes

```
Phase 01 luôn bao gồm:
□ Foundation / Setup cơ bản
□ Database migration scripts
□ Core data structures
□ Base UI shell (nếu có UI)

⚠️ Phase 01 là nơi DUY NHẤT setup foundation.
   Phases sau build ON TOP of Phase 01.
```

---

## ⚠️ Checklist trước khi xong Epic Planning

```
□ Master SPECS file có overview đầy đủ?
□ Mỗi phase = 1 file riêng?
□ Mỗi feature có Given/When/Then TABLE?
□ Mỗi feature có Edge Cases TABLE (≥ 5)?
□ UI features có ASCII wireframe + States?
□ Dependency Matrix cuối mỗi phase?
□ Effort table per feature + buffer ×1.5?
□ Cross-phase dependency graph?
□ MVP cutoff xác định rõ?
□ SQL CREATE TABLE cho data models?
```
