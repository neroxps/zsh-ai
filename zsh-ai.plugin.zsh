#!/usr/bin/env zsh

# zsh-ai - AI-powered command suggestions for zsh
# Supports both Anthropic Claude and local Ollama models

# Set default values for configuration
: ${ZSH_AI_PROVIDER:="anthropic"}  # Default to anthropic for backwards compatibility
: ${ZSH_AI_OLLAMA_MODEL:="llama3.2"}  # Popular fast model
: ${ZSH_AI_OLLAMA_URL:="http://localhost:11434"}  # Default Ollama URL

# Provider validation
if [[ "$ZSH_AI_PROVIDER" != "anthropic" ]] && [[ "$ZSH_AI_PROVIDER" != "ollama" ]]; then
    echo "zsh-ai: Error: Invalid provider '$ZSH_AI_PROVIDER'. Use 'anthropic' or 'ollama'."
    return 1
fi

# Check requirements based on provider
if [[ "$ZSH_AI_PROVIDER" == "anthropic" ]]; then
    if [[ -z "$ANTHROPIC_API_KEY" ]]; then
        echo "zsh-ai: Warning: ANTHROPIC_API_KEY not set. Plugin will not function."
        echo "zsh-ai: Set ANTHROPIC_API_KEY or use ZSH_AI_PROVIDER=ollama for local models."
        return 1
    fi
fi

# Function to detect project type
_zsh_ai_detect_project_type() {
    local project_type="unknown"
    
    if [[ -f "package.json" ]]; then
        project_type="node"
    elif [[ -f "Cargo.toml" ]]; then
        project_type="rust"
    elif [[ -f "requirements.txt" ]] || [[ -f "setup.py" ]] || [[ -f "pyproject.toml" ]]; then
        project_type="python"
    elif [[ -f "Gemfile" ]]; then
        project_type="ruby"
    elif [[ -f "go.mod" ]]; then
        project_type="go"
    elif [[ -f "composer.json" ]]; then
        project_type="php"
    elif [[ -f "pom.xml" ]] || [[ -f "build.gradle" ]]; then
        project_type="java"
    elif [[ -f "docker-compose.yml" ]] || [[ -f "Dockerfile" ]]; then
        project_type="docker"
    fi
    
    echo "$project_type"
}

# Function to get git context
_zsh_ai_get_git_context() {
    local git_info=""
    
    if git rev-parse --is-inside-work-tree &>/dev/null; then
        local branch=$(git branch --show-current 2>/dev/null)
        local git_status="clean"
        
        if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
            git_status="dirty"
        fi
        
        git_info="Git: branch=$branch, status=$git_status"
    fi
    
    echo "$git_info"
}

# Function to get directory context
_zsh_ai_get_directory_context() {
    local dir_context="Current directory: $(pwd)"
    local file_count=$(ls -1 2>/dev/null | wc -l | tr -d ' ')
    
    if [[ $file_count -le 20 ]]; then
        local files=$(ls -1 2>/dev/null | head -10 | tr '\n' ', ' | sed 's/, $//')
        if [[ -n "$files" ]]; then
            dir_context="$dir_context\nFiles: $files"
            if [[ $file_count -gt 10 ]]; then
                dir_context="$dir_context ... and $((file_count - 10)) more"
            fi
        fi
    else
        dir_context="$dir_context\nFiles: $file_count files in directory"
    fi
    
    echo "$dir_context"
}

# Function to build context
_zsh_ai_build_context() {
    local context=""
    
    # Add directory context
    context="$(_zsh_ai_get_directory_context)"
    
    # Add project type
    local project_type=$(_zsh_ai_detect_project_type)
    if [[ "$project_type" != "unknown" ]]; then
        context="$context\nProject type: $project_type"
    fi
    
    # Add git context
    local git_context=$(_zsh_ai_get_git_context)
    if [[ -n "$git_context" ]]; then
        context="$context\n$git_context"
    fi
    
    # Add OS context
    context="$context\nOS: $(uname -s)"
    
    echo "$context"
}

# Function to check if Ollama is running
_zsh_ai_check_ollama() {
    curl -s "${ZSH_AI_OLLAMA_URL}/api/tags" >/dev/null 2>&1
    return $?
}

# Function to call Anthropic API
_zsh_ai_query_anthropic() {
    local query="$1"
    local response
    
    # Build context
    local context=$(_zsh_ai_build_context)
    local escaped_context="${context//\"/\\\"}"
    escaped_context="${escaped_context//$'\n'/\\n}"
    
    # Prepare the JSON payload - escape quotes in the query
    local escaped_query="${query//\"/\\\"}"
    local json_payload=$(cat <<EOF
{
    "model": "claude-3-5-sonnet-20241022",
    "max_tokens": 256,
    "system": "You are a helpful assistant that generates shell commands. When given a natural language description, respond ONLY with the appropriate shell command. Do not include any explanation, markdown formatting, or backticks. Just the raw command.\n\nContext:\n$escaped_context",
    "messages": [
        {
            "role": "user",
            "content": "$escaped_query"
        }
    ]
}
EOF
)
    
    # Call the API
    response=$(curl -s https://api.anthropic.com/v1/messages \
        --header "x-api-key: $ANTHROPIC_API_KEY" \
        --header "anthropic-version: 2023-06-01" \
        --header "content-type: application/json" \
        --data "$json_payload" 2>&1)
    
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to connect to Anthropic API"
        return 1
    fi
    
    # Debug: Uncomment to see raw response
    # echo "DEBUG: Raw response: $response" >&2
    
    # Extract the content from the response
    # Try using jq if available, otherwise fall back to sed/grep
    if command -v jq &> /dev/null; then
        local result=$(echo "$response" | jq -r '.content[0].text // empty' 2>/dev/null)
        if [[ -z "$result" ]]; then
            # Check for error message
            local error=$(echo "$response" | jq -r '.error.message // empty' 2>/dev/null)
            if [[ -n "$error" ]]; then
                echo "API Error: $error"
            else
                echo "Error: Unable to parse response"
            fi
            return 1
        fi
        echo "$result"
    else
        # Fallback parsing without jq
        local result=$(echo "$response" | grep -o '"text":"[^"]*"' | head -1 | sed 's/"text":"\([^"]*\)"/\1/')
        if [[ -z "$result" ]]; then
            echo "Error: Unable to parse response (install jq for better reliability)"
            return 1
        fi
        echo "$result"
    fi
}

