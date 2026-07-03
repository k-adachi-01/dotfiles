# Entry point for AI agent config. Each tool has its own file; shared
# infrastructure lives in lib.nix (class A merge helper) and mcp.nix
# (shared MCP/power definitions). See docs/management-policy.md for the
# class A/B/C model this is built around and AGENTS.md for the source map.
{
  config,
  lib,
  ...
}: let
  dotfilesRepo = "${config.home.homeDirectory}/.config/nix-darwin";
  mkLink = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesRepo}/${path}";
in {
  options.dotfilesAgents.classAMerges = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [];
    internal = true;
    description = ''
      One shell snippet per class A (declare + merge) file, each of which
      prints what the next `switch` would change plus any live keys not
      declared in Nix. Every tool file (codex.nix, claude.nix, cursor.nix,
      kiro.nix) appends to this list via nix/agents/lib.nix's
      mkDiffCommand. Aggregated into ~/.local/bin/agents-diff.
    '';
  };

  imports = [
    ./codex.nix
    ./claude.nix
    ./cursor.nix
    ./kiro.nix
  ];

  config.programs.agent-skills = {
    enable = true;
    sources.personal = {
      input = "agent-skills";
      filter.maxDepth = 1;
    };
    skills.enableAll = ["personal"];
    targets.agents.enable = true;
    targets.claude.enable = true;
    targets.codex.enable = false;
    targets.cursor.enable = true;
    targets.kiro = {
      dest = "$HOME/.kiro/skills";
      enable = false;
      systems = [];
    };
  };

  config.home.file = {
    # Class B: agents.md target reads this but never writes to it, so an
    # out-of-store symlink (edit the repo, no switch needed) is safe. This
    # must match every other class B AGENTS.md/CLAUDE.md symlink below (see
    # nix/agents/{claude,codex,cursor}.nix) — a plain Nix path here would
    # silently degrade to a store copy that only updates on switch, which is
    # exactly the seed-only drift this model exists to avoid.
    ".agents/AGENTS.md".source = mkLink "home/ai/AGENTS.md";

    ".local/bin/agents-diff" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Shows, for every class A (declare + merge) file across all AI
        # agent tools, what the next `darwin-rebuild switch` would change
        # and which live keys are app-owned (not declared in Nix, so never
        # touched by the merge). Read-only: never writes to any live file.
        # See docs/management-policy.md section 4 for the promotion
        # workflow (live app-owned key -> repo attrset -> switch).
        set -uo pipefail

        ${lib.concatStringsSep "\n" config.dotfilesAgents.classAMerges}
        exit 0
      '';
    };

    ".local/bin/skills-push" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        set -euo pipefail

        skills_dir="$HOME/agent-skills"
        dotfiles_dir="$HOME/.config/nix-darwin"

        if [ ! -d "$skills_dir/.git" ]; then
          echo "skills-push: $skills_dir is not a git checkout" >&2
          exit 1
        fi

        echo "==> git status in $skills_dir"
        git -C "$skills_dir" status --short --branch

        if [ -n "$(git -C "$skills_dir" status --porcelain)" ]; then
          git -C "$skills_dir" add -A
          if [ $# -gt 0 ]; then
            git -C "$skills_dir" commit -m "$*"
          else
            git -C "$skills_dir" commit
          fi
        else
          echo "skills-push: no local changes to commit"
        fi

        echo "==> pushing $skills_dir"
        git -C "$skills_dir" push origin HEAD

        echo "==> refreshing agent-skills narHash in flake.lock"
        nix flake update agent-skills --flake "$dotfiles_dir"

        echo "==> sudo darwin-rebuild switch"
        sudo darwin-rebuild switch --flake "$dotfiles_dir#macbook"

        echo "==> verifying activated skill paths"
        for target in "$HOME/.claude/skills" "$HOME/.cursor/skills" "$HOME/.agents/skills"; do
          if [ -e "$target" ]; then
            echo "$target -> $(readlink -f "$target" 2>/dev/null || echo "(not a symlink)")"
          fi
        done
        for target in "$HOME/.codex/skills" "$HOME/.kiro/skills"; do
          if [ -d "$target" ]; then
            echo "$target: $(find "$target" -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ') skill dirs present"
          fi
        done
      '';
    };
  };
}
