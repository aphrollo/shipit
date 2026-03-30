# shipit

Multi-agent development workflow for [Claude Code](https://claude.ai/code). Five specialized agents, mechanically isolated — each owns one job and can't do another's.

## How it works

```
               User request
                    │
            ┌───────▼───────┐
            │  Router (10s) │  ← classifies into 11 task types
            └───────┬───────┘
                    │
            ┌───────▼───────┐
            │  Orchestrator  │  ← dispatches agents in sequence
            └───────┬───────┘
                    │
         ┌──────────▼──────────┐
         │   Researcher        │  optional — only when hitting unknowns
         │   "what do we need  │
         │    to know?"        │
         └──────────┬──────────┘
                    │
         ┌──────────▼──────────┐
         │   Architect         │  reframe → investigate → plan
         │   "think, don't     │
         │    write code"      │
         └──────────┬──────────┘
                    │
         ┌──────────▼──────────┐
         │   Builder           │  RED → GREEN → REFACTOR
         │   "the only agent   │
         │   that edits files" │
         └──────────┬──────────┘
                    │
         ┌──────────▼──────────┐
         │   Reviewer (cold)   │  receives only the diff — never
         │   "audit blind"     │  architect reasoning or builder notes
         └──────────┬──────────┘
                    │
         ┌──────────▼──────────┐
         │   Deployer          │  pre-flight → deploy → canary soak
         │   "ship + watch"    │
         └──────────┬──────────┘
                    │
         ┌──────────▼──────────┐
         │   CIP (improve)     │  what slowed us down? what almost
         │   runs every time   │  went wrong? what should change?
         └─────────────────────┘
```

Not every task hits every agent. The router selects the shortest safe path:

| Task type | Agent sequence |
|-----------|---------------|
| Trivial fix | builder → reviewer |
| Docs only | builder → reviewer |
| Refactor | architect(plan) → builder → reviewer |
| Bug fix | architect(investigate) → builder → reviewer |
| New feature | architect(reframe+plan) → builder → reviewer → deployer |
| Hotfix (prod down) | architect(fast) → builder → reviewer(1-pass) → deployer |
| Performance | researcher → architect → builder(+benchmark) → reviewer |
| Migration | researcher → architect → builder → reviewer(+cso) → deployer |
| Spike | builder (no ship — disposable) |

## Why multi-agent?

Single-agent workflows have a bias problem: the same context that wrote the code reviews it. shipit enforces separation mechanically:

| Agent | Can do | Cannot do |
|-------|--------|-----------|
| `architect` | Read, Grep, Glob, Bash, spawn agents | Edit files |
| `builder` | Read, Grep, Glob, Bash, **Edit, Write** | Spawn review agents |
| `reviewer` | Read, Grep, Glob, Bash, spawn tiebreakers | Edit files |
| `deployer` | Read, Grep, Glob, Bash | Edit files |
| `researcher` | Read, Grep, Glob, Bash, WebFetch, WebSearch | Edit files |

**The reviewer gets only the git diff + call graph.** No architect reasoning, no builder notes, no "here's why I did it this way." It audits the code cold — the way a real code review should work.

## Quality gates

Every agent transition has a gate. Pass or loop back.

| Gate | Pass condition | On failure |
|------|---------------|------------|
| Researcher → Architect | Structured findings with KEY FINDINGS + RELEVANT FILES | Retry with narrower scope |
| Architect → Builder | ROOT CAUSE or PLAN with files + test cases | Ask user to clarify |
| Builder → Reviewer | All tests pass, lint clean | Feed errors back, retry (max 3) |
| Reviewer → Deployer | No CRITICAL/HIGH findings | Feed findings to builder as fixes (max 3) |
| Deployer → Done | Health check passes, canary healthy | Alert user, no auto-rollback |

**3 consecutive failures at any gate → STOP.** Escalate to user. No infinite loops.

### Tiebreaker protocol

When the reviewer flags a CRITICAL/HIGH finding, the builder can't self-dismiss it. A neutral Sonnet subagent arbitrates — sees the finding and the code, rules UPHOLD or DISMISS. Uncertainty defaults to UPHOLD.

## What's included

**18 skills** across the full lifecycle:

| Phase | Skills | Purpose |
|-------|--------|---------|
| Think | `/reframe`, `/investigate`, `/design-review` | Challenge assumptions, find root causes, audit all 7 UI states |
| Plan | `/plan` | Files to change, test cases, order of ops, risk assessment |
| Build | `/build`, `/qa`, `/benchmark` | TDD, Playwright browser testing, Core Web Vitals regression detection |
| Review | `/review`, `/cso` | Dual Sonnet subagent audit + OWASP Top 10 / STRIDE threat model |
| Ship | `/ship`, `/canary` | Pre-flight checks, deploy, post-deploy soak monitoring |
| Improve | `/cip`, `/learn` | Capture what worked, persist patterns cross-session |

**2 global hooks** (always active, all phases, all projects):

| Hook | What it does |
|------|-------------|
| `/careful` | Blocks `rm -rf`, `DROP TABLE`, `force-push`, `terraform destroy`, etc. — requires explicit confirmation |
| `/verify` | Bans "should work now", "tests should pass", "looks correct" — requires actual tool-call output as evidence |

**1 conditional hook** (activates when integration is present):

| Hook | What it does |
|------|-------------|
| `/report` | Sends small progress updates to Telegram at each phase transition. Uses haiku model for minimal cost. Silent when no Telegram channel is active. |

## Anti-rationalization

The workflow explicitly counters common shortcuts:

| What you might think | What shipit does |
|---------------------|-----------------|
| "Too simple for all this" | Trivial path still uses builder + reviewer. Review is never skipped. |
| "I know what the bug is" | `/investigate` first. No fix without a root cause statement. |
| "Quick fix, skip review" | Quick fixes without review cause incidents. Review is mandatory. |
| "Should work now" | Banned phrase. Show test output or it didn't happen. |
| "Reviewer won't get the context" | Good. Cold review catches what warm review misses. |
| "3rd attempt, just force it" | 3 failures = stop. Question the approach, don't brute-force it. |

## Install

```bash
# Clone and symlink (recommended — easy to update)
git clone https://github.com/aphrollo/shipit.git ~/.claude/shipit
ln -s ~/.claude/shipit/skills/* ~/.claude/skills/
ln -s ~/.claude/shipit/agents/* ~/.claude/agents/
```

Or copy if you prefer to customize:

```bash
git clone https://github.com/aphrollo/shipit.git
cp -r shipit/skills/* ~/.claude/skills/
cp -r shipit/agents/* ~/.claude/agents/
```

## Requirements

- [Claude Code](https://claude.ai/code) CLI, desktop app, or IDE extension
- For `/qa` and `/benchmark`: Node.js + Playwright (`npx playwright install chromium`)

## How shipit compares

|  | shipit | [superpowers](https://github.com/anthropics/superpowers) | [gstack](https://github.com/garrytan/gstack) |
|--|--------|------------|--------|
| Architecture | 5 isolated agents, sequential pipeline | Single agent, skill switching | 23 independent skills |
| Code review | Blind (reviewer sees only diff) | Self-review | Sonnet subagent (needs OpenAI key) |
| Disputed findings | Tiebreaker arbitration | Author decides | Author decides |
| Tool restrictions | Mechanical (reviewer can't edit) | Convention-based | Convention-based |
| Context isolation | Enforced per agent | Shared context | Shared context |
| Quality gates | Circuit breakers at every transition | None | None |
| Destructive command guard | `/careful` global hook | None | None |
| Evidence requirement | `/verify` global hook | None | None |
| Browser testing | Playwright built in | None | None |
| Self-improvement | `/cip` after every task | None | None |

## Philosophy

**Do the complete thing.** When 100% costs 2 minutes more than 90%, always do 100%. Write the edge case test. Handle the error path. Check the seventh UI state. The workflow enforces this — not through trust, but through gates that won't let you pass without evidence.

## License

MIT — use it, fork it, make it yours.

Built by [Aphrollo](https://aphrollo.com).
