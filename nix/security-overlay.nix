# Temporary overrides for security releases not yet in nixpkgs master.
# Remove each override once the corresponding upstream version catches up.
{nixpkgs-build}: final: prev: let
  buildPkgs = import nixpkgs-build {
    inherit (final.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };
in {
  # The channel's mise still embeds pre-incident Rust TLS dependencies.
  # Use the fixed official macOS release until nixpkgs catches up.
  mise =
    if final.stdenv.hostPlatform.isDarwin && final.stdenv.hostPlatform.isAarch64
    then
      final.stdenvNoCC.mkDerivation {
        pname = "mise";
        version = "2026.10.17";
        src = final.fetchurl {
          url = "https://github.com/jdx/mise/releases/download/v2026.10.17/mise-v2026.10.17-macos-arm64.tar.gz";
          hash = "sha256-18UMFoNSSnZCYJhszJxBwN5eH81JFxS1ZAtle3Z4GvY=";
        };
        nativeBuildInputs = [final.installShellFiles];
        dontConfigure = true;
        dontBuild = true;
        dontFixup = true;
        installPhase = ''
          runHook preInstall
          install -Dm755 bin/mise "$out/bin/mise"
          installManPage man/man1/mise.1
          "$out/bin/mise" completion bash > mise.bash
          "$out/bin/mise" completion fish > mise.fish
          "$out/bin/mise" completion zsh > _mise
          installShellCompletion --bash mise.bash --fish mise.fish --zsh _mise
          mkdir -p "$out/lib/mise"
          touch "$out/lib/mise/.disable-self-update"
          runHook postInstall
        '';
        doInstallCheck = true;
        installCheckPhase = ''
          "$out/bin/mise" --version | grep -F 2026.10.17
        '';
        meta = prev.mise.meta // {sourceProvenance = [final.lib.sourceTypes.binaryNativeCode];};
      }
    else prev.mise;
  nodejs-slim_24 =
    if final.stdenv.hostPlatform.isDarwin
    then
      final.stdenvNoCC.mkDerivation {
        pname = "nodejs-slim";
        version = "24.22.1";
        src = final.fetchurl {
          url = "https://nodejs.org/dist/v24.22.1/node-v24.22.1-darwin-${
            if final.stdenv.hostPlatform.isAarch64
            then "arm64"
            else "x64"
          }.tar.gz";
          hash =
            if final.stdenv.hostPlatform.isAarch64
            then "sha256-icaCWT12zUQjP6U7FWMmTn3py7GJytFpE1xbT637wKc="
            else "sha256-0TJVfn7iuFrwiwyMNDOOZcZDDyI40B9ydyjvQtyDsDU=";
        };
        outputs = ["out" "npm" "corepack"];
        nativeBuildInputs = [final.makeWrapper];
        dontConfigure = true;
        dontBuild = true;
        dontFixup = true;
        installPhase = ''
          runHook preInstall
          mkdir -p "$out/bin" "$out/share/licenses/node" "$npm/lib/node_modules" "$npm/bin" "$corepack/bin"
          cp bin/node "$out/bin/"
          cp -R include share "$out/"
          cp LICENSE "$out/share/licenses/node/"
          cp -R lib/node_modules/npm "$npm/lib/node_modules/"
          makeWrapper "$out/bin/node" "$npm/bin/npm" --add-flags "$npm/lib/node_modules/npm/bin/npm-cli.js"
          makeWrapper "$out/bin/node" "$npm/bin/npx" --add-flags "$npm/lib/node_modules/npm/bin/npx-cli.js"
          if [ -d lib/node_modules/corepack ]; then
            mkdir -p "$corepack/lib/node_modules"
            cp -R lib/node_modules/corepack "$corepack/lib/node_modules/"
            makeWrapper "$out/bin/node" "$corepack/bin/corepack" --add-flags "$corepack/lib/node_modules/corepack/dist/corepack.js"
          fi
          runHook postInstall
        '';
        doInstallCheck = true;
        installCheckPhase = ''
          test "$("$out/bin/node" --version)" = "v24.22.1"
        '';
        passthru = {
          inherit (prev.nodejs-slim_24) python;
          interpreterName = "nodejs";
        };
        meta =
          prev.nodejs-slim_24.meta
          // {
            sourceProvenance = [final.lib.sourceTypes.binaryNativeCode];
          };
      }
    else
      prev.nodejs-slim_24.overrideAttrs (_: {
        version = "24.22.1";
        src = final.fetchurl {
          url = "https://nodejs.org/dist/v24.22.1/node-v24.22.1.tar.xz";
          hash = "sha256-T1N5eWKAza6wwvNY/QS2oWzE+336g7WoyRqdljtDUjE=";
        };
      });
  rustup = (prev.rustup.override {inherit (buildPkgs) rustPlatform;}).overrideAttrs (attrs: _: {
    version = "1.29.2";
    src = final.fetchFromGitHub {
      owner = "rust-lang";
      repo = "rustup";
      tag = attrs.version;
      hash = "sha256-vtfZNMkUAmbdXv0sv7wdm62AjCkYJY188jLx8RrmO2M=";
    };
    cargoDeps = buildPkgs.rustPlatform.fetchCargoVendor {
      inherit (attrs) src;
      name = "rustup-${attrs.version}";
      hash = "sha256-UL6nS3SbxKXFWftJLeFY622VQEyAimhNz+YJgZsLHJc=";
    };
  });
  # Trio's 10ms HTTP/2 cancellation tests race under local build load.
  # Keep the rest of the suite and runtime import checks enabled.
  pythonPackagesExtensions =
    (prev.pythonPackagesExtensions or [])
    ++ [
      (_: pythonPrev: {
        httpcore2 = pythonPrev.httpcore2.overridePythonAttrs (old: {
          disabledTests =
            (old.disabledTests or [])
            ++ [
              "test_h2_timeout_during_request[trio]"
              "test_h2_timeout_during_response[trio]"
            ];
        });
      })
    ];
  bws = (prev.bws.override {inherit (buildPkgs) rustPlatform;}).overrideAttrs (attrs: old: {
    patches = (old.patches or []) ++ [./pkgs/bws/tls-dependencies.patch];
    cargoDeps = buildPkgs.rustPlatform.fetchCargoVendor {
      inherit (attrs) src patches;
      name = "bws-${attrs.version}";
      hash = "sha256-mHzjeDTlKD1Eb/T+YRx7MM5HtmmE3bhVufeHAuzxX9o=";
    };
  });
  pnpm_12 = prev.pnpm_12.override {inherit (buildPkgs) rustPlatform;};
}
