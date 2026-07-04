{
  lib,
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

  # GUI apps are Homebrew casks. Strip legacy /Applications/Nix Apps bundles
  # before ensureAppManagement runs so darwin-rebuild switch does not reset
  # App Management TCC on every activation (nix-darwin issue #1294).
  system.checks.text = lib.mkBefore ''
    if [ -d "/Applications/Nix Apps" ]; then
      find "/Applications/Nix Apps" -mindepth 1 -maxdepth 1 -name '*.app' -exec rm -rf {} + 2>/dev/null || true
    fi
  '';

  system.activationScripts.applications.text = lib.mkForce ''
    targetFolder='/Applications/Nix Apps'
    if [ -d "$targetFolder" ]; then
      find "$targetFolder" -mindepth 1 -maxdepth 1 -name '*.app' -exec rm -rf {} + 2>/dev/null || true
      rmdir "$targetFolder" 2>/dev/null || true
    fi
  '';

  system = {
    stateVersion = 6;
    defaults = {
      dock = {
        autohide = true;
        show-recents = false;
        tilesize = 38;
        wvous-br-corner = 14;
      };
      finder = {
        AppleShowAllExtensions = true;
        FXPreferredViewStyle = "clmv";
        ShowPathbar = true;
        NewWindowTarget = "Home";
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
      WindowManager = {
        AppWindowGroupingBehavior = true;
        AutoHide = false;
        EnableTiledWindowMargins = false;
        HideDesktop = true;
        StageManagerHideWidgets = false;
        StandardHideWidgets = false;
      };
      screencapture = {
        location = "~/Pictures/Screenshot";
        target = "file";
      };
    };
  };

  # AC/battery profiles differ (pmset -g custom); only declare the stable toggle.
  power.sleep.allowSleepByPowerButton = true;
}
