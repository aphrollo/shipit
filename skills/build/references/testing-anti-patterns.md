# Testing Anti-Patterns

5 common testing mistakes that produce tests which pass but provide no real safety.

## Anti-Pattern 1: Testing Mock Behavior Instead of Real Behavior

**Symptom:** Test suite is green but the feature is broken in production.

**Problem:** The mock returns hardcoded values that don't match what the real dependency returns. The test verifies that your code works with the mock, not that it works with the real system.

**Example (bad):**
```
mock_db.query = returns([{id: 1, name: "Alice"}])
result = userService.findByName("Alice")
assert result.name == "Alice"   # This tests the mock, not the query
```

**Fix:** Use integration tests for critical paths. When mocking is necessary, base the mock's behavior on observed real behavior. Update mocks when the real dependency changes.

**Rule of thumb:** If your test passes with a mock but fails with the real dependency, the test is worthless.

## Anti-Pattern 2: Adding Test-Only Methods to Production Code

**Symptom:** Production code contains methods like `_testGetInternalState()` or `resetForTesting()`.

**Problem:** Production code should not know it is being tested. Test-only methods create maintenance burden, increase attack surface, and signal that the code is not designed for testability.

**Example (bad):**
```
class PaymentProcessor:
    def _testSetGateway(self, mock_gateway):   # exists only for tests
        self._gateway = mock_gateway
```

**Fix:** Use dependency injection. Pass the gateway as a constructor parameter or interface. The production code stays clean, and tests provide their own implementations.

**Example (good):**
```
class PaymentProcessor:
    def __init__(self, gateway):               # inject the dependency
        self._gateway = gateway
```

## Anti-Pattern 3: Mocking Without Understanding

**Symptom:** Mock returns `true` or `200 OK` for every call. Test passes but nobody knows if the mock behaves like the real thing.

**Problem:** If you cannot explain what the real dependency does -- what it returns for valid input, how it fails, what side effects it has -- then your mock is a guess. Guesses become lies as the real dependency evolves.

**Fix:** Before writing a mock, document the real behavior:
1. What does it return on success?
2. What does it return on known failure cases?
3. What side effects does it have (writes, notifications, state changes)?
4. What are its edge cases (empty input, large input, concurrent access)?

Mock only what you can answer these questions for.

## Anti-Pattern 4: Incomplete Mock Structures

**Symptom:** Test passes but production crashes with "method not implemented" or unexpected `nil`/`undefined`.

**Problem:** The interface has 5 methods. The mock implements 2. The test only exercises the 2 implemented paths. In production, the code hits the other 3.

**Example (bad):**
```
mock_cache = {
    get: returns("cached_value"),
    set: returns(true),
    # delete, clear, has -- not implemented
}
# Test passes. Production calls cache.delete() and crashes.
```

**Fix:** When mocking an interface, implement every method. Methods you don't expect to be called should throw an explicit error: `"Unexpected call to delete() in test mock"`. This turns silent bugs into loud failures.

## Anti-Pattern 5: Testing as Afterthought

**Symptom:** Every test mirrors the implementation exactly. Refactoring breaks all tests even though behavior hasn't changed.

**Problem:** Writing implementation first, then writing tests that match the implementation, creates tests that verify the current code -- including its bugs. These tests confirm "the code does what the code does" rather than "the code does what users need."

**Example (bad):**
```
# Implementation uses a specific algorithm
def sort_users(users):
    return bubble_sort(users, key=lambda u: u.name)

# Test verifies the algorithm choice, not the outcome
def test_sort_users():
    assert sort_users.algorithm == "bubble_sort"   # brittle, tests implementation
```

**Example (good):**
```
# Test verifies the behavior
def test_sort_users():
    result = sort_users([User("Charlie"), User("Alice"), User("Bob")])
    assert [u.name for u in result] == ["Alice", "Bob", "Charlie"]   # tests outcome
```

**Fix:** Write the test first (TDD). Describe the desired behavior before writing the code. The test should answer "what should happen?" not "how does it happen?"
