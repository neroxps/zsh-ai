#!/usr/bin/env zsh

# Ollama API provider for zsh-ai

# Function to check if Ollama is running
_zsh_ai_check_ollama() {
    curl -s "${ZSH_AI_OLLAMA_URL}/api/tags" >/dev/null 2>&1
    return $?
}

# Function to call Ollama API
_zsh_ai_query_ollama() {
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