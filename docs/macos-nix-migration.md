# macOS Nix 移行 Runbook

このドキュメントは、現在の **Windows + WSL2 Ubuntu** 環境から、新しい **Apple Silicon Mac + Nix** 環境へ移行するための引き継ぎ資料です。

目的は「今の環境をそのまま macOS にコピーすること」ではありません。WSL/Ubuntu/Windows 依存を捨て、開発に必要な CLI・shell・dotfiles・認証・プロジェクト環境を、macOS 上で再現可能な形に再構成します。

最終状態は以下です。

- macOS のシステム設定は `nix-darwin` で管理する。
- ユーザー環境、CLI、shell、git、開発基本ツールは `home-manager` で管理する。
- Homebrew は GUI アプリの cask のみに限定する。
- `mise` は移行期間だけ残し、最終的には project-local `flake.nix` / `nix develop` に置き換える。
- dotfiles は `k-adachi-01/dotfiles` を Nix flake repository として管理する。
- WSL 固有設定、Windows 連携、Ubuntu 基盤パッケージは macOS へ持ち込まない。

## 1. 現在の状態

### 1.1 dotfiles リポジトリ

リポジトリ:

```text
https://github.com/k-adachi-01/dotfiles.git
```

旧WSL上の作業ディレクトリ:

```text
/home/adachi/.local/share/chezmoi
```

新Macでの標準配置:

```text
~/.config/nix-darwin
```

macOS Nix 構成はすでに `main` に追加済みです。chezmoi source tree としてではなく、Nix flake repository として利用します。

主要ファイル:

```text
flake.nix
nix/apps.nix
nix/darwin.nix
nix/home.nix
nix/packages.nix
docs/macos-nix-migration.md
```

Nix flake の出力名:

```text
darwinConfigurations.macbook
```

対象アーキテクチャ:

```text
aarch64-darwin
```

想定 macOS ユーザー名:

```text
adachi
```

### 1.2 現 WSL 環境の構成要素

現在の WSL 環境は、複数の管理元が混在しています。

```text
apt
mise
pnpm global
uv tools
cargo/rustup
/usr/local/bin の手動配置バイナリ
Windows 側アプリを WSL から参照する設定
Nix/home-manager managed dotfiles
```

macOS 移行では、これらをそのまま移すのではなく、以下の基準で再配置します。

```text
開発 CLI -> Nix / home-manager
macOS システム設定 -> nix-darwin
GUI アプリ -> Homebrew cask
プロジェクト単位の言語ランタイム -> project-local flake.nix
移行期間の互換用ランタイム管理 -> mise
秘密情報・認証情報 -> 各 CLI で再ログイン
AI/editor 系 dotfiles -> home-manager
```

### 1.3 WSL で明示導入されていた apt パッケージ

移行判断に関係する apt パッケージは以下です。

```text
azure-cli
bat
build-essential
cmake
curl
fd-find
fonts-noto-cjk
fonts-noto-color-emoji
fzf
gh
git
gnupg
google-cloud-cli
jq
ngrok
nodejs
npm
podman
python3
python3-pip
python3-venv
ripgrep
stow
tmux
tree
unzip
wl-clipboard
wslu
xdotool
xvfb
zstd
```

Ubuntu/WSL の基盤パッケージ、X11/Wayland 系、Windows 連携用ツールは macOS には移植しません。

### 1.4 現在の mise 管理ツール

WSL で確認された mise 管理ツール:

```text
cargo:dioxus-cli 0.7.2
cargo:dioxus-cli 0.7.3
just 1.48.1
node 22.13.1
node 22.22.2
node 24.12.0
node 25.2.1
pnpm 9.15.9
pnpm 10.27.0
pnpm 10.28.0
pnpm 10.33.0
pnpm 11.1.2
python 3.13.12
python 3.14.2
rust stable
uv 0.9.22
```

グローバル mise 設定:

```toml
[tools]
node = "lts"
pnpm = "latest"
python = "latest"
uv = "latest"
```

dotfiles 側の `~/.mise.toml`:

```toml
[tools]
node = "24.12.0"
pnpm = "10.27.0"
```

移行方針:

```text
初回 macOS 移行では mise を残す。
Nix 側でも mise を入れておく。
ただし新規の長期運用は mise に増やさない。
主要プロジェクトから順に flake.nix へ置き換える。
全主要プロジェクト移行後に mise を nix/packages.nix から削除する。
```

### 1.5 現在の pnpm global ツール

WSL の pnpm global dependencies:

```text
@devcontainers/cli
@dotenvx/dotenvx
@googleworkspace/cli
@openai/codex
agent-browser
defuddle
dev-browser
excalidraw-mcp
vercel
```

初回 macOS 移行では、これらを完全に Nix 化しません。AI/browser/MCP 系 CLI は更新が速く、最初から Nix 化すると移行全体のリスクが上がるためです。

暫定方針:

```text
Nix で安定して提供できるものは Nix へ移す。
プロジェクト単位で使うものは devDependency 化する。
AI/browser/MCP 系の一部は pnpm global を一時許容する。
```

### 1.6 現在の手動配置バイナリ

WSL の `/usr/local/bin` などで確認したもの:

```text
/usr/local/bin/aws
/usr/local/bin/aws_completer
/usr/local/bin/kubectl
/usr/local/bin/mdcat
/usr/local/bin/mo
/usr/local/bin/ngrok
/usr/local/bin/ollama
/usr/local/bin/sam
```

移行判断:

| 現在 | macOS での扱い |
|---|---|
| `aws` | `pkgs.awscli2` |
| `kubectl` | `pkgs.kubectl` |
| `mdcat` | 初回対象外。必要になったら追加 |
| `ngrok` | 初回対象外。必要になったら追加 |
| `ollama` | 初回対象外。必要になったら別途検討 |
| `sam` | 初回対象外。必要なら `aws-sam-cli` を追加 |
| `mo` | 用途が確定するまで移行しない |

### 1.7 WSL / Windows 連携

現在の WSL 固有要素:

```text
/home/adachi/bin/win32yank.exe
/home/adachi/bin/ime_toggle.exe
/home/adachi/bin/im-select.exe
/home/adachi/bin/ime_toggle.ps1
/mnt/c/Users/adachi/... への参照
wslu
wl-clipboard
xdotool
xvfb
```

移行判断:

```text
macOS には移行しない。
```

理由:

