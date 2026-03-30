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

## Post-Ship Automation

After pre-flight checks pass and code is ready:
1. **Auto-suggest `/deploy`** if a deploy platform is detected in the project
2. **Auto-invoke `/document-release`** to audit documentation for staleness
3. **Auto-invoke `/cip`** for continuous improvement (already mandatory)

This chain ensures: ship → deploy → document → improve.

## Next → /canary (if deployed to production) or /cip
