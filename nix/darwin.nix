{
  lib,
  pkgs,
  inputs,
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
    overlays = [(import ./security-overlay.nix {inherit (inputs) nixpkgs-build;})];
  };

  nix.enable = false;

  # Determinate Nix owns /etc/nix/nix.conf and includes this supported
  # extension point. Keep llm-agents.nix on its pinned nixpkgs for cache hits.
  # extra-trusted-substituters lets non-root users also consume the cache
  # (trusted-users = root only on this host).
  environment.etc."nix/nix.custom.conf" = {
    text = ''
      # Use the updated system bundle even with an independent Nix profile.
      ssl-cert-file = /etc/ssl/certs/ca-certificates.crt
      # llm-agents.nix binary cache
      extra-substituters = https://cache.numtide.com
      extra-trusted-substituters = https://cache.numtide.com
      extra-trusted-public-keys = niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=
    '';
    knownSha256Hashes = [
      "3bd68ef979a42070a44f8d82c205cfd8e8cca425d91253ec2c10a88179bb34aa"
    ];
  };

  # Apple Security.framework revocation does not protect PEM-only clients.
  # Keep the legacy macOS curl/Python path on the same updated Mozilla bundle.
  environment.etc."ssl/cert.pem" = {
    source = "${pkgs.cacert}/etc/ssl/certs/ca-no-trust-rules-bundle.crt";
    knownSha256Hashes = [
      "9dae8d76e55cb08991f2b672d58999ea15560d910759c16b544f843bdffbb994"
    ];
  };

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
    ++ import ./packages.nix {
      inherit pkgs inputs system;
    };

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
