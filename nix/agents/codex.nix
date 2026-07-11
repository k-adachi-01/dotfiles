# Codex: class A (merge) config.toml, class B (out-of-store link) everything
# else it reads but never writes. See docs/management-policy.md.
{
  config,
  lib,
  pkgs,
  dotfilesRepo ? "${config.home.homeDirectory}/.config/nix-darwin",
  enableAgentSkills ? true,
  ...
}: let
  agentsLib = import ./lib.nix {inherit pkgs;};
  mkLink = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesRepo}/${path}";
  declaredConfig =
    (builtins.fromTOML (builtins.readFile ../../home/agents/codex/config.toml))
    // {
      notify = [
        "bash"
        "${config.home.homeDirectory}/.codex/notify.sh"
      ];
    };

  configEntry = {
    format = "toml";
    value = declaredConfig;
    dest = "$HOME/.codex/config.toml";
    label = "codex-config";
  };
in {
  dotfilesAgents.classAMerges = [(agentsLib.mkDiffCommand configEntry)];

  home = {
    # Class A: home/agents/codex/config.toml is the human-editable
    # declaration of the keys we own (model, personality, notice, tui,
    # plugins, features, desktop, notify). Everything else Codex writes at
    # runtime — [projects.*] trust decisions, [marketplaces.*] cache paths,
    # [mcp_servers.node_repl] — is left alone because it is simply absent
    # from the declared value.
    activation.mergeCodexConfig = lib.hm.dag.entryAfter ["writeBoundary"] (
      agentsLib.mkMergeActivation (configEntry // {backupDir = "$HOME/.codex/backups";})
    );

    # Class B: Codex never writes to any of these, so a repo-editable
    # symlink is safe and gives "edit repo, effective immediately" without
    # a switch.
    file = {
      ".codex/AGENTS.md".source = mkLink "home/ai/AGENTS.md";
      ".codex/keybindings.json".source = mkLink "home/agents/codex/keybindings.json";
      ".codex/openai.config.toml".source = mkLink "home/agents/codex/openai.config.toml";
      ".codex/bedrock.config.toml".source = mkLink "home/agents/codex/bedrock.config.toml";
      ".codex/rules/default.rules".source = mkLink "home/agents/codex/default.rules";
      ".codex/notify.sh".source = mkLink "home/agents/codex/notify.sh";
    };

    # Skills are a dynamic catalog, not a class A/B file: always mirror the
    # built bundle on every switch (delete+resync), independent of the
    # merge model above.
    activation.syncCodexSkills = lib.mkIf enableAgentSkills (lib.hm.dag.entryAfter ["writeBoundary"] ''
      mkdir -p "$HOME/.codex/skills"
      ${pkgs.rsync}/bin/rsync -aL --delete --exclude='.system/' ${config.programs.agent-skills.bundlePath}/ "$HOME/.codex/skills/"
      chmod -R u+rwX "$HOME/.codex/skills"
    '');
  };
}
