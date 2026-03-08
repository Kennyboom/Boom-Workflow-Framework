# Reference: Backend & Database Optimization

## API Optimization

```
┌──────────────────┬──────────────────────────────────────┐
│ Response Shape   │ Select ONLY needed fields              │
│                  │ Pagination (cursor-based, not offset)  │
├──────────────────┼──────────────────────────────────────┤
│ Compression      │ Brotli > gzip (10-25% smaller)        │
│                  │ HTTP/2 multiplexing, HTTP/3 + QUIC     │
├──────────────────┼──────────────────────────────────────┤
│ Connection Pool  │ DB: CPU cores * 2 + 1                  │
│                  │ Redis: 10-50 connections                │
├──────────────────┼──────────────────────────────────────┤
│ Background Jobs  │ Heavy tasks → async queue (BullMQ)     │
│                  │ Tokio tasks cho Rust                    │
├──────────────────┼──────────────────────────────────────┤
│ Rate Limiting    │ Per-endpoint, Sliding window, 429      │
└──────────────────┴──────────────────────────────────────┘
```

## Memory & CPU Optimization

```
🧠 MEMORY:
□ Memory leak detection (heap snapshot)
□ Object pooling cho heavy allocations
□ Stream processing thay load-all-into-memory
□ GC tuning (Node: --max-old-space-size)
□ Buffer reuse, Weak references cho caches

💻 CPU:
□ Hot path profiling
□ Algorithm complexity (O(n²) → O(n log n))
□ Avoid blocking main thread
□ Worker threads cho parallel processing
□ Batch operations thay loop-per-item
```

## Database Optimization

```
🔍 QUERY ANALYSIS:
□ EXPLAIN ANALYZE trên slow queries (>100ms)
□ Full table scans → index
□ N+1 queries → JOINs / eager loading

📊 INDEXING STRATEGY:
┌──────────────────┬──────────────────────────────────────┐
│ Single column    │ WHERE clause columns                  │
│ Composite        │ Multi-column WHERE + ORDER BY          │
│ Partial          │ Filtered: WHERE status = 'active'      │
│ GIN/GiST        │ Full-text search, JSONB                │
│ Covering         │ INCLUDES all select columns            │
│ Expression       │ Index trên LOWER(email)                │
└──────────────────┴──────────────────────────────────────┘

⚠️ RULES: Index phải CÓ ÍCH | KHÔNG index cột hay UPDATE | Selective nhất đặt trước

📦 SCALING:
□ Partitioning (>1M rows)
□ Read replicas
□ Materialized views
□ Connection pooling (PgBouncer)
□ Query timeout: 5s
```
