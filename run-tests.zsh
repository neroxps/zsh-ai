#!/usr/bin/env zsh

# Simple test runner for zsh-ai that runs existing test files

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test statistics
typeset -g TOTAL_PASSED=0
typeset -g TOTAL_FAILED=0
typeset -g TOTAL_FILES=0
typeset -g FAILED_FILES=()

# Function to run a test file
run_test_file() {
    local test_file="$1"
    local test_output
    local exit_code
    
    echo -e "${YELLOW}Running ${test_file}...${NC}"
    
    # Run the test file and capture output
    test_output=$(zsh "$test_file" 2>&1)
    exit_code=$?
    
    # Display the output
    echo "$test_output"
    
    # Count successes and failures from output
    local passed=$(echo "$test_output" | grep -c "✓")
    local failed=$(echo "$test_output" | grep -c "✗")
    
    TOTAL_PASSED=$((TOTAL_PASSED + passed))
    TOTAL_FAILED=$((TOTAL_FAILED + failed))
    
    if [[ $exit_code -ne 0 ]] || [[ $failed -gt 0 ]]; then
        FAILED_FILES+=("$test_file")
    fi
    
    echo ""
    return $exit_code
}

# Main test runner
main() {
    local test_dir="${1:-tests}"
    
    echo -e "${BLUE}Running zsh-ai tests...${NC}"
    echo ""
    
    # Find all test files
    local test_files=()
    test_files=($test_dir/**/*.test.zsh(N))
    
    if [[ ${#test_files} -eq 0 ]]; then
        echo -e "${YELLOW}No test files found in $test_dir${NC}"
        exit 1
    fi
    
    TOTAL_FILES=${#test_files}
    
    # Run each test file
    for test_file in $test_files; do
        run_test_file "$test_file"
    done
    
    # Overall summary
    echo "================================"
    echo -e "${BLUE}Test Summary:${NC}"
    echo -e "  Test Files: $TOTAL_FILES"
    echo -e "  ${GREEN}Tests Passed: $TOTAL_PASSED${NC}"
    echo -e "  ${RED}Tests Failed: $TOTAL_FAILED${NC}"
    
    if [[ ${#FAILED_FILES} -gt 0 ]]; then
        echo ""
        echo -e "${RED}Failed test files:${NC}"
        for file in $FAILED_FILES; do
            echo "  - $file"
        done
    fi
    echo "================================"
    
    if [[ $TOTAL_FAILED -gt 0 || ${#FAILED_FILES} -gt 0 ]]; then
        exit 1
    else
        exit 0
    fi
}

# Run tests if called directly
if [[ "${ZSH_EVAL_CONTEXT}" == "toplevel" ]]; then
    main "$@"
fi