{
  lib,
  stdenvNoCC,
  nodejs,
  pnpm_10,
  fetchPnpmDeps,
  pnpmConfigHook,
  makeWrapper,
}: let
  # pnpm 11+ stores package manifests as *.json; this nixpkgs fetcher's
  # JSON sorting changes conditional export priority (default before node).
  pnpm = pnpm_10;
in
  stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "textlint-ai-ja";
    version = "1.0.0";
    src = ./.;

    pnpmDeps = fetchPnpmDeps {
      inherit (finalAttrs) pname version src;
      inherit pnpm;
      fetcherVersion = 4;
      hash = "sha256-Woc4objiVOgh2fh2oMQ3HxSLhKblmBnnv+yWsUhHu4c=";
    };
    nativeBuildInputs = [nodejs pnpm pnpmConfigHook makeWrapper];
    dontBuild = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib/textlint-ai-ja
      cp -r node_modules package.json textlintrc.json $out/lib/textlint-ai-ja/
      makeWrapper ${lib.getExe nodejs} $out/bin/textlint-ai-ja \
        --add-flags "$out/lib/textlint-ai-ja/node_modules/textlint/bin/textlint.js" \
        --add-flags "--config $out/lib/textlint-ai-ja/textlintrc.json"
      runHook postInstall
    '';

    meta = {
      description = "Check Japanese AI-style wording with textlint";
      homepage = "https://github.com/p1ass/textlint-rule-preset-ai-words-ja";
      license = lib.licenses.mit;
      mainProgram = "textlint-ai-ja";
    };
  })
