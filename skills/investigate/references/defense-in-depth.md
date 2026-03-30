# Defense in Depth: 4-Layer Validation Architecture

Each layer catches what the previous one missed. A bug must slip past all four layers to reach production undetected.

## Layer 1: Entry -- Input Validation at System Boundaries

**Where:** API request handlers, CLI argument parsers, file readers, message queue consumers, form submissions.

**What to check:**
- Type correctness (string vs number vs boolean)
- Required fields present
- Value ranges and string lengths
- Format validation (email, URL, date, UUID)
- Encoding and character set

**Principle:** Reject bad data before it enters the system. Every byte from outside your process is untrusted.

```
# Pseudocode
func handleRequest(req):
    if not req.has("user_id"):
        return error(400, "user_id is required")
    if not isUUID(req.user_id):
        return error(400, "user_id must be a valid UUID")
    # Only clean data reaches business logic
    processUser(req.user_id)
```

## Layer 2: Business Logic -- Assertions and Invariant Checks

**Where:** Function entry points in core logic, state transitions, calculation steps.

**What to check:**
- Preconditions: assert inputs meet function's contract
- Postconditions: assert outputs are sane before returning
- Invariants: assert relationships between fields remain consistent (e.g., start < end)

**Principle:** Production code should assert what it assumes. If the assumption is wrong, fail loudly instead of producing wrong results silently.

```
# Pseudocode
func calculateDiscount(price, percentage):
    assert price >= 0, "price must be non-negative"
    assert 0 <= percentage <= 100, "percentage out of range"
    result = price * (1 - percentage / 100)
    assert result <= price, "discount cannot increase price"
    return result
```

## Layer 3: Environment -- Guards for Runtime Conditions

**Where:** Application startup, configuration loading, external service connections, deployment checks.

**What to check:**
- Required environment variables are set and non-empty
- Database connection is reachable and points to the correct instance
- External service URLs resolve and respond
- File system paths exist with correct permissions
- Resource limits (memory, disk, file descriptors) are adequate

**Principle:** Fail fast with a clear error message. A crash at startup with "DATABASE_URL not set" saves hours compared to a cryptic error 3 days later when a query finally runs.

```
# Pseudocode
func boot():
    required = ["DATABASE_URL", "API_KEY", "REDIS_HOST"]
    for var in required:
        if not env.get(var):
            fatal("Missing required env var: " + var)
    if not db.ping():
        fatal("Cannot reach database at " + env.DATABASE_URL)
```

## Layer 4: Debug -- Development Instrumentation

**Where:** Throughout the codebase, gated behind debug flags or log levels.

**What to include:**
- Verbose logging of function entry/exit with arguments
- State dumps at critical decision points
- Trace IDs that follow a request across services
- Timing measurements for performance-sensitive paths
- Data snapshots before and after mutations

**Principle:** Strip or gate behind flags for production. Debug instrumentation should be invisible at runtime unless explicitly enabled.

```
# Pseudocode
func processOrder(order):
    debug.log("processOrder entry", {order_id: order.id, items: order.items.length})
    debug.snapshot("order_before", order)
    # ... processing ...
    debug.snapshot("order_after", order)
    debug.timing("processOrder", elapsed)
```

## How the Layers Work Together

```
Request --> [L1: Entry Validation] --> [L2: Business Logic Assertions] --> Response
                                              |
                                       [L3: Environment Guards]
                                              |
                                       [L4: Debug Instrumentation]
```

- L1 stops malformed input from entering the system
- L2 catches logic errors and contract violations
- L3 catches infrastructure and configuration problems
- L4 provides the data needed to diagnose anything that slips through

When adding a fix for a bug, add validation at the appropriate layer. When unsure which layer, start at L1 and work inward.
