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

## Setup

### Prerequisites

Install chezmoi:

```bash
# macOS
brew install chezmoi

# Linux / WSL
sh -c "$(curl -fsLS get.chezmoi.io)"
```

### Apply dotfiles

```bash
chezmoi init --apply k-adachi-01/dotfiles
```

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
