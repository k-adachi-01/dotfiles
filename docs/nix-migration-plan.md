# Nix 移行計画

Last updated: 2026-07-04

このドキュメントは [`docs/nix-management-inventory.md`](nix-management-inventory.md) のバックログを、**小さなステップ + 各ステップでの検証** という方針で実行可能な移行計画に落としたものです。

関連ドキュメント:

| ドキュメント | 役割 |
|---|---|
| [`nix-management-inventory.md`](nix-management-inventory.md) | 現状棚卸し（何が管理済み / 候補 / 意図的除外か） |
| [`management-policy.md`](management-policy.md) | クラスA/B/C 分類と AI エージェント設定の唯一の判断基準 |
| [`macos-nix-migration.md`](macos-nix-migration.md) | WSL → 新 Mac 初回 bootstrap（本計画とは別フェーズ） |

## 1. ゴールと非ゴール

### ゴール

- 再現性と日常の信頼性が高い設定だけを Nix に取り込む。
- 各変更は **1 PR / 1 論点** に分割し、適用前後で必ず検証する。
- 秘密情報・ランタイム状態・ベンダー管理の更新ジョブを repo に混入させない。

### 非ゴール

- ホームディレクトリ全体を Nix 化すること。
- アプリが書き続ける plist / SQLite / キャッシュを一括 symlink すること。
- 低使用・検証用リポジトリすべてに flake を追加すること。
- `local.nix` のような Git 管理外オーバーレイ（pure flake では成立しない）。

## 2. 基本原則

### 2.1 分類を先に決める

[`management-policy.md`](management-policy.md) の基準をそのまま使う。

| 分類 | 移行時の扱い |
|---|---|
| **宣言的で安定** | Nix attrset / `home.file` / class A merge |
| **読み取り専用アセット** | class B `mkLink`（`.source = mkLink "home/..."` 必須） |
| **アプリが書くが構造が安全** | class A merge（宣言キーのみ repo、宣言外は live に残す） |
| **秘密・履歴・キャッシュ** | 管理外のまま |

判断に迷ったら **Nix 化しない**。inventory の「Intentionally Not Managed」を優先する。

### 2.2 1 ステップ = 1 論点 + 検証セット

各ステップは次の形に統一する。

1. **スコープ**: 触るファイルと生成先パスを明示
2. **事前検証**: 現状スナップショット（read-only）
3. **変更**: repo のみ編集（`~/.codex` 等の live ファイルは直接編集しない）
4. **ビルド検証**: `nix build`（sudo 不要）
5. **適用**: `sudo darwin-rebuild switch --flake ~/.config/nix-darwin#macbook`
6. **事後検証**: ステップ専用チェック + 共通チェック
7. **記録**: inventory / 本計画の進捗表を更新

### 2.3 共通検証（毎ステップ末尾）

```bash
# ビルド（適用前、破壊的変更の前に必ず）
nix build '.#darwinConfigurations.macbook.system' --no-link

# lint（コミット前）
alejandra --check . && statix check . && deadnix --fail .

# 適用（この Mac では sudo 必須）
sudo darwin-rebuild switch --flake ~/.config/nix-darwin#macbook

# class A ファイルの drift 確認（read-only）
agents-diff

# class B symlink 退行チェック（store コピー化の検出）
readlink -f ~/.codex/AGENTS.md
readlink -f ~/.claude/AGENTS.md
readlink -f ~/.cursor/AGENTS.md
readlink -f ~/.agents/AGENTS.md
# いずれも ~/.config/nix-darwin/home/... を指すこと（/nix/store の実ファイルを指さない）

# 作業ツリー
git status --short --branch
```

**ロールバック**: 問題があれば `sudo darwin-rebuild --rollback` または `git revert` → 再 switch。

### 2.4 PR / コミット粒度

- 1 ステップ = 原則 1 PR（レビューと bisect を容易にする）
- macOS defaults は **ドメイン単位**（keyboard / trackpad / Mission Control など）で分割
- GUI アプリ設定は **1 アプリ 1 PR** が上限

### 2.5 `darwin-rebuild switch` 運用（2026-07-04 更新）

