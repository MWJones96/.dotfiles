{ pkgs, ... }:

let
  # Bound once here because it's needed in two places that must not drift:
  # the package list, and DOTNET_ROOT below.
  dotnetSdk = pkgs.dotnet-sdk_10;
in
{
  home.username = "mxj";
  home.homeDirectory = if pkgs.stdenv.isDarwin then "/Users/mxj" else "/home/mxj";
  # Pinned once on first setup; do not bump casually — see home-manager docs.
  home.stateVersion = "24.11";

  home.packages = import ./packages.nix { inherit pkgs dotnetSdk; };

  # Defaults to false for a standalone (non-NixOS-module) home-manager setup,
  # which silently leaves fonts installed via home.packages undiscoverable
  # by fontconfig on Linux. No-op on macOS, which uses its own font-linking
  # mechanism (~/Library/Fonts) instead of fontconfig.
  fonts.fontconfig.enable = true;

  # Local dirs that aren't nix-provided packages (nix.cargo/bin, .fzf/bin, and
  # bob's nvim-bin are gone now that cargo/fzf/neovim come straight from nix).
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.terragrunt/bin"
    # `dotnet tool install --global` puts its shims here and the SDK doesn't
    # add it to PATH itself. Needed for `dotnet ef` in particular: quaisr/core
    # has no dotnet-tools.json manifest, so EF's CLI has to be a global tool.
    "$HOME/.dotnet/tools"
  ];

  home.sessionVariables = {
    DOTNET_CLI_TELEMETRY_OPTOUT = "1";
    # Global dotnet tools are apphosts that find the runtime via DOTNET_ROOT.
    # nixpkgs' wrapper only exports it for `dotnet` itself, so without this
    # `dotnet-ef` (and every other global tool) dies with a "missing_runtime"
    # prompt to go download .NET — which is exactly the wrong advice on Nix.
    DOTNET_ROOT = "${dotnetSdk}/share/dotnet";
  };

  imports = [
    ./zsh.nix
    ./tmux.nix
    ./editors.nix
    ./alacritty.nix
    ./direnv.nix
  ];

  programs.home-manager.enable = true;
}
