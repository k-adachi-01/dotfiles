# Devin CLI: class A permissions; shared skills are discovered through
# ~/.agents/skills, managed by programs.agent-skills in default.nix.
{
  lib,
  pkgs,
  ...
}: let
  agentsLib = import ./lib.nix {inherit pkgs;};
  configEntry = {
    format = "json";
    value.permissions.allow = [
      "Fetch(domain:dev.classmethod.jp)"
      "Fetch(domain:strandsagents.com)"
    ];
    dest = "$HOME/.config/devin/config.json";
    label = "devin-config";
  };
in {
  dotfilesAgents.classAMerges = [(agentsLib.mkDiffCommand configEntry)];

  # Only permissions.allow is declared: org_id, setup state, model, theme,
  # version and other app-owned keys survive. The allow array is replaced
  # wholesale on switch; promote durable approvals into this declaration.
  home.activation.mergeDevinConfig = lib.hm.dag.entryAfter ["writeBoundary"] (
    agentsLib.mkMergeActivation (configEntry // {backupDir = "$HOME/.config/devin/backups";})
  );
}
