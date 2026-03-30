---
name: orchestrate
description: When code/config/infra changes are requested — classify the task and dispatch phases to specialized subagents (architect, builder, reviewer, deployer) instead of executing inline. Replaces direct /router invocation for multi-agent workflow.
---

# Orchestrate

**This skill wraps /router with multi-agent dispatch. Use INSTEAD of /router when you want isolated-context phases.**

## Step 1: Classify (10 seconds, inline — no agent spawn)

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
| **Hotfix** | architect(investigate-fast) → builder → reviewer(1-pass) → deployer |
| **New feature** | architect(reframe+plan) → builder → reviewer → deployer |
| **New feature (unfamiliar area)** | researcher → architect(reframe+plan) → builder → reviewer → deployer |
| **Feature change** | architect(reframe+plan) → builder → reviewer → deployer |
| **Migration / deps** | researcher(+deps) → architect(plan) → builder → reviewer(+cso) → deployer |
| **Performance** | researcher(+profiling) → architect(investigate+plan) → builder(+benchmark) → reviewer |

**Fast path:** Trivial and docs skip architect and deployer entirely — 2 agents, not 4.

**Research rule:** When ANY phase hits an unknown — unfamiliar API, unclear behavior, "how does X work?" — spawn researcher instead of exploring inline. Even on trivial tasks. Inline research pollutes the orchestrator's context. The researcher's context is disposable.

## Step 2: Dispatch

For each agent in the sequence:
1. Read the agent's prompt template from `~/.claude/agents/[name].md` (everything below the frontmatter `---`)
2. Spawn a `general-purpose` Agent, passing the template as the system instructions PLUS the task-specific context
3. Collect the agent's structured output

Example spawn pattern:
```
Agent tool call:
  subagent_type: general-purpose
  prompt: |
    [contents of ~/.claude/agents/builder.md body]

    --- TASK CONTEXT ---
    [plan output, files to change, etc.]
```

The `~/.claude/agents/*.md` files are prompt templates, NOT custom agent types. Always spawn as `general-purpose`.

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

**Builder receives:**
- The architect's plan output (or user's request if no architect phase)
- Specific files to change and test cases from the plan
- "Build on dev first" rule (air/8082 before prod)

**Reviewer receives:**
- The git diff of what builder changed (`git diff` output)
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
| deployer | haiku | Mechanical command execution with checks |

Override up: If a haiku agent fails a gate, retry with sonnet. If sonnet fails, retry with opus. Never override down.

### Parallel spawning

When agents are independent, spawn them in parallel:
- Architect phases are sequential (investigate before plan)
- Builder must wait for architect's plan
- Reviewer must wait for builder's diff
- Deployer must wait for reviewer's PASS
- BUT: if reviewer needs CSO, spawn the security check as a parallel reviewer task

## Step 3: Gate checks (inline — no agent spawn)

After each agent returns, check the gate:

| Agent | PASS condition | On FAIL |
|-------|---------------|---------|
| researcher | Has structured RESEARCH output with KEY FINDINGS and RELEVANT FILES | Retry with narrower scope, or skip and let architect explore inline |
| architect | Has structured output (ROOT CAUSE block, or PLAN with files+tests) | Ask user to clarify requirements |
| builder | All tests pass, BUILD RESULT: PASS | Feed errors back to builder, retry (max 3) |
| reviewer | REVIEW RESULT: PASS, no CRITICAL/HIGH | Feed findings to builder as fix instructions, re-review after fix (max 3 cycles) |
| deployer | DEPLOY RESULT: PASS, CANARY: HEALTHY | Alert user immediately. Do NOT auto-rollback without approval. |

**3 failures at any gate → STOP. Report to user: "[phase] failed 3 times. Different approach needed."**

## Step 3.5: /report hook (conditional — Telegram only)

Before Step 4, check once at workflow start: is the Telegram MCP server available AND is there a `chat_id` from an inbound Telegram message?

**If yes:** Fire `/report` at each phase transition — small status updates sent to the Telegram channel using the haiku model. See `/report` skill for message format.

```
For each agent in sequence:
  a. /report → "[phase] starting..."     ← fire-and-forget, never blocks
  b. Spawn agent
  c. Check gate
  d. /report → "[phase] passed/failed"   ← fire-and-forget, never blocks
```

On workflow complete: `/report` → final summary + react to original message with checkmark (if PASS).
On escalation: `/report` → warning that user input is needed.

**If no Telegram:** Skip silently. No errors, no fallback. Reports are optional.

## Step 4: Report

After workflow completes, summarize to user (in the conversation — this is separate from the Telegram /report hook):
```
TASK: [what was done]
PHASES: [which agents ran]
RESULT: PASS | FAIL
CHANGES: [files changed]
DEPLOYED: yes (dev/prod) | no
NOTES: [anything notable — reviewer findings fixed, performance metrics, etc.]
```

## Step 5: CIP (mandatory — runs automatically, never skip)

After EVERY workflow completion (PASS or FAIL), run /cip inline. Do NOT ask whether to run it. Do NOT skip it. This is the continuous improvement loop that makes the workflow better over time.

Answer the 3 CIP questions:
1. What slowed us down?
2. What almost went wrong?
3. What should change?

If a learning emerges → persist via /learn (with user confirmation).
If classification was wrong → update /orchestrate dispatch table.
If a gate was too loose/strict → update the gate check.
If an agent prompt was missing something → update the agent template.

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
