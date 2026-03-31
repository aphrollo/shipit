# Handoff Schemas

**Typed data contracts between agents. Every handoff is validated — missing required fields trigger HANDOFF_INCOMPLETE and block the pipeline.**

The orchestrator validates each schema at the gate check (Step 3). Agents produce output matching their schema. Downstream agents consume only the fields they need.

---

## Schema 1: RESEARCH_HANDOFF

**Producer:** Researcher
**Consumer:** Architect

```yaml
RESEARCH_HANDOFF:
  required:
    research_topic: string          # What was investigated
    summary: string                 # 1-3 sentence answer
    key_findings: list[string]      # Minimum 1 finding
    relevant_files: list[string]    # file:line format, minimum 1
  optional:
    risks: list[string]             # Anything architect should worry about
    sources: list[string]           # Where info came from (URLs, file paths, docs)
    dependencies: list[string]      # External packages/services discovered
    version_info: map[string,string] # package→version mappings
  validation:
    - key_findings must be non-empty
    - relevant_files must be non-empty
    - each relevant_file must match pattern: filepath:line or filepath
```

**HANDOFF_INCOMPLETE if:** key_findings or relevant_files is empty/missing.

---

## Schema 2: PLAN_HANDOFF

**Producer:** Architect (plan phase)
**Consumer:** Builder, Reviewer (for scope verification)

```yaml
PLAN_HANDOFF:
  required:
    files_to_change: list[FileChange]  # Minimum 1
    test_cases: list[TestCase]          # Minimum 1 (except docs/config)
    order_of_operations: list[string]   # Build sequence
    risk_assessment: string             # Shared state? DB? API? Breaking changes?
  optional:
    root_cause: string              # Present if investigate phase ran
    evidence: string                # What proves the root cause
    regression_test: string         # Specific test for the bug (if investigate)
    milestones: list[Milestone]     # For large changes (20+ files)
    design_constraints: list[string] # From designer, if UI
    researcher_findings: string     # Summary from researcher, if ran
  types:
    FileChange:
      path: string                  # Relative file path
      description: string           # One-line: what changes and why
    TestCase:
      file: string                  # Test file path
      description: string           # What behavior is tested
      expected: string              # Expected outcome
    Milestone:
      name: string
      files: list[string]
      gate: string                  # What must pass before next milestone
  validation:
    - files_to_change must be non-empty
    - test_cases must be non-empty (unless task is docs-only or config-only)
    - each FileChange must have both path and description
    - each TestCase must have file and description
    - order_of_operations must be non-empty
```

**HANDOFF_INCOMPLETE if:** files_to_change, test_cases, or order_of_operations is empty/missing.

---

## Schema 3: INVESTIGATE_HANDOFF

**Producer:** Architect (investigate phase)
**Consumer:** Architect (plan phase), Builder

```yaml
INVESTIGATE_HANDOFF:
  required:
    root_cause: string              # One sentence
    evidence: string                # What proves it
    proposed_fix: string            # High-level fix description
    regression_test: string         # What test to write
  optional:
    reproduction_steps: list[string] # How to trigger the bug
    trace: string                   # Data flow from input to error
    hypothesis_log: list[Hypothesis] # Failed hypotheses (learning)
    related_files: list[string]     # Files involved in the bug
  types:
    Hypothesis:
      claim: string
      result: string                # confirmed | disproved
      evidence: string
  validation:
    - root_cause must be non-empty
    - evidence must be non-empty
    - proposed_fix must be non-empty
```

**HANDOFF_INCOMPLETE if:** root_cause, evidence, or proposed_fix is empty/missing.

---

## Schema 4: DESIGN_HANDOFF

**Producer:** Designer
**Consumer:** Builder (as constraints), Reviewer (for compliance check)

```yaml
DESIGN_HANDOFF:
  required:
    design_system_status: enum[created, updated, already_exists]
    ui_states: map[string, SevenStates]  # component→states mapping
    ai_slop_score: enum[A, B, C, D, F]
    accessibility_status: string         # "pass" or list of issues
    responsive_status: string            # "pass" or list of issues
    constraints_for_builder: list[string] # Minimum 1
  optional:
    design_decisions: list[Decision]
    color_palette: map[string, string]   # name→hex
    typography: map[string, string]      # role→font spec
    breakpoints: map[string, string]     # name→width
  types:
    SevenStates:
      empty: string
      loading: string
      error: string
      success: string
      partial: string
      overflow: string
      stale: string
    Decision:
      decision: string
      rationale: string
  validation:
    - ui_states must have all 7 states filled for each component
    - constraints_for_builder must be non-empty
    - ai_slop_score C or below triggers warning (not blocking)
```

