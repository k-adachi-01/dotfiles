# AGENTS.md — global

## 実行環境

- **主環境**: macOS on Apple Silicon / NixOS Linux
- **レガシー環境**: Ubuntu 24.04 on WSL2
- **パッケージ管理の主軸**: Nix (`nix-darwin` + `home-manager`)
- **Homebrew**: GUI cask のみに限定する
- **nix-darwin 適用**: このデバイスでは system activation に root 権限が必要。`darwin-rebuild switch` ではなく `sudo darwin-rebuild switch --flake ~/.config/nix-darwin#macbook` を使う。

### NixOS PC

- NixOS システム設定は `/etc/nixos` で管理する。
- NixOS の active flake は `/etc/nixos#nixos`。
- この dotfiles repo は NixOS ではユーザー環境のみを `.#homeConfigurations."adachi@nixos"` で管理する。
- NixOS の `/etc/nixos` は boot/hardware/networking/desktop services/system daemons/firewall/user account だけに限定する。通常の開発 CLI・shell・git・editor・AI agent 設定は dotfiles の Home Manager 側へ追加し、二重管理しない。

通常のシステム更新:

```bash
sudo nix flake update /etc/nixos
sudo nixos-rebuild switch --flake /etc/nixos#nixos
```

検証のみ:

```bash
sudo nixos-rebuild build --flake /etc/nixos#nixos
```

一時適用:

```bash
sudo nixos-rebuild test --flake /etc/nixos#nixos
```

`nix-channel --update` や `nixos-rebuild --upgrade` はこのマシンの通常更新には使わない。

### WSL2でaptが必要な場合

WSL2上でOSパッケージが必要な場合だけ `apt` を使う。`apt-get` は使用しない。

| NG | OK |
|---|---|
| `apt-get install` | `apt install` |
| `apt-get update` | `apt update` |

## Python パッケージマネージャー

**uv を使用する。pip・pip3 は使用しない。仮想環境は必ず `uv venv` で作成する。**

- 仮想環境作成: `uv venv`
- 仮想環境有効化: `source .venv/bin/activate`
- パッケージインストール: `uv pip install <pkg>`
- スクリプト実行（venv 不要）: `uv run python script.py`
- ツールのグローバルインストール: `uv tool install <pkg>`

| NG | OK |
|---|---|
| `pip install` | `uv pip install` |
| `pip3 install` | `uv pip install` |
| `python -m pip install` | `uv pip install` |
| venv なしで直接インストール | `uv venv` で仮想環境を作成してから |

## JavaScript パッケージマネージャー

**pnpm を使用する。npm は使用しない。**

- 依存インストール: `pnpm install`
- スクリプト実行: `pnpm exec <cmd>` または `pnpm run <script>`
- ロックファイル: `pnpm-lock.yaml`（`package-lock.json` は作成・コミットしない）
- 新規プロジェクトの `package.json` には `"packageManager": "pnpm@<version>"` フィールドを追加する

## ツールバージョン管理

**Nix を主軸にする。mise は移行期間だけ使用する。**

- 新規プロジェクトでは project-local `flake.nix` と `nix develop` を優先する
- 既存プロジェクトの `.mise.toml` は、Nix devShellへ移行するまでの暫定互換として扱う
- `mise` を新しい長期運用の前提にしない
- CIは各プロジェクトの現状に合わせるが、ローカル開発環境は段階的にNixへ寄せる

```toml
# .mise.toml の例
[tools]
node = "22.13.1"
pnpm = "latest"
```

## GitHub Actions

- インストールは `pnpm install --frozen-lockfile`
- スクリプト実行は `pnpm exec` または `pnpm run`
- 既存CIが `mise` を使っている場合は維持してよいが、新規CIではプロジェクトごとに方針を明記する

## Linter / Formatter

**Biome を使用する。ESLint・Prettier は使用しない。**

- インストール: `pnpm add -D @biomejs/biome`
- 初期化: `pnpm exec biome init`
- Lint: `pnpm exec biome lint`
- Format: `pnpm exec biome format`
- Lint + Format 一括: `pnpm exec biome check`
- 自動修正: `pnpm exec biome check --write`

