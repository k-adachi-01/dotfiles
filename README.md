# dotfiles

Personal macOS/WSL development environment managed with Nix.

This repository used to be a chezmoi source tree. The target state is now:

- `nix-darwin` manages macOS system settings.
- `home-manager` manages user dotfiles, CLI tools, shell, git, editor, and AI-agent config.
- Homebrew is limited to GUI casks.
- `mise` is temporary and will be removed after active projects move to project-local `flake.nix`.

## Managed Files

| Path | Description |
|---|---|
| `flake.nix` | macOS flake entrypoint |
| `nix/` | nix-darwin and home-manager modules |
| `home/` | source files installed by home-manager |
| `docs/macos-nix-migration.md` | migration runbook |

## macOS Bootstrap

1. Install Nix with flakes enabled.

```bash
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
```

2. Clone this repository.

```bash
mkdir -p "$HOME/.config"
git clone https://github.com/k-adachi-01/dotfiles.git "$HOME/.config/nix-darwin"
```

3. Build and switch to the macOS profile for the first time.

```bash
nix run github:nix-darwin/nix-darwin/master#darwin-rebuild -- switch --flake "$HOME/.config/nix-darwin#macbook"
```

After the first switch, use:

```bash
darwin-rebuild switch --flake "$HOME/.config/nix-darwin#macbook"
```

## Daily Workflow

```bash
cd "$HOME/.config/nix-darwin"

# Edit Nix modules or files under home/
$EDITOR nix/home.nix

# Apply changes
darwin-rebuild switch --flake "$HOME/.config/nix-darwin#macbook"

# Commit and push
git status
git add -A
git commit -m "update environment"
git push
```

## Authentication

Credentials and secrets are not stored in this repository. After switching on a new Mac, re-authenticate:

```bash
gh auth login
aws configure sso
gcloud auth login
az login
```

Do not commit:

- `.aws/`
- `.azure/`
- `.config/gcloud/`
- `.config/gh/hosts.yml`
- `.ssh/`
- `.gnupg/`
- `.env.keys`
- `DOTENV_PRIVATE_KEY*`

## Migration Notes

The full migration record, risks, and next actions are in:

```text
docs/macos-nix-migration.md
```
