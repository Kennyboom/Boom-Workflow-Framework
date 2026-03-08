# Reference: Production Readiness (DB Migration + Load Testing + Smoke Tests)

## Database Migration Protocol

### Migration File Naming
```
migrations/
├── 001_create_users.sql
├── 002_create_orders.sql
├── 003_add_user_avatar.sql      # Safe: ADD nullable column
├── 004_rename_name_to_fullname.sql  # Dangerous: 3-step process
```

### 3-Step Rename Column
```
STEP 1 (Deploy A): Add new column
  ALTER TABLE users ADD COLUMN full_name VARCHAR;
  UPDATE users SET full_name = name;
  → App reads from BOTH "name" and "full_name"

STEP 2 (Deploy B): Switch app to use new column
  → App writes to "full_name", reads from "full_name"
  → Old "name" column still exists (backward compatible)

STEP 3 (Deploy C): Drop old column (after 24h monitoring)
  ALTER TABLE users DROP COLUMN name;
```

### Pre-Migration Checklist
```
□ Backup production database
□ Test migration on staging (identical schema)
□ Estimate migration duration (for large tables)
□ Check: Is migration backward-compatible?
□ Check: Can app work with BOTH old and new schema?
□ Check: Any locks on large tables? (Use pt-online-schema-change)
□ Prepare rollback migration script
□ Schedule maintenance window (if locking required)
```

### Post-Migration Verification
```
□ Table structure matches expected schema
□ Data integrity: row counts, NULL checks
□ Indexes exist and working (EXPLAIN ANALYZE)
□ Foreign keys valid
□ Application queries working with new schema
□ No orphaned data
```

## Load Testing Scripts

### k6 Basic Script
```javascript
// load-test.js
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '1m', target: 50 },   // Ramp up to 50 users
    { duration: '3m', target: 50 },   // Stay at 50
    { duration: '1m', target: 200 },  // Ramp to 200
    { duration: '3m', target: 200 },  // Stay at 200
    { duration: '1m', target: 0 },    // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],  // 95% under 500ms
    http_req_failed: ['rate<0.01'],    // Error rate < 1%
  },
};

export default function () {
  const res = http.get('https://your-app.com/api/health');
  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
  });
  sleep(1);
}

// Run: k6 run load-test.js
```

### Load Test Thresholds
```
│ Tier          │ Concurrent │ p95 Latency │ Error Rate │
│ Minimum       │ 50         │ < 500ms     │ < 1%       │
│ Standard      │ 200        │ < 500ms     │ < 0.5%     │
│ Enterprise    │ 1000       │ < 500ms     │ < 0.1%     │
│ Spike (10s)   │ 5x normal  │ < 2s        │ < 5%       │
```

## Smoke Test Templates

### API Smoke Test Script
```bash
#!/bin/bash
BASE_URL="${1:-https://your-app.com}"
PASS=0; FAIL=0

check() {
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL$1")
  if [ "$STATUS" = "$2" ]; then
    echo "✅ $1 → $STATUS"; PASS=$((PASS+1))
  else
    echo "❌ $1 → $STATUS (expected $2)"; FAIL=$((FAIL+1))
  fi
}

check "/api/health" "200"
check "/" "200"
check "/login" "200"
check "/api/nonexistent" "404"

echo "━━━━━━━━━━━━━━━━━"
echo "PASS: $PASS | FAIL: $FAIL"
[ $FAIL -gt 0 ] && echo "🔴 SMOKE TEST FAILED!" && exit 1
echo "🟢 ALL SMOKE TESTS PASSED!"
```

### Browser Smoke Test (Playwright)
```typescript
test('smoke: homepage loads', async ({ page }) => {
  await page.goto('/');
  await expect(page).toHaveTitle(/App Name/);
  await expect(page.locator('nav')).toBeVisible();
});

test('smoke: login works', async ({ page }) => {
  await page.goto('/login');
  await page.fill('[name=email]', 'test@example.com');
  await page.fill('[name=password]', 'testpass');
  await page.click('button[type=submit]');
  await expect(page).toHaveURL('/dashboard');
});
```

## Go/No-Go Decision Checklist

```
BEFORE DEPLOY — ALL must be YES:
□ All tests passing? [YES/NO]
□ Build clean (no warnings)? [YES/NO]
□ Security audit passed? [YES/NO/Skipped]
□ Performance budget met? [YES/NO]
□ Database backup taken? [YES/NO]
□ Rollback plan documented? [YES/NO]
□ Team notified? [YES/NO]
□ Maintenance window scheduled (if needed)? [YES/NO/N/A]

IF ANY NO → HOLD DEPLOY. Fix first.
IF ALL YES → GO! Proceed with deploy.
```
