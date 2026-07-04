{
  lib,
  pkgs,
  inputs,
  username,
  ...
}: {
  imports = [
    inputs.agent-skills-nix.homeManagerModules.default
    inputs.nixvim.homeModules.nixvim
    ./agents
    ./editors.nix
    ./editors-zed.nix
    ./launchd.nix
    ./nixvim.nix
  ];

  home = {
    inherit username;
    homeDirectory = "/Users/${username}";
    stateVersion = "25.05";
    sessionVariables = {
      EDITOR = "nvim";
      PNPM_HOME = "$HOME/Library/pnpm";
    };
    sessionPath = [
      "$HOME/bin"
      "$HOME/.local/bin"
      "$PNPM_HOME"
    ];
    file =
      {
        ".inputrc".source = ../home/inputrc;
        ".mise.toml".source = ../home/mise.toml;
        ".zprofile".text = ''
          if [ -r /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
            . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
          elif [ -r /nix/var/nix/profiles/default/etc/profile.d/nix.sh ]; then
            . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
          fi

          if command -v kiro-cli >/dev/null 2>&1; then
            source <(SHELL=/bin/zsh kiro-cli init zsh pre)
          fi

          # Added by OrbStack: command-line tools and integration
          # This won't be added again if you remove it.
          source ~/.orbstack/shell/init.zsh 2>/dev/null || :
        '';
        ".wezterm.lua".source =
          if pkgs.stdenv.isDarwin
          then ../home/wezterm/darwin.lua
          else ../home/wezterm/linux.lua;
      }
      // lib.optionalAttrs (!pkgs.stdenv.isDarwin) {
        ".bashrc".source = ../home/bashrc;
        ".profile".source = ../home/profile;
      };
  };

  programs.home-manager.enable = true;

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

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      ca = "claude --enable-auto-mode";
      cc = "claude --permission-mode acceptEdits";
      cdx = "codex --sandbox workspace-write --ask-for-approval on-request";
      cdx-bedrock = "codex --profile bedrock --sandbox workspace-write --ask-for-approval on-request";
      kiro3 = "kiro-cli --v3";
      la = "ls -A";
      ll = "ls -alF";
    };
    initContent = ''
            if [ -r /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
              . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
            elif [ -r /nix/var/nix/profiles/default/etc/profile.d/nix.sh ]; then
              . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
            fi

            set -o vi
            setopt prompt_subst

            autoload -Uz vcs_info
            precmd() {
              vcs_info
              print -Pn "\e]2;%~\a"
            }

            zstyle ':vcs_info:git:*' formats ' on %b'
            PROMPT='%F{244}+-%f %F{114}%n%f%F{244}@%f%F{117}%m%f %F{244}in%f %B%F{117}%3~%f%b%F{221}''${vcs_info_msg_0_}%f
      %F{244}+-%f %F{114}%#%f '

            if command -v kiro-cli >/dev/null 2>&1; then
              source <(SHELL=/bin/zsh kiro-cli init zsh post | sed '/if \[ -z "''${Q_INLINE_OPT_IN_MIGRATION}" \]; then/,/^fi$/d')
            fi
    '';
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.tmux = {
    enable = true;
    clock24 = true;
    keyMode = "vi";
    mouse = true;
  };
}
