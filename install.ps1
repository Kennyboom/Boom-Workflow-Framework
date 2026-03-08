# Boom Workflow Framework Installer for Windows (PowerShell)
# Boom Workflow Framework - Installer

$RepoBase = "https://raw.githubusercontent.com/Kennyboom/Boom-Workflow-Framework/main"
$RepoUrl = "$RepoBase/workflows"
# Full workflow list (v4.0.2) - Ordered by flow
$Workflows = @(
    # Core Flow: init → brainstorm → plan → design → visualize → code → run
    "init.md", "brainstorm.md", "plan.md", "design.md",
    "visualize.md", "code.md", "run.md",
    # Quality: debug → test → security-audit → performance
    "debug.md", "test.md", "security-audit.md", "performance.md",
    # Deploy & Maintain
    "deploy.md", "refactor.md", "rollback.md",
    # Support workflows
    "next.md", "recap.md", "help.md", "customize.md",
    "save_brain.md", "review.md", "content-creator.md", "council.md",
    "skill.md",
    # System
    "bwf-update.md", "cloudflare-tunnel.md", "README.md"
)

# Schemas and Templates (v3.3+)
$Schemas = @(
    "brain.schema.json", "session.schema.json", "preferences.schema.json"
)
$Templates = @(
    "brain.example.json", "session.example.json", "preferences.example.json"
)

# Boom Workflow Framework Skills (7 skills)
$AwfSkills = @(
    "bwf-session-restore",
    "bwf-auto-save",          # Eternal Context System - auto-save triggers
    "bwf-adaptive-language",
    "bwf-error-translator",
    "bwf-context-help",
    "bwf-onboarding",
    "bwf-code-verification"   # NEW: Anti-Skip System - auto-verify plan vs code
)

# Detect Antigravity Global Path
$AntigravityGlobal = "$env:USERPROFILE\.gemini\antigravity\global_workflows"
$SchemasDir = "$env:USERPROFILE\.gemini\antigravity\schemas"
$TemplatesDir = "$env:USERPROFILE\.gemini\antigravity\templates"
$SkillsDir = "$env:USERPROFILE\.gemini\antigravity\skills"
$SkillLibraryDir = "$env:USERPROFILE\.gemini\antigravity\skill_library"
$GeminiMd = "$env:USERPROFILE\.gemini\GEMINI.md"
$AwfVersionFile = "$env:USERPROFILE\.gemini\bwf_version"

# Get version from repo
try {
    $CurrentVersion = (Invoke-WebRequest -Uri "$RepoBase/VERSION" -UseBasicParsing).Content.Trim()
} catch {
    $CurrentVersion = "4.2.0"
}

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     🚀 Boom Workflow Framework v$CurrentVersion        ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check if updating
if (Test-Path $AwfVersionFile) {
    $OldVersion = Get-Content $AwfVersionFile
    Write-Host "📦 Phiên bản hiện tại: $OldVersion" -ForegroundColor Yellow
    Write-Host "📦 Phiên bản mới: $CurrentVersion" -ForegroundColor Green
    Write-Host ""
}

# 1. Download and Extract BWF Repository
Write-Host "⏳ Đang tải Boom Workflow Framework (toàn bộ nội dung + 1300+ skills)..." -ForegroundColor Cyan
$ZipUrl = "https://github.com/Kennyboom/Boom-Workflow-Framework/archive/refs/heads/main.zip"
$ZipPath = "$env:TEMP\bwf_temp.zip"
$ExtractPath = "$env:TEMP\bwf_extract"

# Cleanup old temp files if any
if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }
if (Test-Path $ExtractPath) { Remove-Item $ExtractPath -Recurse -Force }

try {
    Invoke-WebRequest -Uri $ZipUrl -OutFile $ZipPath -ErrorAction Stop
    $sizeMB = [math]::Round((Get-Item $ZipPath).Length / 1MB, 2)
    Write-Host "   ✅ Tải xong mã nguồn ($sizeMB MB)" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Lỗi tải mã nguồn từ GitHub. Vui lòng kiểm tra kết nối mạng." -ForegroundColor Red
    exit 1
}

Write-Host "⏳ Đang giải nén dữ liệu..." -ForegroundColor Cyan
Expand-Archive -Path $ZipPath -DestinationPath $ExtractPath -Force
$ExtractedRepo = "$ExtractPath\Boom-Workflow-Framework-main"

