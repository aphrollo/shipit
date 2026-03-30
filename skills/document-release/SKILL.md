---
name: document-release
description: After shipping code — audit and update documentation to match the new state. Auto-corrects factual changes, asks for subjective ones. Updates README, ARCHITECTURE, CLAUDE.md.
---

# Document Release — Post-Ship Doc Audit

**After code ships, docs go stale. This skill catches the drift.**

## When to Run

- After `/ship` completes successfully
- After merging a significant PR
- When user notices docs are outdated
- Auto-suggested by `/ship` when markdown files exist in the repo

## Process

### 1. Gather Changes

```bash
# What changed since last release/tag
git diff HEAD~[N]..HEAD --name-only

# Which markdown files exist
find . -name "*.md" -not -path "*/node_modules/*" -not -path "*/.git/*"

# What the changes actually are
git diff HEAD~[N]..HEAD
```

### 2. Cross-Reference

For each markdown file, check if it references anything that changed:
- **Function/class names** that were renamed or removed
- **File paths** that moved
- **CLI flags or commands** that changed
- **Configuration options** that were added/removed
- **Architecture descriptions** that no longer match the code
- **Install/setup instructions** that changed

### 3. Categorize Fixes

| Type | Action |
|------|--------|
| Factual corrections (renamed function, moved file, changed flag) | Auto-fix without asking |
| New features not yet documented | Draft section, ask user to review |
| Removed features still documented | Remove section, confirm with user |
| Architectural changes | Ask user — these are subjective |
| Version numbers, badges, links | Auto-fix |

### 4. Apply

- One commit per documentation file updated
- Commit message: "docs: update [file] to match [what changed]"
- Don't rewrite prose style — only fix factual accuracy
- Don't add documentation for things that weren't documented before (unless user asks)

## Files to Check

Priority order:
1. `README.md` — most visible, most likely stale
2. `CLAUDE.md` — project instructions for AI, must match reality
3. `ARCHITECTURE.md` or `docs/architecture.md`
4. `CONTRIBUTING.md`
5. `CHANGELOG.md` — add entry if not already done by `/ship`
6. Any `docs/*.md` files
7. Inline code comments referencing changed APIs (optional, only if user requests)

## Rules

- Never rewrite documentation voice/style — only fix facts
- Don't create documentation that doesn't exist — only update what's there
- Ask before removing sections — the user may want to keep historical context
- Keep changes minimal — the goal is accuracy, not perfection
- If no docs need updating, say so and move on
