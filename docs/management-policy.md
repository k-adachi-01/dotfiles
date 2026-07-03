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
| Cursor | `cli-config.json`（`hasChangedDefaultModel` 等アプリ状態が書かれる）, `mcp.json` | `AGENTS.md`, `statusline.sh` | `chats/`, `projects/`, `worktrees/` |
| Kiro | `settings/cli.json`, `settings/mcp.json`, `powers.json`, `powers.mcp.json`, `settings/permissions.yaml`（`default.rules` から生成） | `powers/*` のソース | `sessions/`, `logs/`, `.cli_bash_history`, `settings/feed_state.json`, `settings/survey_state.json` |
| Agent Skills | — (`programs.agent-skills` モジュール経由の rsync) | — | — |

## 3. 移行状況（この表は各PRの完了時に更新する）

| ツール | 現在の管理方式 | 目標の管理方式 | 移行PR |
|---|---|---|---|
| Codex | クラスA merge（`config.toml`）+ クラスB link（`AGENTS.md`/`keybindings.json`/`openai.config.toml`/`bedrock.config.toml`/`default.rules`/`notify.sh`）（済） | 同左（完了） | PR6 完了 |
| Kiro | クラスA merge（`powers.json`/`powers.mcp.json`/`settings/cli.json`/`settings/mcp.json`/`settings/kiro_cli_theme.json`/`settings/permissions.yaml`）+ クラスB link（`powers/**` の個別ファイル）（済） | 同左（完了） | PR7 完了 |
| Claude Code | クラスA merge（`settings.json`/`.mcp.json`/`keybindings.json`）+ クラスB link（`AGENTS.md`/`CLAUDE.md`/`statusline.py`/`notify-done.sh`）（済） | 同左（完了） | PR8 完了 |
| Cursor | クラスA merge（`cli-config.json`/`mcp.json`）+ クラスB link（`AGENTS.md`/`statusline.sh`）（済） | 同左（完了） | PR8 完了 |
| Agent Skills flake input | `path:/Users/adachi/agent-skills`（ローカル checkout、GitHub 認証不要） | 同左（完了） | PR5 で一時的に GitHub pin、PR13 で path に戻した |

4ツールすべてがクラスA merge / クラスB linkの統一モデルへ移行済み（2026-07時点）。旧方式（Claude/Cursorの Nix store symlink、Codex/Kiro の seed-only）は全廃した。

### Codex merge 実装メモ（PR6で確定）

`nix/agents/lib.nix` の `mkMergeActivation` が全ツール共通の merge 基盤。フォーマット非依存の単一 Python スクリプト（`mergeConfigScript`）が TOML（`tomllib`/`tomli-w`）・JSON（標準ライブラリ）・YAML（`pyyaml`）を同じ deep-merge ロジックで処理する。`home.activation.mergeCodexConfig` が switch のたびに次を行う:

1. `home/agents/codex/config.toml` を `builtins.fromTOML` で読み、Nix 値として declared file を再生成（TOML として妥当かを eval 時にも検証できる副次効果がある）
2. live 側の `~/.codex/config.toml` を読み込み（無ければ空として扱う）、宣言キーを再帰的に上書きした結果を一時ファイルへ書き出す
3. 一時ファイルを再パースできることを確認できたときだけ、既存ファイルをバックアップ（`~/.codex/backups/`）してから atomic mv。パース不能なら書き込まずエラー終了する
4. 直前の内容と merge 結果が同一なら書き込みをスキップする（冪等・mtime 汚染なし）

検証は `nix build` によるビルド時検証に加え、`merge-agent-config` スクリプトをサンドボックス内で直接実行し、(a) 宣言キーが live 側の変更を上書きすること、(b) `[projects.*]`/`[marketplaces.*]` のような宣言外キーが保持されること、(c) 出力を再度 merge しても差分が出ないこと（冪等性）、(d) live ファイルが壊れた TOML の場合は非ゼロ終了し出力ファイルを書き換えないこと、の4点を確認済み。実機での `sudo darwin-rebuild switch` は Touch IDが必要なため人間が実行して最終確認すること。

