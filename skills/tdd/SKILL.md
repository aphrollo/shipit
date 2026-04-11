---
name: tdd
description: Implement any non-trivial change using a strict red-green-refactor loop. Auto-activate when the user asks to implement a feature, fix a bug of real substance, or picks up a vertical-slice issue. Forces test-first discipline, deep module design, and incremental refactoring. Do NOT activate for trivial changes (typos, one-line fixes, formatting) or for changes to test files alone.
---

# TDD

Test-Driven Development: write a failing test, make it pass with the smallest possible change, refactor, repeat. This is the default implementation mode for any change that has real behavior.

## The loop

1. **RED.** Write one failing test for the next smallest behavior. Run it. Confirm it fails for the expected reason.
2. **GREEN.** Write the smallest code change that makes the test pass. No extra features, no speculative generality, no cleanup.
3. **REFACTOR.** With all tests green, look for duplication, unclear names, shallow modules, leaking abstractions. Fix them without changing behavior. Run tests after every refactor step.
4. **REPEAT** until every acceptance criterion has a passing test.

Never write production code without a failing test pointing at it. Never add a second failing test before the first one is green.

## Before you start

1. **Confirm which behaviors to test.** Read the PRD or issue. Extract the acceptance criteria. Each criterion becomes at least one test.
2. **Design interfaces for testability.** Before writing the first test, sketch the public surface of the thing you are building. Keep the interface thin. Push complexity down, not out.
3. **Prefer deep modules.** A deep module has a simple interface over substantial functionality. A shallow module has a wide interface over trivial functionality. When you have a choice, deepen.

## Rules on mocking

- Mock at the boundaries of the system (HTTP, filesystem, clock, randomness, external services). Never mock your own domain types.
- If a test needs to mock many collaborators inside your own code, the design is wrong. Refactor the design, not the test.
- Prefer fakes and in-memory implementations over mock-call assertions. Verify behavior, not interactions.

## Rules on refactoring

- Refactor only when the bar is green. Never refactor on red.
- After every refactor step, run the tests. If they break, revert that step and try smaller.
- Extract a pure function only when there is a real caller that benefits. Do not extract "for testability" — if a function is hard to test in place, the design around it is wrong.
- Rename aggressively. A variable called `data`, `result`, `temp`, `val`, or `info` is a refactoring opportunity.

## Rules on scope

- One failing test at a time. If you discover a second bug mid-loop, write it down, finish the current loop, then start a new one.
- Do not mix refactoring commits with feature commits. Separate the two.
- When the acceptance criteria are all green and the code is clean, stop. Do not add extra features that were not in the issue.

## What "done" looks like

- Every acceptance criterion has at least one test that would fail if the criterion were broken
- All tests pass
- Coverage of the changed lines is deliberate — you can name each untested branch and justify why
- The diff is small, focused, and would read cleanly in code review
- No `data`, `result`, `temp`, `val`, `info`, or similarly lifeless names anywhere in the new code