| 項目 | 方針 |
|---|---|
| 実行場所 | 初回・権限まわりで詰まるときは **Terminal.app** から実行（Cursor 統合ターミナルは App Management ダイアログが届かないことがある） |
| sudo | この Mac では必須: `sudo darwin-rebuild switch --flake ~/.config/nix-darwin#macbook` |
| App Management 再プロンプト | `90943e8` で `/Applications/Nix Apps` の `.app` を activation 前後に削除。GUI アプリは **Homebrew cask のみ**（Zed 含む）。`.app` バンドル付き Nix パッケージは入れない |
| merge 失敗 | `merge-agent-config` は全 class A で共通。`pyjson5` の import 名ミス（`json5` ではない）で全 merge が止まる → `0c4701b` 参照 |
| 検証 | switch 成功後に `agents-diff` と、当該ステップの専用チェック |

---

## 3. フェーズ概要

| フェーズ | 内容 | 優先度 | inventory 参照 |
|---|---|---|---|
| **0** | ベースライン固定 | — | 全体 |
| **1** | Shell / dotfile 境界の整理 | 高 | §4 Shell / Dotfile Gaps |
| **2** | 開発ツール設定の分離 | 高 | §5 Developer Tool State |
| **3** | macOS システム設定の追加 | 中〜高 | §1 macOS System Settings |
| **4** | GUI アプリ設定（選択的） | 低〜中 | §3 GUI App Configuration |
| **5** | ユーザー所有 launchd | 低 | §2 Launch Agents |
| **6** | プロジェクト flake 化 / mise 廃止 | 変動 | §6 Project-Local Manifests |

---

## 4. フェーズ 0 — ベースライン固定

**目的**: 移行前の「正常状態」を記録し、以降の diff の基準にする。

### ステップ 0.1 — リポジトリと live 環境のスナップショット

| 項目 | 内容 |
|---|---|
| 触るファイル | なし（read-only） |
| 作業 | inventory 更新日と一致していることを確認 |

```bash
cd ~/.config/nix-darwin
git status --short --branch
nix build '.#darwinConfigurations.macbook.system' --no-link
agents-diff | tee /tmp/agents-diff-baseline.txt
defaults read com.apple.dock 2>/dev/null | head
defaults read com.apple.finder 2>/dev/null | head
ls ~/.local/bin 2>/dev/null
```

**合格条件**

- `nix build` が成功
- `agents-diff` がエラーなく完走
- 未コミット変更の意図が説明できる（または clean）

### ステップ 0.2 — 管理済み領域の回帰テスト

AI エージェント + エディタ merge は PR6〜PR11 で完了済み。大きな変更の前に **回帰なし** を確認する。

```bash
# merge 対象が通常ファイルであること（symlink ではない class A）
file ~/.codex/config.toml ~/.claude/settings.json ~/.cursor/cli-config.json
file ~/Library/Application\ Support/Cursor/User/settings.json

# Kiro permissions が Codex rules から生成されていること
yq '.rules | length' ~/.kiro/settings/permissions.yaml

# skills パス
readlink -f ~/.claude/skills/dotfiles-nix-maintenance 2>/dev/null || true
test -f ~/.codex/skills/dotfiles-nix-maintenance/SKILL.md 2>/dev/null || true
```

**合格条件**: 上記が inventory「Already Managed」の記述と一致。

---

## 5. フェーズ 1 — Shell / dotfile 境界（優先度: 高）

**目的**: 「Nix が生成したもの」と「ツールが生成したもの」の境界を明確化する。inventory §4。

### ステップ 1.1 — `~/.local/bin` 棚卸し

| 項目 | 内容 |
|---|---|
| 触るファイル | 調査のみ → 必要なら `nix/agents/default.nix` / `nix/home.nix` |
| 分類 | repo 所有 script → home-manager 生成、それ以外 → 触らない |

```bash
ls -la ~/.local/bin
for f in ~/.local/bin/*; do
  echo "=== $f ==="
  file "$f"
  head -3 "$f" 2>/dev/null
done
```

**期待する分類**

| ファイル | 扱い |
|---|---|
| `agents-diff`, `skills-push` | 既に Nix 管理（`nix/agents/default.nix`） |
| その他 | 調査。恒久設定なら repo へ、一時バイナリなら `nix/packages.nix` 候補 |

