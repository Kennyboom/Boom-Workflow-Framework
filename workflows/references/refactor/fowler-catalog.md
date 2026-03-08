# Reference: Martin Fowler's Code Smell Catalog & Refactoring Techniques

## 1. 🐘 Bloaters (Phình to)

```
□ Long Method — Hàm > 30 dòng?
  → Extract Method, Replace Temp with Query
□ Large Class — Class > 500 dòng?
  → Extract Class, Extract Subclass
□ Long Parameter List — Hàm > 4 params?
  → Introduce Parameter Object, Preserve Whole Object
□ Data Clumps — Nhóm dữ liệu luôn đi cùng?
  → Extract Class, Introduce Parameter Object
□ Primitive Obsession — Dùng primitives thay vì objects?
  → Replace Primitive with Object, Replace Type Code with Class
```

## 2. 🔨 OO Abusers (Lạm dụng OOP)

```
□ Switch Statements — Switch/if-else > 5 cases?
  → Replace Conditional with Polymorphism, Strategy Pattern
□ Temporary Field — Field chỉ dùng vài trường hợp?
  → Extract Class, Introduce Null Object
□ Refused Bequest — Subclass không dùng parent methods?
  → Replace Inheritance with Delegation
□ Alternative Classes with Different Interfaces — 2 class làm cùng việc?
  → Rename Method, Extract Superclass
```

## 3. 🚧 Change Preventers (Cản trở thay đổi)

```
□ Divergent Change — 1 class sửa vì nhiều lý do khác nhau?
  → Extract Class (tách trách nhiệm)
□ Shotgun Surgery — 1 thay đổi → sửa nhiều class?
  → Move Method, Move Field, Inline Class
□ Parallel Inheritance — Tạo subclass A → phải tạo subclass B?
  → Move Method, Move Field
```

## 4. 🗑️ Dispensables (Thừa thãi)

```
□ Dead Code — Functions/variables không ai gọi?
  → Remove Dead Code
□ Commented Code — Code bị comment out?
  → Remove (đã có Git lưu lịch sử)
□ Unused Imports — Import nhưng không dùng?
  → Remove Unused Imports
□ Speculative Generality — Code "phòng xa" chưa ai dùng?
  → Collapse Hierarchy, Remove Middle Man
□ Lazy Class — Class quá nhỏ, không đáng tồn tại?
  → Inline Class
□ Duplicate Code — Code giống nhau ≥ 2 chỗ?
  → Extract Method, Pull Up Method, Form Template Method
```

## 5. 🔗 Couplers (Dính chặt)

```
□ Feature Envy — Method dùng data class khác nhiều hơn class mình?
  → Move Method, Extract Method
□ Inappropriate Intimacy — 2 classes biết quá nhiều về nhau?
  → Move Method, Change Bidirectional to Unidirectional
□ Message Chains — a.getB().getC().getD()?
  → Hide Delegate, Extract Method
□ Middle Man — Class chỉ delegate mà không làm gì?
  → Remove Middle Man, Inline Method
```

## 📊 Báo cáo Code Smell

```
┌─────────────────────┬───────┬──────────┬─────────────────────┐
│ Category            │ Count │ Severity │ Top Issue           │
├─────────────────────┼───────┼──────────┼─────────────────────┤
│ 🐘 Bloaters         │ [?]   │ [🔴🟡🟢] │ [Tên code smell]    │
│ 🔨 OO Abusers       │ [?]   │ [🔴🟡🟢] │ [...]               │
│ 🚧 Change Preventers│ [?]   │ [🔴🟡🟢] │ [...]               │
│ 🗑️ Dispensables     │ [?]   │ [🔴🟡🟢] │ [...]               │
│ 🔗 Couplers         │ [?]   │ [🔴🟡🟢] │ [...]               │
│ TOTAL               │ [XX]  │          │                     │
└─────────────────────┴───────┴──────────┴─────────────────────┘
```

## Refactoring Techniques Quick Reference

```
📦 COMPOSING METHODS:
• Extract Method — Tách logic thành hàm riêng
• Inline Method — Gộp hàm quá nhỏ
• Extract Variable — Tách biểu thức phức tạp thành biến
• Replace Temp with Query — Thay biến tạm bằng hàm

🔄 MOVING FEATURES:
• Move Method/Function — Di chuyển sang module phù hợp
• Move Field — Di chuyển field sang class phù hợp
• Extract Class — Tách class nhiều trách nhiệm
• Inline Class — Gộp class quá nhỏ

📐 ORGANIZING DATA:
• Replace Magic Number with Named Constant
• Replace Primitive with Object
• Introduce Parameter Object

🧱 SIMPLIFYING CONDITIONAL:
• Decompose Conditional — Tách if/else phức tạp
• Replace Nested Conditional with Guard Clauses
• Replace Conditional with Polymorphism

🔗 SIMPLIFYING METHOD CALLS:
• Rename Method — Đặt tên rõ nghĩa
• Separate Query from Modifier
• Parameterize Method
```
