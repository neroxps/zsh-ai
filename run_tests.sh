#!/bin/bash

# Run all zsh-ai tests

echo "Running AI-ZSH Tests"
echo "==================="
echo

# Test files
test_files=(
    "tests/config.test.zsh"
    "tests/context.test.zsh" 
    "tests/providers/anthropic.test.zsh"
    "tests/providers/ollama.test.zsh"
    "tests/utils.test.zsh"
    "tests/widget.test.zsh"
)

# Run each test file
for test_file in "${test_files[@]}"; do
    echo
    echo "Running $test_file"
    echo "-------------------"
    if [[ -f "$test_file" ]]; then
        ./"$test_file"
    else
        echo "Error: Test file not found: $test_file"
    fi
done

echo
echo "All tests completed!"