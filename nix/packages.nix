{
  pkgs,
  inputs,
  system,
  enableLlmAgents ? pkgs.stdenv.isDarwin,
  enableSourceBuiltTools ? pkgs.stdenv.isDarwin,
}:
with pkgs; let
  inherit (stdenv) isDarwin;
  llmAgentsPkgs = inputs.llm-agents-nix.packages.${system};
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
    # Keep the app bundle in the Nix store so kiro-cli can resolve its bundled
    # resources, but move it out of /Applications so nix-darwin does not expose
    # it under /Applications/Nix Apps and trigger App Management prompts.
    postInstall =
      (oldAttrs.postInstall or "")
      + ''
                bundleDir="$out/libexec/Kiro CLI.app"
                mkdir -p "$out/libexec"
                mv "$out/Applications/Kiro CLI.app" "$bundleDir"
                rm -rf "$out/Applications"

        for bin in kiro-cli kiro-cli-chat kiro-cli-term; do
          appBin="$bundleDir/Contents/MacOS/$bin"
          if [ -x "$appBin" ]; then
            rm -f "$out/bin/$bin"
            printf '#!%s\nexec "%s" "$@"\n' "${runtimeShell}" "$appBin" > "$out/bin/$bin"
            chmod +x "$out/bin/$bin"
          fi
        done
      '';
  });
  macismCliOnly = macism.overrideAttrs (oldAttrs: {
    postInstall =
      (oldAttrs.postInstall or "")
      + ''
        rm -rf "$out/Applications"
      '';
  });
in
  [
    awscli2
    azure-cli
    alejandra
    bat
    bun
    cmake
    curl
    deadnix
    delta
    direnv
    bottom
    duf
    dust
    eza
    fd
    fzf
    gh
    git
    gitleaks
    gnumake
    gnupg
    google-cloud-sdk
    husky
    httpie
    hyperfine
    jq
    just
    kubectl
    nix-output-monitor
    nixd
    nodejs_24
    pkg-config
    pnpm
    python313
    procs
    ripgrep
    sd
    sops
    shellcheck
    shfmt
    starship
    statix
    tealdeer
    tokei
    rustup
    tmux
    tree
    unzip
    uv
    wget
    yq-go
    zoxide
    zstd
  ]
  ++ lib.optionals enableLlmAgents [
    llmAgentsPkgs.agent-browser
    llmAgentsPkgs.claude-code
    llmAgentsPkgs.codex
    llmAgentsPkgs.cursor-agent
    llmAgentsPkgs.grok
    llmAgentsPkgs.hunk
    llmAgentsPkgs.herdr
    llmAgentsPkgs.hermes-agent
    llmAgentsPkgs.rtk
  ]
  ++ lib.optionals enableSourceBuiltTools [
    mise
    playwrightCli
  ]
  ++ lib.optionals isDarwin [
    kiroCliFixed
    macismCliOnly
  ]
