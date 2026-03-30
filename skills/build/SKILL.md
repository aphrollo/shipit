---
name: build
description: When implementing code changes — enforce TDD (RED → GREEN → REFACTOR) with language-appropriate tooling. Requires Bash tool evidence of passing tests before proceeding to /review.
---

# Build

**Gate: All tests pass. Lint/vet clean. VERIFIED by running commands via Bash tool and showing actual output.**

## Language Tools

- **Go**: `go vet ./...` + `go test ./... -count=1`
- **JS/TS**: `npm run lint` + `npm test`
- **Python**: `ruff check .` + `pytest`
- **Rust**: `cargo clippy` + `cargo test`

## TDD Iron Rule: RED → GREEN → REFACTOR

1. **RED**: Write one test. Run it. Must FAIL because behavior isn't implemented — not syntax error or trivial assertion.
2. **GREEN**: Write minimal code to pass.
3. **REFACTOR**: Clean up while green.

## Exceptions

- Docs-only: no RED phase, run existing tests
- Config: no new tests, verify existing pass
- Trivial typo: no new tests unless logic change

## Speed

Write test + implementation in same step when behavior is obvious AND implementation didn't previously exist.

## Scope Creep

If BUILD discovers changes not covered by PLAN (new DB schema, new API endpoint, different module) → **STOP**. Return to /plan, update scope, get approval, resume.

## File Size Discipline

Source files should stay under 500 LOC of logic. If a file grows past this, split it before proceeding to /review.

## Next → /qa (if UI/frontend changed) or /review
