# Reference: Architectural Refactoring Patterns

## 🌿 Strangler Fig Pattern — Thay thế từ từ

Khi cần thay thế module/hệ thống cũ mà KHÔNG TẮT hệ thống:

```
BƯỚC 1: Tạo facade/proxy trước module cũ
BƯỚC 2: Xây module mới bên cạnh module cũ
BƯỚC 3: Chuyển hướng từng phần request sang module mới
BƯỚC 4: Khi 100% → module mới → Xóa module cũ

┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   Clients    │───→│    PROXY     │───→│  Old Module  │
└──────────────┘    │  (Facade)    │    └──────────────┘
                    │    ┌─────────┤    ┌──────────────┐
                    │    │ Routing │───→│  New Module  │
                    └────┴─────────┘    └──────────────┘

USE WHEN:
• Module cũ quá phức tạp để refactor in-place
• Cần continuous deployment trong khi refactor
• Team lớn, cần parallel development
```

## 🌉 Branch by Abstraction — Cầu tạm

Khi cần thay đổi INTERNAL component có nhiều upstream dependencies:

```
BƯỚC 1: Tạo abstraction layer (interface) TRÊN component cũ
BƯỚC 2: Chuyển toàn bộ callers sang dùng abstraction
BƯỚC 3: Xây implementation mới (cũng implement abstraction)
BƯỚC 4: Switch abstraction sang implementation mới
BƯỚC 5: Xóa implementation cũ

         ┌───────────────┐
         │  Abstraction  │ ← Callers dùng cái này
         └──────┬────────┘
         ┌──────┴────────┐
   ┌─────┴─────┐   ┌────┴──────┐
   │ Old Impl  │   │ New Impl  │
   └───────────┘   └───────────┘

USE WHEN:
• Component dính chặt vào nhiều chỗ
• Cần refactor IN-PLACE
• Cần feature toggle để switch old/new
```

## 📦 Module Extraction — Tách Module

Khi cần tách God Module thành nhiều modules nhỏ:

```
BƯỚC 1: Identify boundaries (nhóm functions theo responsibility)
BƯỚC 2: Tạo module mới + di chuyển functions
BƯỚC 3: Update imports ở mọi callers
BƯỚC 4: Tạo barrel file (index.ts) cho public API
BƯỚC 5: Hide internal implementation

USE WHEN:
• 1 file/folder làm quá nhiều việc
• Functions trong cùng module không liên quan
• Team conflict khi nhiều người sửa cùng module
```
