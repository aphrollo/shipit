---
name: design-review
description: When building or changing UI elements — audit all 7 interaction states (empty, loading, error, success, partial, overflow, stale), accessibility, and responsive behavior before writing frontend code.
---

# Design Review

**Lightweight audit gate — NOT full design system creation. For full design system, use /design.**

**Gate: All 7 states accounted for.**

## 7-State Audit

For every UI element being added or changed:

| State | What to design |
|-------|---------------|
| **Empty** | No data — what does the user see? |
| **Loading** | Fetching — spinner, skeleton, or placeholder? |
| **Error** | Failed — what message? Can user retry? |
| **Success** | Happy path |
| **Partial** | Some data loaded, some failed — graceful degradation? |
| **Overflow** | Too much data — pagination, virtualization, truncation? |
| **Stale** | Outdated — timestamp, refresh indicator, auto-reload? |

## Checklist

- [ ] Keyboard navigation (Tab, Enter, Escape, arrows)
- [ ] No layout shift on data arrival (reserve space)
- [ ] Contrast passes WCAG AA (4.5:1 text, 3:1 large text)
- [ ] Touch targets 44x44px minimum

## Mandatory Output (gate — all 7 rows required before proceeding)

```
EMPTY: [how handled]
LOADING: [how handled]
ERROR: [how handled]
SUCCESS: [how handled]
PARTIAL: [how handled]
OVERFLOW: [how handled]
STALE: [how handled]
```

Incomplete rows = gate not cleared.

## AI Slop Detection

Score the design against these 10 blacklisted anti-patterns commonly produced by AI. Each violation deducts from the AI Slop Score (A = clean, F = heavy slop):

| # | Anti-Pattern | What to look for |
|---|-------------|-----------------|
| 1 | Gradient hero backgrounds | Linear gradients as primary visual element instead of real content |
| 2 | 3-column feature grids | Three equal cards with icon + heading + paragraph (the "SaaS starter kit" layout) |
| 3 | Centered card layouts | Everything centered with generous whitespace but no visual hierarchy |
| 4 | Emoji as decoration | Emoji used as section icons or bullet replacements |
| 5 | Generic stock copy | "Streamline your workflow", "Built for teams", "Get started today" |
| 6 | Pill-shaped buttons everywhere | Rounded buttons with gradient fills as the only CTA style |
| 7 | Fake testimonials | Placeholder testimonials with stock headshots or avatar initials |
| 8 | Floating cards with shadows | Multiple cards with identical box-shadows floating on light gray backgrounds |
| 9 | Animated counters | "10,000+ users", "99.9% uptime" with scroll-triggered number animations |
| 10 | Dark mode as personality | Dark background used as a substitute for actual visual identity |

**Scoring:**
- 0 violations = A (clean design)
- 1-2 violations = B (minor slop, flag it)
- 3-4 violations = C (needs design attention)
- 5-6 violations = D (significant AI slop)
- 7+ violations = F (redesign needed)

**Report AI Slop Score alongside the design review.** If score is C or below, recommend specific alternatives for each violation.

## DESIGN.md Location

Always `docs/DESIGN.md`. If auditing against an existing design system, look there first. If creating a new one, write to `docs/DESIGN.md`.

## Next → /plan
