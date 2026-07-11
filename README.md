# dotfiles

Personal macOS/WSL development environment managed with Nix.

This repository used to be a chezmoi source tree. The target state is now:

- `nix-darwin` manages macOS system settings.
- `nix-darwin` installs shared CLI tools from `nix/packages.nix`.
- `home-manager` manages user dotfiles, shell, git, editor, and AI-agent config.
- Homebrew is limited to GUI casks.
- `mise` is temporary and will be removed after active projects move to project-local `flake.nix`.
- Agent skills are consumed from a local checkout (`path:/Users/adachi/agent-skills` flake input). See [`docs/management-policy.md`](docs/management-policy.md) for details.

## Managed Files

| Path | Description |
|---|---|
| `flake.nix` | macOS flake entrypoint |
| `AGENTS.md` | guide for AI agents editing this repository (not the global AI config) |
| `nix/` | nix-darwin and home-manager modules |
| `nix/agents/` | Claude Code / Codex / Cursor / Kiro / MCP configuration (see below) |
| `home/` | source files installed by home-manager |
| `home/agents/` | class B asset sources (Codex/Claude/Cursor scripts and config, Kiro powers) installed by home-manager |
| `home/editors/` | editor extension manifests derived from Windows |
| `windows/` | Windows-only fallback settings kept for handoff |
| `docs/management-policy.md` | classification policy for Nix-managed / app-managed / local / secret files |
| `docs/macos-nix-migration.md` | migration runbook |
| `docs/nix-management-inventory.md` | detailed inventory of remaining Nix candidates and intentional exclusions |
| `docs/nix-migration-plan.md` | phased migration plan with per-step verification (companion to the inventory) |
| `docs/nix-migration-audit.md` | migration audit log (phase 0–2 findings) |
| `.gitleaks.toml` | secret-scanning config (extends gitleaks defaults, allowlists Nix SRI hashes) |
| `statix.toml` | statix lint config for this repo |
| `.github/workflows/ci.yml` | CI: lint (alejandra/statix/deadnix) + secret scan (gitleaks) on push/PR |

## AI Agent Configuration

`nix/agents/` is the single source of truth for Claude Code, Codex, Cursor, and Kiro user-level configuration (one file per tool, plus `lib.nix` for the merge helper and `mcp.nix` for shared definitions).
`nix/editors.nix` manages VS Code, Cursor, Antigravity, and Antigravity IDE user settings on macOS.

