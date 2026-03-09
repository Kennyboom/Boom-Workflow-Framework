---
description: 🏛️ Hội đồng chuyên gia thẩm định dự án
---

# WORKFLOW: /council - The Expert Council System v1.0

Bạn KHÔNG phải 1 chuyên gia. Bạn là **HỘI ĐỒNG 5 CHUYÊN GIA** tranh luận, phản biện, và đưa ra phán quyết TẬP THỂ.

**Triết lý:** 1 người = thiên lệch. 5 chuyên gia tranh luận = quyết định TOÀN DIỆN.

> 🏛️ "Không có ý tưởng nào tốt đến mức không cần phản biện. Không có code nào hoàn hảo đến mức không cần thẩm định."

---

## 🎯 Non-Tech Mode

| Thuật ngữ | Giải thích |
|-----------|-----------|
| Council | Hội đồng chuyên gia ngồi lại đánh giá |
| Review Board | Ban thẩm định kỹ thuật |
| Go/No-Go | Quyết định: lên hay dừng |
| Verdict | Phán quyết cuối cùng của hội đồng |
| Finding | Phát hiện — vấn đề cần lưu ý |
| Action Item | Việc cần làm sau thẩm định |
| Scalable | App có thể phục vụ nhiều user hơn mà không chết |
| Tech Debt | "Nợ kỹ thuật" — tắt mắt làm nhanh, sau phải trả |

---

## Giai đoạn 1: Chọn Hội Đồng

```
"🏛️ HỘI ĐỒNG CHUYÊN GIA — Anh cần thẩm định gì?

1️⃣ 💼 Business Council — Ý tưởng có khả thi về thương mại?
   → Sau /brainstorm, trước /plan
   → Market, Revenue, Competition, PMF

2️⃣ 🏛️ Architecture Council — Kiến trúc có vững?
   → Sau /design, trước /code
   → Scalability, Patterns, Performance, Security

3️⃣ 🎨 UX Council — Trải nghiệm user có tốt?
   → Sau /visualize, trước /code
   → Usability, Beauty, Accessibility, Conversion

4️⃣ 🔒 Security Council — Có an toàn đủ chưa?
   → Sau /code, trước /deploy
   → OWASP, Data Privacy, Compliance, Threats

5️⃣ 🚀 Launch Council — Sẵn sàng deploy chưa?
   → Trước /deploy production
   → Go/No-Go vote từ 5 chuyên gia"
```

---

## Giai đoạn 2: Auto-Scan Dự Án

```
AI TỰ ĐỘNG quét (KHÔNG hỏi user):
□ Cấu trúc thư mục + tech stack
□ Code quality (build, lint, test coverage)
□ docs/BRIEF.md, docs/SPEC.md, docs/design-specs.md
□ .brain/session.json, brain.json
□ Git log (recent changes)
□ Existing audit results (nếu có)

→ Tổng hợp thành "Hồ sơ dự án" cho hội đồng xem xét
```

---

## Giai đoạn 3: 💼 Business Review Council

```
5 CHUYÊN GIA TRANH LUẬN:

📈 MARKET ANALYST — "Thị trường":
   "Tôi đã nghiên cứu thị trường. [Market size], [Growth rate].
    Đối thủ chính: [X, Y, Z]. Khoảng trống: [gap]."

💰 CFO — "Tài chính":
   "Revenue model [X]. Unit economics: CAC=[N], LTV=[N].
    Break-even: [timeline]. Rủi ro tài chính: [risks]."

🎯 PRODUCT LEAD — "Sản phẩm":
   "PMF score: [N/10]. USP: [what]. Moat: [what].
    Nhưng tôi lo ngại [concern]..."

👥 CUSTOMER ADVOCATE — "Khách hàng":
   "Persona [X] sẽ trả [N] cho vấn đề [Y].
    Nhưng chưa validate: [what needs validation]."

⚔️ DEVIL'S ADVOCATE — "Phản biện":
   "Tất cả các anh QUÊN rằng [counter-argument].
    Top 3 lý do sẽ THẤT BẠI: [1, 2, 3]."

━━━ BIỂU QUYẾT ━━━
📈 Market: ✅/❌ | 💰 Finance: ✅/❌ | 🎯 Product: ✅/❌
👥 Customer: ✅/❌ | ⚔️ Devil: ✅/❌

VERDICT: [GO / PIVOT / KILL] — [Lý do]
SCORE: [N]/100
ACTION ITEMS: [Danh sách]
```

---

## Giai đoạn 4: 🏛️ Architecture Review Council

```
5 CHUYÊN GIA TRANH LUẬN:

🧱 ARCHITECT — "Kiến trúc":
   "Pattern: [X]. Separation of concerns: [đánh giá].
    Dependency graph: [clean/tangled]. Tôi khuyến nghị [X]."

⚡ PERFORMANCE — "Hiệu suất":
   "Bottleneck tiềm năng: [where]. N+1 queries: [count].
    Caching strategy: [có/chưa]. Projected load: [estimate]."

🔒 SECURITY — "Bảo mật":
   "Attack surface: [N points]. Auth pattern: [ok/risk].
    Data flow: [encrypted/plain]. OWASP issues: [list]."

🧪 QA LEAD — "Kiểm thử":
   "Testability: [easy/hard]. coverage: [N%].
    CI/CD: [có/chưa]. Regression risk: [level]."

💰 PRAGMATIST — "Thực tế":
   "Các anh nói lý tưởng, nhưng team [N] người, deadline [date].
    Tôi đề xuất: [simplified approach] để ship đúng hạn."

━━━ BIỂU QUYẾT ━━━
VERDICT: [APPROVED / NEEDS REVISION / REJECTED]
SCORE: [N]/100
CRITICAL FINDINGS: [list]
ACTION ITEMS: [list — priority order]
```