# 2. Cài đặt Workflows & Reference files
if (-not (Test-Path $AntigravityGlobal)) { New-Item -ItemType Directory -Force -Path $AntigravityGlobal | Out-Null }
Write-Host "⏳ Đang copy Workflows..." -ForegroundColor Cyan
Copy-Item "$ExtractedRepo\workflows\*" $AntigravityGlobal -Recurse -Force
Write-Host "   ✅ Đã copy Workflows & Reference files" -ForegroundColor Green

# 3. Cài đặt Schemas & Templates
if (-not (Test-Path $SchemasDir)) { New-Item -ItemType Directory -Force -Path $SchemasDir | Out-Null }
if (-not (Test-Path $TemplatesDir)) { New-Item -ItemType Directory -Force -Path $TemplatesDir | Out-Null }
Write-Host "⏳ Đang copy Schemas & Templates..." -ForegroundColor Cyan
Copy-Item "$ExtractedRepo\schemas\*" $SchemasDir -Recurse -Force
Copy-Item "$ExtractedRepo\templates\*" $TemplatesDir -Recurse -Force
Write-Host "   ✅ Đã copy Schemas & Templates" -ForegroundColor Green

# 4. Cài đặt Thư Viện Skills (1,300+ skills) & Core Skills (7 skills)
if (-not (Test-Path $SkillsDir)) { New-Item -ItemType Directory -Force -Path $SkillsDir | Out-Null }
if (-not (Test-Path $SkillLibraryDir)) { New-Item -ItemType Directory -Force -Path $SkillLibraryDir | Out-Null }

Write-Host "⏳ Đang cài đặt thư viện Skills khổng lồ (vui lòng chờ)..." -ForegroundColor Cyan
# Đưa toàn bộ 1300+ skills vào thư viện an toàn để chạy /skill
Copy-Item "$ExtractedRepo\bwf_skills\*" $SkillLibraryDir -Recurse -Force
$libCount = (Get-ChildItem $SkillLibraryDir -Directory).Count
Write-Host "   ✅ Đã tải $libCount skills vào thư viện (skill_library)" -ForegroundColor Green

Write-Host "⏳ Đang kích hoạt 7 BWF Core Skills..." -ForegroundColor Cyan
$success = 0
foreach ($skill in $AwfSkills) {
    if (Test-Path "$SkillLibraryDir\$skill") {
        Copy-Item "$SkillLibraryDir\$skill" "$SkillsDir\$skill" -Recurse -Force
        $success++
    }
}
Write-Host "   ✅ Đã kích hoạt $success BWF Core Skills" -ForegroundColor Green

# 5. Cleanup Temp Files
if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }
if (Test-Path $ExtractPath) { Remove-Item $ExtractPath -Recurse -Force }


# 6. Save version
if (-not (Test-Path "$env:USERPROFILE\.gemini")) {
    New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.gemini" | Out-Null
}
Set-Content -Path $AwfVersionFile -Value $CurrentVersion -Encoding UTF8
Write-Host "✅ Đã lưu version: $CurrentVersion" -ForegroundColor Green

# 7. Update Global Rules (GEMINI.md)
$AwfInstructions = @"

# BWF - Antigravity Workflow Framework

## CRITICAL: Command Recognition
Khi user gõ các lệnh bắt đầu bằng ``/`` dưới đây, đây là BWF WORKFLOW COMMANDS (không phải file path).
Bạn PHẢI đọc file workflow tương ứng và thực hiện theo hướng dẫn trong đó.

