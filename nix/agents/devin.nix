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
    value.permissions = {
      allow = [
        "Read(/**)"
        "Write(**)"
        "Fetch(https://*/*)"
        "Fetch(http://*/*)"
        "exec"
        "mcp__*"
      ];
      # Exec scopes are command prefixes, not Kiro's shell globs. Cover
      # common destructive invocations explicitly; ask for every push to
      # catch force flags appearing after the remote/branch arguments.
      deny =
        [
          "Exec(rm -rf)"
          "Exec(rm -fr)"
          "Exec(/bin/rm -rf)"
          "Exec(/bin/rm -fr)"
        ]
        ++ lib.concatMap (git:
          map (command: "Exec(${git} ${command})") [
            "reset --hard"
            "clean"
            "checkout --"
            "restore"
            "branch -D"
            "push --force"
            "push --force-with-lease"
            "push -f"
          ]) ["git" "/usr/bin/git"];
      # ask beats allow, so a broad sudo ask cannot have allow exceptions.
      # Git global options can precede a destructive subcommand; keep
      # those forms subject to review rather than claiming full isolation.
      ask =
        [
          "Exec(sudo)"
          "Exec(/usr/bin/sudo)"
        ]
        ++ lib.concatMap (git:
          map (command: "Exec(${git} ${command})") [
            "push"
            "-C"
            "-c"
          ]) ["git" "/usr/bin/git"];
    };
    dest = "$HOME/.config/devin/config.json";
    label = "devin-config";
  };
in {
  dotfilesAgents.classAMerges = [(agentsLib.mkDiffCommand configEntry)];

  # Only allow/deny/ask are declared: org_id, setup state, model, theme,
  # version and other app-owned keys survive. These arrays are replaced
  # wholesale on switch; promote durable rules into this declaration.
  home.activation.mergeDevinConfig = lib.hm.dag.entryAfter ["writeBoundary"] (
    agentsLib.mkMergeActivation (configEntry // {backupDir = "$HOME/.config/devin/backups";})
  );
}
