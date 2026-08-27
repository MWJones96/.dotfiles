# Cross-platform CLI tools, replacing install.sh's brew/apt/dnf/pacman
# branching and the rustup + cargo-binstall pipeline. Same package set on
# macOS and every Linux distro.
{ pkgs }:

with pkgs; [
  git
  curl
  wget
  unzip

  vim
  neovim

  rustc
  cargo

  oh-my-posh
  fzf
  eza
  bat
  ripgrep
  fd
  bottom
  zoxide
  tree-sitter
  atuin
  dua
  tealdeer
  stylua

  # Referenced by alacritty/alacritty.toml. home-manager symlinks font
  # packages into ~/Library/Fonts on macOS automatically; on Linux it's
  # picked up via fontconfig.
  nerd-fonts.jetbrains-mono
]
# On macOS, Alacritty comes from the Homebrew cask (nix/hosts/darwin.nix) so
# it's a proper .app in Applications/Spotlight — adding nixpkgs' build here
# too would just be a redundant CLI-only duplicate. Linux has no such cask,
# so it comes straight from nixpkgs there.
++ lib.optional stdenv.isLinux alacritty
