# Reference: Anti-Skip Protocol & Feature Extraction

## Feature Checklist Extraction (BẮT BUỘC)

```
TRƯỚC KHI CODE, BẮT BUỘC thực hiện:
1. Đọc TOÀN BỘ plan/spec/phase file liên quan
2. Trích xuất MỌI dòng mô tả chức năng thành checklist items
3. MỖI dòng mô tả = 1 checklist item (dù chỉ 1 dòng ngắn)
4. KHÔNG được gom nhiều dòng thành 1 item
5. KHÔNG được bỏ qua dòng nào vì "quá đơn giản"
```

## Feature Counting Guard

```
MANDATORY VERIFICATION:
spec_features = Đếm features trong spec/plan
checklist_items = Đếm items trong checklist
IF spec_features ≠ checklist_items → DỪNG, review lại

⚠️ Nếu lệch → Quay lại bước 1, đọc lại plan từ đầu
```

## 7-Layer Feature Analysis

```
MỖI FEATURE phải xét qua 7 LỚP (4 bắt buộc + 3 tùy context):

4 LỚP CỐT LÕI (LUÔN BẮT BUỘC):
   🎨 UI Layout  — Grid/Flex, columns, spacing, responsive
   ⚙️ Core Logic  — Nghiệp vụ chính, algorithm, data flow
   🛡️ Error Handle — Try-catch, thông báo lỗi, retry, fallback
   🧪 Edge Cases   — Input bất thường, giới hạn, concurrent

4 LỚP MỞ RỘNG (TÙY CONTEXT):
   📱 Responsive   — Mobile/tablet/desktop (nếu có UI)
   🔐 Security     — XSS, injection, CSRF (nếu có input/API)
   ♿ A11y         — Screen reader, keyboard (nếu có UI)
   🚀 Performance  — Lazy load, debounce (nếu data lớn)

VÍ DỤ: Feature "Search Products"
| Lớp | Check | Chi tiết |
|------|-------|---------|
| 🎨 UI Layout | ✅ | Search bar position, result grid |
| ⚙️ Core Logic | ✅ | Filter algorithm, debounce 300ms |
| 🛡️ Error Handle | ✅ | Network error → retry |
| 🧪 Edge Cases | ✅ | Query rỗng, ký tự đặc biệt |
| 📱 Responsive | ✅ | Mobile: full-width input |
| 🔐 Security | ✅ | Sanitize input, prevent XSS |
| ♿ A11y | ✅ | aria-label, keyboard nav |
| 🚀 Performance | ⬜ | Không cần (data nhỏ) |
```

## Progressive Verification

```
Sau mỗi 3-5 features đã code:
1. DỪNG LẠI
2. Đối chiếu checklist: đã tick bao nhiêu / tổng N
3. Scan lại plan để đảm bảo không bỏ sót
4. Nếu OK → Tiếp tục
5. Nếu thiếu → Quay lại code feature bị thiếu
```

## ⚠️ KHÔNG BAO GIỜ:
- Gom nhiều feature code cùng lúc
- Skip feature vì "quá nhỏ" hoặc "sẽ làm sau"
- Code feature mà không tick checklist
- Bỏ qua lớp cốt lõi nào (4 lớp luôn bắt buộc)
