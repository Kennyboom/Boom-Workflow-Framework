# Reference: DevSecOps Pipeline & Incident Response

## DevSecOps Pipeline

```
┌─────────────────────────────────────────────────────────┐
│ 📝 CODE COMMIT                                          │
│ ├─→ Pre-commit hooks: lint + format + secrets scan      │
│                                                          │
│ 🔍 PULL REQUEST                                         │
│ ├─→ SAST: SonarQube / CodeQL (source code scan)        │
│ ├─→ SCA: Snyk / npm audit (dependency scan)            │
│ ├─→ Secrets: GitLeaks / TruffleHog                     │
│                                                          │
│ 🔨 BUILD                                                │
│ ├─→ Container scan (if Docker)                          │
│ ├─→ SBOM generation                                    │
│ ├─→ License compliance check                           │
│                                                          │
│ 🧪 STAGING                                              │
│ ├─→ DAST: OWASP ZAP (attack running app)              │
│ ├─→ Penetration test scripts                           │
│ ├─→ API fuzzing                                        │
│                                                          │
│ 🚀 PRODUCTION                                           │
│ ├─→ Runtime monitoring                                 │
│ ├─→ Anomaly detection                                  │
│ └─→ Incident response automation                       │
└─────────────────────────────────────────────────────────┘

⚠️ GATE RULES:
🔴 CRITICAL → BLOCK deployment
🟡 HIGH → Manual approval required
🟢 MEDIUM/LOW → Log + create ticket → deploy OK
```

## Incident Response Plan

```
┌─────────────────────────────────────────────────────────┐
│ PHASE 1: DETECTION (0-15 phút)                          │
│ □ Anomaly alert triggered                                │
│ □ Confirm: real attack or false positive?                │
│ □ Assess severity: Critical / High / Medium / Low       │
│                                                          │
│ PHASE 2: CONTAINMENT (15-60 phút)                       │
│ □ Isolate affected systems                               │
│ □ Revoke compromised credentials                         │
│ □ Block attack source (IP/token/account)                 │
│ □ Enable emergency maintenance mode                      │
│                                                          │
│ PHASE 3: ERADICATION (1-24 giờ)                         │
│ □ Identify root cause                                    │
│ □ Patch vulnerability                                    │
│ □ Remove backdoors                                       │
│ □ Update secrets/keys/tokens                             │
│                                                          │
│ PHASE 4: RECOVERY (1-48 giờ)                            │
│ □ Restore from clean backup                              │
│ □ Verify system integrity                                │
│ □ Monitor for re-occurrence                              │
│                                                          │
│ PHASE 5: POST-MORTEM                                     │
│ □ Timeline of events                                     │
│ □ What went wrong / worked well?                         │
│ □ Preventive measures                                    │
│ □ Update security policies                               │
└─────────────────────────────────────────────────────────┘

📞 EMERGENCY CONTACTS:
│ Role            │ Who    │ Contact      │
│ Security Lead   │ [Name] │ [Phone/Email]│
│ DevOps          │ [Name] │ [Phone/Email]│
│ Business Owner  │ [Name] │ [Phone/Email]│
```
