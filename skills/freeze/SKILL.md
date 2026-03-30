---
name: freeze
description: Lock file edits to a specific directory — prevents accidental changes outside the working scope. Use when working on production code, isolated features, or sensitive areas.
---

# Freeze — Edit Boundary Enforcement

**Restrict file edits to a single directory. Everything outside is read-only.**

## When to Use

- Working on production code and don't want to accidentally modify other areas
- Isolating changes to a specific module during a focused refactor
- Pair programming where scope needs to be explicitly bounded
- Any time you want a safety net against scope creep in file edits

## How to Activate

User says: "freeze to src/auth" or "lock edits to packages/core" or "only edit the api directory"

## Behavior

When frozen to a directory:
- **Edit and Write tools**: BLOCKED for files outside the frozen directory. Warn and refuse.
- **Read, Grep, Glob, Bash**: UNRESTRICTED — you can read anything, run any command
- **Creating new files**: Only allowed inside the frozen directory

## Activation

1. User specifies the directory to freeze to
2. Confirm: "Edits locked to `[directory]`. I can read anything but will only modify files in this directory. Say 'unfreeze' to remove the restriction."
3. For every Edit/Write call, check if the target path starts with the frozen directory
4. If outside: refuse with "That file is outside the frozen directory `[dir]`. Unfreeze first or confirm you want to edit outside scope."

## Deactivation

User says: "unfreeze" or "unlock edits" or "remove freeze"

Confirm: "Edit restriction removed. I can modify files anywhere again."

## Rules

- This is a scope management tool, not a security boundary
- Bash commands can still modify files outside the boundary (sed, mv, cp, etc.) — warn if this happens
- The freeze applies to the current conversation only — does not persist across sessions
- Multiple freezes are not supported — freezing to a new directory replaces the old one
- Always confirm when activating or deactivating
