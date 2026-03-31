---
name: report
description: Conditional hook — when a Telegram channel is active, send small progress updates at each phase transition. Uses haiku model to keep reports concise and costs low. Only activates when Telegram MCP server is available.
---

# Report — Telegram Progress Updates

**Embedded in the Step 3 dispatch loop. NOT a separate step. If you dispatch an agent and Telegram is active, you report it.**

## Activation

Active when ALL are true:
1. `telegram__reply` tool is available
2. A `chat_id` exists from an inbound Telegram message
3. Workflow is running via `/orchestrate`

If any condition is missing → skip silently. No errors.

## Message Format

**Phase start:** `[emoji] [Phase] starting... Task: [one-line summary]`
**Phase pass:** `✅ [Phase] passed — [one-line result]`
**Phase fail:** `❌ [Phase] failed ([N] of 3) — [one-line reason]`
**Workflow done:** `🚢 Done — [PASS/FAIL]. Phases: [list]. Changes: [N files].`
**Escalation:** `⚠️ Escalated — [phase] failed 3 times. Needs user input.`

Emoji map: 🔍 Researcher · ✏️ Architect · 🎨 Designer · 🔧 Builder · 👀 Reviewer · 🚀 Deployer · 📈 CIP

## Rules

- **1-3 lines max.** No code. No diffs. No stack traces.
- **Fire-and-forget.** If send fails, continue. Never block the workflow.
- **One message per phase transition.** Not per file, not per test, not per retry within a phase.
- **React on completion.** If PASS, react to the original Telegram message with a checkmark.
- **No sensitive data.** Phase name + pass/fail + one-line summary only.

## Integration

The dispatch loop in `/orchestrate` Step 3 handles all reporting. The orchestrator calls `telegram__reply` directly — no subagent spawn needed for simple status messages. See `orchestrate/SKILL.md` Step 3 for the full loop.
