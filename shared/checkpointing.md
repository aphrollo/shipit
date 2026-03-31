# Checkpointing & Resume

**Save workflow state after each agent completes so crashes don't lose progress.**

Without checkpointing, a 7-agent feature workflow that crashes at the reviewer loses 30+ minutes of architect + builder work. With checkpointing, it resumes from the last completed agent.

---

## Checkpoint Format

After each agent passes its gate check, save a checkpoint file:

```
Location: docs/.shipit-checkpoint.json (project root)
```

```json
{
  "workflow_id": "feat-auth-refactor-2026-03-31",
  "task_type": "new_feature",
  "started_at": "2026-03-31T00:10:00Z",
  "last_updated": "2026-03-31T00:25:00Z",
  "current_phase": "builder",
  "completed_phases": [
    {
      "agent": "researcher",
      "status": "PASS",
      "completed_at": "2026-03-31T00:12:00Z",
      "artifact_id": "research-2026-03-31-auth",
      "output_summary": "Found 3 auth middleware files, JWT validation in middleware/auth.go"
    },
    {
      "agent": "architect",
      "status": "PASS",
      "completed_at": "2026-03-31T00:18:00Z",
      "artifact_id": "plan-2026-03-31-auth-refactor",
      "output_summary": "Plan: modify 3 files, 5 test cases, estimated 2 milestones"
    }
  ],
  "pending_phase": {
    "agent": "builder",
    "started_at": "2026-03-31T00:18:30Z",
    "context_passed": "plan-2026-03-31-auth-refactor"
  },
  "passports": {
    "research-2026-03-31-auth": { "version": 1, "expires_at": "2026-03-31T04:12:00Z", "status": "VERIFIED" },
    "plan-2026-03-31-auth-refactor": { "version": 1, "expires_at": "2026-03-31T02:18:00Z", "status": "VERIFIED" }
  },
  "user_request": "Add JWT validation to the auth middleware",
  "classification": "new_feature",
  "agent_sequence": ["researcher", "architect", "builder", "reviewer", "deployer"]
}
```

---

## When to Checkpoint

Save after:
1. Each agent **passes** its gate check (Step 3c)
2. User approval of a plan (captures the approved plan)
3. Successful deploy (final checkpoint before canary)

Do NOT checkpoint:
- Mid-agent execution (agent context is not serializable)
- On agent failure (failed state is not resumable — needs retry, not resume)
- During CIP (CIP is terminal, nothing to resume)

---

## Resume Protocol

On workflow start, check for an existing checkpoint:

```
1. Read docs/.shipit-checkpoint.json
2. If exists AND workflow_id matches current task (fuzzy match on task description):
   a. Show user: "Found checkpoint from [time]. Completed: [phases]. Resume from [next phase]?"
   b. User approves → validate passports (check expiry), resume from pending_phase
   c. User declines → delete checkpoint, start fresh
3. If exists but stale (last_updated > 4 hours ago):
   a. Show user: "Found stale checkpoint from [time]. Start fresh?"
   b. Always recommend fresh start for stale checkpoints
4. If no checkpoint → proceed normally
```

### Passport Validation on Resume

Before resuming, check ALL passport expiry times against current time:
- If all passports still valid → resume directly
- If some expired → re-run only the expired phases, then resume
- If all expired → start fresh (checkpoint is useless)

Example: Architect plan expired (>2h) but researcher findings still valid (<4h) → re-run architect with existing research, then resume builder.

---

## Checkpoint Cleanup

- **On workflow PASS**: Delete checkpoint file. The workflow completed successfully.
- **On workflow FAIL (escalated)**: Keep checkpoint. User may want to resume after fixing the issue.
- **On "start fresh"**: Delete checkpoint file.
- **Stale checkpoints (>24h)**: Warn user on next workflow start, recommend deletion.

---

## Limitations

- **Agent context is NOT saved**: Only structured output (handoff data + passports) is checkpointed. The agent's internal reasoning, tool call history, and intermediate work are lost. This means resumed agents start with the plan/findings, not mid-thought.
- **Git state must be consistent**: If someone made commits between crash and resume, passport staleness detection handles this (re-runs stale phases).
- **Single checkpoint per project**: Only one active workflow can be checkpointed at a time. Starting a new workflow overwrites the previous checkpoint.
- **No parallel workflow checkpointing**: Worktree-based parallel workflows each need their own checkpoint (saved in their own docs/ directory).
