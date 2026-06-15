{pkgs}:
with pkgs; let
  browserUseCommand = name:
    writeShellApplication {
      inherit name;
      runtimeInputs = [uv];
      text = ''
        export BROWSER_USE_CONFIG_DIR="''${BROWSER_USE_CONFIG_DIR:-$HOME/.browser-use-config}"
        export BROWSER_USE_SOCKET_MODE="''${BROWSER_USE_SOCKET_MODE:-tcp}"
        export PLAYWRIGHT_BROWSERS_PATH="''${PLAYWRIGHT_BROWSERS_PATH:-${playwright-driver.browsers}}"
        export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD="''${PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD:-1}"

        exec uvx --from 'browser-use[cli]==0.12.1' browser-use "$@"
      '';
    };
  browserUse = browserUseCommand "browser-use";
  browserUseLocal = browserUseCommand "browser-use-local";
  kiroCliFixed = kiro-cli.overrideAttrs (oldAttrs: {
    postInstall =
      (oldAttrs.postInstall or "")
      + ''
        for bin in kiro-cli kiro-cli-chat kiro-cli-term; do
          target="$out/Applications/Kiro CLI.app/Contents/MacOS/$bin"
          if [ -x "$target" ]; then
            rm -f "$out/bin/$bin"
            cat > "$out/bin/$bin" <<EOF
#!${runtimeShell}
exec "$target" "\$@"
EOF
            chmod +x "$out/bin/$bin"
          fi
        done
      '';
  });
in [
  awscli2
  azure-cli
  alejandra
  bat
  browserUse
  browserUseLocal
  claude-code
  cmake
  codex
  curl
  deadnix
  delta
  direnv
  eza
  fd
  fzf
  gh
  git
  gnumake
  gnupg
  google-cloud-sdk
  jq
  just
  kiroCliFixed
  kubectl
  macism
  mise
  neovim
  nix-output-monitor
  nixd
  nodejs_24
  pkg-config
  pnpm
  python313
  ripgrep
  sops
  shellcheck
  shfmt
  statix
  rustup
  tmux
  tree
  unzip
  uv
  wget
  yq-go
  zed-editor
  zoxide
  zstd
]
