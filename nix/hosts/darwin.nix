{ pkgs, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Nix was installed via the official multi-user installer before nix-darwin
  # took over; this keeps nix-darwin from trying to recreate the build-users
  # group with a different gid. If this is ever applied on a different Mac,
  # check the real gid first: dscl . -read /Groups/nixbld PrimaryGroupID
  ids.gids.nixbld = 350;

  system.stateVersion = 5;

  # Required by nix-darwin for any option (e.g. homebrew.enable) that still
  # applies per-user rather than system-wide.
  system.primaryUser = "mxj";

  # nix-darwin doesn't create/manage macOS user accounts, but home-manager's
  # darwin integration needs this declared to know the home directory —
  # without it, home.homeDirectory resolves to null and the build fails.
  users.users.mxj = {
    name = "mxj";
    home = "/Users/mxj";
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    alacritty
    firefox
    obsidian
    slack
    zoom-us
  ];

  # Zoom's updater can't write to the read-only nix copy, so it installs a second
  # one in ~/Applications instead.
  system.defaults.CustomSystemPreferences."/Library/Preferences/us.zoom.config".ZAutoUpdate = false;

  # The Dock, system.defaults and Homebrew live in provisioning.nix: they install or
  # reset things, which is a bootstrap step, not something to repeat on every rebuild.

  # Lets nix-darwin patch /etc/zshrc so login shells pick up the nix profile.
  programs.zsh.enable = true;

  # nix-darwin's generated /etc/zprofile replaces Apple's default one and
  # doesn't call path_helper, so /etc/paths.d/* (where Homebrew's own
  # installer put /opt/homebrew/bin) is never read anymore — Homebrew
  # silently drops off PATH the moment this flake is switched to. This is
  # the system-level fix (feeds /etc/zshenv's set-environment, so it covers
  # login shells too — home.sessionPath in home-manager only covers
  # non-login interactive shells and isn't enough on its own).
  environment.systemPath = [
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
  ];
}
