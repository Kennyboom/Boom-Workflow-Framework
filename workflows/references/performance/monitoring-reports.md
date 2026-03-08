# Reference: Monitoring & Performance Report Templates

## Monitoring Stack

```
┌──────────────────┬──────────────────────────────────────┐
│ Real User Monitor│ Vercel Analytics / web-vitals          │
│ Synthetic Monitor│ Lighthouse CI in pipeline             │
│ APM              │ Sentry Performance / Datadog           │
│ DB Monitor       │ pg_stat_statements / slow query log    │
│ Custom Metrics   │ OpenTelemetry spans                   │
│ Uptime           │ Uptime Robot / Better Uptime           │
└──────────────────┴──────────────────────────────────────┘

📊 ALERT THRESHOLDS:
• LCP > 3s → ⚠️ Warning
• INP > 300ms → ⚠️ Warning
• API p95 > 1s → ⚠️ Warning
• API p99 > 2s → 🔴 Critical
• Error rate > 1% → 🔴 Critical
• Memory > 80% → ⚠️ Warning
• Memory growth > 10MB/hour → 🔴 Memory Leak
```

## Before/After Comparison Template

```
┌──────────────────┬──────────┬──────────┬──────────┬──────────┐
│ Metric           │ Before   │ After    │ Change   │ Target   │
├──────────────────┼──────────┼──────────┼──────────┼──────────┤
│ Lighthouse       │ [?]/100  │ [?]/100  │ +[?]     │ >90      │
│ LCP              │ [?]s     │ [?]s     │ -[?]%    │ <2.5s    │
│ INP              │ [?]ms    │ [?]ms    │ -[?]%    │ <200ms   │
│ CLS              │ [?]      │ [?]      │ -[?]%    │ <0.1     │
│ Bundle JS        │ [?]KB    │ [?]KB    │ -[?]%    │ <200KB   │
│ API p50          │ [?]ms    │ [?]ms    │ -[?]%    │ <100ms   │
│ API p95          │ [?]ms    │ [?]ms    │ -[?]%    │ <500ms   │
│ Memory idle      │ [?]MB    │ [?]MB    │ -[?]%    │ <256MB   │
│ DB query avg     │ [?]ms    │ [?]ms    │ -[?]%    │ <50ms    │
│ Cold start       │ [?]s     │ [?]s     │ -[?]%    │ <2s      │
└──────────────────┴──────────┴──────────┴──────────┴──────────┘

🏆 IMPROVEMENT SCORE: [?]% average
```

## Report Template (docs/PERFORMANCE.md)

```markdown
# ⚡ PERFORMANCE REPORT: [Project]
📅 Date | ⚙️ BWF Performance Alchemist v3.0

## 1. Before/After Summary
## 2. Key Optimizations (Frontend/Backend/DB/Network)
## 3. Caching Strategy (6 layers)
## 4. Performance Budget
## 5. Monitoring & Alerts
## 6. Remaining Opportunities
```
