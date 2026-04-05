# AGENTS.md — global

## 実行環境

- **OS**: Ubuntu 24.04 on WSL2
- **パッケージ管理**: `apt`（`apt-get` は使用しない）

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

**mise を使用する。**

- 各プロジェクトルートに `.mise.toml` を置き、`node` と `pnpm` のバージョンを明示する
- CI（GitHub Actions）では `jdx/mise-action@v2` で `.mise.toml` を読み込む

```toml
# .mise.toml の例
[tools]
node = "22.13.1"
pnpm = "latest"
```

## GitHub Actions

- Node/pnpm のセットアップは `jdx/mise-action@v2` 1 ステップで行う（`actions/setup-node` + `pnpm/action-setup` の組み合わせは不要）
- インストールは `pnpm install --frozen-lockfile`
- スクリプト実行は `pnpm exec` または `pnpm run`

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

**chezmoi を使用する。**

- ソースディレクトリ: `~/.local/share/chezmoi/`（git リポジトリ: `k-adachi-01/dotfiles`）
- 設定編集: `chezmoi edit <ファイル>` または直接編集後に `chezmoi apply`
- 新マシンへの適用: `chezmoi init --apply k-adachi-01/dotfiles`
- 管理対象: `.bashrc`, `.profile`, `.gitconfig`, `.inputrc`, `.mise.toml`, `.wezterm.lua`, `.config/nvim/`
- 除外（秘密情報）: `.aws/`, `.claude/`, `.config/gh/hosts.yml`

**dotfiles を更新した後は、必ずユーザーに `k-adachi-01/dotfiles` リポジトリへ commit・push するかどうか確認を求めること。**

## ファイルパス（Windows / WSL2）

- **MUST** ファイルを指定するときに、Windows 形式のパスは Ubuntu のマウントディレクトリのパスに変換すること
  - 例: `C:\Users\user1\Pictures\test.jpg` → `/mnt/c/Users/user1/Pictures/test.jpg`