- clipboard は macOS ネイティブ機能を使う。
- IME 制御は Windows/WSL 固有。
- `/mnt/c` は macOS に存在しない。
- X11/Wayland 前提のツールは macOS の通常開発環境には不要。
- headless browser などで必要な場合だけ、プロジェクト単位で追加する。

### 1.8 現在残っている未コミット変更

初回 Runbook 作成時点では、以下が Nix 移行とは別の未コミット変更として残っていました。

```text
dot_bashrc
dot_wezterm.lua.tmpl
```

扱い:

```text
Nix 構成追加コミットには混ぜない。
内容を確認してから、別コミットとして整理する。
```

整理方針:

```text
dot_bashrc は WSL 互換用として残す。
dot_wezterm.lua.tmpl は Linux/WSL と macOS の分岐を明確にする。
macOS に存在しない /mnt/c や /proc 参照は、実行されないよう条件分岐する。
```

### 1.9 このPCで実施済みの移行準備

このPC上で完了済み:

```text
macOS 用 flake.nix / nix/ 構成を dotfiles に追加。
Homebrew を GUI cask 最小構成に制限。
home-manager で zsh/git/fzf/tmux/direnv/開発CLIを管理する構成を追加。
移行 Runbook を docs/macos-nix-migration.md に追加。
GitHub credential helper の /usr/bin/gh 固定を削除。
WezTerm テンプレートの /proc 参照を Linux/WSL 分岐内へ限定。
WezTerm の leader+n / leader+c を codex 起動へ統一。
bash の cdx alias を codex に統一。
bash の Windows Obsidian alias を実体がある場合だけ定義するよう変更。
Neovim の win32yank clipboard 設定を Windows/WSL かつ実行ファイルがある場合だけ有効化。
Neovim Thino の Obsidian vault を OBSIDIAN_VAULT または ~/obsidian 参照に変更。
chezmoi 固有ファイルを home-manager 用の home/ ツリーへ移動。
README と AGENTS.md を Nix/home-manager 管理方針へ更新。
```

このPC上で意図的に実施しないこと:

```text
WSL に Nix を追加インストールしない。
nix flake check は新 Mac 側で行う。
darwin-rebuild は新 Mac 側で行う。
Homebrew cask の実インストールは新 Mac 側で行う。
クラウド CLI 認証情報は移行せず、新 Mac 側で再ログインする。
```

### 1.10 プロジェクト棚卸し

このPCで確認した `.mise.toml`:

```text
/home/adachi/.mise.toml
/home/adachi/articles/.mise.toml
/home/adachi/blog/tech-blog-writing/.mise.toml
/home/adachi/src/260329_kiro-powers-to-cli/.mise.toml
/home/adachi/src/260404_cdk-insights/.mise.toml
/home/adachi/src/260404_elsa-speak/.mise.toml
/home/adachi/src/260425_ai-tuber/.mise.toml
/home/adachi/src/cdk-agent-lab/.mise.toml
/home/adachi/src/cdk-validations/.mise.toml
/home/adachi/talks/slidev/.mise.toml
```

このPCで確認した `package.json`:

```text
/home/adachi/.dev-browser/package.json
/home/adachi/articles/package.json
/home/adachi/blog/tech-blog-writing/package.json
/home/adachi/package.json
/home/adachi/sample-spec-driven-presentation-maker/infra/package.json
/home/adachi/sample-spec-driven-presentation-maker/web-ui/package.json
/home/adachi/src/260223_ai-dlc-kiro/package.json
/home/adachi/src/260301_vercel-chat/package.json
/home/adachi/src/260329_kiro-powers-to-cli/package.json
/home/adachi/src/260404_cdk-insights/package.json
/home/adachi/src/260404_elsa-speak/package.json
/home/adachi/src/260425_ai-tuber/package.json
/home/adachi/src/app_img-uploader-v2/package.json
/home/adachi/src/app_img-uploader-v3/package.json
/home/adachi/src/cdk-validations/package.json
/home/adachi/talks/slidev/package.json
/home/adachi/tmp/everything-claude-code/package.json
```

このPCで確認した `pyproject.toml`:

```text
/home/adachi/.aws-sam/aws-sam-cli-app-templates/pyproject.toml
/home/adachi/sample-spec-driven-presentation-maker/mcp-local/pyproject.toml
/home/adachi/sample-spec-driven-presentation-maker/mcp-server/pyproject.toml
/home/adachi/sample-spec-driven-presentation-maker/pyproject.toml
/home/adachi/sample-spec-driven-presentation-maker/skill/pyproject.toml
/home/adachi/src/260110_tddbc/pyproject.toml
/home/adachi/src/aws-sam-cli-app-templates/pyproject.toml
/home/adachi/talks/sample-spec-driven-presentation-maker/pyproject.toml
```

移行順序の推奨:

```text
1. articles または blog/tech-blog-writing など、日常使用頻度が高く依存が軽い Node/pnpm プロジェクト。
2. talks/slidev など、成果物生成が明確な Node/pnpm プロジェクト。
3. cdk-validations / cdk-insights など AWS/CDK 依存を含むプロジェクト。
4. sample-spec-driven-presentation-maker など Node/Python/infra が混在するプロジェクト。
5. browser automation / AI tool 系の特殊依存プロジェクト。
```

## 2. 追加済み Nix 構成

### 2.1 flake.nix

役割:

```text
nixpkgs / nix-darwin / home-manager / nix-homebrew を入力として定義する。
Apple Silicon Mac 用の darwinConfigurations.macbook を定義する。
ユーザー名 adachi と system aarch64-darwin を渡す。
```

重要な前提:

```text
macOS ユーザー名が adachi であること。
Apple Silicon Mac であること。
```

ユーザー名が違う場合は、初回 `darwin-rebuild` 前に `flake.nix` の `username` を変更します。

### 2.2 nix/darwin.nix

役割:

```text
nix-darwin 側のシステム設定。
Determinate Nix と衝突しないように nix-darwin 側の Nix 管理を無効化。
zsh を有効化。
home-manager の既存ファイル衝突時 backup extension を設定。
Finder/Dock などの最低限の macOS defaults を設定。
```

現在の設計:

```text
macOS 外観など主観的な設定は最小限にする。
CLI や shell の詳細は home-manager に寄せる。
GUI アプリは apps.nix に分離する。
```

### 2.3 nix/home.nix

役割:

```text
ユーザー adachi の home-manager 設定。
Nix packages の導入。
zsh 設定。
git 設定。
direnv/nix-direnv 設定。
fzf 設定。
tmux 設定。
```

移植済みの shell 要素:

