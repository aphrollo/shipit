# Workflow Metrics

**Track end-to-end success rates, cost, and performance to identify where the pipeline breaks.**

Industry data: 99% per-step reliability = 90.4% over 10 steps. You can't improve what you don't measure.

---

## Metrics Tracked

### Per-Workflow Metrics

Collected by the orchestrator at the end of every workflow (Step 4 report):

```json
{
  "workflow_id": "feat-auth-2026-03-31",
  "classification": "new_feature",
  "result": "PASS",
  "started_at": "2026-03-31T00:10:00Z",
  "completed_at": "2026-03-31T00:45:00Z",
  "duration_minutes": 35,
  "agents_used": ["researcher", "architect", "builder", "reviewer"],
  "agent_results": {
    "researcher": { "result": "PASS", "retries": 0, "model": "haiku", "duration_s": 45 },
    "architect":  { "result": "PASS", "retries": 0, "model": "opus", "duration_s": 120 },
    "builder":    { "result": "PASS", "retries": 1, "model": "sonnet", "duration_s": 300 },
    "reviewer":   { "result": "PASS", "retries": 0, "model": "sonnet", "duration_s": 90 }
  },
  "gate_failures": {
    "builder": { "count": 1, "reasons": ["test_failure"], "loop_detected": false }
  },
  "files_changed": 5,
  "review_findings": { "critical": 0, "high": 0, "medium": 2, "low": 1 },
  "checkpoints_used": false,
  "plan_cache_hit": false,
  "handoff_incomplete_count": 0
}
```

### Aggregate Metrics (computed from history)

```
End-to-end success rate:  PASS workflows / total workflows
Per-agent success rate:   PASS on first attempt / total attempts per agent
Average retry count:      total retries / total workflows
Classification accuracy:  workflows that didn't need reclassification / total
Mean time to completion:  average duration_minutes
Gate failure hotspot:     which agent fails most often
Loop detection rate:      loops caught / total retries
Plan cache hit rate:      cache hits / total plans
Handoff completeness:     workflows with 0 HANDOFF_INCOMPLETE / total
```

---

## Storage

```
docs/.shipit-metrics.jsonl — one JSON object per line, one line per workflow
```

JSONL format (not JSON array) so appending is atomic and the file never needs full rewrite.

For monorepos: one metrics file per package root.

---

## When to Collect

The orchestrator appends a metrics record:
- At Step 4 (Report) — after every workflow, PASS or FAIL
- Include the workflow result, all agent results, retry counts, and timing

---

## When to Analyze

### Automatic (every 10 workflows)

After every 10th workflow, the orchestrator computes aggregates and checks for problems:

```
IF end-to-end success rate < 85% over last 10 workflows:
  → Flag: "Pipeline reliability is degrading. [agent] is the most common failure point."

IF any agent retry rate > 30% over last 10 workflows:
  → Flag: "[agent] is failing frequently. Check prompt quality or model selection."

IF mean time to completion increased > 50% vs previous 10:
  → Flag: "Workflows are getting slower. Check for unnecessary phases or model upgrades."

IF plan cache hit rate < 20% after 20+ workflows:
  → Flag: "Plan cache is not being used. Check task_pattern matching."

IF handoff_incomplete_count > 0 in > 30% of workflows:
  → Flag: "Agents are producing incomplete output. Check schema enforcement."
```

### Manual (via /retro)

The /retro skill reads the metrics file for weekly analysis:
- Which task types succeed most/least
- Which agents need prompt improvement
- Cost trends over time
- Whether new skills/changes improved or degraded performance

---

## Privacy & Size

- Metrics contain task classifications and timing, NOT code or user content
- JSONL grows ~500 bytes per workflow. 1000 workflows = ~500KB. No concern.
- Rotate: archive workflows older than 90 days to `docs/.shipit-metrics-archive.jsonl`

---

## CIP Integration

The /cip skill (Step 5) can reference metrics when answering its 3 questions:
1. "What slowed us down?" → Check duration_minutes trend and agent durations
2. "What almost went wrong?" → Check gate_failures and loop_detected flags
3. "What should change?" → Check per-agent success rates and retry patterns

Metrics make CIP data-driven instead of anecdotal.
