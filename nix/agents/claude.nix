# Claude Code: still Nix store symlinks today (home.file.source). Migrating
# to the class A/B model is tracked as PR8 in docs/management-policy.md;
# until that lands, Claude cannot write back to settings.json/.mcp.json
# without home-manager reverting it on the next switch.
{
  config,
  pkgs,
  ...
}: let
  shared = import ./mcp.nix {inherit config pkgs;};
  inherit (shared) presentationMcpDir pnpmHome json;
in {
  home.file = {
    ".claude/AGENTS.md".source = ../../home/ai/AGENTS.md;
    ".claude/CLAUDE.md".source = ../../home/ai/CLAUDE.md;
    ".claude/settings.json".source = json.generate "claude-settings.json" {
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
    ".claude/keybindings.json".source = json.generate "claude-keybindings.json" {
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
    ".claude/.mcp.json".source = json.generate "claude-mcp.json" {
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
    ".claude/statusline.py" = {
      executable = true;
      text = ''
        #!/usr/bin/env python3
        import json
        import sys

        if sys.platform == "win32":
            sys.stdout.reconfigure(encoding="utf-8")

        data = json.load(sys.stdin)
        BLOCKS = " ▏▎▍▌▋▊▉█"
        R = "\033[0m"
        DIM = "\033[2m"

        def gradient(pct):
            if pct < 50:
                r = int(pct * 5.1)
                return f"\033[38;2;{r};200;80m"
            g = int(200 - (pct - 50) * 4)
            return f"\033[38;2;255;{max(g, 0)};60m"

        def bar(pct, width=10):
            pct = min(max(pct, 0), 100)
            filled = pct * width / 100
            full = int(filled)
            frac = int((filled - full) * 8)
            value = "█" * full
            if full < width:
                value += BLOCKS[frac]
                value += "░" * (width - full - 1)
            return value

        def fmt(label, pct):
            p = round(pct)
            return f"{label} {gradient(pct)}{bar(pct)} {p}%{R}"

        model = data.get("model", {}).get("display_name", "Claude")
        parts = [model]

        ctx = data.get("context_window", {}).get("used_percentage")
        if ctx is not None:
            parts.append(fmt("ctx", ctx))

        five = data.get("rate_limits", {}).get("five_hour", {}).get("used_percentage")
        if five is not None:
            parts.append(fmt("5h", five))

        week = data.get("rate_limits", {}).get("seven_day", {}).get("used_percentage")
        if week is not None:
            parts.append(fmt("7d", week))

        print(f"{DIM}│{R}".join(f" {p} " for p in parts), end="")
      '';
    };
    ".claude/notify-done.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        set -euo pipefail

        data=$(cat)
        last_msg=$(echo "$data" | jq -r '.last_assistant_message // ""' 2>/dev/null)

        if [[ -n "$last_msg" && "$last_msg" != "null" ]]; then
          msg=$(echo "$last_msg" | tr '\n' ' ' | cut -c1-80)
        else
          msg="Claude Code: response completed"
        fi

        if command -v powershell.exe >/dev/null 2>&1; then
          msg_safe=$(echo "$msg" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
          ps_cmd=$(cat <<'EOF'
        $null = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
        $null = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]
        $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
        $xml.LoadXml("<toast><visual><binding template='ToastText01'><text id='1'>MSG_PLACEHOLDER</text></binding></visual></toast>")
        $toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("Claude Code").Show($toast)
        EOF
        )
          ps_cmd="''${ps_cmd/MSG_PLACEHOLDER/$msg_safe}"
          encoded=$(echo -n "$ps_cmd" | iconv -t UTF-16LE | base64 -w 0)
          powershell.exe -EncodedCommand "$encoded" 2>/dev/null || true
        elif command -v osascript >/dev/null 2>&1; then
          osascript -e "display notification \"$msg\" with title \"Claude Code\""
        else
          printf 'Claude Code: %s\n' "$msg"
        fi
      '';
    };
  };
}
