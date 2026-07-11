{
  description = "k-adachi-01 macOS development environment";

  # Bootstrap Numtide's cache before the first switch persists the same
  # settings through nix/nix.custom.conf in nix/darwin.nix. Only effective
  # for trusted users (root); use scripts/apply-llm-agents-overnight which
  # runs via sudo with --option accept-flake-config true.
  nixConfig = {
    extra-substituters = ["https://cache.numtide.com"];
    extra-trusted-substituters = ["https://cache.numtide.com"];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    nixvim.url = "github:nix-community/nixvim";
    llm-agents-nix.url = "github:numtide/llm-agents.nix";
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
    nixpkgs,
    ...
  }: let
    username = "adachi";
    darwinSystem = "aarch64-darwin";
    linuxSystem = "x86_64-linux";
    linuxPkgs = import nixpkgs {
      system = linuxSystem;
      config.allowUnfree = true;
    };
  in {
    darwinConfigurations.macbook = nix-darwin.lib.darwinSystem {
      system = darwinSystem;
      specialArgs = {
        inherit inputs self username;
        system = darwinSystem;
        dotfilesRepo = "/Users/${username}/.config/nix-darwin";
        enableAgentSkills = true;
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
              inherit inputs username;
              system = darwinSystem;
              dotfilesRepo = "/Users/${username}/.config/nix-darwin";
              enableAgentSkills = true;
            };
            users.${username} = import ./nix/home.nix;
          };
        }
      ];
    };

    homeConfigurations."adachi@nixos" = home-manager.lib.homeManagerConfiguration {
      pkgs = linuxPkgs;
      extraSpecialArgs = {
        inherit inputs username;
        system = linuxSystem;
        dotfilesRepo = "/home/${username}/dotfiles";
        enableAgentSkills = false;
      };
      modules = [
        ./nix/home.nix
      ];
    };
  };
}
