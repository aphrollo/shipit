# Plan Cache

**Reuse plan templates from completed workflows to reduce cost and latency for recurring task types.**

Research shows agentic plan caching reduces costs by 50% and latency by 27% while maintaining 96.6% of optimal performance. Common patterns (add API endpoint, fix bug in module X, refactor service) get replanned from scratch each time — plan caching eliminates this waste.

---

## How It Works

### 1. Capture (after successful workflow)

When a workflow completes with PASS, extract a plan template:

```json
{
  "template_id": "add-api-endpoint-v1",
  "task_pattern": "add * endpoint|add * route|new * API",
  "classification": "new_feature",
  "plan_template": {
    "files_to_change": [
      { "pattern": "routes/*.go|routes/*.ts", "description": "Add route handler" },
      { "pattern": "models/*.go|models/*.ts", "description": "Add data model if needed" },
      { "pattern": "*_test.go|*.test.ts", "description": "Add handler tests" },
      { "pattern": "openapi.*|swagger.*", "description": "Update API docs if exists" }
    ],
    "test_cases": [
      { "description": "Happy path — valid request returns expected response" },
      { "description": "Validation — invalid input returns 400" },
      { "description": "Auth — unauthenticated request returns 401" },
      { "description": "Not found — missing resource returns 404" }
    ],
    "order_of_operations": [
      "Write model/types",
      "Write handler with validation",
      "Write tests",
      "Update route registration",
      "Update API docs"
    ],
    "common_risks": ["Breaking existing routes", "Missing auth middleware", "Schema migration needed"]
  },
  "created_from": "plan-2026-03-31-users-endpoint",
  "times_used": 0,
  "last_used": null,
  "success_rate": null
}
```

### 2. Match (at plan phase)

When the architect starts planning, check the cache:

```
1. Read docs/.shipit-plan-cache.json
2. Match user request against task_pattern (glob-style matching)
3. If match found with success_rate >= 80% (or null for new templates):
   a. Present template to architect: "Found cached plan template for this task type."
   b. Architect adapts the template to the specific request (fills in actual file paths, specific test cases)
   c. This is ADAPTATION, not blind reuse — the architect still reasons about the specific task
4. If no match → plan from scratch as normal
5. If match found with success_rate < 80% → flag but still offer: "Template has low success rate. Consider planning fresh."
```

### 3. Track (after workflow completes)

Update the template's success tracking:
- Workflow PASS → increment success count
- Workflow FAIL at builder or later → increment failure count
- Workflow FAIL at architect → template may be wrong, flag for review
- Recalculate success_rate = successes / (successes + failures)

---

## Cache Location

```
docs/.shipit-plan-cache.json — array of plan templates
```

For monorepos: one cache per package root.

---

## Template Lifecycle

- **New template**: Created after first successful workflow of a type. success_rate = null.
- **Validated template**: success_rate >= 80% after 3+ uses. Recommended confidently.
- **Degraded template**: success_rate < 80%. Offered with warning.
- **Retired template**: success_rate < 50% after 5+ uses OR not used in 30 days. Removed from cache.

---

## What Gets Cached vs What Doesn't

**Cache (structural patterns):**
- File path patterns (not exact paths)
- Test case categories (not exact assertions)
- Order of operations
- Common risks
- Classification type

**Never cache (task-specific):**
- Exact file paths (derived at plan time)
- Specific code changes
- Root cause analysis
- Design decisions
- User requirements

The template is a skeleton. The architect fills in the bones.

---

## Cache Limits

- Maximum 20 templates per project (prevent unbounded growth)
- LRU eviction: when full, remove the least recently used template
- Templates are project-scoped, not global (different projects have different patterns)

---

## Integration with Orchestrator

The orchestrator checks the plan cache at the START of the architect phase:
1. Before spawning architect, read cache
2. If template matches, include it in architect's context: "PLAN TEMPLATE (adapt, don't copy): [template]"
3. Architect produces a full plan as normal, but starts from the template instead of blank
4. After workflow completes, update cache (capture new template or track existing)

This is transparent to the builder and reviewer — they see a normal plan, not a template.
