---
name: orchestrate
description: When code/config/infra changes are requested — classify the task and dispatch phases to specialized subagents (architect, builder, reviewer, deployer) instead of executing inline. This is the DEFAULT mode — the router auto-invokes orchestrate for all non-trivial work.
---

# Orchestrate

**This is the DEFAULT execution mode. The router auto-invokes orchestrate for all non-trivial work. Inline execution is the fallback, not the default.**

## Step 1: Resume Checkpoint

Check for an existing checkpoint before starting (see `shared/checkpointing.md`):

1. Read `docs/.shipit-checkpoint.json` if it exists
2. If checkpoint matches current task → offer resume to user
3. If checkpoint is stale (>4h) → recommend fresh start
4. If no checkpoint → proceed normally

On resume: validate all passport expiry times, re-run expired phases, resume from pending_phase.

## Step 2: Classify + Check Plan Cache (10 seconds, inline — no agent spawn)

Same classification as /router:

| Task Type | Agent Sequence |
|-----------|---------------|
| **Trivial fix** | builder → reviewer |
| **Docs only** | builder → reviewer |
| **Spike** | builder |
| **Refactor** | architect(plan) → builder → reviewer |
| **Config/infra** | architect(plan) → builder → reviewer → deployer |
| **Bug / error** | architect(investigate+plan) → builder → reviewer |
| **Bug (complex/unfamiliar code)** | researcher → architect(investigate+plan) → builder → reviewer |
| **Hotfix** | architect(investigate-fast) → builder → reviewer(1-pass) → deployer. **Signal:** Pass `mode: hotfix` to architect. Architect runs REPRODUCE + ROOT CAUSE only (skip TRACE/HYPOTHESIZE/VERIFY). Verbal plan (30s, no docs). **Skip:** /deslop, /benchmark, /cso, /qa. Speed over thoroughness when prod is down. |
| **New feature** | architect(reframe+plan) → builder → reviewer → deployer |
| **New feature (with UI)** | architect(reframe+plan) → designer → builder → reviewer → deployer |
| **New feature (unfamiliar area)** | researcher → architect(reframe+plan) → builder → reviewer → deployer |
| **Feature change** | architect(reframe+plan) → builder → reviewer → deployer |
| **Feature change (with UI)** | architect(reframe+plan) → designer → builder → reviewer → deployer |
| **Migration / deps** | researcher(+deps) → architect(plan) → builder → reviewer(+cso) → deployer |
| **Performance** | researcher(+profiling) → architect(investigate+plan) → builder(+benchmark) → reviewer |

**Fast path:** Trivial and docs skip architect and deployer entirely — 2 agents, not 4.

**Trivial/docs classification gate (mandatory):** Before dispatching the fast path, spawn a haiku subagent to confirm the classification:

```
Agent tool call:
  subagent_type: general-purpose
  model: haiku
  prompt: |
    User request: "[the original request]"
    Classification: "[trivial fix / docs only]"

    Is this actually trivial? Trivial = one function, no shared state,
    no DB/API changes, < 10 lines of logic. Docs = only documentation,
    no code behavior changes.

    Reply ONLY: "AGREE" or "DISAGREE: [reclassify as X because Y]"
```

