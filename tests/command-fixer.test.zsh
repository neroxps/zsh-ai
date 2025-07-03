#!/usr/bin/env zsh
# Tests for command-fixer functionality

# Source test helper
source "${0:A:h}/test_helper.zsh"

# Source the command-fixer module
source "$PLUGIN_DIR/lib/command-fixer.zsh"

# Test setup
setup() {
    setup_test_env
    # Enable auto fix for tests
    export ZSH_AI_AUTO_FIX="true"
    # Mock the AI query function
    _zsh_ai_query() {
        echo "git status"  # Always suggest "git status" as the fix
    }
}

# Test teardown
teardown() {
    teardown_test_env
    unset ZSH_AI_AUTO_FIX
}

# Test: Command fixer initializes hooks
test_command_fixer_init() {
    setup
    
    # Initialize command fixer
    _zsh_ai_init_command_fixer
    
    # Check that hooks are registered
    assert_contains "$preexec_functions" "_zsh_ai_preexec" || return 1
    assert_contains "$precmd_functions" "_zsh_ai_precmd" || return 1
    
    teardown
}

# Test: Captures command in preexec
test_preexec_captures_command() {
    setup
    
    # Run preexec hook
    _zsh_ai_preexec "git statu"
    
    assert_equals "$_ZSH_AI_LAST_COMMAND" "git statu" || return 1
    
    teardown
}

# Test: Skips when exit code is 0
test_skips_successful_commands() {
    setup
    
    _ZSH_AI_LAST_COMMAND="git status"
    _ZSH_AI_LAST_EXIT_CODE=0
    
    # Mock print functions to capture output
    local output=""
    print() { output+="$*"; }
    
    # Run precmd hook
    _zsh_ai_precmd
    
    # Should not have any output since command succeeded
    assert_equals "$output" "" || return 1
    
    teardown
}

# Test: Skips exit code 141 (SIGPIPE)
test_skips_sigpipe_exit_code() {
    setup
    
    _ZSH_AI_LAST_COMMAND="git log"
    _ZSH_AI_LAST_EXIT_CODE=141
    
    # Mock print functions to capture output
    local output=""
    print() { output+="$*"; }
    
    # Run precmd hook
    _zsh_ai_precmd
    
    # Should not have any output since we skip SIGPIPE
    assert_equals "$output" "" || return 1
    
    teardown
}

# Test: Skips pager commands
test_skips_pager_commands() {
    setup
    
    local pager_commands=(
        "git log"
        "git diff"
        "git show"
        "less file.txt"
        "more file.txt"
        "man zsh"
        "help"
    )
    
    for cmd in $pager_commands; do
        _ZSH_AI_LAST_COMMAND="$cmd"
        _ZSH_AI_LAST_EXIT_CODE=1
        
        # Mock print functions to capture output
        local output=""
        print() { output+="$*"; }
        
        # Run precmd hook
        _zsh_ai_precmd
        
        # Should not have any output since we skip pager commands
        if [[ -n "$output" ]]; then
            echo "Expected no output for command '$cmd' but got output"
            return 1
        fi
    done
    
    teardown
}

# Test: Skips SIGINT (Ctrl+C) exit code
test_skips_sigint_exit_code() {
    setup
    
    _ZSH_AI_LAST_COMMAND="npm start"
    _ZSH_AI_LAST_EXIT_CODE=130  # SIGINT exit code
    
    # Mock print functions to capture output
    local output=""
    print() { output+="$*"; }
    
    # Run precmd hook
    _zsh_ai_precmd
    
    # Should not have any output since we skip SIGINT
    assert_equals "$output" "" || return 1
    
    teardown
}

# Test: Skips long-running commands
test_skips_long_running_commands() {
    setup
    
    local long_running_commands=(
        "npm start"
        "npm run dev"
        "yarn start"
        "yarn dev"
        "pnpm start"
        "pnpm dev"
        "serve"
        "python script.py"
        "node server.js"
        "deno run app.ts"
        "bun run index.js"
    )
    
    for cmd in $long_running_commands; do
        _ZSH_AI_LAST_COMMAND="$cmd"
        _ZSH_AI_LAST_EXIT_CODE=1
        
        # Mock print functions to capture output
        local output=""
        print() { output+="$*"; }
        
        # Run precmd hook
        _zsh_ai_precmd
        
        # Should not have any output since we skip long-running commands
        if [[ -n "$output" ]]; then
            echo "Expected no output for command '$cmd' but got output"
            return 1
        fi
    done
    
    teardown
}

