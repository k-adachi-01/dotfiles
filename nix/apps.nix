{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      cleanup = "uninstall";
      upgrade = false;
    };
    # `brew services start container` cannot bootstrap the per-user launchd
    # service while nix-darwin activation is running under sudo. Keep the
    # formula declarative, and start its system service with
    # `container system start` outside activation when needed.
    brews = ["container"];
    casks = [
      "amazon-workspaces"
      "aqua-voice"
      "bitwarden"
      "codex-app"
      "cursor"
      "ghostty"
      "google-chrome"
      "obsidian"
      "orbstack"
      "raycast"
      "slack"
      "zed"
      {
        name = "wezterm";
        greedy = true;
      }
    ];
  };
}