- AGREE → proceed with fast path (builder → reviewer)
- DISAGREE → reclassify using the suggested type and dispatch the full pipeline
- Agent spawn fails → proceed with fast path (don't block on confirmation failure)

**Deslop integration:** After builder completes and before reviewer, run `/deslop --auto` on the builder's changes. This is automatic and non-blocking — it cleans AI code patterns before review sees them. If deslop finds score > 17/33, flag to user but don't block.

**Research rule:** When ANY phase hits an unknown — unfamiliar API, unclear behavior, "how does X work?" — spawn researcher instead of exploring inline. Even on trivial tasks. Inline research pollutes the orchestrator's context. The researcher's context is disposable.

## Handoff Schemas & Material Passports

Every agent-to-agent handoff is governed by typed schemas defined in `shared/handoff_schemas.md`. Every artifact carries a material passport defined in `shared/material_passports.md`.

**Schemas enforce completeness** — missing required fields trigger HANDOFF_INCOMPLETE, blocking the pipeline until the producing agent fills them.

**Passports enforce freshness** — expired artifacts must be re-created before downstream agents can use them.

The orchestrator validates both at every gate check (Step 4).

## Plan Cache

Before spawning the architect for a plan phase, check the plan cache (see `shared/plan_cache.md`):

1. Read `docs/.shipit-plan-cache.json` if it exists
2. Match user request against cached task_patterns
3. If match found (success_rate >= 80% or new template) → include template in architect's context: "PLAN TEMPLATE (adapt, don't copy): [template]"
4. Architect adapts the template to the specific task (this is adaptation, not blind reuse)
5. After workflow completes → update cache (capture new template or track success/failure of existing)

## Loop Detection

The orchestrator tracks agent retries using fingerprinting and progress detection (see `shared/loop_detection.md`):

- After each agent failure, compute fingerprint: `hash(agent + status + error_type + files)`
- **Same fingerprint twice** → agent is stuck. Change approach (more context, model override up, narrower scope) before retrying. Do NOT count as a real retry against circuit breaker.
- **Same fingerprint three times** → STOP immediately. Escalate. Don't waste the circuit breaker budget.
- **No progress between retries** (same test count, same findings, same files) → stuck. Change approach.

This works WITH circuit breakers: breakers catch 3 real failures, loop detection catches identical failures faster.

## Step 3: Dispatch

**Telegram check (once, at start of Step 3):** Is `telegram__reply` available AND is there a `chat_id` from an inbound Telegram message? Store the answer. If yes, every agent dispatch follows the reporting loop below. If no, skip all Telegram calls silently.

For each agent in the sequence, follow this loop:

```
For EACH agent:
  1. IF Telegram active → telegram__reply: "[emoji] [Phase] starting... Task: [one-line]"
  2. Spawn agent (see dispatch rules below)
  3. Run gate check (Step 4)
  4. IF Telegram active → telegram__reply: "[check/cross] [Phase] passed/failed — [one-line result]"

On workflow complete:
  IF Telegram active → telegram__reply: "Done — [PASS/FAIL]. Phases: [list]. Changes: [N files]."
  IF Telegram active AND PASS → telegram__react to original message with checkmark

On escalation (3 failures):
  IF Telegram active → telegram__reply: "Escalated — [phase] failed 3 times. Needs user input."
```

**This is NOT optional when Telegram is active.** The reporting loop is part of the dispatch — not a separate step. If you dispatch an agent, you report it.

Emoji map: Researcher=🔍 Architect=✏️ Designer=🎨 Builder=🔧 Reviewer=👀 Deployer=🚀 CIP=📈

Agent spawn template:
```
Agent tool call:
  subagent_type: shipit:builder
  prompt: |
    --- TASK CONTEXT ---
    [plan output, files to change, etc.]
```

### Agent type names (always use the namespaced version):

| Agent | subagent_type |
|-------|--------------|
| Researcher | `shipit:researcher` |
| Architect | `shipit:architect` |
| Designer | `shipit:designer` |
| Builder | `shipit:builder` |
| Reviewer | `shipit:reviewer` |
| Deployer | `shipit:deployer` |

**IMPORTANT:** When shipit is installed as a plugin, agents are namespaced with the `shipit:` prefix. Using bare names like `researcher` or `builder` will fail with "Agent type not found". Always use `shipit:researcher`, `shipit:builder`, etc.

### Context passing rules — each agent gets ONLY what it needs:

**Researcher receives (when in sequence):**
- The user's original request
- Which area of the codebase or dependency to explore
- Specific questions to answer (e.g., "how does the auth middleware work?", "what calls this function?", "what version of X are we on?")