**変更後検証**

```bash
test -x ~/.local/bin/agents-diff && agents-diff >/dev/null
# 新規追加 script があれば実行テスト
zsh -lic 'echo $PATH' | tr ':' '\n' | grep -E 'local/bin|nix-profile'
```

### ステップ 1.2 — `.zprofile` の ad hoc 統合の整理

| 項目 | 内容 |
|---|---|
| 触るファイル | `nix/home.nix`（`.zprofile` テキスト） |
| 方針 | OrbStack / kiro-cli 等、Nix または cask で入るものだけ残す |

**事前**

```bash
cat ~/.zprofile
diff -u <(grep -v nix-daemon ~/.zprofile 2>/dev/null || true) /dev/null || true
```

**1 行ずつ削除する場合**: 削除 → `nix build` → `switch` → `zsh -lic 'type kiro-cli; type docker'` で機能確認。

**合格条件**

- 新しい login shell でエラーなし
- 削除した統合が本当に不要、または Nix/cask 側で代替済み

### ステップ 1.3 — ランタイム状態の明示的除外（ドキュメントのみ）

| 項目 | 内容 |
|---|---|
| 触るファイル | 本計画 + inventory（必要なら） |
| 管理しないもの | `~/.zsh_history`, `~/.zsh_sessions`, `~/.zcompdump*`, `~/.nix-profile`, `~/.nix-defexpr` |

**検証**: これらのパスを `home.file` に追加していないことを確認。

```bash
rg 'zsh_history|zcompdump|nix-profile' nix/
```

**合格条件**: ヒットなし（または意図的コメントのみ）。

### ステップ 1.4 — `~/.mise.toml` の位置づけ固定

| 項目 | 内容 |
|---|---|
| 現状 | `home/mise.toml` → `~/.mise.toml`（移行期互換） |
| 触るファイル | 変更なし（フェーズ 6 まで維持） |

```bash
readlink -f ~/.mise.toml
mise --version
mise ls 2>/dev/null | head
```

**合格条件**: mise は動くが、新規ツール追加は project flake を優先（AGENTS.md 方針）。

---

## 6. フェーズ 2 — 開発ツール設定の分離（優先度: 高）

**目的**: 設定・秘密・キャッシュを分離し、安全なファイルだけ Nix 候補にする。inventory §5。

### ステップ 2.1 — 候補ディレクトリの read-only 監査

各パスについて **中身の種類** を記録する（1 パス 1 コミットのメモでよい）。

```bash
for d in \
  ~/.config/zed \
  ~/.browser-use-config \
  ~/.agent-browser \
  ~/.orbstack \
  ~/.docker \
  ~/.iam-policy-autopilot \
  ; do
  echo "======== $d ========"
  find "$d" -maxdepth 2 -type f 2>/dev/null | head -20
done
```

**分類テンプレート**（各パスに記入）

| パス | 設定ファイル | 秘密 | キャッシュ/DB | 判定 |
|---|---|---|---|---|
| `~/.config/zed/settings.json` | JSON | 低 | 別 dir | **class A 候補** |
| `~/.docker/config.json` | JSON | **高** | — | **管理しない** |
| `~/.orbstack/...` | 要調査 | 中 | VM 状態 | 設定のみ候補 |
| `~/.browser-use-config` | 要調査 | 高 | プロファイル | 設定のみ、プロファイル除外 |

### ステップ 2.2 — Zed `settings.json`（第一候補）

| 項目 | 内容 |
|---|---|
| 新規 | `nix/editors-zed.nix` または `nix/editors.nix` へ追記 |
| 方式 | class A merge（`agentsLib.mkMergeActivation` 再利用） |
| ソース | `home/editors/zed-settings.json` または Nix attrset |

**事前**

```bash
test -f ~/.config/zed/settings.json && jq 'keys' ~/.config/zed/settings.json
agents-diff  # ベースライン
```

**実装チェックリスト**

- [ ] live ファイルのキーを洗い出し、秘密・マシン固有キーを **宣言から除外**
- [ ] `dotfilesAgents.classAMerges` に diff コマンド追加
- [ ] `mkLink` ではなく merge（Zed は GUI から settings を書く）

