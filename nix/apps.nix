{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      cleanup = "uninstall";
      upgrade = false;
    };
    # `vercel` is an intentional Homebrew-formula exception: nixpkgs has no
    # Vercel CLI, and the published npm tarball ships without a lockfile, so
    # a reproducible packages.nix derivation is not practical. Auth/config
    # under ~/Library/Application Support/com.vercel.cli stays unmanaged.
    brews = [
      "vercel"
    ];
    casks = [
      "amazon-workspaces"
      "bitwarden"
      "codex-app"
      "cursor"
      "deepseek-harness"
      "devin-desktop"
      "ghostty"
      "google-chrome"
      "grok-bot"
      "herdr-app"
      "obsidian"
      "orbstack"
      "raycast"
      "slack"
      "t3-code"
      "zed"
      {
        name = "wezterm";
        greedy = true;
      }
    ];
  };
}
