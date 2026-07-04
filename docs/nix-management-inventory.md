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

### Evaluation Criteria

Use these criteria to decide whether a candidate should actually be moved into Nix:

- Effect: how much reproducibility or day-to-day reliability improves after managing it.
- Blast radius: how much can break if the declared value is wrong.
- App-write risk: whether the application writes the same file at runtime.
- Secret risk: whether credentials, machine identifiers, history, or local project names can leak into the public repo.
- Maintenance cost: whether the setting is stable enough to keep declarative without frequent churn.

Priority summary:

| Area | Effect | Main risk | Recommended priority |
|---|---|---|---|
| Shell / dotfile boundaries | High | accidentally managing generated state | High |
| Developer tool config split | High | secrets and runtime state mixed with config | High |
| macOS system settings | Medium to high | incorrect defaults can affect daily input/window behavior | Medium-high |
| GUI app settings | Low to medium | app overwrites or stores private state | Selective only |
| Launch agents | Low to medium | fighting vendor-managed helper jobs | Low |
| Project-local manifests under `~/src` | Variable | effort spread across low-use test repos | Low unless the repo is active |

### 1. macOS System Settings

`nix/darwin.nix` currently covers only:

- Dock autohide / recent apps
- Finder extensions / default view / path bar
- `NSGlobalDomain` extension display plus keyboard repeat

Everything else in macOS defaults is still open.

Effect:

- Medium to high. These settings affect a new-machine restore more than most app preferences.
- Highest effect is in input behavior, keyboard repeat, trackpad, Mission Control, lock/sleep behavior, and Finder/Dock defaults.
- Low effect settings are cosmetic or frequently changed through System Settings UI.

Risks:

- Medium blast radius. A bad input source, modifier key, trackpad, or Mission Control setting can make the machine unpleasant to use immediately after switch.
- Some defaults are undocumented or change across macOS releases.
- Some values are better represented by nix-darwin options, while others require `defaults` writes. Prefer typed nix-darwin options where available.

Recommended handling:

- Add only settings that are stable personal preferences or required for daily work.
- Start with keyboard, trackpad, Mission Control, lock/sleep, Finder/Dock, and screenshot defaults.
- Avoid declaring large Apple plist files wholesale. Declare individual defaults.

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

Effect:

- Low to medium. Most observed jobs are vendor-managed updaters or helpers and do not improve reproducibility much when copied into Nix.
- Higher effect only applies to user-authored jobs, custom background scripts, or jobs that must be guaranteed on every machine.

Risks:

- Medium. Vendor launch agents may be updated by the app installer. Re-declaring them can fight the application or pin stale helper paths.
- Some jobs contain app-version-specific paths.

Recommended handling:

- Do not Nix-manage observed vendor jobs by default.
- Use home-manager `launchd.agents` only for user-owned jobs that are intentionally part of the environment.

### 3. GUI App Configuration Surfaces

The repo installs GUI apps with Homebrew casks, but most app-specific settings are still outside Nix.

Effect:

- Low to medium. App settings can improve a new-machine restore, but many GUI apps already sync through their own account or write state continuously.
- Highest effect candidates are plain JSON/TOML/YAML config files with stable schemas, such as editor-like tools.

Risks:

- High app-write risk. Many apps rewrite preferences on quit, version upgrade, login, or UI changes.
- High secret risk for apps that include account state, workspace paths, telemetry IDs, tokens, or local project names.
- Symlinking app-writable settings can break saves or cause the app to write runtime state directly into the repo.

Recommended handling:

- Treat this as selective work, not a bulk migration.
- Use the existing class A merge model for app-writable JSON/TOML/YAML only when the schema is stable and secrets can be excluded.
- Use class B symlinks only for files the app reads but does not write.
- Leave account-backed, binary, SQLite, cache-heavy, or plist-heavy app state unmanaged.
- Good first candidates: `~/.config/zed/settings.json`, maybe selected Raycast config if it is plain non-secret JSON.
- Poor first candidates: Chrome, Slack, Bitwarden, Obsidian vault internals, Docker auth-bearing files, and Codex computer-use runtime config.

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

Effect:

- High. Shell and dotfile boundaries affect every terminal session and are easy to verify after switch.
- Cleaning this area reduces hidden dependency on ad hoc PATH entries and tool installer side effects.

Risks:

