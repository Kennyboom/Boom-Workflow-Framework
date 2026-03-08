# Reference: OWASP Top 10:2025 & STRIDE Threat Model

## OWASP Top 10:2025 Checklist

```
┌─────┬──────────────────────────────────────────────────┬────────┐
│ #   │ Vulnerability                                     │ Status │
├─────┼──────────────────────────────────────────────────┼────────┤
│ A01 │ BROKEN ACCESS CONTROL                              │ □      │
│     │ □ Horizontal escalation (truy cập data người khác)?│        │
│     │ □ Vertical escalation (user → admin)?              │        │
│     │ □ URL manipulation bypass?                         │        │
│     │ □ IDOR (insecure direct object reference)?         │        │
│     │ □ CORS misconfiguration?                           │        │
│     │ □ Missing function-level access check?             │        │
├─────┼──────────────────────────────────────────────────┼────────┤
│ A02 │ CRYPTOGRAPHIC FAILURES                              │ □      │
│     │ □ Sensitive data in plaintext?                      │        │
│     │ □ Weak algorithms (MD5, SHA1)?                     │        │
│     │ □ Keys hardcoded in source?                        │        │
│     │ □ HTTP (not HTTPS)?                                │        │
├─────┼──────────────────────────────────────────────────┼────────┤
│ A03 │ INJECTION                                            │ □      │
│     │ □ SQL injection? → Parameterized queries            │        │
│     │ □ NoSQL injection?                                  │        │
│     │ □ OS command injection?                              │        │
│     │ □ XSS (Stored / Reflected / DOM)?                  │        │
├─────┼──────────────────────────────────────────────────┼────────┤
│ A04 │ INSECURE DESIGN                                      │ □      │
│     │ □ Threat modeling done?                              │        │
│     │ □ Security requirements defined?                    │        │
├─────┼──────────────────────────────────────────────────┼────────┤
│ A05 │ SECURITY MISCONFIGURATION                            │ □      │
│     │ □ Default credentials?                               │        │
│     │ □ Verbose error messages in production?             │        │
│     │ □ Unnecessary features enabled?                      │        │
├─────┼──────────────────────────────────────────────────┼────────┤
│ A06 │ VULNERABLE COMPONENTS                                │ □      │
│     │ □ Dependencies có CVE known?                        │        │
│     │ □ Lock file integrity?                               │        │
│     │ □ Typosquatting packages?                            │        │
├─────┼──────────────────────────────────────────────────┼────────┤
│ A07 │ AUTH FAILURES                                         │ □      │
│     │ □ Brute force protection?                            │        │
│     │ □ Session management secure?                         │        │
│     │ □ MFA available?                                     │        │
├─────┼──────────────────────────────────────────────────┼────────┤
│ A08 │ DATA INTEGRITY FAILURES                               │ □      │
│     │ □ CI/CD pipeline unsigned?                           │        │
│     │ □ Auto-update without verification?                  │        │
├─────┼──────────────────────────────────────────────────┼────────┤
│ A09 │ MONITORING FAILURES                                   │ □      │
│     │ □ Logins/failures logged?                            │        │
│     │ □ Alerts for suspicious activity?                    │        │
├─────┼──────────────────────────────────────────────────┼────────┤
│ A10 │ SSRF                                                   │ □      │
│     │ □ URL validation on server-side requests?            │        │
│     │ □ Internal network access blocked?                   │        │
└─────┴──────────────────────────────────────────────────┴────────┘
```

## STRIDE Threat Model

```
┌──────────────────────────────────────────────────────────────┐
│ S — SPOOFING (Giả mạo danh tính)                              │
│   Phòng thủ: □ OAuth/JWT □ MFA □ Session management           │
├──────────────────────────────────────────────────────────────┤
│ T — TAMPERING (Sửa đổi dữ liệu)                              │
│   Phòng thủ: □ HTTPS □ Input validation □ Integrity checks    │
├──────────────────────────────────────────────────────────────┤
│ R — REPUDIATION (Chối bỏ hành động)                           │
│   Phòng thủ: □ Audit logs □ Digital signatures □ Timestamps   │
├──────────────────────────────────────────────────────────────┤
│ I — INFORMATION DISCLOSURE (Lộ thông tin)                     │
│   Phòng thủ: □ Encryption □ Access control □ Error masking    │
├──────────────────────────────────────────────────────────────┤
│ D — DENIAL OF SERVICE                                          │
│   Phòng thủ: □ Rate limiting □ CDN □ Auto-scaling             │
├──────────────────────────────────────────────────────────────┤
│ E — ELEVATION OF PRIVILEGE                                     │
│   Phòng thủ: □ Least privilege □ RBAC □ Input validation      │
└──────────────────────────────────────────────────────────────┘
```
