# ⚡ Boom Workflow Framework v4.2

> **Fork nâng cấp từ [TUAN130294/bwf](https://github.com/TUAN130294/bwf).**
> Bổ sung **Anti-Skip System** và **4-Layer Feature Decomposition** — đảm bảo AI code đầy đủ 100% tính năng, không bỏ sót.

[![Version](https://img.shields.io/badge/version-4.2.1-blue.svg)](https://github.com/Kennyboom/Boom-Workflow-Framework)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Original](https://img.shields.io/badge/original-TUAN130294%2Fbwf-orange.svg)](https://github.com/TUAN130294/bwf)

---

## 🆕 Tính năng mới (so với bản gốc)

### 🛡️ Anti-Skip System v1.1
Hệ thống **3 lớp phòng thủ** chống AI bỏ sót tính năng khi code:

| Lớp | Giai đoạn | Chức năng |
|-----|-----------|-----------|
| **Pre-Code Checklist** (GĐ 2.5) | Trước khi code | Trích xuất MỌI feature từ plan → checklist, đếm N features |
| **Post-Code Cross-Reference** (GĐ 5.5) | Sau khi code | Bảng đối chiếu Feature ↔ Code, block nếu thiếu |
| **Verification Skill** | Auto-trigger | Scan plan ↔ code, block handover nếu chưa 100% |

### 🔍 4-Layer Feature Decomposition
Mỗi dòng yêu cầu được tự động bóc tách thành **4 lớp cốt lõi + 4 lớp mở rộng**:

| Lớp | Loại | Mô tả |
|-----|------|-------|
| 🎨 UI/State | Cốt lõi (luôn bắt buộc) | Giao diện, trạng thái hiển thị |
| ⚙️ Core Logic | Cốt lõi (luôn bắt buộc) | Xử lý nghiệp vụ chính |
| 🛡️ Error Handling | Cốt lõi (luôn bắt buộc) | Xử lý lỗi đầy đủ |
| 🧪 Edge Cases | Cốt lõi (luôn bắt buộc) | Các trường hợp biên |
| 📱 Responsive | Mở rộng (tùy ngữ cảnh) | Mobile/tablet/desktop |
| 🔐 Security | Mở rộng (tùy ngữ cảnh) | XSS, injection, CSRF |
| ♿ Accessibility | Mở rộng (tùy ngữ cảnh) | Keyboard, ARIA, screen reader |
| 🚀 Performance | Mở rộng (tùy ngữ cảnh) | Lazy load, memoize, virtualize |

### 🤖 Skill mới: `bwf-code-verification`
- Auto-trigger khi AI chuẩn bị báo "xong"
- Scan plan ↔ source code để tìm feature chưa implement
- Tạo Verification Report với Layer Coverage
- Block handover nếu phát hiện feature thiếu

---

## ✨ Tính Năng Kế Thừa (từ BWF gốc)

- 🤖 **Multi-Persona AI**: Đội ngũ AI chuyên biệt (PM, Designer, Coder, QA)
- 🧠 **Context Vĩnh Cửu**: Tự động lưu và khôi phục session làm việc
- 📦 **All-in-One**: Không cần cài thêm bất kỳ skill/agent nào khác
- 🔄 **Auto-Update**: Tự động kiểm tra và cập nhật phiên bản mới

---

## 🚀 Cài Đặt (Chỉ 1 Lệnh)

### Windows (PowerShell)
Mở Terminal (**Ctrl + `**) và dán:

```powershell
irm https://raw.githubusercontent.com/Kennyboom/Boom-Workflow-Framework/main/install.ps1 | iex
```

### macOS / Linux
```bash
curl -fsSL https://raw.githubusercontent.com/Kennyboom/Boom-Workflow-Framework/main/install.sh | sh
```

**Xong!** ✅ BWF sẽ tự động tải và cấu hình vào Antigravity.

> ⚠️ **Windows: Gặp lỗi ExecutionPolicy?** Chạy lệnh này trước:
> ```powershell
> Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
> ```

---

## 🎮 Cách Sử Dụng

Sau khi cài xong, gõ lệnh này vào khung Chat của Antigravity:

```
/init
```

AI sẽ hỏi bạn muốn làm dự án gì và tự động hướng dẫn từng bước.

---

## 🗺️ Các Lệnh Chính

| Lệnh | Chức năng | Mô tả |
|------|-----------|-------|
| `/init` | 🏁 Khởi động | Bắt đầu dự án mới |
| `/brainstorm` | 💡 Bàn ý tưởng | Research, brainstorm ý tưởng |
| `/plan` | 📝 Kế hoạch | AI đóng vai PM, phỏng vấn yêu cầu |
| `/design` | 🎨 Thiết kế kỹ thuật | DB, API, Architecture (11 phases) |
| `/visualize` | 🖼️ UI/UX Mockup | Tạo giao diện trước khi code |
| `/security-audit` | 🔒 Kiểm tra bảo mật | Security design audit |
| `/performance` | ⚡ Hiệu suất | Performance budget & optimization |
| `/code` | 💻 Viết code | AI tự động lập trình theo spec **(có Anti-Skip)** |
| `/run` | ▶️ Chạy | Khởi động ứng dụng |
| `/debug` | 🐛 Sửa lỗi | Phân tích và fix bug tự động |
| `/test` | ✅ Kiểm thử | Chạy test cases |
| `/deploy` | 🚀 Deploy | Đẩy lên production |
| `/refactor` | 🔧 Tái cấu trúc | Dọn dẹp & tối ưu code |
| `/review` | 👀 Review code | Tổng quan & bàn giao dự án |
| `/rollback` | ⏪ Quay lại | Rollback deployment |
| `/recap` | 🧠 Nhớ lại | Khôi phục context từ session cũ |
| `/save-brain` | 💾 Lưu kiến thức | Lưu knowledge dự án |
| `/next` | ➡️ Bước tiếp | Gợi ý bước tiếp theo |
| `/help` | ❓ Trợ giúp | Hướng dẫn sử dụng |
| `/customize` | ⚙️ Cá nhân hóa | Tùy chỉnh trải nghiệm AI |
| `/bwf-update` | 🔄 Cập nhật | Kiểm tra và update BWF |

---

## 📂 Cấu Trúc Thư Mục (Sau Cài Đặt)

```
~/.gemini/antigravity/
├── global_workflows/    # Các workflow chính (/init, /plan, /code...)
├── skills/              # BWF Skills (auto-activate)
│   └── bwf-code-verification/  # 🆕 Anti-Skip Verification
├── schemas/             # JSON Schemas
├── templates/           # Mẫu cấu hình
└── scratch/
    └── <workspace>/
        └── .agents/
            └── workflows/ → global_workflows/  # Auto-linked
```

---

## 📜 Changelog

### v4.2.1 (Boom Enhanced)
- 🔧 **Design v2.1** — Refactor `/design` từ 17 → 11 phases, tách riêng `/security-audit` + `/performance` + `/deploy`
- 🆕 **Auto-link Workspaces** — Installer tự động tạo junction symlink cho tất cả workspaces
- 🔧 **README** — Bổ sung đầy đủ 22 commands (trước thiếu 11 lệnh)
- 🔧 **Installer fixes** — Sửa fallback version, skill count, step numbering

### v4.2.0 (Boom Enhanced)
- 🆕 **Anti-Skip System v1.1** — 3 lớp phòng thủ chống bỏ sót feature
- 🆕 **4-Layer Feature Decomposition** — 4 lớp cốt lõi + 4 lớp mở rộng tùy ngữ cảnh
- 🆕 Skill `bwf-code-verification` — Auto-verify plan ↔ code
- 🆕 **Read-One-Code-One Pattern** — Đọc 1, code 1, tick 1
- 🆕 **Progressive Verification** — Checkpoint mỗi 3-5 features
- 🆕 **Post-Code Cross-Reference** — Bảng đối chiếu bắt buộc trước handover
- 🆕 **Double-Pass Review** — Đọc lại toàn bộ plan khi phát hiện thiếu
- 📜 **MIT License** added

### v4.1.0 (Original)
- 🆕 Eternal Context System - Auto-save để không bao giờ mất context
- 🆕 Skill `bwf-auto-save` với trigger thông minh
- 🆕 3-Tier lazy loading cho session restore

### v4.0.0 (Original)
- 🆕 Skill System (bwf-session-restore, bwf-error-translator...)
- 🆕 Schemas & Templates
- 🆕 Multi-language support

---

## 🙏 Credits

- **Original BWF**: [TUAN130294/bwf](https://github.com/TUAN130294/bwf)
- **Enhancements**: [Kennyboom](https://github.com/Kennyboom) — Anti-Skip System, 4-Layer Decomposition

---

**Happy Vibe Coding!** 🚀
