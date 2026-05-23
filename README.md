# dotfiles

Personal dotfiles managed with [chezmoi](https://chezmoi.io).

## Managed files

| File | Description |
|---|---|
| `~/.bashrc` | Bash configuration |
| `~/.profile` | Login shell profile |
| `~/.gitconfig` | Git configuration |
| `~/.inputrc` | Readline (vi mode) |
| `~/.mise.toml` | mise tool versions |
| `~/.wezterm.lua` | WezTerm configuration |
| `~/.config/nvim/` | Neovim (LazyVim) configuration |
| `~/.claude/CLAUDE.md` | Claude Code config |
| `~/.claude/AGENTS.md` | Claude Code agents config |
| `flake.nix`, `nix/` | macOS Nix configuration |

## Setup

### Prerequisites

Install chezmoi:

```bash
# macOS
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"

# Linux / WSL
sh -c "$(curl -fsLS get.chezmoi.io)"
```

### Apply dotfiles

```bash
chezmoi init --apply k-adachi-01/dotfiles
```

### macOS Nix setup

This repository also contains the Apple Silicon macOS Nix configuration.
The target profile is `darwinConfigurations.macbook`.
For the full handoff runbook, see [`docs/macos-nix-migration.md`](docs/macos-nix-migration.md).

1. Install Nix with flakes enabled.
2. Apply dotfiles:

```bash
~/.local/bin/chezmoi init --apply k-adachi-01/dotfiles
```

3. Build and switch to the macOS profile for the first time:

```bash
nix run github:nix-darwin/nix-darwin/master#darwin-rebuild -- switch --flake ~/.local/share/chezmoi#macbook
```

After the first switch, use:

```bash
darwin-rebuild switch --flake ~/.local/share/chezmoi#macbook
```

The macOS profile uses:

- `nix-darwin` and `home-manager` for CLI tools, zsh, git, and development runtimes.
- Homebrew casks only for GUI applications: VS Code, WezTerm, and OrbStack.
- `mise` as a temporary migration tool while project-specific environments move to `flake.nix` and `nix develop`.

After switching, re-authenticate tools that store local credentials:

```bash
gh auth login
aws configure sso
gcloud auth login
az login
```

### mise migration

`mise` is intentionally still installed by Nix for the first macOS migration.
The target end state is to remove `mise` after active projects define their own Nix dev shells.

For each active project:

1. Add a project-local `flake.nix` with the required Node/Python/Rust tools.
2. Use `nix develop` or `direnv` + `nix-direnv` instead of `mise install`.
3. Remove the project's `.mise.toml` only after the Nix shell fully replaces it.
4. Remove `mise` from `nix/packages.nix` after all active projects are migrated.

## Daily workflow

```bash
# Edit via chezmoi (opens source file directly)
chezmoi edit ~/.bashrc

# Or edit the target file directly, then sync back to source
chezmoi re-add ~/.bashrc

# Check diff
chezmoi diff

# Apply source changes to target
chezmoi apply

# Commit and push
chezmoi cd
git add -A && git commit -m "update bashrc" && git push
```