All four tools now share one management mechanism: class A files are deep-merged into the live file on every switch (declared keys always win, app-written keys the repo doesn't declare are preserved), and class B files are out-of-store symlinks to `home/agents/*` (edit the repo, no switch needed). The full classification and rationale are documented in [`docs/management-policy.md`](docs/management-policy.md). `~/.local/bin/agents-diff` shows, read-only, what the next switch would change per class A file and which live keys aren't declared in Nix yet (promotion candidates). The same class A merge mechanism is also used for the editor GUI `settings.json` files below (`nix/editors.nix`), so `agents-diff` covers those too.

Managed by Nix:

- `~/.agents/AGENTS.md`
- `~/.agents/skills` (dynamically populated from the enabled Agent Skills catalog; the exact skill set is not a fixed list in this file)
- `~/.claude/AGENTS.md` (out-of-store symlink)
- `~/.claude/CLAUDE.md` (out-of-store symlink)
- `~/.claude/skills` (same dynamic catalog as above)
- `~/.claude/settings.json` (deep-merged on every switch)
- `~/.claude/keybindings.json` (deep-merged on every switch)
- `~/.claude/.mcp.json` (deep-merged on every switch)
- `~/.claude/statusline.py` (out-of-store symlink to `home/agents/claude/statusline.py`)
- `~/.claude/notify-done.sh` (out-of-store symlink to `home/agents/claude/notify-done.sh`)
- `~/.codex/AGENTS.md` (out-of-store symlink to `home/ai/AGENTS.md`: edit the repo file, no switch needed)
- `~/.codex/config.toml` (deep-merged on every switch: declared keys in `home/agents/codex/config.toml` always win, keys Codex wrote itself like `[projects.*]` are preserved; see `docs/management-policy.md`)
- `~/.codex/openai.config.toml` (out-of-store symlink)
- `~/.codex/bedrock.config.toml` (out-of-store symlink)
- `~/.codex/keybindings.json` (out-of-store symlink)
- `~/.codex/rules/default.rules` (out-of-store symlink)
- `~/.codex/notify.sh` (out-of-store symlink)
- `~/.codex/skills/*` (always re-synced on switch, dynamic catalog)
- `~/.cursor/AGENTS.md` (out-of-store symlink)
- `~/.cursor/skills` (dynamic catalog)
- `~/.cursor/cli-config.json` (deep-merged on every switch: Cursor's own runtime state like `hasChangedDefaultModel`/`selectedModel` is preserved)
- `~/.cursor/mcp.json` (deep-merged on every switch)
- `~/.cursor/statusline.sh` (out-of-store symlink to `home/agents/cursor/statusline.sh`)
- `~/.kiro/powers.json` (deep-merged on every switch)
- `~/.kiro/powers.mcp.json` (deep-merged on every switch)
- `~/.kiro/settings/cli.json`, `settings/mcp.json`, `settings/kiro_cli_theme.json`, `settings/permissions.yaml` (deep-merged on every switch; `permissions.yaml` is generated from `home/agents/codex/default.rules`)
- `~/.kiro/skills/` (always re-synced on switch, dynamic catalog)
- `~/.kiro/powers/**` (individual files are out-of-store symlinks to `home/agents/kiro/powers/`; the `powers/` and `powers/<name>/` directories themselves stay real directories so Kiro can create its own `registries/` etc. alongside them)

None of the four tools need a manual re-sync script anymore (the old `sync-codex-config`/`sync-kiro-config` were removed): every `sudo darwin-rebuild switch` re-applies the merge/symlinks automatically. The merge only recurses into dicts/tables — a list-valued key (e.g. Kiro's `permissions.yaml` `rules` array) is replaced wholesale by the declared value, not merged element-by-element; see `docs/management-policy.md` for the reasoning and what to do if an app is observed appending to such a list at runtime.

Editor settings managed by Nix on macOS (`nix/editors.nix`, using the same class A merge helper as the AI agent configs above, added in PR10):

- `~/Library/Application Support/Code/User/settings.json` (deep-merged on every switch)
- `~/Library/Application Support/Cursor/User/settings.json` (deep-merged on every switch)
- `~/Library/Application Support/Cursor/User/keybindings.json` (generated file, not merged: its top level is a JSON array, and the merge helper only preserves undeclared keys inside dicts, so keeping it merge-based would silently drop any keybinding added through the GUI on the next switch)
- `~/Library/Application Support/Antigravity/User/settings.json` (deep-merged on every switch)
- `~/Library/Application Support/Antigravity/User/keybindings.json` (generated file, not merged; see Cursor keybindings.json note above)
- `~/Library/Application Support/Antigravity IDE/User/settings.json` (deep-merged on every switch)
- `~/Library/Application Support/Antigravity IDE/User/keybindings.json` (generated file, not merged; see Cursor keybindings.json note above)

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

Update shared skills in `~/agent-skills`, then run `~/.local/bin/skills-push "message"`. For manual edits, run `nix flake update agent-skills --flake ~/.config/nix-darwin` before `darwin-rebuild switch` (not `nix flake lock --update-input ... --flake`, which is invalid syntax).

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

3. Clone the Agent Skills repository (private; `gh auth login` must be done first if using `gh`):

```bash
gh repo clone k-adachi-01/agent-skills "$HOME/agent-skills"
```

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

### Overnight LLM Agent Build

The following command keeps the Mac awake, builds any missing
`llm-agents.nix` source packages with logs, and activates the configuration.
Run it from Terminal.app so the required `sudo` authentication is available:

```bash
"$HOME/.config/nix-darwin/scripts/apply-llm-agents-overnight"
```

## Continuous Integration

GitHub Actions (`.github/workflows/ci.yml`) runs on every push to `main` and every pull request: `alejandra --check`, `statix check`, `deadnix --fail`, and `gitleaks detect --config .gitleaks.toml`. It does not run `nix build`/`darwin-rebuild build`; run that locally before pushing (see [`AGENTS.md`](AGENTS.md)).

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
