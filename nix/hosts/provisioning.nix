# Applied once, by scripts/mac.sh on a new Mac, via darwinConfigurations.macbook-bootstrap.
# Later runs use .#macbook, which leaves this out.
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
  homebrew.onActivation = {
    autoUpdate = true;
    # Uninstalls any formula or cask not declared in homebrew.nix.
    cleanup = "uninstall";
  };

  system.defaults = {
    NSGlobalDomain.AppleInterfaceStyleSwitchesAutomatically = true;
    WindowManager.EnableTiledWindowMargins = false;
    dock = {
      wvous-br-corner = 14;
      persistent-apps = [
        "/Applications/Firefox.app"
        "/Applications/Slack.app"
        "/Applications/Microsoft Outlook.app"
        "/Applications/Nix Apps/Alacritty.app"
        "/Applications/Keybase.app"
        "/Applications/Docker.app"
        "/System/Applications/System Settings.app"
        "/Applications/Claude.app"
        "/Applications/Twingate.app"
        "/Applications/Obsidian.app"
        "/Applications/1Password.app"
        "/Applications/zoom.us.app"
      ];
    };
  };
}
