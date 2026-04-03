---
name: review
description: When /build completes and tests pass — spawn parallel Sonnet subagents for independent code audit and adversarial QA. Includes tiebreaker protocol for disputed CRITICAL/HIGH findings. Never skip.
---

# Review

**Gate: Both subagents return PASS with no CRITICAL/HIGH issues, or all issues are fixed. VERIFIED by showing subagent verdicts.**

## Context Assembly

Send BOTH subagents: full git diff, test files for changed modules, upstream callers (files importing changed code), AND downstream callees (files called by changed code). Both directions of call graph. When in doubt, send more.

**Large diffs (> 500 lines):** Auto-split before review:
1. Run `git diff --stat` to identify changed files and line counts
2. Group files by module/package (same directory = same chunk)
3. If any single file > 500 lines changed, that file is its own chunk
4. Spawn one subagent pair per chunk (parallel when independent)
5. ANY chunk FAIL = overall FAIL

The orchestrator handles splitting. If running inline, the reviewer must split manually using the rules above.

### Subagent skepticism

The spec compliance reviewer MUST verify by reading actual code — not by trusting the builder's report. Builders (like all agents) may claim completion without full implementation. The reviewer must:

1. Read every file listed in the diff
2. Verify claimed changes actually exist in the code
3. Check that test assertions test real behavior, not trivially passing stubs
4. If the builder says "all tests pass", grep for the test file and verify tests exist and are meaningful

**Rule: Do Not Trust the Report.** Verify by reading. Claims without code evidence = FAIL.

### Red Flags — Reviewer Self-Check

| You think... | Reality |
|---|---|
| "Code works, tests pass, that's enough" | Working != readable. Check naming. |
| "I understand what `data` means here" | You have full context. Next reader won't. |
| "Naming is subjective" | Builder rules are objective: verb+noun, no `data`/`result`/`temp`. |
| "It's a small change, no need to nitpick" | Small changes accumulate. Apply same bar. |
| "Tests cover it, so the code is fine" | Tests verify behavior, not maintainability. |
| "Refactoring is out of scope for review" | READABILITY is a review dimension. Flag it. |

## Subagent 1: Code Auditor (Sonnet)

```
You are a paranoid staff engineer. Assume the code is wrong until proven otherwise.

Review for:
1. DATA LOSS: Upserts overwriting fields, missing WHERE clauses, tests hitting prod DB
2. CONCURRENCY: Unprotected shared state, thread/task leaks, deadlocks, race conditions (adapt to language)
3. ERRORS: Silent failures, swallowed exceptions, missing error returns
4. SECURITY: Unparameterized queries, credentials in logs, missing input validation
5. PERFORMANCE: N+1 queries, unbounded allocations, expensive ops in loops
6. CORRECTNESS: Off-by-one, overflow, nil/null dereference, wrong comparison
7. READABILITY: Generic names (data/result/temp/val/info), functions missing verb+noun, booleans that don't read as questions, comments restating code, unnecessary abstractions (one caller = inline, unless wrapper enforces an invariant). READABILITY findings are always MEDIUM or LOW — never CRITICAL/HIGH.

For each: SEVERITY (CRITICAL/HIGH/MEDIUM/LOW), FILE:LINE, PROBLEM, FIX.
If uncertain, mark MEDIUM not CRITICAL. Surface MEDIUM/LOW as non-blocking.

VERDICT: PASS (no critical/high) or FAIL. PASS with CRITICAL findings = contradiction → MUST be FAIL.
```

## Subagent 2: Adversarial QA (Sonnet)

```
You are a QA engineer trying to BREAK this code. Assume every input is hostile.

Review for:
1. EDGE CASES: Untested inputs (empty, nil, max, negative, unicode, very long)
2. STATE SEQUENCES: Order of operations causing bugs (create→delete→create, concurrent writes)
3. MISSING TESTS: Compare impl diff against test diff — what lacks coverage?
4. REGRESSION RISK: What existing behavior might break?

For each: SEVERITY, SCENARIO, EXPECTED, ACTUAL.
Focus on the category of code changed.

VERDICT: PASS (no critical/high) or FAIL.
```

## RECEIVE-REVIEW Protocol

For each finding:
1. **Verify against codebase** — Does the referenced code exist? Is the claim correct?
2. **Check false positives** — Intentional behavior? Check comments, git blame, tests.
3. **YAGNI** — Reviewer suggests something unneeded? Skip it.
4. **MEDIUM/LOW** — Document why and dismiss if incorrect.
5. **CRITICAL/HIGH** — Use tiebreaker protocol. Cannot self-dismiss.

## CRITICAL Dismissal Tiebreaker

**Author CANNOT self-dismiss CRITICAL/HIGH findings.**

1. Write dismissal rationale
2. Spawn tiebreaker Sonnet subagent:

```
You are an impartial technical judge. A reviewer found a CRITICAL/HIGH issue. The author wants to dismiss it.

FINDING: [original finding]
CODE: [relevant code]
AUTHOR'S RATIONALE: [why they think it's wrong]

Is the rationale valid or rationalizing away a real bug?
- Genuine false positive → DISMISS
- Real bug being downplayed → UPHOLD
- Uncertain → UPHOLD (err on safety)

RULING: UPHOLD (must fix) or DISMISS (confirmed false positive)
REASON: [one sentence]
```

3. UPHOLD → must fix. No appeal.
4. DISMISS → proceed. Externally validated.

## After Review

- Both PASS → /ship. Surface MEDIUM/LOW to user.
- Either FAIL → builder uses `/receiving-review` protocol to evaluate findings (verify each claim against codebase, push back on false positives, fix confirmed issues). Re-review with only new fixes.
- CRITICAL/HIGH disputed by builder → offer `/second-opinion` (cross-model blind review) as alternative to tiebreaker. If both models agree on CRITICAL, finding is confirmed — no appeal.
- 3 review cycles without PASS → STOP. Escalate: "Review failed 3 times. Different approach needed." Return to /plan.
- Malformed response → FAIL. Re-run subagent.
- Spawn fails → manual review using both checklists. Do NOT skip.

## Failure Paths

| Scenario | Detection | Severity | Recovery |
|----------|-----------|----------|----------|
| Subagent returns malformed output | Missing VERDICT line or unparseable | Medium | Re-run the specific subagent. If fails twice, manual review. |
| Subagent spawn fails | Agent tool returns error | Medium | Manual review using both checklists. Never skip review. |
| Tiebreaker deadlock | Tiebreaker agent returns inconclusive | Medium | Offer /second-opinion. If still deadlocked, escalate to user. |
| Large diff overwhelms reviewer | Findings are vague or miss obvious issues | High | Split into smaller chunks. Re-review per chunk. |
| False positive flood | >5 MEDIUM/LOW findings that are all incorrect | Low | Check reviewer prompt quality. May need context tuning. |
| Builder disputes all findings | Every finding challenged | High | Mandatory /second-opinion. If second model agrees with reviewer, findings stand. |

## Hotfix Mode

For hotfix tasks (prod down): spawn ONE Code Auditor subagent only (skip Adversarial QA). Same prompt, same gate. Speed over thoroughness when production is down.

## Next → /cso (if auth/input/data touched) or /benchmark (if frontend) or /ship
