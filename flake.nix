{
  description = "TJ Maynes' Nix system configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    superpowers = {
      url = "github:obra/superpowers/main";
      flake = false;
    };

    tjmaynes-skills = {
      url = "github:tjmaynes/skills/main";
      flake = false;
    };
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      nix-darwin,
      superpowers,
      tjmaynes-skills,
      ...
    }:
    let
      supportedSystems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      unstableFor =
        system:
        import nixpkgs-unstable {
          inherit system;
          config = {
            allowUnfree = true;
            allowBroken = false;
          };
        };
      identity = {
        username = "tjmaynes";
        fullName = "TJ Maynes";
        email = "tj@tjmaynes.com";
        githubUsername = "tjmaynes";
        timezone = "America/Chicago";
      };
      skillRepos = [
        {
          name = "superpowers";
          source = superpowers;
          subdir = "skills";
        }
        {
          name = "tjmaynes-skills";
          source = tjmaynes-skills;
          subdir = "skills";
        }
      ];
      gaiaUser = identity // {
        homeDirectory = "/Users/${identity.username}";
      };
      athenaUser = identity // {
        homeDirectory = "/home/${identity.username}";
      };
    in
    {
      darwinConfigurations.gaia = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = {
          inherit identity skillRepos;
          user = gaiaUser;
          pkgsUnstable = unstableFor "aarch64-darwin";
        };
        modules = [
          home-manager.darwinModules.home-manager
          ./hosts/gaia/default.nix
        ];
      };

      nixosConfigurations.athena = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit identity skillRepos;
          user = athenaUser;
          pkgsUnstable = unstableFor "x86_64-linux";
        };
        modules = [
          home-manager.nixosModules.home-manager
          ./hosts/athena/default.nix
        ];
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
