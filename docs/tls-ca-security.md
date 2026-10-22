# TLS trust-store security updates

A macOS trust-service update does not automatically protect PEM-only curl,
OpenSSL, Python, Node, or software with embedded roots. Keep the TLS verifier,
its effective CA bundle, and statically linked dependencies in scope together.

## Managed configuration

- `flake.lock` pins the package sources. `nixpkgs` temporarily tracks `master`
  so urgent security fixes do not wait for unstable-channel promotion.
- `nix/security-overlay.nix` supplies releases not yet in the pinned nixpkgs:
  Node 24.22.1, rustup 1.29.2 and the tested Bun canary.
  Remove each override once the upstream package contains the same fix.
- On Apple Silicon, mise uses the checksum-pinned official 2026.10.17 release,
  which includes the CA fix. The older channel package embeds pre-fix Rust
  TLS dependencies. Its man page and shell completions are retained.
- Darwin Node uses the official binary with a pinned checksum. The Linux
  variant retains the nixpkgs source build. The separate build-toolchain input
  avoids rebuilding the Rust compiler for the targeted BWS/rustup/pnpm builds;
  it does not select their TLS dependencies.
- The Bun canary URL is mutable; its content hashes are pinned. A later asset
  replacement must fail the hash check rather than silently change the build.
  Replace it with a stable, immutable release as soon as the CA fix ships.
- `nix/darwin.nix` routes the legacy `/etc/ssl/cert.pem` path to the updated
  Mozilla PEM bundle. The initial Apple file is accepted only by its known hash.
  Existing custom trust files must be reviewed separately.
- Nix fetchers use the updated system bundle through `nix.custom.conf`.
- Home Manager exports `SSL_CERT_FILE` for OpenSSL clients whose independent
  default profile still refers to an older bundle. New shells receive it after
  activation; existing processes must be restarted.
- Nix's certifi package already uses the Nix CA bundle instead of its bundled
  upstream file. `NIX_SSL_CERT_FILE` selects the updated bundle for that patch,
  including Python clients built by an independently pinned flake input.
  Check the effective `certifi.where()` path, rather than its metadata version
  alone. Standalone uv tool environments still need the upstream certifi update.
- The pinned AWS CLI has nixpkgs' system-CA selection patch; confirm its
  botocore `where()` selects the updated bundle. The pinned Google Cloud SDK
  replaces its vendored PEM/text bundles with links to the same bundle.
  Explicit per-command CA settings still require separate review.
- Python MCP launchers constrain certifi to 2026.10.19 or later. Updating uv
  itself does not update every previously resolved Python environment.
  A shared uv override file replaces the AWS MCP proxy's exact old certifi
  pin; `--with` alone conflicts with that pin and prevents startup.
  Managed launchers reference the Nix uv executable directly. Cursor's pnpm
  launchers also put the fixed Node first in PATH, so a GUI application's
  inherited PATH cannot silently select an older runtime.
- BWS is built from its official source with the minimal Cargo.lock security
  update in `nix/pkgs/bws/tls-dependencies.patch`. Updating rustup cannot change
  dependencies embedded in a prebuilt BWS executable.
- agent-browser has its own Cargo.lock backport to webpki 0.103.16 and
  webpki-roots 1.0.10. Its browser engine and native HTTP client have separate
  certificate verification paths.
- Tealdeer and RTK also receive minimal Cargo.lock backports to those versions.
  A package-source update alone does not refresh a statically linked verifier.
- Cursor Agent bundles Node 26 separately. Replace that executable with the
  checksum-pinned official Node 26.12.1 and verify both CLI startup and its
  native SQLite addon. Updating the PATH's Node does not replace this copy.
- Pi is compiled with the fixed Bun package, so its standalone executable
  receives the updated runtime as well.
- Fabric 3 retains Invoke 2.2.1 because Invoke 3 is incompatible with it.
  This compatibility override does not replace the updated Python CA bundle.
- Herdr's build uses Zig 0.16, as required by its vendored libghostty-vt.
  Selecting the default Zig 0.17 fails before Herdr can be built.
