# pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"

# Prevent .zsh_sessions dir from being created on macOS
export SHELL_SESSIONS_DISABLE=1
