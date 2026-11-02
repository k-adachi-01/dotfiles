# Herdr desktop

The desktop app is declared as the `herdr-app` Homebrew cask in
`nix/apps.nix`. Its terminal runtime, `herdr-core` (`hc`), is pinned to an
official release with SHA-256 verification in `nix/pkgs/herdr-core.nix` and
installed through `nix/packages.nix`.

Apply with:

```sh
sudo darwin-rebuild switch --flake ~/.config/nix-darwin#macbook
open -a Herdr
```

If the app asks where core is installed, choose **I have it somewhere…**
and select `/run/current-system/sw/bin/herdr-core`. On NixOS, select the
`herdr-core` executable from the Home Manager profile instead.

Create a space with Cmd+N. Open the command palette with Cmd+Shift+P.
The app's preferences and core's terminals, sockets, and machine profiles
are runtime state and are not tracked here.

The existing `herdr` TUI and its Ghostty integration remain separate from
the desktop app and its `hc` runtime. Update core by changing the pinned
version and hashes in Nix and rebuilding; keep package updates under Nix.
