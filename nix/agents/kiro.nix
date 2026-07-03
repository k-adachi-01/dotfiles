# Kiro: still seed-only today (home.activation creates files once, never
# overwrites). Migrating to the class A/B model is tracked as PR7 in
# docs/management-policy.md; until that lands, edits to nix/agents/kiro.nix
# or home/agents/kiro/ only take effect for files that do not already exist
# on disk. Run ~/.local/bin/sync-kiro-config to force a re-apply.
{
  config,
  lib,
  pkgs,
  ...
}: let
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
in {
  home.activation.seedKiroFiles = lib.hm.dag.entryAfter ["writeBoundary"] ''
    set -euo pipefail

    is_store_link() {
      local path="$1"
      [ -L "$path" ] || return 1

      local target
      target="$(${pkgs.coreutils}/bin/realpath "$path" 2>/dev/null || true)"
      [[ "$target" == /nix/store/* ]]
    }

    seed_file() {
      local src="$1"
      local dest="$2"
      local mode="''${3:-0644}"

      if is_store_link "$dest"; then
        rm -f "$dest"
      elif [ -e "$dest" ]; then
        return 0
      fi

      mkdir -p "$(dirname "$dest")"
      install -m "$mode" "$src" "$dest"
    }

    seed_dir() {
      local src="$1"
      local dest="$2"

      if is_store_link "$dest"; then
        rm -f "$dest"
      elif [ -e "$dest" ] && [ ! -d "$dest" ]; then
        echo "seedKiroFiles: $dest exists and is not a directory" >&2
        exit 1
      fi

      mkdir -p "$dest"
      ${pkgs.rsync}/bin/rsync -aL --ignore-existing "$src/" "$dest/"
      chmod -R u+rwX "$dest"
    }

    seed_agent_skills_dir() {
      local src="$1"
      local dest="$2"

      if is_store_link "$dest"; then
        rm -f "$dest"
      elif [ -e "$dest" ] && [ ! -d "$dest" ]; then
        echo "seedKiroFiles: $dest exists and is not a directory" >&2
        exit 1
      fi

      mkdir -p "$dest"
      ${pkgs.rsync}/bin/rsync -aL --delete --exclude='.system/' "$src/" "$dest/"
      chmod -R u+rwX "$dest"
    }

    seed_file ${kiroPowersJson} "$HOME/.kiro/powers.json"
    seed_file ${kiroPowersMcpJson} "$HOME/.kiro/powers.mcp.json"
    seed_file ${kiroCliJson} "$HOME/.kiro/settings/cli.json"
    seed_file ${kiroSettingsMcpJson} "$HOME/.kiro/settings/mcp.json"
    seed_file ${kiroPermissions} "$HOME/.kiro/settings/permissions.yaml"
    seed_file ${kiroCliThemeJson} "$HOME/.kiro/settings/kiro_cli_theme.json"
    seed_dir ${../../home/agents/kiro/powers/stripe} "$HOME/.kiro/powers/stripe"
    seed_dir ${../../home/agents/kiro/powers/cloud-architect} "$HOME/.kiro/powers/cloud-architect"
    seed_agent_skills_dir ${agentSkillsBundle} "$HOME/.kiro/skills"
  '';

  home.file.".local/bin/sync-kiro-config" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      backup_root="$HOME/.kiro/backups/manual-sync-$(date +%Y%m%d%H%M%S)"

      backup_path() {
        local path="$1"
        if [ -e "$path" ] || [ -L "$path" ]; then
          local rel="''${path#$HOME/.kiro/}"
          mkdir -p "$backup_root/$(dirname "$rel")"
          cp -a "$path" "$backup_root/$rel"
        fi
      }

      sync_file() {
        local src="$1"
        local dest="$2"
        local mode="''${3:-0644}"
        backup_path "$dest"
        mkdir -p "$(dirname "$dest")"
        rm -f "$dest"
        install -m "$mode" "$src" "$dest"
      }

      sync_dir() {
        local src="$1"
        local dest="$2"
        backup_path "$dest"
        mkdir -p "$dest"
        ${pkgs.rsync}/bin/rsync -aL "$src/" "$dest/"
        chmod -R u+rwX "$dest"
      }

      sync_agent_skills_dir() {
        local src="$1"
        local dest="$2"
        backup_path "$dest"
        mkdir -p "$dest"
        ${pkgs.rsync}/bin/rsync -aL --delete --exclude='.system/' "$src/" "$dest/"
        chmod -R u+rwX "$dest"
      }

      sync_file ${kiroPowersJson} "$HOME/.kiro/powers.json"
      sync_file ${kiroPowersMcpJson} "$HOME/.kiro/powers.mcp.json"
      sync_file ${kiroCliJson} "$HOME/.kiro/settings/cli.json"
      sync_file ${kiroSettingsMcpJson} "$HOME/.kiro/settings/mcp.json"
      sync_file ${kiroPermissions} "$HOME/.kiro/settings/permissions.yaml"
      sync_file ${kiroCliThemeJson} "$HOME/.kiro/settings/kiro_cli_theme.json"
      sync_dir ${../../home/agents/kiro/powers/stripe} "$HOME/.kiro/powers/stripe"
      sync_dir ${../../home/agents/kiro/powers/cloud-architect} "$HOME/.kiro/powers/cloud-architect"
      sync_agent_skills_dir ${agentSkillsBundle} "$HOME/.kiro/skills"

      echo "sync-kiro-config: backup written to $backup_root"
    '';
  };
}