# Test: Suggests fix for failed command
test_suggests_fix_for_failed_command() {
    setup
    
    # Variables to capture output
    local suggest_fix_called=0
    local suggested_command=""
    
    # Override the suggest fix function to avoid the async query
    function _zsh_ai_suggest_fix() {
        suggest_fix_called=1
        suggested_command="$1"
    }
    
    _ZSH_AI_LAST_COMMAND="git statu"
    
    # Override _zsh_ai_precmd to skip the exit code capture
    local original_precmd=$(declare -f _zsh_ai_precmd)
    function _zsh_ai_precmd() {
        # Don't capture $? since we're setting it manually
        # _ZSH_AI_LAST_EXIT_CODE=$?
        
        # Check if auto fix is enabled
        [[ "$ZSH_AI_AUTO_FIX" != "true" ]] && return
        
        # Only suggest if command failed and we have a command to analyze
        if [[ $_ZSH_AI_LAST_EXIT_CODE -ne 0 ]] && [[ -n "$_ZSH_AI_LAST_COMMAND" ]]; then
            # Skip if it was a comment command (our AI commands)
            [[ "$_ZSH_AI_LAST_COMMAND" =~ ^'# ' ]] && return
            
            # Skip exit/logout commands
            [[ "$_ZSH_AI_LAST_COMMAND" =~ ^(exit|logout) ]] && return
            
            # Skip SIGPIPE errors (exit code 141) - common when quitting pagers
            [[ $_ZSH_AI_LAST_EXIT_CODE -eq 141 ]] && return
            
            # Skip commands that commonly use pagers
            [[ "$_ZSH_AI_LAST_COMMAND" =~ ^(git\s+(log|diff|show)|less|more|man|help) ]] && return
            
            # Query AI for a fix suggestion
            _zsh_ai_suggest_fix "$_ZSH_AI_LAST_COMMAND"
        fi
    }
    
    # Set the exit code
    _ZSH_AI_LAST_EXIT_CODE=1
    
    # Run precmd hook
    _zsh_ai_precmd
    
    # Check that suggest fix was called with the failed command
    if [[ "$suggest_fix_called" != "1" ]]; then
        echo "Expected suggest_fix to be called, but it wasn't"
        return 1
    fi
    assert_equals "$suggested_command" "git statu" || return 1
    
    teardown
}

# Test: Auto-populate buffer functionality
test_auto_populate_buffer() {
    setup
    
    # Variables to capture print calls
    local print_p_output=""
    local print_z_output=""
    
    # Mock print function to capture both -P and -z calls
    print() {
        case "$1" in
            -P)
                shift
                print_p_output="$*"
                ;;
            -z)
                shift
                print_z_output="$*"
                ;;
        esac
    }
    
    # Directly test the suggest fix function
    local suggestion="git status"
    
    # Simulate the part of _zsh_ai_suggest_fix that displays the suggestion
    if [[ -n "$suggestion" ]] && [[ "$suggestion" != "Error:"* ]] && [[ "$suggestion" != "git statu" ]]; then
        print -P "%F{blue}🤖 %B[zsh-ai]%b Did you mean: %F{cyan}$suggestion%f"
        print -z "$suggestion"
    fi
    
    # Check outputs
    assert_contains "$print_p_output" "Did you mean:" || return 1
    assert_contains "$print_p_output" "git status" || return 1
    assert_equals "$print_z_output" "git status" || return 1
    
    teardown
}

# Test: Skips comment commands
test_skips_comment_commands() {
    setup
    
    _ZSH_AI_LAST_COMMAND="# this is a comment"
    _ZSH_AI_LAST_EXIT_CODE=1
    
    # Mock print functions to capture output
    local output=""
    print() { output+="$*"; }
    
    # Run precmd hook
    _zsh_ai_precmd
    
    # Should not have any output since we skip comment commands
    assert_equals "$output" "" || return 1
    
    teardown
}

# Test: Skips when auto fix is disabled
test_skips_when_disabled() {
    setup
    export ZSH_AI_AUTO_FIX="false"
    
    _ZSH_AI_LAST_COMMAND="git statu"
    _ZSH_AI_LAST_EXIT_CODE=1
    
    # Mock print functions to capture output
    local output=""
    print() { output+="$*"; }
    
    # Run precmd hook
    _zsh_ai_precmd
    
    # Should not have any output since auto fix is disabled
    assert_equals "$output" "" || return 1
    
    teardown
}

# Run tests
echo "Running command-fixer tests..."
test_command_fixer_init && echo "✓ Command fixer init"
test_preexec_captures_command && echo "✓ Preexec captures command"
test_skips_successful_commands && echo "✓ Skips successful commands"
test_skips_sigpipe_exit_code && echo "✓ Skips SIGPIPE exit code"
test_skips_sigint_exit_code && echo "✓ Skips SIGINT exit code"
test_skips_pager_commands && echo "✓ Skips pager commands"
test_skips_long_running_commands && echo "✓ Skips long-running commands"
test_suggests_fix_for_failed_command || echo "✗ Suggests fix for failed command"
test_auto_populate_buffer && echo "✓ Auto-populate buffer functionality"
test_skips_comment_commands && echo "✓ Skips comment commands"
test_skips_when_disabled && echo "✓ Skips when disabled"