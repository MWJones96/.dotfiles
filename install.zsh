#!/bin/zsh
set -e

detect_os() {
    case "$(uname -s)" in
        Darwin)
            OS="macos"
            ;;
        Linux)
            OS="linux"
            # Check for specific distros if needed
            [[ -f /etc/arch-release ]] && DISTRO="arch"
            [[ -f /etc/debian_version ]] && DISTRO="debian"
            ;;
        *)
            print -P "%F{red}Unknown OS. Exiting.%f"
            exit 1
            ;;
    esac
    print -P "%F{cyan}Detected OS: $OS ${DISTRO:+($DISTRO)}%f"
}

install_dependencies() {
    if [[ "$OS" == "macos" ]]; then
        if ! command -v brew &>/dev/null; then
            print "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi

        print -P "%F{yellow}Installing macOS packages via Homebrew...%f"
        # Core, Modern CLI, and Workflow
        brew install \
            stow nvim curl coreutils \
            eza bat ripgrep fd zoxide btop \
            fzf tmux tldr direnv starship
            
    elif [[ "$OS" == "linux" ]]; then
        if [[ "$DISTRO" == "debian" ]]; then
            print -P "%F{yellow}Updating and installing via apt...%f"
            sudo apt update
            sudo apt install -y \
                sudo curl wget stow build-essential unzip ca-certificates \
                neovim eza ripgrep zoxide btop fzf tmux tldr direnv \
                fd-find bat # Note: Debian specific naming

        elif [[ "$DISTRO" == "arch" ]]; then
            print -P "%F{yellow}Installing via pacman...%f"
            sudo pacman -Syu --needed \
                base-devel curl wget stow unzip \
                neovim eza bat ripgrep fd zoxide btop \
                fzf tmux tldr direnv
        fi
    fi
}

install_rust() {
    # 1. Install Rust (non-interactive)
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

    # 2. Source the cargo environment so we can use 'cargo' immediately
    . "$HOME/.cargo/env"

    # 3. Install useful programs
    echo "Installing cargo tools..."
    
    # Fast alternative to 'ls'
    cargo install exa 
    
    # Fast alternative to 'grep'
    cargo install ripgrep 
    
    # A great system monitor
    cargo install bottom --locked
}

stow_dotfiles() {
    local DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

    print -P "%F{magenta}Symlinking configurations...%f"
    cd "$DOTFILES_DIR"
    stow -R -t ~ vim
    stow -R -t ~ zsh
    mkdir -p ~/.config/tmux
    stow -R -d . -t ~/.config/tmux tmux
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

chsh -s $(which zsh)
detect_os
install_dependencies
install_rust
stow_dotfiles
install_tmux
print -P "%F{green}Setup complete!%f"
exec zsh
