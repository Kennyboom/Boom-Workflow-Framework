# Reference: Caching Strategy & Network Optimization

## 6-Layer Caching Strategy

```
┌─────────────────────────────────────────────────────────┐
│  LAYER 1: BROWSER CACHE                                  │
│  Static: Cache-Control: max-age=31536000                 │
│  HTML: no-cache (always revalidate), ETags               │
├─────────────────────────────────────────────────────────┤
│  LAYER 2: CDN CACHE                                      │
│  Cloudflare/Vercel edge, stale-while-revalidate          │
│  Auto WebP/AVIF conversion                               │
├─────────────────────────────────────────────────────────┤
│  LAYER 3: API GATEWAY CACHE                              │
│  Frequent endpoints, TTL by freshness                    │
│  Key: URL + params + role                                │
├─────────────────────────────────────────────────────────┤
│  LAYER 4: APPLICATION CACHE (Redis/Memcached)            │
│  Session, preferences, config                            │
│  TTL: 5min (short) → 1hour (config)                     │
├─────────────────────────────────────────────────────────┤
│  LAYER 5: DATABASE QUERY CACHE                           │
│  Expensive queries, Materialized views                   │
│  Invalidate on write                                     │
├─────────────────────────────────────────────────────────┤
│  LAYER 6: CLIENT-SIDE CACHE                              │
│  React Query/SWR, IndexedDB, Service Worker              │
└─────────────────────────────────────────────────────────┘

⚠️ INVALIDATION: Time-based | Event-based | Version-based
RULE: Không biết khi nào invalidate → ĐỪNG cache
```

## Desktop Optimization

```
□ STARTUP: Lazy load, Defer init, Splash screen, Parallel init
□ MEMORY: Drop unused, Stream files, Limit webview history, Pool objects
□ IPC: Batch calls, MessagePack (-40%), Shared memory
□ STORAGE: SQLite WAL, Batch writes, PRAGMA synchronous=NORMAL
```

## Network Optimization

```
□ PROTOCOL: HTTP/3 + QUIC, gRPC internal, WebSocket realtime
□ RESOURCE HINTS: preload (critical), prefetch (next), preconnect (3rd party)
□ COMPRESSION: Brotli > gzip, Compress >1KB
□ API: Batch requests, Abort controller, Retry w/ backoff
```
