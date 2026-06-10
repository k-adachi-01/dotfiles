{pkgs}:
with pkgs; let
  kiroFixed = kiro.overrideAttrs (oldAttrs: {
    nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [_7zz];
    unpackPhase = ''
      runHook preUnpack
      7zz x "$src"
      runHook postUnpack
    '';
    sourceRoot = "Kiro.app";
    postInstall =
      (oldAttrs.postInstall or "")
      + ''
        ln -s code "$out/Applications/Kiro.app/Contents/Resources/app/bin/kiro"
      '';
    dontFixup = true;
  });
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
  kiroFixed
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
