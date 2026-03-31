---
name: report
description: Conditional hook — when a Telegram channel is active, send self-contained progress updates at each phase transition. The user has NO access to the CLI — reports are their only window into what's happening. Only activates when Telegram MCP server is available.
---

# Report — Telegram Progress Updates

**Embedded in the Step 3 dispatch loop. NOT a separate step. If you dispatch an agent and Telegram is active, you report it.**

## Core Principle: Self-Contained Reports

**The Telegram user cannot see the CLI.** They have zero access to tool output, agent results, conversation context, or terminal logs. Every report must make sense on its own — as if it's the only thing the user will ever read about this phase.

Never reference details that only appeared in CLI output. If the user hasn't been told something via Telegram, they don't know it.

## Activation

Active when ALL are true:
1. `telegram__reply` tool is available
2. A `chat_id` exists from an inbound Telegram message
3. Workflow is running via `/orchestrate`

If any condition is missing → skip silently. No errors.

## Message Format

### Phase start
```
[emoji] [Phase] starting — [what it will do in plain language]
```

### Phase pass (the most important message — include actual findings)
```
✅ [Phase] passed

[2-5 lines of what was actually found/done/decided — the substance, not just "it passed"]
```

### Phase fail
```
❌ [Phase] failed ([N] of 3) — [what specifically went wrong]
```

### Workflow done (comprehensive summary)
```
🚢 Done — [PASS/FAIL]
Phases: [list]
Changes: [N files, N insertions]

What was done:
- [bullet per fix/feature, with enough detail to understand what changed]
```

### Escalation
```
⚠️ Escalated — [phase] failed 3 times.
[What was tried, what keeps failing]
Needs your input on: [specific question]
```

Emoji map: 🔍 Researcher · ✏️ Architect · 🎨 Designer · 🔧 Builder · 👀 Reviewer · 🚀 Deployer · 📈 CIP

## Context Tracking

Track what the user has been told via Telegram vs what exists only in CLI:

- **First report** in a workflow should establish the full task context — what issues exist, what the plan is, what will be fixed. Don't assume the user remembers the original request verbatim.
- **Subsequent reports** can use shorthand, but ONLY for things already explained in a previous Telegram message. If you numbered issues in an earlier message, you can reference those numbers. If you didn't, spell it out.
- **Investigation/plan results** must include the actual findings — "found 3 root causes" is useless; "found that flaky tests, resume bug, and batch cap all share one root cause: tests use a shared DB" is useful.
- **Review findings** must say what was found — "2 HIGH findings" needs to be followed by what they ARE: "rate limiter bypassable via header spoofing; pool config comment misleading operators".

## Rules

- **Concise but complete.** No code, no diffs, no stack traces — but include enough substance that the user understands what happened. 2-8 lines per message is fine when the content is meaningful.
- **No empty calories.** Every line should add information. Cut filler ("Starting now...", "Let me check...") but never cut substance.
- **Fire-and-forget.** If send fails, continue. Never block the workflow.
- **One message per phase transition.** Not per file, not per test, not per retry within a phase.
- **React on completion.** If PASS, react to the original Telegram message with a checkmark.
- **No sensitive data.** No API keys, passwords, tokens, or internal URLs.

## Anti-Patterns

| Bad | Good |
|-----|------|
| "Issues 1, 6, 7 share a root cause" (user never saw issue numbers) | "Flaky tests, resume bug, and batch cap all share one root cause: shared DB" |
| "Investigation complete, 9 issues found" | "Investigation found 9 issues: [list each briefly]" |
| "Review FAIL — 2 HIGH" | "Review FAIL — 2 HIGH: rate limiter bypassable via X-Real-IP spoofing; pool config comment misleads operators" |
| "Phase 2 starting" | "Builder starting — adding rate limiting + input validation + pool config" |
| "Build passed" | "Build passed — rate limiter (60/min per IP), combo tag dedup + cap, pool limits set. 116 tests green." |

## Integration

The dispatch loop in `/orchestrate` Step 3 handles all reporting. The orchestrator calls `telegram__reply` directly — no subagent spawn needed for status messages. See `orchestrate/SKILL.md` Step 3 for the full loop.
