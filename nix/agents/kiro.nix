# Kiro: class A (merge) settings/powers manifests, class B (out-of-store
# link) power source files. See docs/management-policy.md.
{
  config,
  lib,
  pkgs,
  ...
}: let
  agentsLib = import ./lib.nix {inherit pkgs;};
  shared = import ./mcp.nix {inherit config pkgs;};
  inherit
    (shared)
    kiroPowersJson
    kiroPowersMcpJson
    kiroCliJson
    kiroSettingsMcpJson
    kiroCliThemeJson
    kiroPermissions
    ;
  agentSkillsBundle = config.programs.agent-skills.bundlePath;
  dotfilesRepo = "${config.home.homeDirectory}/.config/nix-darwin";
  mkLink = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesRepo}/${path}";

  mergeEntry = {
    name,
    format ? "json",
    declaredFile,
    dest,
  }:
    agentsLib.mkMergeActivation {
      inherit format declaredFile dest;
      backupDir = "$HOME/.kiro/backups";
      label = "kiro-${name}";
    };
in {
  # Class A: each of these is a full file Kiro also writes to (or could
  # write to) at runtime; only merge-on-switch keeps declared keys durable
  # without clobbering app state. Note the merge is dict-only — if Kiro is
  # ever observed appending to a *list* inside one of these (e.g. growing an
  # array of rules in place) that field should move to class C instead, see
  # nix/agents/lib.nix.
  home.activation.mergeKiroPowersJson = lib.hm.dag.entryAfter ["writeBoundary"] (mergeEntry {
    name = "powers-json";
    declaredFile = kiroPowersJson;
    dest = "$HOME/.kiro/powers.json";
  });

  home.activation.mergeKiroPowersMcpJson = lib.hm.dag.entryAfter ["writeBoundary"] (mergeEntry {
    name = "powers-mcp-json";
    declaredFile = kiroPowersMcpJson;
    dest = "$HOME/.kiro/powers.mcp.json";
  });

  home.activation.mergeKiroCliJson = lib.hm.dag.entryAfter ["writeBoundary"] (mergeEntry {
    name = "settings-cli-json";
    declaredFile = kiroCliJson;
    dest = "$HOME/.kiro/settings/cli.json";
  });

  home.activation.mergeKiroSettingsMcpJson = lib.hm.dag.entryAfter ["writeBoundary"] (mergeEntry {
    name = "settings-mcp-json";
    declaredFile = kiroSettingsMcpJson;
    dest = "$HOME/.kiro/settings/mcp.json";
  });

  home.activation.mergeKiroCliThemeJson = lib.hm.dag.entryAfter ["writeBoundary"] (mergeEntry {
    name = "settings-cli-theme-json";
    declaredFile = kiroCliThemeJson;
    dest = "$HOME/.kiro/settings/kiro_cli_theme.json";
  });

  home.activation.mergeKiroPermissions = lib.hm.dag.entryAfter ["writeBoundary"] (mergeEntry {
    name = "settings-permissions-yaml";
    format = "yaml";
    declaredFile = kiroPermissions;
    dest = "$HOME/.kiro/settings/permissions.yaml";
  });

  # Class B: Kiro reads these power source files but does not write to them.
  # ~/.kiro/powers/ itself stays a real (non-symlinked) directory because
  # Kiro creates its own registries/ etc. alongside stripe/ and
  # cloud-architect/; only the individual files inside are linked.
  home.file = {
    ".kiro/powers/stripe/POWER.md".source = mkLink "home/agents/kiro/powers/stripe/POWER.md";
    ".kiro/powers/stripe/mcp.json".source = mkLink "home/agents/kiro/powers/stripe/mcp.json";
    ".kiro/powers/stripe/steering/stripe-best-practices.md".source = mkLink "home/agents/kiro/powers/stripe/steering/stripe-best-practices.md";

    ".kiro/powers/cloud-architect/POWER.md".source = mkLink "home/agents/kiro/powers/cloud-architect/POWER.md";
    ".kiro/powers/cloud-architect/mcp.json".source = mkLink "home/agents/kiro/powers/cloud-architect/mcp.json";
    ".kiro/powers/cloud-architect/steering/cdk-development-guidelines.md".source = mkLink "home/agents/kiro/powers/cloud-architect/steering/cdk-development-guidelines.md";
    ".kiro/powers/cloud-architect/steering/cloud-engineer-agent.md".source = mkLink "home/agents/kiro/powers/cloud-architect/steering/cloud-engineer-agent.md";
    ".kiro/powers/cloud-architect/steering/testing-strategy.md".source = mkLink "home/agents/kiro/powers/cloud-architect/steering/testing-strategy.md";
  };

  # Skills are a dynamic catalog, not a class A/B file: always mirror the
  # built bundle on every switch (delete+resync), independent of the merge
  # model above.
  home.activation.syncKiroSkills = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "$HOME/.kiro/skills"
    ${pkgs.rsync}/bin/rsync -aL --delete --exclude='.system/' ${agentSkillsBundle}/ "$HOME/.kiro/skills/"
    chmod -R u+rwX "$HOME/.kiro/skills"
  '';
}
