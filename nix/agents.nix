{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  homeDir = config.home.homeDirectory;
  json = pkgs.formats.json { };
  dotfilesHome = "${homeDir}/.config/nix-darwin/home";
  mutableHomeFile = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesHome}/${path}";
  pnpmHome =
    if pkgs.stdenv.isDarwin then
      "${homeDir}/Library/pnpm"
    else
      "${homeDir}/.local/share/pnpm";
  presentationMcpDir = "${homeDir}/talks/sample-spec-driven-presentation-maker/mcp-local";
  mcpServers = {
    stripe = {
      url = "https://mcp.stripe.com";
      _power = "stripe";
    };
    awspricing = {
      type = "stdio";
      command = "uvx";
      args = [ "awslabs.aws-pricing-mcp-server@latest" ];
      env.FASTMCP_LOG_LEVEL = "ERROR";
      timeout = 120000;
      disabled = false;
      _power = "cloud-architect";
    };
    awsknowledge = {
      url = "https://knowledge-mcp.global.api.aws";
      type = "http";
      _power = "cloud-architect";
    };
    awsapi = {
      command = "uvx";
      args = [ "awslabs.aws-api-mcp-server@latest" ];
      env.AWS_REGION = "us-east-2";
      disabled = false;
      autoApprove = [ ];
      _power = "cloud-architect";
    };
    context7 = {
      type = "stdio";
      command = "pnpm";
      args = [
        "dlx"
        "@upstash/context7-mcp"
      ];
      timeout = 120000;
      disabled = false;
      _power = "cloud-architect";
    };
    fetch = {
      command = "uvx";
      args = [ "mcp-server-fetch" ];
      env = { };
      disabled = false;
      _power = "cloud-architect";
    };
    spec-driven-presentation-maker = {
      type = "stdio";
      command = "uv";
      args = [
        "run"
        "--directory"
        presentationMcpDir
        "python"
        "server.py"
      ];
      disabled = false;
    };
  };
