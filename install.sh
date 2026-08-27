#!/usr/bin/env zsh
set -eu

# Single-command bootstrap: installs Nix if needed, then hands everything
# else (packages, dotfiles, tmux plugins, NvChad bootstrap) to flake.nix via
# darwin-rebuild (macOS) or home-manager (Linux). See README.md for the
# individual steps this automates, and nix/hosts/darwin.nix + nix/home/*.nix
# for what actually gets installed.

DOTFILES_DIR="${0:a:h}"
cd "$DOTFILES_DIR"

USERNAME="mxj"

detect_os() {
    case "$(uname -s)" in
        Darwin) echo "darwin" ;;
        Linux) echo "linux" ;;
        *)
            print -P "%F{red}Unsupported OS: $(uname -s)%f"
            exit 1
            ;;
    esac
}

detect_arch() {
    case "$(uname -m)" in
        x86_64) echo "x86_64" ;;
        arm64|aarch64) echo "aarch64" ;;
        *)
            print -P "%F{red}Unsupported architecture: $(uname -m)%f"
            exit 1
            ;;
    esac
}

install_nix() {
    if command -v nix &>/dev/null; then
        return
    fi

    print -P "%F{cyan}Nix not found. Installing (multi-user daemon)...%f"
    sh <(curl -L https://nixos.org/nix/install) --daemon

    # The daemon installer only wires PATH into new shells' profile scripts;
    # this session needs it sourced directly to keep going.
    local nix_profile_sh="/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
    if [ -e "$nix_profile_sh" ]; then
        . "$nix_profile_sh"
    fi
}

enable_flakes() {
    local nix_conf="/etc/nix/nix.conf"
    local os="$1"

    if [ -f "$nix_conf" ] && grep -q "experimental-features" "$nix_conf" 2>/dev/null; then
        return
    fi

    print -P "%F{cyan}Enabling flakes in $nix_conf (one-time, needs sudo)...%f"
    echo "experimental-features = nix-command flakes" | sudo tee -a "$nix_conf" >/dev/null

    if [[ "$os" == "darwin" ]]; then
        sudo launchctl kickstart -k system/org.nixos.nix-daemon
    else
        sudo systemctl restart nix-daemon
    fi
}

# Anything still symlinked into place by the old `stow`-based setup would
# make home-manager abort with "would be clobbered" (it won't auto-replace a
# foreign symlink, only plain files). Move those aside instead of deleting.
# No-op on a machine that's never run this before.
retire_foreign_symlinks() {
    local target
    for target in "$HOME/.zshrc" "$HOME/.vimrc" "$HOME/.config/tmux/tmux.conf" "$HOME/.config/nvim"; do
        if [ -L "$target" ] && [[ "$(readlink "$target")" != /nix/store/* ]]; then
            print -P "%F{yellow}Moving pre-existing $target -> $target.pre-nix-backup%f"
            mv "$target" "$target.pre-nix-backup"
        fi
    done
}

main() {
    local os arch
    os="$(detect_os)"
    arch="$(detect_arch)"

    install_nix
    enable_flakes "$os"
    retire_foreign_symlinks

    if [[ "$os" == "darwin" ]]; then
        print -P "%F{magenta}Switching macOS to the Nix config (darwinConfigurations.macbook)...%f"
        sudo nix --extra-experimental-features 'nix-command flakes' \
            run nix-darwin -- switch --flake "${DOTFILES_DIR}#macbook"
    else
        print -P "%F{magenta}Switching this Linux user to the Nix config (${arch}-linux)...%f"
        nix --extra-experimental-features 'nix-command flakes' \
            run home-manager -- switch --flake "${DOTFILES_DIR}#${USERNAME}-${arch}-linux" -b hm-backup
    fi

    print -P "%F{green}Done. Open a new shell (and tmux session) to pick everything up.%f"
}

main
