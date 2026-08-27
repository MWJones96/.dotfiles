{
  description = "Cross-platform Nix config (macOS via nix-darwin, Linux via standalone home-manager)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, ... }:
    let
      username = "mxj";

      # Flakes evaluate in pure mode, so `outputs` can't shell out to `uname`
      # itself — instead, define one homeConfiguration per architecture here
      # (still fully pure/reproducible) and let the caller pick the right one
      # via a `uname -m` lookup at the shell level. See README.md.
      mkHome = system: home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        modules = [ ./nix/home/default.nix ];
      };

      linuxSystems = [ "x86_64-linux" "aarch64-linux" ];
    in
    {
      # `darwin-rebuild switch --flake .#macbook`
      darwinConfigurations.macbook = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ./nix/hosts/darwin.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            # Renames pre-existing plain files (e.g. left over from stow) to
            # *.hm-backup instead of failing the switch.
            home-manager.backupFileExtension = "hm-backup";
            home-manager.users.${username} = import ./nix/home/default.nix;
          }
        ];
      };

      # `home-manager switch --flake .#mxj-x86_64-linux` or `.#mxj-aarch64-linux`
      # — README.md has the `uname -m` one-liner that picks the right one.
      homeConfigurations = nixpkgs.lib.genAttrs
        (map (system: "${username}-${system}") linuxSystems)
        (name: mkHome (nixpkgs.lib.removePrefix "${username}-" name));
    };
}
