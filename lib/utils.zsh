#!/usr/bin/env zsh

# Utility functions for zsh-ai

# Function to properly escape strings for JSON
_zsh_ai_escape_json() {
    # Use printf and perl for reliable JSON escaping
    printf '%s' "$1" | perl -0777 -pe 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g; s/\r/\\r/g; s/\n/\\n/g; s/\f/\\f/g; s/\x08/\\b/g; s/[\x00-\x07\x0B\x0E-\x1F]//g'
}

# Main query function that routes to the appropriate provider
_zsh_ai_query() {
    local query="$1"
    
    if [[ "$ZSH_AI_PROVIDER" == "ollama" ]]; then
        # Check if Ollama is running first
        if ! _zsh_ai_check_ollama; then
            echo "Error: Ollama is not running at $ZSH_AI_OLLAMA_URL"
            echo "Start Ollama with: ollama serve"
            return 1
        fi
        _zsh_ai_query_ollama "$query"
    elif [[ "$ZSH_AI_PROVIDER" == "gemini" ]]; then
        _zsh_ai_query_gemini "$query"
    else
        _zsh_ai_query_anthropic "$query"
    fi
}

# Function to run a command with animated loading indicator
_zsh_ai_with_loading() {
    local cmd="$1"
    shift
    local args=("$@")
    
    # Animation frames - rotating dots
    local dots=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    local frame=0
    
    # Create a temp file for the response
    local tmpfile=$(mktemp)
    
    # Disable job control notifications
    setopt local_options no_monitor no_notify
    
    # Start the command in background
    ($cmd "${args[@]}" > "$tmpfile" 2>&1) &
    local pid=$!
    
    # Animate while waiting
    while kill -0 $pid 2>/dev/null; do
        print -n "\r\033[K${dots[$((frame % ${#dots[@]}))]}"
        ((frame++))
        sleep 0.1
    done
    
    # Clear the animation
    print -n "\r\033[K"
    
    # Get the response
    cat "$tmpfile"
    local exit_code=$?
    rm -f "$tmpfile"
    
    return $exit_code
}

# Optional: Add a helper function for users who prefer explicit commands
zsh-ai() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: zsh-ai \"your natural language command\""
        echo "Example: zsh-ai \"find all python files modified today\""
        echo ""
        echo "Current provider: $ZSH_AI_PROVIDER"
        if [[ "$ZSH_AI_PROVIDER" == "ollama" ]]; then
            echo "Ollama model: $ZSH_AI_OLLAMA_MODEL"
        elif [[ "$ZSH_AI_PROVIDER" == "gemini" ]]; then
            echo "Gemini model: $ZSH_AI_GEMINI_MODEL"
        fi
        return 1
    fi
    
    local query="$*"
    local cmd=$(_zsh_ai_query "$query")
    
    if [[ -n "$cmd" ]] && [[ "$cmd" != "Error:"* ]] && [[ "$cmd" != "API Error:"* ]]; then
        echo "$cmd"
        echo -n "Execute? [y/N] "
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            eval "$cmd"
        fi
    else
        print -P "%F{red}Failed to generate command%f"
        if [[ -n "$cmd" ]]; then
            echo "$cmd"
        fi
        return 1
    fi
}