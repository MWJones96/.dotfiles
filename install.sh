#!/usr/bin/env zsh
set -e

# Change to dotfiles dir if not there already
DOTFILES_DIR="${0:a:h}"
cd "$DOTFILES_DIR"

install_system_dependencies() {
    local os_type=$(uname -s)
    local deps=(stow curl git unzip tmux vim)

    if [[ "$os_type" == "Darwin" ]]; then
        print -P "%F{cyan}Detected macOS. Using Homebrew...%f"
        if ! command -v brew &>/dev/null; then
            print -P "%F{yellow}Homebrew not found. Installing...%f"
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install "${deps[@]}"
    elif [[ "$os_type" == "Linux" ]]; then
        print -P "%F{cyan}Detected Linux. Searching for package manager...%f"
        
        if command -v apt-get &>/dev/null; then
            sudo apt-get update
            sudo apt-get install -y "${deps[@]}" build-essential
        elif command -v dnf &>/dev/null; then
            sudo dnf install -y "${deps[@]}" @development-tools
        elif command -v pacman &>/dev/null; then
            sudo pacman -Syu --noconfirm "${deps[@]}" base-devel
        elif command -v zypper &>/dev/null; then
            sudo zypper install -y "${deps[@]}" -t pattern devel_basis
        else
            print -P "%F{red}Error: No supported package manager found (apt, dnf, pacman, zypper).%f"
            exit 1
        fi
    else
        print -P "%F{red}Unsupported OS: $os_type%f"
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
    	source "$HOME/.cargo/env"
    fi

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
	bob-nvim bob
    )

    for tool binary in ${(kv)tools}; do
        if ! command -v $binary &>/dev/null; then
            print -P "%F{yellow}Installing $tool...%f"
            cargo install $tool --locked
        fi
    done

    bob install stable
    yes n | bob use stable
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

install_nv_chad() {
    print -P "%F{magenta}Running NvChad headless setup...%f"
    nvim --headless \
      -c "lua require('lazy').restore()" \
      -c "lua require('lazy').load({ plugins = { 'ui', 'nvim-treesitter' } })" \
      -c "lua require('nvchad.mason').install_all()" \
      -c "lua require('nvim-treesitter.install').update({ with_sync = true })" \
      -c "qa"
}

install_system_dependencies
install_dependencies
stow_dotfiles
install_tmux
install_nv_chad

print -P "%F{green}Setup complete!%f"

# Change default shell if not changed
if [[ "$SHELL" != *(zsh)* ]]; then
    chsh -s "$(which zsh)"
fi

echo "Installation complete. Please run 'source ~/.zshrc' or restart your terminal."
