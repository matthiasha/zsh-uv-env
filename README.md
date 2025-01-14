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