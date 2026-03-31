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
1. **Suggest `/deploy`** if a deploy platform is detected in the project (requires user approval — never auto-deploy)
2. **Auto-run `/document-release`** to audit documentation for staleness (no approval needed — docs audit is non-destructive)

**Note:** `/cip` is invoked by the orchestrator after the full workflow completes — NOT here. Ship does not invoke CIP. This prevents double-invocation.

## Failure Paths

| Scenario | Detection | Severity | Recovery |
|----------|-----------|----------|----------|
| Tests fail on pre-flight | Test runner output | High | Return to /build. Do NOT ship with failing tests. |
| Accidentally staged secrets | .env, credentials, API keys in git status | Critical | Unstage immediately. If already committed, rewrite history. Alert user. |
| Lint fails on pre-flight | Lint tool output | Medium | Fix lint issues. Re-run pre-flight. |
| Build fails | Compile/bundle errors | High | Return to /build. Investigate build failure. |
| Health check fails after deploy | Non-200 response | High | Offer rollback. Check logs. Do NOT proceed to canary. |

## Next → /canary (if deployed to production). CIP is handled by orchestrator.
