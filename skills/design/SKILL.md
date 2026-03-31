---
name: design
description: When building UI — create or update the project's design system (DESIGN.md), audit 7 interaction states, detect AI slop, check accessibility and responsive behavior. Activates only for frontend/UI tasks.
---

# Design — Visual Design System & Audit

**Build and maintain the project's visual design system before any UI code is written.**

## When to Use

- New frontend feature or page
- Significant UI changes
- When no DESIGN.md exists and UI work is requested
- When the architect's plan includes frontend components
- User says "design this" or "how should this look"

## What It Does

1. **Design System**: Creates/updates DESIGN.md with typography, colors, spacing, layout, components, motion
2. **7-State Audit**: Ensures every UI element handles empty, loading, error, success, partial, overflow, stale
3. **AI Slop Detection**: Scores against 10 anti-patterns (A-F scale)
4. **Accessibility**: WCAG AA contrast, 44px touch targets, keyboard nav, focus indicators
5. **Responsive**: Mobile/tablet/desktop breakpoint coverage

## How /design differs from /design-review

- **/design** = Create or update the full design system (DESIGN.md). Holistic: typography, colors, spacing, components, motion. Used when building a new UI or establishing visual identity.
- **/design-review** = Lightweight audit gate. Checks 7 states + accessibility + AI slop on specific components. Used before planning to ensure completeness.

The orchestrator's **designer agent** runs /design when DESIGN.md doesn't exist, and /design-review when it does.

## Integration

- Runs after Architect (plan) and before Builder
- Output constrains what Builder implements
- Uses the Designer agent when invoked via /orchestrate
- Can be run standalone for design audits on existing UI

## DESIGN.md Location

Always `docs/DESIGN.md` in the project root. If `docs/` doesn't exist, create it. This is the canonical location — never project root, never nested deeper.

## Output

Produces a structured design specification that the Builder must follow. The Builder receives this as constraints, not suggestions.
