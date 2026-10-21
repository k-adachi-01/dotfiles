# Temporary overrides for security releases not yet in nixpkgs master.
# Remove each override once the corresponding upstream version catches up.
final: prev: {
  nodejs_24 = prev.nodejs_24.overrideAttrs (_: {
    version = "24.22.1";
    src = final.fetchurl {
      url = "https://nodejs.org/dist/v24.22.1/node-v24.22.1.tar.xz";
      hash = "sha256-T1N5eWKAza6wwvNY/QS2oWzE+336g7WoyRqdljtDUjE=";
    };
  });
}