### Kiro merge 実装メモ（PR7で確定）

Kiro の宣言データ（`kiroPowersJson`/`kiroPowersMcpJson`/`kiroCliJson`/`kiroSettingsMcpJson`/`kiroCliThemeJson`/`kiroPermissions`）は Nix 属性セットではなく、`nix/agents/mcp.nix` の `pkgs.formats.json{}.generate`（または `kiroPermissions` の場合は ruby 製ビルド）が生成する**既存の store ファイル**である。これを再度 Nix 値化して `mkMergeActivation` の `value` に渡すのは冗長なため、`mkMergeActivation` を拡張し、`value`（Nix値をformatsで生成）と `declaredFile`（すでに存在するファイルをそのまま使う）のどちらか一方を渡せるようにした。Kiro は全項目で `declaredFile` を使う。

`kiro_cli_theme.json` は元の再設計案の分類表に載っていなかったが、`settings/cli.json` と同種の単純な設定ファイル（Kiro が実行時に他のキーを追記する形跡がない）と判断し、クラスA merge に含めた。

merge が辞書（テーブル/オブジェクト）のみを再帰処理し、配列は宣言側で丸ごと置き換わる仕様であることは、`settings/permissions.yaml` の `rules` 配列で実際にテストして確認した: live 側に Kiro が追加したと仮定する `rules` エントリと無関係な独自トップレベルキーを仕込んだ状態で merge した結果、`rules` は宣言値で完全に上書きされ、無関係なトップレベルキーは保持された。したがって `permissions.yaml` に対して Kiro アプリ自身が実行時に allow ルールを追記するようになった場合、そのユースケースはこの merge モデルでは失われる点に注意（現時点でそのような書き込みは観測されていない）。

`sync-codex-config`/`sync-kiro-config` はいずれも削除済み。switch のたびに自動で merge されるため、明示的な再同期コマンドは不要になった。

### Claude Code / Cursor merge 実装メモ（PR8で確定）

Claude Code と Cursor は、Codex/Kiro が確立した merge 機構（`nix/agents/lib.nix`）をそのまま再利用する形で、Nix store symlink 方式から class A merge / class B link へ移行した。Codex/Kiro との違いは、宣言データが `builtins.fromTOML`（Codex）や既存の store ファイル（Kiro）ではなく、**元から Nix attrset として書かれていた**点だけである。したがって `mkMergeActivation` の `value` 引数（`pkgs.formats.*.generate` で都度シリアライズ）をそのまま使う。

- Claude Code: `settings.json`（env・permissions・hooks・statusLine・enabledPlugins 等）・`.mcp.json`・`keybindings.json` を merge。`AGENTS.md`・`CLAUDE.md`・`statusline.py`・`notify-done.sh` は class B link。旧 `home.file.".claude/statusline.py".text = ''...''`（Nix文字列埋め込み）は `home/agents/claude/statusline.py`・`home/agents/claude/notify-done.sh` の実ファイルへ切り出し、shellcheck/エディタ支援が効くようにした（実行ビットは repo 側のファイルに `chmod +x` 済み、`git` が実行権限を追跡する）
- Cursor: `cli-config.json`（`hasChangedDefaultModel`/`selectedModel` 等、Cursor 自身が書き込む値を含む）・`mcp.json` を merge。`AGENTS.md`・`statusline.sh` は class B link
- 移行に伴う home-manager 側の挙動: これまで `home.file."*.json".source` だった Nix store symlink を削除し、同じパスを `home.activation` の merge 対象に切り替えた。次の switch では、home-manager の通常のジェネレーション世代管理が「もう `home.file` で宣言されていない」symlink を削除し、その直後（`entryAfter ["writeBoundary"]`）に merge スクリプトが同じパスへ通常ファイルとして書き込む。ライブファイルが存在しない場合の merge スクリプトの挙動（空 dict として扱い宣言値で新規作成）と同じ経路なので、Codex 初回移行時と同様に安全なはずだが、**手元の switch で `*.hm-backup` が生成されていないか確認すること**（生成されていた場合は中身を確認してから削除してよい）

