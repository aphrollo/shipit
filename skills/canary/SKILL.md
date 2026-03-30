---
name: canary
description: After deploying to production — monitor for errors, performance degradation, and health check failures over a soak period. Triggers rollback if thresholds breached.
---

# Canary — Post-Deploy Soak Monitoring

**A single health check is not enough. Monitor the deploy for 5-10 minutes under real traffic.**

## When to Run

- After /ship deploys to production
- After infrastructure changes
- After database migrations

## Protocol

### 1. Start Soak Monitor

Run a monitoring loop via Bash tool:

```bash
# Monitor for 5 minutes, check every 60 seconds
for i in $(seq 1 5); do
  echo "=== Check $i/5 ($(date)) ==="

  # Health check
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://YOUR_DOMAIN/api/health)
  echo "Health: $HTTP_CODE"

  # Response time
  TTFB=$(curl -s -o /dev/null -w "%{time_starttransfer}" https://YOUR_DOMAIN/api/status)
  echo "TTFB: ${TTFB}s"

  # Error log check
  ERROR_COUNT=$(journalctl -u SERVICE_NAME --since "1 min ago" --no-pager 2>/dev/null | grep -c "ERROR" || echo 0)
  echo "Errors in last minute: $ERROR_COUNT"

  # Fail fast
  if [ "$HTTP_CODE" != "200" ]; then
    echo "CANARY FAILED: Health check returned $HTTP_CODE"
    break
  fi

  sleep 60
done
```

### 2. Playwright Smoke Test (optional, for frontend deploys)

```javascript
const { chromium } = require('playwright');
const browser = await chromium.launch({ headless: true });
const page = await browser.newPage();

const errors = [];
page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });

await page.goto(URL, { waitUntil: 'networkidle' });
const title = await page.title();

console.log('Title:', title);
console.log('Console errors:', errors.length);
if (errors.length) console.log('Errors:', errors);
await browser.close();
```

## Failure Thresholds

| Signal | Threshold | Action |
|--------|-----------|--------|
| Health check non-200 | Any occurrence | ROLLBACK |
| TTFB > 2x baseline | 2 consecutive checks | ALERT |
| Error log spike | > 10 errors/minute | ALERT |
| Console JS errors | Any new error | ALERT |

## Rollback

If canary fails:
```bash
# Revert to previous build (adapt paths to your project)
git checkout HEAD~1 -- <binary-or-build-output>
sudo systemctl restart <service-name>
# Verify recovery
curl -s https://<YOUR_DOMAIN>/api/health
```
Set YOUR_DOMAIN, service name, and binary path from project's CLAUDE.md or environment.

## Output

```
SOAK DURATION: [minutes]
HEALTH CHECKS: [pass/fail per check]
TTFB TREND: [values over time]
ERROR COUNT: [total new errors]
VERDICT: HEALTHY / DEGRADED / ROLLBACK
```

## Next → /cip
