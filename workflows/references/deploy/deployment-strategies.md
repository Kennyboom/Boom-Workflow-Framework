# Reference: Deployment Strategies (Blue-Green, Canary, Rolling)

## Blue-Green Deployment Config

### Vercel (Instant Rollback)
```
# Vercel already does Blue-Green by default
# Every deploy creates immutable deployment
# Rollback: vercel rollback [deployment-url]
# Or: Dashboard → Deployments → Promote previous
```

### Docker Compose Blue-Green
```yaml
# docker-compose.blue.yml
services:
  app-blue:
    image: myapp:v1.0
    ports: ["3001:3000"]

# docker-compose.green.yml  
services:
  app-green:
    image: myapp:v2.0
    ports: ["3002:3000"]

# nginx upstream switch:
# upstream app { server localhost:3001; }  → Blue
# upstream app { server localhost:3002; }  → Green
# nginx -s reload (instant switch)
```

### Kubernetes Blue-Green
```yaml
# Deploy Green
kubectl apply -f deployment-green.yaml
# Test Green
kubectl port-forward svc/app-green 8080:80
# Switch Service selector
kubectl patch svc app -p '{"spec":{"selector":{"version":"green"}}}'
# Rollback
kubectl patch svc app -p '{"spec":{"selector":{"version":"blue"}}}'
```

## Canary Deployment Config

### Nginx Canary (Weight-based)
```nginx
upstream app {
    server app-v1:3000 weight=99;  # 99% old
    server app-v2:3000 weight=1;   # 1% new (canary)
}

# Gradually increase:
# weight=90 / weight=10  → 10%
# weight=50 / weight=50  → 50%
# weight=0  / weight=100 → 100% (full rollout)
```

### Kubernetes Canary
```yaml
# Stable: 9 replicas of v1
# Canary: 1 replica of v2
# = 10% canary traffic

# Monitor: kubectl top pods, error rates
# Scale up canary → scale down stable
```

### Vercel / Cloudflare (A/B Split)
```
# Vercel: Use Edge Middleware for traffic splitting
# Cloudflare: Workers for percentage-based routing
```

## Rolling Update Config

### Kubernetes
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1        # 1 extra pod during update
    maxUnavailable: 0   # Zero downtime
```

### PM2 (Node.js)
```bash
pm2 reload app --update-env  # Zero-downtime reload
```

## Feature Flag Implementation

### Simple ENV-based
```typescript
// lib/flags.ts
export const flags = {
  NEW_CHECKOUT: process.env.FEATURE_NEW_CHECKOUT === 'true',
  AI_RECOMMENDATIONS: process.env.FEATURE_AI_RECS === 'true',
  DARK_MODE: process.env.FEATURE_DARK_MODE === 'true',
}

// Usage
import { flags } from '@/lib/flags'
if (flags.NEW_CHECKOUT) { /* new flow */ }
else { /* old flow */ }
```

### Database-based (Runtime Toggle)
```sql
CREATE TABLE feature_flags (
  name VARCHAR PRIMARY KEY,
  enabled BOOLEAN DEFAULT false,
  rollout_percentage INT DEFAULT 0,
  user_whitelist TEXT[], -- specific users for beta
  updated_at TIMESTAMP
);
```

### Tools
```
Free/Open Source:
- Unleash (self-hosted)
- Flagsmith (free tier)
- GrowthBook (AB testing + flags)

Paid:
- LaunchDarkly (enterprise)
- Split.io
```

## Rollback Procedures

### Immediate Rollback Checklist
```
1. DETECT: Alert triggered / user report / smoke test fail
2. DECIDE: Rollback within 5 minutes of detection
3. EXECUTE:
   □ Revert traffic to previous version
   □ Verify old version working
   □ Notify team: "Rollback executed: [reason]"
4. INVESTIGATE:
   □ Collect logs from failed deployment
   □ Identify root cause
   □ Fix and re-deploy through normal pipeline
```

### Platform-Specific Rollback
```
Vercel:    vercel rollback <url>
Railway:   railway environment rollback
Docker:    docker-compose -f docker-compose.blue.yml up -d
K8s:       kubectl rollout undo deployment/app
Git:       git revert HEAD && git push  # trigger CI/CD
PM2:       pm2 rollback  # if using PM2 deploy
```
