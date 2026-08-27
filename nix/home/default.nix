{ pkgs, ... }:

{
  home.username = "mxj";
  home.homeDirectory = if pkgs.stdenv.isDarwin then "/Users/mxj" else "/home/mxj";
  # Pinned once on first setup; do not bump casually — see home-manager docs.
  home.stateVersion = "24.11";

  home.packages = import ./packages.nix { inherit pkgs; };

  # Local dirs that aren't nix-provided packages (nix.cargo/bin, .fzf/bin, and
  # bob's nvim-bin are gone now that cargo/fzf/neovim come straight from nix).
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.terragrunt/bin"
  ];

  imports = [
    ./zsh.nix
    ./tmux.nix
    ./editors.nix
    ./alacritty.nix
  ];

  programs.home-manager.enable = true;
}
