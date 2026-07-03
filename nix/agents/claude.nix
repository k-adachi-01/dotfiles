# Claude Code: class A (merge) settings/mcp/keybindings, class B
# (out-of-store link) everything it reads but never writes. See
# docs/management-policy.md.
{
  config,
  lib,
  pkgs,
  ...
}: let
  agentsLib = import ./lib.nix {inherit pkgs;};
  shared = import ./mcp.nix {inherit config pkgs;};
  inherit (shared) presentationMcpDir pnpmHome;
  dotfilesRepo = "${config.home.homeDirectory}/.config/nix-darwin";
  mkLink = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesRepo}/${path}";

  settingsValue = {
    env = {
      PNPM_HOME = pnpmHome;
      CLAUDE_CODE_USE_BEDROCK = "1";
      AWS_REGION = "us-east-1";
      AWS_PROFILE = "default";
      ANTHROPIC_DEFAULT_SONNET_MODEL = "us.anthropic.claude-sonnet-4-6";
      ANTHROPIC_DEFAULT_OPUS_MODEL = "us.anthropic.claude-opus-4-7";
      ANTHROPIC_DEFAULT_HAIKU_MODEL = "us.anthropic.claude-haiku-4-5-20251001-v1:0";
    };
    permissions = {
      allow = [
        "Bash(codex:*)"
        "Read(*)"
        "Glob(*)"
        "Grep(*)"
        "Edit(*)"
        "Write(*)"
        "MultiEdit(*)"
        "Bash(ls)"
        "Bash(ls *)"
        "Bash(find *)"
        "Bash(grep *)"
        "Bash(cat)"
        "Bash(cat *)"
        "Bash(head *)"
        "Bash(tail *)"
        "Bash(wc *)"
        "Bash(stat *)"
        "Bash(file *)"
        "Bash(echo *)"
        "Bash(pwd)"
        "Bash(which *)"
        "Bash(jq *)"
        "Bash(sort *)"
        "Bash(uniq *)"
        "Bash(cut *)"
        "Bash(date)"
        "Bash(date *)"
        "Bash(df *)"
        "Bash(du *)"
        "Bash(* --version)"
        "Bash(* --help *)"
        "Bash(git status *)"
        "Bash(git diff *)"
        "Bash(git log)"
        "Bash(git log *)"
        "Bash(git show)"
        "Bash(git show *)"
        "Bash(git blame *)"
        "Bash(git tag)"
        "Bash(git tag *)"
        "Bash(git remote)"
        "Bash(git remote *)"
        "Bash(git add *)"
        "Bash(git commit *)"
        "Bash(git checkout *)"
        "Bash(git branch *)"
        "Bash(git stash *)"
        "Bash(git fetch *)"
        "Bash(git pull *)"
        "Bash(git -C ~/.claude/references/*)"
        "Bash(pnpm exec *)"
        "Bash(pnpm run *)"
        "Bash(pnpm install)"
        "Bash(pnpm install *)"
        "Bash(pnpm add *)"
        "Bash(pnpm remove *)"
        "Bash(pnpm dlx *)"
        "Bash(pnpm test *)"
        "Bash(vitest *)"
        "Bash(agent-browser *)"
        "Bash(playwright-cli *)"
      ];
      deny = [
        "Bash(sudo *)"
        "Bash(su *)"
        "Bash(chmod *)"
        "Bash(chown *)"
        "Bash(wget *)"
        "Bash(ssh *)"
        "Bash(scp *)"
        "Bash(rsync *)"
        "Read(**/.env)"
        "Read(**/.env.*)"
        "Read(**/id_rsa)"
        "Read(**/id_ed25519)"
        "Read(**/*.pem)"
        "Read(**/*.key)"
      ];
    };
    hooks.Stop = [
      {
        hooks = [
          {
            type = "command";
            command = "bash ~/.claude/notify-done.sh";
            async = true;
          }
          {
            type = "command";
            command = ''PLAN_DIR="$HOME/.claude/plans"; RECENT=$(ls -t "$PLAN_DIR"/*.md 2>/dev/null | head -1); LAST_FILE="$HOME/.claude/.last-opened-plan"; if [ -n "$RECENT" ]; then LAST=$(cat "$LAST_FILE" 2>/dev/null); if [ "$RECENT" != "$LAST" ]; then echo "$RECENT" > "$LAST_FILE"; mo "$RECENT"; fi; fi'';
            async = true;
          }
        ];
      }
    ];
    statusLine = {
      type = "command";
      command = "~/.claude/statusline.py";
    };
    enabledPlugins = {
      "typescript-lsp@claude-plugins-official" = true;
      "pyright-lsp@claude-plugins-official" = true;
      "deploy-on-aws@claude-plugins-official" = true;
      "aws-serverless@claude-plugins-official" = true;
    };
    extraKnownMarketplaces = {
      anthropic-agent-skills.source = {
        source = "github";
        repo = "anthropics/skills";
      };
      agent-plugins-for-aws.source = {
        source = "github";
        repo = "awslabs/agent-plugins";
      };
      everything-claude-code.source = {
        source = "github";
        repo = "affaan-m/everything-claude-code";
      };
      claude-plugins-official.source = {
        source = "github";
        repo = "anthropics/claude-plugins-official";
      };
    };
    effortLevel = "xhigh";
    tui = "fullscreen";
  };

  mcpValue = {
    mcpServers.spec-driven-presentation-maker = {
      command = "uv";
      args = [
        "run"
        "--directory"
        presentationMcpDir
        "python"
        "server.py"
      ];
    };
  };

  keybindingsValue = {
    "$schema" = "https://www.schemastore.org/claude-code-keybindings.json";
    "$docs" = "https://code.claude.com/docs/en/keybindings";
    bindings = [
      {
        context = "Chat";
        bindings = {
          enter = null;
          "ctrl+enter" = "chat:submit";
          "shift+enter" = "chat:newline";
        };
      }
    ];
  };

  backupDir = "$HOME/.claude/backups";

  settingsEntry = {
    format = "json";
    value = settingsValue;
    dest = "$HOME/.claude/settings.json";
    label = "claude-settings";
  };
  mcpEntry = {
    format = "json";
    value = mcpValue;
    dest = "$HOME/.claude/.mcp.json";
    label = "claude-mcp";
  };
  keybindingsEntry = {
    format = "json";
    value = keybindingsValue;
    dest = "$HOME/.claude/keybindings.json";
    label = "claude-keybindings";
  };
in {
  dotfilesAgents.classAMerges =
    map agentsLib.mkDiffCommand [settingsEntry mcpEntry keybindingsEntry];

  home = {
    # Class A: Claude writes trust decisions, model selection, and other UI
    # state into settings.json/.mcp.json at runtime; merge-on-switch keeps
    # our declared keys durable without clobbering that state. See
    # nix/agents/lib.nix for the dict-only merge caveat.
    activation.mergeClaudeSettings = lib.hm.dag.entryAfter ["writeBoundary"] (
      agentsLib.mkMergeActivation (settingsEntry // {inherit backupDir;})
    );
    activation.mergeClaudeMcp = lib.hm.dag.entryAfter ["writeBoundary"] (
      agentsLib.mkMergeActivation (mcpEntry // {inherit backupDir;})
    );
    activation.mergeClaudeKeybindings = lib.hm.dag.entryAfter ["writeBoundary"] (
      agentsLib.mkMergeActivation (keybindingsEntry // {inherit backupDir;})
    );

    # Class B: Claude never writes to any of these, so a repo-editable
    # symlink is safe and gives "edit repo, effective immediately" without
    # a switch.
    file = {
      ".claude/AGENTS.md".source = ../../home/ai/AGENTS.md;
      ".claude/CLAUDE.md".source = ../../home/ai/CLAUDE.md;
      ".claude/statusline.py".source = mkLink "home/agents/claude/statusline.py";
      ".claude/notify-done.sh".source = mkLink "home/agents/claude/notify-done.sh";
    };
  };
}