in
{
  programs.agent-skills = {
    enable = true;
    sources.personal = {
      input = "agent-skills";
      filter.maxDepth = 1;
    };
    skills.enableAll = [ "personal" ];
    targets.agents.enable = true;
    targets.claude.enable = true;
    targets.codex.enable = true;
    targets.cursor.enable = true;
  };

  home.file = {
    ".agents/AGENTS.md".source = ../home/ai/AGENTS.md;

    ".claude/AGENTS.md".source = ../home/ai/AGENTS.md;
    ".claude/CLAUDE.md".source = ../home/ai/CLAUDE.md;
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
          "Bash(dev-browser *)"
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

    ".codex/AGENTS.md".source = mutableHomeFile "ai/AGENTS.md";
    ".codex/keybindings.json".source = mutableHomeFile "agents/codex/keybindings.json";
    ".codex/config.toml".source = mutableHomeFile "agents/codex/config.toml";
    ".codex/openai.config.toml".source = mutableHomeFile "agents/codex/openai.config.toml";
    ".codex/bedrock.config.toml".source = mutableHomeFile "agents/codex/bedrock.config.toml";
    ".codex/rules/default.rules".source = mutableHomeFile "agents/codex/default.rules";
    ".codex/notify.sh".source = mutableHomeFile "agents/codex/notify.sh";

    ".cursor/AGENTS.md".source = ../home/ai/AGENTS.md;
    ".cursor/mcp.json".source = json.generate "cursor-mcp.json" {
      mcpServers = {
        playwright = {
          command = "pnpm";
          args = [
            "dlx"
            "@playwright/mcp@latest"
          ];
        };
        "awslabs.aws-documentation-mcp-server" = {
          command = "uvx";
          args = [ "awslabs.aws-documentation-mcp-server@latest" ];
          env = {
            FASTMCP_LOG_LEVEL = "ERROR";
            AWS_DOCUMENTATION_PARTITION = "aws";
          };
        };
        "aws-knowledge-mcp-server".url = "https://knowledge-mcp.global.api.aws";
        context7 = {
          command = "pnpm";
          args = [
            "dlx"
            "@upstash/context7-mcp@latest"
          ];
        };
      };
    };
    ".cursor/cli-config.json".source = json.generate "cursor-cli-config.json" {
      permissions = {
        allow = [ "Shell(ls)" ];
        deny = [ ];
      };
      version = 1;
      editor.vimMode = false;
      display = {
        showLineNumbers = false;
        showThinkingBlocks = false;
        showStatusIndicators = true;
      };
      statusLine = {
        type = "command";
        command = "~/.cursor/statusline.sh";
        padding = 2;
        updateIntervalMs = 300;
        timeoutMs = 2000;
      };
      model = {
        modelId = "default";
        displayModelId = "auto";
        displayName = "Auto";
        displayNameShort = "Auto";
        aliases = [ "auto" ];
        maxMode = false;
      };
      hasChangedDefaultModel = true;
      maxMode = false;
      modelParameters.default = [ ];
      selectedModel = {
        modelId = "default";
        parameters = [ ];
      };
      network.useHttp1ForAgent = false;
      approvalMode = "allowlist";
      sandbox = {
        mode = "disabled";
        networkAccess = "user_config_with_defaults";
      };
      runEverythingSettingsPromptStreak = 1;
      attribution = {
        attributeCommitsToAgent = true;
        attributePRsToAgent = true;
      };
    };
    ".cursor/statusline.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        set -euo pipefail

        payload=$(cat)
        model=$(echo "$payload" | jq -r '.model.display_name // "?"')
        pct=$(echo "$payload" | jq -r '.context_window.used_percentage // 0' | awk '{ printf "%.0f", $1 }')
        dir=$(echo "$payload" | jq -r '.cwd // .workspace.current_dir // ""')

        wt=""
        wt_name=$(echo "$payload" | jq -r '.worktree.name // empty')
        if [[ -n "$wt_name" ]]; then
          printf -v wt '\033[33m[wt:%s]\033[0m ' "$wt_name"
        fi

        short="''${dir##*/}"
        branch_sfx=""
        if [[ -n "$dir" ]] && git -C "$dir" rev-parse --git-dir >/dev/null 2>&1; then
          b=$(git -C "$dir" branch --show-current 2>/dev/null || true)
          if [[ -n "$b" ]]; then
            branch_sfx=$(printf ' | \033[35m%s\033[0m' "$b")
          fi
        fi

        printf '\033[36m%s\033[0m %s\033[90m📁 %s\033[0m  ctx \033[33m%s%%\033[0m%s' \
          "$model" "$wt" "$short" "$pct" "$branch_sfx"
      '';
    };

    ".kiro/powers.json".source = json.generate "kiro-powers.json" {
      "$schema" = "https://kiro.dev/schemas/powers-manifest.json";
      version = 1;
      powers = {
        stripe = {
          displayName = "Stripe Payments";
          description = "Build payment integrations with Stripe - accept payments, manage subscriptions, handle billing, and process refunds";
          type = "guided-mcp";
          active = true;
          source = {
            type = "local";
            path = "${homeDir}/.kiro/powers/stripe";
          };
          installedAt = "2026-03-29T16:36:05.235Z";
          updatedAt = "2026-03-29T16:36:05.235Z";
          keywords = [
            "stripe"
            "payments"
            "checkout"
            "subscriptions"
            "billing"
            "invoices"
            "refunds"
            "payment-intents"
          ];
          author = "Stripe";
          mcpServers = [ "stripe" ];
          steeringFiles = [ "stripe-best-practices" ];
        };
        cloud-architect = {
          displayName = "Build infrastructure on AWS";
          description = "Build AWS infrastructure with CDK in Python following AWS Well-Architected framework best practices";
          type = "guided-mcp";
          active = true;
          source = {
            type = "local";
            path = "${homeDir}/.kiro/powers/cloud-architect";
          };
          installedAt = "2026-03-29T16:36:05.538Z";
          updatedAt = "2026-03-29T16:36:05.538Z";
          keywords = [
            "aws"
            "cdk"
            "python"
            "infrastructure"
            "iac"
            "cloudformation"
            "lambda"
            "well-architected"
          ];
          author = "Christian Bonzelet";
          mcpServers = [
            "awspricing"
            "awsknowledge"
            "awsapi"
            "context7"
            "fetch"
          ];
          steeringFiles = [
            "cdk-development-guidelines"
            "cloud-engineer-agent"
            "testing-strategy"
          ];
        };
      };
    };
    ".kiro/powers.mcp.json".source = json.generate "kiro-powers-mcp.json" {
      inherit mcpServers;
    };
    ".kiro/settings/cli.json".source = json.generate "kiro-cli.json" {
      "chat.defaultModel" = "claude-opus-4.8";
    };
    ".kiro/settings/mcp.json".source = json.generate "kiro-settings-mcp.json" {
      mcpServers = { };
      powers.mcpServers = {
        "power-aws-sam-awslabs.aws-serverless-mcp-server" = {
          command = "uvx";
          args = [ "awslabs.aws-serverless-mcp-server@latest" ];
          disabled = false;
          autoApprove = [ "sam_init" ];
        };
        "power-aws-sam-fetch" = {
          command = "uvx";
          args = [ "mcp-server-fetch" ];
          env = { };
          disabled = false;
        };
        "power-aws-observability-awslabs.cloudwatch-mcp-server" = {
          command = "uvx";
          args = [ "awslabs.cloudwatch-mcp-server@latest" ];
          env = {
            AWS_PROFILE = "default";
            AWS_REGION = "us-east-1";
            FASTMCP_LOG_LEVEL = "ERROR";
          };
          disabled = false;
        };
        "power-aws-observability-awslabs.cloudwatch-applicationsignals-mcp-server" = {
          command = "uvx";
          args = [ "awslabs.cloudwatch-applicationsignals-mcp-server@latest" ];
          env = {
            AWS_PROFILE = "default";
            AWS_REGION = "us-east-1";
            FASTMCP_LOG_LEVEL = "ERROR";
          };
          disabled = false;
        };
        "power-aws-observability-awslabs.cloudtrail-mcp-server" = {
          command = "uvx";
          args = [ "awslabs.cloudtrail-mcp-server@latest" ];
          env = {
            AWS_PROFILE = "default";
            AWS_REGION = "us-east-1";
            FASTMCP_LOG_LEVEL = "ERROR";
          };
          disabled = false;
          transportType = "stdio";
        };
        "power-aws-observability-awslabs.aws-documentation-mcp-server" = {
          command = "uvx";
          args = [ "awslabs.aws-documentation-mcp-server@latest" ];
          env.FASTMCP_LOG_LEVEL = "ERROR";
          disabled = false;
        };
        "power-iam-policy-autopilot-power-iam-policy-autopilot-mcp" = {
          command = "uvx";
          args = [
            "iam-policy-autopilot@latest"
            "mcp-server"
          ];
          env = { };
          disabled = false;
        };
        "power-aws-agentcore-agentcore-mcp-server" = {
          command = "uvx";
          args = [ "awslabs.amazon-bedrock-agentcore-mcp-server@latest" ];
          disabled = true;
        };
      };
    };
    ".kiro/settings/kiro_cli_theme.json".source = json.generate "kiro-cli-theme.json" {
      responsePreset = "light";
      diffPreset = "dark";
      baseTheme = "dark";
    };
    ".kiro/powers".source = ../home/agents/kiro/powers;
  };
}
