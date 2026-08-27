#!/usr/bin/env zsh
set -eu

# Single-command bootstrap: installs Nix if needed, then hands everything
# else (packages, dotfiles, tmux plugins, NvChad bootstrap) to flake.nix via
# darwin-rebuild (macOS) or home-manager (Linux). See README.md for the
# individual steps this automates, and nix/hosts/darwin.nix + nix/home/*.nix
# for what actually gets installed.

DOTFILES_DIR="${0:a:h}"
cd "$DOTFILES_DIR"

# Not every invocation context exports $USER (e.g. `docker exec -u`, some
# minimal `su`/non-login shells) even though `id -un`/$HOME are always
# correct — and both nix-darwin and home-manager's own CLIs read $USER
# directly and fail with "unbound variable" if it's unset.
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

# The Nix installer needs curl (to fetch itself) and xz (to unpack its own
# binary tarball) — chicken-and-egg prerequisites Nix itself can't provide,
# and a minimal fresh install (e.g. a base Ubuntu server image) commonly
# lacks both. This is deliberately the ONLY thing still routed through a
# system package manager; everything else goes through Nix. Checking and
# installing explicitly (rather than letting `sh <(curl ...)` fail) also
# sidesteps a real gotcha: `set -e` does not reliably catch a failure inside
# a `<(...)` process substitution, so a missing curl there silently falls
# through to later, more confusing errors instead of stopping cleanly here.
ensure_bootstrap_prereqs() {
    local missing=()
    command -v curl &>/dev/null || missing+=(curl)
    command -v xz &>/dev/null || missing+=(xz)
    (( ${#missing[@]} == 0 )) && return

    print -P "%F{cyan}Installing prerequisites for the Nix installer: ${missing[*]}...%f"
    if command -v apt-get &>/dev/null; then
        local pkgs=()
        local m
        for m in "${missing[@]}"; do
            [[ "$m" == "xz" ]] && pkgs+=(xz-utils) || pkgs+=("$m")
        done
        sudo apt-get update -qq && sudo apt-get install -y "${pkgs[@]}"
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y "${missing[@]}"
    elif command -v pacman &>/dev/null; then
        sudo pacman -Sy --noconfirm "${missing[@]}"
    elif command -v zypper &>/dev/null; then
        sudo zypper install -y "${missing[@]}"
    elif command -v brew &>/dev/null; then
        brew install "${missing[@]}"
    else
        print -P "%F{red}Error: missing ${missing[*]} and no supported package manager to install them. Install manually and re-run.%f"
        exit 1
    fi
}

install_nix() {
    if command -v nix &>/dev/null; then
        return
    fi

    ensure_bootstrap_prereqs
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
