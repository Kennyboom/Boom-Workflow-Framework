---
name: mobile-ui-ux
description: Design exceptional mobile experiences following Material Design 3 and Apple Human Interface Guidelines. Covers navigation patterns, gestures, accessibility, responsive layouts, dark mode, animations, and onboarding flows.
---

# Mobile UI/UX Expert

Expert guidance for designing intuitive, accessible, and beautiful mobile interfaces across Android and iOS.

## When to Use

- Designing mobile app interfaces
- Choosing navigation patterns
- Implementing accessibility (a11y)
- Responsive layouts (phone, tablet, foldable)
- Dark mode and theming
- Onboarding and user flows

---

## 1. Platform Design Systems

### Material Design 3 (Android) vs Human Interface Guidelines (iOS)

| Aspect | Material 3 (Android) | HIG (iOS) |
|--------|----------------------|------------|
| **Navigation** | Bottom nav (3-5 items), Nav drawer, Nav rail | Tab bar (max 5), Sidebar (iPad) |
| **Actions** | FAB (Floating Action Button) | Toolbar buttons, pull-down menus |
| **Colors** | Dynamic color from wallpaper | System colors adapt to light/dark |
| **Typography** | Roboto, display/headline/body/label | SF Pro, large/standard title |
| **Elevation** | Tonal elevation (color shift) | Translucent materials, blur |
| **Sheets** | Bottom sheet (standard/modal) | Sheet presentation (.sheet) |
| **Alerts** | Dialogs centered | Alerts anchored to bottom |
| **Haptics** | Limited vibration API | Rich haptic engine (UIFeedbackGenerator) |
| **Gestures** | Predictive back gesture | Swipe-back, edge gestures |

### When to Follow Platform vs Cross-Platform
- **Follow platform**: Navigation patterns, system controls, gestures
- **Unify**: Brand colors, icons, content layout, business logic
- **Test on both**: Always verify feel on both platforms

## 2. Navigation Patterns

### Tab Bar / Bottom Navigation
```
Best for: 3-5 top-level destinations
Rules:
- Always visible at bottom
- Show labels + icons (no icon-only)
- Highlight active tab clearly
- Persist scroll position when switching tabs
- Never nest tab bars
```

### Drawer / Sidebar
```
Best for: 5+ destinations, settings, account
Rules:
- Use hamburger menu sparingly (low discoverability)
- iPad: permanent sidebar (SplitView)
- Android: Navigation drawer
- Always show current section highlighted
```

### Bottom Sheet
```
Best for: Contextual actions, filters, details
Rules:
- Partial height by default (peek)
- Draggable to full height
- Dismiss via drag down or tap outside
- Keep critical actions above fold
```

### Stack Navigation
```
Best for: Hierarchical content (list → detail)
Rules:
- Show back button (< or ←)
- iOS: swipe-from-left-edge to go back
- Android: predictive back animation
- Keep navigation bar title visible
```

## 3. Gestures

| Gesture | Usage | Platform Notes |
|---------|-------|----------------|
| **Tap** | Primary action | Both: 44pt min touch target |
| **Long press** | Context menu | iOS: peek/pop, Android: tooltip |
| **Swipe horizontal** | Delete, actions on list items | iOS: native swipe actions |
| **Swipe down** | Pull-to-refresh, dismiss modal | Both: standard pattern |
| **Pinch** | Zoom images/maps | Both: use standard gesture recognizers |
| **Double tap** | Zoom in, like (social) | Keep consistent within app |
| **Drag** | Reorder lists, move items | Use drag handles for discoverability |

### Touch Target Guidelines
```
Minimum touch target: 44×44 pt (iOS) / 48×48 dp (Android)
Spacing between targets: ≥8pt
Thumb zone: Bottom 1/3 of screen is easiest to reach
- Place primary actions in bottom area
- Place destructive actions away from common tap zones
```

## 4. Accessibility (a11y)

### WCAG Mobile Checklist
- [ ] **Contrast ratio**: ≥4.5:1 for normal text, ≥3:1 for large text
- [ ] **Touch targets**: ≥44pt / 48dp
- [ ] **Labels**: All interactive elements have accessibility labels
- [ ] **Roles**: Buttons, links, headings properly annotated
- [ ] **Screen reader**: Test with VoiceOver (iOS) / TalkBack (Android)
- [ ] **Dynamic type**: Support system font scaling (up to 200%)
- [ ] **Reduce motion**: Respect `prefers-reduced-motion`
- [ ] **Color independence**: Never use color alone to convey meaning
- [ ] **Focus order**: Logical tab/swipe order
- [ ] **Live regions**: Announce dynamic content changes

