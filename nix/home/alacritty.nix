# Kept as a plain TOML file (not home-manager's structured
# programs.alacritty.settings) so it stays hand-editable exactly like
# tmux.conf/init.lua — this just places it instead of stow.
{ ... }:

{
  xdg.configFile."alacritty/alacritty.toml".source = ../../alacritty/alacritty.toml;
}
