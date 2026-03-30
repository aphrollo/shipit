---
name: ship
description: When /review passes — run pre-flight checks (lint, tests, git status), build, deploy (only on user approval), and post-deploy verification. Requires Bash tool evidence.
---

# Ship

**Gate: Health check passes (if deploying). Pre-flight always required. VERIFIED by showing Bash tool output.**

## Pre-flight (always)

```bash
# 1. Run language-appropriate lint + tests (must show tool output)
# 2. Verify git status shows only intentional changes
# 3. Check for accidentally staged files (.env, credentials, binaries)
```

## Deploy (only when user explicitly approves)

Dev server for testing. Production only on explicit user approval.

### After deploy:
- [ ] Health check endpoint returns OK
- [ ] Smoke test core functionality
- [ ] Check logs for errors (last 2 min)
- [ ] Verify dependent services still running

## Next → /canary (if deployed to production) or /cip
