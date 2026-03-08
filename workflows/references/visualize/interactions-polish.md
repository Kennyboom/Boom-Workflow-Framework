# Reference: Micro-interactions + Premium Polish

## Interaction Map

```
┌──────────────┬─────────────────────────────────────────┐
│ Trigger      │ Animation                               │
├──────────────┼─────────────────────────────────────────┤
│ Button hover │ Scale 1.02 + shadow tăng + color shift  │
│ Button click │ Scale 0.98 (nhấn xuống) → 1.0           │
│ Page load    │ Stagger fade-in (từng block lần lượt)   │
│ Card hover   │ Translate Y -4px + shadow tăng          │
│ Link hover   │ Underline slide-in từ trái→phải         │
│ Loading      │ Skeleton shimmer (gradient chạy ngang)  │
│ Success      │ Checkmark draw animation + confetti     │
│ Error        │ Shake nhẹ + border đỏ pulse             │
│ Form focus   │ Border glow + label float up            │
│ Toggle       │ Slide smooth + color transition         │
│ Scroll       │ Elements fade-in khi vào viewport       │
│ Toast        │ Slide-in từ top-right + auto-dismiss    │
│ Modal open   │ Backdrop fade + modal scale 0.95→1.0    │
│ Modal close  │ Scale 1.0→0.95 + fade-out               │
│ Delete       │ Row slide-out + height collapse          │
├──────────────┴─────────────────────────────────────────┤
│ ⏱️ TIMING:                                             │
│ • Instant feedback: 100-150ms (hover, click)           │
│ • Transitions: 200-300ms (modals, page changes)        │
│ • Complex animations: 400-600ms (celebrations)         │
│ • Easing: ease-out (vào), ease-in-out (ra)             │
│ 🎯 prefers-reduced-motion → TẮT tất cả animation      │
└─────────────────────────────────────────────────────────┘
```

## Premium Polish Checklist

```
🌟 SHADOWS (Layered 2-3 lớp):
□ box-shadow: 0 1px 2px rgba(0,0,0,0.06),
               0 4px 8px rgba(0,0,0,0.04),
               0 12px 24px rgba(0,0,0,0.03);
□ Colored shadows: box-shadow: 0 8px 32px rgba(primary, 0.25);

🌈 GRADIENTS:
□ Background gradient (subtle, 2-3 stops)
□ Text gradient cho headlines (CSS background-clip)
□ Border gradient (nổi bật CTA)
□ Hover gradient shift

🔮 GLASSMORPHISM:
□ backdrop-filter: blur(16px) saturate(180%)
□ Background: rgba(255,255,255,0.08)
□ Border: 1px rgba(255,255,255,0.12)

📐 SPACING (8pt Grid):
□ Mọi spacing = bội số 8: 8, 16, 24, 32, 48, 64, 96
□ Internal padding ≤ External margin

🔤 TYPOGRAPHY:
□ Google Fonts premium (Inter, Outfit, Plus Jakarta Sans)
□ Weight: 700 (H1) → 600 (H2) → 400 (body)
□ Line-height: 1.2 (H1) → 1.4 (H2) → 1.6 (body)
□ Letter-spacing: -0.02em (headlines), 0 (body), 0.05em (labels)

🎭 MICRO-DETAILS:
□ Border-radius nhất quán (4/8/12/16/9999)
□ Icon set thống nhất (Lucide / Phosphor / Heroicons)
□ Custom scrollbar (dark theme)
□ ::selection color match brand
□ Focus ring: 2px offset, primary color, rounded
```
