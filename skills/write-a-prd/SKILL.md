---
name: write-a-prd
description: Turn a shared understanding of a feature into a Product Requirements Document with user stories. Auto-activate when the user asks for a PRD, spec, requirements doc, or says they are ready to document a feature they have already discussed. Can submit the PRD as a GitHub issue.
---

# Write a PRD

Produce a Product Requirements Document from the current conversation. If the feature has not yet been thoroughly interviewed, run grill-me first. If it has, skip straight to drafting.

## Process

1. **Ask for a baseline description** of what is being built, unless one is already in the conversation.
2. **Explore the repo** to verify any assertions the user made. Read the files that will be touched. Note existing patterns to follow.
3. **Interview any remaining gaps.** If design-tree branches are still open, grill until they are closed. Skip this step if grill-me has already run.
4. **Sketch the major modules** that the feature will touch or introduce. One line per module, naming the responsibility.
5. **Draft the PRD** using the template below. Show it to the user for review before saving anywhere.
6. **On approval**, save to `docs/prd/<short-slug>.md` or, if the user prefers, submit as a GitHub issue via `gh issue create` with the PRD as the body.

## PRD template

```markdown
# <Feature name>

## Problem
What user or system problem does this solve? One paragraph.

## Goals
- Bullet list of outcomes this feature must achieve
- Each goal is observable and testable

## Non-goals
- Things explicitly out of scope
- Prevents scope creep during implementation

## User stories
- As a <role>, I want <capability>, so that <benefit>.
- (At least one story per goal. These are the contract.)

## Design
Brief description of the approach. Reference existing code patterns. Link modules that will be touched.

## Modules
- `path/to/module` — responsibility
- `path/to/other` — responsibility

## Risks and open questions
- Known unknowns, assumptions to validate, decisions deferred
```

## Rules

- User stories are the most important section. They become the acceptance criteria downstream.
- Keep the PRD under one page if possible. Long PRDs hide decisions.
- Do not write implementation code inside the PRD. That is what prd-to-issues is for.
- If the user answered fewer than five meaningful design questions before this skill ran, stop and grill first.
