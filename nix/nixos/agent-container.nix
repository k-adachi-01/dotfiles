# WARNING: This module is designed exclusively for single-user AI agent
# containers running on a host-only or isolated network. It disables the
# firewall and enables passwordless sudo for the wheel group. Do NOT reuse
# this module in multi-user, network-exposed, or production environments
# without adding appropriate access controls.
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
