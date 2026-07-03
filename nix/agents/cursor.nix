# Cursor: class A (merge) cli-config/mcp, class B (out-of-store link)
# everything it reads but never writes. See docs/management-policy.md.
{
  config,
  lib,
  pkgs,
  ...
}: let
  agentsLib = import ./lib.nix {inherit pkgs;};
  dotfilesRepo = "${config.home.homeDirectory}/.config/nix-darwin";
  mkLink = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesRepo}/${path}";

  mcpValue = {
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

  # Cursor writes runtime state (hasChangedDefaultModel, selectedModel, etc.)
  # into this same file, which is exactly why it's class A merge and not a
  # symlink: a read-only file here would make Cursor unable to persist its
  # own model selection.
  cliConfigValue = {
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

  backupDir = "$HOME/.cursor/backups";

  mcpEntry = {
    format = "json";
    value = mcpValue;
    dest = "$HOME/.cursor/mcp.json";
    label = "cursor-mcp";
  };
  cliConfigEntry = {
    format = "json";
    value = cliConfigValue;
    dest = "$HOME/.cursor/cli-config.json";
    label = "cursor-cli-config";
  };
in {
  dotfilesAgents.classAMerges = map agentsLib.mkDiffCommand [mcpEntry cliConfigEntry];

  home = {
    # Class A: see cliConfigValue comment above for why this can't be a
    # symlink. Merge-on-switch keeps declared keys durable without
    # clobbering Cursor's own runtime state. See nix/agents/lib.nix for the
    # dict-only merge caveat.
    activation.mergeCursorMcp = lib.hm.dag.entryAfter ["writeBoundary"] (
      agentsLib.mkMergeActivation (mcpEntry // {inherit backupDir;})
    );
    activation.mergeCursorCliConfig = lib.hm.dag.entryAfter ["writeBoundary"] (
      agentsLib.mkMergeActivation (cliConfigEntry // {inherit backupDir;})
    );

    # Class B: Cursor never writes to any of these, so a repo-editable
    # symlink is safe and gives "edit repo, effective immediately" without
    # a switch.
    file = {
      ".cursor/AGENTS.md".source = mkLink "home/ai/AGENTS.md";
      ".cursor/statusline.sh".source = mkLink "home/agents/cursor/statusline.sh";
    };
  };
}
