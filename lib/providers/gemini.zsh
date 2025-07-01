#!/usr/bin/env zsh

# Google Gemini API provider for zsh-ai

# Function to call Gemini API
_zsh_ai_query_gemini() {
    local query="$1"
    local response
    
    # Build context
    local context=$(_zsh_ai_build_context)
    local escaped_context=$(_zsh_ai_escape_json "$context")
    
    # Prepare the JSON payload - escape quotes in the query
    local escaped_query=$(_zsh_ai_escape_json "$query")
    local json_payload=$(cat <<EOF
{
    "contents": [
        {
            "role": "user",
            "parts": [
                {
                    "text": "$escaped_query"
                }
            ]
        }
    ],
    "systemInstruction": {
        "parts": [
            {
                "text": "You are a helpful assistant that generates shell commands. When given a natural language description, respond ONLY with the appropriate shell command. Do not include any explanation, markdown formatting, or backticks. Just the raw command.\n\nContext:\n$escaped_context"
            }
        ]
    },
    "generationConfig": {
        "temperature": 0.3,
        "maxOutputTokens": 256
    }
}
EOF
)
    
    # Call the API
    response=$(curl -s "https://generativelanguage.googleapis.com/v1beta/models/${ZSH_AI_GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}" \
        --header "content-type: application/json" \
        --data "$json_payload" 2>&1)
    
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to connect to Gemini API"
        return 1
    fi
    
    # Debug: Uncomment to see raw response
    # echo "DEBUG: Raw response: $response" >&2
    
    # Extract the content from the response
    # Try using jq if available, otherwise fall back to sed/grep
    if command -v jq &> /dev/null; then
        local result=$(echo "$response" | jq -r '.candidates[0].content.parts[0].text // empty' 2>/dev/null)
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