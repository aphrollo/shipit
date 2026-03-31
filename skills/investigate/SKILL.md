---
name: investigate
description: When encountering a bug, error, crash, test failure, or unexpected behavior — find root cause before proposing any fix. Mandatory for tasks containing fix, bug, broken, error, crash, or why.
---

# Investigate

**NEVER propose a fix without completing investigation. No exceptions.**

## Protocol

1. **REPRODUCE**: Trigger the bug. Read the error message completely.
2. **TRACE**: Follow the data flow from input to error. Read the code — don't guess.
3. **HYPOTHESIZE**: Form ONE specific hypothesis. "X fails because Y when Z."
4. **VERIFY**: Test the hypothesis minimally. Add a log, check a value. Don't fix yet.
5. **ROOT CAUSE**: State in one sentence. This is the gate.

## Rules

- **No fix without root cause.** Understanding the problem IS the fix.
- **Read before theorizing.** Open the file. Read the function. THEN hypothesize.
- **One hypothesis at a time.** No shotgunning 5 changes.
- **3 failed fixes → STOP.** Architecture is wrong, not implementation. Escalate to user.
- **Write regression test BEFORE fixing.** Fails now, passes after fix.

## Mandatory Output (before BUILD proceeds)

```
ROOT CAUSE: [one sentence]
EVIDENCE: [what proves it]
FIX: [proposed change]
REGRESSION TEST: [what test to write]
```

If you can't fill ROOT CAUSE and EVIDENCE, you haven't finished investigating.

## Hotfix Mode (prod is down)

Abbreviated: REPRODUCE + ROOT CAUSE only. Skip TRACE/HYPOTHESIZE/VERIFY when the cause is obvious from the stack trace. Still requires the mandatory output block. Target: < 2 minutes.

## Failure Paths

| Scenario | Detection | Severity | Recovery |
|----------|-----------|----------|----------|
| Cannot reproduce bug | Steps don't trigger error locally | Medium | Check environment differences (versions, config, data). Ask user for exact reproduction steps. |
| Root cause unclear after 3 hypotheses | 3 VERIFY steps all disprove hypothesis | High | STOP. Escalate: "Cannot isolate root cause after 3 hypotheses. Need more context or a different perspective." |
| Bug is in dependency, not our code | Trace leads outside project boundary | Medium | Document which dependency and version. Check for known issues/CVEs. Evaluate: patch, workaround, or upgrade. |
| Multiple root causes | Fix one issue reveals another | High | Document all root causes. Return to /plan with full list. Fix in priority order. |
| Flaky/intermittent bug | Reproduces sometimes but not consistently | High | Add logging/instrumentation to capture state on next occurrence. Check for race conditions, timing, shared state. |
| Stack trace points to wrong location | Error originates upstream of reported location | Medium | Trace data flow backward from error. The symptom is not the cause. |

## Routing After

- Simple implementation fix → /plan → /build
- Design flaw requiring behavior/interface change → /reframe
- Hotfix → verbal /plan (30s) → /build
