---
name: design-review
description: When building or changing UI elements — audit all 7 interaction states (empty, loading, error, success, partial, overflow, stale), accessibility, and responsive behavior before writing frontend code.
---

# Design Review

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

## Next → /plan
