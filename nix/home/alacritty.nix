# Kept as a plain TOML file (not home-manager's structured
# programs.alacritty.settings) so it stays hand-editable exactly like
# tmux.conf/init.lua — this just places it instead of stow.
{ config, pkgs, ... }:

{
  xdg.configFile."alacritty/alacritty.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/alacritty/alacritty.toml";

  # zsh only reads TERMINFO_DIRS at startup, before nix's profile sets it.
  home.file.".terminfo".source = "${pkgs.alacritty.terminfo}/share/terminfo";
}
