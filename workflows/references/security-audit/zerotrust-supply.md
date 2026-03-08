# Reference: Zero Trust Audit & Supply Chain Security

## Zero Trust Checklist

```
1️⃣ IDENTITY VERIFICATION:
□ Mọi request có authentication token?
□ Token verified ở EVERY endpoint?
□ Service-to-service có mTLS?
□ API keys rotate định kỳ?

2️⃣ LEAST PRIVILEGE:
□ Users chỉ có quyền CẦN THIẾT?
□ Admin access có MFA?
□ Role-based access control (RBAC)?
□ Separation of duties?

3️⃣ MICRO-SEGMENTATION:
□ Network segments isolated?
□ Database access restricted by service?
□ Secrets management (Vault/env)?

RBAC Matrix template:
│ Action         │ Admin │ Editor │ Viewer │ Guest │
│ Create         │ ✅    │ ✅     │ ❌     │ ❌    │
│ Read           │ ✅    │ ✅     │ ✅     │ 🔒    │
│ Update         │ ✅    │ ✅     │ ❌     │ ❌    │
│ Delete         │ ✅    │ ❌     │ ❌     │ ❌    │
│ Manage Users   │ ✅    │ ❌     │ ❌     │ ❌    │
```

## Supply Chain Security

```
🔍 DEPENDENCY SCAN:
□ npm audit / yarn audit / pip audit → CVE check
□ Snyk / Dependabot automated PRs
□ Lock file committed + integrity verified
□ No typosquatting packages

📜 LICENSE CHECK:
□ All dependencies have compatible licenses?
□ No GPL in proprietary project?
□ SBOM (Software Bill of Materials) generated?

🔒 BUILD PIPELINE:
□ Dependencies pinned to exact versions?
□ Checksum verification on install?
□ Private registry for internal packages?
```
