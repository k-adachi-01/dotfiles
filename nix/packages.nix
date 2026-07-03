{pkgs}:
with pkgs; let
  playwrightCli = buildNpmPackage rec {
    pname = "playwright-cli";
    version = "0.1.14";

    src = fetchFromGitHub {
      owner = "microsoft";
      repo = "playwright-cli";
      rev = "9b118a1a737662fa118d591b5687340b86005d5c";
      hash = "sha256-wLE04sfPMh43IzIp6/HKBjloy3iSSanSYdYtklc6lQ4=";
    };

    npmDepsHash = "sha256-0bvwryiyPskay+h8+0RiOmnamHkmcRRK00q7ZEPdj1g=";
    dontNpmBuild = true;
    npmFlags = ["--ignore-scripts"];
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";

    meta = {
      description = "CLI for common Playwright actions";
      homepage = "https://github.com/microsoft/playwright-cli";
      license = lib.licenses.asl20;
      mainProgram = "playwright-cli";
    };
  };
  kiroCliFixed = kiro-cli.overrideAttrs (oldAttrs: {
    version = "2.8.1";
    src = fetchurl {
      url = "https://prod.download.cli.kiro.dev/stable/2.8.1/Kiro%20CLI.dmg";
      hash = "sha256-nN3GHnAdjgIplKgbPgtis4M1lRhyH5s8ilHMjKAuRJU=";
    };
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
  agent-browser
  bat
  claude-code
  cmake
  codex
  curl
  cursor-cli
  deadnix
  delta
  direnv
  eza
  fd
  fzf
  gh
  git
  gitleaks
  gnumake
  gnupg
  google-cloud-sdk
  jq
  just
  kiroCliFixed
  kubectl
  macism
  mise
  nix-output-monitor
  nixd
  nodejs_24
  pkg-config
  playwrightCli
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