```text
vi mode
alias cc='claude --permission-mode acceptEdits'
alias ca='claude --enable-auto-mode'
alias cdx='codex'
alias ll='ls -alF'
alias la='ls -A'
WezTerm title update
簡易 prompt
```

移植していないもの:

```text
WSL/Ubuntu 固有 PATH
/mnt/c 参照
Podman socket
Windows Obsidian alias
Ubuntu bash completion
/usr/lib/git-core/git-sh-prompt
```

### 2.4 nix/packages.nix

現在 Nix で導入する CLI / 開発ツール:

```text
awscli2
azure-cli
bat
cmake
curl
direnv
fd
fzf
gh
git
gnumake
gnupg
google-cloud-sdk
jq
just
kubectl
mise
neovim
nodejs_24
pkg-config
pnpm
python313
ripgrep
rustup
tmux
tree
unzip
uv
wget
zstd
```

運用ルール:

```text
CLI を追加する場合は基本的にこのファイルへ追加する。
Homebrew formula には追加しない。
mise は移行完了後に削除する。
```

### 2.5 nix/apps.nix

Homebrew cask で管理する GUI アプリ:

```text
bitwarden
google-chrome
obsidian
orbstack
slack
visual-studio-code
wezterm
```

Homebrew activation policy:

```text
autoUpdate = false
upgrade = false
cleanup = "uninstall"
```

理由:

```text
darwin-rebuild のたびに Homebrew 全体を勝手に更新しない。
宣言から外した cask は削除する。
ただし zap は使わず、アプリの設定や状態を不用意に消さない。
```

## 3. 新 Mac 初回セットアップ手順

### 3.1 前提確認

新 Mac で確認します。

```bash
uname -m
whoami
```

期待値:

```text
uname -m -> arm64
whoami -> adachi
```

`whoami` が `adachi` でない場合は、先に dotfiles の Nix 構成を修正してから進めます。

### 3.2 Nix をインストール

推奨:

```bash
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
```

インストール後、新しい terminal を開くか、installer の指示どおり shell profile を読み込みます。

確認:

```bash
nix --version
nix flake --help
```

`nix flake --help` が動かない場合、flakes が使える状態になっていません。`darwin-rebuild` へ進まず、Nix 初期化を直します。

### 3.3 dotfiles repository を clone する

Homebrew は Nix 管理下で GUI cask 用に使うため、bootstrap には使いません。chezmoi も使いません。

```bash
mkdir -p "$HOME/.config"
git clone https://github.com/k-adachi-01/dotfiles.git "$HOME/.config/nix-darwin"
```

### 3.4 repository を確認する

```bash
ls -la "$HOME/.config/nix-darwin"
ls -la "$HOME/.config/nix-darwin/flake.nix"
ls -la "$HOME/.config/nix-darwin/nix"
ls -la "$HOME/.config/nix-darwin/home"
```

### 3.5 初回 darwin-rebuild

初回は `darwin-rebuild` がまだ PATH にないため、`nix run` 経由で実行します。

```bash
nix run github:nix-darwin/nix-darwin/master#darwin-rebuild -- switch --flake "$HOME/.config/nix-darwin#macbook"
```

成功後はいったん新しい login shell を開き、`PATH` を更新します。

```bash
exec "$SHELL" -l
```

その後、次回以降は以下を使います。

```bash
darwin-rebuild switch --flake "$HOME/.config/nix-darwin#macbook"
```

### 3.6 初回 switch 後に確認するもの

GUI アプリ:

```bash
ls -d /Applications/OrbStack.app
ls -d "/Applications/Visual Studio Code.app"
ls -d /Applications/WezTerm.app
```

基本 CLI:

```bash
git --version
gh --version
jq --version
rg --version
fd --version
bat --version
fzf --version
tmux -V
tree --version
just --version
```

言語ランタイム:

```bash
node --version
pnpm --version
python --version
uv --version
rustup --version
```

Cloud / infra:

```bash
aws --version
gcloud --version
az version
kubectl version --client
```

Nix / direnv:

```bash
nix --version
nix flake show "$HOME/.config/nix-darwin"
darwin-rebuild --help
direnv --version
```

### 3.7 認証を再設定する

認証情報は dotfiles で移行しません。新 Mac 側で再ログインします。

```bash
gh auth login
aws configure sso
gcloud auth login
az login
```

確認:

```bash
gh auth status
aws sts get-caller-identity
gcloud auth list
az account show
```

失敗した場合、まず各サービスのログイン状態を疑います。Nix 設定を変更する前に認証フローを完了させます。

## 4. WSL から macOS への置き換え表

### 4.1 apt から Nix へ移すもの

| WSL / apt | macOS / Nix |
|---|---|
| `azure-cli` | `pkgs.azure-cli` |
| `bat` | `pkgs.bat` |
| `build-essential` | Xcode CLT + `gnumake` / `pkg-config` / `cmake` |
| `cmake` | `pkgs.cmake` |
| `curl` | `pkgs.curl` |
| `fd-find` | `pkgs.fd` |
| `fzf` | `pkgs.fzf` |
| `gh` | `pkgs.gh` |
| `git` | `pkgs.git` |
| `gnupg` | `pkgs.gnupg` |
| `google-cloud-cli` | `pkgs.google-cloud-sdk` |
| `jq` | `pkgs.jq` |
| `nodejs` | `pkgs.nodejs_24` |
| `npm` | 直接管理しない。Node/pnpm に含める |
| `python3` | `pkgs.python313` |
| `python3-pip` | 使わない。`uv` に置換 |
| `python3-venv` | `uv venv` または project flake |
| `ripgrep` | `pkgs.ripgrep` |
| `tmux` | `pkgs.tmux` |
| `tree` | `pkgs.tree` |
| `unzip` | `pkgs.unzip` |
| `zstd` | `pkgs.zstd` |

### 4.2 移行しないもの

| 現在 | 理由 |
|---|---|
| `wslu` | WSL 専用 |
| `wl-clipboard` | Linux/Wayland 前提 |
| `xdotool` | X11 前提 |
| `xvfb` | Linux headless X 前提。必要なら project 単位で追加 |
| `podman` | 初回 macOS では OrbStack を使う |
| `win32yank.exe` | Windows 専用 |
| `ime_toggle.exe` | Windows 専用 |
| `im-select.exe` | Windows 専用 |
| Windows Obsidian alias | macOS アプリ起動方法に置き換える |

### 4.3 Homebrew に残すもの

初回で Homebrew に残すのは以下のみです。

