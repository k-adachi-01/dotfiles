# Nix Management Inventory

Last updated: 2026-07-04

This document is a read-only inventory of what this Mac can reasonably put under Nix management, with the current state of this repository as the baseline.

It is intentionally split into three groups:

- Already managed by Nix in this repo
- Not yet managed, but a plausible Nix candidate
- Intentionally not managed

The goal is not to treat every file on the machine as a Nix target. The goal is to identify the remaining configuration surfaces that are still being edited by hand, by the app itself, or by project-specific tooling.

## Scope And Caveat

This inventory is based on:

- The repository modules under `nix/` and `home/`
- The policy in `docs/management-policy.md`
- A read-only filesystem scan of visible user paths on the current machine

Some macOS-protected directories report `Operation not permitted` in a normal shell scan. Those areas are acknowledged here where they are relevant, but not exhaustively enumerated.

## Already Managed By Nix

These are already in the repo and should remain the source of truth:

- System settings: `nix/darwin.nix`
- GUI apps via Homebrew casks: `nix/apps.nix`
- CLI packages: `nix/packages.nix`
- Shell, git, direnv, fzf, tmux: `nix/home.nix`
- Editor settings: `nix/editors.nix`
- AI agent settings and MCP wiring: `nix/agents/*`
- Shared source files for class B symlinks: `home/*`

From the current repository state, this includes:

- `~/.codex/config.toml`
- `~/.codex/AGENTS.md`
- `~/.codex/openai.config.toml`
- `~/.codex/bedrock.config.toml`
- `~/.codex/keybindings.json`
- `~/.codex/rules/default.rules`
- `~/.codex/notify.sh`
- `~/.claude/settings.json`
- `~/.claude/keybindings.json`
- `~/.claude/.mcp.json`
- `~/.claude/AGENTS.md`
- `~/.claude/CLAUDE.md`
- `~/.claude/statusline.py`
- `~/.claude/notify-done.sh`
- `~/.cursor/cli-config.json`
- `~/.cursor/mcp.json`
- `~/.cursor/AGENTS.md`
- `~/.cursor/statusline.sh`
- `~/.kiro/powers.json`
- `~/.kiro/powers.mcp.json`
- `~/.kiro/settings/cli.json`
- `~/.kiro/settings/mcp.json`
- `~/.kiro/settings/kiro_cli_theme.json`
- `~/.kiro/settings/permissions.yaml`
- `~/.kiro/powers/**`
- `~/Library/Application Support/Code/User/settings.json`
- `~/Library/Application Support/Cursor/User/settings.json`
- `~/Library/Application Support/Antigravity/User/settings.json`
- `~/Library/Application Support/Antigravity IDE/User/settings.json`

These paths are not candidates for further Nix work unless the management model itself changes.

## Nix Candidates Still Missing

This section is the actual backlog for “manage the whole Mac with Nix.”

The list is grouped by layer so it is easier to decide whether the next change belongs in `nix/darwin.nix`, `nix/home.nix`, `nix/apps.nix`, `nix/editors.nix`, or a new module.

### 1. macOS System Settings

`nix/darwin.nix` currently covers only:

- Dock autohide / recent apps
- Finder extensions / default view / path bar
- `NSGlobalDomain` extension display plus keyboard repeat

Everything else in macOS defaults is still open.

#### High-value macOS settings that are not yet declared

- Keyboard and input sources
- Trackpad and mouse behavior
- Menu bar and Control Center layout
- Mission Control and Spaces behavior
- Screensaver and lock screen behavior
- Accessibility defaults
- Sound / volume / input-output defaults
- Battery / power / sleep defaults
- Time Machine defaults
- Software Update policy
- Spotlight indexing behavior
- Safari defaults
- Terminal.app preferences
- WindowManager defaults
- Login item and launch-on-login behavior
- Notification defaults
- Wallpaper / screen saver presentation
- Bluetooth preferences

#### Observed preference domains not mapped in `nix/darwin.nix`

The following files exist in `~/Library/Preferences` and represent settings surfaces that could be managed if you want to go deeper into macOS defaults:

- `com.apple.ActivityMonitor.plist`
- `com.apple.AppleMultitouchMouse.plist`
- `com.apple.AppleMultitouchTrackpad.plist`
- `com.apple.Accessibility.plist`
- `com.apple.Keyboard-Settings.extension.plist`
- `com.apple.Terminal.plist`
- `com.apple.WindowManager.plist`
- `com.apple.bluetooth.plist`
- `com.apple.controlcenter.plist`
- `com.apple.dock.plist`
- `com.apple.finder.plist`
- `com.apple.SoftwareUpdate.plist`
- `com.apple.Spotlight.plist`
- `com.apple.Siri.plist`
- `com.apple.TTY.plist`
- `com.apple.TextInputMenu.plist`

