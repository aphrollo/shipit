---
name: router
description: When user asks to build, fix, change, add, remove, or refactor code — classify the task, dispatch agents, enforce gates, and run CIP. Single entry point for all work. Mandatory for ALL projects. Auto-invoke on any work request.
---

# Workflow Router

**This workflow is MANDATORY for ALL projects, ALL languages, ALL tasks.**

**Auto-trigger:** Invoke immediately when code/config/infra changes are requested.

---

## STEP 1: CLASSIFY (10 seconds)

| Task Type | Route |
|-----------|-------|
| **New feature** | REFRAME → DESIGN-REVIEW (if UI) → PLAN → BUILD → DESLOP (auto) → QA (if UI) → REVIEW → CSO (if auth/input/data) → BENCHMARK (if frontend) → SHIP → CANARY |
| **Feature change** | Same as new feature |
| **Bug / error** | INVESTIGATE → PLAN → BUILD → DESLOP (auto) → QA (if UI) → REVIEW → SHIP → CANARY |
| **Hotfix (prod down)** | INVESTIGATE (fast) → BUILD → REVIEW (1 agent) → SHIP → CANARY. **Skip:** DESLOP, QA, BENCHMARK, CSO. |
| **Refactor** | PLAN → BUILD → DESLOP (auto) → REVIEW → SHIP |
| **Migration / deps** | PLAN → BUILD → DESLOP (auto) → REVIEW → CSO → SHIP |
| **Config/infra** | PLAN → BUILD → REVIEW → SHIP |
| **Trivial fix** | BUILD → DESLOP (auto) → REVIEW → SHIP |
| **Docs only** | BUILD (no TDD) → REVIEW → SHIP |
| **Performance** | INVESTIGATE → PLAN → BUILD → DESLOP (auto) → BENCHMARK → REVIEW → SHIP |
| **Spike** | BUILD → done (no SHIP) |

**Rules:**
- Non-trivial tasks with "fix/bug/broken/error/crash/why" → INVESTIGATE first. Trivial ("Fix typo") is exempt.
- Bug requiring behavior/interface change → Feature Change (REFRAME)
- Touches secrets/deployment/networking → include PLAN
- "Trivial" = one function, no shared state, no DB/API, < 10 lines. **If in doubt, not trivial.**

**Classification gut check (5s):**
1. Would I classify the same if I re-read the request cold? (anchoring check)
2. Does it touch shared state, DB, API, or auth? → not trivial.
3. Am I downgrading to avoid overhead? → reclassify one level up.

**Trivial/docs gate:** Spawn a haiku subagent to confirm before fast path:

```
Agent tool call:
  subagent_type: general-purpose
  model: haiku
  prompt: |
    User request: "[the original request]"
    Classification: "[trivial fix / docs only]"
    Is this actually trivial (one function, no shared state, no DB/API, <10 lines)?
    Reply ONLY: "AGREE" or "DISAGREE: [reclassify as X because Y]"
```
- AGREE → fast path. DISAGREE → reclassify. Spawn fails → proceed anyway.

If still trivial/docs after haiku confirms, proceed to Step 2.

**Hotfix fast path:** Abbreviated INVESTIGATE (reproduce + root cause only). Verbal PLAN (30s). ONE review subagent.

---

## STEP 2: RESUME CHECKPOINT

Check for an existing checkpoint before dispatching (see `shared/checkpointing.md`):

1. Read `docs/.shipit-checkpoint.json` if it exists
2. If checkpoint matches current task → offer resume to user
3. If checkpoint is stale (>4h) → recommend fresh start
4. If no checkpoint → proceed normally

On resume: validate all passport expiry times, re-run expired phases, resume from pending_phase.

---

## STEP 3: DISPATCH AGENTS

### Agent sequence by task type

