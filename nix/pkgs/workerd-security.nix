{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
}: let
  assets = {
    aarch64-darwin = {
      platform = "darwin-arm64";
      hash = "sha256-D/5QcLJJTa1GEhJT6SaBFbyUs3pp63KD06BfVDnBugY=";
    };
    aarch64-linux = {
      platform = "linux-arm64";
      hash = "sha256-MN76eBCnjKSGqu6T1p+2YnvEIMMxh3fJgtyK8YflmMA=";
    };
    x86_64-linux = {
      platform = "linux-64";
      hash = "sha256-O4t9m/TiX4yPT0eHXyt8aDZ/KyVPsxI1yQ/mFObKSqA=";
    };
  };
  asset = assets.${stdenv.hostPlatform.system};
in
  stdenvNoCC.mkDerivation rec {
    pname = "workerd-security";
    version = "1.20261021.1";
    src = fetchurl {
      url = "https://registry.npmjs.org/@cloudflare/workerd-${asset.platform}/-/workerd-${asset.platform}-${version}.tgz";
      inherit (asset) hash;
    };
    nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [autoPatchelfHook];
    buildInputs = lib.optionals stdenv.hostPlatform.isLinux [stdenv.cc.cc.lib];
    dontConfigure = true;
    dontBuild = true;
    dontFixup = stdenv.hostPlatform.isDarwin;
    installPhase = ''
      runHook preInstall
      install -Dm755 bin/workerd "$out/bin/workerd"
      runHook postInstall
    '';
    doInstallCheck = true;
    installCheckPhase = ''
      runHook preInstallCheck
      "$out/bin/workerd" --version | grep -F "2026-10-21"
      runHook postInstallCheck
    '';
    meta = {
      description = "Pinned workerd runtime with the webpki security update";
      homepage = "https://github.com/cloudflare/workerd/releases/tag/v1.20261021.1";
      license = lib.licenses.asl20;
      mainProgram = "workerd";
      platforms = builtins.attrNames assets;
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    };
  }
