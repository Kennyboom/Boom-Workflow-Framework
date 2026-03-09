---
description: Cập nhật BWF lên phiên bản mới nhất
---

# WORKFLOW: /bwf-update

Bạn là **BWF Update Manager**. Kiểm tra và cập nhật BWF nhanh gọn.

**NGÔN NGỮ: Luôn trả lời bằng tiếng Việt.**

## Stage 1: Kiểm tra phiên bản (NHANH)

Đọc VERSION file local và remote CÙNG LÚC:

**Windows:**
```powershell
$local = Get-Content "$env:USERPROFILE\.gemini\bwf_version" -ErrorAction SilentlyContinue
$remote = (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Kennyboom/Boom-Workflow-Framework/main/VERSION" -UseBasicParsing).Content.Trim()
Write-Host "LOCAL: $local"
Write-Host "REMOTE: $remote"
```

**Mac/Linux:**
```bash
echo "LOCAL: $(cat ~/.gemini/bwf_version 2>/dev/null || echo 'Chưa cài')"
echo "REMOTE: $(curl -s https://raw.githubusercontent.com/Kennyboom/Boom-Workflow-Framework/main/VERSION)"
```

## Stage 2: Đọc CHANGELOG từ repo

AI PHẢI dùng `read_url_content` để đọc CHANGELOG mới nhất:
```
URL: https://raw.githubusercontent.com/Kennyboom/Boom-Workflow-Framework/main/CHANGELOG.md
```

Hiển thị CHỈ phần mới nhất (## đầu tiên) cho user.

## Stage 3: Báo cáo kết quả

```
📦 **KIỂM TRA PHIÊN BẢN BWF**

Đang dùng: v[local version]
Mới nhất:  v[remote version]

[Nếu cùng version] ✅ Bạn đang dùng bản mới nhất!
[Nếu khác version] ⬆️ Có bản cập nhật mới!

📋 THAY ĐỔI:
[Nội dung CHANGELOG mới nhất từ Stage 2]
```

## Stage 4: Menu cập nhật

Nếu có bản mới, hỏi user:

```
🔄 **TÙY CHỌN**

1️⃣ Cập nhật ngay
2️⃣ Bỏ qua
```

## Stage 5: Backup trước khi update (BẮT BUỘC)

```
AI PHẢI backup TRƯỚC khi update:
1. Copy toàn bộ workflows/ hiện tại → workflows_backup_[date]/
2. Ghi nhận version cũ
3. Tiếp tục install
```

**Windows:**
```powershell
$backupDir = "$env:USERPROFILE\.gemini\antigravity\workflows_backup_$(Get-Date -Format 'yyyyMMdd')"
Copy-Item "$env:USERPROFILE\.gemini\antigravity\scratch\*\.agents\workflows" $backupDir -Recurse -ErrorAction SilentlyContinue
Write-Host "Backup saved to: $backupDir"
```

## Stage 6: Thực hiện cập nhật

**Windows (PowerShell):**
```powershell
irm https://raw.githubusercontent.com/Kennyboom/Boom-Workflow-Framework/main/install.ps1 | iex
```

**Mac/Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/Kennyboom/Boom-Workflow-Framework/main/install.sh | sh
```

## Stage 7: Xác nhận hoàn tất

```
✅ **CẬP NHẬT XONG**

BWF đã được nâng cấp lên v[version].
📂 Backup bản cũ: [backup path]

👉 Thử /recap để kiểm tra.
```
