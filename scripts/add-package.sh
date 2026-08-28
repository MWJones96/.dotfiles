#!/usr/bin/env zsh
set -eu

# Adds a nixpkgs package either:
#   - permanently, into nix/home/packages.nix (every fresh machine gets it)
#   - or as a one-off, for this machine only, untracked anywhere in the repo
#
# Usage:
#   ./add-package.sh <package>          permanent — baked into fresh installs
#   ./add-package.sh --once <package>   one-off — this machine only
#
# <package> is a nixpkgs attribute name, e.g. 'ripgrep' or
# 'nerd-fonts.jetbrains-mono'. Look packages up at https://search.nixos.org/packages

# This script lives in <dotfiles>/scripts/ — the flake itself is one level up.
SCRIPT_DIR="${0:a:h}"
DOTFILES_DIR="${SCRIPT_DIR:h}"
PACKAGES_FILE="$DOTFILES_DIR/nix/home/packages.nix"
# Captured here, at top-level scope — inside a zsh function, $0 resolves to
# the *function's* name, not the script's, so usage() can't rely on $0.
SCRIPT_NAME="${0:t}"

usage() {
    cat <<EOF
Usage:
  ./$SCRIPT_NAME <package>          Add <package> permanently — every fresh machine gets it
  ./$SCRIPT_NAME --once <package>   Install <package> on this machine only, not tracked anywhere

<package> is a nixpkgs attribute name, e.g. 'ripgrep' or 'nerd-fonts.jetbrains-mono'.
Look packages up at https://search.nixos.org/packages
EOF
    exit 1
}

# Fast, direct attribute-lookup check (not a full-tree `nix search`, which
# is much slower) — catches a typo'd package name before it ends up
# committed or half-installed.
verify_package_exists() {
    local pkg="$1"
    print -P "%F{cyan}Checking nixpkgs#$pkg exists...%f"
    if ! nix --extra-experimental-features 'nix-command flakes' eval --raw "nixpkgs#${pkg}.pname" &>/dev/null; then
        print -P "%F{red}Error: nixpkgs#$pkg doesn't resolve to a package.%f"
        print -P "%F{red}Check the exact name at https://search.nixos.org/packages%f"
        exit 1
    fi
}

add_once() {
    local pkg="$1"
    verify_package_exists "$pkg"
    print -P "%F{magenta}Installing $pkg for this machine only (nothing written to the repo)...%f"
    nix --extra-experimental-features 'nix-command flakes' profile install "nixpkgs#$pkg"
    print -P "%F{green}Done. This won't show up on a fresh machine, and refresh.sh/install.sh won't touch it.%f"
}

add_permanent() {
    local pkg="$1"
    verify_package_exists "$pkg"

    if grep -qE "^[[:space:]]*${pkg//./\\.}[[:space:]]*\$" "$PACKAGES_FILE"; then
        print -P "%F{yellow}$pkg is already in packages.nix — nothing to do.%f"
        return
    fi

    print -P "%F{magenta}Adding $pkg to nix/home/packages.nix...%f"
    # Inserts right before the closing `]` of the main package list. Assumes
    # packages.nix's current shape (a `with pkgs; [ ... ]` list, one package
    # per line, closing bracket at the start of its own line) — if that
    # structure ever changes, this may need adjusting.
    local tmp
    tmp="$(mktemp)"
    awk -v pkg="$pkg" '
        /^\]/ && !inserted { print "  " pkg; inserted=1 }
        { print }
    ' "$PACKAGES_FILE" > "$tmp"
    mv "$tmp" "$PACKAGES_FILE"

    print -P "%F{green}Added. Review nix/home/packages.nix (it landed at the end of the%f"
    print -P "%F{green}list — feel free to move it into a themed section) before applying.%f"

    if read -q "?Run refresh.sh now to apply it? [y/N] "; then
        echo
        "$SCRIPT_DIR/refresh.sh"
    else
        echo
        print -P "%F{yellow}Skipped. Run ./refresh.sh whenever you're ready.%f"
    fi
}

if [[ $# -eq 0 ]]; then
    usage
fi

if [[ "$1" == "--once" || "$1" == "-1" ]]; then
    [[ $# -eq 2 ]] || usage
    add_once "$2"
else
    [[ $# -eq 1 ]] || usage
    add_permanent "$1"
fi
