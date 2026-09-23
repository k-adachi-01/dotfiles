# Shared plumbing and MCP/power definitions used by more than one agent
# config file. Values that are genuinely single-tool (e.g. Cursor's own
# .cursor/mcp.json server list) stay local to that tool's file instead of
# being forced in here.
{
  config,
  pkgs,
  ...
}: let
  homeDir = config.home.homeDirectory;
in rec {
  json = pkgs.formats.json {};
  yaml = pkgs.formats.yaml {};

  pnpmHome =
    if pkgs.stdenv.isDarwin
    then "${homeDir}/Library/pnpm"
    else "${homeDir}/.local/share/pnpm";

  presentationMcpDir = "${homeDir}/talks/sample-spec-driven-presentation-maker/mcp-local";

  # Linear's hosted MCP server uses OAuth 2.1 with dynamic client
  # registration. Keep the endpoint centralized; credentials stay in each
  # client's runtime auth store and never enter this public repository.
  linearMcpUrl = "https://mcp.linear.app/mcp";

  kiroCliJson = json.generate "kiro-cli.json" {
    "chat.defaultModel" = "auto";
  };

  kiroSettingsMcpJson = json.generate "kiro-settings-mcp.json" {
    mcpServers.linear = {
      type = "http";
      url = linearMcpUrl;
    };
    mcpServers.spec-driven-presentation-maker = {
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

  # Kiro is permissive by default: explicit deny rules protect only
  # destructive shell operations. Deny takes precedence over the catch-all
  # allow rule. sudo is denied except for darwin-rebuild switch and the
  # Nix store remount repair (needed when /nix is unmounted after reboot).
  kiroPermissions = yaml.generate "kiro-permissions.yaml" {
    rules = [
      {
        capability = "all";
        effect = "allow";
      }
      {
        capability = "shell";
        effect = "deny";
        match = [
          "rm -rf *"
          "rm -fr *"
          "/bin/rm -rf *"
          "/bin/rm -fr *"
          "git reset --hard*"
          "git clean -*f*"
          "git checkout -- *"
          "git restore *"
          "git branch -D *"
          "git push *--force*"
          "git push -f*"
        ];
      }
      {
        capability = "shell";
        effect = "deny";
        match = ["sudo *"];
        exclude = [
          "sudo darwin-rebuild switch --flake /Users/adachi/.config/nix-darwin#macbook"
          "sudo /Users/adachi/.config/nix-darwin/home/bin/nix-store-repair.sh"
          "sudo /Users/adachi/bin/nix-store-repair"
          "sudo /bin/bash /Users/adachi/.config/nix-darwin/home/bin/nix-store-repair.sh"
          "sudo /bin/bash /Users/adachi/bin/nix-store-repair"
          "sudo /usr/local/bin/determinate-nixd init"
        ];
      }
    ];
  };
}
