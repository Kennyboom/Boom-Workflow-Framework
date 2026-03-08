# Reference: Performance Profiling & Budget Templates

## Frontend Profiling Checklist

```
□ Lighthouse audit (Performance score)
□ Core Web Vitals (LCP, INP, CLS)
□ Bundle analysis (npm run build → size report)
□ Network waterfall (Chrome DevTools → Network)
□ React DevTools Profiler (component render times)
□ Memory snapshot (Chrome DevTools → Memory)

📊 FRONTEND METRICS:
┌──────────────┬──────────┬──────────┬──────────┐
│ Metric       │ Hiện tại │ Target   │ Gap      │
├──────────────┼──────────┼──────────┼──────────┤
│ Lighthouse   │ [?]/100  │ >90      │ [?]      │
│ LCP          │ [?]s     │ <2.5s    │ [?]      │
│ INP          │ [?]ms    │ <200ms   │ [?]      │
│ CLS          │ [?]      │ <0.1     │ [?]      │
│ Bundle (JS)  │ [?]KB    │ <200KB   │ [?]      │
│ Bundle (CSS) │ [?]KB    │ <50KB    │ [?]      │
│ Total Weight │ [?]MB    │ <1MB     │ [?]      │
└──────────────┴──────────┴──────────┴──────────┘
```

## Backend Profiling Checklist

```
□ API response times (p50, p95, p99)
□ Database slow query log (>100ms)
□ Memory usage (idle, peak, growth rate)
□ CPU usage (idle, peak)
□ Connection pool utilization
□ Error rate (4xx, 5xx)

📊 BACKEND METRICS:
┌──────────────┬──────────┬──────────┬──────────┐
│ API p50      │ [?]ms    │ <100ms   │ [?]      │
│ API p95      │ [?]ms    │ <500ms   │ [?]      │
│ API p99      │ [?]ms    │ <1000ms  │ [?]      │
│ DB query avg │ [?]ms    │ <50ms    │ [?]      │
│ Memory idle  │ [?]MB    │ <256MB   │ [?]      │
│ Error rate   │ [?]%     │ <0.1%    │ [?]      │
└──────────────┴──────────┴──────────┴──────────┘
```

## Desktop Profiling Checklist

```
□ Startup time (cold start → interactive)
□ Memory usage (idle, peak, after 1 hour)
□ CPU usage (idle, during operations)
□ IPC latency (frontend ↔ backend)

📊 DESKTOP METRICS:
┌──────────────┬──────────┬──────────┬──────────┐
│ Cold start   │ [?]s     │ <2s      │ [?]      │
│ Memory idle  │ [?]MB    │ <100MB   │ [?]      │
│ Memory peak  │ [?]MB    │ <500MB   │ [?]      │
│ IPC latency  │ [?]ms    │ <10ms    │ [?]      │
│ CPU idle     │ [?]%     │ <3%      │ [?]      │
└──────────────┴──────────┴──────────┴──────────┘
```

## Performance Budget Table

```
┌─────────────────────────────────────────────────────────┐
│  📱 FRONTEND BUDGET (Core Web Vitals 2025)               │
├────────────────────────┬────────────────────────────────┤
│ LCP                    │ < 2.5s                         │
│ INP                    │ < 200ms                        │
│ CLS                    │ < 0.1                          │
│ TTI                    │ < 3.0s                         │
│ JS Bundle              │ < 200KB gzipped                │
│ CSS Bundle             │ < 50KB gzipped                 │
│ Max Image              │ < 100KB (WebP/AVIF)            │
│ Lighthouse             │ > 90                           │
├────────────────────────┼────────────────────────────────┤
│  🖥️ BACKEND BUDGET                                      │
├────────────────────────┼────────────────────────────────┤
│ API p50                │ < 100ms                        │
│ API p95                │ < 500ms                        │
│ API p99                │ < 1000ms                       │
│ DB Query (simple)      │ < 50ms                         │
│ DB Query (complex)     │ < 200ms                        │
│ Memory (idle)          │ < 256MB                        │
│ Error Rate             │ < 0.1%                         │
└────────────────────────┴────────────────────────────────┘
```
