# Reference: Dependency & Coupling Analysis + Architecture Audit

## Dependency Graph

```
AI PHẢI phân tích:

1️⃣ DEPENDENCY GRAPH:
   → Vẽ sơ đồ: Module A → imports → Module B → imports → Module C
   → Tìm CIRCULAR DEPENDENCIES (A → B → C → A = 🔴 CRITICAL)
   → Đếm import depth (max depth > 5 = ⚠️)
```

## Coupling Metrics

```
┌──────────────────┬──────────┬──────────┬──────────┐
│ Module           │ Ca       │ Ce       │ Instab.  │
│                  │(Afferent)│(Efferent)│ Ce/(Ca+  │
│                  │(ai dùng  │(dùng bao │  Ce)     │
│                  │ mình)    │ nhiêu)   │          │
├──────────────────┼──────────┼──────────┼──────────┤
│ [Module A]       │ [?]      │ [?]      │ [?]      │
│ [Module B]       │ [?]      │ [?]      │ [?]      │
└──────────────────┴──────────┴──────────┴──────────┘

Instability = Ce/(Ca+Ce)
• 0.0 = Maximally stable (nhiều module dùng, ít phụ thuộc)
• 1.0 = Maximally unstable (ít module dùng, phụ thuộc nhiều)
• Abstract modules NÊN stable (0.0-0.3)
• Concrete modules NÊN unstable (0.7-1.0)
```

## Cohesion Check

```
□ Modules có LCOM cao? (methods không dùng chung fields)
□ Files chứa functions không liên quan nhau?
□ Modules có thể tách thành modules nhỏ hơn?
```

## Module Boundary Violations

```
□ Presentation layer import trực tiếp Database layer?
□ Utils folder biến thành 'junk drawer'?
□ Shared folder quá lớn (> 20 files)?

🔴 CRITICAL ISSUES:
• Circular dependencies: [List]
• God modules (Ca > 10 AND Ce > 10): [List]
• Layer violations: [List]
```

---

## Architecture Audit (Clean Architecture)

```
1️⃣ LAYER BOUNDARIES:
□ Tách rõ: Presentation / Business / Data?
□ Dependencies chạy ĐÚNG HƯỚNG? (outer → inner)
□ Business logic KHÔNG phụ thuộc framework?
□ Data access được trừu tượng hóa?

┌─────────────────────────────────────────────┐
│          PRESENTATION LAYER                   │
│  (Components, Pages, UI)                      │
├─────────────────────────────────────────────┤
│          BUSINESS LAYER                       │
│  (Services, Use Cases, Domain Logic)          │
├─────────────────────────────────────────────┤
│          DATA LAYER                           │
│  (Repositories, API clients, DB)              │
└─────────────────────────────────────────────┘

2️⃣ MODULE ORGANIZATION:
□ Feature-based hay Layer-based?
□ Modules tự chứa (self-contained)?
□ Public API rõ ràng (index.ts exports)?

3️⃣ PATTERN CONSISTENCY:
□ Patterns nhất quán? (Repository, Factory, Observer)
□ Error handling thống nhất?
□ State management thống nhất?
□ Naming conventions thống nhất?

VERDICT:
• 🟢 Architecture OK — Focus code-level refactoring
• 🟡 Cần cải thiện — Mixed refactoring
• 🔴 Cần tái cấu trúc — Dùng Architectural Patterns
```
