# Reference: Frontend Optimization Techniques

## Bundle Optimization

```
🔪 TREE SHAKING:
□ ES modules (import/export) thay CommonJS
□ sideEffects: false trong package.json
□ Kiểm tra dead code không bị tree-shake

📦 CODE SPLITTING:
□ Dynamic import per route: import('./pages/Dashboard')
□ Lazy load heavy components (charts, editors, modals)
□ Vendor chunking: tách react, lodash riêng
□ Shared chunk cho common utilities

🗑️ BUNDLE DIET:
□ moment.js → date-fns (-80%)
□ lodash → lodash-es (tree-shakeable)
□ Analyze: npx source-map-explorer / webpack-bundle-analyzer
□ Remove unused CSS (PurgeCSS, Tailwind purge)
□ Xóa polyfills không cần (core-js ~100KB)
```

## Loading Optimization

```
┌──────────────────┬──────────────────────────────────────┐
│ Images           │ Next/Image (auto WebP/AVIF)            │
│                  │ Lazy loading, Blur placeholder          │
│                  │ Responsive srcset, Priority hero        │
├──────────────────┼──────────────────────────────────────┤
│ Fonts            │ font-display: swap                    │
│                  │ Subset, Preload critical, Variable     │
├──────────────────┼──────────────────────────────────────┤
│ CSS              │ Critical CSS inline <head>             │
│                  │ CSS Modules / tree-shaking, Purge      │
├──────────────────┼──────────────────────────────────────┤
│ JavaScript       │ Defer non-critical, Async 3rd-party    │
│                  │ Web Workers, Preload critical chunks    │
└──────────────────┴──────────────────────────────────────┘
```

## Rendering Optimization

```
┌──────────────────┬──────────────────────────────────────┐
│ Rendering Mode   │ SSR: SEO + fast first load             │
│                  │ SSG: Static, build-time                 │
│                  │ ISR: Periodic update                    │
│                  │ CSR: Dynamic, behind auth               │
│                  │ RSC: React Server Components (2025)     │
├──────────────────┼──────────────────────────────────────┤
│ React Perf       │ React.memo(), useMemo/useCallback      │
│                  │ React Compiler (2025 auto-optimize)     │
│                  │ Virtual Lists (>100 items)              │
│                  │ Debounce/Throttle search, scroll        │
├──────────────────┼──────────────────────────────────────┤
│ Paint Perf       │ will-change, transform thay top/left    │
│                  │ GPU compositing, Avoid layout thrashing │
└──────────────────┴──────────────────────────────────────┘
```