### Dynamic Type Support
```
iOS: Use system text styles (.title, .body, .caption)
     or custom fonts with UIFontMetrics

Android: Use sp units for text sizes
         Support fontScale in configuration

Cross-platform: Define text scale multipliers
  Small:   0.85x
  Default: 1.0x
  Large:   1.15x
  XL:      1.30x
  XXL:     1.50x
```

## 5. Responsive Design

### Breakpoints
```
Phone portrait:   320-428 pt
Phone landscape:  568-926 pt
Tablet portrait:  744-834 pt
Tablet landscape: 1024-1194 pt
Foldable open:    882+ pt (inner display)
```

### Layout Strategies
```
Phone:            Single column, full-width cards
Tablet portrait:  2-column grid, master-detail
Tablet landscape: Sidebar + content, 3-column
Foldable (folded): Phone layout
Foldable (open):   Dual-pane, table-top mode support
```

### Safe Areas
```
Always respect safe area insets:
- Top: Status bar + notch/Dynamic Island
- Bottom: Home indicator (iOS) / navigation bar (Android)
- Sides: Rounded corners on modern devices

Never place interactive content:
- Behind system bars
- In rounded corner danger zones (16pt from corners)
- Under the Dynamic Island
```

## 6. Dark Mode

### Implementation Strategy
```
1. Use semantic color tokens, never hardcoded colors:
   ✅ surface, onSurface, primary, onPrimary
   ❌ #FFFFFF, #000000, #FF5722

2. Elevation in dark mode:
   - Light mode: shadow/elevation
   - Dark mode: lighter surface tint (Material 3)

3. Image handling:
   - Reduce image brightness/saturation in dark mode
   - Provide dark mode variants for logos
   - Use transparency-aware illustrations

4. Testing:
   - Toggle dark mode in device settings
   - Check all screens, empty states, error states
   - Verify contrast ratios in both modes
```

### Color Token System
```
Background:     light: #FFFFFF   dark: #121212
Surface:        light: #F5F5F5   dark: #1E1E1E
Surface High:   light: #EBEBEB   dark: #2C2C2C
Primary:        light: #6750A4   dark: #D0BCFF
On Primary:     light: #FFFFFF   dark: #381E72
On Surface:     light: #1C1B1F   dark: #E6E1E5
Error:          light: #B3261E   dark: #F2B8B5
```

## 7. Animation Principles

### Performance Targets
```
Frame rate:  60 fps minimum (ProMotion: 120 fps)
Duration:    150-300ms for micro-interactions
             300-500ms for page transitions
Easing:      ease-out for entrances
             ease-in for exits
             ease-in-out for state changes
```

### Meaningful Motion
```
Hierarchy:   Shared element transitions (list → detail)
Feedback:    Button press scale (0.95), haptic feedback
Continuity:  Hero animations linking related screens
Direction:   Push right = forward, slide left = back
Loading:     Skeleton screens > spinners > progress bars
Emphasis:    Subtle pulse or glow for new/important items
```

### What NOT to Animate
```
❌ Loading spinners that block interaction
❌ Bouncing/jiggling elements (annoying)
❌ Auto-playing video without user consent
❌ Parallax effects that cause motion sickness
❌ Animations >500ms for routine actions
```

## 8. Onboarding Patterns

### Progressive Disclosure
```
1. Show only essential features first
2. Reveal advanced features as user engages
3. Use contextual tooltips on first encounter
4. Save tutorials for complex interactions only
```

### Permission Requests
```
Best practices:
- Explain WHY before showing system dialog
- Pre-permission screen with benefits
- Allow "Ask Later" option
- Graceful degradation if denied

Order: Request when needed, not all at once
  1. First: Camera (when user taps photo button)
  2. Later: Notifications (after value is demonstrated)
  3. Never: Contacts (unless core feature)
```

## 9. Common Anti-Patterns

| Anti-Pattern | Fix |
|-------------|-----|
| Splash screen >2s | Use system launch screen, load data async |
| Hamburger menu for primary nav | Use bottom tabs / tab bar |
| Carousel for important content | Use scrollable list |
| Pull-to-refresh with no indicator | Show loading state immediately |
| Modal on top of modal | Redesign flow, use navigation |
| Custom gestures without tutorial | Use standard platform gestures |
| Text-only buttons | Add icons + descriptive labels |
| Infinite scroll without position save | Save scroll position on tab switch |

## 10. Design Checklist

- [ ] Works in portrait AND landscape
- [ ] Supports dark mode
- [ ] Passes WCAG AA contrast checks
- [ ] Touch targets ≥44pt/48dp
- [ ] Error states designed (not just happy path)
- [ ] Empty states with helpful messaging
- [ ] Loading states (skeleton screens)
- [ ] Offline state handling
- [ ] Tested with VoiceOver/TalkBack
- [ ] Tested with Dynamic Type/Font Scale
- [ ] Animations respect Reduce Motion
- [ ] Follows platform conventions (Material/HIG)
