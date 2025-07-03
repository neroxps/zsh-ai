#!/usr/bin/env zsh
# Minimal BATS-compatible test runner for zsh-ai

# Test state
typeset -g output=""
typeset -g state=0
typeset -g lines=()

# Define @test function that will be overridden
@test() { : }

# Define @setup and @teardown defaults
@setup() { : }
@teardown() { : }

# BATS-compatible run function
run() {
    output=$("$@" 2>&1)
    state=$?
    lines=("${(@f)output}")
}

# BATS-compatible assert function
assert() {
    case "$1" in
        \$state)
            shift
            [[ "$1" == "equals" ]] && [[ $state -eq $2 ]]
            ;;
        "\$output")
            shift
            if [[ "$1" == "equals" ]]; then
                [[ "$output" == "$2" ]]
            elif [[ "$1" == "contains" ]]; then
                [[ "$output" == *"$2"* ]]
            fi
            ;;
        *)
            "$@"
            ;;
    esac
}

# Helper assertions
assert_equals() {
    [[ "$1" == "$2" ]]
}

assert_contains() {
    [[ "$1" == *"$2"* ]]
}

# Export functions so they're available to sourced tests
typeset -fx @test @setup @teardown run assert assert_equals assert_contains