**Architect receives:**
- The user's original request
- Researcher's findings (if researcher ran — replaces raw code exploration)
- Relevant file paths and code (read them first, pass content in prompt — only if no researcher phase)
- Error logs/stack traces (for investigate)
- Which phase(s) to execute (reframe, investigate, plan, design-review)

**Designer receives:**
- The architect's plan output (specifically UI-related components)
- Existing project styles (CSS files, Tailwind config, theme files)
- Current DESIGN.md if one exists
- Which components need design decisions

**Builder receives:**
- The architect's plan output (or user's request if no architect phase)
- Specific files to change and test cases from the plan
- "Build on dev first" rule (air/8082 before prod)

**Reviewer receives:**
- The git diff of what builder changed (`git diff` output)
- `git diff --stat` output (for large diff auto-splitting — if >500 lines, split by module before spawning review subagents)
- Test files for changed modules
- Upstream callers and downstream callees of changed code
- Whether to include CSO (security audit)
- NEVER include the architect's reasoning or builder's notes — review cold

**Deployer receives:**
- The service name and deploy commands
- Health check URLs
- Whether this is dev or prod deploy
- The "dev before prod" rule

### Model selection

Use the least powerful model that can handle each role to minimize token cost:

| Agent | Recommended model | Rationale |
|-------|------------------|-----------|
| researcher | haiku | Mechanical search and summarization |
| architect | opus/sonnet | Requires reasoning about architecture and trade-offs |
| builder | sonnet | Needs to write correct code, but follows a plan |
| reviewer | sonnet | Needs judgment to assess code quality and security |
| designer | sonnet | Needs design judgment for visual systems and accessibility |
| deployer | haiku | Mechanical command execution with checks |

Override up: If a haiku agent fails a gate, retry with sonnet. If sonnet fails, retry with opus. Never override down.

### Parallel spawning

When agents are independent, spawn them in parallel:
- Architect phases are sequential (investigate before plan)
- Builder must wait for architect's plan
- **Deslop** runs after builder, before reviewer (automatic, inline, non-blocking)
- Reviewer must wait for builder's diff (post-deslop)
- Deployer must wait for reviewer's PASS
- CSO runs **sequentially after reviewer PASS**, not in parallel (security audit needs clean code, not in-flight changes)

### Staleness detection

Before each agent runs, check if its inputs are stale:
- **Plan staleness**: If architect's plan is >2 hours old AND git log shows new commits since plan was created → re-run architect with updated context
- **Research staleness**: If researcher's findings are >4 hours old → re-run researcher
- **Review staleness**: If reviewer's PASS is >1 hour old AND builder made additional changes since review → re-review
- **Baseline staleness**: If benchmark baseline is >24 hours old → recapture before comparing

**Implementation:** Timestamps are tracked by the orchestrator in-memory during a session. Each agent's completion time is recorded when its gate check passes. Compare against `git log --oneline -1 --format=%ct` (unix timestamp of latest commit) to detect code changes since last phase. No external file needed — staleness is session-scoped.

When in doubt, re-run — fresh data is cheap, stale bugs are expensive.

## Step 4: Gate checks (inline — no agent spawn)

After each agent returns, the orchestrator runs THREE checks in order:

### 4a. Passport validation
- Parse the PASSPORT block from agent output
- Verify required fields: artifact, version, created_at, created_by, based_on, content_summary
- Check that `based_on` references match artifacts the orchestrator has in session
- Set `expires_at` based on artifact type (see `shared/material_passports.md`)
- Set status to VERIFIED if all checks pass
- Missing PASSPORT block → warn agent but don't block (graceful degradation)

