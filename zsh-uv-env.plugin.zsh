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
        for _v in .venv venv; do
            if [[ -d "$current_dir/$_v" && -r "$current_dir/$_v/bin/activate" ]]; then
                echo "$current_dir/$_v"
                return 0
            fi
        done
        current_dir="$(dirname "$current_dir")"
    done

    # Check stop_dir itself
    for _v in .venv venv; do
        if [[ -d "$stop_dir/$_v" && -r "$stop_dir/$_v/bin/activate" ]]; then
            echo "$stop_dir/$_v"
            return 0
        fi
    done

    return 1
}

# Variable to track if we activated the venv
typeset -g AUTOENV_ACTIVATED=0

# Define arrays for hooks early so they're available throughout the session
typeset -ga ZSH_UV_ACTIVATE_HOOKS=()
typeset -ga ZSH_UV_DEACTIVATE_HOOKS=()

# Add the hook registration functions
zsh_uv_add_post_hook_on_activate() {
    ZSH_UV_ACTIVATE_HOOKS+=("$1")
}

zsh_uv_add_post_hook_on_deactivate() {
    ZSH_UV_DEACTIVATE_HOOKS+=("$1")
}

# Function to execute all activation hooks
_run_activate_hooks() {
    local hook
    for hook in "${ZSH_UV_ACTIVATE_HOOKS[@]}"; do
        eval "$hook"
    done
}

# Function to execute all deactivation hooks
_run_deactivate_hooks() {
    local hook
    for hook in "${ZSH_UV_DEACTIVATE_HOOKS[@]}"; do
        eval "$hook"
    done
}

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
            # Run activation hooks
            _run_activate_hooks
        fi
    else
        # If no venv found and we activated one before, deactivate it
        if [[ $AUTOENV_ACTIVATED == 1 ]] && is_venv_active; then
            deactivate
            AUTOENV_ACTIVATED=0
            # Run deactivation hooks
            _run_deactivate_hooks
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
