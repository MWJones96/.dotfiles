#!/bin/zsh

# --- OS Detection ---
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

# --- Package Manager Logic ---
install_dependencies() {
    local deps=(stow git nvim zsh)

    if [[ "$OS" == "macos" ]]; then
        if ! command -v brew &>/dev/null; then
            print "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
        brew install $deps
    elif [[ "$OS" == "linux" ]]; then
        print -P "%F{yellow}Updating and installing via sudo...%f"
        if [[ "$DISTRO" == "debian" ]]; then
            sudo apt update && sudo apt install -y stow git neovim zsh
        elif [[ "$DISTRO" == "arch" ]]; then
            sudo pacman -Syu --needed stow git neovim zsh
        fi
    fi
}
# --- 3. The "Smart Stow" Logic ---
# This ignores the install script and other non-config files
stow_dotfiles() {
    print -P "%F{magenta}Symlinking configurations...%f"
    cd "$DOTFILES_DIR"
    stow -R -t ~ vim
    stow -R -t ~ zsh
    mkdir -p ~/.config/tmux
    stow -R -d . -t ~/.config/tmux tmux
    # 2. Define the plugin path (matching your new .config setup)
    TPM_PATH="$HOME/.config/tmux/plugins/tpm"

    # 3. Check if TPM is installed; if not, clone it
    if [ ! -d "$TPM_PATH" ]; then
        echo "Installing TPM..."
        git clone https://github.com/tmux-plugins/tpm "$TPM_PATH"
    fi

    # 4. Install the plugins (Catppuccin, Yank, etc.)
    # This runs TPM's internal installer headlessly
    echo "Installing tmux plugins..."
    "$TPM_PATH/bin/install_plugins"

    echo "Tmux setup complete!"
}

# --- Execution ---
main() {
    install_dependencies
    stow_dotfiles
    source $HOME/.zshrc
    print -P "%F{green}Setup complete!%f"
}

main