- Low to medium if changes are scoped to declarations.
- High if generated history, caches, or tool-managed directories are accidentally made declarative.

Recommended handling:

- Keep history and generated completion caches unmanaged: `~/.zsh_history`, `~/.zsh_sessions`, `~/.bash_history`, `~/.zcompdump*`.
- Keep Nix profile implementation paths unmanaged: `~/.nix-profile`, `~/.nix-defexpr`.
- Split `~/.local/bin` into repo-owned scripts versus tool-installed binaries. Repo-owned scripts should be generated by home-manager; tool-installed binaries should stay tool-managed or move to `nix/packages.nix`.
- Remove or gate ad hoc shell integration from `.zprofile` when an app can provide a stable Nix/home-manager equivalent.
- Keep `~/.cargo`, `~/.rustup`, `~/.npm`, and `~/.cache` unmanaged as runtime state unless a specific config file inside them is proven safe.

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

Effect:

- High when the tool is part of daily development or agent workflows.
- Medium when the directory only stores cache, logs, generated indexes, or one-off experiment state.
- Low for tools that are only used inside throwaway validation projects.

Risks:

- High secret risk for Docker, cloud tooling, agent tools, browser automation profiles, and any directory containing tokens or account identifiers.
- High churn risk for tools that store logs, browser profiles, embeddings, model caches, SQLite databases, or generated indexes beside config files.
- Medium app-write risk for tools that rewrite config files on every launch.

Recommended handling by path:

| Path | Effect | Risk | Recommendation |
|---|---|---|---|
| `~/.config/zed/settings.json` | Medium | Medium app-write risk | Candidate for class A merge after inspecting keys |
| `~/.browser-use-config` | Medium | High profile/cache risk | Split config from browser profiles; do not manage profiles |
| `~/.agent-browser` | Medium | High cache/profile risk | Inspect first; likely manage only stable config, if any |
| `~/.orbstack/config` | Medium-high | Medium, affects containers | Candidate if plain config; keep VM state unmanaged |
| `~/.docker` | Medium | High secret risk | Do not manage whole directory; avoid `config.json` unless auth is excluded |
| `~/.cdk` | Low-medium | Cache/account context risk | Usually leave unmanaged; project CDK config belongs in projects |
| `~/.blocks` | Unknown | Unknown | Inspect before deciding; likely project/runtime state |
| `~/.iam-policy-autopilot` | Unknown | Possible account/local state | Inspect before deciding |
| `~/.semantic_search` | Low | Generated model/index state | Leave unmanaged unless a stable config file exists |
| `~/.vscode` / `~/.vscode-shared` | Low | Extension/runtime churn | Settings already handled elsewhere; leave extension cache unmanaged |
| `~/.local/share/nvim/mason` | Low-medium | Generated tool install state | Prefer Nix-managed tools over Mason-managed state |

### 6. Project-Local Environment Manifests Still Outside This Repo

These are not dotfiles in the narrow sense, but they are still part of the “everything on the machine should be reproducible” goal.

Effect:

- Variable. High for repos used daily, published artifacts, deployment workflows, and anything with CI parity requirements.
- Low for validation, throwaway experiments, copied samples, and old prototypes under `~/src`.

Risks:

- Low blast radius if each project gets its own flake and no global dotfiles change is required.
- Medium maintenance cost if many low-use repos get flakes that are never exercised.
- Higher risk for AWS/CDK and mixed Python/Node repos because devShells often need extra native dependencies and cloud-tool assumptions.

Recommended handling:

- Do not treat all of `~/src` as equal.
- Migrate active repos first: writing/publishing repos, talks, active app repos, CDK repos, and anything repeatedly opened by agents.
- Leave validation-heavy or low-use repos as-is until they become active.
- Keep project flakes in the project repos, not in this dotfiles repo.

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

1. Classify shell and dotfile gaps into managed config versus runtime state.
2. Split developer tool directories into stable config, secrets, cache, and generated state.
3. Add high-effect macOS defaults to `nix/darwin.nix`, starting with input and window-management behavior.
4. Selectively evaluate app settings that have stable plain-text config files.
5. Add launchd jobs only for user-owned background tasks.
6. Add project-local flakes only to active repos where reproducibility materially improves daily work.

The main constraint is not technical ability. It is classification discipline:

- declarative and stable -> Nix
- app-managed but structurally safe -> merge or generated config
- secret or ephemeral -> leave out