**事後**

```bash
nix build '.#darwinConfigurations.macbook.system' --no-link
sudo darwin-rebuild switch --flake ~/.config/nix-darwin#macbook
file ~/.config/zed/settings.json   # regular file, not symlink to store-only
agents-diff | rg -i zed || true
# Zed 起動 → 設定 UI で 1 項目変更 → 保存 → agents-diff で宣言外キーが残ること
# 再度 switch → 宣言キーが repo 値に戻ること
```

**合格条件**: merge の3性質（宣言外保持・宣言上書き・冪等）を満たす。

### ステップ 2.3 — OrbStack 設定（第二候補）

| 項目 | 内容 |
|---|---|
| 触るファイル | 要調査（`~/.orbstack/config` 等） |
| 管理しない | VM イメージ、内部 state |

```bash
find ~/.orbstack -maxdepth 2 -type f 2>/dev/null
grep -r '' ~/.orbstack/config 2>/dev/null | head
```

**Go / No-Go**: 平文 YAML/JSON で秘密がなく、OrbStack が追記しないキーだけなら class A。否则スキップ。

### ステップ 2.4 — 明示的スキップの固定

以下は **フェーズ 2 では Nix 化しない**（inventory と同じ）。

- `~/.docker/config.json`（認証含む）
- `~/.codex/computer-use/config.json`（ランタイム）
- `~/.semantic_search`（生成インデックス）
- `~/.local/share/nvim/mason`（Mason は Nix ツールへ寄せる）

**検証**: `rg 'docker/config|computer-use|semantic_search|mason' nix/` → 意図的参照のみ。

---

## 7. フェーズ 3 — macOS システム設定（優先度: 中〜高）

**目的**: 新 Mac 復元効果が高い defaults だけを `nix/darwin.nix` に追加。inventory §1。

**共通ルール**

- nix-darwin の typed option を優先。無い場合のみ `system.defaults.CustomUserDefaults` 等
- **1 ドメイン = 1 PR**
- switch 後すぐ入力・ウィンドウ操作で体感確認

### ステップ 3.1 — キーボード / 入力ソース

| 項目 | 内容 |
|---|---|
| 触るファイル | `nix/darwin.nix` |
| 対象例 | `KeyRepeat` / `InitialKeyRepeat`（一部済）、入力ソース、修飾キー |

**事前**

```bash
defaults read NSGlobalDomain KeyRepeat InitialKeyRepeat 2>/dev/null
defaults read com.apple.HIToolbox 2>/dev/null | head -30
```

**事後（必須・人手）**

- キー repeat が期待どおり
- 日本語 IME 切替が壊れていない
- 修飾キー（Caps Lock 等）が意図どおり

**不合格時**: 当該 commit を revert → `--rollback`

### ステップ 3.2 — Trackpad / Mouse

```bash
defaults read com.apple.AppleMultitouchTrackpad 2>/dev/null | head
defaults read com.apple.AppleMultitouchMouse 2>/dev/null | head
```

**事後**: スクロール方向、タップ to click、Mission Control スワイプを確認。

### ステップ 3.3 — Mission Control / Spaces / WindowManager

```bash
defaults read com.apple.dock mru-spaces 2>/dev/null
defaults read com.apple.WindowManager 2>/dev/null | head
```

### ステップ 3.4 — Finder / Dock（既存の拡張）

現状: autohide, show-recents, FXPreferredViewStyle 等。

```bash
defaults read com.apple.finder
defaults read com.apple.dock
```

追加するたびに Finder / Dock を再起動または relaunch で確認。

### ステップ 3.5 — スクリーンショット / ロック / スリープ

```bash
defaults read com.apple.screencapture 2>/dev/null
pmset -g
```

**注意**: スリープ設定は nix-darwin と `pmset` の相互作用を確認。

### ステップ 3.6 — 低優先 defaults（必要になったら）

Spotlight、Software Update、Bluetooth、Safari、Terminal.app、通知 — inventory 記載の plist ドメイン参照。**日常で触らないものは後回し。**

### ステップ 3.7 — やらないこと（再確認）