### 4b. Schema validation
- Validate agent output against the handoff schema for its type (see `shared/handoff_schemas.md`)
- Check all required fields present and non-empty
- Run type checks (enums match, lists are lists, etc.)
- Run cross-reference checks (e.g., builder's files_changed subset of plan's files_to_change)
- Run contradiction checks (e.g., PASS + CRITICAL findings = auto-correct to FAIL)
- **HANDOFF_INCOMPLETE** → return to agent with: "HANDOFF_INCOMPLETE: missing [field1, field2]. Re-run and include these." Max 2 retries.

### 4c. Gate check
- Evaluate pass/fail condition for the agent type:

| Agent | PASS condition | On FAIL |
|-------|---------------|---------|
| researcher | RESEARCH_HANDOFF valid: key_findings + relevant_files non-empty | Retry with narrower scope, or skip and let architect explore inline |
| architect | PLAN_HANDOFF or INVESTIGATE_HANDOFF valid: all required fields present | Ask user to clarify requirements, retry (max 2). If still fails, STOP. |
| designer | DESIGN_HANDOFF valid: all 7 states filled, constraints non-empty | Re-run with specific missing states listed. Max 2 retries. |
| builder | BUILD_HANDOFF valid: result=PASS, tests_passed=tests_total | Feed errors back to builder, retry (max 3) |
| reviewer | REVIEW_HANDOFF valid: result=PASS, critical_count=0, high_count=0 | Feed findings to builder via /receiving-review, re-review after fix (max 3 cycles) |
| deployer | DEPLOY_HANDOFF valid: result=PASS, preflight=PASS | Alert user immediately. Do NOT auto-rollback without approval. |

### 4d. Staleness check on next agent's inputs
- Before spawning the NEXT agent, check `expires_at` on all parent artifacts it depends on
- If any parent is expired → re-run the expired agent first
- Pass artifact IDs + content_summaries to the next agent in its prompt

**3 failures at any gate → STOP. Report to user: "[phase] failed 3 times. Different approach needed."**
**But first**: check loop detection — if fingerprints are identical, change approach before counting as a real failure.

## Step 5: Save Checkpoint

After gate check PASSES, save checkpoint to `docs/.shipit-checkpoint.json` (see `shared/checkpointing.md`):
- Record: completed phase, artifact ID, passport, output summary
- This enables resume if the orchestrator crashes before the next agent completes

## Step 6: Report + Collect Metrics

After workflow completes, summarize to user (in the conversation — this is separate from the Telegram /report hook):
```
TASK: [what was done]
PHASES: [which agents ran]
RESULT: PASS | FAIL
CHANGES: [files changed]
DEPLOYED: yes (dev/prod) | no
NOTES: [anything notable — reviewer findings fixed, performance metrics, etc.]

PROVENANCE CHAIN:
  [artifact-id v1] → [artifact-id v1] → [artifact-id v1] → ...
  (full chain from first agent to last, with versions)
```

The provenance chain is constructed from material passports collected during the workflow. It enables post-incident traceability — if something breaks in prod, follow the chain to find which plan, build, and review led to the deploy.

Also append a metrics record to `docs/.shipit-metrics.jsonl` (see `shared/workflow_metrics.md`):
- Workflow result, classification, duration, agents used
- Per-agent results, retry counts, models used, durations
- Gate failures, loop detections, handoff incomplete counts
- Plan cache hit/miss, checkpoint resume used

Every 10th workflow, auto-analyze aggregates:
- End-to-end success rate < 85% → flag degradation
- Any agent retry rate > 30% → flag for prompt improvement
- Mean time increased > 50% → flag slowdown

Metrics make /cip and /retro data-driven instead of anecdotal.

**Checkpoint cleanup:**
- Workflow PASS → delete `docs/.shipit-checkpoint.json`
- Workflow FAIL (escalated) → keep checkpoint (user may resume later)

## Step 7: Update Plan Cache

- Workflow PASS → capture plan template if new task pattern, or increment success count for existing template
- Workflow FAIL at builder or later → increment failure count for matched template
- Workflow FAIL at architect → flag template for review (may be wrong)