- Hermes uses the fixed Node runtime. Its prompt-toolkit and Markdown metadata
  pins are relaxed for the patch releases in nixpkgs; upstream's import,
  wrapper, subprocess and CLI install checks remain enabled.
- DSH has a separate official Node binary because its loader inspects V8 code.
  Update its version and source hash independently of `nodejs_24`.
- CF and Wrangler set Miniflare's supported `MINIFLARE_WORKERD_PATH` override
  to the pinned workerd 1.20261021.1 binary. Its dependency update includes
  rustls-webpki 0.103.16. Their original lockfiles may still list an older
  bundled binary; inspect the executable selected by the wrapper as well.
  Test the Miniflare/runtime handshake after changing this override.
- CI obtains the nixpkgs revision from the lockfile without evaluating the local
  private skills input. Homebrew application upgrades remain explicit.
- The agent module uses Nix module merging to retain `home.file` declarations
  alongside conditional skill activation. A shallow attribute update at that
  level would silently discard the read-only `agents-diff` command.

## Verification

Use the real executable and its effective trust store. A version check is
necessary but does not establish which CA file the process loads.

```sh
curl https://dv-g3b-emudhra.we-have-a-problem.com/
curl https://dv-g3b-aaa-emudhra.we-have-a-problem.com/
curl https://example.com/
```

Both incident hosts must fail certificate verification; the normal control
must succeed. DNS failures, connection timeouts and HTTP errors are not proof
of distrust. Never disable certificate verification for this test.

The incident's public `chains.zip` provides twelve TLS chains, including the
Sectigo/AAA cross-signs. Test all of them with the actual bundle, hostname and
TLS-server purpose. A passing `openssl verify` result means that bundle still
trusts the affected chain. OpenSSL does not automatically perform fail-closed
revocation checking in this test.

Also inspect embedded roots and verifier versions in Rust/Go/Electron/Node
binaries. A browser's CRLSet/OneCRL or the macOS trust service cannot be assumed
to protect another TLS implementation in the same application. Container
rebuilds, newly pulled images, running containers and deployed cloud images
are distinct states; check the effective digest and verifier at each boundary.

## Compatibility and rollout

The updated Mozilla trust list can reject formerly valid chains through the
affected roots, including AAA cross-signs. Verify required services against the
new bundle before restarting long-running clients. Do not restore trust in an
affected issuer to work around a service failure; use a replacement server
chain that validates through an unaffected path.

GUI applications may bundle an older Electron or Rust verifier even when their
application updater reports the latest version. Updating the OS or the system
PEM bundle cannot establish that these embedded implementations are fixed.
Track the vendor release separately and test its actual network stack.

## Upstream references

- [Incident data and verification chains](https://emudhra.we-have-a-problem.com/)
- [Nixpkgs tracking](https://github.com/NixOS/nixpkgs/issues/576485)
- [Nix CA update](https://github.com/NixOS/nixpkgs/pull/576347)
- [Node 24.22.1](https://github.com/nodejs/node/releases/tag/v24.22.1)
- [Node 26.12.1](https://github.com/nodejs/node/releases/tag/v26.12.1)
- [rustup update](https://github.com/NixOS/nixpkgs/pull/576835)
- [mise 2026.10.17](https://github.com/jdx/mise/releases/tag/v2026.10.17)
- [AWS MCP proxy dependencies](https://github.com/aws/mcp-proxy-for-aws/blob/main/pyproject.toml)
- [rustls-webpki SPKI rejection](https://github.com/rustls/webpki/releases/tag/v/0.103.16)
- [Rust root-bundle update](https://github.com/rustls/webpki-roots/releases/tag/v/1.0.10)
- [Bun CA fix](https://github.com/oven-sh/bun/pull/46159)
- [workerd dependency update](https://github.com/cloudflare/workerd/pull/7829)
- [workerd 1.20261021.1](https://github.com/cloudflare/workerd/releases/tag/v1.20261021.1)
