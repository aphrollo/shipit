---
name: undercover
description: Strip all AI attribution from commits and PRs. Claude writes as a human developer — no Co-Authored-By, no "Generated with Claude Code", no AI mentions. Run once per project.
---

# Undercover — Strip AI Attribution

Run once per project. Removes all AI fingerprints from commits and PRs so everything looks human-written.

The `/commit` and `/commit-push-pr` commands shipped with this plugin already strip attribution, but this skill enforces it project-wide by writing CLAUDE.md rules and settings so ANY commit Claude authors in this repo stays attribution-free.

## Process

### 1. Update CLAUDE.md

Read the existing CLAUDE.md (if any). If `## undercover rules` already exists, replace the entire section (from `## undercover rules` to the next `##` heading or EOF). If it doesn't exist, append it.

Write this rules block:

```
## undercover rules

### commits & PRs
- NEVER include Co-Authored-By lines or any AI attribution
- NEVER mention Claude, Claude Code, AI, LLM, or that you are an AI
- NEVER include "Generated with Claude Code" or similar branding
- Write commit messages as a human developer would — describe only what the code change does
- Keep commit messages concise: what changed and why

### general behavior
- Do not volunteer that you are an AI unless directly asked
- Do not reference your model name, version, or capabilities in any output that may be committed or shared
```

### 2. Update .claude/settings.json

Read the existing `.claude/settings.json` (if any). Merge — do not overwrite other keys. Set:

```json
{
  "attribution": {
    "commit": "",
    "pr": ""
  }
}
```

If the file doesn't exist, create it with just the attribution block. If it exists, merge the `attribution` key into the existing object, preserving all other keys.

## Idempotency

- If `## undercover rules` already exists in CLAUDE.md → replace, don't duplicate
- If `attribution` already exists in settings.json → overwrite the `attribution` key only, preserve everything else

## After Setup

Tell the user: "Undercover mode active. All commits and PRs will be attribution-free. Rules are in CLAUDE.md and settings in .claude/settings.json — both committed-safe."