## Step 8: CIP (mandatory — the ONLY place CIP runs, never skip)

After EVERY workflow completion (PASS or FAIL), run /cip inline. Do NOT ask whether to run it. Do NOT skip it. This is the continuous improvement loop that makes the workflow better over time.

**CIP runs HERE and ONLY here.** Individual skills (like /ship) do NOT invoke CIP — only the orchestrator does, once, at the end. This prevents double-invocation.

Answer the 3 CIP questions:
1. What slowed us down?
2. What almost went wrong?
3. What should change?

If a learning emerges → persist via /learn (with user confirmation).
If classification was wrong → update /orchestrate dispatch table.
If a gate was too loose/strict → update the gate check.
If an agent prompt was missing something → update the agent template.

## Failure Paths (orchestrator-level)

| Scenario | Detection | Severity | Recovery |
|----------|-----------|----------|----------|
| Agent spawn fails | Agent tool returns error | Medium | Retry once with same model. If still fails, retry with model override up. If opus fails, fall back to inline execution. |
| Agent returns empty/garbage | No structured output, missing required sections | Medium | Re-spawn with clearer prompt. If fails twice, escalate to user. |
| Gate fails 3 times at same phase | Counter reaches 3 for any phase | High | STOP entire workflow. Report which phase failed and why. Return to /plan or escalate. |
| Stale inputs detected | Timestamp check fails (see staleness detection) | Medium | Re-run the upstream agent that produced stale data. |
| Classification was wrong (discovered mid-workflow) | Builder or reviewer discovers task is more complex than classified | High | STOP. Reclassify. Restart from correct phase. Do NOT continue on wrong path. |
| Context window approaching limit | Orchestrator at >70% context | Medium | Compact conversation. Summarize completed phases. Continue with fresh context. |
| User interrupts mid-workflow | User sends new message during agent execution | Low | Complete current agent, then pause. Ask user if they want to continue or pivot. |
| Researcher returns nothing useful | No KEY FINDINGS or all findings are irrelevant | Low | Skip researcher phase. Let architect explore inline. |
| Builder scope creep | Builder discovers changes not in plan | High | STOP builder. Return to architect for re-plan. |
| Deploy fails after review PASS | Health check fails post-deploy | Critical | Offer rollback immediately. Do NOT auto-rollback without user approval. |

## Adding a New Agent

To add a new agent to the system:

1. Create `~/.claude/agents/[name].md` — frontmatter for metadata, body is the prompt template
2. Add the agent to the dispatch table above (which task types invoke it, and where in the sequence)
3. Define what context it receives and what output it returns in the context passing rules
4. Define its PASS/FAIL gate condition in the gate checks table

That's it. The orchestrator reads the template and spawns it as a general-purpose agent.

Agents can also be invoked standalone via CLI: `claude --agent ~/.claude/agents/[name].md`

## Overrides

- User says "skip it" / "just do it" → builder → reviewer. Never skip reviewer.
- User says "no deploy" → skip deployer.
- User says "inline" → fall back to normal /router behavior (no subagents).
- User says "just build" → builder only (spike mode).

## Global Guards

/careful and /verify remain active in the ORCHESTRATOR context (not inside subagents — they have their own safeguards baked into their prompts).

## Conditional Hooks

/report activates only when Telegram MCP server is present and a chat_id exists. Check once at workflow start, store the result. If not available, skip all /report calls silently.

## Anti-Rationalization

| Thought | Reality |
|---------|---------|
| "Too simple for agents" | Use the fast path (builder+reviewer). Still isolated. |
| "Agent overhead too high" | Trivial = 2 agents. Feature = 4. Overhead is worth independent review. |
| "I'll just do it inline" | Unless user said "inline", use agents. That's the point. |
| "Reviewer won't have enough context" | Good. Cold review catches what warm review misses. |
| "Skip deployer, I'll deploy myself" | Deployer has the safety checks. Use it. |
