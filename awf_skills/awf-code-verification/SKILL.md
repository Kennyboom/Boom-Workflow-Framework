---
name: AWF Code Verification (Anti-Skip)
description: Auto-verify that ALL plan/spec features are implemented in code. Triggers after coding is complete or when switching phases. Blocks handover if features are missing.
triggers:
  - code xong
  - hoàn thành
  - phase done
  - handover
  - chuyển phase
---

# AWF Code Verification Skill (Anti-Skip v1.1)

## Mục Đích

Skill này là **lớp phòng thủ cuối cùng** chống bỏ sót tính năng. Nó tự động kích hoạt khi AI chuẩn bị báo "xong" hoặc chuyển phase, buộc AI phải kiểm tra lại plan ↔ code trước khi handover.

## Khi Nào Kích Hoạt

Skill này **TỰ ĐỘNG** kích hoạt khi:
1. AI chuẩn bị báo "code xong" hoặc "hoàn thành"
2. AI chuẩn bị chuyển từ phase này sang phase khác
3. AI đang ở Giai đoạn 5.5 hoặc Giai đoạn 6 của workflow `/code`
4. User hỏi "xong chưa?" hoặc "đã code hết chưa?"

## Quy Trình Verification

### Bước 1: Thu Thập Nguồn Spec

```
Tìm spec/plan/phase file từ các nguồn sau (theo thứ tự ưu tiên):

1. Phase file đang code: plans/[plan-name]/phase-XX-*.md
2. Design file: docs/DESIGN.md hoặc plans/[plan-name]/DESIGN.md
3. Plan file: plans/[plan-name]/plan.md
4. Spec file: docs/specs/*.md
5. Brief file: docs/BRIEF.md
6. Task context từ session.json

→ Đọc TOÀN BỘ nội dung file spec liên quan
```

### Bước 2: Trích Xuất Danh Sách Features

```
Từ spec file, trích xuất MỌI tính năng:

1. Mỗi dòng có checkbox (- [ ] ...) = 1 feature
2. Mỗi dòng mô tả chức năng (dù không có checkbox) = 1 feature
3. Mỗi sub-item trong danh sách = 1 feature riêng
4. Mỗi mục trong bảng requirements = 1 feature

RULE: "1 Dòng = 1 Feature"
→ KHÔNG gom nhiều dòng thành 1 feature
→ KHÔNG bỏ qua dòng nào vì "quá nhỏ"
→ Đếm tổng: N features
```

### Bước 3: Scan Source Code + 4-Layer Depth Check

```
Với MỖI feature trong danh sách:

1. Tìm file/function/component liên quan trong source code
2. Kiểm tra 4 LỚP CỐT LÕI (tất cả phải có):
   🎨 UI/State     — Có UI/state handling? (nếu feature cần UI)
   ⚙️ Core Logic   — Có logic xử lý nghiệp vụ thực sự?
   🛡️ Error Handle — Có try-catch, error message, fallback?
   🧪 Edge Cases   — Có xử lý input rỗng, giới hạn, trường hợp bất thường?

3. Kiểm tra LỚP MỞ RỘNG (tùy ngữ cảnh):
   📱 Responsive   — Nếu có UI → responsive OK?
   🔐 Security     — Nếu có input/API → sanitize, auth check?
   ♿ A11y         — Nếu có UI tương tác → ARIA, keyboard?
   🚀 Performance  — Nếu có data lớn → lazy load, memoize?

4. Ghi nhận bằng chứng: file path, function name, dòng code
5. Đếm số lớp đã implement: 4+M (M = lớp mở rộng phù hợp)

Tiêu chí "ĐÃ IMPLEMENT" (phải đủ 4 lớp cốt lõi):
✅ Có function/component/route xử lý feature
✅ Core Logic đầy đủ, không có placeholder/TODO
✅ Có error handling phù hợp
✅ Có xử lý edge cases
✅ Các lớp mở rộng phù hợp context đã có

Tiêu chí "CHƯA ĐẦY ĐỦ" (thiếu 1+ lớp cốt lõi):
⚠️ Có code nhưng thiếu error handling
⚠️ Có logic nhưng không xử lý edge cases
⚠️ Có UI nhưng thiếu loading/empty state
→ Đánh dấu PARTIAL, liệt kê lớp thiếu

Tiêu chí "CHƯA IMPLEMENT":
❌ Không tìm thấy code liên quan
❌ Chỉ có comment/placeholder mô tả
❌ Có function nhưng body rỗng hoặc chỉ return null
❌ Có TODO/FIXME chưa giải quyết
```

### Bước 4: Tạo Báo Cáo Cross-Reference (với Layer Coverage)

