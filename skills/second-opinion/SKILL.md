---
name: second-opinion
description: Get an independent second opinion from a different AI model on code, architecture, or review findings. Cross-model analysis highlights unique findings each model catches.
---

# Second Opinion — Cross-Model Validation

**When a review or decision needs independent validation, get a second opinion from a different model.**

## When to Use

- After `/review` flags disputed findings
- Before merging complex architectural changes
- When the architect's plan feels uncertain
- When two approaches seem equally valid
- When user explicitly requests a second take

## How It Works

1. **Collect context**: Gather the diff, findings, or decision being validated
2. **Spawn second opinion**: Use the Agent tool with a different model:
   - If primary review used Sonnet → spawn with `model: "opus"` or `model: "haiku"`
   - If primary review used Opus → spawn with `model: "sonnet"`
   - The second agent receives ONLY the raw material (diff, code, requirements) — never the first reviewer's findings
3. **Cross-model analysis**: Compare findings from both models:
   - **Overlap**: Findings both models flagged → high confidence, likely real issues
   - **Unique to Model A**: Check if Model B missed it or if it's a false positive
   - **Unique to Model B**: Fresh perspective — the whole point of cross-model review
   - **Contradictions**: When models disagree, present both positions to the user
4. **Report**: Structured output showing agreement, unique findings, and contradictions

## Prompt Template for Second Opinion Agent

```
You are an independent code reviewer. You have NOT seen any prior review of this code.
Review the following diff for:
- Correctness (bugs, logic errors, edge cases)
- Security (injection, auth bypass, data exposure)
- Performance (N+1 queries, unnecessary allocations, blocking calls)
- Maintainability (complexity, naming, structure)

Rate each finding: CRITICAL / HIGH / MEDIUM / LOW
For each finding, state your confidence: 1-10

[DIFF OR CODE HERE]
```

## Rules

- The second opinion agent MUST NOT see the first reviewer's findings — this is a blind review
- Present cross-model analysis to the user, don't auto-resolve disagreements
- Use for high-stakes decisions, not routine changes
- If both models agree on a CRITICAL finding, treat it as confirmed — no tiebreaker needed
- If models contradict on severity, escalate to user with both arguments

## Integration with /review (automatic offer)

After `/review` completes, `/second-opinion` is **automatically offered** (not auto-invoked) when:
1. Any CRITICAL/HIGH findings exist AND the builder disputes them
2. The tiebreaker protocol returns an inconclusive ruling
3. Both models (auditor + adversarial QA) disagree on severity of the same finding

The second opinion provides a completely independent review rather than arbitrating a specific finding.

**Hard gate:** If both the original reviewer AND the second-opinion model agree on a CRITICAL finding, it is **confirmed with no appeal**. The builder must fix it.
