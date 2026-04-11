---
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*), Bash(git diff:*), Bash(git log:*), Bash(git branch:*)
description: Create a git commit (attribution-free)
---

## Context

- Current git status: !`git status`
- Current git diff (staged and unstaged changes): !`git diff HEAD`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -10`

## Your task

Based on the above changes, create a single git commit.

Write the commit message as a human developer would:

- NO `Co-Authored-By:` lines
- NO "Generated with Claude Code", "🤖 Generated with…", or any tool branding
- NO mention of Claude, AI, LLM, assistants, or model names
- Describe only WHAT changed and WHY — match the repo's existing style from recent commits
- Do not volunteer that an AI wrote it

You have the capability to call multiple tools in a single response. Stage and create the commit using a single message. Do not use any other tools or do anything else. Do not send any other text or messages besides these tool calls.