```
Tạo bảng báo cáo:

"🔍 **VERIFICATION REPORT: Plan ↔ Code**

📋 Spec Source: [tên file spec]
📅 Verified at: [timestamp]

| # | Feature | Status | Layers | File | Evidence |
|---|---------|--------|--------|------|----------|
| 1 | [Feature 1] | ✅ | 4+2 | src/xxx.ts | handleXxx() L45 |
| 2 | [Feature 2] | ✅ | 4+1 | src/yyy.tsx | <YyyForm /> L12 |
| 3 | [Feature 3] | ⚠️ | 3/4 | src/aaa.ts | THIẾU: Error Handling |
| 4 | [Feature 4] | ❌ | 0 | — | MISSING |
| N | [Feature N] | ✅ | 4+0 | src/zzz.ts | POST /api/zzz L23 |

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 RESULT: [N1]/[N] features ✅ | [N2] ⚠️ partial | [N3] ❌ missing
📊 LAYER COVERAGE: [%] features có đủ 4 lớp cốt lõi
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

Status legend:
✅ = Đủ 4 lớp cốt lõi + lớp mở rộng phù hợp
⚠️ = Có code nhưng thiếu 1+ lớp cốt lõi → PHẢI bổ sung
❌ = Chưa implement → PHẢI code
```

### Bước 5: Quyết Định

```
IF tất cả features = ✅ (N1 == N):
    → "✅ VERIFICATION PASSED — 100% features implemented!"
    → Cho phép Handover (GĐ 6)

IF có bất kỳ feature = ❌ (N1 < N):
    → "❌ VERIFICATION FAILED — [N2] features MISSING!"
    →
    "⚠️ CÁC FEATURE CHƯA IMPLEMENT:
     1. [Feature X] — [Mô tả từ spec]
     2. [Feature Y] — [Mô tả từ spec]

     🔧 Em sẽ code tiếp các feature thiếu.
     Anh muốn:
     1️⃣ Em code tiếp ngay (Recommended)
     2️⃣ Bỏ qua các feature này (Cần anh xác nhận TỪNG feature)"

    → Nếu user chọn 1: Quay lại GĐ 3, code feature thiếu, rồi verify lại
    → Nếu user chọn 2: Yêu cầu xác nhận TỪNG feature bị skip
```

### Bước 6: Double-Pass (Khi Phát Hiện Thiếu)

```
Nếu Bước 5 phát hiện feature thiếu:

PASS 1: Code các feature thiếu
PASS 2: Đọc lại TOÀN BỘ spec từ dòng đầu đến dòng cuối
         → Kiểm tra từng dòng một lần nữa
         → Tạo bảng Cross-Reference lần 2
         → Chỉ khi Pass 2 = 100% ✅ → Mới cho Handover
```

## Tích Hợp Với Workflow `/code`

```
Skill này hoạt động song song với workflow /code:

/code workflow:
  GĐ 0 → GĐ 1 → GĐ 2 → GĐ 2.5 (Pre-Code Checklist)
  → GĐ 3 (Implementation) → GĐ 4 (Auto Test)
  → GĐ 5 (Progress Update)
  → GĐ 5.5 (Post-Code Cross-Reference) ← SKILL TRIGGERS HERE
  → GĐ 6 (Handover) ← BLOCKED until verification passes

Skill tự động verify ở GĐ 5.5.
Nếu GĐ 5.5 không được thực hiện (bị skip) → Skill block ở GĐ 6.
```

## Edge Cases

### Khi plan/spec file không tồn tại:
```
→ Thông báo: "Không tìm thấy spec file. Anh chỉ em file nào chứa requirements?"
→ Chờ user chỉ định file
→ KHÔNG skip verification
```

### Khi plan/spec quá mơ hồ:
```
→ Trích xuất best-effort checklist
→ Hỏi user: "Em trích xuất được [N] features. Anh review xem có thiếu không?"
→ User bổ sung → Verify lại
```

### Khi code theo yêu cầu ad-hoc (không có plan file):
```
→ Trích xuất features từ tin nhắn của user
→ Tạo mini-checklist từ yêu cầu
→ Verify như bình thường
```

### Khi context quá lớn (plan + code > 80% context):
```
→ Verify theo batch: chia features thành nhóm 5-10
→ Verify từng nhóm
→ Aggregate kết quả cuối cùng
```

## Hard Rules (Không Ngoại Lệ)

1. **KHÔNG BAO GIỜ** báo "xong" khi chưa chạy verification
2. **KHÔNG BAO GIỜ** skip verification vì "plan đơn giản"
3. **KHÔNG BAO GIỜ** tự ý đánh feature là ✅ nếu không có bằng chứng code thực sự
4. **KHÔNG BAO GIỜ** gom nhiều features thành 1 để giảm số lượng cần verify
5. **CHỈ USER** mới có quyền cho phép skip feature — AI không tự quyết