| NG | OK |
|---|---|
| `eslint` | `pnpm exec biome lint` |
| `prettier` | `pnpm exec biome format` |

## NG パターン

| NG | OK |
|---|---|
| `pip install` | `uv pip install`（仮想環境内） |
| `pip3 install` | `uv pip install`（仮想環境内） |
| `npm install` | `pnpm install` |
| `npx <cmd>` | `pnpm exec <cmd>` |
| `cache: 'npm'` (actions/setup-node) | `jdx/mise-action@v2` |
| `package-lock.json` をコミット | `pnpm-lock.yaml` をコミット |
| `eslint` / `prettier` を導入 | `@biomejs/biome` を使用 |

## dotfiles 管理

**Nix/home-manager を使用する。chezmoi は使わない。**

- 標準配置: `~/.config/nix-darwin/`（git リポジトリ: `k-adachi-01/dotfiles`）
- 設定編集: `nix/` または `home/` を直接編集する
- 適用: `sudo darwin-rebuild switch --flake ~/.config/nix-darwin#macbook`
- 管理対象: shell, git, WezTerm, Neovim, Claude/Codex/Cursor/Agents 設定
- GUI アプリ（Zed, WezTerm, Cursor 等）は Homebrew cask（`nix/apps.nix`）。`darwin-rebuild switch` は可能なら **Terminal.app** から実行する（App Management TCC の再プロンプト回避）
- 除外（秘密情報）: `.aws/`, `.azure/`, `.config/gcloud/`, `.config/gh/hosts.yml`, `.ssh/`, `.gnupg/`, `.env.keys`
- コミット前に `gitleaks protect --staged --config .gitleaks.toml` を実行する（`gitleaks` は `nix/packages.nix` で管理）。push 後は GitHub Actions（`.github/workflows/ci.yml`）が同じ設定で `gitleaks detect` を実行する

**dotfiles を更新した後は、ユーザーへ確認せず、必ず `k-adachi-01/dotfiles` リポジトリへ commit・push すること。**

### Codex / Claude Code / Cursor / Kiro 設定運用

