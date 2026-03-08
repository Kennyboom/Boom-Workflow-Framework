# Reference: Test Strategies (Pyramid + Boundary + Generation)

## Test Pyramid

```
       /\
      /  \     E2E Tests (10%)
     /    \    Login flow, Checkout, Critical paths
    /──────\
   /        \  Integration Tests (20%)
  /          \ API + DB, Component interactions
 /────────────\
/              \ Unit Tests (70%)
/________________\ Functions, Utils, Hooks, Services

GAP ANALYSIS:
│ Layer        │ Current │ Target │ Gap  │
│ Unit         │ [X]     │ [Y]    │ [Z]  │
│ Integration  │ [X]     │ [Y]    │ [Z]  │
│ E2E          │ [X]     │ [Y]    │ [Z]  │
│ Coverage     │ [X]%    │ 80%    │ [Z]% │
```

## Auto-Generate Test Cases

```
Cho function calculateTotal(items, discount):
✅ Happy: items=[{price:100}], discount=10 → 90
❌ Edge: items=[], discount=0 → 0
❌ Error: items=null → throw Error
🔒 Auth: Without token → 401
⚡ Perf: 1000 items → < 100ms
```

## Boundary Value Analysis

```
│ Boundary             │ Value     │ Expected  │
│ Minimum              │ 1         │ ✅ Accept  │
│ Just below minimum   │ 0         │ ❌ Reject  │
│ Just above minimum   │ 2         │ ✅ Accept  │
│ Maximum              │ 100       │ ✅ Accept  │
│ Just above maximum   │ 101       │ ❌ Reject  │
│ Way above            │ 999       │ ❌ Reject  │
│ Negative             │ -100      │ ❌ Reject  │
│ Zero                 │ 0         │ ✅ Accept  │
│ Float                │ 25.5      │ ❌ Reject? │
│ String               │ 'abc'     │ ❌ Reject  │
│ Empty                │ ''        │ ❌ Reject  │
│ Null                 │ null      │ ❌ Reject  │
│ Undefined            │ undefined │ ❌ Reject  │
```
