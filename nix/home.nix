{
  pkgs,
  username,
  ...
}:

{
  home = {
    inherit username;
    homeDirectory = "/Users/${username}";
    stateVersion = "25.05";
    packages = import ./packages.nix { inherit pkgs; };
    sessionVariables = {
      EDITOR = "nvim";
      PNPM_HOME = "$HOME/Library/pnpm";
    };
    sessionPath = [
      "$HOME/bin"
      "$HOME/.local/bin"
      "$PNPM_HOME"
    ];
  };

  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    userName = "k-adachi-01";
    userEmail = "sewaniwa@gmail.com";
    extraConfig = {
      init.defaultBranch = "main";
      credential."https://github.com" = {
        helper = [
          ""
          "!gh auth git-credential"
        ];
      };
      credential."https://gist.github.com" = {
        helper = [
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
      cdx = "codex";
      la = "ls -A";
      ll = "ls -alF";
    };
    initContent = ''
      set -o vi

      autoload -Uz vcs_info
      precmd() {
        vcs_info
        print -Pn "\e]2;%~\a"
      }

      zstyle ':vcs_info:git:*' formats ' on %b'
      PROMPT='%F{244}+-%f %F{114}%n%f%F{244}@%f%F{117}%m%f %F{244}in%f %B%F{117}%3~%f%b%F{221}''${vcs_info_msg_0_}%f
%F{244}+-%f %F{114}%#%f '
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
