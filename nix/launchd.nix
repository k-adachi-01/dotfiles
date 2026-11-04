# User-owned launchd agents. Vendor updaters (Google Keystone, etc.) stay
# outside Nix; only jobs authored for this environment belong here.
{
  config,
  lib,
  pkgs,
  ...
}: let
  homeDir = config.home.homeDirectory;
  # Same derivation as home.packages; resolved here so the agent can use an
  # absolute store path instead of relying on PATH.
  rustxng = pkgs.callPackage ./pkgs/rustxng.nix {};
in
  lib.mkIf pkgs.stdenv.isDarwin {
    launchd.agents."com.adachi.screenshot-copy" = {
      config = {
        ProgramArguments = ["${homeDir}/.config/screenshot-copy/screenshot-copy.sh"];
        WatchPaths = ["${homeDir}/Pictures/Screenshot"];
        StandardOutPath = "${homeDir}/Library/Logs/screenshot-copy.out.log";
        StandardErrorPath = "${homeDir}/Library/Logs/screenshot-copy.err.log";
      };
    };

    home.file.".config/screenshot-copy/screenshot-copy.sh" = {
      source = ../home/launchd/screenshot-copy/screenshot-copy.sh;
      executable = true;
    };

    # Local search backend for Pi (K-373). Loopback only; Pi falls back to
    # the OpenAI subscription search when this process is not running.
    launchd.agents."com.adachi.rustxng" = {
      enable = true;
      config = {
        ProgramArguments = [(lib.getExe rustxng) "--bind" "127.0.0.1" "--port" "29483"];
        RunAtLoad = true;
        KeepAlive = {SuccessfulExit = false;};
        StandardOutPath = "${homeDir}/Library/Logs/rustxng.out.log";
        StandardErrorPath = "${homeDir}/Library/Logs/rustxng.err.log";
      };
    };
  }
