# RustXNG: self-hosted metasearch engine used as Pi's first search route (K-373).
#
# Upstream publishes standalone release binaries; the source build is a full
# Rust workspace, so pin the published artifact and verify it against the
# release checksums instead. Bump `version` and every hash together.
{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  cacert,
}: let
  version = "0.27.1";
  base = "https://github.com/sahenjp/RustXNG/releases/download/v${version}";

  # x86_64-linux ships a static musl build; the others use the release artifact
  # for that target. Hashes are the published .sha256 sidecars.
  targets = {
    aarch64-darwin = {
      asset = "rustxng-v${version}-aarch64-apple-darwin";
      sha256 = "c4081bf48da9ff6d3b11024f3f150cc7d7fdfd93067b1ec838049c328918a2e2";
    };
    x86_64-darwin = {
      asset = "rustxng-v${version}-x86_64-apple-darwin";
      sha256 = "8236276317b7161af9e78aa779700bc094a999b061dce21c41cfa38d7c52f0c4";
    };
    aarch64-linux = {
      asset = "rustxng-v${version}-aarch64-unknown-linux-gnu";
      sha256 = "059376705bd8c2e91dc37f15f7752bdb8863b051bbd7d48e9497c5a29b28bcef";
    };
    x86_64-linux = {
      asset = "rustxng-v${version}-x86_64-unknown-linux-musl";
      sha256 = "d701cb636f7ba57b428228203152827e5a879fef5562b54e88cbcc80fb1b5919";
    };
  };

  target =
    targets.${stdenv.hostPlatform.system}
    or (throw "rustxng: no release artifact pinned for ${stdenv.hostPlatform.system}");
in
  stdenv.mkDerivation {
    pname = "rustxng";
    inherit version;

    src = fetchurl {
      url = "${base}/${target.asset}";
      inherit (target) sha256;
    };

    # The release bundles LICENSE and NOTICE next to the binary; keep them with
    # the installed copy (AGPL-3.0-or-later).
    license = fetchurl {
      url = "${base}/LICENSE";
      sha256 = "57c8ff33c9c0cfc3ef00e650a1cc910d7ee479a8bc509f6c9209a7c2a11399d6";
    };
    notice = fetchurl {
      url = "${base}/NOTICE";
      sha256 = "56bcb799330f38ca4f3c47541495a8b088504e379b15a22c20b7f6e886abe6ee";
    };

    dontUnpack = true;
    nativeBuildInputs = [makeWrapper];

    installPhase = ''
      runHook preInstall

      install -Dm755 "$src" "$out/bin/rustxng"
      install -Dm644 "$license" "$out/share/doc/rustxng/LICENSE"
      install -Dm644 "$notice" "$out/share/doc/rustxng/NOTICE"

      # Upstream reads providers from its bundled settings; keep the CA bundle
      # explicit so TLS to search providers does not depend on the caller's env.
      wrapProgram "$out/bin/rustxng" \
        --set-default SSL_CERT_FILE "${cacert}/etc/ssl/certs/ca-bundle.crt" \
        --set-default NIX_SSL_CERT_FILE "${cacert}/etc/ssl/certs/ca-bundle.crt"

      runHook postInstall
    '';

    meta = {
      description = "Self-hosted, SearXNG-compatible metasearch engine for local agents";
      homepage = "https://github.com/sahenjp/RustXNG";
      license = lib.licenses.agpl3Plus;
      mainProgram = "rustxng";
      platforms = builtins.attrNames targets;
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    };
  }