# Function to call Ollama API
_zsh_ai_query_ollama() {
    echo "Using Ollama model: $ZSH_AI_OLLAMA_MODEL"
    local query="$1"
    local response
    
    # Build context
    local context=$(_zsh_ai_build_context)
    local escaped_context="${context//\"/\\\"}"
    escaped_context="${escaped_context//$'\n'/\\n}"
    
    # Prepare the JSON payload
    local escaped_query="${query//\"/\\\"}"
    local json_payload=$(cat <<EOF
{
    "model": "$ZSH_AI_OLLAMA_MODEL",
    "prompt": "$escaped_query",
    "system": "You are a helpful assistant that generates shell commands. When given a natural language description, respond ONLY with the appropriate shell command. Do not include any explanation, markdown formatting, or backticks. Just the raw command.\n\nContext:\n$escaped_context",
    "stream": false,
    "options": {
        "temperature": 0.3
    }
}
EOF
)
    
    # Call the API
    response=$(curl -s "${ZSH_AI_OLLAMA_URL}/api/generate" \
        --header "content-type: application/json" \
        --data "$json_payload" 2>&1)
    
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to connect to Ollama. Is it running?"
        return 1
    fi
    
    # Extract the response
    if command -v jq &> /dev/null; then
        local result=$(echo "$response" | jq -r '.response // empty' 2>/dev/null)
        if [[ -z "$result" ]]; then
            # Check for error message
            local error=$(echo "$response" | jq -r '.error // empty' 2>/dev/null)
            if [[ -n "$error" ]]; then
                echo "Ollama Error: $error"
            else
                echo "Error: Unable to parse Ollama response"
            fi
            return 1
        fi
        # Clean up the response - remove any trailing newlines
        result=$(echo "$result" | tr -d '\n' | sed 's/[[:space:]]*$//')
        echo "$result"
    else
        # Fallback parsing without jq
        local result=$(echo "$response" | grep -o '"response":"[^"]*"' | head -1 | sed 's/"response":"\([^"]*\)"/\1/')
        if [[ -z "$result" ]]; then
            echo "Error: Unable to parse response (install jq for better reliability)"
            return 1
        fi
        # Clean up the response
        result=$(echo "$result" | tr -d '\n' | sed 's/[[:space:]]*$//')
        echo "$result"
    fi
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
    else
        _zsh_ai_query_anthropic "$query"
    fi
}

# Custom widget to intercept Enter key
_zsh_ai_accept_line() {
    # Check if the line starts with "# " and handle multiline input
    if [[ "$BUFFER" =~ ^'# ' ]]; then
        # Check if buffer contains newlines (multiline command)
        if [[ "$BUFFER" == *$'\n'* ]]; then
            # Multiline command detected - execute normally without AI processing
            zle .accept-line
            return
        fi
        
        # Extract the query (remove the "# " prefix)
        local query="${BUFFER:2}"
        
        # Add a loading indicator
        local saved_buffer="$BUFFER"
        BUFFER="$BUFFER ⏳"
        zle redisplay
        
        # Get AI response
        local cmd=$(_zsh_ai_query "$query")
        
        if [[ -n "$cmd" ]] && [[ "$cmd" != "Error:"* ]] && [[ "$cmd" != "API Error:"* ]]; then
            # Simply replace the buffer with the generated command
            BUFFER="$cmd"
            
            # Move cursor to end of line
            CURSOR=$#BUFFER
        else
            # Show error
            print -P "%F{red}❌ Failed to generate command%f"
            if [[ -n "$cmd" ]]; then
                print -P "%F{red}$cmd%f"
            fi
            BUFFER=""
        fi
        
        # Redraw the prompt
        zle reset-prompt
    else
        # Normal command - execute as usual
        zle .accept-line
    fi
}

# Create the widget and bind it
zle -N accept-line _zsh_ai_accept_line

# Optional: Add a helper function for users who prefer explicit commands
zsh-ai() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: zsh-ai \"your natural language command\""
        echo "Example: zsh-ai \"find all python files modified today\""
        echo ""
        echo "Current provider: $ZSH_AI_PROVIDER"
        if [[ "$ZSH_AI_PROVIDER" == "ollama" ]]; then
            echo "Ollama model: $ZSH_AI_OLLAMA_MODEL"
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
