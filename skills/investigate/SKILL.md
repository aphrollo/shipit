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

## Routing After

- Simple implementation fix → /plan → /build
- Design flaw requiring behavior/interface change → /reframe
- Hotfix → verbal /plan (30s) → /build
