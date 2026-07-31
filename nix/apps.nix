{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      cleanup = "uninstall";
      upgrade = false;
    };
    brews = [
      {
        name = "container";
        start_service = true;
      }
    ];
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
