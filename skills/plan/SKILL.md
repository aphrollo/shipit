---
name: plan
description: When requirements are clear (after /reframe or /investigate) — define files to change, test cases, order of operations, and risk assessment. Gate: user approval before /build.
---

# Plan

**Gate: User approves the plan. Do NOT auto-approve. Do NOT proceed without explicit approval.**

## Produce

1. **Files to change** (list with one-line description each)
2. **Test cases** (specific behaviors to test — not "add tests")
3. **Order of operations** (what to build first)
4. **Risk check**: Shared state? Database schema? Public API? Breaking changes? Secrets?

## Large Changes (20+ files)

Break into staged milestones with intermediate reviews. Don't try to do everything in one pass.

## Next → /build
