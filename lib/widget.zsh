#!/usr/bin/env zsh

# ZLE widget and key binding for zsh-ai

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
_zsh_ai_init_widget() {
    zle -N accept-line _zsh_ai_accept_line
}