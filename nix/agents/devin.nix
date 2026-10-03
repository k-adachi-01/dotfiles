# Devin CLI: class A permissions; shared skills are discovered through
# ~/.agents/skills, managed by programs.agent-skills in default.nix.
{
  config,
  lib,
  pkgs,
  ...
}: let
  agentsLib = import ./lib.nix {inherit pkgs;};
  shared = import ./mcp.nix {inherit config pkgs;};
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
      deny = lib.concatMap (git:
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
      # rm -rf/-fr asks rather than denies so routine temp-file cleanup
      # can proceed after confirmation.
      ask =
        [
          "Exec(sudo)"
          "Exec(/usr/bin/sudo)"
          "Exec(rm -rf)"
          "Exec(rm -fr)"
          "Exec(/bin/rm -rf)"
          "Exec(/bin/rm -fr)"
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
  # Since Devin CLI v3000.3 MCP servers live in a dedicated file; entries
  # left in config.json are migrated here by the app on startup anyway.
  mcpEntry = {
    format = "json";
    value.mcpServers =
      {
        linear = {
          url = shared.linearMcpUrl;
          transport = "http";
        };
      }
      // shared.awsMcpServers;
    dest = "$HOME/.config/devin/mcp_config.json";
    label = "devin-mcp";
  };
in {
  dotfilesAgents.classAMerges = map agentsLib.mkDiffCommand [configEntry mcpEntry];

  # Only allow/deny/ask are declared: org_id, setup state, model, theme,
  # version and other app-owned keys survive. These arrays are replaced
  # wholesale on switch; promote durable rules into this declaration.
  home.activation.mergeDevinConfig = lib.hm.dag.entryAfter ["writeBoundary"] (
    agentsLib.mkMergeActivation (configEntry // {backupDir = "$HOME/.config/devin/backups";})
  );
  home.activation.mergeDevinMcp = lib.hm.dag.entryAfter ["writeBoundary"] (
    agentsLib.mkMergeActivation (mcpEntry // {backupDir = "$HOME/.config/devin/backups";})
  );
}
