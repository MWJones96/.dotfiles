#!/usr/bin/env zsh
set -eu
cd "${0:a:h:h}"

if ! command -v nix &>/dev/null; then
    sh <(curl -L https://nixos.org/nix/install) --daemon
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

if ! grep -qs experimental-features /etc/nix/nix.conf; then
    echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf >/dev/null
    sudo launchctl kickstart -k system/org.nixos.nix-daemon
fi

# First run also sets the Dock and system defaults; later runs leave them alone.
target=macbook
[ -e /run/current-system ] || target=macbook-bootstrap

sudo -H nix --extra-experimental-features 'nix-command flakes' \
    run nix-darwin -- switch --flake ".#${target}"
