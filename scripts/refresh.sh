#!/usr/bin/env zsh
set -eu

# Re-applies the current flake after any local change — a dotfile edit, a
# package added/removed in nix/home/packages.nix, any nix/*.nix tweak.
# Assumes install.sh has already bootstrapped this machine (Nix installed,
# flakes enabled) — this is the fast everyday path, not first-time setup.
# (install.sh is itself idempotent and would also work here, but this skips
# its one-time bootstrap checks.)

# This script lives in <dotfiles>/scripts/ — the flake itself is one level up.
SCRIPT_DIR="${0:a:h}"
DOTFILES_DIR="${SCRIPT_DIR:h}"
cd "$DOTFILES_DIR"

# See install.sh for why this is needed — not every invocation context
# exports $USER, and nix-darwin/home-manager's own CLIs require it.
export USER="${USER:-$(id -un)}"

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

main() {
    local os arch
    os="$(detect_os)"
    arch="$(detect_arch)"

    if [[ "$os" == "darwin" ]]; then
        print -P "%F{magenta}Refreshing macOS from the Nix config (darwinConfigurations.macbook)...%f"
        sudo nix --extra-experimental-features 'nix-command flakes' \
            run nix-darwin -- switch --flake "${DOTFILES_DIR}#macbook"
    else
        print -P "%F{magenta}Refreshing this Linux user from the Nix config (${arch}-linux)...%f"
        nix --extra-experimental-features 'nix-command flakes' \
            run home-manager -- switch --flake "${DOTFILES_DIR}#${USERNAME}-${arch}-linux" -b hm-backup
    fi

    print -P "%F{green}Done. Open a new shell (and tmux session) to pick everything up.%f"
}

main
