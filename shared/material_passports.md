# Material Passports

**Every artifact flowing between agents carries a passport — metadata about its origin, freshness, and integrity.**

Material passports solve three problems in multi-agent pipelines:
1. **Staleness** — Is this plan still valid or did the code change since it was written?
2. **Provenance** — Which agent created this, using what model, based on what inputs?
3. **Traceability** — When deploy fails, trace back to exactly which plan, review, and build led here.

---

## Passport Format

Every agent output includes a `PASSPORT` block at the end:

```
PASSPORT:
  artifact: [type]-[date]-[topic]
  version: [integer, starts at 1, increments on revision]
  created_at: [ISO 8601 timestamp]
  created_by: [agent name] ([model])
  based_on: [list of parent artifact IDs this was derived from]
  expires_at: [ISO 8601 timestamp]
  status: [DRAFT | VERIFIED | EXPIRED | SUPERSEDED]
  content_summary: [one-line description of what this artifact contains]
```

### Example: Plan Passport

```
PASSPORT:
  artifact: plan-2026-03-30-auth-refactor
  version: 1
  created_at: 2026-03-30T23:40:00Z
  created_by: architect (opus)
  based_on: [research-2026-03-30-auth-investigation]
  expires_at: 2026-03-31T01:40:00Z
  status: VERIFIED
  content_summary: Refactor auth middleware to use JWT validation with 3 files changed
```

### Example: Review Passport

```
PASSPORT:
  artifact: review-2026-03-30-auth-refactor
  version: 1
  created_at: 2026-03-30T23:55:00Z
  created_by: reviewer (sonnet)
  based_on: [build-2026-03-30-auth-refactor, plan-2026-03-30-auth-refactor]
  expires_at: 2026-03-31T00:55:00Z
  status: VERIFIED
  content_summary: Code audit PASS — 0 critical, 0 high, 2 medium (non-blocking)
```

---

## Artifact Types and Expiry

| Artifact Type | Default Expiry | Rationale |
|---------------|---------------|-----------|
| research-* | 4 hours | External info and codebase state change frequently |
| investigate-* | 2 hours | Root cause is stable but code context drifts |
| plan-* | 2 hours | Plans go stale when code changes under them |
| design-* | 24 hours | Visual decisions are more stable |
| build-* | 1 hour | Builds are only valid until next code change |
| review-* | 1 hour | Reviews are invalid if builder makes more changes |
| deploy-* | No expiry | Deploy results are historical facts |
| cso-* | 4 hours | Security findings stay valid longer than code reviews |

---

## Status Lifecycle

```
DRAFT → VERIFIED → EXPIRED
                 → SUPERSEDED (when a new version is created)
```

- **DRAFT**: Agent produced output but gate check hasn't run yet
- **VERIFIED**: Gate check passed, handoff schema validated
- **EXPIRED**: `expires_at` has passed — must be re-created before use
- **SUPERSEDED**: A newer version exists (e.g., plan v2 replaces plan v1)

---

## Orchestrator Passport Rules

### On Agent Completion

1. Parse the PASSPORT block from agent output
2. Validate required fields (artifact, version, created_at, created_by, status)
3. Set status to VERIFIED if gate check passes
4. Store passport in session memory (orchestrator tracks all passports for the workflow)

### Before Spawning Next Agent

1. Check `expires_at` on all parent artifacts the next agent depends on
2. If ANY parent is expired → re-run the expired agent before proceeding
3. Pass parent artifact IDs in the `based_on` field of the task prompt
4. Include relevant passport summaries so the downstream agent knows what it's building on

### On Revision

1. Increment version number
2. Set previous version status to SUPERSEDED
3. New passport gets fresh `expires_at`
4. All downstream artifacts that `based_on` the old version are now STALE — flag for re-verification

### Cross-Reference Validation

The orchestrator checks:
- **Builder's `based_on`** must include the plan artifact ID
- **Reviewer's `based_on`** must include the build artifact ID (and optionally the plan)
- **Deployer's `based_on`** must include the review artifact ID
- **Reviewer must NOT reference architect or builder notes** (cold review — only references build artifact)
- If `based_on` references an artifact the orchestrator doesn't have → HANDOFF_INCOMPLETE

---

## How Agents Use Passports

### Producing a Passport

Every agent appends a PASSPORT block to its structured output. The agent fills in:
- `artifact`: type + date + topic (descriptive, unique within the workflow)
- `version`: 1 for first attempt, increment on revision
- `created_at`: current timestamp
- `created_by`: agent name and model
- `based_on`: list of artifact IDs received from the orchestrator
- `content_summary`: one-line summary of what was produced

The orchestrator fills in:
- `expires_at`: based on artifact type table above
- `status`: set to VERIFIED after gate check passes

### Consuming a Passport

When an agent receives parent artifacts, it should:
1. Note the `content_summary` to understand context without re-reading everything
2. Reference `based_on` IDs in its own passport (chain of custody)
3. If a parent artifact looks stale or contradicts current code state, flag it: "STALE_INPUT: [artifact ID] may be outdated because [reason]"

---

## Traceability Chain

At workflow completion, the orchestrator constructs a full provenance chain:

```
WORKFLOW TRACE:
  research-2026-03-30-auth → architect read this
  investigate-2026-03-30-auth → found root cause
  plan-2026-03-30-auth-refactor v2 → revised after scope discovery
  build-2026-03-30-auth-refactor → 3 files changed, 12/12 tests pass
  review-2026-03-30-auth-refactor → PASS, 0 critical
  deploy-2026-03-30-auth-refactor → prod, healthy
```

This chain is included in the Step 4 report. If something goes wrong post-deploy, the chain tells you exactly what happened and where to look.

---

## When Passports Are NOT Required

- **Inline execution** (user said "inline"): No passports. The conversation is the context.
- **Spike mode** (user said "just build"): No passports. Spikes are throwaway.
- **CIP**: No passport. CIP is a reflection, not an artifact.
- **Report**: No passport. Telegram updates are fire-and-forget.
