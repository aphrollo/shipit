# shipit

Multi-agent development workflow for [Claude Code](https://claude.ai/code). Architect thinks, Builder codes, Reviewer audits blind, Deployer ships.

## What is this?

shipit is an opinionated development workflow that replaces single-agent "just code it" with specialized agents that each own one part of the process:

```
User request → Router classifies
                    ↓
              ┌─────┼─────┐
              ↓     ↓     ↓
         Architect  Builder  Reviewer  Deployer
         (thinks)   (codes)  (audits)  (ships)
              ↓     ↓     ↓     ↓
         plan → code+tests → verdict → deployed
                    ↓
              CIP (improve)
```

**The key insight:** The Reviewer never sees the Architect's reasoning or Builder's notes. It audits the code *cold* — catching what the author can't see. This is mechanically enforced: the Reviewer agent has no Write/Edit tools and receives only the diff.

## What's included

**17 skills** covering the full lifecycle:

| Phase | Skills | What happens |
|-------|--------|-------------|
| Think | `/reframe`, `/investigate`, `/design-review` | Challenge assumptions, find root causes, audit UI states |
| Plan | `/plan` | Files, tests, order of operations, risk check |
| Build | `/build`, `/qa`, `/benchmark` | TDD (RED→GREEN→REFACTOR), browser testing, perf regression detection |
| Review | `/review`, `/cso` | Parallel Sonnet subagent audit + OWASP security check |
| Ship | `/ship`, `/canary` | Pre-flight, deploy, post-deploy soak monitoring |
| Improve | `/cip`, `/learn` | Continuous improvement + cross-session learning |

**5 specialized agents:**

| Agent | Role | Tools |
|-------|------|-------|
| `architect` | Thinks about what and why. Reframes, investigates, plans. | Read, Grep, Glob, Bash |
| `builder` | Writes code via TDD. The *only* agent that edits files. | Read, Grep, Glob, Bash, Edit, Write |
| `reviewer` | Audits code blind. Cannot edit. Can spawn tiebreaker subagents. | Read, Grep, Glob, Bash, Agent |
| `deployer` | Ships code. Pre-flight checks, deploy, health monitoring. | Read, Grep, Glob, Bash |
| `researcher` | Deep codebase/dependency exploration. Disposable context. | Read, Grep, Glob, Bash, WebFetch, WebSearch |

**2 global hooks** (active in all phases):

| Hook | Purpose |
|------|---------|
| `/careful` | Blocks destructive commands (rm -rf, DROP TABLE, force-push, etc.) |
| `/verify` | Requires tool-call evidence before claiming done — no "should work now" |

## How it works

1. **`/orchestrate`** auto-triggers when you request code changes
2. **Router** classifies the task (feature, bug, refactor, hotfix, trivial, etc.)
3. **Agents** are dispatched in sequence — each gets only the context it needs
4. **Gates** enforce quality at each transition — FAIL loops back, 3 failures escalate
5. **CIP** runs at the end of every task — the workflow improves itself

### Smart routing

| Task | Agent sequence |
|------|---------------|
| Trivial fix | builder → reviewer |
| Bug fix | architect(investigate) → builder → reviewer |
| New feature | architect(reframe+plan) → builder → reviewer → deployer |
| Hotfix (prod down) | architect(fast) → builder → reviewer(1-pass) → deployer |
| Performance | researcher → architect → builder(+benchmark) → reviewer |

## Install

```bash
# Clone into Claude Code skills directory
git clone https://github.com/aphrollo/shipit.git
cp -r shipit/skills/* ~/.claude/skills/
cp -r shipit/agents/* ~/.claude/agents/
```

Or symlink for easy updates:

```bash
git clone https://github.com/aphrollo/shipit.git ~/.claude/shipit
ln -s ~/.claude/shipit/skills/* ~/.claude/skills/
ln -s ~/.claude/shipit/agents/* ~/.claude/agents/
```

## Key innovations

**vs. [superpowers](https://github.com/obra/superpowers):**
- Multi-agent architecture (isolated context per phase) vs. single-agent with skill switching
- Blind review (reviewer never sees author's reasoning) vs. self-review
- Tiebreaker protocol for disputed findings (3-party arbitration) vs. author-as-judge
- Continuous improvement loop (/cip) built in

**vs. [gstack](https://github.com/garrytan/gstack):**
- Same model diversity for review (Sonnet subagents) without needing OpenAI API keys
- Unified orchestrator instead of 23 independent skills
- Browser testing + performance benchmarking via Playwright
- Classification verification (Sonnet confirms "trivial" tasks to prevent gaming)

**vs. both:**
- Tool restrictions are mechanical (reviewer literally cannot edit files)
- Agent context isolation (architect's reasoning doesn't bias the reviewer)
- Circuit breakers at every gate (3 failures → stop, escalate)
- /careful global hook prevents destructive commands across all phases

## Requirements

- [Claude Code](https://claude.ai/code) CLI or IDE extension
- For `/qa` and `/benchmark`: Node.js + Playwright (`npx playwright install chromium`)

## Philosophy

**Do the complete thing.** When 100% costs 2 minutes more than 90%, always do 100%. Write the edge case test. Handle the error path. The workflow enforces this — not through trust, but through gates.

## License

MIT — use it, fork it, make it yours.

Built by [Aphrollo](https://aphrollo.com).