```text
bitwarden
google-chrome
obsidian
orbstack
slack
visual-studio-code
wezterm
```

追加する場合の判断基準:

```text
GUI アプリである。
Nix で扱うより Homebrew cask の方が明らかに安定している。
商用アプリ、署名付きアプリ、auto-update 前提アプリである。
```

CLI は原則 Nix に追加します。

## 5. pnpm global ツールの扱い

### 5.1 初回移行で許容するもの

以下は必要になった時点で pnpm global を一時的に使ってよいです。

```text
@openai/codex
agent-browser
dev-browser
defuddle
```

例:

```bash
pnpm add -g @openai/codex agent-browser dev-browser defuddle
```

ただしこれは恒久運用ではありません。

### 5.2 project dependency へ寄せる候補

```text
@dotenvx/dotenvx
vercel
@devcontainers/cli
```

理由:

```text
プロジェクトごとに必要バージョンが変わる可能性が高い。
グローバルに固定すると、別プロジェクトで破壊的変更を受けやすい。
```

### 5.3 後回しにするもの

```text
@googleworkspace/cli
excalidraw-mcp
```

理由:

```text
常用かどうかを確認してから移行判断する。
必要なら project-local または pnpm global で暫定導入する。
```

## 6. Python / JavaScript の運用ルール

### 6.1 Python

使わない:

```text
pip install
pip3 install
python -m pip install
```

使う:

```bash
uv venv
source .venv/bin/activate
uv pip install <package>
uv run python <script.py>
uv tool install <tool>
```

長期方針:

```text
Python バージョンと uv は project-local flake.nix で固定する。
```

### 6.2 JavaScript / TypeScript

使わない:

```text
npm install
npx
package-lock.json
```

使う:

```bash
pnpm install
pnpm exec <command>
pnpm run <script>
```

プロジェクトに必要なもの:

```text
pnpm-lock.yaml
package.json の packageManager
```

長期方針:

```text
Node と pnpm のバージョンは mise ではなく project-local flake.nix で固定する。
```

## 7. mise 廃止手順

### 7.1 対象プロジェクト一覧

現在 `.mise.toml` が見つかっている場所:

```text
/home/adachi/.mise.toml
/home/adachi/articles/.mise.toml
/home/adachi/blog/tech-blog-writing/.mise.toml
/home/adachi/src/260329_kiro-powers-to-cli/.mise.toml
/home/adachi/src/260404_cdk-insights/.mise.toml
/home/adachi/src/260404_elsa-speak/.mise.toml
/home/adachi/src/260425_ai-tuber/.mise.toml
/home/adachi/src/cdk-agent-lab/.mise.toml
/home/adachi/src/cdk-validations/.mise.toml
/home/adachi/talks/slidev/.mise.toml
```

### 7.2 移行順序

1. 最もよく使うプロジェクトを1つ選ぶ。
2. そのプロジェクトに `flake.nix` を追加する。
3. 必要なら `.envrc` に `use flake` を追加する。
4. `direnv allow` を実行する。
5. 既存の開発コマンドを `mise activate` なしで実行する。
6. 全て通ったら、そのプロジェクトでは `.mise.toml` 依存を廃止する。
7. 同じ流れを主要プロジェクトで繰り返す。
8. 最後に `nix/packages.nix` から `mise` を削除する。

### 7.3 Node/pnpm プロジェクト用 flake template

```nix
{
  description = "Project development shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs systems (
          system:
          f import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          }
        );
    in
    {
      devShells = forAllSystems (
        pkgs:
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              nodejs_24
              pnpm
              just
              jq
              ripgrep
            ];
          };
        }
      );
    };
}
```

AWS CDK を使う場合は追加:

```nix
awscli2
```

Kubernetes を使う場合は追加:

```nix
kubectl
```

### 7.4 Python プロジェクト用 flake template

```nix
{
  description = "Python development shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs {
        inherit system;
      };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          python313
          uv
          just
        ];
      };
    };
}
```

### 7.5 プロジェクト移行完了条件

プロジェクトごとに、該当するコマンドが `mise activate` なしで通ることを確認します。

```bash
nix develop
node --version
pnpm --version
python --version
uv --version
pnpm install --frozen-lockfile
pnpm test
pnpm build
```

存在しない script は実行しません。実際にそのプロジェクトで使っているコマンドを確認してから検証します。

## 8. macOS 移行後の日常運用

### 8.1 CLI を追加・削除する

編集:

```text
~/.config/nix-darwin/nix/packages.nix
```

適用:

```bash
darwin-rebuild switch --flake "$HOME/.config/nix-darwin#macbook"
```

commit:

```bash
cd "$HOME/.config/nix-darwin"
git status
git add nix/packages.nix
git commit -m "chore: update nix packages"
git push
```

### 8.2 GUI アプリを追加・削除する

編集:

```text
~/.config/nix-darwin/nix/apps.nix
```

適用:

```bash
darwin-rebuild switch --flake "$HOME/.config/nix-darwin#macbook"
```

ルール:

```text
GUI は Homebrew cask。
CLI は Nix。
例外は理由をドキュメントに残す。
```

### 8.3 Nix inputs を更新する

```bash
cd "$HOME/.config/nix-darwin"
nix flake update
darwin-rebuild switch --flake "$HOME/.config/nix-darwin#macbook"
git status
git add flake.lock
git commit -m "chore: update nix flake inputs"
git push
```

`flake.lock` は初回 Nix 評価後に生成されます。生成されたら必ず commit します。

### 8.4 rollback

世代一覧:

```bash
darwin-rebuild --list-generations
```

直前世代へ rollback:

```bash
darwin-rebuild --rollback
```

Git 変更が原因なら:

```bash
cd "$HOME/.config/nix-darwin"
git log --oneline
git revert <bad-commit>
darwin-rebuild switch --flake "$HOME/.config/nix-darwin#macbook"
```

ローカル変更を失うため、`git reset --hard` は安易に使いません。

## 9. 検証チェックリスト

### 9.1 Nix / darwin

```bash
nix --version
nix flake show "$HOME/.config/nix-darwin"
darwin-rebuild --help
```

期待:

```text
flake に darwinConfigurations.macbook が見える。
darwin-rebuild が使える。
```

### 9.2 shell

```bash
echo "$SHELL"
zsh -lic 'echo ok'
zsh -lic 'alias cdx'
zsh -lic 'which rg'
```

期待:

```text
zsh が起動する。
WSL 固有 PATH エラーが出ない。
rg が Nix profile から解決される。
```

