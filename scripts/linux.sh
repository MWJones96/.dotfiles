#!/usr/bin/env zsh
set -eu
cd "${0:a:h:h}"

# Not every context exports $USER (e.g. `docker exec -u`), and home-manager needs it.
export USER="${USER:-$(id -un)}"

arch="$(uname -m)"
[[ "$arch" == arm64 ]] && arch=aarch64

install_pkgs() {
    if command -v apt-get &>/dev/null; then
        sudo apt-get update -qq && sudo apt-get install -y "${@/#xz/xz-utils}"
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y "$@"
    elif command -v pacman &>/dev/null; then
        sudo pacman -Sy --noconfirm "$@"
    else
        print -P "%F{red}Install $* manually and re-run.%f"
        exit 1
    fi
}

if ! command -v nix &>/dev/null; then
    missing=()
    command -v curl &>/dev/null || missing+=(curl)
    command -v xz &>/dev/null || missing+=(xz)
    (( ${#missing} )) && install_pkgs "${missing[@]}"
    sh <(curl -L https://nixos.org/nix/install) --daemon
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

if ! grep -qs experimental-features /etc/nix/nix.conf; then
    echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf >/dev/null
    sudo systemctl restart nix-daemon
fi

# 1Password's apt/dnf repos have no arm64 desktop build, and the Nix one lacks
# browser integration outside NixOS.
if ! command -v 1password &>/dev/null; then
    tmp="$(mktemp -d)"
    curl -fsSL "https://downloads.1password.com/linux/tar/stable/${arch}/1password-latest.tar.gz" | tar xz -C "$tmp"
    sudo rm -rf /opt/1Password
    sudo mv "$tmp"/1password-* /opt/1Password
    sudo /opt/1Password/after-install.sh
    rm -rf "$tmp"
fi

nix --extra-experimental-features 'nix-command flakes' \
    run home-manager -- switch --flake ".#mxj-${arch}-linux" -b hm-backup
