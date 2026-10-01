# Replaces TPM: the plugin list now lives here instead of `set -g @plugin`
# lines + a git-cloned tpm/ directory. Confirm `catppuccin` is still the
# correct tmuxPlugins attribute name on first `nix flake check` — nixpkgs
# occasionally renames these.
{ config, pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    extraConfig = "source-file ${config.home.homeDirectory}/.dotfiles/tmux/tmux.conf";
    plugins = with pkgs.tmuxPlugins; [
      sensible
      vim-tmux-navigator
      yank
      {
        plugin = catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavor 'mocha'
          set -g @catppuccin_window_text ' #W'
          set -g @catppuccin_window_current_text ' #W'
        '';
      }
      {
        plugin = resurrect;
        extraConfig = "set -g @resurrect-capture-pane-contents 'on'";
      }
      {
        plugin = continuum;
        extraConfig = "set -g @continuum-restore 'on'";
      }
    ];
  };
}
