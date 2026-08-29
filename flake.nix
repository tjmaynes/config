{
  description = "TJ Maynes' Nix system configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      nix-darwin,
      ...
    }:
    let
      supportedSystems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      identity = {
        username = "tjmaynes";
        fullName = "TJ Maynes";
        email = "tj@tjmaynes.com";
        githubUsername = "tjmaynes";
        timezone = "America/Chicago";
      };
      gaiaUser = identity // {
        homeDirectory = "/Users/${identity.username}";
      };
      athenaUser = identity // {
        homeDirectory = "/home/${identity.username}";
      };
      atlasUser = identity // {
        homeDirectory = "/home/${identity.username}";
      };
    in
    {
      darwinConfigurations.gaia = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = {
          inherit identity;
          user = gaiaUser;
        };
        modules = [
          home-manager.darwinModules.home-manager
          ./hosts/gaia/default.nix
        ];
      };

      nixosConfigurations.athena = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit identity;
          user = athenaUser;
        };
        modules = [
          home-manager.nixosModules.home-manager
          ./hosts/athena/default.nix
        ];
      };

      nixosConfigurations.atlas = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit identity;
          user = atlasUser;
        };
        modules = [ ./hosts/atlas/default.nix ];
      };

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              actionlint
              deadnix
              jq
              nixfmt
              ripgrep
              shellcheck
              statix
            ];
          };
        }
      );
    };
}
