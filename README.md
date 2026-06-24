# dotfiles

Personal macOS/WSL development environment managed with Nix.

This repository used to be a chezmoi source tree. The target state is now:

- `nix-darwin` manages macOS system settings.
- `nix-darwin` installs shared CLI tools from `nix/packages.nix`.
- `home-manager` manages user dotfiles, shell, git, editor, and AI-agent config.
- Homebrew is limited to GUI casks.
- `mise` is temporary and will be removed after active projects move to project-local `flake.nix`.
- Agent skills are managed as an immutable Nix flake input from `k-adachi-01/agent-skills`.

## Managed Files

| Path | Description |
|---|---|
| `flake.nix` | macOS flake entrypoint |
| `nix/` | nix-darwin and home-manager modules |
| `home/` | source files installed by home-manager |
| `home/agents/` | Codex rules and Kiro powers installed by home-manager |
| `home/editors/` | editor extension manifests derived from Windows |
| `windows/` | Windows-only fallback settings kept for handoff |
| `docs/macos-nix-migration.md` | migration runbook |

## AI Agent Configuration

`nix/agents.nix` is the single source of truth for Claude Code, Codex, Cursor, and Kiro user-level configuration.
`nix/editors.nix` manages VS Code, Cursor, Antigravity, and Antigravity IDE user settings on macOS.

Managed by Nix:

- `~/.agents/AGENTS.md`
- `~/.agents/skills`
- `~/.claude/AGENTS.md`
- `~/.claude/CLAUDE.md`
- `~/.claude/skills`
- `~/.claude/settings.json`
- `~/.claude/keybindings.json`
- `~/.claude/.mcp.json`
- `~/.claude/statusline.py`
- `~/.claude/notify-done.sh`
- `~/.codex/AGENTS.md`
- `~/.codex/config.toml`
- `~/.codex/openai.config.toml`
- `~/.codex/bedrock.config.toml`
- `~/.codex/keybindings.json`
- `~/.codex/rules/default.rules`
- `~/.codex/notify.sh`
- `~/.codex/skills/browser-use-local`
- `~/.codex/skills/vercel-react-best-practices`
- `~/.codex/skills/wezterm-config-sync`
- `~/.cursor/AGENTS.md`
- `~/.cursor/skills`
- `~/.cursor/cli-config.json`
- `~/.cursor/statusline.sh`
- `~/.kiro/powers.json`
- `~/.kiro/powers.mcp.json`
- `~/.kiro/settings/`
- `~/.kiro/skills/`
- `~/.kiro/powers/`

Editor settings managed by Nix on macOS:

- `~/Library/Application Support/Code/User/settings.json`
- `~/Library/Application Support/Cursor/User/settings.json`
- `~/Library/Application Support/Cursor/User/keybindings.json`
- `~/Library/Application Support/Antigravity/User/settings.json`
- `~/Library/Application Support/Antigravity/User/keybindings.json`
- `~/Library/Application Support/Antigravity IDE/User/settings.json`
- `~/Library/Application Support/Antigravity IDE/User/keybindings.json`

Windows-only settings preserved for handoff:

- `home/wezterm/windows.lua`
- `windows/terminal/settings.json`
- `windows/wsl/.wslconfig`

Not managed by Nix:

- auth files and credentials, including `~/.codex/auth.json`
- local session and prompt history, including `history.jsonl`, `session_index.jsonl`, `transcription-history.jsonl`, `sessions/`, and `shell_snapshots/`
- telemetry, cache, and state files, including `*.sqlite*`, `cache/`, `.tmp/`, `tmp/`, `models_cache.json`, and `installation_id`
- browser and computer-use runtime state, including `chrome-native-hosts*.json` and `computer-use/`
- tool-managed runtime plugins and system skills, such as Codex `.system` skills

Before pruning Codex runtime state, quit Codex first. Start with cache-only files such as `cache/`, `.tmp/`, `tmp/`, and `models_cache.json`; delete history or SQLite databases only when losing local history/state is intentional.

Update shared skills in the local `~/agent-skills` checkout. That repository is private and is consumed by this flake through a local path input.

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

After the first switch, start a new login shell once so `/run/current-system/sw/bin` is on `PATH`.

```bash
exec "$SHELL" -l
```

Then use:

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

## NixOS Agent Container

An isolated aarch64-linux NixOS configuration designed for running AI coding agents (Claude Code, Codex) on Apple Silicon via virtualization or containers. This profile is fully independent of the macOS darwin configuration and has no macOS-specific dependencies.

### Architecture

- Target: `aarch64-linux` NixOS system
- No dependency on macOS paths, agent-skills input, or GUI tools
- Secrets and credentials are not included; mount them at runtime
- Shares source dotfiles (AGENTS.md, CLAUDE.md, nvim config) with the macOS profile but uses a separate Nix module path

### Verification

```bash
# Check flake evaluates correctly
nix flake check

# Build the package set
nix build .#packages.aarch64-linux.agent-container-tools

# Enter the dev shell
nix develop .#agent-container

# Build the full NixOS system
nix build .#nixosConfigurations.agent-container-aarch64-linux.config.system.build.toplevel
```

### Home Manager Standalone Usage

The home-manager configuration at `nix/home-agent-container.nix` can also be used standalone on any aarch64-linux host with home-manager installed:

```bash
home-manager switch --flake .#adachi
```

### Future Direction

The NixOS configuration can be used to produce a container image or VM disk via `nixos-generators`, enabling reproducible agent execution environments that boot in seconds.

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
