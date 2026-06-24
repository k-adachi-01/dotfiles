{
  description = "k-adachi-01 macOS development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    agent-skills-nix.url = "github:Kyure-A/agent-skills-nix";
    # Local macOS path used for development on the darwin host.
    # This input is only consumed by darwinConfigurations.macbook.
    # On Linux-only evaluation (e.g. CI), override with a local clone:
    #   nix flake check --override-input agent-skills /path/to/local/clone
    agent-skills = {
      url = "path:/Users/adachi/agent-skills";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      nix-homebrew,
      ...
    }:
    let
      username = "adachi";
      system = "aarch64-darwin";
      linuxSystem = "aarch64-linux";
      linuxPkgs = import nixpkgs {
        system = linuxSystem;
        config.allowUnfree = true;
      };
      agentContainerPackages = import ./nix/packages/agent-container.nix {pkgs = linuxPkgs;};
    in
    {
      darwinConfigurations.macbook = nix-darwin.lib.darwinSystem {
        inherit system;
        specialArgs = {
          inherit inputs self username system;
        };
        modules = [
          ./nix/darwin.nix
          nix-homebrew.darwinModules.nix-homebrew
          home-manager.darwinModules.home-manager
          {
            nix-homebrew = {
              enable = true;
              enableRosetta = true;
              user = username;
            };

            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = {
                inherit inputs username system;
              };
              users.${username} = import ./nix/home.nix;
            };
          }
        ];
      };

      packages.${linuxSystem}.agent-container-tools = linuxPkgs.buildEnv {
        name = "agent-container-tools";
        paths = agentContainerPackages;
      };

      devShells.${linuxSystem}.agent-container = linuxPkgs.mkShell {
        name = "agent-container";
        packages = agentContainerPackages;
        shellHook = ''
          echo "Agent container dev shell - aarch64-linux"
        '';
      };

      nixosConfigurations.agent-container-aarch64-linux = nixpkgs.lib.nixosSystem {
        system = linuxSystem;
        modules = [
          ./nix/nixos/agent-container.nix
          home-manager.nixosModules.home-manager
        ];
      };
    };
}
