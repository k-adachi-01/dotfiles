{
  stdenvNoCC,
  fetchurl,
  lib,
}:
stdenvNoCC.mkDerivation rec {
  pname = "agent-desktop";
  version = "1.3.1";
  src = fetchurl {
    url = "https://github.com/vercel-labs/agent-desktop/releases/download/v${version}/agent-desktop-v${version}-aarch64-apple-darwin.tar.gz";
    hash = "sha256-m3t8/HSJLqtGwshdbLfcSGO/jasKIiz8+4rkYExpyGw=";
  };
  sourceRoot = ".";
  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;
  installPhase = ''
    runHook preInstall
    install -Dm755 agent-desktop $out/bin/agent-desktop
    install -Dm755 agent-desktop-macos-helper $out/bin/agent-desktop-macos-helper
    runHook postInstall
  '';
  meta = {
    description = "Desktop automation for AI agents";
    homepage = "https://github.com/vercel-labs/agent-desktop";
    license = lib.licenses.asl20;
    mainProgram = "agent-desktop";
    platforms = ["aarch64-darwin"];
    sourceProvenance = [lib.sourceTypes.binaryNativeCode];
  };
}
