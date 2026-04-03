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

## Code Hygiene

Self-documenting code is the goal. Comments are a last resort, not a default.

### Naming

- **Functions**: verb + domain noun. `parseInvoice`, `routeMessage`, `validateToken`. NOT `handleData`, `processItem`, `doWork`.
- **Variables**: reveal what it holds. `retryCount`, `userEmail`, `pendingOrders`. NOT `data`, `result`, `temp`, `val`, `info`. (`item` is fine when iterating a well-named collection.)
- **Booleans**: read as a question. `isExpired`, `hasPermission`, `shouldRetry`. NOT `flag`, `check`, `status`.
- **Match the codebase**: Before naming anything, read existing names in the file/module. Mirror the project's conventions, not your defaults.

### Comments — the 3 permitted uses

1. **WHY** — explain a non-obvious business rule or workaround. `// Stripe requires idempotency key for retries`
2. **TODO** — flag known incomplete work. `// TODO: handle pagination when > 100 results`
3. **PUBLIC API** — document exported functions/types that others consume.

Everything else is banned. No restating code. No section headers. No "Initialize variables" above variable declarations.

### Abstraction gate

- **One caller = inline (production code).** Do not extract a helper function until it has 2+ distinct call sites. Test helpers are exempt.
- **One implementation = no interface.** Do not create an interface/trait/protocol until a second implementation exists.
- **Thin wrappers = delete.** If a function only calls another function with the same or fewer args, inline it.

### Self-check at REFACTOR

Before leaving REFACTOR, scan your changes for: (1) any comment that restates code — delete it, (2) any variable named `data`/`result`/`info`/`temp`/`val` — rename it, (3) any production function with one caller — consider inlining.

## Scope Creep

If BUILD discovers changes not covered by PLAN (new DB schema, new API endpoint, different module) → **STOP**. Return to /plan, update scope, get approval, resume.

## Circuit Breaker

3 build cycles without tests passing → **STOP**. Escalate: "Build has failed 3 times. The approach or architecture may need rethinking." Return to /plan.

## File Size Discipline

Source files should stay under 500 LOC of logic. If a file grows past this, split it before proceeding to /review.

## Failure Paths

| Scenario | Detection | Severity | Recovery |
|----------|-----------|----------|----------|
| Tests fail after GREEN phase | Test runner output shows failures | Medium | Re-read failing test, check if implementation is incomplete. Fix and re-run. |
| Lint/vet errors after REFACTOR | Lint tool output | Low | Fix lint issues without changing behavior. Re-run tests. |
| Scope creep discovered | New DB schema, API endpoint, or module needed | High | STOP. Return to /plan. Do NOT expand scope inline. |
| Flaky test (passes sometimes) | Intermittent pass/fail on same code | High | Isolate flaky test, fix root cause (race condition, time dependency, shared state). Never ignore. |
| Build tool crash / environment issue | npm/go/cargo errors unrelated to code | Medium | Fix environment (install deps, clear cache). If persists after 2 attempts, escalate. |
| Implementation contradicts plan | Code requires different approach than planned | Medium | STOP. Return to /plan with findings. Update plan before continuing. |

## References

- `references/testing-anti-patterns.md` — common testing mistakes to avoid during RED/GREEN/REFACTOR

## Next → /deslop (--auto mode) → /qa (if UI/frontend changed) or /review
