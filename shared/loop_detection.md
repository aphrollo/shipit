# Loop Detection

**Detect stuck agents before circuit breakers trip. Circuit breakers catch "3 failures" — loop detection catches "3 identical failures."**

Industry data: agent loops only manifest in production (rate limits, transient errors, backpressure). Three detection techniques, applied at the orchestrator level.

---

## Technique 1: Fingerprinting

After each agent retry, hash the key output characteristics:

```
fingerprint = hash(agent_name + result_status + error_type + files_mentioned)
```

**Rule: 2 identical fingerprints in a row = likely stuck.**

If fingerprint[N] == fingerprint[N-1]:
- Don't count as a meaningful retry
- Change the approach before retrying:
  - Add more context to the agent prompt
  - Override model up (haiku → sonnet → opus)
  - Narrow the scope
- If fingerprint[N] == fingerprint[N-1] == fingerprint[N-2]: STOP immediately. Don't wait for circuit breaker.

---

## Technique 2: Sliding Window (within agent execution)

Track tool calls reported by agents in their output. If an agent reports:
- Same tool + same arguments appearing >5 times → agent is in a loop
- A-B-A-B alternating pattern in last 6 actions → oscillation detected

**Action on detection:**
- Flag to orchestrator: "LOOP_DETECTED: agent [name] is repeating [pattern]"
- Orchestrator terminates the agent and retries with modified prompt: "Your previous attempt entered a loop doing [pattern]. Take a different approach."

---

## Technique 3: Progress Tracking

Between retries, check if the agent made any forward progress:

```
Progress indicators:
- Builder: did test count change? did any new files appear?
- Reviewer: did finding count change? are findings about different code?
- Architect: did the plan change? are different files mentioned?
- Researcher: did new findings appear? are different files cited?
```

**No progress after retry = stuck.** Don't count it as a real retry against the circuit breaker limit. Instead:
1. Change the approach (more context, different model, narrower scope)
2. If still no progress → escalate immediately, don't waste the third retry

---

## Integration with Circuit Breakers

Loop detection works WITH circuit breakers, not instead of them:

```
Agent fails → Check fingerprint
  ├─ New fingerprint → Real failure. Count toward circuit breaker. Retry normally.
  └─ Same fingerprint → Stuck loop. Do NOT count toward breaker.
       ├─ Change approach (context/model/scope), retry once
       └─ Still same fingerprint → STOP immediately. Escalate.
```

This means:
- Circuit breaker trips after 3 REAL failures (different approaches, different errors)
- Loop detection catches 3 IDENTICAL failures faster (stops at 2, not 3)
- Combined: faster detection of stuck states + full retry budget for genuine issues

---

## Orchestrator Implementation

The orchestrator maintains a retry log per agent:

```
retry_log = {
  "builder": [
    { "attempt": 1, "fingerprint": "abc123", "progress": true, "timestamp": "..." },
    { "attempt": 2, "fingerprint": "abc123", "progress": false, "timestamp": "..." }
  ]
}
```

After each agent return:
1. Compute fingerprint
2. Compare to previous fingerprint (if any)
3. Check progress indicators
4. Decide: retry normally, retry with changes, or STOP

This is lightweight — no external infrastructure needed. Just in-memory tracking in the orchestrator session.
