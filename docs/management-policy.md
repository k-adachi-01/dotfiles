# 設定管理ポリシー

このドキュメントは、このリポジトリで「何を Nix が管理し、何をアプリや人間の手に委ねるか」を判断するための唯一の分類基準です。`README.md` と `AGENTS.md`（ルート、`home/ai/AGENTS.md`）はここに書かれた分類に従います。

## 1. 全体像: 4つの分類

| 分類 | 定義 | 具体例 | Git管理 |
|---|---|---|---|
| **Nix管理（システム/CLI）** | OS設定・CLIパッケージ | `nix/darwin.nix`, `nix/packages.nix`, `nix/apps.nix` | する |
| **Nix管理（ユーザー環境）** | shell/git/エディタ/Neovim | `nix/home.nix`, `nix/nixvim.nix`, `nix/editors.nix` | する |
| **Nix管理（AI エージェント設定）** | 下記「AI エージェント設定のクラス分け」を参照 | `nix/agents/*` | する |
| **管理外（ローカル/秘密）** | 認証情報・セッション状態・マシン固有ランタイム状態 | `~/.aws/`, `~/.ssh/`, `~/.codex/auth.json`, `*.sqlite*` | しない |

## 2. AI エージェント設定のクラス分け（クラスA/B/C）

Claude Code / Codex / Cursor / Kiro はいずれも「アプリ本体が自分の設定ファイルに書き込むかどうか」が異なる。この違いを無視して全ツールに同じ管理方式を強制すると、次のいずれかが起きる。

- **Nix store symlink を強制**すると、アプリが設定へ書き込めず壊れる（例: Cursor `cli-config.json` は `hasChangedDefaultModel` 等のアプリ状態を自分で書く）。
- **何も merge せず放置**すると、repo と実ファイルが黙って乖離し SSOT でなくなる。
- **repo への symlink を無条件に張る**と、アプリがランタイム状態を repo の作業ツリーへ直接書き込み、秘密やローカル情報が commit されうる。**これは推測ではなく実際に起きた**: 過去の `home/agents/codex/config.toml` には `[projects.*]`（第三者名を含むプロジェクトパス）や `[marketplaces.*]`（ローカルキャッシュパスとタイムスタンプ）が commit されていた。

そこで、ファイルごとに「アプリが書き込むか」だけを基準に3クラスへ仕分ける。

| クラス | 判定基準 | 管理方式 | Git管理 |
|---|---|---|---|
| **クラスA: 宣言データ** | アプリ自身も書き込みうる設定ファイル（JSON/TOML/YAML） | repo の Nix attrset で管理したいキーだけを宣言し、`darwin-rebuild switch` 時に実ファイルへ **deep-merge**（宣言キー=Nixが正、宣言外キー=アプリが正） | 宣言部分のみ |
| **クラスB: 静的アセット** | アプリは読むだけで書き込まないファイル | repo の実ファイルへ out-of-store symlink。repo 編集が switch 不要で即反映 | する |
| **クラスC: ランタイム状態・秘密** | 認証・履歴・セッション・キャッシュ | 完全に管理外 | しない（`.gitignore` + `gitleaks`） |

### ツール別分類（目標状態）

| ツール | クラスA (merge) | クラスB (out-of-store link) | クラスC (管理外) |
|---|---|---|---|
| Codex | `config.toml`（`model`/`personality`/`notice`/`tui`/`plugins`/`features`/`desktop` 等の管理キーのみ宣言） | `AGENTS.md`, `openai.config.toml`, `bedrock.config.toml`, `rules/default.rules`, `notify.sh`, `keybindings.json` | `auth.json`, `history.jsonl`, `sessions/`, `*.sqlite*`, `cache/`, `.tmp/`, `[projects.*]`, `[marketplaces.*]` |
| Claude Code | `settings.json`, `.mcp.json`, `keybindings.json` | `AGENTS.md`, `CLAUDE.md`, `statusline.py`, `notify-done.sh` | `.credentials.json`, `projects/`, `statsig/` |
| Cursor | `cli-config.json`, `mcp.json` | `AGENTS.md`, `statusline.sh` | `chats/`, `projects/`, `worktrees/` |
| Kiro | `settings/cli.json`, `settings/mcp.json`, `powers.json`, `powers.mcp.json`, `settings/permissions.yaml`（`default.rules` から生成） | `powers/*` のソース | `sessions/`, `logs/`, `.cli_bash_history`, `settings/feed_state.json`, `settings/survey_state.json` |
| Agent Skills | — (`programs.agent-skills` モジュール経由の rsync) | — | — |

