---
name: learn
description: When discovering a non-obvious pattern, pitfall, or architectural decision during any phase — persist it for future sessions. Also use to recall learned patterns before starting work on a familiar module.
---

# Learn — Cross-Session Persistence

**Persist lessons so future sessions don't repeat mistakes or rediscover patterns.**

## When to Save

- Bug caused by a non-obvious interaction (e.g., "postgres tests wipe prod DB if using same DATABASE_URL")
- Architectural decision with rationale (e.g., "store enrichment is sequential because CCU shares API rate limiter")
- Pattern that works for this codebase (e.g., "air must be started from project root, not frontend/")
- User preference discovered during work (e.g., "dev first, prod only when user approves")

## How to Save

**Before saving, state the evidence.** Learnings without evidence are hypotheses — label them as such. Present the learning to the user before persisting: "I'd like to save this learning: [text]. OK?"

Write to the project's memory system (`~/.claude/projects/*/memory/`) or the project's CLAUDE.md:

```
LEARNING: [one sentence — the fact]
CONTEXT: [why this matters — what went wrong or what decision was made]
APPLIES TO: [which module/phase/scenario]
```

## When to Recall

Before starting work on a module, check:
1. Memory files for relevant learnings
2. CLAUDE.md for project-specific rules
3. Git blame for recent changes and their commit messages

## What NOT to Save

- Standard practices documented elsewhere
- Ephemeral task state (use tasks, not memory)
- Code patterns derivable from reading the code
- Git history (use git log)

## Recall Validation

When recalling a learning, verify it's still true before applying. If tool output contradicts a stored learning, surface the conflict: "Stored learning says X, but current evidence shows Y. Updating."

## Pruning

If a learning is no longer true (code changed, decision reversed), delete or update it. Stale learnings are worse than no learnings.
