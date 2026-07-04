{
  pkgs,
  username,
  system,
  ...
}: {
  imports = [
    ./apps.nix
  ];

  nixpkgs = {
    hostPlatform = system;
    config.allowUnfree = true;
  };

  nix.enable = false;

  users.users.${username}.home = "/Users/${username}";
  system.primaryUser = username;

  programs.zsh.enable = true;
  system.tools.darwin-rebuild.enable = true;

  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };

  home-manager.backupFileExtension = "hm-backup";

  fonts.packages = with pkgs; [
    plemoljp-nf
  ];

  environment.systemPackages =
    (with pkgs; [
      vim
    ])
    ++ import ./packages.nix {inherit pkgs;};

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
        NSAutomaticCapitalizationEnabled = true;
        NSAutomaticPeriodSubstitutionEnabled = true;
      };
      trackpad = {
        ActuateDetents = true;
        Clicking = false;
        DragLock = false;
        Dragging = false;
        FirstClickThreshold = 1;
        ForceSuppressed = false;
        SecondClickThreshold = 1;
        TrackpadCornerSecondaryClick = 0;
        TrackpadFourFingerHorizSwipeGesture = 2;
        TrackpadFourFingerPinchGesture = 2;
        TrackpadFourFingerVertSwipeGesture = 2;
        TrackpadMomentumScroll = true;
        TrackpadPinch = true;
        TrackpadRightClick = true;
        TrackpadRotate = true;
        TrackpadThreeFingerDrag = false;
        TrackpadThreeFingerHorizSwipeGesture = 2;
        TrackpadThreeFingerTapGesture = 0;
        TrackpadThreeFingerVertSwipeGesture = 2;
        TrackpadTwoFingerDoubleTapGesture = true;
        TrackpadTwoFingerFromRightEdgeSwipeGesture = 3;
      };
    };
  };
}