### agents-diff（PR8で追加）

`~/.local/bin/agents-diff` は、上記すべての class A ファイルについて「次の switch で何が変わるか」と「宣言されていない（アプリ所有の）キー」を読み取り専用で表示する。実装は `nix/agents/lib.nix` の `mkDiffCommand`（`merge-agent-config --check` を呼ぶだけで、`dest` には一切書き込まない）と、各 `nix/agents/<tool>.nix` が `dotfilesAgents.classAMerges`（文字列のリスト型オプション、`nix/agents/default.nix` で定義）へ自分の diff コマンドを追加する仕組みからなる。`--check` モードは各フォーマットの正規化済みテキスト同士の unified diff に加えて、live 側にだけ存在するトップレベル（以深）キーのパス一覧を出力する。後者が「repo の attrset へ昇格する候補」であり、昇格は必ず人間/agentが手動で `nix/agents/<tool>.nix` を編集して行う（自動逆同期はしない）。

### エディタ GUI 設定（`nix/editors.nix`、PR10で確定）

VS Code / Cursor / Antigravity / Antigravity IDE の `settings.json` はクラスA/B/Cの判定基準（「アプリが書き込むか」）で見ると、AI エージェント設定と全く同じ性質を持つ。各アプリの GUI 設定エディタ（Settings UI）はテーマ選択・言語別オーバーライドの追加などをこのファイルへ直接書き込むため、これまでの `home.file.<path>.source`（Nix store symlink）方式では**GUI から設定を変更しても保存できない**問題があった。PR10 で `nix/agents/lib.nix` の merge 基盤をそのまま再利用し、4アプリの `settings.json` をクラスA merge へ移行した。

- 宣言データはこれまでどおり Nix attrset（`commonSettings`/`cursorSettings`）のまま。`mkMergeActivation`/`mkDiffCommand` の `value` 引数に渡すだけで済むため、Codex/Kiro のような TOML パースや store ファイル読み込みの追加実装は不要だった
- `dotfilesAgents.classAMerges`（`nix/agents/default.nix` で定義したオプション）は `nix/agents/*.nix` からしか設定していなかったが、home-manager のモジュールシステム上はどのモジュールからでも同じオプションへ追記できるため、`nix/editors.nix`（`nix/agents/` の外にある兄弟モジュール）からも `agentsLib.mkDiffCommand` の結果を追加している。`agents-diff` の出力には自動的にエディタ4本の diff も含まれる
- `keybindings.json`（Cursor/Antigravity/Antigravity IDE のみ）は**クラスA化していない**。VS Code系の keybindings.json はトップレベルが辞書ではなく配列であり、`nix/agents/lib.nix` の merge はトップレベルが辞書のときしか宣言外キーを保持できない（配列は宣言側で丸ごと置換される）。トップレベル自体が配列だと GUI がキーバインドを追加しても次の switch で全消去されてしまうため、意図的に旧来どおりの生成ファイル（Nix store symlink）のまま残した。将来 GUI からのキーバインド追加を保存可能にしたい場合は、配列をラップする形式変更をエディタ側が提供しない限り、この制約は解消しない
- 検証: `merge-agent-config` をサンドボックス内で直接実行し、(a) GUI が書いたと仮定する未宣言キー（`editor.fontSize`、`workbench.colorTheme` 等）が merge 後も残ること、(b) 宣言キー（`window.commandCenter` 等）を live 側で書き換えても switch で宣言値に戻ること、(c) 一度 merge した結果を再度 merge しても差分が出ないこと（冪等性）の3点を確認済み。`nix build .#darwinConfigurations.macbook.system` も成功することを確認済み。実機での `sudo darwin-rebuild switch` と GUI からの実際の保存操作は Touch ID 認証と GUI 操作が必要なため人間が実行して最終確認すること

### class B symlink 実装漏れの修正（PR11で確定）

