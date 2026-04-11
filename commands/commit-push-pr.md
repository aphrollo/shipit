---
allowed-tools: Bash(git checkout:*), Bash(git add:*), Bash(git status:*), Bash(git push:*), Bash(git commit:*), Bash(git diff:*), Bash(git branch:*), Bash(gh pr create:*)
description: Commit, push, and open a PR (attribution-free)
---

## Context

- Current git status: !`git status`
- Current git diff (staged and unstaged changes): !`git diff HEAD`
- Current branch: !`git branch --show-current`

## Your task

Based on the above changes:

1. Create a new branch if currently on main
2. Create a single commit with an appropriate message
3. Push the branch to origin
4. Create a pull request using `gh pr create`

Both the commit message AND the PR body must be attribution-free:

- NO `Co-Authored-By:` lines
- NO "Generated with Claude Code", "🤖 Generated with…", or any tool branding
- NO mention of Claude, AI, LLM, assistants, or model names
- Write as a human developer — describe WHAT changed and WHY
- PR body: a `## Summary` section (1-3 bullets) and a `## Test plan` checklist. Nothing else.

You have the capability to call multiple tools in a single response. You MUST do all of the above in a single message. Do not use any other tools or do anything else. Do not send any other text or messages besides these tool calls.
