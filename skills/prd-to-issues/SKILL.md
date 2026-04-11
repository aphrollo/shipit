---
name: prd-to-issues
description: Break a Product Requirements Document into a Kanban board of vertical-slice GitHub issues with explicit blocking relationships. Auto-activate when the user has a PRD ready and wants to start executing, asks to break down a spec into tasks, or says they want issues for a feature. Uses tracer-bullet slicing — each issue cuts through all integration layers.
---

# PRD to Issues

Turn a PRD into a set of independently grabbable issues. The goal is a Kanban board a team (or a parallel fleet of agents) can pick from without stepping on each other.

## Process

1. **Locate the PRD.** If the user has not pointed at one, ask. Try `docs/prd/`, recent `gh issue list --label prd`, or the current conversation.
2. **Explore the code base.** Read the files the PRD touches. Understand existing patterns before slicing.
3. **Draft vertical slices.** Each slice must cut through every layer (UI, API, data, tests) that the final feature will touch. Favor slices that flush out unknown unknowns fast.
4. **Establish blocking relationships.** For each issue, record which other issues it is blocked by. Many issues should have no blockers — that is what unlocks parallel work.
5. **Write each issue** in the template below. Review with the user before creating anything.
6. **On approval**, create issues via `gh issue create`. Set labels. Cross-link blockers in the body using `Blocked by #N`.

## Tracer-bullet rule

A horizontal slice ("implement the database layer") is forbidden. Every slice must ship something end-to-end, even if ugly, even if stubbed elsewhere. The first slice is a tracer bullet: it proves the wiring works through every layer before any single layer is polished.

Good slices:
- "User can POST /foo and see the new row in the list view" — touches API, DB, UI, tests
- "Feature flag gates the new dashboard tile, default off" — touches config, UI, tests

Bad slices:
- "Add `foo` table migration" — horizontal, not shippable alone
- "Build the settings page" — too vague, no acceptance criterion

## Issue template

```markdown
## Summary
One sentence: what does this slice ship?

## Acceptance criteria
- [ ] Observable, testable outcome 1
- [ ] Observable, testable outcome 2

## Scope
- In: files / modules this slice touches
- Out: things this slice deliberately does not do

## Blockers
- Blocked by #<n> (if any)

## Notes
Any gotchas, links to the PRD section, references to existing patterns.
```

## Parallelism check

After drafting, confirm at least one issue has no blockers. If every issue is blocked by something, the slicing is wrong — re-slice so at least one can be picked up immediately.