PR8/PR6 でクラスBとして「out-of-store symlink（repo 編集が switch 不要で即反映）」と文書化していたにもかかわらず、次の3箇所は実装が `config.lib.file.mkOutOfStoreSymlink`（このファイル内の `mkLink` ヘルパー）を使わず、`.source = ../../home/ai/AGENTS.md` のような**生の Nix パス参照**になっていた。

- `nix/agents/default.nix`: `.agents/AGENTS.md`
- `nix/agents/claude.nix`: `.claude/AGENTS.md`, `.claude/CLAUDE.md`
- `nix/agents/cursor.nix`: `.cursor/AGENTS.md`

生の Nix パス参照は home-manager 上で通常の `home.file.source` として扱われ、評価時点の repo の内容を Nix store へコピーした不変ファイルへの symlink になる。見た目は `mkLink` を使った場合と同じ「symlink」だが、**repo を編集しても次の `switch` まで反映されない**という、このクラスBモデルが最も避けたかった挙動そのものになっていた（実機で `readlink` を2段階たどって確認: `mkLink` を使った `~/.codex/AGENTS.md` は最終的に `/Users/adachi/.config/nix-darwin/home/ai/AGENTS.md` を指す symlink だったのに対し、`~/.claude/AGENTS.md`/`~/.claude/CLAUDE.md`/`~/.cursor/AGENTS.md` は Nix store 内にコピーされた通常ファイルを指していた）。

この不整合はドキュメント（本ファイル、`README.md`、両方の `AGENTS.md`）と実装が食い違っていたという点で、まさに「AI agent が誤解しそうな箇所」の実例である。3箇所すべてを `mkLink` 経由に修正し、`nix build` で `hm_AGENTS.md`/`hm_CLAUDE.md` 系の派生物が（コピーではなく）symlink derivation としてビルドされることを確認した。**新しいクラスBファイルを追加するときは、必ず `mkLink`（各 `nix/agents/<tool>.nix` 内で定義済みの同名ヘルパー）を経由すること。`.source = ../../home/...` のような生パス参照は使わない。** どちらも見た目のコード量に大差がなく、evalとbuildは両方成功するため、`nix build`/`darwin-rebuild build` だけではこの種の退化を検出できない点に注意。レビュー時は `.source = ` の右辺が `mkLink "..."` の形になっているかを目視で確認する。

### Agent Skills input の実装メモ（PR5 → PR13）

**現在の設計**: flake input `path:/Users/adachi/agent-skills`。Nix はローカルディスクを store にコピーするだけなので GitHub 認証は不要。`programs.agent-skills-nix` の module 直 `path` オプションは eval サンドボックス下で `pathExists` が失敗するため使わない（flake path input 経由が正しい）。

**narHash の更新**: `path:` flake input は `flake.lock` に内容ハッシュを pin する。`~/agent-skills` 編集後に lock を更新せず `switch` すると `NAR hash mismatch` になる。正しいコマンド（`nix flake lock` ではなく `nix flake update`）:

```bash
nix flake update agent-skills --flake ~/.config/nix-darwin
# または
cd ~/.config/nix-darwin && nix flake update agent-skills
```

**廃止した方式**: PR5 の `git+https` / PR12 の `github:` + PAT（root からの GitHub フェッチで認証が壊れる / 長期キー管理が必要）。

**bootstrap**: dotfiles clone に加え `gh repo clone k-adachi-01/agent-skills ~/agent-skills`。初回 `switch` 前に上記 `nix flake update agent-skills` を1回実行。

**skills-push** の流れ: `~/agent-skills` commit/push → `nix flake update agent-skills --flake ~/.config/nix-darwin` → `sudo darwin-rebuild switch` → 反映確認。`flake.lock` の commit は skills 変更と一緒に dotfiles へ push してよいが、ローカルだけ試すなら lock 更新だけで十分。

## 4. ローカル専用設定と共有設定の分離

