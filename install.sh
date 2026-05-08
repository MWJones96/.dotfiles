#!/usr/bin/env zsh
set -e

# Change to dotfiles dir if not there already
DOTFILES_DIR="${0:a:h}"
cd "$DOTFILES_DIR"

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
        ~/.fzf/install 
    fi

    local -A tools=(
        eza eza
        ripgrep rg
        bottom btm
        zoxide zoxide
	tree-sitter-cli tree-sitter
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

install_nvim() {
    if ! command -v nvim &>/dev/null; then
        print -P "%F{cyan}Installing Neovim...%f"
    	curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage
    	chmod u+x nvim-linux-x86_64.appimage
    	mkdir -p ~/.local/bin
    	mv nvim-linux-x86_64.appimage ~/.local/bin/nvim
	
	# Install NVChad	
	git clone --depth 1 https://github.com/NvChad/starter ~/.config/nvim
	rm -rf ~/.config/nvim/.git
	rm ~/.config/nvim/.stylua.toml
	rm -rf ~/.config/nvim/*
    fi
}

stow_dotfiles() {
    print -P "%F{magenta}Symlinking configurations...%f"

    mkdir -p ~/.config/tmux
    mkdir -p ~/.config/nvim
    mkdir -p ~/.config/alacritty

    stow -R -t ~ vim
    stow -R -t ~ zsh
    stow -R -t ~/.config/tmux tmux
    stow -R -t ~/.config/nvim nvim 
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
install_nvim
stow_dotfiles
install_tmux

print -P "%F{green}Setup complete!%f"

# Change default shell if not changed
if [[ "$SHELL" != *(zsh)* ]]; then
    chsh -s "$(which zsh)"
fi

# Source new .zshrc
exec zsh -l
