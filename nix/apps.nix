{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      cleanup = "uninstall";
      upgrade = false;
    };
    casks = [
      "bitwarden"
      "google-chrome"
      "obsidian"
      "orbstack"
      "slack"
      "visual-studio-code"
      "wezterm"
    ];
  };
}
