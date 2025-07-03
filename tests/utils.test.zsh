#!/usr/bin/env zsh

# Load test helper
source "${0:A:h}/test_helper.zsh"

# Load required modules
source "$PLUGIN_DIR/lib/config.zsh"
source "$PLUGIN_DIR/lib/context.zsh"
source "$PLUGIN_DIR/lib/providers/anthropic.zsh"
source "$PLUGIN_DIR/lib/providers/ollama.zsh"
source "$PLUGIN_DIR/lib/utils.zsh"

# Test functions

# _zsh_ai_query routing tests
test_routes_to_anthropic_provider() {
    setup_test_env
    export ZSH_AI_PROVIDER="anthropic"
    export ANTHROPIC_API_KEY="test-key"
    
    # Mock Anthropic query function
    _zsh_ai_query_anthropic() {
        echo "anthropic:$1"
    }
    
    local output
    output=$(_zsh_ai_query "test query")
    assert_equals "$output" "anthropic:test query"
    
    teardown_test_env
}

test_routes_to_ollama_provider() {
    setup_test_env
    export ZSH_AI_PROVIDER="ollama"
    
    # Mock Ollama check and query functions
    _zsh_ai_check_ollama() {
        return 0
    }
    
    _zsh_ai_query_ollama() {
        echo "ollama:$1"
    }
    
    local output
    output=$(_zsh_ai_query "test query")
    assert_equals "$output" "ollama:test query"
    
    teardown_test_env
}

test_checks_ollama_availability_before_querying() {
    setup_test_env
    export ZSH_AI_PROVIDER="ollama"
    export ZSH_AI_OLLAMA_URL="http://localhost:11434"
    
    # Mock Ollama check to fail
    _zsh_ai_check_ollama() {
        return 1
    }
    
    local output
    output=$(_zsh_ai_query "test query")
    local result=$?
    
    assert_equals "$result" "1"
    assert_contains "$output" "Ollama is not running"
    assert_contains "$output" "http://localhost:11434"
    assert_contains "$output" "ollama serve"
    
    teardown_test_env
}

# zsh-ai command tests
test_shows_usage_without_arguments() {
    setup_test_env
    export ZSH_AI_PROVIDER="anthropic"
    
    # Capture output through a subshell
    local output
    output=$(zsh-ai)
    local result=$?
    
    assert_equals "$result" "1"
    assert_contains "$output" "Usage: zsh-ai"
    assert_contains "$output" "Example:"
    assert_contains "$output" "Current provider: anthropic"
    
    teardown_test_env
}

test_shows_ollama_model_in_usage() {
    setup_test_env
    export ZSH_AI_PROVIDER="ollama"
    export ZSH_AI_OLLAMA_MODEL="llama3.2"
    
    # Capture output through a subshell
    local output
    output=$(zsh-ai)
    local result=$?
    
    assert_equals "$result" "1"
    assert_contains "$output" "Current provider: ollama"
    assert_contains "$output" "Ollama model: llama3.2"
    
    teardown_test_env
}

test_executes_command_when_user_confirms() {
    setup_test_env
    export ZSH_AI_PROVIDER="anthropic"
    export ANTHROPIC_API_KEY="test-key"
    
    # Mock query function
    _zsh_ai_query() {
        echo "echo 'Hello World'"
    }
    
    # Mock read to simulate user input
    read() {
        response="y"
    }
    
    # Track eval execution
    local eval_called=0
    local eval_command=""
    eval() {
        eval_called=1
        eval_command="$1"
    }
    
    zsh-ai "say hello" >/dev/null 2>&1
    
    assert_equals "$eval_called" "1"
    assert_equals "$eval_command" "echo 'Hello World'"
    
    teardown_test_env
}

test_does_not_execute_when_user_declines() {
    setup_test_env
    export ZSH_AI_PROVIDER="anthropic"
    export ANTHROPIC_API_KEY="test-key"
    
    # Mock query function
    _zsh_ai_query() {
        echo "rm -rf /"
    }
    
    # Mock read to simulate user input
    read() {
        response="n"
    }
    
    # Track eval execution
    local eval_called=0
    eval() {
        eval_called=1
    }
    
    zsh-ai "dangerous command" >/dev/null 2>&1
    
    assert_equals "$eval_called" "0"
    
    teardown_test_env
}