## 3. 移行状況（この表は各PRの完了時に更新する）

| ツール | 現在の管理方式 | 目標の管理方式 | 移行PR |
|---|---|---|---|
| Codex | seed-only（`home.activation` で「無ければ作成、あれば触らない」） | クラスA merge + クラスB link | PR6 |
| Kiro | seed-only | クラスA merge + クラスB link | PR7 |
| Claude Code | Nix store symlink（`home.file.source`） | クラスA merge + クラスB link | PR8 |
| Cursor | Nix store symlink（`home.file.source`） | クラスA merge + クラスB link | PR8 |
| Agent Skills flake input | ローカル絶対パス (`path:/Users/adachi/agent-skills`) | `github:k-adachi-01/agent-skills` pin | PR5 |

移行前のツールについては、既存の運用ルール（seed-only の場合は `sync-codex-config`/`sync-kiro-config` を明示実行しないと反映されない、symlink の場合はアプリ側の書き込みが効かない）が引き続き有効。**このドキュメントの「目標の管理方式」列は将来の設計であり、上の表で完了と記載されるまでは現在の挙動と異なる。**

## 4. ローカル専用設定と共有設定の分離

- 共有 = このリポジトリの宣言（クラスA attrset + クラスB ファイル）。
- ローカル専用 = クラスAファイルの「宣言外キー」とクラスC全体。
- リポジトリ内に `local.nix` のようなオーバーレイファイルは作らない。pure flake evaluation は Git 管理外ファイルを読めないため、その方式は成立しない。クラスAの merge が「同一ファイル内でのローカル層」を実質的に代替する。
- ローカルで試した設定を恒久化したい場合は、`agents-diff`（PR8 で追加）で宣言外キーを確認し、該当する `nix/agents/<tool>.nix` の attrset へ人間/agent が手動で移してから `darwin-rebuild switch` する。自動逆同期は行わない（秘密混入の逆流を防ぐための意図的な非対称性）。

## 5. 秘密情報の防御

1. `.gitignore`: `result`, `result-*`, `*.hm-backup`, `.env`, `.env.*`, `*.pem`, `*.key`, `auth.json`, `DOTENV_PRIVATE_KEY*`
2. コミット前チェック: `gitleaks protect --staged`（PR9 で導入）
3. CI: `gitleaks detect` + `alejandra --check` + `statix check` + `deadnix`（PR9 で導入。private な `agent-skills` input への認証が必要なため、フルの `darwin-rebuild build` は CI に含めずローカル必須手順とする）
4. 構造的防御: クラスA merge は repo→live の一方向のみ。アプリが live に書いた内容が自動で repo に来る経路は存在しない
5. クラスB のレビュー規約: `home/agents/` への変更では、絶対パス・タイムスタンプ・第三者名の混入がないか diff を確認してからコミットする

## 6. 新しい AI ツールを追加する時の手順

1. 対象ツールの設定ファイルを列挙し、「アプリが書き込むか」でクラスA/B/Cに仕分ける
2. `nix/agents/<tool>.nix` を作成: クラスAは attrset + `nix/agents/lib.nix` の merge ヘルパー、クラスBは `mkOutOfStoreLink`
3. 実体ファイルは `home/agents/<tool>/` に置く
4. `nix/agents/default.nix` に import を追加。MCP が必要なら `nix/agents/mcp.nix` の共有定義を参照する
5. クラスCの一覧を本ドキュメントの表と `README.md` の除外リストへ追記する
6. 検証: 冪等性（2回 switch しても差分が出ない）・アプリ状態の保持（宣言外キーが消えない）・SSOT再主張（管理キーをlive側で書き換えてもswitchで戻る）の3点を確認する
