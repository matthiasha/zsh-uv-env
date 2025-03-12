# zsh-uv-env

zsh-uv-env is a plugin for zsh and uv. It automatically activates a virtual environment based on the current directory.

# Installation with oh-my-zsh

1. Clone this repository into `$ZSH_CUSTOM/plugins` (by default `~/.oh-my-zsh/custom/plugins`)

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

The plugin automatically detects and activates Python virtual environments (.venv directories) as you navigate through your filesystem. When you leave a directory with an active virtual environment, it automatically deactivates it.
Post-Hooks

This plugin supports post-hooks that allow you to execute custom commands after a virtual environment is activated or deactivated.
Adding Post-Hooks

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
autoswitch_add_post_hook_on_activate '_venv_post_hook'
autoswitch_add_post_hook_on_deactivate '_venv_post_hook_deactivate'
```

Then call this function in your .zshrc.

## Available Hook Functions

    autoswitch_add_post_hook_on_activate: Register a function to run after a virtual environment is activated

    autoswitch_add_post_hook_on_deactivate: Register a function to run after a virtual environment is deactivated
