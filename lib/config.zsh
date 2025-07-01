#!/usr/bin/env zsh

# Configuration and validation for zsh-ai

# Set default values for configuration
: ${ZSH_AI_PROVIDER:="anthropic"}  # Default to anthropic for backwards compatibility
: ${ZSH_AI_OLLAMA_MODEL:="llama3.2"}  # Popular fast model
: ${ZSH_AI_OLLAMA_URL:="http://localhost:11434"}  # Default Ollama URL
: ${ZSH_AI_GEMINI_MODEL:="gemini-2.5-flash"}  # Fast Gemini 2.5 model
: ${ZSH_AI_AUTO_FIX:="true"}  # Enable automatic command fix suggestions by default

# Provider validation
_zsh_ai_validate_config() {
    if [[ "$ZSH_AI_PROVIDER" != "anthropic" ]] && [[ "$ZSH_AI_PROVIDER" != "ollama" ]] && [[ "$ZSH_AI_PROVIDER" != "gemini" ]]; then
        echo "zsh-ai: Error: Invalid provider '$ZSH_AI_PROVIDER'. Use 'anthropic', 'ollama', or 'gemini'."
        return 1
    fi

    # Check requirements based on provider
    if [[ "$ZSH_AI_PROVIDER" == "anthropic" ]]; then
        if [[ -z "$ANTHROPIC_API_KEY" ]]; then
            echo "zsh-ai: Warning: ANTHROPIC_API_KEY not set. Plugin will not function."
            echo "zsh-ai: Set ANTHROPIC_API_KEY or use ZSH_AI_PROVIDER=ollama for local models."
            return 1
        fi
    elif [[ "$ZSH_AI_PROVIDER" == "gemini" ]]; then
        if [[ -z "$GEMINI_API_KEY" ]]; then
            echo "zsh-ai: Warning: GEMINI_API_KEY not set. Plugin will not function."
            echo "zsh-ai: Set GEMINI_API_KEY or use ZSH_AI_PROVIDER=ollama for local models."
            return 1
        fi
    fi

    return 0
}