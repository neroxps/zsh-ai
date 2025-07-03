#!/usr/bin/env zsh

# Command failure detection and AI-powered fix suggestion

# Variables to track command execution
typeset -g _ZSH_AI_LAST_COMMAND=""
typeset -g _ZSH_AI_LAST_EXIT_CODE=0

# Hook to capture command before execution
_zsh_ai_preexec() {
    _ZSH_AI_LAST_COMMAND="$1"
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
        
        # Skip SIGPIPE errors (exit code 141) - common when quitting pagers
        [[ $_ZSH_AI_LAST_EXIT_CODE -eq 141 ]] && return
        
        # Skip SIGINT (Ctrl+C) for long-running processes
        [[ $_ZSH_AI_LAST_EXIT_CODE -eq 130 ]] && return
        
        # Skip commands that commonly use pagers
        [[ "$_ZSH_AI_LAST_COMMAND" =~ ^(git\s+(log|diff|show)|less|more|man|help) ]] && return
        
        # Skip common long-running commands that are often interrupted
        [[ "$_ZSH_AI_LAST_COMMAND" =~ ^(npm\s+(start|run|dev)|yarn\s+(start|dev)|pnpm\s+(start|dev)|serve|python|node|deno|bun) ]] && return
        
        # Query AI for a fix suggestion
        _zsh_ai_suggest_fix "$_ZSH_AI_LAST_COMMAND"
    fi
}

# Function to query AI for command fix
_zsh_ai_suggest_fix() {
    local failed_cmd="$1"
    
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
    
    # Animate while waiting
    while kill -0 $pid 2>/dev/null; do
        print -n "\r${dots[$((frame % ${#dots[@]}))]}"
        ((frame++))
        sleep 0.1
    done
    
    # Clear the animation
    print -n "\r\033[K"
    
    # Get the response
    local suggestion=$(cat "$tmpfile")
    rm -f "$tmpfile"
    
    # Validate and display suggestion
    if [[ -n "$suggestion" ]] && [[ "$suggestion" != "Error:"* ]] && [[ "$suggestion" != "$failed_cmd" ]]; then
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