## Command Mapping (v4.0.2 - Full Flow):
| Command | Workflow File | Mô tả |
|---------|--------------|-------|
| ``/init`` | init.md | ✨ Khởi tạo dự án mới |
| ``/brainstorm`` | brainstorm.md | 💡 Bàn ý tưởng, research |
| ``/plan`` | plan.md | 📋 Lên kế hoạch tính năng |
| ``/design`` | design.md | 🎨 Thiết kế kỹ thuật (DB, API, Flow) |
| ``/visualize`` | visualize.md | 🖼️ Thiết kế UI/UX mockup |
| ``/code`` | code.md | 💻 Viết code |
| ``/run`` | run.md | ▶️ Chạy ứng dụng |
| ``/debug`` | debug.md | 🐛 Sửa lỗi |
| ``/test`` | test.md | 🧪 Kiểm thử |
| ``/security-audit`` | security-audit.md | 🔒 Kiểm tra bảo mật |
| ``/performance`` | performance.md | ⚡ Thiết kế & Tối ưu hiệu suất |
| ``/deploy`` | deploy.md | 🚀 Deploy production |
| ``/next`` | next.md | ➡️ Gợi ý bước tiếp theo |
| ``/recap`` | recap.md | 📖 Khôi phục ngữ cảnh |
| ``/help`` | help.md | ❓ Trợ giúp & Hướng dẫn |
| ``/customize`` | customize.md | ⚙️ Cá nhân hóa AI |
| ``/refactor`` | refactor.md | 🔧 Tái cấu trúc code |
| ``/review`` | review.md | 👀 Review code |
| ``/content-creator`` | content-creator.md | ✍️ Viết nội dung chuyên nghiệp |
| ``/council`` | council.md | 🏛️ Hội đồng chuyên gia thẩm định |
| ``/skill`` | skill.md | 🧰 Quản lý thư viện 1,300+ AI Skills |
| ``/save-brain`` | save_brain.md | 🧠 Lưu kiến thức |
| ``/rollback`` | rollback.md | ⏪ Rollback deployment |
| ``/bwf-update`` | bwf-update.md | 📦 Cập nhật BWF |
| ``/cloudflare-tunnel`` | cloudflare-tunnel.md | 🌐 Quản lý tunnel |

## Flow Chuẩn (v4.0.2):
``/init`` → ``/plan`` → ``/design`` → ``/security-audit`` → ``/performance`` → ``/code`` → ``/run`` → ``/test`` → ``/deploy``

## Resource Locations (v4.0+):
- Schemas: ~/.gemini/antigravity/schemas/
- Templates: ~/.gemini/antigravity/templates/
- Skills: ~/.gemini/antigravity/skills/

## BWF Skills (v4.0 - Auto-activate):
Skills là helper ẩn, tự động kích hoạt khi cần. User KHÔNG cần gọi trực tiếp.

| Skill | Trigger | Chức năng |
|-------|---------|-----------|
| bwf-session-restore | Đầu mỗi session | Tự động khôi phục context (lazy loading) |
| bwf-auto-save | Workflow end, user leaving, decisions | Eternal Context - auto-save để không mất data |
| bwf-adaptive-language | Đầu mỗi session | Điều chỉnh ngôn ngữ theo trình độ user |
| bwf-error-translator | Khi có lỗi | Dịch lỗi kỹ thuật sang tiếng đời thường |
| bwf-onboarding | /init lần đầu | Hướng dẫn user mới |
| bwf-context-help | /help hoặc ? | Trợ giúp thông minh theo context |

**Cách hoạt động:**
1. Đọc ~/.brain/preferences.json để lấy technical_level (newbie/basic/technical)
2. Điều chỉnh ngôn ngữ trong workflows theo level
3. Skills tự động trigger, user không cần biết

## Hướng dẫn thực hiện:
1. Khi user gõ một trong các commands trên, ĐỌC FILE WORKFLOW tương ứng
2. Thực hiện TỪNG GIAI ĐOẠN trong workflow
3. KHÔNG tự ý bỏ qua bước nào
4. Kết thúc bằng NEXT STEPS menu như trong workflow

## Update Check:
- BWF version được lưu tại: ~/.gemini/bwf_version
- Để kiểm tra và cập nhật BWF, user gõ: /bwf-update
- Thỉnh thoảng (1 lần/tuần) nhắc user kiểm tra update nếu họ dùng BWF thường xuyên
"@