- plist ファイル丸ごとコピー
- メニューバー / Control Center の全レイアウト（macOS バージョンで変わりやすい）
- Time Machine ディスク選択（マシン固有）

---

## 8. フェーズ 4 — GUI アプリ設定（選択的・低〜中）

**目的**: スキーマが安定した JSON/TOML/YAML のみ。inventory §3。

### ステップ 4.1 — Raycast（調査 → 条件付き Go）

```bash
find ~/Library/Application\ Support/Raycast -maxdepth 3 -name '*.json' 2>/dev/null | head
find ~/Library/Application\ Support/com.raycast.macos -maxdepth 3 -type f 2>/dev/null | head
```

**Go 条件**: 平文 JSON、アカウントトークンなし、アプリが単方向 read または merge 可能。

### ステップ 4.2 — スキップ固定リスト

| アプリ | 理由 |
|---|---|
| Chrome / Slack / Bitwarden | アカウント・トークン・キャッシュ |
| Obsidian | vault 本体はデータ |
| Docker Desktop auth | 秘密 |
| Codex/Cursor/Kiro Application Support | CLI 側はフェーズ 0 済、GUI state はクラスC |

**検証**: 上記を repo に取り込んでいないこと。

---

## 9. フェーズ 5 — Launch Agents（優先度: 低）

**目的**: ユーザーが書いた job のみ `home-manager` `launchd.agents` で管理。

### ステップ 5.1 — 既存 plist の分類

```bash
ls -la ~/Library/LaunchAgents/
plutil -p ~/Library/LaunchAgents/com.google.keystone.agent.plist 2>/dev/null | head
```

| 観測ファイル | 推奨 |
|---|---|
| `com.google.*` | **管理しない**（vendor updater） |
| `com.amazon.codewhisperer.*` | **管理しない** |
| 自作 script 用 | 候補 — `home/launchd/` + Nix 宣言 |

### ステップ 5.2 — ユーザー job 追加時のテンプレート

1. `home/launchd/<label>.plist` または Nix `launchd.agents` 宣言
2. `nix build` → `switch`
3. `launchctl list | rg <label>`
4. ログ出力先が repo 外（`~/Library/Logs` 等）であること

---

## 10. フェーズ 6 — プロジェクト flake 化 / mise 廃止

**目的**: グローバル mise を減らし、活発な repo だけ `flake.nix` + `nix develop`。inventory §6、[`macos-nix-migration.md`](macos-nix-migration.md) §7。

**このフェーズの変更は dotfiles repo ではなく各 project repo に行う。**

### ステップ 6.1 — 優先度付け（inventory リストから）

| 優先 | リポジトリ | 理由 |
|---|---|---|
| 1 | `articles/`, `blog/tech-blog-writing/` | 軽量・高頻度 |
| 2 | `talks/slidev/` | 成果物明確 |
| 3 | `src/cdk-validations/`, `src/cdk-insights/` | AWS 日常 |
| 4 | その他 `src/*` | 使用頻度に応じて |
| 後回し | `tmp/*`, sample 系 | 低使用 |

### ステップ 6.2 — 1 プロジェクト移行手順

```bash
cd ~/src/<project>
# 1. flake.nix 追加（macos-nix-migration.md の template）
# 2. .envrc: use flake
direnv allow
# 3. 開発コマンド検証
nix develop -c node --version
nix develop -c pnpm install --frozen-lockfile
nix develop -c pnpm test   # 存在する場合のみ
# 4. .mise.toml 削除
# 5. 翌日も同コマンドで開発できることを確認
```

**合格条件**: `mise activate` なしで同一コマンドが通る。

### ステップ 6.3 — グローバル mise 削除（最終ステップ）

**前提**: 主要プロジェクトすべてが flake 化済み。

| 触るファイル | 内容 |
|---|---|
| `nix/packages.nix` | `mise` 削除 |
| `nix/home.nix` | `.mise.toml` の `home.file` 削除 |
| `home/mise.toml` | 削除 |

```bash
nix build '.#darwinConfigurations.macbook.system' --no-link
sudo darwin-rebuild switch --flake ~/.config/nix-darwin#macbook
command -v mise && echo 'FAIL: still present' || echo 'OK: mise removed'
test ! -f ~/.mise.toml && echo 'OK'
```

