# Reference: Edge Cases + Performance Testing

## Edge Case Matrix

```
📝 INPUT EDGE CASES:
□ Empty string "", null, undefined
□ Rất dài (10,000+ chars)
□ Special chars: <script>, ' OR 1=1 --, ../etc/passwd
□ Emoji: 🔥🎉
□ Unicode: café, naïve, résumé
□ Số cực lớn: 999999999999
□ Số âm: -1, -0.001
□ SQL Injection: ' OR 1=1 --
□ XSS: <img onerror=alert(1)>
□ Path traversal: ../../etc/passwd

🖥️ UI EDGE CASES:
□ Double-click nhanh (duplicate submit?)
□ Rapid navigation (page A → B → A)
□ Text rất dài (cắt hay wrap?)
□ Nhiều items (100+ rows → pagination?)
□ Autofill browser
□ Zoom 200% / 50%
□ Screen reader / keyboard-only

⏱️ TIMING EDGE CASES:
□ Slow network (simulate 3G)
□ Timeout (request > 30s)
□ Concurrent requests (double submit)
□ Race condition (2 user cùng edit)
□ Session expired giữa chừng
□ Clock change (timezone)

📱 DEVICE EDGE CASES:
□ Mobile vs Desktop
□ Touch vs Mouse
□ Landscape vs Portrait
□ Low memory / slow CPU
□ Old browser (Safari, Firefox quirks)
```

## Performance Testing Checklist

```
🖥️ FRONTEND:
□ Bundle size < 300KB gzipped?
□ LCP < 2.5s?
□ FPS ≥ 60?
□ Lighthouse score ≥ 90?
□ Lazy loading cho images?
□ Không có unnecessary re-renders?

💾 BACKEND:
□ API response < 500ms?
□ Database queries < 100ms? (EXPLAIN ANALYZE)
□ N+1 query problems?
□ Proper caching?
□ Pagination cho large datasets?

🔗 NETWORK:
□ Gzip/Brotli compression?
□ HTTP/2 or HTTP/3?
□ Proper cache headers?
□ CDN configured?
```

## Regression Testing

```
🔄 REGRESSION CHECK:
1. Liệt kê files vừa sửa
2. Tìm modules LIÊN QUAN (imports/exports)
3. Test lại modules liên quan
4. Run FULL test suite

EXPLORATORY TESTING:
1. Smoke Test: Click mọi trang, check render
2. Rapid Testing: Click mọi thứ, nhập mọi thứ
3. Persona Testing: Test như user mới, user cũ, admin
4. Destructive Testing: Cố tình phá app
```
