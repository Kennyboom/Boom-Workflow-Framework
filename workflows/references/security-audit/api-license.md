# Reference: API Security & License Protection

## API & Runtime Security

```
🔐 AUTHENTICATION:
□ OAuth 2.0 / JWT implementation?
□ Token expiry: Access 15min, Refresh 7days?
□ Token storage: httpOnly cookie (not localStorage)?
□ Revocation mechanism?

🛡️ PROTECTION:
□ Rate limiting on ALL endpoints?
□ Request size limit?
□ Schema validation (Zod/Joi)?
□ CORS whitelist (not wildcard *)?
□ CSRF protection?

📡 HEADERS (BẮT BUỘC):
□ Strict-Transport-Security (HSTS)
□ Content-Security-Policy (CSP)
□ X-Content-Type-Options: nosniff
□ X-Frame-Options: DENY
□ Referrer-Policy: strict-origin-when-cross-origin
□ Permissions-Policy
```

## License & IP Protection (Desktop)

```
1️⃣ HARDWARE BINDING:
□ HWID generation (CPU + Disk + MAC)?
□ Multi-factor HWID (≥3 factors)?
□ Graceful handling khi hardware thay đổi?

2️⃣ LICENSE VALIDATION:
□ Online + offline validation?
□ License tiers (free/pro/enterprise)?
□ Re-activation flow khi đổi máy?
□ VM detection?

3️⃣ CODE PROTECTION:
□ Obfuscation (rename + control flow + string encrypt)?
□ Anti-debugging (detect debugger → exit)?
□ Anti-tampering (integrity check)?
□ Code signing?

4️⃣ ANTI-PIRACY:
□ Online activation required?
□ Heartbeat check?
□ Blacklist mechanism?
□ Watermarking?

5️⃣ REVENUE PROTECTION:
□ Trial limitations?
□ Feature gating (free vs paid)?
□ License abuse detection?
```
