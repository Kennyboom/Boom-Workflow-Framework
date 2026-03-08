# Reference: State Management + Error Handling + Caching

## State Architecture

```
┌─────────────────────────────────────────────────────────┐
│ 🌐 SERVER STATE: TanStack Query / SWR                    │
│   users, orders, products — auto-refetch, cache          │
│                                                          │
│ 💻 CLIENT STATE: Zustand / useState                      │
│   UI (modal, sidebar) — form state — theme/language      │
│                                                          │
│ 💾 PERSISTENT STATE: localStorage / IndexedDB            │
│   Auth tokens, preferences, offline queue                │
│                                                          │
│ 🔗 URL STATE: URL params / searchParams                  │
│   Filters, pagination, selected tab (shareable)          │
└─────────────────────────────────────────────────────────┘

Store Slicing:
│ Store         │ Data                    │ Actions                     │
│ authStore     │ user, token, isLoggedIn │ login, logout, refreshToken │
│ uiStore       │ theme, sidebar, modal   │ toggleSidebar, setTheme     │
│ settingsStore │ language, notifications │ updateSettings              │
```

## Error Classification

```
┌──────────────────┬──────────────────────────────────────┐
│ Validation Error │ Inline ngay tại field                │
│ Auth Error       │ Redirect login, lưu URL hiện tại     │
│ Permission Error │ "403 - Không có quyền"               │
│ Not Found Error  │ Trang 404 đẹp + gợi ý quay về       │
│ Network Error    │ Toast "Mất kết nối" + auto-retry     │
│ Server Error     │ Retry 3 lần (exp. backoff)           │
│ Rate Limit Error │ Countdown khi nào hết bị chặn        │
│ Business Error   │ Thông báo cụ thể ("Hết hàng")       │
└──────────────────┴──────────────────────────────────────┘

Error Response Standard:
{
  "success": false,
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "Không tìm thấy đơn hàng",
    "details": [...],
    "requestId": "req_abc123"
  }
}
```

## Caching Strategy

```
┌──────────────┬──────────────┬────────────┬──────────────┐
│ Layer        │ Tool         │ TTL        │ Data         │
├──────────────┼──────────────┼────────────┼──────────────┤
│ Browser      │ Service Worker│ Variable  │ Static assets│
│ CDN          │ CloudFlare   │ 1 hour     │ Images, fonts│
│ API Response │ TanStack Query│ 5 min     │ API data     │
│ Server       │ Redis        │ 15 min     │ DB queries   │
│ Database     │ Query cache  │ Auto       │ Frequent     │
└──────────────┴──────────────┴────────────┴──────────────┘

Invalidation Rules:
• Create/Update/Delete → Invalidate related cache
• Admin changes → Invalidate all user caches
• Deploy → Bust all static caches

🚫 NEVER CACHE: Auth tokens, real-time data, sensitive data
```
