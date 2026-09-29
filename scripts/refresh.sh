#!/usr/bin/env zsh
set -eu

# Applies settings changes only. If the change would add or remove a program,
# it stops and points at bootstrap.sh instead.

# This script lives in <dotfiles>/scripts/ — the flake itself is one level up.
SCRIPT_DIR="${0:a:h}"
DOTFILES_DIR="${SCRIPT_DIR:h}"
cd "$DOTFILES_DIR"

# See bootstrap.sh for why this is needed — not every invocation context
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

refuse_program_changes() {
    local attr="$1" current="$2"
    if [[ "$(nix --extra-experimental-features 'nix-command flakes' eval --raw "${DOTFILES_DIR}#${attr}")" \
        != "$(readlink -f "$current")" ]]; then
        print -P "%F{red}This change adds or removes programs. Run bootstrap.sh to apply it.%f"
        exit 1
    fi
}

main() {
    local os arch
    os="$(detect_os)"
    arch="$(detect_arch)"

    if [[ "$os" == "darwin" ]]; then
        refuse_program_changes darwinConfigurations.macbook.config.system.path /run/current-system/sw
        refuse_program_changes \
            "darwinConfigurations.macbook.config.environment.etc.\"profiles/per-user/${USERNAME}\".source" \
            "/etc/profiles/per-user/$USERNAME"

        print -P "%F{magenta}Refreshing macOS from the Nix config (darwinConfigurations.macbook)...%f"
        sudo nix --extra-experimental-features 'nix-command flakes' \
            run nix-darwin -- switch --flake "${DOTFILES_DIR}#macbook"
    else
        refuse_program_changes "homeConfigurations.${USERNAME}-${arch}-linux.config.home.path" \
            "$HOME/.local/state/nix/profiles/home-manager/home-path"
        print -P "%F{magenta}Refreshing this Linux user from the Nix config (${arch}-linux)...%f"
        nix --extra-experimental-features 'nix-command flakes' \
            run home-manager -- switch --flake "${DOTFILES_DIR}#${USERNAME}-${arch}-linux" -b hm-backup
    fi

    print -P "%F{green}Done. Open a new shell (and tmux session) to pick everything up.%f"
}

main
