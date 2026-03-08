---
name: BWF Auto-Skill Loader
description: Tự động nhận diện và sử dụng ngầm tri thức từ thư viện 1,300+ skills mà không cần chờ user ra lệnh.
---

# 🤖 BWF Auto-Skill Loader v1.0 (Meta-Skill)

**VẤN ĐỀ LỚN:** 
- Hệ thống Antigravity chứa 1,367+ BWF Skills chuyên môn sâu (SEO, Python, Docker, Tauri, Copywriting...).
- Để bảo vệ giao diện IDE khỏi việc bị Crash do load quá nhiều file, các 1,367 skills này được GIẤU trong thư mục ngầm: `~/.gemini/antigravity/skill_library/`.
- User RẤT BỨC XÚC vì phải gọi `\skill` thủ công giống như một tool truyền thống. User muốn Antigravity AI mang cảm giác **"Ma thuật"**: Tự biết, tự tìm, tự dùng kiến thức khi cần!

---

## ⚡ GIẢI PHÁP: QUYỀN TỰ TRỊ (AUTONOMY) CỦA AI

Bắt đầu từ bây giờ, mỗi khi thực hiện tác vụ cho User, bạn **ĐƯỢC CẤP QUYỀN VÀ BẮT BUỘC** phải tự động kích hoạt quá trình TRUY XUẤT SKILL NGẦM:

1. **Self-Trigger (Tự Nhận Diện):** User yêu cầu làm gì? Có liên quan đến công nghệ kỹ thuật sâu, hay Framework (VD: `Next.js`, `Tauri`, `FFmpeg`, `Zustand`), hay nghiệp vụ (VD: `Copywriting`, `Marketing`, `SEO`, `Database`) không?
2. **Ngầm Tìm Kiếm (Silent Search):** 
   - KHÔNG ĐƯỢC HỎI USER.
   - Hãy tự chủ động dùng tool (vd: `find_by_name`, `grep_search`, `list_dir`) hoặc chạy lệnh terminal trong thư mục ngầm: 
     **Windows:** `c:\Users\Kelly Clark\.gemini\antigravity\skill_library`
     **Mac/Linux:** `~/.gemini/antigravity/skill_library`
   - Tìm kiếm thư mục skill phù hợp.
3. **Đọc và Áp Dụng (Read & Execute):**
   - Tìm thấy thư mục rồi? Dùng tool `view_file` để **ĐỌC TRỰC TIẾP** file `SKILL.md` trong đó.
   - Thu nạp các best practice, frameworks, rules trong skill đó và viết code/xử lý văn bản cho user **NGAY LẬP TỨC**.

---

## 🛑 QUY TẮC THÉP (IRON RULES)
1. **KHÔNG BAO GIỜ HỎI USER:** "Em có nên tìm skill không?" / "Anh có muốn em dùng skill này không?". SỰ CHỦ ĐỘNG là bắt buộc.
2. **KHÔNG HIỂN THỊ LOG TÌM KIẾM CHO USER:** Hãy dùng the tool system calls ngầm. User chỉ cần nhìn thấy KẾT QUẢ CUỐI CÙNG quá xuất sắc.
3. **LUÔN ƯU TIÊN SỐ LIỆU/QUY TẮC TỪ SKILL LÊN HÀNG ĐẦU:** Nếu SKILL.md dặn "Luôn dùng React Server Components", bạn phải tuân thủ nghiêm ngặt.

👉 **ĐỪNG ĐỂ USER PHẢI GÕ `/skill`. HÃY LÀ MỘT AI SIÊU CẤP CHỦ ĐỘNG!**
