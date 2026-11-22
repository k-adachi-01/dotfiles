# AGENTS.md — global

## 実行環境

- **主環境**: macOS on Apple Silicon / NixOS Linux
- **レガシー環境**: Ubuntu 24.04 on WSL2
- **パッケージ管理の主軸**: Nix (`nix-darwin` + `home-manager`)
- **Homebrew**: GUI cask のみに限定する
- **nix-darwin 適用**: このデバイスでは system activation に root 権限が必要。`darwin-rebuild switch` ではなく `sudo darwin-rebuild switch --flake ~/.config/nix-darwin#macbook` を使う。
- **再起動後に CLI が消える**: `/nix` は APFS ボリューム。未マウントなら Nix 由来コマンドはすべて失敗する。再インストールせず `/bin/bash ~/.config/nix-darwin/home/bin/nix-store-repair.sh` を実行する。詳細は `~/.config/nix-darwin/docs/nix-store-recovery.md`。

### NixOS PC

- NixOS システム設定は `/etc/nixos` で管理し、active flake は `/etc/nixos#nixos`。
- この dotfiles repo は NixOS ではユーザー環境のみを `.#homeConfigurations."adachi@nixos"` で管理する。boot/hardware/networking/desktop services/firewall/user account 以外は dotfiles の Home Manager 側へ置き、二重管理しない。
- 更新は `sudo nixos-rebuild switch --flake /etc/nixos#nixos`（検証は `build`、一時適用は `test`）。`nix-channel` や `nixos-rebuild --upgrade` は使わない。

## パッケージマネージャー・ツールチェーン

- **Python**: `uv` を使う。`pip` / `pip3` / `python -m pip` は使わない。仮想環境は `uv venv` で作る。
- **JavaScript**: `pnpm` を使う。`npm` / `npx` は使わない。ロックファイルは `pnpm-lock.yaml` を使い、`package-lock.json` は作らない。
- **JS/TS lint・format・test**: Vite+（`vp`）を標準とする。Vite+ を使わないプロジェクトでは `oxlint` + `oxfmt`。Biome / ESLint / Prettier は新規導入しない。各コマンドの詳細は `vp --help` とプロジェクトの scripts を参照。
- **ツールバージョン**: project-local `flake.nix` + `nix develop` を優先する。既存の `.mise.toml` は Nix devShell 移行までの暫定互換として扱い、mise を新しい長期運用の前提にしない。
- **GitHub Actions**: `pnpm install --frozen-lockfile` と `pnpm exec` / `pnpm run` を使う。

## ブラウザ・デスクトップ操作

- Web ページの閲覧・操作・抽出は `agent-browser` を使う。実行前に `agent-browser skills get core` を読み、`agent-browser session id` で自前のセッションを取る。他のブラウザ自動化ライブラリや単なる HTTP fetch で代用しない。
- ネイティブなデスクトップアプリ・OS UI（Finder、System Settings、メニューバー、ダイアログ）は `agent-desktop` を使う。実行前に `agent-desktop permissions` を確認し、未許可ならユーザーに許可を依頼して止まる。
- それぞれの詳細は `agent-browser` / `agent-desktop` skill にある。

### フォーカスを奪わない（人間と同時に作業している前提）

同じマシンで人間が作業している。エージェントの都合でフォーカス・カーソル・画面を動かさない。

- Web ページは `agent-browser`（既定は headless。ウィンドウも出ず、フォーカスも動かない）。**ユーザーの Chrome を操作対象にしない。** ログインが必要なサイトは agent-browser の専用 `--profile` に一度だけ通し、以降は再利用する。
- ユーザーが「このブラウザ（自分の Chrome）でやって」と指示しても、まず agent-browser + 専用プロファイルで代替できないかを確認する。代替できるならそう提案し、`agent-desktop` でのブラウザ操作は最後の手段にする。
- `agent-desktop` では次を禁止する。
  - `open -a` / `osascript ... activate` / `focus-window` を**リトライループに入れる**こと。前面化しないなら原因を報告して止まる。
  - `caffeinate -u` でスリープを解除すること（離席を尊重する）。
  - `screencapture` で画面全体・画面領域を撮ること（ウィンドウ指定か、ドライバのページスクリーンショットを使う）。
- フォーカス・カーソル・キーを動かす操作（`--headed`、`mouse-click`、`press`）は、対象と座標を先に提示して許可を得てから**1 回だけ**実行し、終わったら元のアプリに戻す。
- 作業開始前に前面アプリを確認し、人間がアクティブなら中断して確認する。作業中に前面アプリが変わったら人間の介入とみなして即停止する。

## dotfiles 管理

- **Nix/home-manager を使用する。chezmoi は使わない。**
- 標準配置: `~/.config/nix-darwin/`（git リポジトリ: `k-adachi-01/dotfiles`、**public**）
- 設定編集: `nix/` または `home/` を直接編集し、`sudo darwin-rebuild switch --flake ~/.config/nix-darwin#macbook` で適用する
- GUI アプリ（Zed, WezTerm, Cursor 等）は Homebrew cask（`nix/apps.nix`）
- 秘密情報をコミットしない: `.aws/`, `.azure/`, `.config/gcloud/`, `.config/gh/hosts.yml`, `.ssh/`, `.gnupg/`, `.env.keys`
- コミット前に `gitleaks protect --staged --config .gitleaks.toml` を実行する
- **dotfiles を更新した後は、ユーザーへ確認せず、必ず `k-adachi-01/dotfiles` リポジトリへ commit・push すること。**

### AI agent 設定

Claude Code / Codex / Cursor / Kiro / Devin の設定は dotfiles のクラスA（merge）/ クラスB（symlink）/ クラスC（runtime）モデルで一元管理する。生成先（`~/.codex`, `~/.claude`, `~/.cursor`, `~/.kiro`, `~/.config/devin`）は直接編集しない。詳細は dotfiles repo の `AGENTS.md`・`docs/management-policy.md` と `dotfiles-nix-maintenance` skill を参照。

## ファイルパス（Windows / WSL2）

- Windows 形式のパスは Ubuntu のマウントディレクトリのパスに変換すること（例: `C:\Users\user1\test.jpg` → `/mnt/c/Users/user1/test.jpg`）
