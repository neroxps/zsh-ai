#!/usr/bin/env zsh

# zsh-ai - AI-powered command suggestions for zsh
# Requires ANTHROPIC_API_KEY environment variable to be set

# Check if API key is set
if [[ -z "$ANTHROPIC_API_KEY" ]]; then
    echo "zsh-ai: Warning: ANTHROPIC_API_KEY not set. Plugin will not function."
    return 1
fi

# Function to call Anthropic API
_zsh_ai_query() {
    local query="$1"
    local response
    
    # Prepare the JSON payload - escape quotes in the query
    local escaped_query="${query//\"/\\\"}"
    local json_payload=$(cat <<EOF
{
    "model": "claude-3-5-sonnet-20241022",
    "max_tokens": 256,
    "system": "You are a helpful assistant that generates shell commands. When given a natural language description, respond ONLY with the appropriate shell command. Do not include any explanation, markdown formatting, or backticks. Just the raw command.",
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

# Custom widget to intercept Enter key
_zsh_ai_accept_line() {
    # Check if the line starts with "# "
    if [[ "$BUFFER" =~ ^'# ' ]]; then
        # Extract the query (remove the "# " prefix)
        local query="${BUFFER:2}"
        
        # Save the current buffer
        local saved_buffer="$BUFFER"
        
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