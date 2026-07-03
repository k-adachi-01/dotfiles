{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  homeDir = config.home.homeDirectory;
  json = pkgs.formats.json {};
  kiroPermissions =
    pkgs.runCommand "kiro-permissions.yaml" {
      nativeBuildInputs = [pkgs.ruby];
      src = ../home/agents/codex/default.rules;
    } ''
      ruby <<'RUBY' > "$out"
      commands = []

      File.foreach(ENV.fetch("src")) do |line|
        next unless line =~ /prefix_rule\(pattern=\[(.*?)\], decision="allow"\)/

        command = Regexp.last_match(1)
          .scan(/"((?:\\.|[^"])*)"/)
          .flatten
          .map { |part| part.gsub(/\\"/, '"') }
          .join(" ")

        commands << command
      end

      puts "rules:"
      puts "  - capability: shell"
      puts "    effect: allow"
      puts "    match:"

      commands.each do |command|
        [command, "#{command} *"].uniq.each do |pattern|
          puts "      - #{pattern.inspect}"
        end
      end
      RUBY
    '';
  pnpmHome =
    if pkgs.stdenv.isDarwin
    then "${homeDir}/Library/pnpm"
    else "${homeDir}/.local/share/pnpm";
  presentationMcpDir = "${homeDir}/talks/sample-spec-driven-presentation-maker/mcp-local";
  mcpServers = {
    stripe = {
      url = "https://mcp.stripe.com";
      _power = "stripe";
    };
    awspricing = {
      type = "stdio";
      command = "uvx";
      args = ["awslabs.aws-pricing-mcp-server@latest"];
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
      args = ["awslabs.aws-api-mcp-server@latest"];
      env.AWS_REGION = "us-east-2";
      disabled = false;
      autoApprove = [];
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
      args = ["mcp-server-fetch"];
      env = {};
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
  kiroPowersJson = json.generate "kiro-powers.json" {
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
        mcpServers = ["stripe"];
        steeringFiles = ["stripe-best-practices"];
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
  kiroPowersMcpJson = json.generate "kiro-powers-mcp.json" {
    inherit mcpServers;
  };
  kiroCliJson = json.generate "kiro-cli.json" {
    "chat.defaultModel" = "claude-opus-4.8";
  };
  kiroSettingsMcpJson = json.generate "kiro-settings-mcp.json" {
    mcpServers = {};
    powers.mcpServers = {
      "power-aws-sam-awslabs.aws-serverless-mcp-server" = {
        command = "uvx";
        args = ["awslabs.aws-serverless-mcp-server@latest"];
        disabled = false;
        autoApprove = ["sam_init"];
      };
      "power-aws-sam-fetch" = {
        command = "uvx";
        args = ["mcp-server-fetch"];
        env = {};
        disabled = false;
      };
      "power-aws-observability-awslabs.cloudwatch-mcp-server" = {
        command = "uvx";
        args = ["awslabs.cloudwatch-mcp-server@latest"];
        env = {
          AWS_PROFILE = "default";
          AWS_REGION = "us-east-1";
          FASTMCP_LOG_LEVEL = "ERROR";
        };
        disabled = false;
      };
      "power-aws-observability-awslabs.cloudwatch-applicationsignals-mcp-server" = {
        command = "uvx";
        args = ["awslabs.cloudwatch-applicationsignals-mcp-server@latest"];
        env = {
          AWS_PROFILE = "default";
          AWS_REGION = "us-east-1";
          FASTMCP_LOG_LEVEL = "ERROR";
        };
        disabled = false;
      };
      "power-aws-observability-awslabs.cloudtrail-mcp-server" = {
        command = "uvx";
        args = ["awslabs.cloudtrail-mcp-server@latest"];
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
        args = ["awslabs.aws-documentation-mcp-server@latest"];
        env.FASTMCP_LOG_LEVEL = "ERROR";
        disabled = false;
      };
      "power-iam-policy-autopilot-power-iam-policy-autopilot-mcp" = {
        command = "uvx";
        args = [
          "iam-policy-autopilot@latest"
          "mcp-server"
        ];
        env = {};
        disabled = false;
      };
      "power-aws-agentcore-agentcore-mcp-server" = {
        command = "uvx";
        args = ["awslabs.amazon-bedrock-agentcore-mcp-server@latest"];
        disabled = true;
      };
    };
  };
  kiroCliThemeJson = json.generate "kiro-cli-theme.json" {
    responsePreset = "light";
    diffPreset = "dark";
    baseTheme = "dark";
  };
  agentSkillsBundle = config.programs.agent-skills.bundlePath;
in {
  programs.agent-skills = {
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

  home.activation.seedCodexKiroFiles = lib.hm.dag.entryAfter ["writeBoundary"] ''
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
        echo "seedCodexKiroFiles: $dest exists and is not a directory" >&2
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
        echo "seedCodexKiroFiles: $dest exists and is not a directory" >&2
        exit 1
      fi

      mkdir -p "$dest"
      ${pkgs.rsync}/bin/rsync -aL --delete --exclude='.system/' "$src/" "$dest/"
      chmod -R u+rwX "$dest"
    }

    seed_file ${../home/ai/AGENTS.md} "$HOME/.codex/AGENTS.md"
    seed_file ${../home/agents/codex/keybindings.json} "$HOME/.codex/keybindings.json"
    seed_file ${../home/agents/codex/config.toml} "$HOME/.codex/config.toml"
    seed_file ${../home/agents/codex/openai.config.toml} "$HOME/.codex/openai.config.toml"
    seed_file ${../home/agents/codex/bedrock.config.toml} "$HOME/.codex/bedrock.config.toml"
    seed_file ${../home/agents/codex/default.rules} "$HOME/.codex/rules/default.rules"
    seed_file ${../home/agents/codex/notify.sh} "$HOME/.codex/notify.sh" 0755
    seed_agent_skills_dir ${agentSkillsBundle} "$HOME/.codex/skills"

    seed_file ${kiroPowersJson} "$HOME/.kiro/powers.json"
    seed_file ${kiroPowersMcpJson} "$HOME/.kiro/powers.mcp.json"
    seed_file ${kiroCliJson} "$HOME/.kiro/settings/cli.json"
    seed_file ${kiroSettingsMcpJson} "$HOME/.kiro/settings/mcp.json"
    seed_file ${kiroPermissions} "$HOME/.kiro/settings/permissions.yaml"
    seed_file ${kiroCliThemeJson} "$HOME/.kiro/settings/kiro_cli_theme.json"
    seed_dir ${../home/agents/kiro/powers/stripe} "$HOME/.kiro/powers/stripe"
    seed_dir ${../home/agents/kiro/powers/cloud-architect} "$HOME/.kiro/powers/cloud-architect"
    seed_agent_skills_dir ${agentSkillsBundle} "$HOME/.kiro/skills"
  '';

  home.file = {
    ".local/bin/sync-codex-config" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        set -euo pipefail

        backup_root="$HOME/.codex/backups/manual-sync-$(date +%Y%m%d%H%M%S)"

        backup_path() {
          local path="$1"
          if [ -e "$path" ] || [ -L "$path" ]; then
            local rel="''${path#$HOME/.codex/}"
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

        sync_file ${../home/ai/AGENTS.md} "$HOME/.codex/AGENTS.md"
        sync_file ${../home/agents/codex/keybindings.json} "$HOME/.codex/keybindings.json"
        sync_file ${../home/agents/codex/config.toml} "$HOME/.codex/config.toml"
        sync_file ${../home/agents/codex/openai.config.toml} "$HOME/.codex/openai.config.toml"
        sync_file ${../home/agents/codex/bedrock.config.toml} "$HOME/.codex/bedrock.config.toml"
        sync_file ${../home/agents/codex/default.rules} "$HOME/.codex/rules/default.rules"
        sync_file ${../home/agents/codex/notify.sh} "$HOME/.codex/notify.sh" 0755
        sync_agent_skills_dir ${agentSkillsBundle} "$HOME/.codex/skills"

        echo "sync-codex-config: backup written to $backup_root"
      '';
    };

    ".local/bin/sync-kiro-config" = {
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
        sync_dir ${../home/agents/kiro/powers/stripe} "$HOME/.kiro/powers/stripe"
        sync_dir ${../home/agents/kiro/powers/cloud-architect} "$HOME/.kiro/powers/cloud-architect"
        sync_agent_skills_dir ${agentSkillsBundle} "$HOME/.kiro/skills"

        echo "sync-kiro-config: backup written to $backup_root"
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

        echo "==> updating agent-skills flake input"
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

        echo "==> committing updated flake.lock in $dotfiles_dir"
        if ! git -C "$dotfiles_dir" diff --quiet -- flake.lock; then
          git -C "$dotfiles_dir" add flake.lock
          git -C "$dotfiles_dir" commit -m "chore: update agent-skills flake input"
          git -C "$dotfiles_dir" push origin HEAD
        else
          echo "skills-push: flake.lock unchanged"
        fi
      '';
    };

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
          args = ["awslabs.aws-documentation-mcp-server@latest"];
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
        allow = ["Shell(ls)"];
        deny = [];
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
        aliases = ["auto"];
        maxMode = false;
      };
      hasChangedDefaultModel = true;
      maxMode = false;
      modelParameters.default = [];
      selectedModel = {
        modelId = "default";
        parameters = [];
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
  };
}