if (-not (Test-Path $GeminiMd)) {
    Set-Content -Path $GeminiMd -Value $AwfInstructions -Encoding UTF8
    Write-Host "✅ Đã tạo Global Rules (GEMINI.md)" -ForegroundColor Green
} else {
    # Always update to latest version - just overwrite BWF section
    $content = Get-Content $GeminiMd -Raw -ErrorAction SilentlyContinue
    if ($null -eq $content) { $content = "" }

    # Clean up OLD AWF block if it exists (legacy from older versions)
    $awfMarker = "# AWF - Antigravity Workflow Framework"
    $awfIndex = $content.IndexOf($awfMarker)
    if ($awfIndex -ge 0) {
        # Find where BWF block starts (if present after AWF)
        $bwfMarker = "# BWF - Antigravity Workflow Framework"
        $bwfIndex = $content.IndexOf($bwfMarker)
        if ($bwfIndex -gt $awfIndex) {
            # Remove AWF block (between AWF marker and BWF marker)
            $content = $content.Substring(0, $awfIndex) + $content.Substring($bwfIndex)
        } elseif ($bwfIndex -lt 0) {
            # No BWF block, AWF is the only one - remove it entirely
            $content = $content.Substring(0, $awfIndex)
        }
    }

    # Now handle BWF block
    $bwfMarker = "# BWF - Antigravity Workflow Framework"
    $markerIndex = $content.IndexOf($bwfMarker)
    if ($markerIndex -ge 0) {
        $content = $content.Substring(0, $markerIndex)
    }
    $content = $content.TrimEnd() + "`n" + $AwfInstructions
    Set-Content -Path $GeminiMd -Value $content -Encoding UTF8
    Write-Host "✅ Đã cập nhật Global Rules (GEMINI.md)" -ForegroundColor Green
}

# 8. Auto-link workflows to ALL workspaces (via Junction for shared global install)
Write-Host ""
Write-Host "⏳ Đang link BWF vào tất cả workspaces..." -ForegroundColor Cyan

$ScratchDir = "$env:USERPROFILE\.gemini\antigravity\scratch"
$linked = 0

if (Test-Path $ScratchDir) {
    $workspaces = Get-ChildItem -Path $ScratchDir -Directory
    foreach ($ws in $workspaces) {
        $agentsDir = Join-Path $ws.FullName ".agents"
        $workflowsLink = Join-Path $agentsDir "workflows"

        # Skip if already a valid junction/symlink pointing to correct target
        if (Test-Path $workflowsLink) {
            $item = Get-Item $workflowsLink -Force
            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
                Write-Host "   ✅ $($ws.Name) (đã link)" -ForegroundColor DarkGray
                $linked++
                continue
            }
            # It's a real directory with existing workflows - backup and replace with junction
            $backupName = "workflows.bak.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            Rename-Item -Path $workflowsLink -NewName $backupName -Force
            Write-Host "   📦 $($ws.Name): backup workflows cũ → $backupName" -ForegroundColor Yellow
        }

        # Create .agents dir if not exists
        if (-not (Test-Path $agentsDir)) {
            New-Item -ItemType Directory -Force -Path $agentsDir | Out-Null
        }

        # Create directory junction: .agents/workflows → global_workflows
        try {
            cmd /c mklink /J "$workflowsLink" "$AntigravityGlobal" 2>$null | Out-Null
            if (Test-Path $workflowsLink) {
                Write-Host "   ✅ $($ws.Name)" -ForegroundColor Green
                $linked++
            } else {
                Write-Host "   ❌ $($ws.Name) (junction failed)" -ForegroundColor Red
            }
        } catch {
            Write-Host "   ❌ $($ws.Name) (error: $($_.Exception.Message))" -ForegroundColor Red
        }
    }
}
Write-Host "🔗 Đã link $linked workspaces" -ForegroundColor Green

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "🎉 HOÀN TẤT! Đã cài $success files + link $linked workspaces." -ForegroundColor Yellow
Write-Host "📦 Version: $CurrentVersion" -ForegroundColor Cyan
Write-Host ""
Write-Host "📂 Workflows: $AntigravityGlobal" -ForegroundColor DarkGray
Write-Host "📂 Schemas:   $SchemasDir" -ForegroundColor DarkGray
Write-Host "📂 Templates: $TemplatesDir" -ForegroundColor DarkGray
Write-Host "📂 Skills:    $SkillsDir" -ForegroundColor DarkGray
Write-Host ""
Write-Host "👉 BWF đã được link vào TẤT CẢ workspaces tự động!" -ForegroundColor Cyan
Write-Host "👉 Mở workspace bất kỳ, gõ '/plan' để dùng ngay." -ForegroundColor White
Write-Host "👉 Thêm workspace mới? Chạy lại installer hoặc gõ '/bwf-update'." -ForegroundColor White
Write-Host "👉 Kiểm tra update: '/bwf-update'" -ForegroundColor White
Write-Host ""