### 9.3 git / GitHub

```bash
git config --global user.name
git config --global user.email
git config --global --get-all credential.https://github.com.helper
gh auth status
```

期待:

```text
user.name が k-adachi-01。
user.email が sewaniwa@gmail.com。
credential helper が gh auth git-credential。
gh が authenticated。
```

### 9.4 開発ツール

```bash
node --version
pnpm --version
python --version
uv --version
rustup --version
just --version
direnv --version
```

期待:

```text
全て存在する。
node は v24 系。
uv が使える。
```

### 9.5 Cloud / infra

```bash
aws --version
gcloud --version
az version
kubectl version --client
```

期待:

```text
全て存在する。
認証が必要なコマンドはログイン後に通る。
```

### 9.6 GUI

```bash
ls -d /Applications/OrbStack.app
ls -d "/Applications/Visual Studio Code.app"
ls -d /Applications/WezTerm.app
```

期待:

```text
3つとも存在する。
```

## 10. 既知の未完了事項

### 10.1 WSL 上では Nix 検証未実行

現在の WSL には `nix` がないため、以下は未実行です。

```text
nix flake check
nix flake show
darwin-rebuild switch
```

新 Mac 側で必ず実行します。

### 10.2 flake.lock

現時点では `flake.lock` がまだない可能性があります。初回 Nix 評価後に生成されたら commit します。

```bash
cd "$HOME/.config/nix-darwin"
git status
git add flake.lock
git commit -m "chore: lock nix inputs"
git push
```

### 10.3 フォント

WezTerm 設定では以下のフォントが参照されています。

```text
PlemolJP Console NF
JetBrains Mono
Segoe UI Symbol
Segoe UI Emoji
```

macOS には Windows フォントが存在しないため、初回 switch 後に見た目を確認します。

必要な対応:

```text
Nix で入れられるフォントを追加する。
Nix で難しいフォントだけ Homebrew cask を検討する。
WezTerm の fallback を macOS 向けに調整する。
```

### 10.4 Codex / Claude

zsh alias は以下を参照します。

```text
claude
codex
```

現在の Nix package set ではこれらを入れていません。

初回対応:

```text
各ツールの公式手順、または pnpm global で暫定導入する。
Nix 化は後続タスクにする。
```

### 10.5 AWS SAM / ngrok / Ollama

初回対象外:

```text
aws-sam-cli
ngrok
ollama
```

追加基準:

```text
実際に必要なプロジェクトがある。
Nix package として安定して使える。
または GUI/service として別管理する理由がある。
```

### 10.6 WSL 互換 dotfiles の扱い

以下は初回 Nix 構成追加とは別に整理した WSL 互換設定です。

```text
home/bashrc
home/wezterm/linux.lua
home/wezterm/darwin.lua
home/config/nvim/init.lua
home/config/nvim/lua/plugins/thino.lua
```

現在の扱い:

```text
home/bashrc は WSL 互換用として維持し、macOS では原則配置しない。
WezTerm は home/wezterm/linux.lua と home/wezterm/darwin.lua に分ける。
Neovim の win32yank は Windows/WSL かつ実行ファイルがある場合だけ使う。
Thino の Obsidian vault は OBSIDIAN_VAULT または ~/obsidian を使う。
macOS で不要な WSL 固有コマンドは、存在確認または OS 判定の内側に閉じ込める。
```

## 11. 障害対応

### 11.1 flake が見つからない

確認:

```bash
ls -la "$HOME/.config/nix-darwin/flake.nix"
```

なければ再取得:

```bash
mkdir -p "$HOME/.config"
git clone https://github.com/k-adachi-01/dotfiles.git "$HOME/.config/nix-darwin"
```

### 11.2 username が違う

症状:

```text
/Users/adachi を設定しようとして失敗する。
```

対応:

```text
flake.nix の username を実際の macOS ユーザー名に変える。
nix/home.nix と nix/darwin.nix の home path 前提を確認する。
再度 darwin-rebuild する。
```

### 11.3 Homebrew cask が失敗する

確認:

```bash
brew --version
brew list --cask
```

一つの cask だけ失敗する場合:

```text
nix/apps.nix から一時的にその cask を外す。
darwin-rebuild を通す。
原因を別途調べる。
```

CLI を Homebrew formula に逃がさないこと。

### 11.4 home-manager と既存ファイルが衝突する

設定済み:

```nix
home-manager.backupFileExtension = "hm-backup";
```

衝突時は `*.hm-backup` が作られる想定です。削除する前に中身を確認します。

### 11.5 Cloud CLI の認証エラー

認証エラーは Nix の失敗ではなく、ローカル credential 未移行が原因であることが多いです。

再ログイン:

```bash
gh auth login
aws configure sso
gcloud auth login
az login
```

### 11.6 プロジェクトが mise なしで動かない

短期対応:

```bash
mise install
mise activate zsh
```

長期対応:

```text
project-local flake.nix を追加する。
必要な Node/Python/Rust/tool を devShell に入れる。
既存コマンドが通ったら mise 依存を外す。
```

## 12. これまで実施したこと

この章は、移行作業の履歴を引き継ぐための記録です。新 Mac 側で作業する人は、ここを読めば「このPCで何が終わっていて、何がまだ実機待ちか」を判断できます。

### 12.1 Nix 構成の追加

実施済みコミット:

```text
5bd194b feat: add macos nix configuration
```

追加したもの:

```text
flake.nix
nix/apps.nix
nix/darwin.nix
nix/home.nix
nix/packages.nix
```

内容:

```text
Apple Silicon Mac 用の darwinConfigurations.macbook を定義した。
nix-darwin / home-manager / nix-homebrew を導入した。
Homebrew は GUI cask だけに制限した。
GUI cask は orbstack / visual-studio-code / wezterm のみにした。
CLI と開発ツールは nix/packages.nix に集約した。
zsh / git / fzf / tmux / direnv を home-manager 管理にした。
mise は初回移行用に一時的に残した。
GitHub credential helper の /usr/bin/gh 固定をやめ、gh auth git-credential にした。
```

この段階でまだ未実施だったもの:

```text
nix flake check
darwin-rebuild switch
flake.lock 生成
Homebrew cask の実インストール
新 Mac での zsh / WezTerm / OrbStack / VS Code 実機確認
```

理由:

```text
このWSL環境には nix / darwin-rebuild がない。
darwin-rebuild は macOS でしか意味のある検証ができない。
```

