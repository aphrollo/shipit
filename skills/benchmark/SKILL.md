---
name: benchmark
description: When shipping frontend changes — measure performance before and after. Captures Core Web Vitals, bundle size, request count, and TTFB. Blocks if regressions exceed thresholds.
---

# Benchmark — Performance Regression Detection

**Uses Playwright to capture real performance metrics from the running application.**

Playwright at `~/.claude/tools/node_modules/playwright`.

## Playwright Verification (run before any benchmark work)

```bash
node -e "require('playwright')" 2>/dev/null && echo "PLAYWRIGHT: OK" || echo "PLAYWRIGHT: MISSING"
ls ~/.cache/ms-playwright/chromium-*/chrome-linux/chrome 2>/dev/null && echo "CHROMIUM: OK" || echo "CHROMIUM: MISSING"
```

If either is MISSING: `cd ~/.claude/tools && npm install playwright && npx playwright install chromium`. If install fails after 2 attempts → use bundle-size-only fallback (no browser metrics).

## When to Run

- Before /ship for any frontend change
- After major dependency updates
- When user reports slowness

## Protocol

### 1. Capture Baseline (before changes, or from last known good)

```javascript
const { chromium } = require('playwright');
const browser = await chromium.launch({ headless: true });
const page = await browser.newPage();

await page.goto(URL, { waitUntil: 'networkidle' });

// Core Web Vitals via Performance API
const metrics = await page.evaluate(() => {
  const nav = performance.getEntriesByType('navigation')[0];
  const paint = performance.getEntriesByType('paint');
  const fcp = paint.find(p => p.name === 'first-contentful-paint');
  return {
    ttfb: nav.responseStart - nav.requestStart,
    fcp: fcp ? fcp.startTime : null,
    domContentLoaded: nav.domContentLoadedEventEnd,
    loadComplete: nav.loadEventEnd,
    transferSize: nav.transferSize,
    requestCount: performance.getEntriesByType('resource').length,
  };
});
console.log(JSON.stringify(metrics, null, 2));
```

### 2. Capture After (with changes)

Same script, same URL. Compare.

### 3. Bundle Size Check

```bash
# Check built asset sizes
du -sh web/assets/*.js web/assets/*.css 2>/dev/null
```

## Regression Thresholds

| Metric | Regression if | Block? |
|--------|--------------|--------|
| TTFB | > 50% increase OR > 500ms absolute | YES |
| FCP | > 50% increase OR > 2000ms absolute | YES |
| Bundle JS | > 25% increase | YES |
| Bundle CSS | > 25% increase | WARNING |
| Request count | > 50% increase | WARNING |
| DOM Content Loaded | > 50% increase | WARNING |

## Output

```
BASELINE: [metrics before]
CURRENT: [metrics after]
REGRESSIONS: [list with % change]
VERDICT: PASS / REGRESSED (list blockers)
```

## Baseline Storage

Save to `docs/.benchmark-baseline.json`. On first run: capture metrics, output `VERDICT: BASELINE CAPTURED`, save file. On subsequent runs: load baseline, compare, output PASS/REGRESSED.

For monorepos: save to `<package-root>/docs/.benchmark-baseline.json` (one baseline per package).

**Staleness:** Baselines older than 24 hours should be recaptured before comparing. Check file modification time before using.

## Fallback

If Playwright unavailable: check bundle sizes via `du -sh` on built assets. Compare against previous git commit's build. This catches bundle regressions without browser metrics.

## Next → /review (if in Performance route) or /ship
