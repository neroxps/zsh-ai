#!/usr/bin/env zsh
# Simple test framework for zsh-ai tests

# Test framework state
typeset -g CURRENT_SUITE=""
typeset -g CURRENT_TEST=""
typeset -g TEST_PASSED=0
typeset -g TEST_FAILED=0
typeset -g TEST_OUTPUT=""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test suite definition
describe() {
    CURRENT_SUITE="$1"
    echo -e "${BLUE}Testing: $CURRENT_SUITE${NC}"
}

# Test case definition
it() {
    CURRENT_TEST="$1"
    # The test body will be on the next lines
}

# Expectation matchers
expect() {
    local actual="$1"
    shift
    
    case "$1" in
        to_equal)
            shift
            local expected="$1"
            if [[ "$actual" == "$expected" ]]; then
                echo -e "  ${GREEN}✓${NC} $CURRENT_TEST"
                TEST_PASSED=$((TEST_PASSED + 1))
            else
                echo -e "  ${RED}✗${NC} $CURRENT_TEST"
                echo -e "    Expected: '$expected'"
                echo -e "    Actual:   '$actual'"
                TEST_FAILED=$((TEST_FAILED + 1))
            fi
            ;;
        to_contain)
            shift
            local substring="$1"
            if [[ "$actual" == *"$substring"* ]]; then
                echo -e "  ${GREEN}✓${NC} $CURRENT_TEST"
                TEST_PASSED=$((TEST_PASSED + 1))
            else
                echo -e "  ${RED}✗${NC} $CURRENT_TEST"
                echo -e "    Expected to contain: '$substring'"
                echo -e "    Actual: '$actual'"
                TEST_FAILED=$((TEST_FAILED + 1))
            fi
            ;;
        to_be_empty)
            if [[ -z "$actual" ]]; then
                echo -e "  ${GREEN}✓${NC} $CURRENT_TEST"
                TEST_PASSED=$((TEST_PASSED + 1))
            else
                echo -e "  ${RED}✗${NC} $CURRENT_TEST"
                echo -e "    Expected empty, got: '$actual'"
                TEST_FAILED=$((TEST_FAILED + 1))
            fi
            ;;
        to_exist)
            if [[ -e "$actual" ]]; then
                echo -e "  ${GREEN}✓${NC} $CURRENT_TEST"
                TEST_PASSED=$((TEST_PASSED + 1))
            else
                echo -e "  ${RED}✗${NC} $CURRENT_TEST"
                echo -e "    Expected file to exist: '$actual'"
                TEST_FAILED=$((TEST_FAILED + 1))
            fi
            ;;
    esac
}

# Run tests function
run_tests() {
    echo ""
    echo "================================"
    echo "Test Summary:"
    echo -e "  ${GREEN}Passed: $TEST_PASSED${NC}"
    echo -e "  ${RED}Failed: $TEST_FAILED${NC}"
    echo "================================"
    
    if [[ $TEST_FAILED -gt 0 ]]; then
        exit 1
    else
        exit 0
    fi
}

# Mock output capture
output_of() {
    "$@" 2>&1
}