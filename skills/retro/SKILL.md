---
name: retro
description: Weekly retrospective — analyze commits, review patterns, identify improvements. Run at the end of a sprint or week to reflect on what shipped, what slowed us down, and what to improve.
---

# Retro — Weekly Retrospective

**At the end of a sprint or week, analyze what happened and capture improvements.**

## When to Run

- End of week / sprint
- After a major feature ships
- After an incident or production issue
- When user asks "what did we ship?" or "how did the week go?"

## Process

### 1. Gather Data (automated)

Run these commands to collect metrics:

```bash
# Commits this week (or specified period)
git log --since="1 week ago" --oneline --stat

# Files most frequently changed
git log --since="1 week ago" --name-only --pretty=format: | sort | uniq -c | sort -rn | head -20

# Contributors
git log --since="1 week ago" --format="%an" | sort | uniq -c | sort -rn

# Lines changed
git diff --stat $(git log --since="1 week ago" --reverse --format="%H" | head -1)^..HEAD
```

### 1.5. Workflow Metrics (if available)

If `docs/.shipit-metrics.jsonl` exists, analyze it for the period:

```bash
# Count workflows and results
cat docs/.shipit-metrics.jsonl | jq -r '.result' | sort | uniq -c

# Average duration
cat docs/.shipit-metrics.jsonl | jq '.duration_minutes' | awk '{sum+=$1; n++} END {print sum/n " avg minutes"}'

# Most common failure agent
cat docs/.shipit-metrics.jsonl | jq -r '.gate_failures | keys[]' 2>/dev/null | sort | uniq -c | sort -rn

# Plan cache hit rate
cat docs/.shipit-metrics.jsonl | jq -r '.plan_cache_hit' | sort | uniq -c
```

Key metrics to surface:
- **End-to-end success rate** over the period
- **Which agent fails most** and why
- **Plan cache effectiveness** (hit rate, success rate of cached plans)
- **Average retries per workflow** (trending up = prompt quality degrading)
- **Loop detection triggers** (if any, what caused them)

### 2. Analyze Patterns

From the commit data and workflow metrics, identify:
- **Shipping velocity**: How many features/fixes shipped?
- **Hotspot files**: Which files changed most? (potential refactor candidates)
- **Commit patterns**: Are commits atomic and well-described, or large and vague?
- **Test coverage trend**: Did test files grow proportionally to source files?
- **AI-assisted commits**: Count commits with `Co-Authored-By` to track AI collaboration ratio

### 3. The 5 Questions

1. **What shipped?** — List features, fixes, and improvements with commit refs
2. **What slowed us down?** — Blocked PRs, flaky tests, unclear requirements, tooling issues
3. **What almost went wrong?** — Near-misses caught by review, close calls, incidents averted
4. **What did we learn?** — Non-obvious patterns, architectural insights, process improvements
5. **What should we change?** — Concrete actions for next week (not vague "do better")

### 4. Output

```
RETRO: [date range]
REPO: [repo name]

SHIPPED:
- [feature/fix] ([commit hash]) — [one-line description]
- ...

METRICS:
- Commits: [N]
- Files changed: [N]
- Lines added/removed: +[N] / -[N]
- AI-assisted commits: [N] / [total] ([%])
- Hotspot files: [top 3 most-changed files]

VELOCITY: [assessment — accelerating, steady, slowing]
HEALTH: [assessment — improving, stable, degrading]

FRICTION:
- [what slowed us down]

NEAR MISSES:
- [what almost went wrong]

LEARNINGS:
- [what we learned] → /learn if worth persisting

ACTIONS:
- [concrete change for next week]
```

### 5. Persist

- If learnings are non-obvious → invoke `/learn` to persist cross-session
- If process changes are needed → note in project CLAUDE.md
- If a skill needs updating → note for `/writing-skills`

## Modes

- **Standard**: Single repo retrospective (default)
- **Global**: Scan all git repos in home directory, aggregate metrics across projects
- **Compare**: Side-by-side with a prior retro (if saved)

## Rules

- Be honest, not cheerful. If the week was slow, say so.
- Metrics are facts, not judgments. Let the numbers speak.
- Actions must be specific and achievable in one week.
- Don't pad the retro — if nothing to improve, say "none needed."
