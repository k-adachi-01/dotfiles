{
  pkgs,
  username,
  system,
  ...
}:

{
  imports = [
    ./apps.nix
  ];

  nixpkgs = {
    hostPlatform = system;
    config.allowUnfree = true;
  };

  nix = {
    package = pkgs.nix;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "root"
        username
      ];
    };
  };

  users.users.${username}.home = "/Users/${username}";
  system.primaryUser = username;

  programs.zsh.enable = true;
  system.tools.darwin-rebuild.enable = true;

  home-manager.backupFileExtension = "hm-backup";

  environment.systemPackages = with pkgs; [
    vim
  ];

  system = {
    stateVersion = 6;
    defaults = {
      dock = {
        autohide = true;
        show-recents = false;
      };
      finder = {
        AppleShowAllExtensions = true;
        FXPreferredViewStyle = "clmv";
        ShowPathbar = true;
      };
      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        InitialKeyRepeat = 15;
        KeyRepeat = 2;
      };
    };
  };
}
