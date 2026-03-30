#!/usr/bin/env bash
# find-polluter.sh -- Bisect a test suite to find which test pollutes shared
# state and causes another test to fail.
#
# Usage: ./find-polluter.sh <test-command> <failing-test>
#
# Example:
#   ./find-polluter.sh "pytest" "test_user_profile"
#   ./find-polluter.sh "go test ./..." "TestGetUser"
#   ./find-polluter.sh "npm test --" "should return user profile"
#
# How it works:
#   1. Run the full suite to collect the ordered list of tests.
#   2. Find the position of the failing test.
#   3. Binary search through the tests that run BEFORE the failing test.
#   4. At each step, run a subset of preceding tests followed by the failing
#      test. If it fails, the polluter is in that subset. If it passes, the
#      polluter is in the other half.
#   5. Narrow down to the single test that causes the failure.

set -euo pipefail

# -- Argument validation --
if [ $# -lt 2 ]; then
    echo "Usage: $0 <test-command> <failing-test>"
    echo ""
    echo "  test-command   The command to run tests (e.g., 'pytest', 'go test ./...')"
    echo "  failing-test   The name or identifier of the test that fails"
    exit 1
fi

TEST_CMD="$1"
FAILING_TEST="$2"

echo "=== Find Polluter ==="
echo "Test command: $TEST_CMD"
echo "Failing test: $FAILING_TEST"
echo ""

# -- Step 1: Confirm the failing test passes in isolation --
# If it fails alone, the problem is not pollution -- it's a broken test.
echo "[Step 1] Verifying that '$FAILING_TEST' passes in isolation..."
if $TEST_CMD -run "$FAILING_TEST" -count=1 > /dev/null 2>&1; then
    echo "  PASS -- test passes alone. Proceeding to find polluter."
else
    echo "  FAIL -- test fails even in isolation. This is not a pollution problem."
    echo "  Fix the test itself first."
    exit 1
fi

# -- Step 2: Collect the full ordered test list --
# This uses 'go test -v' or 'pytest -v' style output and extracts test names.
# Adjust the grep pattern for your test runner.
echo ""
echo "[Step 2] Collecting ordered test list from full suite..."
FULL_OUTPUT=$($TEST_CMD -v 2>&1 || true)

# Extract test names. This pattern works for Go ("--- FAIL: TestName" / "--- PASS: TestName")
# and pytest ("test_name PASSED" / "test_name FAILED"). Adapt as needed.
TEST_LIST=$(echo "$FULL_OUTPUT" | grep -oP '(?<=--- (PASS|FAIL): )\S+|(?<=:: )\S+(?= (PASSED|FAILED))' || true)

if [ -z "$TEST_LIST" ]; then
    echo "  Could not extract test names from output."
    echo "  You may need to adjust the grep pattern in this script for your test runner."
    exit 1
fi

TOTAL_TESTS=$(echo "$TEST_LIST" | wc -l)
echo "  Found $TOTAL_TESTS tests."

# -- Step 3: Find the position of the failing test --
FAILING_INDEX=$(echo "$TEST_LIST" | grep -n "$FAILING_TEST" | head -1 | cut -d: -f1)

if [ -z "$FAILING_INDEX" ]; then
    echo "  Could not find '$FAILING_TEST' in the test list."
    exit 1
fi

echo "  '$FAILING_TEST' is at position $FAILING_INDEX."

# Get all tests that run BEFORE the failing test (these are the candidates).
PRECEDING=$(echo "$TEST_LIST" | head -n $((FAILING_INDEX - 1)))
PRECEDING_COUNT=$(echo "$PRECEDING" | wc -l)

if [ "$PRECEDING_COUNT" -eq 0 ]; then
    echo "  No tests run before '$FAILING_TEST'. Cannot be pollution."
    exit 1
fi

echo "  $PRECEDING_COUNT candidate polluter tests."

# -- Step 4: Binary search for the polluter --
echo ""
echo "[Step 3] Binary searching for polluter..."

# Convert preceding tests to an array.
mapfile -t CANDIDATES <<< "$PRECEDING"

low=0
high=$((${#CANDIDATES[@]} - 1))
iteration=0

while [ "$low" -lt "$high" ]; do
    iteration=$((iteration + 1))
    mid=$(( (low + high) / 2 ))

    # Build the subset: tests from index low..mid, then the failing test.
    subset=""
    for i in $(seq "$low" "$mid"); do
        if [ -n "$subset" ]; then
            subset="$subset|"
        fi
        subset="$subset${CANDIDATES[$i]}"
    done
    run_pattern="($subset|$FAILING_TEST)"

    echo "  Iteration $iteration: testing candidates [$low..$mid] ($(( mid - low + 1 )) tests)"

    # Run the subset followed by the failing test.
    if $TEST_CMD -run "$run_pattern" -count=1 > /dev/null 2>&1; then
        # Failing test PASSED -- polluter is NOT in this subset.
        # Search the upper half.
        echo "    -> PASS: polluter is in upper half"
        low=$((mid + 1))
    else
        # Failing test FAILED -- polluter IS in this subset.
        # Search the lower half.
        echo "    -> FAIL: polluter is in lower half"
        high=$mid
    fi
done

echo ""
echo "=== POLLUTER FOUND ==="
echo "Test '${CANDIDATES[$low]}' pollutes shared state and causes '$FAILING_TEST' to fail."
echo ""
echo "Next steps:"
echo "  1. Run these two tests together to confirm:"
echo "     $TEST_CMD -run '(${CANDIDATES[$low]}|$FAILING_TEST)' -v"
echo "  2. Look at '${CANDIDATES[$low]}' for shared state mutations:"
echo "     - Global variables modified without cleanup"
echo "     - Database rows inserted without rollback"
echo "     - Environment variables set without restoration"
echo "     - Files created without cleanup"
echo "     - Singletons or caches populated with test-specific data"
