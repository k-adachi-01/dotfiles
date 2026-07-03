# dotfiles

Personal macOS/WSL development environment managed with Nix.

This repository used to be a chezmoi source tree. The target state is now:

- `nix-darwin` manages macOS system settings.
- `nix-darwin` installs shared CLI tools from `nix/packages.nix`.
- `home-manager` manages user dotfiles, shell, git, editor, and AI-agent config.
- Homebrew is limited to GUI casks.
- `mise` is temporary and will be removed after active projects move to project-local `flake.nix`.
- Agent skills are consumed from the private `k-adachi-01/agent-skills` repository as a flake input. See [`docs/management-policy.md`](docs/management-policy.md) for the current input type and migration status.

## Managed Files

| Path | Description |
|---|---|
| `flake.nix` | macOS flake entrypoint |
| `AGENTS.md` | guide for AI agents editing this repository (not the global AI config) |
| `nix/` | nix-darwin and home-manager modules |
| `nix/agents/` | Claude Code / Codex / Cursor / Kiro / MCP configuration (see below) |
| `home/` | source files installed by home-manager |
| `home/agents/` | Codex config sources and Kiro powers installed by home-manager |
| `home/editors/` | editor extension manifests derived from Windows |
| `windows/` | Windows-only fallback settings kept for handoff |
| `docs/management-policy.md` | classification policy for Nix-managed / app-managed / local / secret files |
| `docs/macos-nix-migration.md` | migration runbook |

## AI Agent Configuration

`nix/agents.nix` is the single source of truth for Claude Code, Codex, Cursor, and Kiro user-level configuration.
`nix/editors.nix` manages VS Code, Cursor, Antigravity, and Antigravity IDE user settings on macOS.

The management mechanism differs per tool today (Nix store symlink for Claude/Cursor, seed-only activation for Codex/Kiro because those apps write back to their own config files). The full classification, rationale, and migration plan toward a unified model are documented in [`docs/management-policy.md`](docs/management-policy.md); do not assume all four tools behave the same way until that document says the migration is complete.

Managed by Nix:

- `~/.agents/AGENTS.md`
- `~/.agents/skills` (dynamically populated from the enabled Agent Skills catalog; the exact skill set is not a fixed list in this file)
- `~/.claude/AGENTS.md`
- `~/.claude/CLAUDE.md`
- `~/.claude/skills` (same dynamic catalog as above)
- `~/.claude/settings.json`
- `~/.claude/keybindings.json`
- `~/.claude/.mcp.json`
- `~/.claude/statusline.py`
- `~/.claude/notify-done.sh`
- `~/.codex/AGENTS.md` (seed-only: created if missing, not overwritten on later switches; see `docs/management-policy.md`)
- `~/.codex/config.toml` (seed-only)
- `~/.codex/openai.config.toml` (seed-only)
- `~/.codex/bedrock.config.toml` (seed-only)
- `~/.codex/keybindings.json` (seed-only)
- `~/.codex/rules/default.rules` (seed-only)
- `~/.codex/notify.sh` (seed-only)
- `~/.codex/skills/*` (seed-only, dynamic catalog)
- `~/.cursor/AGENTS.md`
- `~/.cursor/skills` (dynamic catalog)
- `~/.cursor/cli-config.json`
- `~/.cursor/statusline.sh`
- `~/.kiro/powers.json` (seed-only)
- `~/.kiro/powers.mcp.json` (seed-only)
- `~/.kiro/settings/` (seed-only)
- `~/.kiro/skills/` (seed-only, dynamic catalog)
- `~/.kiro/powers/` (seed-only)

"Seed-only" means `sudo darwin-rebuild switch` only creates the file if it does not already exist; it does not overwrite files the app has since modified. Run `~/.local/bin/sync-codex-config` or `~/.local/bin/sync-kiro-config` to explicitly re-apply the dotfiles source (a timestamped backup is written first).

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

Update shared skills in the local `~/agent-skills` checkout, then run `~/.local/bin/skills-push "message"` to publish, re-pin the flake input, and switch in one step. See [`docs/management-policy.md`](docs/management-policy.md) for how that repository is wired into this flake.

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

3. Authenticate GitHub so the private `agent-skills` flake input can be fetched over `git+https://`. `gh` is normally installed via `nix/packages.nix`, but on a brand-new Mac nothing has been switched yet, so run it ad hoc through `nix run` first:

```bash
nix run nixpkgs#gh -- auth login
```

Accept the prompt to authenticate Git with your GitHub credentials (or run `nix run nixpkgs#gh -- auth setup-git` afterward). Skip this step only if git is already configured with working GitHub HTTPS credentials by some other means.

4. Build and switch to the macOS profile for the first time.

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

## For AI Agents

If you are an AI coding agent editing this repository, read [`AGENTS.md`](AGENTS.md) first. It covers the source map, the required `sudo darwin-rebuild switch` command, and the AI agent configuration classification defined in `docs/management-policy.md`.
