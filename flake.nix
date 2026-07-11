{
  description = "k-adachi-01 macOS development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    nixvim.url = "github:nix-community/nixvim";
    llm-agents-nix.url = "github:numtide/llm-agents.nix";
    hunk = {
      url = "github:modem-dev/hunk";
      # hunk's flake still evaluates x86_64-darwin outputs; nixpkgs 26.11
      # dropped that platform, so pin its private nixpkgs input to the
      # last darwin-supporting branch instead of following our global input.
      inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    };
    agent-skills-nix.url = "github:Kyure-A/agent-skills-nix";
    # Local checkout of k-adachi-01/agent-skills (private). Flake path input
    # copies ~/agent-skills into the store at eval time (module-level `path`
    # cannot be read under the default eval sandbox). After editing skills,
    # refresh the pinned narHash before switch:
    #   nix flake update agent-skills --flake ~/.config/nix-darwin
    agent-skills = {
      url = "path:/Users/adachi/agent-skills";
      flake = false;
    };
  };

  outputs = inputs @ {
    self,
    nix-darwin,
    home-manager,
    nix-homebrew,
    ...
  }: let
    username = "adachi";
    system = "aarch64-darwin";
  in {
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
  };
}
