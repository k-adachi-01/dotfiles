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
# Edit a file
chezmoi edit ~/.bashrc

# Check diff after editing directly
chezmoi diff

# Apply changes
chezmoi apply

# Commit and push
chezmoi cd
git add -A && git commit -m "update bashrc" && git push
```
