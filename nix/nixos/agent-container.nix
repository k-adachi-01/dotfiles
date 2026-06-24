{
  config,
  lib,
  pkgs,
  ...
}:

let
  agentContainerPackages = import ../packages/agent-container.nix {inherit pkgs;};
in
{
  system.stateVersion = "25.05";

  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
    };
  };

  nixpkgs.config.allowUnfree = true;

  users.users.adachi = {
    isNormalUser = true;
    shell = pkgs.bashInteractive;
    extraGroups = ["wheel"];
    home = "/home/adachi";
  };

  security.sudo.wheelNeedsPassword = false;

  networking = {
    hostName = "agent-container";
    firewall.enable = false;
  };

  # To enable SSH access, uncomment the following:
  # services.openssh = {
  #   enable = true;
  #   settings = {
  #     PermitRootLogin = "no";
  #     PasswordAuthentication = false;
  #   };
  # };

  environment.systemPackages = agentContainerPackages;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      username = "adachi";
      homeDirectory = "/home/adachi";
    };
    users.adachi = import ../home-agent-container.nix;
  };
}
