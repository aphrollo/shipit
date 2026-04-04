---
name: router
description: When user asks to build, fix, change, add, remove, or refactor code — classify the task and route to the correct phase skill. Mandatory for ALL projects. Auto-invoke on any work request.
---

# Workflow Router

**This workflow is MANDATORY for ALL projects, ALL languages, ALL tasks.**

**Auto-trigger:** Invoke immediately when code/config/infra changes are requested.

## Default Mode: Orchestrate

**All non-trivial work MUST go through `/orchestrate` (multi-agent dispatch).** This is the default — not an option to choose.

After classifying the task, invoke `/orchestrate` to dispatch isolated agents. Do NOT run phases inline unless the user explicitly says "inline".

Why: Inline execution skips agent isolation, context separation, and mechanical enforcement of CIP. The orchestrator ensures every phase runs, every gate is checked, and CIP fires at the end. Without it, steps get skipped.

**User overrides:**
- "inline" → run phases inline without agent dispatch (fallback mode)
- "skip it" / "just do it" → BUILD → REVIEW → SHIP via orchestrate. Never skip REVIEW or SHIP.
- "just build" → builder only (spike mode)

## CLASSIFY (10 seconds)

| Task Type | Route |
|-----------|-------|
| **New feature** | REFRAME → DESIGN-REVIEW (if UI) → PLAN → BUILD → DESLOP (auto) → QA (if UI) → REVIEW → CSO (if auth/input/data) → BENCHMARK (if frontend) → SHIP → CANARY |
| **Feature change** | Same as new feature |
| **Bug / error** | INVESTIGATE → PLAN → BUILD → DESLOP (auto) → QA (if UI) → REVIEW → SHIP → CANARY |
| **Hotfix (prod down)** | INVESTIGATE (fast) → BUILD → REVIEW (1 agent) → SHIP → CANARY. **Skip:** DESLOP, QA, BENCHMARK, CSO. Speed over thoroughness. |
| **Refactor** | PLAN → BUILD → DESLOP (auto) → REVIEW → SHIP |
| **Migration / deps** | PLAN → BUILD → DESLOP (auto) → REVIEW → CSO → SHIP |
| **Config/infra** | PLAN → BUILD → REVIEW → SHIP |
| **Trivial fix** | BUILD → DESLOP (auto) → REVIEW → SHIP |
| **Docs only** | BUILD (no TDD) → REVIEW → SHIP |
| **Performance** | INVESTIGATE → PLAN → BUILD → DESLOP (auto) → BENCHMARK → REVIEW → SHIP |
| **Spike** | BUILD → done (no SHIP) |

**Rules:**
- Non-trivial tasks with "fix/bug/broken/error/crash/why" → INVESTIGATE first. Trivial ("Fix typo") is exempt — keyword rule does NOT override confirmed-trivial classification.
- Bug requiring behavior/interface change → Feature Change (REFRAME)
- Touches secrets/deployment/networking → include PLAN
- "Trivial" = one function, no shared state, no DB/API, < 10 lines. **If in doubt, not trivial.**
- Trivial/docs classification requires haiku subagent confirmation (enforced mechanically in orchestrator). DISAGREE → reclassify.

**Hotfix fast path:** Abbreviated INVESTIGATE (reproduce + root cause only). Verbal PLAN (30s). ONE review subagent. CANARY is mandatory for hotfixes.

**Classification gut check (5s):**
1. Would I classify the same if I re-read the request cold? (anchoring check)
2. Does it touch shared state, DB, API, or auth? → not trivial.
3. Am I downgrading to avoid overhead? → reclassify one level up.

If still trivial/docs after this check, the Sonnet confirmation rule above still applies.

## Phase Skills

| Skill | Purpose | Next |
|-------|---------|------|
| /reframe | Problem reframing | → /design-review (UI) or /plan |
| /design-review | 7-state UI audit | → /plan |
| /investigate | Root cause debugging | → /plan (or /reframe if design flaw) |
| /plan | Files, tests, risks | → /build |
| /build | TDD: RED → GREEN → REFACTOR | → /deslop (auto) → /qa (if UI) or /review |
| /deslop | AI code cleanup (automatic, --auto mode) | → /qa (if UI) or /review |
| /qa | Browser testing (Playwright) | → /review |
| /review | Parallel Sonnet subagent audit + /receiving-review for findings | → /cso (if applicable) or /benchmark (if frontend) or /ship |
| /cso | OWASP + STRIDE security audit | → /benchmark or /ship |
| /benchmark | Performance regression detection | → /ship |
| /ship | Pre-flight, deploy, verify | → /canary (if deployed) |
| /canary | Post-deploy soak monitoring | → /cip |
| /cip | Continuous improvement — capture learnings | Terminal |

## Specialist Skills

| Skill | Purpose |
|-------|---------|
| /learn | Persist/recall cross-session learnings |
| /writing-skills | TDD for creating/editing skills |

## Global Hooks (ALL phases)

| Hook | Purpose |
|------|---------|
| /careful | Blocks destructive commands |
| /verify | Tool-call evidence before claiming done |

**1% Rule:** If there's a 1% chance a phase or skill applies, invoke it. The cost of running it is minutes; the cost of skipping it is incidents.

## Anti-Rationalization

| Thought | Reality |
|---------|---------|
| "Too simple" | Classify trivial — still BUILD + REVIEW + SHIP |
| "Quick fix" | Quick fixes without review cause incidents |
| "I know the bug" | INVESTIGATE first. No fix without root cause. |
| "Subagents overkill" | They catch what you can't see |
| "User said skip" | BUILD + REVIEW + SHIP. Never skip REVIEW or SHIP. |
| "Should work now" | Show tool output. VERIFY. |
| "3rd attempt" | Stop. Question architecture. Escalate. |
| "I'll classify after I start" | CLASSIFY FIRST. 10 seconds now saves a wrong pipeline. |
| "It's basically trivial" | If you're arguing it's trivial, it isn't. Reclassify. |
| "Faster without /orchestrate" | Inline skips isolation, review gates, and CIP. Use /orchestrate. |
| "User seems impatient" | Impatience is not permission. Run the pipeline. |

## Do the Complete Thing

When 100% costs 2 min more, always do 100%.
