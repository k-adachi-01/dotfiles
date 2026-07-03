# AGENTS.md — dotfiles リポジトリ作業ガイド

このファイルは **このリポジトリ自体を編集する AI agent** 向けです。全プロジェクト共通のコーディングルールは [`home/ai/AGENTS.md`](home/ai/AGENTS.md)（`~/.codex/AGENTS.md` 等として配布される）にあり、役割が異なります。混同しないでください。

## このリポジトリの位置づけ

- パス: `~/.config/nix-darwin`（GitHub: `k-adachi-01/dotfiles`, **Public リポジトリ**）
- `nix-darwin` + `home-manager` による macOS 単一ホスト構成（`darwinConfigurations.macbook`, `aarch64-darwin`, ユーザー `adachi` 固定）
- **Public リポジトリであることを常に意識する**: 個人パス・第三者名・APIキー・タイムスタンプ付きランタイム状態を絶対にコミットしない

## 適用コマンド（必ず sudo 付き）

このデバイスは system activation に root 権限を要求する。

```bash
sudo darwin-rebuild switch --flake ~/.config/nix-darwin#macbook
```

プレーンな `darwin-rebuild switch` は `system activation must now be run as root` で失敗する。変更を加えたら必ず上記コマンドで適用し、`git status`/`git diff` を確認してからコミットする。

ビルドのみ行い適用しない検証（sudo 不要、破壊的変更前に使う）:

```bash
nix build '.#darwinConfigurations.macbook.system' --no-link
```

## ソースマップ

| ソース | 生成先 | 方式 |
|---|---|---|
| `nix/darwin.nix` | macOS system defaults, fonts, system packages | nix-darwin モジュール |
| `nix/apps.nix` | Homebrew casks/brews | nix-homebrew |
| `nix/packages.nix` | CLI 一式 | system packages |
| `nix/home.nix` | shell/git/direnv/fzf/tmux | home-manager ネイティブ |
| `nix/nixvim.nix` | Neovim 全設定 | nixvim（Neovim の唯一のソース。`home/config/nvim/` のような別ツリーを作らない） |
| `nix/editors.nix` | VS Code/Cursor/Antigravity/Antigravity IDE の `settings.json`（クラスA merge、`nix/agents/lib.nix` を共用） / `keybindings.json`（home.file symlink、配列トップレベルのため merge 非対応） | 詳細は [`docs/management-policy.md`](docs/management-policy.md) |
| `nix/agents/*` | Claude/Codex/Cursor/Kiro の user-level 設定、MCP 定義 | 詳細は [`docs/management-policy.md`](docs/management-policy.md) |
| `home/*` | 上記から参照される実ファイル本体 | — |

## AI エージェント設定の管理方式（最重要）

Claude Code / Codex / Cursor / Kiro の設定は、[`docs/management-policy.md`](docs/management-policy.md) が定義する **クラスA（宣言データ・merge）/ クラスB（静的アセット・symlink）/ クラスC（ランタイム状態・管理外）** の3分類に従う。**ツールごとに管理方式を独自に決めない。** 新しい設定項目を追加するときは、まず「アプリがそのファイルに書き込むか」を確認し、書き込むならクラスA、書き込まないならクラスBとして扱う。

同ドキュメントの「移行状況」表で各ツールが現在どちらの方式で実装されているかを確認すること。移行完了前のツールは、旧方式（seed-only または Nix store symlink）の制約がまだ有効。

やってはいけないこと:

- `~/.codex/*`, `~/.claude/*`, `~/.cursor/*`, `~/.kiro/*` を直接編集して「設定した」つもりにならない。これらは生成先であり、変更は必ず `nix/agents/*` または `home/agents/*` に対して行い、`sudo darwin-rebuild switch` で反映する
  - 例外: クラスB ファイル（`~/.codex/AGENTS.md`、`~/.claude/statusline.py`、`~/.cursor/statusline.sh` 等）は repo への symlink なので、`home/agents/*` を編集すれば switch なしで即反映される
