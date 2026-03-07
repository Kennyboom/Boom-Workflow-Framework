# ⚡ Boom AWF v4.2 — Boom Antigravity Workflow Framework

> **Bản nâng cấp toàn diện từ [AWF gốc](https://github.com/TUAN130294/awf).**
> Tích hợp **31 expert skills**, **Anti-Skip System**, và **4-Layer Feature Decomposition** — biến AI thành đội ngũ chuyên gia thực sự.

[![Version](https://img.shields.io/badge/version-4.2.0-blue.svg)](https://github.com/Kennyboom/Boom-Antigravity-Workflow-Framework)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Skills](https://img.shields.io/badge/skills-31-orange.svg)](#-skill-catalog-31-skills)

---

## 🆕 Điểm khác biệt so với AWF gốc

| Tính năng | AWF gốc | Boom AWF |
|-----------|---------|----------|
| Skills | 6 cơ bản | **31 expert skills** |
| Anti-Skip | ❌ | ✅ 3-layer defense |
| 4-Layer Decomposition | ❌ | ✅ 4 core + 4 extended |
| License | Không có | MIT |
| Chuyên ngành | Generic | Tauri, AI, Video, Security... |

---

## 🚀 Cài Đặt (1 Lệnh)

### Windows (PowerShell)
```powershell
irm https://raw.githubusercontent.com/Kennyboom/Boom-Antigravity-Workflow-Framework/main/install.ps1 | iex
```

### macOS / Linux
```bash
curl -fsSL https://raw.githubusercontent.com/Kennyboom/Boom-Antigravity-Workflow-Framework/main/install.sh | sh
```

> ⚠️ **Windows: Gặp lỗi ExecutionPolicy?** Chạy trước:
> ```powershell
> Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
> ```

---

## 🛡️ Anti-Skip System v1.1

Hệ thống 3 lớp phòng thủ chống AI bỏ sót tính năng:

| Lớp | Giai đoạn | Chức năng |
|-----|-----------|-----------|
| **Pre-Code Checklist** (GĐ 2.5) | Trước code | Trích xuất MỌI feature → checklist, đếm N features |
| **Post-Code Cross-Reference** (GĐ 5.5) | Sau code | Bảng đối chiếu Feature ↔ Code, block nếu thiếu |
| **Verification Skill** | Auto-trigger | Scan plan ↔ code, block handover nếu chưa 100% |

## 🔍 4-Layer Feature Decomposition

Mỗi dòng yêu cầu tự động bóc tách thành:

**4 lớp cốt lõi (luôn bắt buộc):**
🎨 UI/State · ⚙️ Core Logic · 🛡️ Error Handling · 🧪 Edge Cases

**4 lớp mở rộng (tùy ngữ cảnh):**
📱 Responsive · 🔐 Security · ♿ Accessibility · 🚀 Performance

---

## 📦 Skill Catalog (31 Skills)

### 🔧 AWF Core (7)
| Skill | Chức năng |
|-------|-----------|
| `awf-session-restore` | Khôi phục context lazy loading 3 tầng |
| `awf-auto-save` | Eternal Context — auto-save session |
| `awf-adaptive-language` | Điều chỉnh ngôn ngữ theo trình độ user |
| `awf-error-translator` | Dịch lỗi kỹ thuật → tiếng đời thường |
| `awf-context-help` | Trợ giúp thông minh theo context |
| `awf-onboarding` | Hướng dẫn user mới |
| `awf-code-verification` | 🆕 Anti-Skip — verify plan ↔ code |

### 🖥️ Boom Open / Desktop (12)
| Skill | Chức năng |
|-------|-----------|
| `tauri-v2-expert` | Tauri v2 desktop app patterns |
| `flowise-fork-expert` | Flowise 3.0 fork customization |
| `rustdesk-fork-expert` | RustDesk v1.4.6 fork patterns |
| `grpc-rust-expert` | gRPC + tonic + prost in Rust |
| `ollama-integration-expert` | Ollama API, model management |
| `wasm-sandbox-expert` | WASM sandbox + Wasmtime security |
| `hand-toml-spec` | HAND.toml spec for AI Employees |
| `marketplace-backend-expert` | Marketplace API patterns |
| `sqlite-expert` | SQLite + SQLCipher + FTS5 |
| `zustand-expert` | Zustand state management |
| `react-flow-expert` | React Flow visual pipeline builder |
| `desktop-automation-expert` | Desktop automation in Rust |

### 🎬 Media / AI (6)
| Skill | Chức năng |
|-------|-----------|
| `ffmpeg-expert` | FFmpeg GPU acceleration, filters |
| `ai-lip-sync` | AI lip sync + phoneme mapping |
| `video-streaming-preview` | Real-time video preview in Tauri |
| `webgpu-video-processing` | WebGPU compute shaders |
| `on-device-ai` | ONNX Runtime, WebNN, local AI |
| `crdt-collaboration` | Yjs CRDT real-time collaboration |

### 🔐 Security / Payment (4)
| Skill | Chức năng |
|-------|-----------|
| `advanced-encryption` | SQLCipher, Argon2, key derivation |
| `anti-tamper-protection` | HWID binding, anti-debug |
| `stealth-browser-automation` | Camoufox + Playwright anti-detect |
| `stripe-payment-expert` | Stripe, SePay VN, NOWPayments |

### 🌐 General (2)
| Skill | Chức năng |
|-------|-----------|
| `nextjs-ai-expert-skill` | Next.js 16 + React 19 + AI SDK 6.0 |
| `telemetry-analytics` | Privacy-first product analytics |

---

## 🗺️ Các Lệnh Chính

| Lệnh | Chức năng |
|------|-----------|
| `/init` | 🏁 Bắt đầu dự án mới |
| `/plan` | 📝 AI đóng vai PM, lên kế hoạch |
| `/code` | 💻 Viết code **(có Anti-Skip)** |
| `/run` | ▶️ Chạy ứng dụng |
| `/debug` | 🐛 Fix bug tự động |
| `/test` | ✅ Chạy test cases |
| `/deploy` | 🚀 Deploy production |
| `/recap` | 🧠 Khôi phục context |

---

## 📜 Changelog

### v4.2.0 (Boom AWF)
- 🆕 **31 expert skills** (từ 6 → 31)
- 🆕 **Anti-Skip System v1.1** — 3-layer defense
- 🆕 **4-Layer Feature Decomposition** — 4 core + 4 extended
- 🆕 **Read-One-Code-One Pattern** + Progressive Verification
- 🆕 **Post-Code Cross-Reference** + Double-Pass Review
- 📜 **MIT License**
- 🔄 Rebranded: AWF → **Boom AWF**

---

## 🙏 Credits

- **AWF gốc**: [TUAN130294/awf](https://github.com/TUAN130294/awf)
- **Boom AWF**: [Kennyboom](https://github.com/Kennyboom)

**Happy Vibe Coding!** 🚀
