export ZSH="$HOME/.oh-my-zsh"
# Theme (Agnoster requires a Nerd Font or Powerline font)
ZSH_THEME="agnoster"
# Define the custom plugins directory
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
