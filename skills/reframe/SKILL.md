---
name: reframe
description: When starting a new feature or significant change — challenge assumptions, explore alternatives, define success criteria before any planning or coding.
---

# Reframe

**Gate: User confirms problem statement and scope. Do NOT auto-approve. Do NOT proceed without explicit confirmation.**

## Process

1. **What user problem does this solve?** (one sentence)
2. **What happens if we don't build this?** (urgency)
3. **What's the simplest thing that could work?** (minimum viable)
4. **What could go wrong?** (risks)

## Output

```
PROBLEM: [one sentence]
APPROACH: [chosen path]
SCOPE: [what's in / what's out]
```

### Spec persistence

After the user approves the reframed problem statement and scope, write the spec to:
```
docs/specs/YYYY-MM-DD-<topic>-design.md
```

Create the directory if it doesn't exist. The spec document should include:
- Problem statement (as approved)
- Scope (in/out)
- Approach chosen (with trade-offs noted)
- Success criteria
- Open questions (if any)

This creates an audit trail and lets future sessions reference past design decisions.

Do NOT write code. Do NOT explore files. Just think.

## Next

- Has UI → /design-review
- Backend only → /plan
