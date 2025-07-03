#!/usr/bin/env zsh

# Command failure detection and AI-powered fix suggestion

# Variables to track command execution
typeset -g _ZSH_AI_LAST_COMMAND=""
typeset -g _ZSH_AI_LAST_EXIT_CODE=0
typeset -g _ZSH_AI_COMMAND_START_TIME=0

# Hook to capture command before execution
_zsh_ai_preexec() {
    _ZSH_AI_LAST_COMMAND="$1"
    _ZSH_AI_COMMAND_START_TIME=$EPOCHSECONDS
}

# Hook to check command exit status after execution
_zsh_ai_precmd() {
    _ZSH_AI_LAST_EXIT_CODE=$?
    
    # Check if auto fix is enabled
    [[ "$ZSH_AI_AUTO_FIX" != "true" ]] && return
    
    # Only suggest if command failed and we have a command to analyze
    if [[ $_ZSH_AI_LAST_EXIT_CODE -ne 0 ]] && [[ -n "$_ZSH_AI_LAST_COMMAND" ]]; then
        # Skip if it was a comment command (our AI commands)
        [[ "$_ZSH_AI_LAST_COMMAND" =~ ^'# ' ]] && return
        
        # Skip exit/logout commands
        [[ "$_ZSH_AI_LAST_COMMAND" =~ ^(exit|logout) ]] && return
        
        # Exit codes that indicate user interruption or normal termination
        local user_interrupt_codes=(130 131 141 143 146 147 148 149 150)
        
        # Check if this is a user interruption exit code
        for code in $user_interrupt_codes; do
            [[ $_ZSH_AI_LAST_EXIT_CODE -eq $code ]] && {
                # For interrupt signals, also check runtime
                if [[ $code -eq 130 ]] || [[ $code -eq 143 ]]; then
                    # Calculate runtime
                    local runtime=$((EPOCHSECONDS - _ZSH_AI_COMMAND_START_TIME))
                    # Skip if command ran for more than 2 seconds (likely intentional interruption)
                    [[ $runtime -gt 2 ]] && return
                else
                    # For other codes like SIGPIPE, always skip
                    return
                fi
            }
        done
        
        # Query AI for a fix suggestion
        _zsh_ai_suggest_fix "$_ZSH_AI_LAST_COMMAND"
    fi
}

# Function to query AI for command fix
_zsh_ai_suggest_fix() {
    local failed_cmd="$1"
    
    # Check if we have necessary configuration
    if [[ -z "$ANTHROPIC_API_KEY" ]] && [[ "$ZSH_AI_PROVIDER" == "anthropic" || -z "$ZSH_AI_PROVIDER" ]]; then
        print ""  # Add blank line for spacing
        print -P "%F{yellow}⚠ %B[zsh-ai]%b ANTHROPIC_API_KEY not set%f"
        return
    fi
    
    # Create query for AI
    local query="The shell command '$failed_cmd' failed. What is the correct command? Reply with ONLY the corrected command, no explanation."
    
    # Animation frames - rotating dots
    local dots=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    local frame=0
    
    # Create a temp file for the response
    local tmpfile=$(mktemp)
    
    # Disable job control notifications
    setopt local_options no_monitor no_notify
    
    # Add blank line for spacing
    print ""
    
    # Start the API query in background
    (_zsh_ai_query "$query" > "$tmpfile" 2>&1) &
    local pid=$!
    
    # Animate while waiting with timeout
    local timeout=10  # 10 second timeout
    local elapsed=0
    while kill -0 $pid 2>/dev/null; do
        print -n "\r${dots[$((frame % ${#dots[@]}))]}"
        ((frame++))
        sleep 0.1
        ((elapsed++))
        
        # Check for timeout (10 seconds = 100 * 0.1)
        if [[ $elapsed -ge 100 ]]; then
            kill $pid 2>/dev/null
            print -n "\r\033[K"
            print -P "%F{yellow}⚠ %B[zsh-ai]%b Request timed out%f"
            rm -f "$tmpfile"
            return
        fi
    done
    
    # Clear the animation
    print -n "\r\033[K"
    
    # Wait for the process to finish and get its exit code
    wait $pid
    local exit_code=$?
    
    # Get the response
    local suggestion=$(cat "$tmpfile" 2>/dev/null)
    rm -f "$tmpfile"
    
    # Check if the query failed
    if [[ $exit_code -ne 0 ]] || [[ -z "$suggestion" ]]; then
        print -P "%F{red}✗ %B[zsh-ai]%b Failed to get suggestion%f"
        return
    fi
    
    # Check for API errors in the response
    if [[ "$suggestion" == "Error:"* ]] || [[ "$suggestion" == "API Error:"* ]]; then
        print -P "%F{red}✗ %B[zsh-ai]%b $suggestion%f"
        return
    fi
    
    # Validate and display suggestion
    if [[ -n "$suggestion" ]] && [[ "$suggestion" != "$failed_cmd" ]]; then
        print -P "%F{blue}🤖 %B[zsh-ai]%b Did you mean: %F{cyan}$suggestion%f"
        print -z "$suggestion"
    fi
}

# Initialize the command fixer
_zsh_ai_init_command_fixer() {
    # Add our hooks
    autoload -Uz add-zsh-hook
    add-zsh-hook preexec _zsh_ai_preexec
    add-zsh-hook precmd _zsh_ai_precmd
}