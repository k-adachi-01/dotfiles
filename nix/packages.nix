{pkgs}:
with pkgs; let
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
