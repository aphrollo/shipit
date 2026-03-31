---
name: cip
description: After completing any task through the workflow — capture what worked, what didn't, and what to improve. Continuous Improvement Process. Runs automatically at the end of every workflow.
---

# CIP — Continuous Improvement Process

**The workflow improves itself. After every completed task, spend 30 seconds capturing learnings.**

## When to Run

Automatically after /ship or /canary completes. Also after failed tasks (escalated bugs, abandoned spikes).

## The 3 Questions (30 seconds)

Check `docs/.shipit-metrics.jsonl` for data to inform your answers (if it exists):

1. **What slowed us down?** (phase that took too long, missing context, wrong classification, false positive in review) — Check agent durations and retry counts in metrics.
2. **What almost went wrong?** (bug caught by review that should have been caught by tests, scope creep discovered late, destructive command that /careful blocked) — Check gate_failures and loop_detected flags.
3. **What should change?** (new /learn entry, skill update needed, classification rule missing, checklist item to add) — Check per-agent success rates and plan cache hit rate.

## Actions

- **New learning discovered** → Invoke /learn to persist it (with evidence + user confirmation)
- **Skill gap found** → Note it. Invoke /writing-skills to create or fix the skill when time allows.
- **Classification was wrong** → Check if /router needs a new row or rule
- **Review found real bugs** → Check if /build TDD coverage was insufficient. Were the test cases in /plan too weak?
- **Nothing to improve** → That's fine. Most tasks are routine. Only capture non-obvious insights.

## Output

```
TASK: [what was done]
DURATION: [actual vs benchmark]
WORKFLOW FRICTION: [what slowed things down, if anything]
NEAR MISSES: [what almost went wrong]
IMPROVEMENT: [specific action, or "none needed"]
```

## Key Rule

CIP is lightweight — 30 seconds, not 30 minutes. If you're writing paragraphs, you're over-doing it. One learning per task is plenty. Most tasks produce "none needed" and that's correct.

**The goal: the workflow gets 1% better every day, compounding over weeks.**
