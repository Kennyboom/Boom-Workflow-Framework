# Reference: Debug Investigation Patterns

## Scientific Method Investigation

```
Giả thuyết → Thí nghiệm → Kết luận

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🐛 BUG: [Mô tả ngắn]
📍 LOCATION: [File + line]
🏷️ TYPE: [CRASH / LOGIC / PERF / UI / INFRA / TIMING]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 GIẢ THUYẾT A (70% khả năng):
   📌 Nguyên nhân: [...]
   🔍 Bằng chứng: [Dữ kiện từ log/code]
   🧪 Thí nghiệm: [Cách kiểm chứng]
   ⏱️  Thời gian: [X phút]

🎯 GIẢ THUYẾT B (20% khả năng):
   [Tương tự]

🎯 GIẢ THUYẾT C (10% khả năng):
   [Tương tự]

Tools: IDE debugger, console.log, network tab
Git bisect: git bisect start → good [commit] → bad [commit]
```

## Fishbone Root Cause Analysis

```
6 NHÁNH PHÂN TÍCH:

                     BUG: [Mô tả]
                         │
    ┌────────────────────┼────────────────────┐
    │                    │                    │
  CODE              NETWORK              CONFIG
  Logic sai?        API timeout?         .env sai?
  Type mismatch?    CORS blocked?        Version mismatch?
    │                    │                    │
  DATA               INFRA               HUMAN
  Input bất thường?  Server down?        Deploy nhầm?
  Race condition?    Memory full?        Merge conflict?
```

## Complex Bug Patterns

```
🔻 RACE CONDITION:
   Triệu chứng: Lỗi ngẫu nhiên
   Chẩn đoán: 2+ async cùng truy cập 1 resource?
   Phác đồ: Mutex → Queue → Debounce → Lock

💧 MEMORY LEAK:
   Triệu chứng: App ngày càng chậm
   Chẩn đoán: Không cleanup listeners/intervals/subscriptions?
   Phác đồ: Cleanup useEffect → WeakRef → Pool

🔒 DEADLOCK:
   Triệu chứng: App treo hoàn toàn
   Chẩn đoán: 2+ processes chờ nhau? DB locks?
   Phác đồ: Lock ordering → Timeout → Tránh nested transactions

♾️ INFINITE LOOP:
   Triệu chứng: CPU 100%, no response
   Chẩn đoán: While không exit? Recursive không base case?
   Phác đồ: Max iterations → Recursion depth limit

👻 HEISENBUG:
   Triệu chứng: Fix chỗ này, hỏng chỗ khác
   Chẩn đoán: Timing-dependent? Side effects?
   Phác đồ: Immutable state → Pure functions → Logging
```

## Dependency Analysis

```
Impact Graph:
File A ──→ File B ──→ File C (🐛)
                          ↓
                      File D ──→ File E

Fix C → kiểm tra D, E có bị ảnh hưởng?
Shared Dependencies → Fix Module X ảnh hưởng TẤT CẢ files dùng nó
```

## Performance Debug

```
⚡ FRONTEND:
□ Component re-render? (React Profiler)
□ Images chưa optimize? (WebP, lazy loading)
□ Bundle size > 300KB?
□ CSS animations janky? (use transform)
□ Too many DOM elements? (> 1500 nodes)

💾 BACKEND:
□ N+1 query? (100 queries vs 1)
□ Missing database index?
□ Query phức tạp? (EXPLAIN ANALYZE)
□ Synchronous blocking operations?
□ Memory leak? (heap snapshot)

🔗 NETWORK:
□ Payload quá lớn? (> 1MB)
□ Không có caching?
□ Quá nhiều requests?
□ Missing CDN?
```
