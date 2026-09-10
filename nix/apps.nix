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
    #
    # `vercel` is an intentional Homebrew-formula exception: nixpkgs has no
    # Vercel CLI, and the published npm tarball ships without a lockfile, so
    # a reproducible packages.nix derivation is not practical. Auth/config
    # under ~/Library/Application Support/com.vercel.cli stays unmanaged.
    brews = [
      "container"
      "vercel"
    ];
    casks = [
      "amazon-workspaces"
      "bitwarden"
      "codex-app"
      "cursor"
      "ghostty"
      "google-chrome"
      "grok-bot"
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
