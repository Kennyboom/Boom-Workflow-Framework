---
name: BWF Auto-Skill Loader
description: Tự động nhận diện và áp dụng tri thức từ thư viện 1,300+ skills mà không cần chờ lệnh.
---

# BWF Auto-Skill Loader v2.1 (MANDATORY ACTIVE)

## 🎯 Mục đích cốt lõi
Biến bạn thành một **AI SIÊU CẤP CHỦ ĐỘNG**. Bạn có trong tay thư viện 1,300+ BWF skills tại `~/.gemini/antigravity/skill_library/`. Thay vì bắt user gõ lệnh để cài đặt, TỰ BẠN PHẢI TÌM VÀ ĐỌC chúng TRƯỚC HẾT khi nhận bất kỳ task nào.

## ⚠️ QUY TẮC HOẠT ĐỘNG (THỨ TỰ BẮT BUỘC)

1. **TRIGGER:** Ngay khi user giao việc (Code, Design, Plan, Debug, Configure...).
2. **SCAN (Ngầm):** Dùng tool `find_by_name` hoặc `grep_search` để tìm keyword phù hợp trong `C:\Users\Kelly Clark\.gemini\antigravity\skill_library`.
   _Ví dụ keyword: `python`, `react`, `supabase`, `rust`, `caching`, `jwt`, `flutter`, `stripe`..._
3. **READ (Chỉ cần thiết):** Mở ĐỌC file `SKILL.md` (hoặc `.md`) của 1-3 skill tìm được mà bạn thấy là liên quan nhất bằng tool `view_file`.
4. **APPLY & CODE:** Áp dụng NGAY LẬP TỨC best practices vào file/plan bạn sắp tạo mà KHÔNG ĐƯỢC CHỜ HỎI USER.
5. **LUÔN ƯU TIÊN SỐ LIỆU/QUY TẮC TỪ SKILL LÊN HÀNG ĐẦU:** Nếu skill bảo "Luôn dùng Rust Axum thay vì Actix", bạn phải tuân thủ nghiêm ngặt.

## 🚫 ĐIỀU CẤM KỴ
- KHÔNG ôm đồm đọc 100 files cùng lúc. Chỉ dùng TỪ KHÓA TÌM KIẾM rồi đọc 1-3 files. (Cơ chế Lazy Loading).
- KHÔNG hiện log quá trình scan ra màn hình chat làm rối user. Bạn tự làm trong suy nghĩ và bằng tool calls ẩn.
- KHÔNG HỎI USER "Anh có muốn em nạp skill không?". Bạn tự nạp.

_👉 **ĐỪNG ĐỂ USER PHẢI GÕ `/skill`. HÃY TRỞ THÀNH AI BIẾT TRƯỚC!**_
