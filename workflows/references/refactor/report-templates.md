# Reference: Refactor Report & Measurement Templates

## Before/After Comparison Table

```
┌──────────────────────┬──────────┬──────────┬──────────┬──────────┐
│ Metric               │ Before   │ After    │ Change   │ Target   │
├──────────────────────┼──────────┼──────────┼──────────┼──────────┤
│ 🏥 Health Score      │ [?]/100  │ [?]/100  │ +[?]     │ ≥80      │
│ 💀 SQALE Rating      │ [?]      │ [?]      │ [↑↓]     │ A        │
│ 💀 Technical Debt    │ [?]h     │ [?]h     │ -[?]h    │ ↓        │
├──────────────────────┼──────────┼──────────┼──────────┼──────────┤
│ 🧠 Cognitive (avg)   │ [?]      │ [?]      │ -[?]%    │ ≤8       │
│ 🧠 Cognitive (max)   │ [?]      │ [?]      │ -[?]%    │ ≤15      │
│ 🔄 Cyclomatic (avg)  │ [?]      │ [?]      │ -[?]%    │ ≤10      │
│ 🔄 Cyclomatic (max)  │ [?]      │ [?]      │ -[?]%    │ ≤15      │
├──────────────────────┼──────────┼──────────┼──────────┼──────────┤
│ 📏 Lines/fn (avg)    │ [?]      │ [?]      │ -[?]%    │ ≤30      │
│ 📏 Lines/fn (max)    │ [?]      │ [?]      │ -[?]%    │ ≤50      │
│ 📁 Lines/file (max)  │ [?]      │ [?]      │ -[?]%    │ ≤500     │
├──────────────────────┼──────────┼──────────┼──────────┼──────────┤
│ 🐟 Code smells       │ [?]      │ [?]      │ -[?]     │ ↓        │
│ 🗑️ Dead code lines   │ [?]      │ [?]      │ -[?]     │ 0        │
│ 📋 Duplication %     │ [?]%     │ [?]%     │ -[?]%    │ ≤3%      │
├──────────────────────┼──────────┼──────────┼──────────┼──────────┤
│ 🏗️ SOLID Score       │ [?]/50   │ [?]/50   │ +[?]     │ ≥40      │
│ 🕸️ Circular deps     │ [?]      │ [?]      │ -[?]     │ 0        │
│ ⚡ Performance       │ [?]ms    │ [?]ms    │ [≤]      │ ≤baseline│
│ 🧪 Tests pass        │ [?]/[?]  │ [?]/[?]  │ [=]      │ 100%     │
└──────────────────────┴──────────┴──────────┴──────────┴──────────┘

🏆 IMPROVEMENT SCORE: [?]% average improvement
```

## Impact Report Template

```markdown
# 🔪 REFACTOR REPORT: [Project Name]

📅 Ngày: [Date]
⚙️ Engine: BWF Code Surgeon v3.0
🎯 Scope: [Quick/Deep/Full/Architectural]

## Executive Summary
- 🏥 Health Score: [Before] → [After] (+[?])
- 💀 Technical Debt: [Before]h → [After]h (-[?]h)
- ⚡ Performance: [Before]ms → [After]ms (≤ baseline ✅)
- 🐟 Code Smells Fixed: [?]
- 📁 Files Modified: [?]
- ⏱️ Total Time: [?] phút

## Code Health X-Ray (Before/After)
[Bảng comparison ở trên]

## Code Smells Resolved
[Danh sách smells đã fix]

## SOLID Improvements
[Score card before/after]

## Refactoring Techniques Used
[Danh sách Fowler patterns đã áp dụng]

## Verification
- Tests: [?]/[?] pass (100%)
- Lint: [?] errors (≤ baseline)
- Performance: [?]ms (≤ baseline ✅)
- Logic: ✅ Unchanged

## Recommendations
[Những gì chưa refactor + lý do]
```

## Session Journal (Auto-save)

```json
{
  "refactors": [{
    "scope": "[Quick/Deep/Full/Architectural]",
    "health_score_before": 0,
    "health_score_after": 0,
    "performance_before_ms": 0,
    "performance_after_ms": 0,
    "debt_reduced_hours": 0,
    "smells_fixed": 0,
    "files_modified": [],
    "techniques_used": [],
    "timestamp": ""
  }]
}
```
