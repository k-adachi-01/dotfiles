# Antigravity CLI (agy): class A permissions on
# ~/.gemini/antigravity-cli/settings.json. Shared skills are delivered to
# ~/.gemini/antigravity-cli/skills by programs.agent-skills in default.nix.
#
# Rule syntax is `action(target)` (command/read_file/write_file/read_url/
# execute_url/mcp), evaluated deny > ask > allow. `command` rules match
# word-prefixes literally; `regex:` evaluates each whitespace-separated
# token as an anchored regular expression.
{
  lib,
  pkgs,
  ...
}: let
  agentsLib = import ./lib.nix {inherit pkgs;};
  settingsEntry = {
    format = "json";
    # Mirrors the shared Kiro/Devin stance: permissive base plus explicit
    # guardrails for destructive operations. deny beats ask beats allow,
    # so command(*) cannot unlock anything listed below.
    value.permissions = {
      allow = [
        "command(*)"
        "read_url(*)"
        "mcp(*)"
      ];
      deny =
        [
          "command(git reset --hard)"
          "command(git checkout --)"
          "command(git restore)"
          "command(git branch -D)"
        ]
        ++ [
          # Flag clusters and flags appearing after remote/branch
          # arguments need regex rules; plain prefixes only see the
          # leading tokens.
          "command(regex:git clean -\\S*f\\S*)"
          "command(regex:git clean \\S+ -\\S*f\\S*)"
          "command(regex:git branch -\\S*D\\S*)"
          "command(regex:git push (--force.*|-f.*))"
          "command(regex:git push \\S+ (--force.*|-f.*))"
          "command(regex:git push \\S+ \\S+ (--force.*|-f.*))"
        ];
      # rm -rf/-fr asks rather than denies so routine temp-file cleanup
      # can proceed after confirmation. sudo is ask (not deny like Kiro)
      # because agy rules have no exclusion field and Go regex lacks
      # lookahead — sudo darwin-rebuild switch and nix-store-repair stay
      # reachable after a prompt. git -C/-c global options can precede a
      # denied subcommand, so those forms ask rather than claiming full
      # isolation.
      ask =
        [
          "command(rm -rf)"
          "command(rm -fr)"
          "command(/bin/rm -rf)"
          "command(/bin/rm -fr)"
          "command(sudo)"
          "command(/usr/bin/sudo)"
        ]
        ++ [
          "command(git -C)"
          "command(git -c)"
        ];
    };
    dest = "$HOME/.gemini/antigravity-cli/settings.json";
    label = "agy-settings";
  };
in {
  dotfilesAgents.classAMerges = map agentsLib.mkDiffCommand [settingsEntry];

  # Only permissions is declared: trustedWorkspaces, allowNonWorkspaceAccess,
  # colorScheme and other app-owned keys survive. These arrays are replaced
  # wholesale on switch; rules added via /permissions must be promoted here
  # to persist.
  home.activation.mergeAgySettings = lib.hm.dag.entryAfter ["writeBoundary"] (
    agentsLib.mkMergeActivation (settingsEntry // {backupDir = "$HOME/.gemini/antigravity-cli/backups";})
  );
}
