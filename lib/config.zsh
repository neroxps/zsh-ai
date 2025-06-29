#!/usr/bin/env zsh

# Configuration and validation for zsh-ai

# Set default values for configuration
: ${ZSH_AI_PROVIDER:="anthropic"}  # Default to anthropic for backwards compatibility
: ${ZSH_AI_OLLAMA_MODEL:="llama3.2"}  # Popular fast model
: ${ZSH_AI_OLLAMA_URL:="http://localhost:11434"}  # Default Ollama URL

# Provider validation
_zsh_ai_validate_config() {
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

    return 0
}