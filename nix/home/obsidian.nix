{ config, lib, pkgs, ... }:

lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  xdg.configFile."tidy-scratch-pad/prompt.md".source = ../../obsidian/tidy-scratch-pad.md;
  home.file.".local/bin/tidy-scratch-pad".source = ../../obsidian/tidy-scratch-pad.sh;

  launchd.agents.tidy-scratch-pad = {
    enable = true;
    config = {
      ProgramArguments = [ "${config.home.homeDirectory}/.local/bin/tidy-scratch-pad" ];
      StartCalendarInterval = [ { Minute = 0; } ];
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/tidy-scratch-pad.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/tidy-scratch-pad.log";
    };
  };
}
