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
  clippy
  rustfmt
  cargo-nextest

  # python-lsp-server (Mason) needs an actual interpreter to run at all —
  # was silently relying on whatever Python happens to be on the system.
  python3
  ruff
  uv

  # clangd (Mason) is LSP-only; these are what actually build/debug the code.
  clang
  cmake

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

  # General dev workflow — not installed anywhere before this pass.
  gh
  lazygit
  jq
  delta
  shellcheck
  just
  # Closes a real gap: conform.nvim formats css/html with this, but nothing
  # installed it anywhere.
  prettier

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
