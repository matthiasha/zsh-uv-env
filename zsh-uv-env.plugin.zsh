# Function to check if a virtualenv is already activated
is_venv_active() {
    [[ -n "$VIRTUAL_ENV" ]] && return 0
    return 1
}

# Function to find nearest .venv directory
find_venv() {
    local current_dir="$PWD"
    local home_dir="$HOME"
    local root_dir="/"
    local stop_dir="$root_dir"
    
    # If we're under home directory, stop at home
    if [[ "$current_dir" == "$home_dir"* ]]; then
        stop_dir="$home_dir"
    fi

    while [[ "$current_dir" != "$stop_dir" ]]; do
        if [[ -d "$current_dir/.venv" ]]; then
            echo "$current_dir/.venv"
            return 0
        fi
        current_dir="$(dirname "$current_dir")"
    done
    
    # Check stop_dir itself
    if [[ -d "$stop_dir/.venv" ]]; then
        echo "$stop_dir/.venv"
        return 0
    fi
    
    return 1
}

# Variable to track if we activated the venv
typeset -g AUTOENV_ACTIVATED=0

# Function to handle directory changes
autoenv_chpwd() {
    # Don't do anything if a virtualenv is already manually activated
    if is_venv_active && [[ $AUTOENV_ACTIVATED == 0 ]]; then
        return
    fi
    
    local venv_path=$(find_venv)
    
    if [[ -n "$venv_path" ]]; then
        # If we found a venv and none is active, activate it
        if ! is_venv_active; then
            source "$venv_path/bin/activate"
            AUTOENV_ACTIVATED=1
        fi
    else
        # If no venv found and we activated one before, deactivate it
        if [[ $AUTOENV_ACTIVATED == 1 ]] && is_venv_active; then
            deactivate
            AUTOENV_ACTIVATED=0
        fi
    fi
}

# Register precmd hook to watch for new venv creation
# A cheaper alternative would be the chpwd hook, but 
# we would miss the case where a venv is created or deleted
autoload -U add-zsh-hook
add-zsh-hook precmd autoenv_chpwd

# Run once when shell starts
autoenv_chpwd
