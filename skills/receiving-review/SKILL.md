---
name: receiving-review
description: Evaluate and respond to code review feedback with technical rigor. No performative agreement. Verify every finding against codebase reality before acting.
---

# Receiving Review

**Purpose:** Technical evaluation of review findings — not performative agreement. Evaluate each finding on its merit.

## Response Protocol

Follow this sequence for every piece of feedback:

1. **READ** the finding completely
2. **UNDERSTAND** what the reviewer is claiming
3. **VERIFY** the claim against actual codebase state (grep, read files, run tests)
4. **EVALUATE** whether the suggestion improves the code
5. **RESPOND** with your technical assessment
6. **IMPLEMENT** only after verification confirms the finding is valid

## Forbidden Responses

These phrases indicate performative agreement, not technical evaluation. Never use them:

- "You're absolutely right!"
- "Great point!"
- "Great catch!"
- "Let me implement that right away"
- Any gratitude expression toward the reviewer
- Implementing suggestions without verifying them first

If a finding is valid, state that it is valid and why. Skip the theater.

## Evaluation Rules

**Verify before implementing.** Grep for actual usage, check if the pattern exists elsewhere, read surrounding code. Reviewers work from diffs, not full context — they can be wrong.

**Push back when the reviewer is wrong.** Reviewers produce false positives. If verification shows the finding is incorrect, say so with evidence.

**YAGNI check.** Before implementing "professional" suggestions (add logging, add metrics, add abstraction layers, add error wrapping), grep the codebase for actual usage patterns. If nobody else does it in this codebase, don't add it. Match the existing style, not an idealized one.

**Clarify before implementing.** If any finding is ambiguous or unclear, ask for clarification on ALL unclear items before implementing ANY of them.

**External feedback = suggestions to evaluate, not orders to follow.**

## Implementation Order

When accepting findings, fix in this order:

1. **CRITICAL:** Fix immediately. Re-run tests after each fix.
2. **HIGH:** Fix before proceeding to other work.
3. **MEDIUM:** Fix in the current session.
4. **LOW/MINOR:** Note for later. Do not block the workflow.

Test each fix individually. Do not batch fixes — a batch that breaks tests makes it impossible to isolate which fix caused the failure.

## When to Dispute

Dispute a finding when:

- The finding is based on an incorrect assumption about the codebase
- The suggestion would break existing behavior
- The "improvement" adds complexity without measurable benefit
- The finding applies to code outside the current diff scope

## How to Dispute

State the technical reason. Cite evidence:

- File and line number (`handler.go:47`)
- Test output showing current behavior is correct
- Grep results showing the pattern is (or is not) used elsewhere
- Git log showing why code is written the way it is

Never dispute based on opinion alone. If you cannot produce evidence, the dispute is not valid.