**HANDOFF_INCOMPLETE if:** ui_states has any empty state field, or constraints_for_builder is empty.

---

## Schema 5: BUILD_HANDOFF

**Producer:** Builder
**Consumer:** Reviewer (the diff), Deployer (the result)

```yaml
BUILD_HANDOFF:
  required:
    result: enum[PASS, FAIL]
    tests_passed: integer
    tests_total: integer
    files_changed: list[string]     # Minimum 1
  optional:
    notes: string                   # Anything reviewer should know
    scope_issues: list[string]      # Scope creep discoveries (if FAIL)
    deslop_score: string            # From auto-deslop run (N/30)
    benchmark_result: string        # If benchmark ran
    lint_output: string             # Summary of lint results
  validation:
    - result must be PASS for handoff to proceed
    - tests_passed must equal tests_total (all passing)
    - files_changed must be non-empty
    - if result is FAIL, notes must explain what's blocking
```

**HANDOFF_INCOMPLETE if:** result is FAIL, or files_changed is empty on PASS.

---

## Schema 6: REVIEW_HANDOFF

**Producer:** Reviewer
**Consumer:** Builder (fix instructions on FAIL), Deployer (on PASS), Ship

```yaml
REVIEW_HANDOFF:
  required:
    result: enum[PASS, FAIL]
    critical_count: integer
    high_count: integer
    medium_count: integer
    low_count: integer
    findings: list[Finding]         # Empty list on clean PASS
  optional:
    cso_result: string              # If security audit ran
    cso_findings: list[Finding]     # Security-specific findings
    tiebreaker_rulings: list[Ruling] # If tiebreaker was invoked
    second_opinion_result: string   # If cross-model review ran
  types:
    Finding:
      severity: enum[CRITICAL, HIGH, MEDIUM, LOW]
      file_line: string             # file:line
      problem: string
      fix: string
    Ruling:
      finding: string               # Original finding reference
      verdict: enum[UPHOLD, DISMISS]
      reason: string
  validation:
    - result PASS requires critical_count == 0 AND high_count == 0
    - PASS with critical_count > 0 is a contradiction → force FAIL
    - each Finding must have severity, file_line, and problem
```

**HANDOFF_INCOMPLETE if:** result is missing, or PASS contradicts finding counts.

---

## Schema 7: DEPLOY_HANDOFF

**Producer:** Deployer
**Consumer:** Orchestrator (final report), Canary monitor

```yaml
DEPLOY_HANDOFF:
  required:
    result: enum[PASS, FAIL]
    preflight: enum[PASS, FAIL]
    deploy_status: enum[SKIPPED, SUCCESS, FAILED]
    canary: enum[HEALTHY, DEGRADED, ROLLBACK, SKIPPED]
  optional:
    health_check_url: string
    deploy_url: string              # Where the app is running
    notes: string
    error_log: string               # If FAIL, what went wrong
    rollback_command: string        # How to revert if needed
  validation:
    - result PASS requires preflight == PASS
    - if deploy_status is FAILED, result must be FAIL
    - if canary is ROLLBACK, result must be FAIL
```

**HANDOFF_INCOMPLETE if:** result or preflight is missing.

---

## Validation Rules (orchestrator enforces)

1. **Required field check**: Every required field must be present and non-empty
2. **Type check**: Enums must match allowed values, lists must be lists, integers must be integers
3. **Cross-reference check**: Builder's files_changed must be subset of Plan's files_to_change (warn if builder changed files not in plan)
4. **Contradiction check**: PASS result with CRITICAL findings = FAIL (auto-correct)
5. **Completeness check**: 7-state audits must have all 7 states filled

On HANDOFF_INCOMPLETE:
- Log which fields are missing
- Return to producing agent with specific error: "HANDOFF_INCOMPLETE: missing [field1, field2]"
- Agent retries with explicit instruction to fill missing fields
- 2 retries max, then escalate to user