There are many more Apple-owned plist files in `~/Library/Preferences`, but most of them are system data rather than settings worth declaratively controlling. The ones above are the practical candidates.

### 2. Launch Agents / Startup Jobs

This repo does not yet declare launchd jobs.

Observed launch agent files:

- `~/Library/LaunchAgents/com.google.GoogleUpdater.wake.plist`
- `~/Library/LaunchAgents/com.google.keystone.agent.plist`
- `~/Library/LaunchAgents/com.google.keystone.xpcservice.plist`
- `~/Library/LaunchAgents/com.amazon.codewhisperer.launcher.plist`

These are not good candidates for direct hand editing, but they are valid Nix targets if you decide to standardize startup jobs and helper daemons.

### 3. GUI App Configuration Surfaces

The repo installs GUI apps with Homebrew casks, but most app-specific settings are still outside Nix.

#### Apps that already have visible local config but are not Nix-managed yet

- `~/Library/Application Support/Bitwarden`
- `~/Library/Application Support/Google`
- `~/Library/Application Support/Slack`
- `~/Library/Application Support/Obsidian`
- `~/Library/Application Support/Raycast`
- `~/Library/Application Support/Zed`
- `~/Library/Application Support/Aqua Voice`
- `~/Library/Application Support/OpenAI`
- `~/Library/Application Support/Codex`
- `~/Library/Application Support/Cursor`
- `~/Library/Application Support/Kiro`
- `~/Library/Application Support/Antigravity`
- `~/Library/Application Support/Antigravity IDE`
- `~/Library/Application Support/draw.io`
- `~/Library/Application Support/FastMCP`
- `~/Library/Application Support/com.raycast.macos`
- `~/Library/Application Support/com.raycast.shared`
- `~/Library/Application Support/com.openai.codex`
- `~/Library/Application Support/com.vercel.cli`

#### Specific app files that are visible and could be candidates

- `~/.config/zed/settings.json`
- `~/.slack/config.json`
- `~/.docker/config.json`
- `~/.iam-policy-autopilot/config.json`
- `~/.codex/computer-use/config.json`

Notes:

- `~/.docker/config.json` often contains credentials and should be treated as sensitive even if part of the file is configuration.
- `~/.codex/computer-use/config.json` is app/runtime state, not a stable declarative target.
- `~/.slack/config.json` and `~/.iam-policy-autopilot/config.json` may be worth review if you want to fully control app behavior, but they are not yet wired into the repo.

### 4. Shell / Dotfile Gaps

Most shell basics are already in `nix/home.nix`, but these surfaces are still only partially modeled or remain local-state driven:

- `~/.zsh_sessions`
- `~/.zsh_history`
- `~/.bash_history`
- `~/.zcompdump*`
- `~/.nix-profile`
- `~/.nix-defexpr`
- `~/.local/bin` runtime scripts that are not part of the repo
- `~/.cargo/env`
- `~/.rustup`
- `~/.npm`
- `~/.cache`

Some of these are inherently runtime state and should stay out of Git, but the distinction between “configured by Nix” and “generated by the tool” should be kept explicit.

### 5. Developer Tool State That Could Be Split Further

These directories were observed and are at least partially configurable, even though they are not declared as Nix-managed targets today:

- `~/.agent-browser`
- `~/.browser-use-config`
- `~/.blocks`
- `~/.cdk`
- `~/.docker`
- `~/.iam-policy-autopilot`
- `~/.semantic_search`
- `~/.vscode`
- `~/.vscode-shared`
- `~/.orbstack`
- `~/.local/share/nvim/mason`

Some of these are mostly cache or runtime data. Some may have a separable config file hidden inside. The practical path is to decide per tool whether you want:

- A declarative config file in `home/`
- A generated config in `nix/`
- Or a runtime directory that stays outside Nix

### 6. Project-Local Environment Manifests Still Outside This Repo

These are not dotfiles in the narrow sense, but they are still part of the “everything on the machine should be reproducible” goal.

#### `mise` manifests still present

- `/Users/adachi/.mise.toml`
- `/Users/adachi/articles/.mise.toml`
- `/Users/adachi/blog/tech-blog-writing/.mise.toml`
- `/Users/adachi/src/260329_kiro-powers-to-cli/.mise.toml`
- `/Users/adachi/src/260404_cdk-insights/.mise.toml`
- `/Users/adachi/src/260404_elsa-speak/.mise.toml`
- `/Users/adachi/src/260425_ai-tuber/.mise.toml`
- `/Users/adachi/src/cdk-agent-lab/.mise.toml`
- `/Users/adachi/src/cdk-validations/.mise.toml`
- `/Users/adachi/talks/slidev/.mise.toml`

