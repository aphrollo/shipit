---
name: worktrees
description: When starting feature work needing isolation, before executing implementation plans, or developing multiple features in parallel — manage git worktrees for safe, isolated development environments.
---

# Worktrees

**Gate: Worktree created, project setup complete, tests passing in the new worktree before any work begins.**

## When to Use

- Starting feature work that needs isolation from the main working tree
- Before executing an implementation plan (from /plan) that touches many files
- Parallel development on multiple features simultaneously
- When /router dispatches builders that need independent workspaces

## Directory Selection Priority

Detect or create the worktree root directory in this order:

1. Use existing `.worktrees/` directory if present
2. Use existing `worktrees/` directory if present
3. Create `.worktrees/` and add it to `.gitignore` (see Safety Rules)

## Creation Process

### 1. Detect Project Name

```bash
# From git remote (preferred)
git remote get-url origin | sed 's/.*\///' | sed 's/\.git$//'

# Fallback: directory name
basename "$(git rev-parse --show-toplevel)"
```

### 2. Verify .gitignore Coverage

Before creating any worktree, confirm the worktree directory is in `.gitignore`. If not, add it and commit immediately (see Safety Rules below).

### 3. Create the Worktree

```bash
git worktree add .worktrees/<feature-name> -b <feature-branch>
```

Use a descriptive branch name that reflects the feature or task, e.g. `feat/add-auth-middleware`, `fix/race-condition-in-cache`.

### 4. Auto-Detect and Run Project Setup

Inside the new worktree, detect the project type and install dependencies:

| Indicator File       | Setup Command                      |
|----------------------|------------------------------------|
| `package.json`       | `npm install`                      |
| `Cargo.toml`         | `cargo build`                      |
| `requirements.txt`   | `pip install -r requirements.txt`  |
| `go.mod`             | `go mod download`                  |
| `Gemfile`            | `bundle install`                   |
| `mix.exs`            | `mix deps.get`                     |

Run the first matching setup command. If multiple apply (e.g. a monorepo), run all that match.

### 5. Verify Clean Test Baseline

Run the project's test suite in the new worktree. Tests MUST pass before any feature work begins. If tests fail, investigate and fix in the main tree first.

### 6. Report Status

Output a summary:

```
WORKTREE READY
  Location: .worktrees/<feature-name>
  Branch:   <feature-branch>
  Setup:    <command run> -- OK
  Tests:    PASS
```

## Safety Rules

1. **MUST verify worktree directory is in `.gitignore` before creating.** If the directory (`.worktrees/` or `worktrees/`) is not listed in `.gitignore`, add it and commit immediately:
   ```bash
   echo ".worktrees/" >> .gitignore
   git add .gitignore
   git commit -m "chore: add .worktrees/ to .gitignore"
   ```

2. **Never create worktrees on main/master.** The `-b <branch>` flag must always specify a new feature branch. If the user asks to work directly on main, refuse and explain why isolation requires a branch.

3. **Always verify tests pass in the new worktree before starting work.** A red baseline means bugs will be attributed to the feature work. Fix first, then branch.

## Cleanup

After a feature branch is merged or discarded:

```bash
# Remove the worktree
git worktree remove .worktrees/<feature-name>

# Optionally delete the branch (if merged)
git branch -d <feature-branch>
```

Maintenance commands:

```bash
# List all active worktrees
git worktree list

# Prune stale worktree references (e.g. after manual directory deletion)
git worktree prune
```

## Integration with /router

When the router dispatches builder agents for parallel work, it can assign each agent its own worktree:

- Each builder agent gets an isolated worktree with its own branch
- Agents can run tests independently without interfering with each other
- After completion, the orchestrator merges branches and cleans up worktrees
- This prevents file-level conflicts between concurrent agents working on the same repo
