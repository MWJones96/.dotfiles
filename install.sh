#!/usr/bin/env zsh
set -e

# Change to dotfiles dir if not there already
DOTFILES_DIR="${0:a:h}"
cd "$DOTFILES_DIR"

# Change default shell if not changed
if [[ "$SHELL" != *(zsh)* ]]; then
    chsh -s "$(which zsh)"
fi

check_system_dependencies() {
    local deps=(stow curl git unzip vim tmux)
    for dep in $deps; do
        if ! command -v $dep &>/dev/null; then
            print -P "%F{red}Error: '$dep' is not installed. Please install it with your system's package manager.%f"
            exit 1
        fi
    done
    if ! command -v cc &>/dev/null; then
        print -P "%F{red}Error: Build tools not installed. Please install appropriate buildtools package for your distro.%f"
        exit 1
    fi
}

install_dependencies() {
    if ! command -v oh-my-posh &>/dev/null; then
        print -P "%F{cyan}Installing Oh My Posh...%f"
    	mkdir -p ~/.local/bin
        curl -s https://ohmyposh.dev/install.sh | bash -s -- -d ~/.local/bin
    fi

    if ! command -v cargo &>/dev/null; then
        print -P "%F{cyan}Installing Rust...%f"
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    fi
    source "$HOME/.cargo/env"

    if ! command -v fzf &>/dev/null; then
        print -P "%F{cyan}Installing fzf...%f"
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        ~/.fzf/install --bin --no-update-path --no-completion --no-key-bindings
    fi

    local -A tools=(
        eza eza
        ripgrep rg
        bottom btm
        zoxide zoxide
    )

    echo "Checking cargo tools..."
    for tool binary in ${(kv)tools}; do
        if ! command -v $binary &>/dev/null; then
            print -P "%F{yellow}Installing $tool...%f"
            cargo install $tool --locked
        else
            print -P "%F{green}✓ $tool already installed.%f"
        fi
    done
}

stow_dotfiles() {
    print -P "%F{magenta}Symlinking configurations...%f"

    mkdir -p ~/.config/tmux
    mkdir -p ~/.config/nvim
    mkdir -p ~/.config/alacritty

    stow -R -t ~ vim
    stow -R -t ~ zsh
    stow -R -t ~/.config/tmux tmux
}

install_tmux() {
    TPM_PATH="$HOME/.config/tmux/plugins/tpm"

    if [ ! -d "$TPM_PATH" ]; then
        echo "Installing TPM..."
        git clone https://github.com/tmux-plugins/tpm "$TPM_PATH"
    fi

    echo "Installing tmux plugins..."
    "$TPM_PATH/bin/install_plugins"

    echo "Tmux setup complete!"
}

check_system_dependencies
install_dependencies
stow_dotfiles
install_tmux

print -P "%F{green}Setup complete!%f"

# Source new .zshrc
exec zsh
