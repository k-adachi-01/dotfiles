# AGENTS.md — global

## 実行環境

- **主環境**: macOS on Apple Silicon
- **レガシー環境**: Ubuntu 24.04 on WSL2
- **パッケージ管理の主軸**: Nix (`nix-darwin` + `home-manager`)
- **Homebrew**: GUI cask のみに限定する
- **nix-darwin 適用**: このデバイスでは system activation に root 権限が必要。`darwin-rebuild switch` ではなく `sudo darwin-rebuild switch --flake ~/.config/nix-darwin#macbook` を使う。

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
- 除外（秘密情報）: `.aws/`, `.azure/`, `.config/gcloud/`, `.config/gh/hosts.yml`, `.ssh/`, `.gnupg/`, `.env.keys`

**dotfiles を更新した後は、ユーザーへ確認せず、必ず `k-adachi-01/dotfiles` リポジトリへ commit・push すること。**

### Codex / Kiro 設定運用

- Codex durable config は `home/agents/codex/*` を編集し、`~/.codex/*` を直接編集しない
- Kiro durable config は `nix/agents.nix` と `home/agents/kiro/powers/` を編集し、`~/.kiro/settings/*`, `~/.kiro/powers.json`, `~/.kiro/powers.mcp.json` を直接編集しない
- Kiro CLI 本体のバージョン・取得元は `nix/packages.nix` で管理する
- Kiro shell integration / alias は `nix/home.nix` で管理する
- Kiro v3 permissions は `home/agents/codex/default.rules` を source of truth とし、`nix/agents.nix` の生成処理で `~/.kiro/settings/permissions.yaml` に反映する
- `home/agents/codex/default.rules` を変更したら、Kiro permissions も変わる前提で `sudo darwin-rebuild switch --flake ~/.config/nix-darwin#macbook` 後に `~/.kiro/settings/permissions.yaml` を確認する
- `~/.kiro/sessions/`, `~/.kiro/logs/`, `~/.kiro/.cli_bash_history`, `~/.kiro/settings/feed_state.json`, `~/.kiro/settings/survey_state.json`, `~/.codex/sessions/`, `~/.codex/cache/`, `~/.codex/*.sqlite*` は runtime state として Nix/Git 管理しない
- `kiro-cli settings`, `kiro-cli mcp add`, `kiro-cli theme` で試した変更は永続化せず、必要な内容を Nix source に移してから switch する

## ファイルパス（Windows / WSL2）

- **MUST** ファイルを指定するときに、Windows 形式のパスは Ubuntu のマウントディレクトリのパスに変換すること
  - 例: `C:\Users\user1\Pictures\test.jpg` → `/mnt/c/Users/user1/Pictures/test.jpg`