- 共有 = このリポジトリの宣言（クラスA attrset + クラスB ファイル）。
- ローカル専用 = クラスAファイルの「宣言外キー」とクラスC全体。
- リポジトリ内に `local.nix` のようなオーバーレイファイルは作らない。pure flake evaluation は Git 管理外ファイルを読めないため、その方式は成立しない。クラスAの merge が「同一ファイル内でのローカル層」を実質的に代替する。
- ローカルで試した設定を恒久化したい場合は、`agents-diff`（`~/.local/bin/agents-diff`）で宣言外キーを確認し、該当する `nix/agents/<tool>.nix` の attrset へ人間/agent が手動で移してから `darwin-rebuild switch` する。自動逆同期は行わない（秘密混入の逆流を防ぐための意図的な非対称性）。

## 5. 秘密情報の防御

1. `.gitignore`: `result`, `result-*`, `*.hm-backup`, `.env`, `.env.*`, `*.pem`, `*.key`, `auth.json`, `DOTENV_PRIVATE_KEY*`
2. コミット前チェック: `gitleaks protect --staged --config .gitleaks.toml`（`nix/packages.nix` に `gitleaks` を追加済み。PR9 で導入）
3. CI（`.github/workflows/ci.yml`、PR9 で導入）: `alejandra --check` + `statix check` + `deadnix --fail` + `gitleaks detect --config .gitleaks.toml`。フルの `darwin-rebuild build`/`nix build` は CI に含めずローカル必須手順のまま
4. `.gitleaks.toml`: デフォルトルールセット（`useDefault = true`）を拡張し、`sha256-`/`sha512-`/`sha1-`/`md5-` プレフィックス付きの SRI ハッシュ文字列（`flake.lock` の `narHash`、`fetchFromGitHub`/`fetchurl` の `hash`、`npmDepsHash` 等）だけを許可リスト化している。これらは公開ソースの内容アドレスであり秘密情報ではないが、gitleaks の汎用高エントロピー文字列検出が将来誤検知する可能性があるための予防的措置（現時点の `gitleaks detect`/`--config` 込みの実行では誤検知は未発生）
5. 構造的防御: クラスA merge は repo→live の一方向のみ。アプリが live に書いた内容が自動で repo に来る経路は存在しない
6. クラスB のレビュー規約: `home/agents/` への変更では、絶対パス・タイムスタンプ・第三者名の混入がないか diff を確認してからコミットする

## 6. 新しい AI ツールを追加する時の手順

1. 対象ツールの設定ファイルを列挙し、「アプリが書き込むか」でクラスA/B/Cに仕分ける
2. `nix/agents/<tool>.nix` を作成: クラスAは attrset + `nix/agents/lib.nix` の merge ヘルパー、クラスBは `config.lib.file.mkOutOfStoreSymlink`（既存ファイルの `mkLink = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesRepo}/${path}";` をコピーして使う）。**クラスBの `.source` に `../../home/...` のような生の Nix パスを直接書かない** — 見た目は動くが Nix store コピーに退化し、repo 編集が switch まで反映されなくなる（実際に起きた事故と修正は「class B symlink 実装漏れの修正（PR11で確定）」を参照）
3. 実体ファイルは `home/agents/<tool>/` に置く
4. `nix/agents/default.nix` に import を追加。MCP が必要なら `nix/agents/mcp.nix` の共有定義を参照する
5. Agent Skills をそのツールへ配布したい場合は `nix/agents/default.nix` の `config.programs.agent-skills.targets` に対象を追加する（`programs.agent-skills` がそのツールをネイティブサポートしていない場合は、Codex/Kiro に倣い `targets.<tool>.enable = false` のまま `nix/agents/<tool>.nix` 側に `activation.sync<Tool>Skills`（`rsync -aL --delete` で `config.programs.agent-skills.bundlePath` をミラーする）を自前で書く。この場合の同期先はクラスA/Bのどちらでもない「常に上書きされる動的カタログ」として扱い、本ドキュメントの分類表にはクラスCの隣に別枠で書く）
6. クラスCの一覧を本ドキュメントの表と `README.md` の除外リストへ追記する
7. 検証: 冪等性（2回 switch しても差分が出ない）・アプリ状態の保持（宣言外キーが消えない）・SSOT再主張（管理キーをlive側で書き換えてもswitchで戻る）の3点を確認する
