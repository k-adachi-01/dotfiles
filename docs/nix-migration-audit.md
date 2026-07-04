# Nix Migration Audit Log

Last updated: 2026-07-04

実行結果の記録。計画本体は [`nix-migration-plan.md`](nix-migration-plan.md)。

## Phase 0 — Baseline (2026-07-04)

### 0.1 リポジトリと live 環境

| チェック | 結果 |
|---|---|
| `nix build '.#darwinConfigurations.macbook.system' --no-link` | 成功 |
| `agents-diff` | 完走。`codex-config` のみ `model` が live `gpt-5.5` vs 宣言 `gpt-5.4-mini` で差分（意図的に宣言側が switch で上書き） |
| `agents-diff` 宣言外キー | `marketplaces`, `mcp_servers`, `projects`（クラスC相当、昇格しない） |
| ベースライン保存 | `/tmp/agents-diff-baseline.txt` |

### 0.2 管理済み領域の回帰

| パス | 結果 |
|---|---|
| `~/.codex/config.toml` | regular file（class A） |
| `~/.claude/settings.json` | JSON data |
| `~/.cursor/cli-config.json` | JSON data |
| Cursor `settings.json` | JSON data |
| `~/.kiro/settings/permissions.yaml` | `rules` 1 件 |
| class B `AGENTS.md` ×4 | すべて `~/.config/nix-darwin/home/ai/AGENTS.md` を指す |
| Codex skill ミラー | `dotfiles-nix-maintenance/SKILL.md` 存在 |

---

## Phase 1 — Shell / dotfile 境界 (2026-07-04)

### 1.1 `~/.local/bin` 棚卸し

| エントリ | 種別 | 推奨 |
|---|---|---|
| `agents-diff` | Nix 生成 script | **管理済み** (`nix/agents/default.nix`) |
| `skills-push` | Nix 生成 script | **管理済み** |
| `kiro-cli`, `kiro-cli-chat`, `kiro-cli-term` | Mach-O（Nix `kiro-cli` 由来） | **ツール管理のまま**。`nix/packages.nix` に同梱済み。`~/.local/bin` への重複配置は kiro-cli インストーラ側。削除は switch では行わない |
| `bash/fish/nu/zsh (kiro-cli-term)` | Mach-O ラッパー | 同上 |
| `cursor`, `cursor-agent` | Cursor cask 付属 script | **cask 管理のまま** |
| `agent` | shell script | **要確認**（Cursor 関連の可能性。repo へ取り込まない） |

**結論**: repo 所有は `agents-diff` / `skills-push` のみ。他はツール・cask が書く領域として触らない。

### 1.2 `.zprofile`

宣言元は `nix/home.nix` の `home.file.".zprofile".text`:

- Nix daemon profile（必須）
- `kiro-cli init zsh pre`（`packages.nix` の `kiro-cli` と整合）
- `~/.orbstack/shell/init.zsh`（OrbStack cask 付属、存在時のみ）

**結論**: 現状維持。ad hoc 行の追加削除は不要。

### 1.3 ランタイム状態の除外

`rg 'zsh_history|zcompdump|nix-profile' nix/` → ヒットなし。

### 1.4 `~/.mise.toml`

- ソース: `home/mise.toml` → `node 24.12.0`, `pnpm 10.27.0`
- フェーズ 6 まで維持。新規ツールは project flake 優先。

---

## Phase 2 — 開発ツール監査 (2026-07-04)

### 2.1 ディレクトリ分類

| パス | 設定 | 秘密/状態 | 判定 |
|---|---|---|---|
| `~/.config/zed/settings.json` | JSONC、674B | 低 | **class A 候補 → 2.2 で実装** |
| `~/.config/zed/keymap.json` | JSONC 配列 | 低 | **class B `mkLink`**（配列トップレベル、GUI 追記ありうるが merge 非対応のため symlink） |
| `~/.browser-use-config` | 拡張 CRX のみ | — | **管理しない**（プロファイル/拡張） |
| `~/.agent-browser` | `.pid`, `.stream` 等 | — | **管理しない**（ランタイム） |
| `~/.orbstack/config/docker.json` | JSON | VM/SSH/ログ同階層 | **設定のみ将来候補**（2.3）。`ssh/`, `vmstate.json`, `log/` は除外 |
| `~/.docker/config.json` | 認証含む | **高** | **管理しない** |
| `~/.iam-policy-autopilot/config.json` | JSON | 要調査 | **後回し** |

### 2.4 明示スキップ（固定）

- `~/.docker/config.json`
- `~/.codex/computer-use/config.json`
- `~/.semantic_search`
- `~/.local/share/nvim/mason`

---

## Phase 5 — Launch Agents（先行観測）

| plist | 推奨 |
|---|---|
| `com.google.*` | 管理しない（vendor） |
| `com.amazon.codewhisperer.*` | 管理しない |
| `com.adachi.screenshot-copy.plist` | **ユーザー所有**。`~/.config/screenshot-copy/` へ symlink。dotfiles 未収録 → フェーズ 5.2 候補 |

---

## 次の実装 PR

1. `nix-mig/2.2-zed-settings` — Zed `settings.json` class A merge（JSONC 読み取り対応）+ `keymap.json` class B link
2. `nix-mig/3.1-keyboard-defaults` — 入力ソース等（`KeyRepeat`/`InitialKeyRepeat` は既に `darwin.nix` と live 一致済み）
3. `nix-mig/5.2-screenshot-copy` — launchd + config を dotfiles へ取り込み（別 repo パス要確認）
