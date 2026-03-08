# Reference: Code Health Metrics Engine

## Complexity Metrics (BẮT BUỘC)

```
📊 COMPLEXITY X-RAY:
┌──────────────────────────┬──────────┬──────────┬──────────┐
│ Metric                   │ Hiện tại │ Target   │ Status   │
├──────────────────────────┼──────────┼──────────┼──────────┤
│ Cyclomatic Complexity    │          │          │          │
│  (Avg per function)      │ [?]      │ ≤ 10     │ [🟢🟡🔴] │
│  (Max function)          │ [?]      │ ≤ 15     │ [🟢🟡🔴] │
├──────────────────────────┼──────────┼──────────┼──────────┤
│ Cognitive Complexity     │          │          │          │
│  (Avg per function)      │ [?]      │ ≤ 8      │ [🟢🟡🔴] │
│  (Max function)          │ [?]      │ ≤ 15     │ [🟢🟡🔴] │
├──────────────────────────┼──────────┼──────────┼──────────┤
│ Lines per Function       │          │          │          │
│  (Avg)                   │ [?]      │ ≤ 30     │ [🟢🟡🔴] │
│  (Max)                   │ [?]      │ ≤ 50     │ [🟢🟡🔴] │
├──────────────────────────┼──────────┼──────────┼──────────┤
│ Lines per File           │          │          │          │
│  (Avg)                   │ [?]      │ ≤ 300    │ [🟢🟡🔴] │
│  (Max)                   │ [?]      │ ≤ 500    │ [🟢🟡🔴] │
├──────────────────────────┼──────────┼──────────┼──────────┤
│ Nesting Depth (Max)      │ [?]      │ ≤ 3      │ [🟢🟡🔴] │
├──────────────────────────┼──────────┼──────────┼──────────┤
│ Parameters per Function  │ [?]      │ ≤ 4      │ [🟢🟡🔴] │
└──────────────────────────┴──────────┴──────────┴──────────┘

Thresholds: 🟢 Trong target | 🟡 Vượt 1-50% | 🔴 Vượt >50%
```

## Code Health Score (0-100)

```
🏥 CODE HEALTH SCORE: [XX]/100

│ Dimension          │ Weight │ Score  │ Weighted │
│ Complexity         │ 25%    │ [?]/10 │ [?]/25   │
│ Duplication        │ 15%    │ [?]/10 │ [?]/15   │
│ Naming & Reading   │ 15%    │ [?]/10 │ [?]/15   │
│ SOLID Compliance   │ 15%    │ [?]/10 │ [?]/15   │
│ Coupling/Cohesion  │ 15%    │ [?]/10 │ [?]/15   │
│ Dead Code          │ 10%    │ [?]/10 │ [?]/10   │
│ Error Handling     │ 5%     │ [?]/10 │ [?]/5    │
│ TOTAL              │ 100%   │        │ [XX]/100 │

Rating: 80-100: 🟢 A | 60-79: 🟡 B | 40-59: 🟠 C | 20-39: 🔴 D | 0-19: 💀 E
```

## Technical Debt (SQALE Model)

```
💀 TECHNICAL DEBT DASHBOARD

┌──────────────────────┬───────────────────────────────────┐
│ Total Debt           │ [?] giờ remediation              │
│ Debt Ratio           │ [?]% (debt / development cost)    │
│ SQALE Rating         │ [A/B/C/D/E]                       │
├──────────────────────┴───────────────────────────────────┤
│ DEBT BREAKDOWN BY CATEGORY:                              │
│ ┌──────────────────┬──────────┬──────────┬─────────────┐ │
│ │ Category         │ Issues   │ Debt(h)  │ Priority    │ │
│ ├──────────────────┼──────────┼──────────┼─────────────┤ │
│ │ 🏗️ Architecture  │ [?]      │ [?]h     │ [🔴🟡🟢]    │ │
│ │ 🔧 Design        │ [?]      │ [?]h     │ [🔴🟡🟢]    │ │
│ │ 📝 Code Quality  │ [?]      │ [?]h     │ [🔴🟡🟢]    │ │
│ │ 🧪 Testability   │ [?]      │ [?]h     │ [🔴🟡🟢]    │ │
│ │ 📖 Readability   │ [?]      │ [?]h     │ [🔴🟡🟢]    │ │
│ │ 🗑️ Dead Code     │ [?]      │ [?]h     │ [🔴🟡🟢]    │ │
│ │ 📦 Dependencies  │ [?]      │ [?]h     │ [🔴🟡🟢]    │ │
│ └──────────────────┴──────────┴──────────┴─────────────┘ │
│                                                          │
│ SQALE THRESHOLDS: A: ≤5% | B: ≤10% | C: ≤20% | D: ≤50% | E: >50% │
└──────────────────────────────────────────────────────────┘

⏱️ ROI CALCULATOR:
• Debt hiện tại: [?] giờ
• Chi phí nếu KHÔNG sửa: [?] giờ mất thêm mỗi tháng (interest)
• Chi phí nếu SỬA ngay: [?] giờ
• ROI: Hoàn vốn sau [?] tháng
```