### 12.2 移行 Runbook の追加

実施済みコミット:

```text
1dfdf25 docs: add macos nix migration runbook
```

追加したもの:

```text
docs/macos-nix-migration.md
README.md から Runbook へのリンク
```

内容:

```text
現 WSL 環境の棚卸しを記録した。
apt / mise / pnpm global / 手動バイナリ / Windows連携の扱いを記録した。
新 Mac 初回セットアップ手順を記録した。
mise 廃止手順を記録した。
Node/pnpm project と Python project の flake template を記録した。
検証チェックリスト、障害対応、完了条件を記録した。
```

### 12.3 shell / WezTerm / Neovim の移行安全化

実施済みコミット:

```text
f3620e1 chore: clean up migration shell config
```

変更したもの:

```text
dot_bashrc
dot_wezterm.lua.tmpl
dot_config/nvim/init.lua
dot_config/nvim/lua/plugins/thino.lua
```

内容:

```text
bash の cdx alias を codex に統一した。
bash の Windows Obsidian alias は実体がある場合だけ定義するようにした。
WezTerm の /proc / readlink -f 参照を Linux/WSL 分岐内に閉じ込めた。
WezTerm の leader+n / leader+c を nvim . + codex 起動へ統一した。
WezTerm の ANSI green 調整を維持した。
Neovim の win32yank clipboard 設定を Windows/WSL かつ win32yank.exe がある場合だけ有効にした。
Neovim Thino の vault path を /mnt/c 固定から OBSIDIAN_VAULT または ~/obsidian に変更した。
```

確認したこと:

```text
chezmoi execute-template で WezTerm の Linux 想定レンダリングが成功した。
chezmoi execute-template で WezTerm の macOS 想定レンダリングが成功した。
macOS 想定 WezTerm レンダリングに /proc / readlink -f /mnt/c /usr/bin/gh / win32yank / ime_toggle が出ないことを確認した。
git diff --check が通ることを確認した。
```

未実施:

```text
WezTerm 実機起動確認。
Neovim の LazyVim 実機起動確認。
フォント表示確認。
codex / claude 実体の導入確認。
```

### 12.4 Runbook の引き継ぎ状態更新

実施済みコミット:

```text
c1cf33a docs: update macos migration handoff status
```

内容:

```text
このPCで実施済みの移行準備を記録した。
このPCでは意図的に実施しない作業を明記した。
.mise.toml / package.json / pyproject.toml の棚卸し結果を追記した。
WSL 互換 dotfiles の扱いを更新した。
```

### 12.5 chezmoi 撤退と home-manager 集約

実施内容:

```text
chezmoi 固有の dot_ / symlink_ ファイルを通常ファイルツリー home/ へ移動した。
WezTerm はテンプレートではなく home/wezterm/linux.lua と home/wezterm/darwin.lua に分離した。
Neovim は home/config/nvim として home-manager の xdg.configFile で配置するようにした。
AGENTS / CLAUDE 設定は home/ai を単一ソースとして home.file で複数箇所へ配置するようにした。
README を git clone + darwin-rebuild 前提に更新した。
AGENTS.md の dotfiles 管理方針を chezmoi から Nix/home-manager に更新した。
```

### 12.6 現在の dotfiles 状態

この Runbook 更新時点で、dotfiles repository の最新主要コミットは以下です。

```text
c1cf33a docs: update macos migration handoff status
f3620e1 chore: clean up migration shell config
1dfdf25 docs: add macos nix migration runbook
5bd194b feat: add macos nix configuration
```

作業ツリーは clean であることを確認済みです。

## 13. 懸念点一覧

この章は、新 Mac への移行で問題になり得る点を漏れなく確認するためのリスク一覧です。解決済みのもの、意図的に後回しにしたもの、Mac 実機でしか検証できないものを分けて扱います。

### 13.1 最重要リスク

| 懸念点 | 状態 | 対応 |
|---|---|---|
| `flake.nix` が Mac 実機で未検証 | 未解決 | 新 Mac で `darwin-rebuild switch` を実行する |
| `flake.lock` がまだない | 未解決 | 初回 Nix 評価後に commit/push する |
| macOS ユーザー名を `adachi` 固定にしている | 未確認 | 新 Mac で `whoami` を確認し、違えば `flake.nix` を修正する |
| Nix / home-manager への集約はMac実機未確認 | 継続リスク | 新 Mac で生成ファイルと起動確認を行う |
| 主要プロジェクトがまだ mise 依存 | 未解決 | project-local `flake.nix` へ順次移行する |

### 13.2 Nix / nix-darwin の懸念

| 懸念点 | 状態 | 対応 |
|---|---|---|
| `nixpkgs-unstable` を使っている | 意図的 | `flake.lock` で固定する |
| `home.stateVersion = "25.05"` が実行時 home-manager と合うか未確認 | 未確認 | 新 Mac の `darwin-rebuild` エラーで確認する |
| `system.stateVersion = 6` が nix-darwin と合うか未確認 | 未確認 | 新 Mac の `darwin-rebuild` エラーで確認する |
| `nix-homebrew` 初回 bootstrap が未検証 | 未確認 | 新 Mac で Homebrew cask 導入を確認する |
| cask 名 `orbstack` / `visual-studio-code` / `wezterm` が取得可能か未確認 | 未確認 | 新 Mac で `brew list --cask` を確認する |
| Xcode Command Line Tools が必要になる可能性 | 未確認 | 要求されたら `xcode-select --install` を実行する |
| Apple Silicon 前提 | 固定 | Intel Mac の場合は `system` を変更する |

### 13.3 shell / PATH の懸念

| 懸念点 | 状態 | 対応 |
|---|---|---|
| macOS では zsh 主運用になる | 意図的 | bash は WSL 互換用として残す |
| `.bashrc` はLinux/WSLのみ配置する設計 | 一部対応済み | 新 Mac で `.bashrc` が不要に生成されないことを確認する |
| `PNPM_HOME = "$HOME/Library/pnpm"` が pnpm 実挙動と合うか未確認 | 未確認 | 新 Mac で `pnpm setup` / `pnpm root -g` を確認する |
| `cc` / `ca` / `cdx` alias の実体が未導入 | 未解決 | `claude` / `codex` を別途導入する |
| Neovim の外部依存が不足する可能性 | 未確認 | LazyVim 起動後に missing tool を追加する |

### 13.4 WezTerm / GUI の懸念

