---
name: interview
description: Before building — clarify requirements through Socratic questioning. Scores ambiguity across 4 dimensions and gates readiness. Use when requirements are vague, incomplete, or assumed.
---

# Interview — Socratic Requirements Clarification

**Don't build on assumptions. Ask until the requirements are clear enough to execute.**

## When to Use

- Requirements are vague ("make it better", "add a dashboard", "fix the UX")
- Multiple valid interpretations exist
- User hasn't specified success criteria
- Before /reframe when the problem itself is unclear
- When /autoplan would have to guess too much

## Process

### 1. Identify Ambiguity

Score the request across 4 dimensions (0-100% ambiguity):

| Dimension | Weight | What to check |
|-----------|--------|--------------|
| Goal | 40% | Is the desired outcome specific and measurable? |
| Constraints | 30% | Are technical, time, and scope boundaries defined? |
| Success criteria | 20% | Can you verify when it's done? |
| Context | 10% | Is the why and who clear? |

**Weighted ambiguity score** = sum of (dimension score x weight)

### 2. Gate Check

- **< 20% ambiguity**: Ready to proceed. Pass to /reframe or /plan.
- **20-50% ambiguity**: Ask 2-3 targeted questions to resolve the highest-weighted gaps.
- **> 50% ambiguity**: Full interview needed. Do not proceed until below 20%.

### 3. Interview Rules

- Ask ONE question at a time. Not a list. Not a wall of text.
- Prefer multiple-choice when possible — faster for the user and reduces ambiguity.
- Never ask questions you can answer by reading the codebase. Check first.
- Don't ask about implementation details — that's the architect's job.
- Focus on WHAT and WHY, not HOW.
- If the user says "you decide" — make the decision, state it, and move on. Don't loop.

### 4. Output

When ambiguity is below 20%:

```
INTERVIEW COMPLETE

AMBIGUITY: [score]% → READY
  Goal: [score]% — [one-line summary]
  Constraints: [score]% — [one-line summary]
  Success criteria: [score]% — [one-line summary]
  Context: [score]% — [one-line summary]

CLARIFIED REQUIREMENTS:
- [requirement 1]
- [requirement 2]
- ...

DECISIONS MADE (by user or by us):
- [decision 1]
- [decision 2]

NEXT: /reframe or /plan
```

## Anti-Patterns

- Don't interview for trivial tasks. "Fix the typo in the header" doesn't need clarification.
- Don't re-ask questions the user already answered in their request.
- Don't ask philosophical questions. "What does success mean to you?" — no. "Should this return a 404 or redirect?" — yes.
- Don't block on style preferences when project conventions already exist. Check the codebase first.