- クラスA移行済みのツールで、宣言外キー（アプリが書いた実行時状態）を repo 側の attrset へ無条件にコピーしない。昇格は `agents-diff` で確認してから明示的に行う
- Codex/Claude Code/Cursor/Kiro の4ツールすべてが統一モデルへ移行済み（PR6〜PR8完了）。`nix/agents/*.nix` や `home/agents/*/*` を編集したら `sudo darwin-rebuild switch` だけで自動的に merge/link される。`sync-codex-config`/`sync-kiro-config` のような手動再同期スクリプトはもう存在しない
- merge は辞書のみ再帰処理する。配列（例: Kiro `permissions.yaml` の `rules`）は宣言側で丸ごと置き換わり、要素単位のマージはしない。配列に対するアプリの追記を保持したくなったら、そのフィールドをクラスCへ動かすことを検討する

## Agent Skills

- 共有 skills は別リポジトリ `/Users/adachi/agent-skills`（private, `k-adachi-01/agent-skills`）を flake input として取り込む
- flake input は `git+https://github.com/k-adachi-01/agent-skills.git`（`nix/home.nix` で設定済みの `gh auth git-credential` ヘルパーを再利用。`github:owner/repo` 形式は private repo だと別途 `access-tokens` の設定が必要になるため使わない）
- skills を更新する標準手順は `~/.local/bin/skills-push "commit message"` を実行するだけ（commit・push・`nix flake update agent-skills`・`sudo darwin-rebuild switch`・反映確認・`flake.lock` の commit/push を一括で行う）
- push せずローカルの skills 変更だけを試す場合は `sudo darwin-rebuild switch --flake ~/.config/nix-darwin#macbook --override-input agent-skills path:/Users/adachi/agent-skills`
- 個別に手順を追う場合は `nix flake update agent-skills --flake ~/.config/nix-darwin` を実行してから `sudo darwin-rebuild switch` する。`nix flake update`（引数なし = 全 input 更新）と混同しない

## 秘密情報・ローカル情報の防御

コミット前に必ず確認する:

- `.aws/`, `.azure/`, `.config/gcloud/`, `.config/gh/hosts.yml`, `.ssh/`, `.gnupg/`, `.env*`, `*.pem`, `*.key`, `auth.json`, `DOTENV_PRIVATE_KEY*` を含めない
- `home/agents/codex/config.toml` などクラスAの seed/宣言ファイルに `[projects.*]` のようなランタイム状態（プロジェクトパス、第三者名を含みうる）やタイムスタンプ付きキャッシュパスを混入させない（詳細は `home/ai/AGENTS.md` の Codex/Kiro 設定運用節）
- 迷ったら `docs/management-policy.md` の分類表とクラスC一覧を確認する

## 検証コマンド

```bash
git status --short --branch
nix build '.#darwinConfigurations.macbook.system' --no-link   # sudo 不要のビルド検証
alejandra --check . && statix check . && deadnix --fail .      # CI（.github/workflows/ci.yml）と同じ lint
gitleaks protect --staged --config .gitleaks.toml              # commit 前の秘密情報チェック
sudo darwin-rebuild build --flake ~/.config/nix-darwin#macbook  # 適用前のフル検証
sudo darwin-rebuild switch --flake ~/.config/nix-darwin#macbook
agents-diff                                                     # 次の switch での変更点とアプリ所有キーの確認（読み取り専用）
```

CI（GitHub Actions, `.github/workflows/ci.yml`）は push/PR ごとに lint（alejandra/statix/deadnix）と gitleaks を実行する。`agent-skills` が private repo のため、CI に認証情報を渡さない設計上の理由でフルの `nix build`/`darwin-rebuild build` は CI に含めていない。これは必ずローカルで実行すること。

## 変更後の運用

dotfiles を更新した後は、ユーザーへ確認せず `k-adachi-01/dotfiles` へ commit・push する（詳細は `home/ai/AGENTS.md` の dotfiles 管理節）。git 履歴は書き換えない（force-push・rebase -i・reset --hard は使わない）。
