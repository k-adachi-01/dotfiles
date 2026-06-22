{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      cleanup = "uninstall";
      upgrade = false;
    };
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
      "wezterm"
    ];
  };
}
