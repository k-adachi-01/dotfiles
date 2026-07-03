# Cursor: still Nix store symlinks today (home.file.source). Migrating to
# the class A/B model is tracked as PR8 in docs/management-policy.md.
{
  config,
  pkgs,
  ...
}: let
  shared = import ./mcp.nix {inherit config pkgs;};
  inherit (shared) json;
in {
  home.file = {
    ".cursor/AGENTS.md".source = ../../home/ai/AGENTS.md;
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
