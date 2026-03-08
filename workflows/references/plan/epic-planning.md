# Reference: Epic-Level Planning

## Epic Folder Structure

```
📁 plans/[project-name]/
├── epic-01-[module-name]/           ← EPIC (1 module)
│   ├── plan.md                      ← Overview + dependency map
│   ├── feature-01-[name].md         ← Feature (Bulletproof)
│   ├── feature-02-[name].md
│   └── feature-03-[name].md
├── epic-02-[module-name]/
│   ├── plan.md
│   └── feature-01-[name].md
└── integration-matrix.md            ← Cross-epic integration
```

## Epic plan.md Template

```markdown
# Epic: [Module Name]
Status: ⬜ Pending
Dependencies: [Epic nào phải xong trước]

## Module Overview
[Module làm gì trong hệ thống tổng thể]

## Integration Contracts
### Cung cấp:
| Interface | Consumer | Format |
|-----------|----------|--------|
| [API/Event/IPC] | [Module] | [Data format] |

### Phụ thuộc:
| Interface | Provider | Format |
|-----------|----------|--------|
| [API/Event/IPC] | [Module] | [Data format] |

## Features
| # | Feature | Type | Priority | Status |
|---|---------|------|----------|--------|
| 1 | [Name] | [UI/Backend/AI] | [MVP/Phase2] | ⬜ |
```

## integration-matrix.md Template

```markdown
# Integration Matrix

## Module Dependencies
| Module | Depends On | Interface | Status |
|--------|-----------|-----------|--------|
| AI Engine | Ollama | HTTP API :11434 | ⬜ |
| Visual Builder | AI Engine | gRPC :50051 | ⬜ |

## Integration Test Scenarios
- [ ] Module A + Module B: [Test scenario]
- [ ] Module A + Module C: [Test scenario]
```

## Phase-01 Setup (always includes)

```markdown
# Phase 01: Project Setup
- [ ] Create project with framework
- [ ] Install core dependencies
- [ ] Setup TypeScript + ESLint + Prettier
- [ ] Create folder structure
- [ ] Setup Git + initial commit
- [ ] Create .env.example
- [ ] Create .brain/ folder

## Output: Project runs (npm run dev), Clean structure, Git ready
```

⚠️ Phase-01 là nơi DUY NHẤT install. Phases sau KHÔNG install thêm trừ khi cần package mới.
