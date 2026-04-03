---
name: visual-qa
description: Screenshot-based visual QA — capture pages, score against design specs, detect visual regressions. Uses Playwright screenshots for evidence-based UI verification.
---

# Visual QA — Screenshot-Based UI Verification

**Don't trust that UI changes look right. Screenshot them and verify.**

## Playwright Verification (run before any visual QA work)

```bash
node -e "require('playwright')" 2>/dev/null && echo "PLAYWRIGHT: OK" || echo "PLAYWRIGHT: MISSING"
ls ~/.cache/ms-playwright/chromium-*/chrome-linux64/chrome 2>/dev/null && echo "CHROMIUM: OK" || echo "CHROMIUM: MISSING"
curl -s http://127.0.0.1:9222/json/version | head -1 && echo "CDP: OK" || echo "CDP: DOWN (will use standalone launch)"
```

If either is MISSING: `cd ~/.claude/tools && npm install playwright && npx playwright install chromium`. If install fails after 2 attempts → escalate to user. Visual QA without screenshots is not visual QA.

## When to Use

- After /build when UI changes were made
- After /qa to verify visual appearance (not just functionality)
- When comparing before/after for visual regressions
- When verifying against DESIGN.md specifications

## Process

### 1. Capture Baseline (before changes)

If a baseline exists (previous screenshots), use it. If not, capture the current state before making changes.

```javascript
const { chromium } = require('playwright');
let browser, usedCDP = false;
try {
  browser = await chromium.connectOverCDP('http://127.0.0.1:9222');
  usedCDP = true;
} catch (e) {
  browser = await chromium.launch({ headless: true });
}
const context = await browser.newContext();
const page = await context.newPage();

// Capture at key breakpoints
for (const width of [375, 768, 1280]) {
  await page.setViewportSize({ width, height: 900 });
  await page.goto(url);
  await page.screenshot({ path: `baseline-${width}.png`, fullPage: true });
}
// Cleanup: await context.close(); if (!usedCDP) await browser.close();
```

### 2. Capture Current State (after changes)

Same screenshots at the same breakpoints.

### 3. Compare and Score

For each screenshot pair, evaluate:

| Criteria | Weight | What to check |
|----------|--------|--------------|
| Layout integrity | 30% | Elements in correct positions, no overlap, proper spacing |
| Typography | 20% | Font sizes, weights, line heights match DESIGN.md |
| Color accuracy | 15% | Colors match palette, contrast passes WCAG AA |
| Responsive behavior | 15% | Layout adapts correctly across breakpoints |
| Content completeness | 10% | All content visible, no clipping, no overflow |
| Visual polish | 10% | Alignment, consistency, no artifacts |

**Score**: 0-100 per page per breakpoint.
- **90+**: Pass
- **70-89**: Minor issues, flag but don't block
- **< 70**: Fail — needs fixes before shipping

### 4. Output

```
VISUAL QA RESULT: PASS | FAIL

PAGES TESTED: [N]
BREAKPOINTS: 375px, 768px, 1280px

| Page | Mobile | Tablet | Desktop | Score |
|------|--------|--------|---------|-------|
| [page] | [score] | [score] | [score] | [avg] |

ISSUES:
- [page] @ [breakpoint]: [description] — [severity]

SCREENSHOTS: [paths to captured images]
```

### 5. Evidence

Use the Read tool to show screenshots to the conversation. Visual QA without showing the screenshots is not QA — it's guessing.

## Integration

- Runs after /qa (functional testing) and before /review
- If DESIGN.md exists, compare against its specifications
- If AI Slop Score from /design-review is available, verify those patterns aren't present in the actual screenshots

## Rules

- Always capture at all 3 breakpoints (mobile, tablet, desktop)
- Always show the screenshots — don't describe what you see without evidence
- Score against DESIGN.md when it exists, against common UX standards when it doesn't
- Don't block on subjective preferences — flag them for the user
- Playwright must be available (`~/.claude/tools/node_modules/playwright`)
