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
  opencodexSrc = fetchFromGitHub {
    owner = "lidge-jun";
    repo = "opencodex";
    tag = "v2.7.41";
    hash = "sha256-caQaXF7GRAjEU4cbTI8N8EyIxzZfaA5JklNIl7OzUWs=";
  };
  opencodexDeps = stdenvNoCC.mkDerivation {
    pname = "opencodex-deps";
    version = "2.7.41";
    src = opencodexSrc;

    nativeBuildInputs = [
      bun
      cacert
    ];

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall
      export HOME="$TMPDIR"
      bun install --frozen-lockfile --ignore-scripts
      mkdir -p "$out"
      cp -R node_modules "$out/"
      runHook postInstall
    '';

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-ib0LJ6RdQ+Z/Q26ssyazcGcFPg2IXM6RlxjUJc/d5zA=";
  };
  opencodex = stdenvNoCC.mkDerivation {
    pname = "opencodex";
    version = "2.7.41";
    src = opencodexSrc;

    nativeBuildInputs = [makeWrapper];

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall
      installDir="$out/libexec/opencodex"
      mkdir -p "$installDir" "$out/bin"
      cp -R . "$installDir/"
      cp -R ${opencodexDeps}/node_modules "$installDir/"
      makeWrapper ${bun}/bin/bun "$out/bin/ocx" \
        --add-flags "$installDir/src/cli/index.ts"
      ln -s ocx "$out/bin/opencodex"
      runHook postInstall
    '';

    meta = {
      description = "Universal provider proxy for OpenAI Codex and Claude Code";
      homepage = "https://opencodex.me/";
      license = lib.licenses.mit;
      mainProgram = "ocx";
      platforms = lib.platforms.darwin;
    };
  };
  devinCli = stdenvNoCC.mkDerivation rec {
    pname = "devin-cli";
    version = "3000.2.17";

    src = fetchurl (
      if system == "aarch64-darwin"
      then {
        url = "https://static.devin.ai/cli/${version}/devin-${version}-aarch64-apple-darwin.tar.gz";
        hash = "sha256-YOLt0yH1zV4c/fPW1eEgZPJTJsqONqitcfQ9AAdF3/g=";
      }
      else if system == "x86_64-darwin"
      then {
        url = "https://static.devin.ai/cli/${version}/devin-${version}-x86_64-apple-darwin.tar.gz";
        hash = "sha256-jU2dYnuTRImEQuFP/4cAOzdt2aGr9SQ3IgbxcnshzSg=";
      }
      else if system == "aarch64-linux"
      then {
        url = "https://static.devin.ai/cli/${version}/devin-${version}-aarch64-unknown-linux.tar.gz";
        hash = "sha256-EW3HHvCFqSK8P/DqA3fUsmxSmkMdWCRuNlcpE+LSViQ=";
      }
      else if system == "x86_64-linux"
      then {
        url = "https://static.devin.ai/cli/${version}/devin-${version}-x86_64-unknown-linux.tar.gz";
        hash = "sha256-8OHpNjr8buaMTvh7q0rrf/XMCKX6g4NQ7zzu/bsqK+I=";
      }
      else throw "devin-cli is unsupported on ${system}"
    );

    sourceRoot = ".";
    dontStrip = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 bin/devin "$out/bin/devin"
      if [ -d share ]; then
        cp -R share "$out/share"
      fi
      runHook postInstall
    '';

    meta = {
      description = "Devin CLI";
      homepage = "https://docs.devin.ai/work-with-devin/devin-cli";
      license = lib.licenses.unfree;
      mainProgram = "devin";
      platforms = ["aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux"];
    };
  };
  # Cursor Origin CLI (https://cursor.com/docs/origin/cli). Pin the public
  # stable artifact; `origin update` writes ~/.local/bin/origin and would
  # shadow this derivation. Bump version + hashes from the URLs baked into
  # https://downloads.cursor.com/origin/install.sh. Auth/config under
  # ~/.config/origin-cli/ stays unmanaged.
  originCli = stdenvNoCC.mkDerivation rec {
    pname = "origin-cli";
    version = "2026.08.15-22-58-04-922a05a";

    src = fetchurl (
      if system == "aarch64-darwin"
      then {
        url = "https://downloads.cursor.com/co/${version}/darwin-arm64/co.tar.gz";
        hash = "sha256-oiiss2K54STALTEyq3Tr1HBOvVvltHBj22OOkHg2xpw=";
      }
      else if system == "x86_64-darwin"
      then {
        url = "https://downloads.cursor.com/co/${version}/darwin-x64/co.tar.gz";
        hash = "sha256-hWRPsOMbglBOc03agtXCEv/tIwFtRDQv4pk3OdFblWs=";
      }
      else if system == "aarch64-linux"
      then {
        url = "https://downloads.cursor.com/co/${version}/linux-arm64/co.tar.gz";
        hash = "sha256-MVJkVbACszjff/vxothcqLUIMRhyhajRiM4qC24+I4o=";
      }
      else if system == "x86_64-linux"
      then {
        url = "https://downloads.cursor.com/co/${version}/linux-x64/co.tar.gz";
        hash = "sha256-bjsMF5MJmBVYYRZW9PCpl4OFgh/sLHP59k8l6Tj1roc=";
      }
      else throw "origin-cli is unsupported on ${system}"
    );

    sourceRoot = ".";
    dontStrip = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 origin "$out/bin/origin"
      runHook postInstall
    '';

    meta = {
      description = "Cursor Origin CLI";
      homepage = "https://cursor.com/docs/origin/cli";
      license = lib.licenses.unfree;
      mainProgram = "origin";
      platforms = ["aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux"];
    };
  };
  slackCli = stdenvNoCC.mkDerivation rec {
    pname = "slack-cli";
    version = "4.4.0";

    src = fetchurl (
      if system == "aarch64-darwin"
      then {
        url = "https://downloads.slack-edge.com/slack-cli/slack_cli_${version}_macOS_arm64.tar.gz";
        hash = "sha256-3ds0NC9ABZg0is5/XIb4Wv5dmWZghHIPliZp0SvEnU8=";
      }
      else if system == "x86_64-linux"
      then {
        url = "https://downloads.slack-edge.com/slack-cli/slack_cli_${version}_linux_64-bit.tar.gz";
        hash = "sha256-MV9tBy6D/mgWM3Ycrh5rGMSyb6oW0b9NibIedro9P6o=";
      }
      else throw "slack-cli is unsupported on ${system}"
    );

    sourceRoot = ".";
    dontStrip = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 bin/slack "$out/bin/slack"
      runHook postInstall
    '';

    meta = {
      description = "Official command-line interface for creating and managing Slack apps";
      homepage = "https://docs.slack.dev/tools/slack-cli/";
      license = lib.licenses.asl20;
      mainProgram = "slack";
      platforms = ["aarch64-darwin" "x86_64-linux"];
    };
  };
  kiroCliFixed = kiro-cli.overrideAttrs (oldAttrs: {
    version = "2.16.1";
    src = fetchurl {
      url = "https://prod.download.cli.kiro.dev/stable/2.16.1/Kiro%20CLI.dmg";
      hash = "sha256-X86c+dymp08MUpFRdqZCH1lI5pA4E6+QSAxrciyyDTI=";
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
    devinCli
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
    originCli
    openssl
    pkg-config
    pnpm
    python313
    procs
    ripgrep
    sd
    sops
    shellcheck
    shfmt
    slackCli
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
    (wrangler.override {nodejs = nodejs_22;})
    yq-go
    zoxide
    zstd
  ]
  ++ lib.optionals (!isDarwin) [
    obsidian
    slack
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
    opencodex
  ]
