---
name: context
description: Context window management — monitor usage, compact proactively, avoid the "agent dumb zone" where performance degrades. Use when context is getting large or switching tasks mid-session.
---

# Context — Window Management

**Context is finite. Manage it or watch quality degrade.**

## The Agent Dumb Zone

Claude's output quality degrades as the context window fills up. At ~80% capacity, responses become less precise, instructions get missed, and the agent starts making mistakes it wouldn't make with a fresh context. This is the "agent dumb zone."

## Rules

### 1. Monitor Context Usage

Watch the token count in the status bar. Know where you are:
- **< 50%**: Safe. Work normally.
- **50-70%**: Caution. Consider compacting if switching tasks or starting a new phase.
- **70-80%**: Compact now. Run `/compact` before starting any new work.
- **> 80%**: Danger zone. Quality is degrading. `/compact` immediately or `/clear` if switching tasks.

### 2. Compact at Phase Transitions

The best time to compact is between phases in the workflow:
- After Researcher finishes → compact before Architect starts
- After Architect's plan is approved → compact before Builder starts
- After Builder finishes → compact before Reviewer starts
- After review findings are resolved → compact before Deploy

The orchestrator should compact between agent dispatches when context exceeds 50%.

### 3. Clear When Switching Tasks

If you're done with one task and starting a completely different one, `/clear` is better than `/compact`. A compacted context of Task A will pollute Task B's context with irrelevant information.

### 4. Rename Sessions

Use `/rename` to name sessions before switching away. This makes `/resume` useful — you can find the session by name later instead of scrolling through unnamed sessions.

## For Orchestrator Integration

When the orchestrator dispatches agents, it should check context usage between phases:
- If > 50%: Run `/compact` before spawning the next agent
- If > 80%: Consider whether remaining phases can fit, or split into a new session
- Subagents get fresh context windows, so the main concern is the orchestrator's own window

## Anti-Patterns

- **Don't hoard context.** Reading 20 files "just in case" wastes tokens. Read what you need.
- **Don't re-read files you already read.** Use the information from the first read.
- **Don't paste full file contents when a summary would do.** Be concise in agent prompts.
- **Don't ignore the status bar.** If you can't see it, ask about context usage.
