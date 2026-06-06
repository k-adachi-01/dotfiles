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
      "google-chrome"
      "obsidian"
      "orbstack"
      "raycast"
      "slack"
      "visual-studio-code"
      "wezterm"
    ];
  };
}