- Codex/Claude Code/Cursor/Kiro の4ツールすべてが統一管理モデル（`docs/management-policy.md`）のクラスA/Bへ移行済み（PR6〜PR8完了）。`sync-codex-config`/`sync-kiro-config` のようなツール固有の再同期スクリプトはもう存在しない。`sudo darwin-rebuild switch` を実行するだけで、クラスAは deep-merge、クラスBは symlink 経由で常に最新の宣言が反映される
- Codex: `home/agents/codex/config.toml` が `nix/agents/codex.nix` 経由で `~/.codex/config.toml` へ **switch のたびに deep-merge** される（宣言キーは常に上書き、`[projects.*]` 等アプリが書いた宣言外キーは保持）。`~/.codex/AGENTS.md`・`keybindings.json`・`openai.config.toml`・`bedrock.config.toml`・`rules/default.rules`・`notify.sh` は `home/agents/codex/*` への out-of-store symlink（repo を編集すれば switch 不要で即反映）
- Claude Code: `nix/agents/claude.nix` の attrset が `~/.claude/settings.json`・`.mcp.json`・`keybindings.json` へ deep-merge される。`~/.claude/AGENTS.md`・`CLAUDE.md`・`statusline.py`・`notify-done.sh` は `home/ai/`・`home/agents/claude/*` への out-of-store symlink
- Cursor: `nix/agents/cursor.nix` の attrset が `~/.cursor/cli-config.json`・`mcp.json` へ deep-merge される（Cursor 自身が書く `hasChangedDefaultModel`/`selectedModel` 等は宣言外キーとして保持される）。`~/.cursor/AGENTS.md`・`statusline.sh` は out-of-store symlink
- Kiro: `nix/agents/kiro.nix`（`nix/agents/mcp.nix` の値を参照）が `~/.kiro/powers.json`・`powers.mcp.json`・`settings/cli.json`・`settings/mcp.json`・`settings/kiro_cli_theme.json`・`settings/permissions.yaml` を同様に deep-merge する。`home/agents/kiro/powers/**` の個別ファイルは out-of-store symlink。`~/.kiro/powers/` 自体は Kiro runtime が `registries/` などを作成できるよう通常ディレクトリのまま維持する
- merge は辞書（テーブル/オブジェクト）のみを再帰マージする。配列は宣言側で丸ごと置き換わる（例: `permissions.yaml` の `rules` リストに Kiro が独自に追記しても、次の switch で宣言値に戻る）。配列への追記を保持したいフィールドが見つかったら、そのフィールドは merge の対象から外しクラスCとして扱うことを検討する
- `agents-diff`（`~/.local/bin/agents-diff`）を実行すると、4ツールすべての class A ファイルについて「次の switch で何が変わるか」と「宣言されていないアプリ所有キー」を読み取り専用で確認できる。ローカルで試した設定を恒久化したい時は、これで確認してから該当する `nix/agents/<tool>.nix` の attrset へ手動で移す
- Codex skills と Kiro skills の seed は `/Users/adachi/agent-skills` を共通 source of truth とする。`~/.codex/skills/*` と `~/.kiro/skills/*` は switch のたびに常に再同期される動的カタログ（merge/link のどちらでもない、専用の rsync ミラー）
- Kiro CLI 本体のバージョン・取得元は `nix/packages.nix` で管理する
- Kiro shell integration / alias は `nix/home.nix` で管理する
- Kiro v3 permissions は `nix/agents/mcp.nix` の `kiroPermissions` を独立した source of truth とする。全 capability を許可し、回復困難な shell 操作だけを明示的に deny する。`sudo` は原則 deny だが、`sudo darwin-rebuild switch --flake /Users/adachi/.config/nix-darwin#macbook` だけを例外として許可する
- Kiro powers の seed は `home/agents/kiro/powers/` で管理し、共通 skills とは別責務として維持する
- `~/.kiro/sessions/`, `~/.kiro/logs/`, `~/.kiro/.cli_bash_history`, `~/.kiro/settings/feed_state.json`, `~/.kiro/settings/survey_state.json`, `~/.codex/sessions/`, `~/.codex/cache/`, `~/.codex/*.sqlite*` は runtime state として Nix/Git 管理しない
- `kiro-cli settings`, `kiro-cli mcp add`, `kiro-cli theme` で試した変更は永続化せず、必要な内容を Nix source に移してから switch する
- `home/agents/codex/config.toml` は「switch のたびに live ファイルへ merge される管理キーの宣言」を最小に維持する。次のものは **コミットしない**（アプリが実行時に生成するランタイム状態であり、宣言に混ぜると個人のプロジェクト構成やローカルパスが漏れる。混ぜても実害はない——宣言外キーとしてそのまま live 側に残るだけだが、public repo に個人情報を置くこと自体が問題）:
  - `[projects.*]`（trust_level の記録。プロジェクトディレクトリ名を通じて業務内容や第三者名が漏れる可能性がある）
  - `[marketplaces.*]`（`last_updated` タイムスタンプと `.tmp/`/`.cache/` 配下のローカル絶対パス）
  - `[mcp_servers.node_repl]` とその `env`（Codex.app のビルド固有パス・バージョン文字列）
  - `notify` に computer-use 由来の `.app` バンドル絶対パスを含めない。`nix/agents/codex.nix` で `config.home.homeDirectory` から生成される `["bash", "$HOME/.codex/notify.sh"]` 相当の形だけを維持する
  - `home/agents/codex/config.toml` を変更する PR では、上記パターンが紛れ込んでいないか diff を確認してからコミットする

## ファイルパス（Windows / WSL2）

- **MUST** ファイルを指定するときに、Windows 形式のパスは Ubuntu のマウントディレクトリのパスに変換すること
  - 例: `C:\Users\user1\Pictures\test.jpg` → `/mnt/c/Users/user1/Pictures/test.jpg`