| Task Type | Agent Sequence |
|-----------|---------------|
| **Trivial fix** | builder → reviewer |
| **Docs only** | builder → reviewer |
| **Spike** | builder |
| **Refactor** | architect(plan) → builder → reviewer |
| **Config/infra** | architect(plan) → builder → reviewer → deployer |
| **Bug / error** | architect(investigate+plan) → builder → reviewer |
| **Bug (complex)** | researcher → architect(investigate+plan) → builder → reviewer |
| **Hotfix** | architect(investigate-fast) → builder → reviewer(1-pass) → deployer |
| **New feature** | architect(reframe+plan) → builder → reviewer → deployer |
| **New feature (UI)** | architect(reframe+plan) → designer → builder → reviewer → deployer |
| **New feature (unfamiliar)** | researcher → architect(reframe+plan) → builder → reviewer → deployer |
| **Feature change** | architect(reframe+plan) → builder → reviewer → deployer |
| **Feature change (UI)** | architect(reframe+plan) → designer → builder → reviewer → deployer |
| **Migration / deps** | researcher(+deps) → architect(plan) → builder → reviewer(+cso) → deployer |
| **Performance** | researcher(+profiling) → architect(investigate+plan) → builder(+benchmark) → reviewer |

### Telegram reporting

**Telegram check (once, at start):** Is `telegram__reply` available AND is there a `chat_id`? If yes, report every agent start/pass/fail. If no, skip silently.

```
For EACH agent:
  1. IF Telegram → "[emoji] [Phase] starting..."
  2. Spawn agent
  3. Gate check (Step 4)
  4. IF Telegram → "[check/cross] [Phase] passed/failed"

On complete: IF Telegram → "Done — [PASS/FAIL]. Phases: [list]."
On escalation: IF Telegram → "Escalated — [phase] failed 3 times."
```

Emoji map: Researcher=🔍 Architect=✏️ Designer=🎨 Builder=🔧 Reviewer=👀 Deployer=🚀 CIP=📈

### Agent type names (always namespaced)

| Agent | subagent_type |
|-------|--------------|
| Researcher | `shipit:researcher` |
| Architect | `shipit:architect` |
| Designer | `shipit:designer` |
| Builder | `shipit:builder` |
| Reviewer | `shipit:reviewer` |
| Deployer | `shipit:deployer` |

### Context passing — each agent gets ONLY what it needs

**Researcher:** Original request, area to explore, specific questions.
**Architect:** Original request, researcher findings (or read files inline), error logs, which phases to run.
**Designer:** Architect's plan (UI parts), existing styles, DESIGN.md.
**Builder:** Architect's plan (or user request if no architect), files + test cases.
**Reviewer:** Git diff + diff stat + test files + call graph. NEVER architect reasoning or builder notes — review cold.
**Deployer:** Service name, deploy commands, health check URLs, dev-or-prod.

### Model selection

| Agent | Model | Rationale |
|-------|-------|-----------|
| researcher | haiku | Mechanical search |
| architect | opus/sonnet | Requires reasoning |
| builder | sonnet | Writes code, follows plan |
| reviewer | sonnet | Judgment for quality |
| designer | sonnet | Design judgment |
| deployer | haiku | Mechanical commands |

Override up on failure: haiku → sonnet → opus. Never down.

### Integration rules

- **Deslop:** Runs auto after builder, before reviewer. Score > 17/33 → flag but don't block.
- **Research rule:** Unknown API/behavior → spawn researcher, don't explore inline.
- **Parallel spawning:** Independent agents in parallel. Builder waits for plan. Reviewer waits for diff. CSO after reviewer PASS.
- **Plan cache:** Check `docs/.shipit-plan-cache.json` before architect. Adapt cached templates, don't copy.

### Staleness detection

- Plan >2h old + new commits → re-run architect
- Research >4h old → re-run researcher
- Review >1h old + new builder changes → re-review
- Benchmark baseline >24h → recapture

---

## STEP 4: GATE CHECKS

After each agent returns, run three checks in order:

**4a. Passport validation:** Parse PASSPORT block. Verify fields. Check `based_on` references. Missing → warn but don't block.

