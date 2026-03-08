# Reference: Design System Architecture

## 3-Tier Token System

```
┌─────────────────────────────────────────────────────────┐
│ TIER 1: REFERENCE TOKENS (Giá trị gốc)                  │
│ Colors:  blue-500: #6366f1, green-500: #10b981, ...      │
│ Spacing: space-2: 8px, space-4: 16px, ...                │
│ Fonts:   font-sans: 'Inter', sans-serif                  │
│ Radii:   radius-sm: 4px, radius-md: 8px, ...             │
├─────────────────────────────────────────────────────────┤
│ TIER 2: SEMANTIC TOKENS (Ý nghĩa)                       │
│ color-primary:     → blue-500                            │
│ color-surface:     → gray-900 (dark) / white (light)     │
│ spacing-component: → space-4 (16px)                      │
│ spacing-section:   → space-8 (32px)                      │
├─────────────────────────────────────────────────────────┤
│ TIER 3: COMPONENT TOKENS (Cụ thể)                       │
│ button-bg:     → color-primary                           │
│ button-radius: → radius-md                               │
│ card-bg:       → color-surface                           │
│ card-padding:  → spacing-component                       │
└─────────────────────────────────────────────────────────┘
```

## Design Specs File Template (`docs/design-specs.md`)

```markdown
# 🎨 Design System: [Tên Dự Án]

## 1. Color Palette
[Bảng màu đầy đủ + dark/light mode]

## 2. Typography
| Element | Font  | Size         | Weight | Line Height | Letter Spacing |
|---------|-------|-------------|--------|-------------|----------------|
| H1      | Inter | 48px/3rem   | 700    | 1.2         | -0.02em        |
| H2      | Inter | 36px/2.25rem| 600    | 1.3         | -0.01em        |
| H3      | Inter | 24px/1.5rem | 600    | 1.4         | 0              |
| Body    | Inter | 16px/1rem   | 400    | 1.6         | 0              |
| Small   | Inter | 14px/0.875re| 400    | 1.5         | 0.01em         |
| Caption | Inter | 12px/0.75rem| 500    | 1.4         | 0.03em         |

## 3. Spacing (8pt Grid)
| Token | Value | Usage |
|-------|-------|-------|
| xs    | 4px   | Icon gaps |
| sm    | 8px   | Tight spacing |
| md    | 16px  | Default padding |
| lg    | 24px  | Section padding |
| xl    | 32px  | Between sections |
| 2xl   | 48px  | Major gaps |
| 3xl   | 64px  | Page-level |

## 4. Shadows (Layered)
| Level  | Value | Usage |
|--------|-------|-------|
| subtle | 0 1px 2px rgba(0,0,0,0.04) | Borders |
| sm     | 0 1px 3px + 0 4px 8px     | Buttons |
| md     | 0 4px 6px + 0 12px 24px   | Cards |
| lg     | 0 8px 16px + 0 24px 48px  | Modals |

## 5. Border Radius
| Token | Value  | Usage |
|-------|--------|-------|
| sm    | 4px    | Inputs |
| md    | 8px    | Cards, buttons |
| lg    | 12px   | Modals |
| xl    | 16px   | Floating panels |
| full  | 9999px | Pills, avatars |

## 6. Breakpoints
| Name    | Width      | Layout |
|---------|-----------|--------|
| mobile  | < 640px   | Stack, bottom nav |
| tablet  | 640-1024px| 2-col |
| desktop | > 1024px  | Full layout |

## 7. Animations
| Name    | Duration | Easing | Usage |
|---------|----------|--------|-------|
| instant | 100ms    | ease-out | Hover |
| fast    | 200ms    | ease-out | Clicks |
| normal  | 300ms    | ease-in-out | Modals |
| slow    | 500ms    | ease-in-out | Pages |
| spring  | 400ms    | cubic-bezier(0.34,1.56,0.64,1) | Playful |
```
