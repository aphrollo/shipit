---
name: deslop
description: Clean up AI-generated code slop — remove dead code, redundant comments, unnecessary abstractions, over-engineering, and bloat. Use after /build or when code feels "AI-written."
---

# Deslop — AI Code Cleanup

**AI-generated code has predictable failure modes. This skill finds and fixes them.**

## Pipeline Position

**Automatic:** Runs after /build and before /review in `--auto` mode. The orchestrator invokes this automatically — no manual trigger needed. This ensures the reviewer sees clean code, not raw AI output.

**Manual:** Can also be invoked standalone at any time.

## When to Use

- **Automatic (in pipeline):** After every /build, before /review. Runs in `--auto` mode (no approval needed).
- **Manual:** When reviewing AI-written code that's technically correct but bloated
- **Manual:** User says "deslop", "clean this up", "simplify", "too much code"
- **Manual:** As part of /review when the reviewer flags unnecessary complexity

## The 11 Code Slop Patterns

| # | Pattern | What to look for |
|---|---------|-----------------|
| 1 | Defensive over-coding | Try/catch around code that can't throw. Null checks on non-nullable values. Validation of internal state that's already validated upstream. |
| 2 | Premature abstraction | Interfaces with one implementation. Abstract base classes for one subclass. Factory functions that create one thing. Generic type parameters used once. |
| 3 | Comment narration | Comments that restate the code. `// increment counter` above `counter++`. JSDoc on obvious getters/setters. |
| 4 | Dead code | Unused imports, unreachable branches, commented-out code, unused variables, unused functions. |
| 5 | Wrapper functions | Functions that just call another function with the same arguments. Thin wrappers that add no logic. |
| 6 | Over-logging | Logging every function entry/exit. Logging values that are already visible in error messages. Debug logs left in production code. |
| 7 | Config theater | Environment variables for values that never change. Feature flags for features that are always on. Constants files with one constant. |
| 8 | Type ceremony | Explicit types where inference works. Interface for every object literal. Type aliases that just rename primitives. |
| 9 | Error message novels | Multi-paragraph error messages. Errors that explain the architecture. Stack traces in user-facing messages. |
| 10 | Test scaffolding bloat | beforeEach/afterEach that could be inline setup. Shared fixtures for tests that don't share state. Helper functions used once. |
| 11 | Generic naming | Variables named `data`/`result`/`temp`/`val`/`info`/`flag`/`check`/`status`. Functions named handleX/processX/doX without domain nouns (except framework-idiomatic handlers like handleClick/handleSubmit). Booleans that don't read as questions. Lower weight for `result` in test assertion code. Renaming is permitted under the no-add rule. |

## Process

### 1. Scan

Read the changed files and score each slop pattern (0 = none, 1 = minor, 2 = significant, 3 = pervasive).

### 2. Report

```
DESLOP SCAN

FILES: [list]
TOTAL SLOP SCORE: [sum] / 33

FINDINGS:
- [pattern name]: [score] — [specific example with file:line]
- ...

RECOMMENDED FIXES: [N]
```

### 3. Fix (if approved)

- One commit per fix category (not per line)
- Run tests after each commit
- Don't change behavior — only remove unnecessary code
- If removing code changes behavior, flag it and ask

### Modes

- **Default**: Scan + report + fix (with approval)
- **--review**: Scan + report only (no fixes)
- **--auto**: Scan + fix without asking (for post-build cleanup in the pipeline)

## Rules

- Never add code during deslop. Only remove or simplify.
- If you're unsure whether code is dead, grep for usage before removing.
- Don't deslop test code more aggressively than production code.
- Preserve intentional defensive coding in security-sensitive areas.
- Three similar lines is NOT slop — it's clearer than a premature abstraction.
