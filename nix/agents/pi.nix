# Pi's preferences are writable; instructions are read-only assets.
{
  config,
  lib,
  pkgs,
  dotfilesRepo ? "${config.home.homeDirectory}/.config/nix-darwin",
  enableAgentSkills ? true,
  ...
}: let
  mkLink = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesRepo}/${path}";
  agentsLib = import ./lib.nix {inherit pkgs;};
  settingsEntry = {
    format = "json";
    value =
      {
        enableInstallTelemetry = false;
        enableAnalytics = false;
      }
      // lib.optionalAttrs enableAgentSkills {
        skills = ["~/.agents/skills"];
      };
    dest = "$HOME/.pi/agent/settings.json";
    label = "pi-settings";
  };
in {
  dotfilesAgents.classAMerges = map agentsLib.mkDiffCommand [settingsEntry];

  home.activation.mergePiSettings = lib.hm.dag.entryAfter ["writeBoundary"] (
    agentsLib.mkMergeActivation (settingsEntry // {backupDir = "$HOME/.pi/agent/backups";})
  );

  home.file.".pi/agent/AGENTS.md".source = mkLink "home/ai/AGENTS.md";
}
