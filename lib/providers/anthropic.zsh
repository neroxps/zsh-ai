#!/usr/bin/env zsh

# Anthropic Claude API provider for zsh-ai

# Function to call Anthropic API
_zsh_ai_query_anthropic() {
    local query="$1"
    local response
    
    # Build context
    local context=$(_zsh_ai_build_context)
    local escaped_context=$(_zsh_ai_escape_json "$context")
    
    # Prepare the JSON payload - escape quotes in the query
    local escaped_query=$(_zsh_ai_escape_json "$query")
    local json_payload=$(cat <<EOF
{
    "model": "$ZSH_AI_ANTHROPIC_MODEL",
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