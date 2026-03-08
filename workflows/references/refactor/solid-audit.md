# Reference: SOLID Principles Audit Checklist

## S — Single Responsibility Principle

```
❓ Mỗi class/module chỉ có 1 lý do để thay đổi?
□ Classes làm quá nhiều việc? (God Class)
□ Functions xử lý nhiều concern? (mixed logic)
□ Files chứa nhiều class/module không liên quan?

Violations: [List files vi phạm]
Fix: Extract Class, Extract Module, Move Method
```

## O — Open/Closed Principle

```
❓ Code mở cho mở rộng, đóng cho sửa đổi?
□ Thêm feature mới phải SỬA code cũ?
□ Switch/if-else chains growing?
□ Thiếu abstraction/interface cho variation?

Violations: [List]
Fix: Replace Conditional with Strategy/Polymorphism
```

## L — Liskov Substitution Principle

```
❓ Subclass thay thế parent mà không gây lỗi?
□ Subclass override method nhưng thay đổi behavior?
□ Subclass throw exception mà parent không throw?
□ Instanceof/typeof checks khắp nơi?

Violations: [List]
Fix: Extract Interface, Replace Inheritance with Delegation
```

## I — Interface Segregation Principle

```
❓ Interface nhỏ gọn, chỉ chứa methods cần thiết?
□ Fat interfaces buộc implement methods không dùng?
□ Clients phụ thuộc methods không cần?

Violations: [List]
Fix: Split Interface, Extract Interface
```

## D — Dependency Inversion Principle

```
❓ High-level modules phụ thuộc abstractions?
□ Import trực tiếp implementation (không qua interface)?
□ Business logic phụ thuộc database/framework cụ thể?
□ Thiếu dependency injection?

Violations: [List]
Fix: Introduce Interface, Dependency Injection
```

## SOLID Score Card

```
│ Principle │ Pass │ Violations │ Score  │
│ S (SRP)   │ [?]  │ [?]        │ [?]/10 │
│ O (OCP)   │ [?]  │ [?]        │ [?]/10 │
│ L (LSP)   │ [?]  │ [?]        │ [?]/10 │
│ I (ISP)   │ [?]  │ [?]        │ [?]/10 │
│ D (DIP)   │ [?]  │ [?]        │ [?]/10 │
│ TOTAL     │      │            │ [?]/50 │
```
