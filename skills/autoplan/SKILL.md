---
name: autoplan
description: One-command fully reviewed plan — runs reframe, design-review (if UI), and plan sequentially with auto-decisions. Surfaces only premise challenges and taste decisions to the user.
---

# Autoplan — Automated Planning Pipeline

**One command to go from request to reviewed, approved plan. Auto-decides everything except what requires human judgment.**

## When to Use

- Starting a new feature and want to skip the back-and-forth
- User says "just plan it" or "autoplan this"
- When the request is clear enough to not need interactive reframing

## Pipeline

### Step 1: Reframe (10-30s)

Run `/reframe` logic inline:
- Challenge the premise: Is this the right problem to solve?
- Define success criteria
- Identify scope boundaries (in/out)

**Auto-decide**: Accept the reframe if it doesn't change the fundamental premise.
**Ask user**: If the reframe suggests a significantly different approach than requested.

### Step 2: Design Review (if UI detected, 10-30s)

Run `/design-review` logic inline — only if the change touches frontend/UI:
- Audit all 7 interaction states
- Check accessibility
- Check responsive behavior

**Auto-decide**: Standard UI patterns (forms, lists, modals).
**Ask user**: Novel interactions, animations, unconventional layouts.

**Skip entirely**: For backend-only, infrastructure, config, or CLI changes.

### Step 3: Plan (30-60s)

Run `/plan` logic inline:
- List files to change
- Define test cases
- Set order of operations
- Assess risks

**Auto-decide**: Standard implementation order, obvious test cases.
**Ask user**: Risk assessment items, alternative approaches with trade-offs.

### Step 4: Present

Output the complete plan for user approval:

```
AUTOPLAN COMPLETE

REFRAME:
  Problem: [one-line]
  Success: [criteria]
  Scope: [in/out]

DESIGN: [if applicable]
  States covered: [7/7 or N/A]
  Accessibility: [pass/flags]

PLAN:
  Files: [list]
  Tests: [list]
  Order: [sequence]
  Risks: [if any]

DECISIONS MADE:
  - [what was auto-decided and why]

NEEDS YOUR INPUT:
  - [questions that require human judgment, if any]
```

**Gate**: User must approve before `/build` begins. Autoplan accelerates planning, it doesn't skip the approval gate.

## Rules

- Autoplan is speed, not shortcuts — every phase still runs, just with less back-and-forth
- If ANY step raises a concern that could change the approach, stop and ask
- Never auto-decide on: security implications, data model changes, breaking API changes, or anything affecting other teams
- The output is a complete plan ready for `/build` — not a summary or sketch
- If the request is too vague for autoplan, fall back to interactive `/reframe`
