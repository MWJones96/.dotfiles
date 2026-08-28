#!/usr/bin/env zsh
set -eu

# Removes a nixpkgs package either:
#   - permanently, from nix/home/packages.nix (future fresh machines won't
#     get it either) — and applies that removal to this machine too
#   - or a one-off previously installed via `add-package.sh --once`
#
# Usage:
#   ./remove-package.sh <package>          permanent — repo + this machine
#   ./remove-package.sh --once <package>   undoes an --once install
#
# Counterpart to add-package.sh — see that script for the install side.

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
  ./$SCRIPT_NAME <package>          Remove <package> permanently — repo + this machine
  ./$SCRIPT_NAME --once <package>   Undo an 'add-package.sh --once' install

<package> is a nixpkgs attribute name, e.g. 'ripgrep' or 'nerd-fonts.jetbrains-mono'.
EOF
    exit 1
}

remove_once() {
    local pkg="$1"
    print -P "%F{magenta}Removing $pkg from this machine's profile (installed via --once)...%f"
    nix --extra-experimental-features 'nix-command flakes' profile remove "$pkg"
    print -P "%F{green}Done.%f"
}

remove_permanent() {
    local pkg="$1"
    local pattern="^[[:space:]]*${pkg//./\\.}[[:space:]]*\$"

    if ! grep -qE "$pattern" "$PACKAGES_FILE"; then
        print -P "%F{yellow}$pkg isn't in packages.nix — nothing to remove there.%f"
        print -P "%F{yellow}If you installed it with 'add-package.sh --once', use '--once' here too.%f"
        return
    fi

    print -P "%F{magenta}Removing $pkg from nix/home/packages.nix...%f"
    local tmp
    tmp="$(mktemp)"
    grep -vE "$pattern" "$PACKAGES_FILE" > "$tmp"
    mv "$tmp" "$PACKAGES_FILE"

    print -P "%F{green}Removed from the repo.%f"

    if read -q "?Run refresh.sh now to remove it from this machine's PATH too? [y/N] "; then
        echo
        "$SCRIPT_DIR/refresh.sh"
        print -P "%F{green}Done — no longer on PATH. The actual files stay in /nix/store, unreferenced,%f"
        print -P "%F{green}until you next run 'nix-collect-garbage' (or a similar GC sweep) — that's%f"
        print -P "%F{green}normal Nix behavior, not something this script needs to handle.%f"
    else
        echo
        print -P "%F{yellow}Skipped. Removed from the repo either way — run ./refresh.sh whenever%f"
        print -P "%F{yellow}you want it off this machine's PATH; it just won't be on future fresh machines.%f"
    fi
}

if [[ $# -eq 0 ]]; then
    usage
fi

if [[ "$1" == "--once" || "$1" == "-1" ]]; then
    [[ $# -eq 2 ]] || usage
    remove_once "$2"
else
    [[ $# -eq 1 ]] || usage
    remove_permanent "$1"
fi