#### `package.json` manifests still present

- `/Users/adachi/articles/package.json`
- `/Users/adachi/blog/tech-blog-writing/package.json`
- `/Users/adachi/package.json`
- `/Users/adachi/sample-spec-driven-presentation-maker/infra/package.json`
- `/Users/adachi/sample-spec-driven-presentation-maker/web-ui/package.json`
- `/Users/adachi/src/260223_ai-dlc-kiro/package.json`
- `/Users/adachi/src/260301_vercel-chat/package.json`
- `/Users/adachi/src/260329_kiro-powers-to-cli/package.json`
- `/Users/adachi/src/260404_cdk-insights/package.json`
- `/Users/adachi/src/260404_elsa-speak/package.json`
- `/Users/adachi/src/260425_ai-tuber/package.json`
- `/Users/adachi/src/app_img-uploader-v2/package.json`
- `/Users/adachi/src/app_img-uploader-v3/package.json`
- `/Users/adachi/src/cdk-validations/package.json`
- `/Users/adachi/talks/slidev/package.json`
- `/Users/adachi/tmp/everything-claude-code/package.json`

#### `pyproject.toml` manifests still present

- `/Users/adachi/.aws-sam/aws-sam-cli-app-templates/pyproject.toml`
- `/Users/adachi/sample-spec-driven-presentation-maker/mcp-local/pyproject.toml`
- `/Users/adachi/sample-spec-driven-presentation-maker/mcp-server/pyproject.toml`
- `/Users/adachi/sample-spec-driven-presentation-maker/pyproject.toml`
- `/Users/adachi/sample-spec-driven-presentation-maker/skill/pyproject.toml`
- `/Users/adachi/src/260110_tddbc/pyproject.toml`
- `/Users/adachi/src/aws-sam-cli-app-templates/pyproject.toml`
- `/Users/adachi/talks/sample-spec-driven-presentation-maker/pyproject.toml`

These belong in the project repositories themselves, not in the dotfiles repo. They are still part of the broader “all of this PC under Nix” migration because each of them can eventually become a project-local `flake.nix`.

## Intentionally Not Managed

These should remain out of Nix because they are secrets, auth state, ephemeral caches, or OS-specific runtime data.

### Secrets And Authentication

- `~/.aws`
- `~/.azure`
- `~/.config/gcloud`
- `~/.config/gh/hosts.yml`
- `~/.ssh`
- `~/.gnupg`
- `~/.codex/auth.json`
- `~/.claude/.credentials.json`
- `~/.config/cursor/auth.json`
- `DOTENV_PRIVATE_KEY*`

### Runtime State And Cache

- `~/.codex/history.jsonl`
- `~/.codex/sessions/`
- `~/.codex/cache/`
- `~/.codex/*.sqlite*`
- `~/.claude/projects/`
- `~/.claude/sessions/`
- `~/.claude/cache/`
- `~/.claude/statsig/`
- `~/.cursor/chats/`
- `~/.cursor/projects/`
- `~/.cursor/worktrees/`
- `~/.kiro/sessions/`
- `~/.kiro/logs/`
- `~/.kiro/.cli_bash_history`
- `~/.kiro/settings/feed_state.json`
- `~/.kiro/settings/survey_state.json`
- `~/.cache`
- `~/.npm`
- `~/.rustup`
- `~/.cargo`
- `~/Library/Application Support/*/Cache`
- `~/Library/Caches`

### Windows / WSL Artifacts

These are preserved for fallback, but they are not part of the macOS Nix target:

- `windows/terminal/settings.json`
- `home/wezterm/windows.lua`
- `/mnt/c` references
- Windows-specific helper binaries and aliases

## Practical Next Step Map

If the goal is “everything that can be managed should be managed,” the remaining work should be tackled in this order:

1. Finish the macOS defaults inventory in `nix/darwin.nix`.
2. Add launchd jobs if any helper needs to survive login sessions.
3. Decide whether each app config directory is worth declarative control or should remain runtime state.
4. Migrate the biggest remaining local tool configs into `home/`.
5. Push project-local `flake.nix` files into the active repos listed above.

The main constraint is not technical ability. It is classification discipline:

- declarative and stable -> Nix
- app-managed but structurally safe -> merge or generated config
- secret or ephemeral -> leave out

