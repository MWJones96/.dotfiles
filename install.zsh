#!/bin/zsh

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
            stow nvim curl coreutils build-essential \
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

install_zsh_plugin() {
    local repo_url=$1
    local plugin_name=$2
    if [ ! -d "$ZSH_CUSTOM/plugins/$plugin_name" ]; then
        echo "Installing $plugin_name..."
        git clone "$repo_url" "$ZSH_CUSTOM/plugins/$plugin_name"
    fi
}

install_oh_my_zsh() {
    export ZSH="$HOME/.oh-my-zsh"
    export ZSH_CUSTOM="$ZSH/custom"

    if [ ! -d "$ZSH" ]; then
        echo "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
    fi

    install_zsh_plugin "https://github.com/zsh-users/zsh-autosuggestions" "zsh-autosuggestions"
    install_zsh_plugin "https://github.com/zsh-users/zsh-syntax-highlighting" "zsh-syntax-highlighting"
}

stow_dotfiles() {
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

detect_os
install_dependencies
install_oh_my_zsh
stow_dotfiles
install_tmux
print -P "%F{green}Setup complete!%f"
exec zsh