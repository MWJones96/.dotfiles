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

  # GUI apps that aren't practical to get from nixpkgs. Homebrew itself still
  # does the actual install; this list is the only thing that's declarative.
  #
  # cleanup is deliberately "none" (the default): this machine already has a
  # lot of brew formulae/casks installed outside this config, and "uninstall"
  # or "zap" would remove anything not listed above on every switch. Only
  # flip this once `casks`/`brews` actually enumerates everything you want
  # kept — until then, this list is additive only.
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "none";
    };
    casks = [
      "alacritty"
    ];
  };

  # Intentionally empty for now — add `defaults write`-style preferences here
  # (system.defaults.dock, .finder, NSGlobalDomain, etc.) once you've decided
  # which ones you actually want.
  system.defaults = { };

  # Lets nix-darwin patch /etc/zshrc so login shells pick up the nix profile.
  programs.zsh.enable = true;
}
