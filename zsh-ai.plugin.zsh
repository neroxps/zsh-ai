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
    
    # Prepare the JSON payload
    local json_payload=$(printf '{
        "model": "claude-3-5-sonnet-20241022",
        "max_tokens": 256,
        "messages": [
            {
                "role": "system",
                "content": "You are a helpful assistant that generates shell commands. When given a natural language description, respond ONLY with the appropriate shell command. Do not include any explanation, markdown formatting, or backticks. Just the raw command."
            },
            {
                "role": "user",
                "content": "%s"
            }
        ]
    }' "$query")
    
    # Call the API
    response=$(curl -s https://api.anthropic.com/v1/messages \
        --header "x-api-key: $ANTHROPIC_API_KEY" \
        --header "anthropic-version: 2023-06-01" \
        --header "content-type: application/json" \
        --data "$json_payload" 2>/dev/null)
    
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to connect to Anthropic API"
        return 1
    fi
    
    # Extract the content from the response
    # Try using jq if available, otherwise fall back to sed/grep
    if command -v jq &> /dev/null; then
        echo "$response" | jq -r '.content[0].text // empty' 2>/dev/null
    else
        # Fallback parsing without jq
        echo "$response" | grep -o '"text":"[^"]*"' | head -1 | sed 's/"text":"\([^"]*\)"/\1/'
    fi
}

# Custom widget to intercept Enter key
_zsh_ai_accept_line() {
    # Check if the line starts with "# "
    if [[ "$BUFFER" =~ ^'# ' ]]; then
        # Extract the query (remove the "# " prefix)
        local query="${BUFFER:2}"
        
        # Show loading message
        echo "🤔 Thinking..."
        
        # Get AI response
        local cmd=$(_zsh_ai_query "$query")
        
        if [[ -n "$cmd" ]] && [[ "$cmd" != "Error:"* ]]; then
            # Replace the buffer with the generated command
            BUFFER="$cmd"
            
            # Move cursor to end of line
            CURSOR=$#BUFFER
            
            # Show the command and let user edit/confirm
            echo "💡 Generated command: $cmd"
            echo "Press Enter to execute, or edit the command first"
            
            # Redraw the prompt with the new command
            zle reset-prompt
        else
            echo "❌ Failed to generate command"
            BUFFER=""
            zle reset-prompt
        fi
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
    
    if [[ -n "$cmd" ]] && [[ "$cmd" != "Error:"* ]]; then
        echo "Generated command: $cmd"
        echo -n "Execute? [y/N] "
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            eval "$cmd"
        fi
    else
        echo "Failed to generate command"
        return 1
    fi
}