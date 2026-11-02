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
      # The account running the script (under sudo on macOS). Needs --impure;
      # pure evaluation, as in CI, sees no environment and falls back to "mxj".
      env = name: builtins.getEnv name;
      username = if env "SUDO_USER" != "" then env "SUDO_USER"
        else if env "USER" != "" then env "USER"
        else "mxj";
      linuxHome = if env "HOME" != "" && env "SUDO_USER" == "" then env "HOME" else "/home/${username}";

      # One per architecture; scripts/linux.sh picks with `uname -m`.
      mkHome = system: home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        modules = [ ./nix/home/default.nix ];
        extraSpecialArgs = { inherit username; homeDirectory = linuxHome; };
      };

      mkDarwin = extraModules: nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = { inherit username; };
        modules = [
          ./nix/hosts/darwin.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            # Renames pre-existing plain files (e.g. left over from stow) to
            # *.hm-backup instead of failing the switch.
            home-manager.backupFileExtension = "hm-backup";
            home-manager.extraSpecialArgs = { inherit username; homeDirectory = "/Users/${username}"; };
            home-manager.users.${username} = import ./nix/home/default.nix;
          }
        ] ++ extraModules;
      };

      linuxSystems = [ "x86_64-linux" "aarch64-linux" ];
    in
    {
      darwinConfigurations.macbook = mkDarwin [ ./nix/hosts/homebrew.nix ];
      # New machine only, picked by scripts/mac.sh. See nix/hosts/provisioning.nix.
      darwinConfigurations.macbook-bootstrap = mkDarwin [
        ./nix/hosts/homebrew.nix
        ./nix/hosts/provisioning.nix
      ];

      homeConfigurations = nixpkgs.lib.genAttrs linuxSystems mkHome;
    };
}