test_handles_api_errors_in_zsh_ai() {
    setup_test_env
    export ZSH_AI_PROVIDER="anthropic"
    export ANTHROPIC_API_KEY="test-key"
    
    # Mock query function to return error
    _zsh_ai_query() {
        echo "Error: API connection failed"
    }
    
    # Capture output
    local output
    output=$(zsh-ai "test query")
    local result=$?
    
    assert_equals "$result" "1"
    assert_contains "$output" "Failed to generate command"
    assert_contains "$output" "API connection failed"
    
    teardown_test_env
}

test_handles_empty_response_in_zsh_ai() {
    setup_test_env
    export ZSH_AI_PROVIDER="anthropic"
    export ANTHROPIC_API_KEY="test-key"
    
    # Mock query function to return empty
    _zsh_ai_query() {
        echo ""
    }
    
    # Capture output
    local output
    output=$(zsh-ai "test query")
    local result=$?
    
    assert_equals "$result" "1"
    assert_contains "$output" "Failed to generate command"
    
    teardown_test_env
}

test_combines_multiple_arguments() {
    setup_test_env
    export ZSH_AI_PROVIDER="anthropic"
    export ANTHROPIC_API_KEY="test-key"
    
    # Mock query function to echo the query
    _zsh_ai_query() {
        echo "query:$1"
    }
    
    # Mock read to decline execution
    read() {
        response="n"
    }
    
    local output
    output=$(zsh-ai find all python files)
    assert_contains "$output" "query:find all python files"
    
    teardown_test_env
}

test_shows_generated_command_before_prompt() {
    setup_test_env
    export ZSH_AI_PROVIDER="anthropic"
    export ANTHROPIC_API_KEY="test-key"
    
    # Mock query function
    _zsh_ai_query() {
        echo "ls -la"
    }
    
    # Mock read to decline execution
    read() {
        response="n"
    }
    
    local output
    output=$(zsh-ai "list files")
    assert_contains "$output" "ls -la"
    assert_contains "$output" "Execute? [y/N]"
    
    teardown_test_env
}

test_case_insensitive_confirmation() {
    setup_test_env
    export ZSH_AI_PROVIDER="anthropic"
    export ANTHROPIC_API_KEY="test-key"
    
    # Mock query function
    _zsh_ai_query() {
        echo "pwd"
    }
    
    # Test with uppercase Y
    read() {
        response="Y"
    }
    
    local eval_called=0
    eval() {
        eval_called=1
    }
    
    zsh-ai "show directory" >/dev/null 2>&1
    assert_equals "$eval_called" "1"
    
    teardown_test_env
}

# Run tests
echo "Running utils tests..."
test_routes_to_anthropic_provider && echo "✓ Routes to Anthropic provider when configured"
test_routes_to_ollama_provider && echo "✓ Routes to Ollama provider when configured"
test_checks_ollama_availability_before_querying && echo "✓ Checks Ollama availability before querying"
test_shows_usage_without_arguments && echo "✓ Shows usage when called without arguments"
test_shows_ollama_model_in_usage && echo "✓ Shows Ollama model in usage for Ollama provider"
test_executes_command_when_user_confirms && echo "✓ Executes command when user confirms"
test_does_not_execute_when_user_declines && echo "✓ Does not execute command when user declines"
test_handles_api_errors_in_zsh_ai && echo "✓ Handles API errors in zsh-ai command"
test_handles_empty_response_in_zsh_ai && echo "✓ Handles empty response in zsh-ai command"
test_combines_multiple_arguments && echo "✓ Combines multiple arguments in zsh-ai command"
test_shows_generated_command_before_prompt && echo "✓ Shows generated command before execution prompt"
test_case_insensitive_confirmation && echo "✓ Case insensitive confirmation acceptance"