| 懸念点 | 状態 | 対応 |
|---|---|---|
| WezTerm 実機起動が未確認 | 未解決 | 新 Mac で起動し、pane split / cwd / tab title を確認する |
| フォントが未整備 | 未解決 | `PlemolJP Console NF` / Nerd Font / emoji fallback を確認する |
| Windows フォント `Segoe UI` は macOS にない | 既知 | WezTerm font fallback を macOS 向けに調整する |
| OrbStack と Docker Desktop の挙動差 | 未確認 | Docker context / compose / volume / Kubernetes を確認する |
| VS Code / Cursor / Antigravity settings | 対応済み | `nix/editors.nix` で macOS User settings/keybindings を配置する |
| VS Code / Cursor / Antigravity extension 実体 | 意図的に未移行 | `home/editors/extensions.json` に ID manifest だけ保存する |

### 13.5 認証 / secrets の懸念

| 懸念点 | 状態 | 対応 |
|---|---|---|
| GitHub CLI 認証は再ログインが必要 | 既知 | `gh auth login` |
| AWS 認証は再設定が必要 | 既知 | `aws configure sso` |
| GCP 認証は再ログインが必要 | 既知 | `gcloud auth login` |
| GCP ADC が必要な場合は別ログインが必要 | 既知 | `gcloud auth application-default login` |
| Azure 認証は再ログインが必要 | 既知 | `az login` |
| SSH key 移行方針が未決定 | 未解決 | 新規発行または安全な鍵移行を選ぶ |
| GPG / commit signing が未整理 | 未解決 | SSH signing または GPG key 移行を検討する |
| dotenvx private key を移してはいけない | 重要 | secret store から安全に注入する |

### 13.6 プロジェクト移行の懸念

| 懸念点 | 状態 | 対応 |
|---|---|---|
| `.mise.toml` が複数プロジェクトに残っている | 未解決 | 使用頻度順に project flake 化する |
| Node 24 が全プロジェクトに合うとは限らない | 既知 | project-local `flake.nix` で個別固定する |
| Python 3.13 が全プロジェクトに合うとは限らない | 既知 | project-local `flake.nix` で個別固定する |
| Rust は `rustup` 依存のまま | 意図的暫定 | 必要なら `fenix` / `rust-overlay` を検討する |
| Dioxus CLI が Nix package set にない | 未解決 | Dioxus project 移行時に追加判断する |
| Playwright / browser automation の依存が未確認 | 未解決 | macOS 実機で browser install / permission を確認する |
| CDK / AWS 系プロジェクトの追加依存が未確認 | 未解決 | project 移行時に `awscli2`, Docker, CDK 周辺を確認する |

### 13.7 pnpm global / AI tools の懸念

| 懸念点 | 状態 | 対応 |
|---|---|---|
| pnpm global tools をまだ再現していない | 未解決 | 必要になった順に一時導入する |
| `@openai/codex` の導入方法が未固定 | 未解決 | 公式手順または pnpm global で暫定導入する |
| `agent-browser` / `dev-browser` が未導入 | 未解決 | browser automation が必要になった時点で導入する |
| MCP / Google Workspace 系 CLI が未整理 | 未解決 | 常用性を確認して project-local へ寄せる |
| Claude / Codex の credential/cache は dotfiles 管理外 | 既知 | 新 Mac で再認証する |

### 13.8 dotfiles / home-manager の懸念

| 懸念点 | 状態 | 対応 |
|---|---|---|
| `.gitconfig` は home-manager 管理へ集約済み | 対応済み | 新 Mac で `git config --global` を確認する |
| `.mise.toml` は home-manager で暫定配置する | 既知 | mise 廃止時に `home/mise.toml` と配置設定を削除する |
| Neovim 設定は macOS 実機未確認 | 未確認 | 新 Mac で LazyVim 起動確認を行う |
| AGENTS / CLAUDE / Codex 関連配置が macOS で未確認 | 未確認 | home-manager適用後に対象パスを確認する |
| WSL 互換設定が残っている | 意図的 | OS 判定・存在確認の内側に閉じ込める |

### 13.9 データ移行の懸念

| 懸念点 | 状態 | 対応 |
|---|---|---|
| `/home/adachi/src` など作業ディレクトリは dotfiles では移行されない | 未解決 | 必要な repo を新 Mac で clone する |
| Obsidian vault が Windows path 前提だった | 一部対応済み | `OBSIDIAN_VAULT` または `~/obsidian` を新 Mac で用意する |
| `.aws` / `.azure` / `.config/gcloud` は移行しない | 意図的 | 新 Mac で再ログインする |
| `.ssh` / `.gnupg` の移行方針が未決定 | 未解決 | 新規作成または安全な移行を選ぶ |
| cache / node_modules / mise installs は移行しない | 意図的 | 新 Mac で再構築する |

### 13.10 macOS 固有の懸念

| 懸念点 | 状態 | 対応 |
|---|---|---|
| Gatekeeper / 権限許可が必要になる可能性 | 未確認 | 初回起動時に許可する |
| FileVault / Keychain / Touch ID 統合が未設計 | 未解決 | SSH key / signing / secrets 方針と合わせて決める |
| 日本語入力設定が未移行 | 未解決 | macOS 設定または Karabiner 等を検討する |
| キーボード設定が未移行 | 未解決 | JIS/US, CapsLock, Command/Control, IME toggle を確認する |
| Finder / Dock 設定は最小限 | 意図的 | 使用しながら nix-darwin defaults に追加する |
| Time Machine / backup 方針が未記載 | 未解決 | 新 Mac セットアップ後に決める |

### 13.11 パッケージ不足の懸念

初回 Nix package set に入れていないもの:

```text
ngrok
aws-sam-cli
ollama
mdcat
stow
dotenvx
biome
vercel
dioxus-cli
fonts
```

扱い:

```text
常用が確認できたものだけ追加する。
プロジェクト固有のものは project-local flake.nix または devDependency に寄せる。
CLI を Homebrew formula に逃がさない。
```

## 14. 優先順位

新 Mac での作業はこの順番で進めます。

