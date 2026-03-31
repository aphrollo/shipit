# shipit

Multi-agent development workflow for [Claude Code](https://claude.ai/code). Six specialized agents, mechanically isolated — each owns one job and can't do another's.

## How it works

```
User request
 ⎿ Router (10s) — classifies into 11 task types
    ⎿ Orchestrator
       │
       │  [1] Resume checkpoint (if crashed workflow exists)
       │  [2] Classify task type + check plan cache
       │  [3] Dispatch agents ↓
       │
       ├─ Researcher (optional)
       │  ⎿ codebase exploration, dependency analysis, web research
       ├─ Architect
       │  ⎿ reframe → investigate → plan — never writes code
       ├─ Designer (optional)
       │  ⎿ design system → 7-state audit → AI slop detection
       ├─ Builder
       │  ⎿ RED → GREEN → REFACTOR — the only agent that edits files
       ├─ Deslop (automatic)
       │  ⎿ cleans AI code slop before review sees it
       ├─ Reviewer (cold)
       │  ⎿ receives only the diff — never architect or builder notes
       ├─ Deployer
       │  ⎿ pre-flight → deploy → canary soak
       │
       │  [4] Gate check: passport → schema → pass/fail → staleness
       │  [5] Save checkpoint
       │  [6] Report with provenance chain + collect metrics
       │  [7] Update plan cache
       │  [8] CIP — what slowed us? what almost went wrong? what should change?
       │
       └─ Done
```

The orchestrator dispatches agents sequentially, checking quality gates between each. Every handoff is validated against typed schemas, and every artifact carries a material passport for traceability. Not every task hits every agent — the router selects the shortest safe path:

| Task type | Agent sequence |
|-----------|---------------|
| Trivial fix | builder → reviewer |
| Docs only | builder → reviewer |
| Refactor | architect(plan) → builder → reviewer |
| Bug fix | architect(investigate) → builder → reviewer |
| New feature | architect(reframe+plan) → builder → reviewer → deployer |
| New feature (with UI) | architect(reframe+plan) → designer → builder → reviewer → deployer |
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
| `designer` | Read, Grep, Glob, Bash, **Write** (DESIGN.md only) | Edit application code |
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

**Loop detection** catches stuck agents faster — if two consecutive retries produce identical fingerprints (same error, same files), it changes the approach before counting against the circuit breaker. Three identical fingerprints = immediate stop.

### Tiebreaker protocol

When the reviewer flags a CRITICAL/HIGH finding, the builder can't self-dismiss it. A neutral Sonnet subagent arbitrates — sees the finding and the code, rules UPHOLD or DISMISS. Uncertainty defaults to UPHOLD.

## What's included

**32 skills** + **6 shared infrastructure modules** across the full lifecycle:

| Phase | Skills | Purpose |
|-------|--------|---------|
| Clarify | `/interview` | Socratic requirements clarification with ambiguity scoring — gates readiness |
| Think | `/reframe`, `/investigate`, `/design-review` | Challenge assumptions, find root causes, audit all 7 UI states + AI slop detection |
| Design | `/design` | Build/maintain visual design system, constrain UI before code |
| Plan | `/plan`, `/autoplan` | Files, test cases, order of ops — or one-command auto-reviewed plan |
| Build | `/build`, `/qa`, `/visual-qa`, `/benchmark` | TDD, browser testing, screenshot QA, Core Web Vitals regression detection |
| Review | `/review`, `/second-opinion`, `/receiving-review`, `/cso`, `/deslop` | Cold review + cross-model + feedback eval + OWASP + AI code slop cleanup |
| Ship | `/ship`, `/deploy`, `/canary`, `/document-release` | Pre-flight, platform-aware deploy, canary soak, post-ship doc audit |
| Isolation | `/worktrees`, `/freeze` | Git worktrees + edit boundary enforcement |
| Improve | `/cip`, `/retro`, `/learn` | Per-task improvement, weekly retrospective, cross-session learning |
| Context | `/context` | Window management — compact proactively, avoid the "agent dumb zone" |

**2 global hooks** (always active, all phases, all projects):

| Hook | What it does |
|------|-------------|
| `/careful` | Blocks `rm -rf`, `DROP TABLE`, `force-push`, `terraform destroy`, etc. — requires explicit confirmation |
| `/verify` | Bans "should work now", "tests should pass", "looks correct" — requires actual tool-call output as evidence |

**1 conditional hook** (activates when integration is present):

| Hook | What it does |
|------|-------------|
| `/report` | Sends small progress updates to Telegram at each phase transition. Uses haiku model for minimal cost. Silent when no Telegram channel is active. |

## Pipeline infrastructure

**6 shared modules** govern how agents communicate, recover, and improve:

| Module | File | What it does |
|--------|------|-------------|
| Handoff schemas | `shared/handoff_schemas.md` | 7 typed data contracts (RESEARCH, PLAN, INVESTIGATE, DESIGN, BUILD, REVIEW, DEPLOY). Missing required fields → HANDOFF_INCOMPLETE → blocks pipeline. |
| Material passports | `shared/material_passports.md` | Every artifact carries provenance (who created it, when, from what, expiry). Enables staleness detection and post-incident traceability. |
| Checkpointing | `shared/checkpointing.md` | Saves workflow state after each agent passes. Resume from last checkpoint on crash. Validates passport expiry on resume. |
| Plan cache | `shared/plan_cache.md` | Extracts plan templates from successful workflows. Architect adapts cached templates instead of planning from scratch. 50% cost reduction on recurring task types. |
| Loop detection | `shared/loop_detection.md` | Fingerprints agent retries. Identical failures don't waste circuit breaker budget — changes approach first. Three identical fingerprints = immediate stop. |
| Workflow metrics | `shared/workflow_metrics.md` | JSONL log of every workflow: result, duration, per-agent stats, retries, cache hits. Auto-flags degradation every 10 workflows. Powers /cip and /retro. |

### Provenance chain

Every workflow report includes a full artifact chain:

```
research-2026-03-31-auth v1 → plan-2026-03-31-auth v2 → build-2026-03-31-auth v1 → review-2026-03-31-auth v1 → deploy-2026-03-31-auth v1
```

When something breaks in production, follow the chain to find exactly which plan, review, and build led there.

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

### Plugin (recommended — auto-updates)

```
/plugin marketplace add aphrollo/shipit
/plugin install shipit@shipit-marketplace
```

That's it. Skills, agents, and hooks are installed automatically. Update with `/plugin marketplace update` + `/plugin update shipit@shipit-marketplace`.

### Manual (if you prefer full control)

```bash
git clone https://github.com/aphrollo/shipit.git ~/.claude/shipit
ln -s ~/.claude/shipit/skills/* ~/.claude/skills/
ln -s ~/.claude/shipit/agents/* ~/.claude/agents/
cp ~/.claude/shipit/hooks/hooks.json ~/.claude/hooks/hooks.json
```

## Requirements

- [Claude Code](https://claude.ai/code) CLI, desktop app, or IDE extension
- For `/qa`, `/benchmark`, `/visual-qa`: Node.js + Playwright (`npx playwright install chromium`) — auto-verified before use
- For workflow metrics analysis (`/retro`): `jq` (optional, for aggregate queries)

## How shipit compares

|  | shipit | [superpowers](https://github.com/obra/superpowers) | [gstack](https://github.com/garrytan/gstack) |
|--|--------|------------|--------|
| Architecture | 6 isolated agents, sequential pipeline | Single agent, skill switching | Single agent, persona switching |
| Skills | 32 skills + 6 shared modules + 3 hooks | 13 skills | 31 skills |
| Code review | Blind (reviewer sees only diff) | Self-review | Sonnet subagent + Codex cross-model |
| Cross-model review | `/second-opinion` (blind, any model pair) | None | `/codex` (requires OpenAI key) |
| Review feedback | `/receiving-review` (evaluate, don't agree) | `receiving-code-review` | None |
| Disputed findings | Tiebreaker arbitration | Author decides | Author decides |
| Reviewer trust | "Do Not Trust the Report" — verify by reading code | Trust but verify | Confidence scores 1-10 |
| Tool restrictions | Mechanical (reviewer can't edit) | Convention-based | Convention-based |
| Context isolation | Enforced per agent | Shared context | Shared context |
| Quality gates | Circuit breakers at every transition | None | None |
| Model cost optimization | Haiku for mechanical, Sonnet for judgment, auto-upgrade on failure | Manual | Manual |
| Automated planning | `/autoplan` (reframe → design → plan in one command) | None | `/autoplan` (CEO → design → eng review) |
| AI slop detection | 10 anti-pattern scoring (A-F) in `/design-review` | None | 10 anti-pattern scoring in `/design-review` |
| Deploy automation | `/deploy` with 9-platform auto-detection | None | `/land-and-deploy` with platform detection |
| Post-ship docs | `/document-release` auto-updates stale docs | None | `/document-release` auto-invoked by `/ship` |
| Edit boundary | `/freeze` locks edits to one directory | None | `/freeze` + `/guard` |
| Weekly retrospective | `/retro` with commit analysis and metrics | None | `/retro` with contributor breakdowns |
| Destructive command guard | `/careful` global hook | None | `/careful` hook |
| Evidence requirement | `/verify` global hook | `verification-before-completion` | None |
| Git worktrees | `/worktrees` with auto-setup | `using-git-worktrees` | None |
| Spec/plan persistence | Writes to `docs/specs/` and `docs/plans/` | Writes to `docs/superpowers/` | `~/.gstack/projects/` |
| Reference docs | Root-cause tracing, defense-in-depth, anti-patterns, find-polluter | Same set | None |
| Browser testing | Playwright built in | Visual companion (mockups) | Persistent browser daemon (~100ms) |
| Security audit | `/cso` OWASP + STRIDE | None | `/cso` OWASP + STRIDE |
| Post-deploy monitoring | `/canary` soak watch | None | `/canary` periodic snapshots |
| Self-improvement | `/cip` after every task | None | None |
| Cross-session learning | `/learn` persists patterns | None | `/learn` with search + prune |
| External reporting | `/report` Telegram hook | None | None |
| Context management | `/context` skill — compact at 50%, avoid dumb zone | None | None |
| Default orchestration | Router auto-dispatches to orchestrate | None | None |
| Requirements clarification | `/interview` Socratic questioning + ambiguity scoring | None | `/office-hours` YC-style forcing questions |
| AI code slop cleanup | `/deslop` — 10 code anti-patterns, scan + fix | None | `/ai-slop-cleaner` |
| Visual screenshot QA | `/visual-qa` — screenshot capture + scoring at 3 breakpoints | None | None |
| Typed handoff schemas | 7 schemas with validation + HANDOFF_INCOMPLETE | None | None |
| Material passports | Artifact provenance, expiry, traceability chain | None | None |
| Checkpointing | Resume from last agent on crash | None | None |
| Plan caching | Template reuse for recurring task types | None | None |
| Loop detection | Fingerprint-based stuck agent detection | None | None |
| Workflow metrics | JSONL log with auto-degradation alerts | None | None |
| Session bootstrap | `hooks.json` auto-loads router | `hooks.json` auto-loads meta-skill | None |

## Philosophy

**Do the complete thing.** When 100% costs 2 minutes more than 90%, always do 100%. Write the edge case test. Handle the error path. Check the seventh UI state. The workflow enforces this — not through trust, but through gates that won't let you pass without evidence.

## License

MIT — use it, fork it, make it yours.

Built by [Aphrollo](https://aphrollo.com).
