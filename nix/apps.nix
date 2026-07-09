{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      cleanup = "uninstall";
      upgrade = false;
    };
    brews = [
      "container"
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