1. `whoami` が `adachi` か確認する。
2. Nix をインストールする。
3. `git clone` で `~/.config/nix-darwin` に dotfiles を取得する。
4. 初回 `nix run ... darwin-rebuild -- switch --flake ~/.config/nix-darwin#macbook` を実行する。
5. `flake.lock` を生成し、commit/push する。
6. WezTerm / fonts / zsh / Neovim を確認する。
7. `claude` / `codex` の導入方法を決める。
8. GitHub / AWS / GCP / Azure に再ログインする。
9. VS Code / Cursor / Antigravity settings を確認する。
10. Obsidian vault の配置を決め、`OBSIDIAN_VAULT` を設定する。
11. 一番よく使う Node/pnpm project を1つ project-local flake 化する。
12. AWS/CDK project、Python project、browser automation project の順に flake 化する。
13. 主要 project が mise なしで動くことを確認する。
14. `nix/packages.nix` から `mise` を削除する。
15. Homebrew cask が本当に GUI アプリだけになっていることを確認する。

## 15. 完了条件

移行完了は、以下を全て満たした状態です。

```text
新 Mac で darwin-rebuild switch --flake ~/.config/nix-darwin#macbook が通る。
主要 CLI が Nix から解決される。
Homebrew は承認済み GUI cask だけを管理している。
zsh が WSL 固有エラーなしで起動する。
GitHub / AWS / GCP / Azure の認証が必要範囲で完了している。
主要プロジェクトに project-local flake.nix がある。
主要プロジェクトが mise なしで動く。
nix/packages.nix から mise が削除されている。
flake.lock が commit されている。
WSL 固有 PATH、Windows helper、apt 前提が macOS の日常開発経路から消えている。
```

初回 `darwin-rebuild` が成功しただけでは完了ではありません。最終ゴールは、WSL・apt・mise に依存せず、Mac 上で主要プロジェクトを再現可能に開発できる状態です。

## 16. AI Agent / MCP / Skills の完全 Nix 管理

Claude Code / Codex / Cursor / Kiro の user-level 設定、共通 skills、MCP 定義は `nix/agents.nix` に集約します。

### 16.1 Nix で管理するもの

home-manager が以下を配置します。

```text
~/.agents/AGENTS.md
~/.agents/skills
~/.claude/AGENTS.md
~/.claude/CLAUDE.md
~/.claude/skills
~/.claude/settings.json
~/.claude/keybindings.json
~/.claude/.mcp.json
~/.claude/statusline.py
~/.claude/notify-done.sh
~/.codex/AGENTS.md
~/.codex/config.toml
~/.codex/rules/default.rules
~/.codex/notify.sh
~/.codex/skills/browser-use-local
~/.codex/skills/vercel-react-best-practices
~/.codex/skills/wezterm-config-sync
~/.cursor/AGENTS.md
~/.cursor/skills
~/.cursor/cli-config.json
~/.cursor/statusline.sh
~/.kiro/powers.json
~/.kiro/powers.mcp.json
~/.kiro/settings/
~/.kiro/powers/
```

共通 skills は private repo のローカル checkout `~/agent-skills` を flake input として取り込みます。
Nix store 上へコピーされた source を `~/.agents/skills`, `~/.claude/skills`, `~/.cursor/skills` へ symlink します。

### 16.2 Nix で管理しないもの

以下は移行しません。新 Mac で各 tool の認証 flow を使って再作成します。

```text
~/.claude/.credentials.json
~/.claude/projects/
~/.claude/sessions/
~/.claude/cache/
~/.claude/statsig/
~/.codex/auth.json
~/.codex/history.jsonl
~/.codex/sessions/
~/.codex/state_*.sqlite*
~/.codex/logs_*.sqlite*
~/.codex/skills/.system/
~/.cursor/chats/
~/.cursor/projects/
~/.cursor/worktrees/
~/.config/cursor/auth.json
~/.kiro/sessions/
~/.kiro/.cli_bash_history
```

### 16.3 MCP 定義の方針

- MCP server 定義は Nix から JSON を生成します。
- secret 値は JSON に直書きしません。
- AWS は `AWS_PROFILE` / `AWS_REGION` と通常の AWS credential chain に任せます。
- Node MCP は `npx` ではなく `pnpm dlx` を使います。
- Python MCP は `uv` / `uvx` を使います。
- ローカル project を参照する MCP は `${HOME}` 配下の macOS path を Nix で生成します。

### 16.4 Skill 更新手順

1. `k-adachi-01/agent-skills` を編集する。
2. `.claude/`, cache, workspace, secret が入っていないことを確認する。
3. `agent-skills` repo を commit / push する。
4. dotfiles repo で `nix flake lock --update-input agent-skills` を実行し、local path input の lock を更新する。
5. `darwin-rebuild switch --flake ~/.config/nix-darwin#macbook` を実行する。

### 16.5 Antigravity

Windows 側では `AppData/Roaming/Antigravity/User/settings.json` が存在したが、内容は `{}` でした。
Mac 側では VS Code / Cursor と同じ editor settings を `nix/editors.nix` から配置します。

## 17. Windows 側から取り込んだ設定

Windows 側の設定は、Mac 移行後の日常運用に使うものと、Windows fallback 用に保存するものを分けます。

### 17.1 macOS にも反映する設定

`nix/editors.nix` で以下を生成します。

```text
~/Library/Application Support/Code/User/settings.json
~/Library/Application Support/Cursor/User/settings.json
~/Library/Application Support/Cursor/User/keybindings.json
~/Library/Application Support/Antigravity/User/settings.json
~/Library/Application Support/Antigravity/User/keybindings.json
~/Library/Application Support/Antigravity IDE/User/settings.json
~/Library/Application Support/Antigravity IDE/User/keybindings.json
```

取り込んだ主な内容:

- VSCodeVim の `jj` escape、leader、検索、key handling
- PlantUML server 設定
- Copilot chat の日本語 locale
- Cursor の `ctrl+i` agent mode keybinding
- Cursor の terminal `shift+enter` 継続入力
- Markdown / Docker Compose / GitHub Actions の editor 設定
- Cursor MCP: Playwright、AWS documentation、AWS knowledge、context7
- Kiro MCP: AWS SAM、AWS observability、IAM policy autopilot、AgentCore

### 17.2 Windows fallback 用に保存した設定

```text
home/wezterm/windows.lua
windows/terminal/settings.json
windows/wsl/.wslconfig
```

`home/wezterm/windows.lua` は Windows 側で調整した WezTerm 設定の実体です。
Mac では `home/wezterm/darwin.lua` を使い、Windows を継続利用する場合だけこの file を Windows home へ配置します。

### 17.3 取り込まないもの

以下は commit しません。

- VS Code / Cursor / Antigravity / Kiro の extension 実体
- `globalStorage`, `workspaceStorage`, `History`, `Cache`
- `argv.json` の crash reporter id
- agent の auth / credential / session / project state
- Windows registry hive (`NTUSER.DAT`)
