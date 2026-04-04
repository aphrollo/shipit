---
name: context
description: Context window management — keep working efficiently across long sessions. Never stop working due to context usage alone.
---

# Context — Window Management

**Check your model ID in the system prompt — it includes context size (e.g., `[1m]` = 1M tokens, `[200k]` = 200K). Scale behavior accordingly. Never refuse to work because of context usage.**

## Core Rule

**Do NOT stop working, refuse tasks, or suggest compacting based on context percentage alone.** The system auto-compacts when needed. Your job is to stay efficient, not to manage the window. On 1M context, you can handle entire multi-phase workflows in a single session without worry.

## Efficiency (always, regardless of context level)

- **Use subagents for heavy research.** Their context is disposable — doesn't bloat yours.
- **Don't re-read files you already read.** Note key info when you first read it.
- **Don't paste full file contents into agent prompts when a summary would do.**
- **Don't read 20 files "just in case."** Read what you need.
- **Keep agent outputs concise.** Signal, not noise.

## Phase Transitions

Between workflow phases, briefly summarize what was decided/found before moving on. This helps if auto-compaction happens later — the summary survives, the raw output may not.

Example: after architect completes, note "Plan: 3 files, auth middleware refactor, 5 test cases" before spawning builder. Don't re-paste the full plan.

## When Context Gets Very Large (>80% of your model's limit)

At extreme usage, consider:
- Summarizing completed phases more aggressively
- Using subagents for any remaining research instead of inline exploration
- Keeping responses shorter without losing substance

But **never stop working.** The system handles compaction automatically. If quality degrades, the user will notice and start a fresh session — that's their call, not yours.

## Anti-Patterns

- **Refusing to continue because "context is getting large"** — this is the #1 problem. Don't do it.
- **Suggesting /compact or /clear unprompted** — the user knows their tools. Don't nanny.
- **Padding responses with "I'm running low on context" disclaimers** — wastes the very tokens you're worried about.
- **Re-reading files you already have in context** — check your conversation first.
