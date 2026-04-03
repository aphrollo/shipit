# shipit

Six AI agents, one pipeline, zero trust between them. Your code gets planned, built, cleaned, and reviewed by agents that can't see each other's reasoning. The reviewer only gets the diff — never the architect's notes or the builder's excuses.

```
/plugin marketplace add aphrollo/shipit
/plugin install shipit@shipit-marketplace
```

That's it. Works on any project, any language. Start building — shipit activates automatically.

## What happens when you ask it to build something

```
You: "Add rate limiting to the API"

Router (10s)     → classifies as "new feature"
Architect        → challenges assumptions, picks approach, plans with risk assessment
Builder          → TDD: failing test → make it pass → refactor → clean naming
Deslop (auto)    → strips AI code slop before review sees it
Reviewer (cold)  → audits the diff blind — no architect notes, no builder context
Deployer         → pre-flight checks → deploy → 5-minute canary soak
```

Every handoff is validated. Every artifact is tracked. Three failures at any gate = full stop.

## The six agents

| Agent | Job | Key constraint |
|-------|-----|---------------|
| **Researcher** | Explore code, read docs, search web | Can't edit files or make decisions |
| **Architect** | Reframe problems, investigate bugs, plan | Can't write code. Must state alternatives before committing. |
| **Designer** | Design system, 7-state UI audit, slop detection | Can only write to docs/DESIGN.md and docs/specs/ |
| **Builder** | TDD implementation with self-documenting code | The only agent that edits application code |
| **Reviewer** | Blind code audit + adversarial QA | Can't edit files. Gets only the diff. |
| **Deployer** | Pre-flight, deploy, canary monitoring | Can't edit files. Stops on any destructive command. |

Not every task hits every agent. A trivial fix goes straight to builder → reviewer. A new feature runs the full pipeline.

## What makes it different

**Cold blind review.** The reviewer never sees why the code was written — only what changed. This catches what warm reviews miss. No other AI workflow framework does this.

**Mechanical isolation.** Agents can't do each other's jobs — the reviewer literally can't edit files. This isn't convention; it's enforced by tool restrictions.

**Typed handoffs.** Seven data contracts govern agent-to-agent communication. Missing a required field blocks the pipeline. No free-text handwaving.

**Anti-rationalization.** Every agent has red-flag tables countering specific shortcuts Claude tends to take. The router blocks "it's basically trivial." The builder enforces clean naming at write time and blocks scope creep. The reviewer blocks "tests cover it, so the code is fine."

**Self-documenting code enforcement.** The builder writes clean names (verb+noun functions, no `data`/`result`/`temp`). Deslop catches stragglers. The reviewer verifies with a READABILITY dimension. Three layers, same standard.

## Pipeline infrastructure

| Module | What it does |
|--------|-------------|
| Handoff schemas | 7 typed contracts — missing fields block the pipeline |
| Material passports | Every artifact carries provenance + expiry for traceability |
| Checkpointing | Resume from last agent on crash |
| Plan cache | Reuses plan templates from successful workflows |
| Loop detection | Fingerprints retries — identical failures change approach, don't waste budget |
| Workflow metrics | JSONL log with auto-degradation alerts every 10 workflows |

## Key skills

| Phase | Skills |
|-------|--------|
| Clarify | `/interview` — Socratic requirements with ambiguity scoring |
| Think | `/reframe`, `/investigate`, `/design-review` |
| Design | `/design` — visual design system + AI slop detection |
| Plan | `/plan`, `/autoplan` — or one-command auto-reviewed plan |
| Build | `/build`, `/qa`, `/visual-qa`, `/benchmark` |
| Review | `/review`, `/second-opinion`, `/receiving-review`, `/cso`, `/deslop` |
| Ship | `/ship`, `/deploy`, `/canary`, `/document-release` |
| Isolation | `/worktrees`, `/freeze` |
| Improve | `/cip`, `/retro`, `/learn` |
| Context | `/context` — compact proactively, avoid the dumb zone |

**Global hooks** (always active): `/careful` blocks destructive commands. `/verify` bans "should work" — requires tool output.

**Telegram** (optional): `/report` sends progress updates at each phase transition.

## vs. superpowers vs. gstack

| | shipit | superpowers | gstack |
|--|--------|------------|--------|
| Agents | 6 isolated, sequential | 1 agent, skill switching | 1 agent, persona switching |
| Code review | Blind (diff only) | Self-review | Sonnet + Codex cross-model |
| Tool isolation | Mechanical | Convention | Convention |
| Quality gates | Circuit breakers + typed schemas | None | None |
| Artifact tracking | Material passports + provenance | None | None |
| Crash recovery | Checkpoint + resume | None | None |
| AI slop cleanup | `/deslop` (11 patterns) | None | `/ai-slop-cleaner` |
| Security audit | `/cso` OWASP + STRIDE | None | `/cso` |
| Post-deploy | `/canary` soak monitoring | None | `/canary` snapshots |
| Self-improvement | `/cip` after every task | None | None |
| Anti-rationalization | Red-flag tables in every agent | Convention-based | None |

## Requirements

- [Claude Code](https://claude.ai/code) (CLI, desktop, or IDE extension)
- For browser testing: Node.js + Playwright (`npx playwright install chromium`)
- For metrics analysis: `jq` (optional)

## Manual install

If you prefer full control over plugin marketplace:

```bash
git clone https://github.com/aphrollo/shipit.git ~/.claude/shipit
ln -s ~/.claude/shipit/skills/* ~/.claude/skills/
ln -s ~/.claude/shipit/agents/* ~/.claude/agents/
cp ~/.claude/shipit/hooks/hooks.json ~/.claude/hooks/hooks.json
```

## Philosophy

Do the complete thing. When 100% costs 2 minutes more than 90%, always do 100%. The workflow enforces this — not through trust, but through gates that won't let you pass without evidence.

## License

MIT

Built by [Aphrollo](https://aphrollo.com).