---

## 11. 進捗トラッキング

ステップ完了時に **日付 + PR** を記入する。

| ステップ | 状態 | PR / 日付 | メモ |
|---|---|---|---|
| 0.1 ベースライン | 完了 | 2026-07-04 | `nix build` OK、`agents-diff` 保存 |
| 0.2 回帰テスト | 完了 | 2026-07-04 | class A/B 回帰 OK |
| 1.1 local/bin 棚卸し | 完了 | 2026-07-04 | 監査: [`nix-migration-audit.md`](nix-migration-audit.md) |
| 1.2 zprofile 整理 | 完了 | 2026-07-04 | `home.nix` 宣言で妥当、変更なし |
| 1.3 ランタイム除外 doc | 完了 | 2026-07-04 | `nix/` に history 等なし |
| 1.4 mise 位置づけ | 完了 | 2026-07-04 | フェーズ6まで維持 |
| 2.1 開発ツール監査 | 完了 | 2026-07-04 | 監査表あり |
| 2.2 Zed settings | 完了 | PR #3, `90943e8` | settings class A merge + keymap mkLink。GUI は Homebrew `zed` cask |
| 2.3 OrbStack | 未着手 | | |
| 2.4 スキップ固定 | 完了 | 2026-07-04 | 監査に記載 |
| 3.1 keyboard | 完了 | 2026-07-04 | KeyRepeat 済。入力ソースは IME リスクのため未宣言。capitalization/period を追加 |
| 3.2 trackpad | 完了 | PR #4, switch 済 | live 値を `system.defaults.trackpad` に反映 |
| 3.3 Mission Control | 完了 | 2026-07-04 | WindowManager + trackpad ジェスチャー（dock 側は未設定＝macOS デフォルト） |
| 3.4 Finder/Dock 拡張 | 完了 | 2026-07-04 | `tilesize`, `wvous-br-corner`, Finder `NewWindowTarget` |
| 3.5 screenshot/sleep | 完了 | 2026-07-04 | screencapture 保存先。sleep は AC/電池で値が異なるため `allowSleepByPowerButton` のみ |
| 3.6 低優先 defaults | 完了 | 2026-07-04 | 意図的スキップ（Spotlight/Safari/Bluetooth 等は必要時のみ） |
| 4.1 Raycast | 未着手 | | |
| 4.2 GUI スキップ固定 | 未着手 | | |
| 5.1 LaunchAgents 分類 | 完了 | 2026-07-04 | 監査済み。vendor は触らない |
| 5.2 ユーザー job | 完了 | PR #5 | `screenshot-copy` launchd |
| 6.x project flakes | 未着手 | | |
| 6.3 mise 削除 | 未着手 | | |

---

## 12. 完了条件（この計画スコープ）

以下を満たした時点で、inventory の「Nix Candidates Still Missing」は **意図的に残したもの以外** 消化済みとみなす。

1. Shell 境界が文書化され、`~/.local/bin` の repo 所有物だけが Nix 生成である。
2. 開発ツールは監査表があり、Zed（および Go 判定した OrbStack 等）が class A merge または明示スキップされている。
3. 日常に効く macOS defaults が `nix/darwin.nix` にあり、各ドメインが実機検証済み。
4. GUI は Raycast 等 **採用したものだけ** 管理、それ以外はスキップ理由が表にある。
5. vendor LaunchAgent は触っていない。
6. 活発な project が flake 化され、最終的に `mise` が `packages.nix` から削除されている。
7. 全フェーズを通じ、秘密情報が `gitleaks protect --staged` を通過している。

---

## 13. 次のアクション（推奨着手順）

**完了済み（2026-07-04）**: フェーズ 0–2、**フェーズ 3 完了**、フェーズ 5、`darwin-rebuild switch` 運用安定化（`90943e8`）。

**これから**:

1. **4.1–4.2** — Raycast 調査 / GUI スキップ固定の文書化
2. **2.3** — OrbStack 設定（Go/No-Go）
3. **6.x** — 活発な project の flake 化（dotfiles 外）

macOS defaults は引き続き **1 ドメイン = 1 PR**、switch 後すぐ体感確認。
