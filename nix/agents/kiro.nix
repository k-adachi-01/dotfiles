# Kiro: class A (merge) user settings, class B (out-of-store link) Agent
# Plugins package files. Power installation state is Kiro-owned. See
# docs/management-policy.md.
{
  config,
  lib,
  pkgs,
  dotfilesRepo ? "${config.home.homeDirectory}/.config/nix-darwin",
  enableAgentSkills ? true,
  ...
}: let
  agentsLib = import ./lib.nix {inherit pkgs;};
  shared = import ./mcp.nix {inherit config pkgs;};
  inherit
    (shared)
    kiroCliJson
    kiroSettingsMcpJson
    kiroCliThemeJson
    kiroPermissions
    ;
  mkLink = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesRepo}/${path}";

  mkEntry = {
    name,
    format ? "json",
    declaredFile,
    dest,
  }: {
    inherit format declaredFile dest;
    label = "kiro-${name}";
  };

  entries = [
    (mkEntry {
      name = "settings-cli-json";
      declaredFile = kiroCliJson;
      dest = "$HOME/.kiro/settings/cli.json";
    })
    (mkEntry {
      name = "settings-mcp-json";
      declaredFile = kiroSettingsMcpJson;
      dest = "$HOME/.kiro/settings/mcp.json";
    })
    (mkEntry {
      name = "settings-cli-theme-json";
      declaredFile = kiroCliThemeJson;
      dest = "$HOME/.kiro/settings/kiro_cli_theme.json";
    })
    (mkEntry {
      name = "settings-permissions-yaml";
      format = "yaml";
      declaredFile = kiroPermissions;
      dest = "$HOME/.kiro/settings/permissions.yaml";
    })
  ];
in {
  dotfilesAgents.classAMerges = map agentsLib.mkDiffCommand entries;

  home = {
    # Class A: each of these is a full file Kiro also writes to (or could
    # write to) at runtime; only merge-on-switch keeps declared keys
    # durable without clobbering app state. Note the merge is dict-only —
    # if Kiro is ever observed appending to a *list* inside one of these
    # (e.g. growing an array of rules in place) that field should move to
    # class C instead, see nix/agents/lib.nix.
    activation.mergeKiroCliJson = lib.hm.dag.entryAfter ["writeBoundary"] (
      agentsLib.mkMergeActivation ((builtins.elemAt entries 0) // {backupDir = "$HOME/.kiro/backups";})
    );

    activation.mergeKiroSettingsMcpJson = lib.hm.dag.entryAfter ["writeBoundary"] (
      agentsLib.mkMergeActivation ((builtins.elemAt entries 1) // {backupDir = "$HOME/.kiro/backups";})
    );

    activation.mergeKiroCliThemeJson = lib.hm.dag.entryAfter ["writeBoundary"] (
      agentsLib.mkMergeActivation ((builtins.elemAt entries 2) // {backupDir = "$HOME/.kiro/backups";})
    );

    activation.mergeKiroPermissions = lib.hm.dag.entryAfter ["writeBoundary"] (
      agentsLib.mkMergeActivation ((builtins.elemAt entries 3) // {backupDir = "$HOME/.kiro/backups";})
    );

    # Class B: Kiro reads Agent Plugins from these source files but does not
    # write to them. Keep ~/.kiro/powers/ as a real directory because Kiro
    # maintains its own registries there; link each package file to the repo.
    file = {
      ".kiro/powers/stripe/plugin.json".source = mkLink "home/agents/kiro/powers/stripe/plugin.json";
      ".kiro/powers/stripe/mcp.json".source = mkLink "home/agents/kiro/powers/stripe/mcp.json";
      ".kiro/powers/stripe/skills/stripe-payments/SKILL.md".source = mkLink "home/agents/kiro/powers/stripe/skills/stripe-payments/SKILL.md";
      ".kiro/powers/stripe/dev.kiro/steering/stripe-best-practices.md".source = mkLink "home/agents/kiro/powers/stripe/dev.kiro/steering/stripe-best-practices.md";

      ".kiro/powers/cloud-architect/plugin.json".source = mkLink "home/agents/kiro/powers/cloud-architect/plugin.json";
      ".kiro/powers/cloud-architect/mcp.json".source = mkLink "home/agents/kiro/powers/cloud-architect/mcp.json";
      ".kiro/powers/cloud-architect/skills/cloud-architect/SKILL.md".source = mkLink "home/agents/kiro/powers/cloud-architect/skills/cloud-architect/SKILL.md";
      ".kiro/powers/cloud-architect/dev.kiro/steering/cdk-development-guidelines.md".source = mkLink "home/agents/kiro/powers/cloud-architect/dev.kiro/steering/cdk-development-guidelines.md";
      ".kiro/powers/cloud-architect/dev.kiro/steering/cloud-engineer-agent.md".source = mkLink "home/agents/kiro/powers/cloud-architect/dev.kiro/steering/cloud-engineer-agent.md";
      ".kiro/powers/cloud-architect/dev.kiro/steering/testing-strategy.md".source = mkLink "home/agents/kiro/powers/cloud-architect/dev.kiro/steering/testing-strategy.md";
    };

    # Skills are a dynamic catalog, not a class A/B file: always mirror the
    # built bundle on every switch (delete+resync), independent of the
    # merge model above.
    activation.syncKiroSkills = lib.mkIf enableAgentSkills (lib.hm.dag.entryAfter ["writeBoundary"] ''
      mkdir -p "$HOME/.kiro/skills"
      ${pkgs.rsync}/bin/rsync -aL --delete --exclude='.system/' ${config.programs.agent-skills.bundlePath}/ "$HOME/.kiro/skills/"
      chmod -R u+rwX "$HOME/.kiro/skills"
    '');
  };
}