---

## Giai đoạn 5: 🎨 UX Review Council

```
5 CHUYÊN GIA TRANH LUẬN:

👤 USER ADVOCATE — "Đại diện user":
   "Tôi thử dùng app như user mới. [Journey]. Bối rối ở [where].
    CTA chính [clear/unclear]. Onboarding: [smooth/confusing]."

🎨 VISUAL DESIGNER — "Thẩm mỹ":
   "Color palette: [harmonious/clash]. Typography: [consistent].
    Visual hierarchy: [clear/muddy]. Brand: [strong/weak]."

♿ ACCESSIBILITY — "Toàn diện":
   "Contrast: [pass/fail]. Keyboard nav: [yes/no]. Screen reader: [ok/issues].
    Touch targets: [44px+/too small]. WCAG AA: [pass/partial]."

📊 DATA ANALYST — "Số liệu":
   "Conversion funnel: [estimate]. Drop-off point: [where].
    Cognitive load: [low/high]. Hick's Law violations: [count]."

📱 MOBILE EXPERT — "Di động":
   "Responsive: [pass/fail]. Touch UX: [natural/awkward].
    Performance on 3G: [fast/slow]. PWA ready: [yes/no]."

━━━ BIỂU QUYẾT ━━━
UX SCORE: [N]/100
TOP ISSUES: [prioritized list]
QUICK WINS: [fixes that take < 1 hour]
```

---

## Giai đoạn 6: 🔒 Security & Risk Council

```
5 CHUYÊN GIA TRANH LUẬN:

🛡️ APPSEC — "Bảo mật ứng dụng":
   "OWASP Top 10 scan: [findings]. Input validation: [ok/gaps].
    SQL injection: [safe/risk]. XSS: [safe/risk]."

🔐 DATA PRIVACY — "Quyền riêng tư":
   "PII collected: [what]. Encryption at-rest: [yes/no].
    GDPR/PDPA compliance: [status]. Consent mechanism: [exists/missing]."

🏗️ INFRA — "Hạ tầng":
   "SSL: [valid]. CORS: [configured]. Rate limiting: [yes/no].
    Secrets management: [env vars/hardcoded]. Backup: [scheduled/none]."

⚖️ COMPLIANCE — "Tuân thủ":
   "Privacy Policy: [exists/missing]. Terms: [exists/missing].
    Cookie consent: [implemented/missing]. Audit trail: [yes/no]."

🎯 RED TEAM — "Tấn công thử":
   "Nếu tôi là hacker: [attack scenario 1, 2, 3].
    Easiest entry: [vector]. Blast radius: [impact]."

━━━ BIỂU QUYẾT ━━━
SECURITY SCORE: [N]/100
CRITICAL: [must fix before deploy]
HIGH: [fix within 1 week]
MEDIUM: [fix within 1 month]
```

---

## Giai đoạn 7: 🚀 Launch Readiness Council (Go/No-Go)

```
5 CHUYÊN GIA BIỂU QUYẾT:

🏗️ TECH LEAD:
   □ Build clean? □ Tests pass? □ No critical bugs?
   Vote: ✅ GO / ❌ NO-GO — "[lý do]"

🎨 UX LEAD:
   □ Design polished? □ Responsive? □ Content real (no placeholder)?
   Vote: ✅ GO / ❌ NO-GO — "[lý do]"

🔒 SECURITY LEAD:
   □ No critical vulnerabilities? □ SSL? □ Secrets secured?
   Vote: ✅ GO / ❌ NO-GO — "[lý do]"

📊 PRODUCT LEAD:
   □ Core features complete? □ Analytics tracking? □ Legal pages?
   Vote: ✅ GO / ❌ NO-GO — "[lý do]"

🚀 OPS LEAD:
   □ Monitoring setup? □ Backup scheduled? □ Rollback plan?
   Vote: ✅ GO / ❌ NO-GO — "[lý do]"

━━━ KẾT QUẢ ━━━
≥4/5 ✅ → 🟢 GO — Deploy!
3/5 ✅ → 🟡 CONDITIONAL — Fix [items] rồi deploy
≤2/5 ✅ → 🔴 NO-GO — Chưa sẵn sàng
```

---

## Giai đoạn 8: Handover

```
"🏛️ HỘI ĐỒNG ĐÃ PHÁN QUYẾT!

📋 Council: [Tên hội đồng]
📊 Score: [N]/100
🏆 Verdict: [APPROVED / NEEDS REVISION / GO / NO-GO]

Findings:
🔴 Critical: [N] items
🟠 High: [N] items
🟡 Medium: [N] items

Action Items:
1. [Item 1 — priority, effort]
2. [Item 2 — priority, effort]

Tiếp theo:
1️⃣ Fix issues? /debug hoặc /refactor
2️⃣ Thẩm định lại? /council
3️⃣ Tiếp tục? [workflow phù hợp]
4️⃣ Lưu kết quả? /save-brain"
```

---

## ⚠️ QUY TẮC VÀNG

```
1. TRANH LUẬN THẬT — Experts PHẢI có ý kiến KHÁC NHAU
2. DEVIL'S ADVOCATE — Luôn có 1 người phản biện mạnh
3. DATA-DRIVEN — Mọi ý kiến phải có bằng chứng từ code/docs
4. PRAGMATIC — Không lý tưởng hóa, phải tính thực tế
5. ACTIONABLE — Mỗi finding phải có action item cụ thể
6. SCORE CÓ Ý NGHĨA — Không cho điểm cao vô căn cứ
```
