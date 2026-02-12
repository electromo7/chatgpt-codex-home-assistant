#!/usr/bin/env bash
# Run all project tests.
# Usage: ./tests/run_tests.sh
#
# Dependencies:
#   pip install pytest pyyaml
#   npm install -g bats        (or: apt-get install bats)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "${SCRIPT_DIR}")"
EXIT_CODE=0

echo "========================================"
echo " Running project tests"
echo "========================================"

# --- Python / pytest tests ---
echo ""
echo "--- pytest: config & structure tests ---"
if python3 -m pytest --version &>/dev/null; then
    if python3 -m pytest "${SCRIPT_DIR}/test_config.py" -v; then
        echo "  [PASS] pytest tests passed"
    else
        echo "  [FAIL] pytest tests failed"
        EXIT_CODE=1
    fi
else
    echo "  [SKIP] pytest not found (pip install pytest pyyaml)"
    echo "  Install with: pip3 install pytest pyyaml"
    EXIT_CODE=1
fi

# --- bats tests ---
echo ""
echo "--- bats: shell script tests ---"
if command -v bats &>/dev/null; then
    if bats "${SCRIPT_DIR}/test_run.bats"; then
        echo "  [PASS] bats tests passed"
    else
        echo "  [FAIL] bats tests failed"
        EXIT_CODE=1
    fi
else
    echo "  [SKIP] bats not found (npm install -g bats)"
    EXIT_CODE=1
fi

echo ""
echo "========================================"
if [ "${EXIT_CODE}" -eq 0 ]; then
    echo " All tests passed!"
else
    echo " Some tests failed (exit code ${EXIT_CODE})"
fi
echo "========================================"

exit "${EXIT_CODE}"
