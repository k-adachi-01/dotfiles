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
      "aqua-voice"
      "bitwarden"
      "codex-app"
      "cursor"
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
