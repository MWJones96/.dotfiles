{ config, ... }:

let
  link = name: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/claude/${name}";
in
{
  home.file = {
    ".claude/CLAUDE.md".source = link "CLAUDE.md";
    ".claude/settings.json".source = link "settings.json";
    ".claude/statusline.sh".source = link "statusline.sh";
  };
}
