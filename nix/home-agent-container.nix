{
  config,
  lib,
  pkgs,
  username,
  homeDirectory,
  ...
}:

{
  home = {
    inherit username homeDirectory;
    stateVersion = "25.05";
    sessionVariables = {
      EDITOR = "nvim";
    };
    sessionPath = [
      "$HOME/bin"
      "$HOME/.local/bin"
    ];
    file = {
      ".agents/AGENTS.md".source = ../home/ai/AGENTS.md;

      ".codex/AGENTS.md".source = ../home/ai/AGENTS.md;
      ".codex/config.toml".text = ''
        model = "gpt-5.5"
        model_reasoning_effort = "medium"
        personality = "pragmatic"

        notify = ["bash", "-c", "printf 'Codex: %s\\n' \"$1\"", "--"]
        approvals_reviewer = "user"

        [notice]
        hide_rate_limit_model_nudge = true
        fast_default_opt_out = true

        [projects."/home/${username}"]
        trust_level = "trusted"

        [tui]
        screen_reader_mode = true
        status_line = ["model-with-reasoning", "current-dir", "five-hour-limit", "weekly-limit", "context-remaining"]
        status_line_use_colors = true
      '';
      ".codex/openai.config.toml".source = ../home/agents/codex/openai.config.toml;
      ".codex/bedrock.config.toml".text = ''
        model = "openai.gpt-oss-120b"
        model_provider = "amazon-bedrock"
        model_reasoning_effort = "medium"

        [model_providers.amazon-bedrock.aws]
        region = "us-east-2"

        [projects."/home/${username}/.codex"]
        trust_level = "trusted"
      '';
      ".codex/keybindings.json".source = ../home/agents/codex/keybindings.json;
      ".codex/rules/default.rules".source = ../home/agents/codex/default.rules;
      ".codex/notify.sh" = {
        executable = true;
        text = ''
          #!/usr/bin/env bash
          set -euo pipefail

          payload=''${1:-{}}
          last_message=$(printf '%s' "$payload" | jq -r '.["last-assistant-message"] // "Codex task completed"')
          printf 'Codex: %s\n' "$last_message"
        '';
      };

      ".claude/AGENTS.md".source = ../home/ai/AGENTS.md;
      ".claude/CLAUDE.md".source = ../home/ai/CLAUDE.md;
    };
  };

  programs.home-manager.enable = true;

  programs.bash = {
    enable = true;
    shellAliases = {
      ca = "claude --enable-auto-mode";
      cc = "claude --permission-mode acceptEdits";
      cdx = "codex --sandbox workspace-write --ask-for-approval on-request";
    };
  };

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "k-adachi-01";
        email = "sewaniwa@gmail.com";
      };
      init.defaultBranch = "main";
      credential = {
        "https://github.com".helper = [
          ""
          "!gh auth git-credential"
        ];
        "https://gist.github.com".helper = [
          ""
          "!gh auth git-credential"
        ];
      };
    };
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
  };

  programs.tmux = {
    enable = true;
    clock24 = true;
    keyMode = "vi";
    mouse = true;
  };

  xdg.configFile."nvim" = {
    source = ../home/config/nvim;
    recursive = true;
  };
}
