# Replaces TPM: the plugin list now lives here instead of `set -g @plugin`
# lines + a git-cloned tpm/ directory. Confirm `catppuccin` is still the
# correct tmuxPlugins attribute name on first `nix flake check` — nixpkgs
# occasionally renames these.
{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    extraConfig = builtins.readFile ../../tmux/tmux.conf;
    plugins = with pkgs.tmuxPlugins; [
      sensible
      vim-tmux-navigator
      yank
      catppuccin
    ];
  };
}
