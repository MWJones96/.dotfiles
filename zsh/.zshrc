# 1. Install Oh My Zsh if missing
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi
export ZSH="$HOME/.oh-my-zsh"

# Theme (Agnoster requires a Nerd Font or Powerline font)
ZSH_THEME="agnoster"
# Define the custom plugins directory
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"

# Function to clone if missing
install_zsh_plugin() {
    local repo_url=$1
    local plugin_name=$2
    if [ ! -d "$ZSH_CUSTOM/plugins/$plugin_name" ]; then
        echo "Installing $plugin_name..."
        git clone "$repo_url" "$ZSH_CUSTOM/plugins/$plugin_name"
    fi
}

# Install your specific plugins
install_zsh_plugin "https://github.com/zsh-users/zsh-autosuggestions" "zsh-autosuggestions"
install_zsh_plugin "https://github.com/zsh-users/zsh-syntax-highlighting" "zsh-syntax-highlighting"
# --- 2. PLUGINS ---
# Standard OMZ plugins + your custom ones
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)

# Load Oh My Zsh
source $ZSH/oh-my-zsh.sh

# --- 3. ALIASES & SHORTCUTS ---
alias ll="ls -alF"
alias la="ls -A"
alias l="ls -CF"
alias dotfiles="cd ~/.dotfiles"
alias reload="exec zsh" # Quick command to refresh shell

# --- 4. PYTHON (pyenv) ---
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# --- 5. NODE.JS (pnpm) ---
export PNPM_HOME="/home/mwjones/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# --- 6. TMUX & TERMINAL ---
# Ensure colors work correctly
export TERM="xterm-256color"

# --- 7. HISTORY SETTINGS ---
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY     # Append to history file rather than replace
setopt SHARE_HISTORY      # Share history between different sessions
setopt HIST_IGNORE_DUPS   # Don't record an entry that was just recorded
