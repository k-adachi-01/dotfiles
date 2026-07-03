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
    agent-skills-nix.url = "github:Kyure-A/agent-skills-nix";
    # k-adachi-01/agent-skills is a private repo, fetched via Nix's built-in
    # GitHub API fetcher (respects `access-tokens` in nix.conf). This used to
    # be `git+https://...` reusing the `gh auth git-credential` helper from
    # nix/home.nix, but that helper only works for the `adachi` user session:
    # `sudo darwin-rebuild switch` runs as root, whose $HOME (/var/root) has
    # no gh config, and even pointing GH_CONFIG_DIR at adachi's config still
    # fails because gh's OAuth token lives in adachi's macOS login Keychain,
    # which root cannot read non-interactively. A fine-grained PAT via
    # access-tokens sidesteps both the git-CLI credential helper and the
    # Keychain entirely. See docs/management-policy.md for setup.
    # For local skills development, override with:
    #   --override-input agent-skills path:/Users/adachi/agent-skills
    agent-skills = {
      url = "github:k-adachi-01/agent-skills";
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
