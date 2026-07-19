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

  pnpmHome =
    if pkgs.stdenv.isDarwin
    then "${homeDir}/Library/pnpm"
    else "${homeDir}/.local/share/pnpm";

  presentationMcpDir = "${homeDir}/talks/sample-spec-driven-presentation-maker/mcp-local";

  # Kiro "powers" MCP catalog. `_power` tags which power(s) each server
  # belongs to; it is intentionally passed straight through into
  # ~/.kiro/powers.mcp.json today (pre-existing behavior, unrelated to this
  # split — left as-is; revisit in the Kiro merge migration if it matters).
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

  # Generates ~/.kiro/settings/permissions.yaml allow-rules from Codex's
  # rules/default.rules. Cross-tool dependency is intentional: Codex's rule
  # syntax already encodes the shell-command allowlist we want Kiro to share.
  kiroPermissions =
    pkgs.runCommand "kiro-permissions.yaml" {
      nativeBuildInputs = [pkgs.ruby];
      src = ../../home/agents/codex/default.rules;
    } ''
      ruby <<'RUBY' > "$out"
      Encoding.default_external = Encoding::UTF_8
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
}
