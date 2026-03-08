# Reference: UI Implementation Guide

## Mockup-to-Code Checklist

```
⚠️ LỖI THƯỜNG GẶP: Code ra 1 cột thay vì grid như mockup!

□ Layout type: Grid hay Flex?
□ Số columns: 2, 3, 4 cột?
□ Gap giữa các items
□ Mockup có 6 cards xếp 3x2 → Code PHẢI là grid-cols-3

PIXEL-PERFECT:
□ Colors đúng hex code từ mockup
□ Font-family, font-size, font-weight đúng
□ Spacing (margin, padding) đúng
□ Border-radius, shadows đúng
```

## Interaction States (MỌI element)

```
□ Default: Trạng thái bình thường
□ Hover: Mouse di lên
□ Active: Đang nhấn
□ Focus: Tab navigation
□ Disabled: Không thể tương tác
□ Loading: Đang tải
```

## 5 UI States (MỌI component có data)

```
1. IDLE: Trạng thái ban đầu
2. LOADING: Skeleton / shimmer / spinner
3. SUCCESS: Hiển thị data
4. ERROR: Thông báo lỗi + nút Retry
5. EMPTY: "Chưa có data" + CTA tạo mới
```

## Phase-01 Setup Checklist

```
Phase 01 là NƠI DUY NHẤT install. Phases sau KHÔNG install thêm trừ khi cần.

□ Create project with framework
□ Install core dependencies
□ Setup TypeScript + ESLint + Prettier
□ Create folder structure
□ Setup Git + initial commit
□ Create .env.example
□ Create .brain/ folder

Output: Project runs (npm run dev), Clean structure, Git ready
```

## All-Phases Mode (`/code all-phases`)

```
1. Confirmation: Liệt kê tất cả phases
2. Code tuần tự: Phase 01 → 02 → ... → N
3. Mỗi phase: Đọc file → Code tasks → Test → Confirm → Next
4. Auto-transition: Xong phase → Tự chuyển phase tiếp
5. Context management: >80% → Auto-save, resume sau
```
