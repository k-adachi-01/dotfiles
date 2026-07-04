# User-owned launchd agents. Vendor updaters (Google Keystone, etc.) stay
# outside Nix; only jobs authored for this environment belong here.
{config, ...}: let
  homeDir = config.home.homeDirectory;
in {
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
}
