---
name: report
description: Conditional hook — when a Telegram channel is active, send small progress updates at each phase transition. Uses haiku model to keep reports concise and costs low. Only activates when Telegram MCP server is available.
---

# Report — Telegram Progress Updates

**When a Telegram channel is active, send a short status update at each workflow phase transition. Silent when no channel is configured.**

## When to Activate

This hook is **conditional** — it only fires when ALL of these are true:

1. The Telegram MCP server is connected (tools `telegram__reply`, `telegram__react` are available)
2. A `chat_id` is known from an inbound Telegram message in the current conversation
3. The workflow is running via `/orchestrate` (not inline `/router`)

**If any condition is missing, do nothing. No errors, no warnings — just skip silently.**

## What to Report

Send a Telegram message at each phase transition using the **haiku model** (spawn a haiku subagent for message generation to keep costs minimal):

### Phase Start

When an agent is about to be dispatched:

```
[phase emoji] [Phase] starting...
Task: [one-line summary]
```

Emoji map:
- Researcher: magnifying glass
- Architect: pencil
- Builder: wrench
- Reviewer: eyes
- Deployer: rocket
- CIP: chart with upwards trend

### Phase Complete (PASS)

```
[check mark] [Phase] passed
[one-line summary of output — e.g., "3 files in plan", "12 tests green", "no findings"]
```

### Phase Complete (FAIL)

```
[cross mark] [Phase] failed ([attempt] of 3)
[one-line reason — e.g., "2 test failures", "1 CRITICAL finding"]
```

### Workflow Complete

```
[ship emoji] Done — [PASS/FAIL]
Phases: [list]
Changes: [N files]
[Duration if available]
```

### Workflow Escalation (3 failures)

```
[warning emoji] Escalated — [phase] failed 3 times
Needs user input
```

## How to Send

Use the `telegram__reply` tool with the `chat_id` from the conversation's inbound Telegram message. Do NOT use `reply_to` for progress updates — they should appear as standalone messages, not threaded replies.

## Rules

- **Keep it short.** Each update is 1-3 lines max. No code blocks. No diffs. No explanations.
- **Use haiku model** for generating report text — spawn with `model: "haiku"` to minimize token cost.
- **Never block the workflow.** If the Telegram send fails, log nothing and continue. Reports are fire-and-forget.
- **No sensitive data.** Never include file contents, credentials, error stack traces, or code snippets in reports. Phase name + pass/fail + one-line summary only.
- **Don't over-report.** One message per phase transition. Not per file. Not per test. Not per retry attempt within a phase — only when retrying after a gate failure (attempt 2 of 3, attempt 3 of 3).
- **React instead of messaging** when appropriate — if the user sent the request via Telegram, react to their message with a checkmark when the workflow completes successfully.

## Integration with /orchestrate

The orchestrator should check for Telegram availability once at the start of the workflow. If available, store the `chat_id` and invoke `/report` at each gate transition. The report hook runs inline (not as a subagent) since it's just a single tool call.

```
Orchestrator flow with /report:
  1. Classify task
  2. Check: is Telegram active? Store chat_id if yes.
  3. For each agent:
     a. /report → "[phase] starting..."
     b. Spawn agent
     c. Check gate
     d. /report → "[phase] passed/failed"
  4. /report → "Done — PASS/FAIL"
  5. React to original message with checkmark (if PASS)
  6. CIP (as always)
```

## Not a Global Hook

Unlike `/careful` and `/verify`, this is a **conditional hook** — it requires an external integration (Telegram) and only activates when that integration is present. It should be listed separately from the global hooks in documentation.
