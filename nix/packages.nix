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
  # The source-built package lacks the manifest/helpers required by the
  # default daemon startup since 0.157. Keep the official macOS bundle intact.
  codexCli =
    if isDarwin
    then
      stdenvNoCC.mkDerivation rec {
        pname = "codex";
        version = "0.159.2";
        src = fetchurl {
          url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-package-${stdenv.hostPlatform.rust.rustcTarget}.tar.gz";
          sha256 =
            {
              aarch64-darwin = "38aaf6dce63099fd10988948d03bbc6c0474253aef6961fcbe60f8d154b39101";
              x86_64-darwin = "6b9b38bfad6ac8019aa6a243ee3ab11d3e22889eafd5458b0344cf20e797e680";
            }.${
              system
            };
        };
        unpackPhase = ''
          runHook preUnpack
          mkdir source
          tar -xzf $src -C source
          cd source
          runHook postUnpack
        '';
        dontConfigure = true;
        dontBuild = true;
        dontFixup = true;
        installPhase = ''
          runHook preInstall
          mkdir -p $out/libexec/codex $out/bin
          cp -R . $out/libexec/codex/
          ln -s ../libexec/codex/bin/codex $out/bin/codex
          runHook postInstall
        '';
        doInstallCheck = true;
        installCheckPhase = ''
          runHook preInstallCheck
          test -f $out/libexec/codex/codex-package.json
          test -x $out/libexec/codex/bin/codex-code-mode-host
          test -x $out/libexec/codex/codex-path/rg
          $out/bin/codex --version | grep -F "codex-cli ${version}"
          runHook postInstallCheck
        '';
        meta =
          llmAgentsPkgs.codex.meta
          // {
            sourceProvenance = [lib.sourceTypes.binaryNativeCode];
            platforms = lib.platforms.darwin;
          };
      }
    else llmAgentsPkgs.codex;
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
  devinCli = stdenvNoCC.mkDerivation rec {
    pname = "devin-cli";
    version = "3000.11.3";

    src = fetchurl (
      if system == "aarch64-darwin"
      then {
        url = "https://static.devin.ai/cli/${version}/devin-${version}-aarch64-apple-darwin.tar.gz";
        hash = "sha256-wIzD81B9EDJGuMYBpYT8xxn9d/bMEPJsyQ6fQYZkDfI=";
      }
      else if system == "x86_64-darwin"
      then {
        url = "https://static.devin.ai/cli/${version}/devin-${version}-x86_64-apple-darwin.tar.gz";
        hash = "sha256-WU+JtrDQPf/sTqvHVBBORHHMQ6AUohZOL919DXUtAQA=";
      }
      else if system == "aarch64-linux"
      then {
        url = "https://static.devin.ai/cli/${version}/devin-${version}-aarch64-unknown-linux.tar.gz";
        hash = "sha256-IaLXqN6meYcGfN5+s/5xk6SNqo+MPVDUFMYDxKK2fxU=";
      }
      else if system == "x86_64-linux"
      then {
        url = "https://static.devin.ai/cli/${version}/devin-${version}-x86_64-unknown-linux.tar.gz";
        hash = "sha256-g7OxE8Ab8qPp4QDbCNd+awhoBqd1TwkeIIMb3+IVFX4=";
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
  bwsCli = stdenvNoCC.mkDerivation rec {
    pname = "bws";
    version = "2.1.0";

    src = fetchurl (
      if system == "aarch64-darwin"
      then {
        url = "https://github.com/bitwarden/sdk/releases/download/bws-v${version}/bws-aarch64-apple-darwin-${version}.zip";
        hash = "sha256-nLHBxuYWTYOy4zmIO6ArTLs3GIzppISxzoJJRDFj4GY=";
      }
      else if system == "x86_64-darwin"
      then {
        url = "https://github.com/bitwarden/sdk/releases/download/bws-v${version}/bws-x86_64-apple-darwin-${version}.zip";
        hash = "sha256-b2JrOXE2iQKvG5hHwCeRobRmaWnXVh4gR2gc3teZdTc=";
      }
      else if system == "aarch64-linux"
      then {
        url = "https://github.com/bitwarden/sdk/releases/download/bws-v${version}/bws-aarch64-unknown-linux-gnu-${version}.zip";
        hash = "sha256-GCU3VyhuEZ1FATOofrRjv4wc5BjOJMg09PJQ1gy6b54=";
      }
      else if system == "x86_64-linux"
      then {
        url = "https://github.com/bitwarden/sdk/releases/download/bws-v${version}/bws-x86_64-unknown-linux-gnu-${version}.zip";
        hash = "sha256-uoIzw6Su5dQ+PHO70E2Z6bxauhO7v9BtibBzq+cyuGA=";
      }
      else throw "bws is unsupported on ${system}"
    );

    nativeBuildInputs = [unzip];
    sourceRoot = ".";
    dontStrip = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 bws "$out/bin/bws"
      runHook postInstall
    '';

    meta = {
      description = "Bitwarden Secrets Manager CLI";
      homepage = "https://bitwarden.com/help/secrets-manager-cli/";
      license = lib.licenses.unfree;
      mainProgram = "bws";
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
  # Cloudflare's unified CLI (technical preview,
  # https://blog.cloudflare.com/cf-cli-local-explorer/). Not yet in nixpkgs,
  # so wrap the published npm tarball. The tarball ships a prebuilt dist/
  # but its devDependencies reference an unpublished vendor tarball, so they
  # are stripped and a prod-only lockfile is committed at
  # nix/pkgs/cf/pnpm-lock.yaml. fetchPnpmDeps is unusable: a dependency ships
  # a non-JSON .json file that breaks the fetcher's jq pass, so node_modules
  # is materialized by a fixed-output derivation instead. Bump: update
  # version + both hashes, then regenerate the lockfile from the unpacked
  # tarball after deleting devDependencies
  # (`pnpm install --lockfile-only --ignore-scripts`).
  cfCli = let
    version = "1.0.0-beta.12";
    src =
      runCommand "cf-${version}-src" {
        tarball = fetchurl {
          url = "https://registry.npmjs.org/cf/-/cf-${version}.tgz";
          hash = "sha256-LGaN+SuptzxQq1uElbwA71HzBk3en/cLPZwCyOTLMHY=";
        };
        nativeBuildInputs = [jq];
      } ''
        mkdir $out
        tar -xzf "$tarball" -C $out --strip-components=1
        chmod -R u+w $out
        jq 'del(.devDependencies)' $out/package.json > $out/package.json.new
        mv $out/package.json.new $out/package.json
        cp ${./pkgs/cf/pnpm-lock.yaml} $out/pnpm-lock.yaml
      '';
    nodeModules = stdenvNoCC.mkDerivation {
      name = "cf-${version}-node-modules";
      inherit src;
      nativeBuildInputs = [
        cacert
        nodejs
        pnpm
        writableTmpDirAsHomeHook
      ];
      outputHash = "sha256-oe1PIz2B80QnCBoKQWQXmebEwWglVyQdMQyVUTSDV3E=";
      outputHashAlgo = "sha256";
      outputHashMode = "recursive";
      # Skip fixup: patchShebangs would rewrite script shebangs to store
      # paths, which fixed-output derivations may not reference.
      dontFixup = true;
      installPhase = ''
        runHook preInstall
        export pnpm_config_pm_on_fail=ignore
        export pnpm_config_side_effects_cache=false
        export pnpm_config_update_notifier=false
        pnpm config set reporter append-only
        pnpm config set store-dir "$TMPDIR/pnpm-store"
        pnpm install --frozen-lockfile --ignore-scripts --prod
        # Normalize files embedding the build dir or timestamps so the
        # fixed-output hash is reproducible.
        rm -f node_modules/.modules.yaml node_modules/.pnpm-workspace-state-v1.json
        find node_modules \( -name '*.cmd' -o -name '*.ps1' \) -delete
        find node_modules -path '*/.bin/*' -type f -exec sed -i "s|$PWD|__PNPM_ROOT__|g" {} +
        mkdir $out
        cp -r node_modules $out/node_modules
        runHook postInstall
      '';
    };
  in
    stdenvNoCC.mkDerivation {
      pname = "cf";
      inherit version src;

      nativeBuildInputs = [
        makeWrapper
        nodejs
      ];

      dontConfigure = true;
      dontBuild = true;

      installPhase = ''
        runHook preInstall
        mkdir -p $out/lib/node_modules/cf
        cp -r bin dist package.json $out/lib/node_modules/cf/
        cp -r ${nodeModules}/node_modules $out/lib/node_modules/cf/node_modules
        makeWrapper ${lib.getExe nodejs} $out/bin/cf \
          --add-flags "$out/lib/node_modules/cf/bin/cf"
        ln -s cf $out/bin/cloudflare
        runHook postInstall
      '';

      meta = {
        description = "Cloudflare CLI - manage Cloudflare resources (technical preview)";
        homepage = "https://github.com/cloudflare/cf";
        license = lib.licenses.mit;
        mainProgram = "cf";
      };
    };
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
    bwsCli
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
    (lib.hiPrio slackCli)
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
    kiro-cli
    obsidian
    slack
  ]
  ++ lib.optionals enableLlmAgents [
    llmAgentsPkgs.agent-browser
    llmAgentsPkgs.claude-code
    codexCli
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
    # The node_modules FOD hash below is platform-specific (pnpm installs
    # optional deps for the build platform only). To support Linux, build
    # the FOD there and pick the hash per system.
    cfCli
    macismCliOnly
  ]
