# zsh-uv-env

zsh-uv-env is a plugin for zsh and uv. It automatically activates a virtual environment
based on the current directory.

# Installation with oh-my-zsh

1. Clone this repository into `$ZSH_CUSTOM/plugins` (by default
   `~/.oh-my-zsh/custom/plugins`)

   ```sh
   git clone https://github.com/matthiasha/zsh-uv-env ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-uv-env
   ```

2. Add the plugin to the list of plugins for Oh My Zsh to load (inside `~/.zshrc`):

   ```sh
   plugins=(
     ...
     zsh-uv-env
   )
   ```

3. Start a new terminal session.

# How It Works

The plugin automatically detects and activates Python virtual environments (.venv
or venv directories) as you navigate through your filesystem. When you leave a directory with an
active virtual environment, it automatically deactivates it. When you switch from one project with
a virtual environment to another project with a different virtual environment, the plugin automatically
deactivates the first and activates the second.

The plugin searches for virtual environments in the following order of priority:
1. `.venv` directory (uv default)
2. `venv` directory (alternative convention)

The plugin validates that a virtual environment contains a valid `activate` script before attempting to use it.

## Post-Hooks

This plugin supports post-hooks that allow you to execute custom commands after a
virtual environment is activated or deactivated.

### Adding Post-Hooks

You can add post-hooks in your .zshrc file:

```bash
# Define hook functions
_venv_post_hook() {
    v cd
    v venv
}

_venv_post_hook_deactivate() {
    v cd
    v reset_venv
}

# Register the hooks
zsh_uv_add_post_hook_on_activate '_venv_post_hook'
zsh_uv_add_post_hook_on_deactivate '_venv_post_hook_deactivate'
```

Then call this function in your .zshrc.

#### Available Hook Functions

    zsh_uv_add_post_hook_on_activate: Register a function to run after a virtual environment is activated

    zsh_uv_add_post_hook_on_deactivate: Register a function to run after a virtual environment is deactivated

# Testing

The plugin includes comprehensive automated tests to ensure reliability:

## Running Tests

```bash
# Run all tests
make test

# Run focused tests for find_venv function
make test-find-venv

# Run venv switching tests
make test-switching

# Test with real uv environments
make test-with-uv

# Clean up test artifacts
make clean
```

## Test Coverage

The test suite covers:
- Detection of `.venv` directories
- Detection of `venv` directories  
- Priority order when both exist
- Validation of activate scripts
- Nested directory search
- Home directory boundary handling
- Switching between different virtual environments
- Integration with real uv environments

## Continuous Integration

Tests run automatically on:
- All pushes to main branch
- Pull requests to main branch
- Both Bash and Zsh shells
