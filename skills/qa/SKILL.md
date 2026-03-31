---
name: qa
description: When frontend changes are complete — run real browser testing via Playwright. Visits pages, checks console errors, tests interactions, verifies responsive layout. Catches bugs unit tests miss.
---

# QA — Browser Testing

**Uses Playwright (headless Chromium) to test the actual running application.**

Playwright is installed at `~/.claude/tools/node_modules/playwright`. Chromium at `~/.cache/ms-playwright/`.

## Playwright Verification (run before any QA work)

```bash
# Check Playwright is installed and Chromium is available
node -e "require('playwright')" 2>/dev/null && echo "PLAYWRIGHT: OK" || echo "PLAYWRIGHT: MISSING"
ls ~/.cache/ms-playwright/chromium-*/chrome-linux/chrome 2>/dev/null && echo "CHROMIUM: OK" || echo "CHROMIUM: MISSING"
```

If either is MISSING, install before proceeding:
```bash
cd ~/.claude/tools && npm install playwright && npx playwright install chromium
```

If install fails after 2 attempts → fall back to manual testing checklist. Do NOT skip QA.

## When to Run

- After /build for any frontend change
- After /review for full-stack features
- Before /ship for production deploys

## Protocol

Write and execute a Playwright test script via Bash tool. The script should:

### 1. Page Load Check
```javascript
const { chromium } = require('playwright');
const browser = await chromium.launch({ headless: true });
const page = await browser.newPage();

// Collect console errors
const errors = [];
page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });

await page.goto(URL);
await page.waitForLoadState('networkidle');
```

### 2. Console Error Audit
```javascript
// After page loads, check for JS errors
if (errors.length > 0) {
  console.log('FAIL: Console errors found:', errors);
}
```

### 3. Visual Verification
```javascript
// Screenshot for manual review
await page.screenshot({ path: '/tmp/qa-screenshot.png', fullPage: true });
```

### 4. Interactive Testing
```javascript
// Test key interactions: click, type, navigate
await page.click('selector');
await page.fill('input[name=search]', 'test query');
await page.keyboard.press('Enter');
```

### 5. Responsive Check
```javascript
// Test at mobile, tablet, desktop viewports
for (const width of [320, 768, 1920]) {
  await page.setViewportSize({ width, height: 900 });
  await page.screenshot({ path: `/tmp/qa-${width}.png` });
}
```

### 6. Network Error Check
```javascript
// Monitor for failed requests
page.on('requestfailed', req => {
  console.log('FAIL: Request failed:', req.url(), req.failure().errorText);
});
```

## Output

```
PAGES TESTED: [list]
CONSOLE ERRORS: [count — list if any]
NETWORK ERRORS: [count — list if any]
RESPONSIVE: [pass/fail per viewport]
INTERACTIONS: [pass/fail per test]
SCREENSHOTS: [paths]
VERDICT: PASS / FAIL
```

## Circuit Breaker

3 QA cycles without PASS → STOP. Escalate: "QA has failed 3 times. The approach may need rethinking." Return to /plan.

## Fallback

If Playwright fails to launch or crashes: run `npm install playwright && npx playwright install chromium` in `~/.claude/tools/`. If still fails, perform manual testing checklist. Do NOT mark QA as passed without evidence.

## Key Rule

QA tests the RUNNING app, not the code. Start the dev server (or use prod URL), then test against it. If the server isn't running, start it first.

## Next → /review