**4b. Schema validation:** Validate against handoff schema (`shared/handoff_schemas.md`). HANDOFF_INCOMPLETE → return to agent with missing fields. Max 2 retries.

**4c. Gate check:**

| Agent | PASS condition | On FAIL |
|-------|---------------|---------|
| researcher | KEY FINDINGS + RELEVANT FILES non-empty | Retry narrower, or skip |
| architect | PLAN/INVESTIGATE fields complete | Ask user to clarify (max 2) |
| designer | All 7 states + constraints filled | Re-run with missing states (max 2) |
| builder | result=PASS, tests_passed=tests_total | Feed errors back (max 3) |
| reviewer | result=PASS, critical=0, high=0 | Feed findings to builder via /receiving-review (max 3) |
| deployer | result=PASS, preflight=PASS | Alert user. No auto-rollback. |

**4d. Staleness check on next agent's inputs.** Expired parent → re-run upstream.

**3 failures at any gate → STOP.** Check loop detection first — identical fingerprints change approach before counting.

---

## STEP 5: CHECKPOINT + METRICS

After each gate PASS, save to `docs/.shipit-checkpoint.json`. Workflow PASS → delete checkpoint. FAIL → keep for resume.

After workflow completes, report:
```
TASK: [what] | PHASES: [list] | RESULT: PASS|FAIL | CHANGES: [files]
PROVENANCE: [artifact chain]
```

Append to `docs/.shipit-metrics.jsonl`. Every 10th workflow, auto-flag: success <85%, retry >30%, time +50%.

---

## STEP 6: CIP (mandatory, never skip)

After EVERY workflow (PASS or FAIL):
1. What slowed us down?
2. What almost went wrong?
3. What should change?

Learning → /learn. Wrong classification → update dispatch. Loose gate → update check. Missing prompt → update agent.

---

## LOOP DETECTION

Fingerprint: `hash(agent + status + error_type + files)`
- Same fingerprint twice → change approach before retrying
- Same fingerprint three times → STOP immediately
- No progress between retries → stuck, change approach

---

## FAILURE PATHS

| Scenario | Recovery |
|----------|----------|
| Agent spawn fails | Retry with model override up. Opus fails → inline fallback. |
| Empty/garbage output | Re-spawn with clearer prompt. 2 fails → escalate. |
| 3 gate failures | STOP. Report which phase failed. |
| Classification wrong mid-workflow | STOP. Reclassify. Restart from correct phase. |
| Context >70% | Compact. Summarize completed phases. Continue. |
| Builder scope creep | STOP builder. Return to plan. |
| Deploy fails after review PASS | Offer rollback. No auto-rollback. |

---

## OVERRIDES

- "inline" → run phases inline (no subagents)
- "skip it" / "just do it" → builder → reviewer → ship. Never skip review.
- "no deploy" → skip deployer
- "just build" → builder only (spike mode)

## GLOBAL GUARDS

/careful and /verify remain active in all phases. Subagents have their own safeguards.

## CONDITIONAL HOOKS

/report activates only when Telegram MCP is present + chat_id exists. Silent otherwise.

---

**1% Rule:** If there's a 1% chance a phase or skill applies, invoke it. Minutes vs. incidents.

## ANTI-RATIONALIZATION

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
| "Faster without agents" | Inline skips isolation, review gates, and CIP. Use agents. |
| "User seems impatient" | Impatience is not permission. Run the pipeline. |

## COMMUNICATION

- **Facts only.** No apologies, no hedging, no softening. State what is, not what you feel about it.
- **Never read tone.** CAPS = emphasis. Short messages = efficiency. Don't interpret emotion.
- **No babysitting.** Don't ask "are you sure?" or "would you like me to explain?" Just do the work.
- **Wrong? Correct and move on.** No groveling. "That was wrong. The correct answer is X."

## DO THE COMPLETE THING

When 100% costs 2 min more, always do 100%.
