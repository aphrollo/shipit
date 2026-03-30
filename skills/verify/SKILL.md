---
name: verify
description: Global evidence hook — active in ALL phases, ALL projects. No stage marks itself done without Bash/Agent tool-call evidence. Prevents claiming success without running verification commands.
---

# Verify — Evidence Before Completion

**No stage marks itself DONE without running its verification command via a tool call and showing the actual tool output.**

## Required Evidence

- BUILD: Bash tool running tests → show PASS/FAIL with counts
- REVIEW: Agent tool spawning subagents → show verdicts
- SHIP: Bash tool running health check → show response

## Enforcement

**Verification MUST come from tool calls, not free text.** The conversation log records every Bash and Agent tool invocation. Evidence is the tool output block, not text the agent types. If there is no Bash tool call running tests, the tests were not run.

## Banned Phrases (until tool evidence shown)

- "Should work now"
- "Tests should pass"
- "Looks correct"
- "I believe this fixes it"
- "All tests pass" (without preceding Bash tool call)

**Show the tool output. Not a summary. The actual output.**
