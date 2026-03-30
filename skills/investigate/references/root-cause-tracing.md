# Root Cause Tracing: Backward Call-Stack Analysis

Trace backwards from the error through each layer until you find where the fix belongs. Fix at the deepest level possible.

## Technique

Start from the visible symptom. At each level, answer three questions:
1. What was called?
2. What did it expect vs. what did it receive?
3. Why is that wrong?

Move to the next level only if the current level is a victim, not the cause.

## 5-Level Trace Format

### Level 0: Error message / symptom
The observable failure. Copy the exact error message, stack trace, or incorrect output.

```
Example: "TypeError: Cannot read property 'id' of undefined at UserService.getProfile()"
```

### Level 1: Direct caller -- what function triggered it?
Find the immediate caller in the stack trace. What arguments did it pass?

```
Example: getProfile() was called with user=undefined by AuthMiddleware.validateSession()
```

### Level 2: Data source -- where did the bad input come from?
Trace the bad value to where it was produced. What function returned it? What query fetched it?

```
Example: validateSession() got user from SessionStore.lookup(token), which returned undefined
```

### Level 3: State mutation -- what changed the state?
Something modified the state between when it was correct and when it became wrong. What wrote to the session store? What invalidated the cache?

```
Example: SessionStore.cleanup() ran a sweep that deleted sessions older than 30min,
but the TTL was calculated using server time (UTC) while sessions were stamped with local time
```

### Level 4: Root cause -- what originally caused the incorrect state?
The originating defect. This is where your fix belongs.

```
Example: Session creation in login() uses Date.now() (local) but cleanup uses
moment.utc(). Fix: standardize on UTC timestamps in session creation.
```

## Rules

- **Stop when you find the fix level.** Not every trace goes to Level 4. If Level 2 reveals a missing null check, fix it there.
- **Document each level even if you skip ahead.** The trace is your proof that you found the real cause, not a symptom.
- **Never fix at Level 0.** Catching the error or suppressing the message hides the bug.
- **If Level 4 is in a dependency you don't control,** fix at the highest level you own and add a defensive guard.

## Applying the Trace

```
[Symptom] --> [Direct Caller] --> [Data Source] --> [State Mutation] --> [Root Cause]
   L0              L1                 L2                 L3                L4
                                                                          ^
                                                                     Fix here
```

Walk the chain backward. The fix goes at the deepest level you can reach. Add a guard one level above as insurance.
