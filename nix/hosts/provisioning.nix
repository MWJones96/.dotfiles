# Applied ONCE, by scripts/bootstrap.sh, via darwinConfigurations.macbook-bootstrap.
# Everyday rebuilds use .#macbook, which leaves this out.
#
# Nix activation is convergent: whatever a module declares is re-asserted on every
# switch. That is what you want for packages and dotfiles, and wrong for anything a
# human is expected to change afterwards - declaring the Dock here means every
# rebuild discards whatever was pinned since the last one. These options set a
# starting state on a new machine and then get out of the way.
#
# Leaving this module out does not revert anything: nix-darwin writes defaults but
# never unsets them, and Homebrew cleanup only runs when it is declared.

{ ... }:

{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      # Uninstalls any formula or cask not declared here.
      cleanup = "uninstall";
    };
    casks = [
      "claude"
      "docker-desktop"
      "keybase"
      "twingate"
    ];
    masApps = {
      "Microsoft Outlook" = 985367838;
    };
  };

  system.defaults = {
    NSGlobalDomain.AppleInterfaceStyleSwitchesAutomatically = true;
    WindowManager.EnableTiledWindowMargins = false;
    dock = {
      wvous-br-corner = 14;
      persistent-apps = [
        "/Applications/Nix Apps/Firefox.app"
        "/Applications/Nix Apps/Slack.app"
        "/Applications/Microsoft Outlook.app"
        "/Applications/Nix Apps/Alacritty.app"
        "/Applications/Keybase.app"
        "/Applications/Docker.app"
        "/System/Applications/System Settings.app"
        "/Applications/Claude.app"
        "/Applications/Twingate.app"
        "/Applications/Nix Apps/Obsidian.app"
        "/Applications/Nix Apps/zoom.us.app"
      ];
    };
  };
}
