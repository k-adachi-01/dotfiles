# Harness Inventory — 自然言語 Agent Harness の分解と最小化

Linear: [K-210](https://linear.app/k-adachi-01/issue/K-210/)

対象 repo:

- `k-adachi-01/dotfiles`（`~/.config/nix-darwin`）
- `k-adachi-01/agent-skills`（`~/agent-skills`, private, dotfiles flake input）
- `k-adachi-01/cdk-starter`（`~/src/cdk-starter`）

対象: AGENTS.md / Steering / Rules / Agent Skills / Custom Agents / その他自然言語 instruction。
原則対象外: Hooks（enforcement）, permissions, sandbox, approval, MCP。vendor plugin（AWS toolkit skills, Kiro powers, AWS MCP, Agent Plugin for AWS）は「大きな知識注入 plugin」として別 Issue 候補とし、本書では inventory のみ記録する。

---

## Phase 1 — Source Map

### dotfiles（`~/.config/nix-darwin`）

| Source | Agent | Scope | Mechanism | Load | Size |
|---|---|---|---|---|---|
| `AGENTS.md`（root）| 全 agent（この repo を編集する時）| repo | AGENTS.md（`CLAUDE.md` は `@AGENTS.md` shim）| always（repo）| 105 行 |
| `home/ai/AGENTS.md` | Codex / Claude / Cursor / Devin | global | AGENTS.md → `~/.codex/AGENTS.md`, `~/.claude/AGENTS.md`, `~/.cursor/AGENTS.md`, `~/.agents/AGENTS.md`（全て out-of-store symlink）| always（global）| 193 行 |
| `home/ai/CLAUDE.md` | Claude | global | `@~/.claude/AGENTS.md` import shim → `~/.claude/CLAUDE.md` | always | 1 行 |
| `home/agents/codex/default.rules` | Codex | global | Rules（`prefix_rule` allow リスト）| always | ~230 行 — **permissions のため対象外** |
| `home/agents/kiro/powers/cloud-architect/` | Kiro | global | Power（steering×3 `inclusion: always` + SKILL×1 + mcp.json）| conditional（Power install 時）| 4 ファイル ~300 行 — **vendor plugin → 別 Issue 候補** |
| `home/agents/kiro/powers/stripe/` | Kiro | global | Power（steering×1 + SKILL×1 + mcp.json）| conditional | 3 ファイル ~400 行 — **vendor plugin → 別 Issue 候補** |
| `nix/agents/devin.nix` permissions 宣言 | Devin | global | config（allow/deny/ask）| always | **permissions → 対象外** |
| `nix/agents/claude.nix` hooks/statusline | Claude | global | hooks + statusline | — | **hooks → 対象外** |
| `home/agents/codex/config.toml` の `personality = "pragmatic"` 等 | Codex | global | config | always | **自然言語 instruction ではないが行動に影響 → 傍証として記録** |
| `docs/management-policy.md` 他 docs/ | 人間 + agent 参照用 | repo | docs | explicit（参照時のみ）| instruction ではないが Phase 3 の意図復元に使用 |

### agent-skills（`~/agent-skills` → `~/.agents/skills` `~/.claude/skills` `~/.cursor/skills` `~/.codex/skills` `~/.kiro/skills`）

全て Agent Skill（progressive disclosure: description が常時 context、本体は conditional/explicit load）。

| Source | Agent | Scope | Mechanism | Load | Size |
|---|---|---|---|---|---|
| `skill-creator/SKILL.md` | 全 agent | global | Skill | conditional | 480 行 |
| `dotfiles-nix-maintenance/SKILL.md` | 全 agent | global | Skill | conditional | 348 行 |
| `aws-sandbox-run/SKILL.md` | 全 agent | global | Skill | conditional | 279 行（+ scripts/）|
| `herdr/SKILL.md` | 全 agent | global | Skill | conditional | 214 行 |
| `browser-use/SKILL.md` | 全 agent | global | Skill | conditional | 193 行 |
| `yomiyasu/SKILL.md` | 全 agent | global | Skill | conditional | 190 行 |
| `drawio/SKILL.md` | 全 agent | global | Skill | conditional | 185 行 |
| `natural-japanese/SKILL.md` | 全 agent | global | Skill | conditional | 138 行 |
| `wezterm-config-sync/SKILL.md` | 全 agent | global | Skill | conditional | 65 行 |
| `bws-secrets/SKILL.md` | 全 agent | global | Skill | conditional | 55 行 |
| `best-practices/SKILL.md` | 全 agent | global | Skill | conditional | 51 行 |
| `grilling/SKILL.md` | 全 agent | global | Skill | conditional | 28 行 |
| `grill-me/SKILL.md` | 全 agent | global | Skill（`disable-model-invocation: true` のエイリアス）| explicit | 7 行 |
| `README.md` | 人間 | repo | doc | explicit | 30 行 |
| `darwin-eval/`（baseline-scores.json, results.tsv）| — | — | 実験データ | — | Phase 3/5 の証拠ソース |
| AWS toolkit skills（flake input `awslabs` 系, `~/.agents/skills/amazon-*` `aws-*` `launch-with-aws` `signing-in-to-aws` 等 ~21 個）| 全 agent | global | Skill（vendor）| conditional | **vendor plugin → 別 Issue 候補** |

### cdk-starter（`~/src/cdk-starter`）

| Source | Agent | Scope | Mechanism | Load | Size |
|---|---|---|---|---|---|
| `AGENTS.md` | Codex / Cursor / Kiro / Devin 等 | repo | AGENTS.md | always（repo）| 120 行 |
| `.cursor/rules/no-direct-deploy.mdc` | Cursor | repo | Rule（`alwaysApply: true`）| always | 10 行 |
| `.cursor/rules/cdk-typescript.mdc` | Cursor | repo | Rule（glob: `bin/**/*.ts,lib/**/*.ts`）| conditional | 12 行 |
| `.cursor/rules/lint-format-oxc.mdc` | Cursor | repo | Rule（description match）| conditional | 12 行 |
| `.cursor/rules/security-cdk.mdc` | Cursor | repo | Rule（description match）| conditional | 13 行 |
| `.cursor/rules/testing-vitest-cdk.mdc` | Cursor | repo | Rule（glob: `test/**/*.ts`）| conditional | 11 行 |
| `.cursor/agents/*.md` ×6（agent-harness-maintainer, cdk-architect, cdk-change-reviewer, cdk-security-reviewer, cdk-test-engineer, nix-maintainer）| Cursor | repo | Custom Agent | explicit | 7–10 行 each |
| `.kiro/steering/*.md` ×7（agent-workflow, deployment, product, security, structure, tech, testing）| Kiro | repo | Steering | conditional | 5–10 行 each（計 ~60 行）|
| `.kiro/agents/*.json` ×6（同上 + prompt + resources）| Kiro | repo | Custom Agent | explicit | 6–13 行 each |
| `.agents/skills/*/SKILL.md` ×7（agent-quality-gate, aws-sandbox-run, cdk-change-review, cdk-diff-explain, cdk-security-review, cdk-synth-debug, cdk-unit-test）| 全 agent（`.cursor/skills` `.kiro/skills` はここへの symlink）| repo | Skill | conditional | 29–43 行 each（計 ~235 行）|
| `.agents/skills/cdk-change-review/references/reviewer-contract.md` | cdk-change-reviewer | repo | Skill 付属 reference | conditional | 32 行 |
| `.codex/hooks/inject_repo_context.py` | Codex | repo | Hook → **AGENTS.md 先頭 4000 文字 + 固定 policy を context 注入** | always（SessionStart）| 21 行 — mechanism は hook だが中身は自然言語注入（borderline）|
| `.codex/hooks/subagent_context.py` | Codex subagent | repo | Hook → 固定 policy 5 行注入 | conditional（SubagentStart）| 21 行 — 同上 borderline |
| `.codex/hooks/block_direct_deploy.py`, `validate_stop.py` / `.kiro/hooks/*.json` / `.cursor/hooks.json` / `rules/cfn-guard/` | — | repo | Hooks / policy | — | **enforcement → 対象外** |
| `docs/*.md` ×14（requirements, plan, security, agent-workflow, deployment, testing, …）| 人間 + agent 参照 | repo | docs | explicit（リンク経由）| harness ではないが steering/rules の参照先 |
| `.agents/darwin/`（iteration-1/2, scorecard, EVAL.md）| — | — | 過去の skill 評価実験データ | — | Phase 3/5 の証拠ソース（K-192 関連）|

### Source Map の要点

1. **最大の always-on harness は `home/ai/AGENTS.md`（193 行）**: 4 系統の agent の global context に常時注入される。
2. **cdk-starter は「薄い pointer 層 + AGENTS.md 集約」構造**: steering/rules/agents の多くは AGENTS.md と docs/ の内容を 5–13 行で再掲するだけ。重複が構造的に存在する。
3. **cdk-starter の `.codex/hooks` は AGENTS.md を SessionStart で再注入する**: mechanism は hook（対象外）だが、機能的には AGENTS.md の重複配布経路。
4. **vendor plugin 系は独立評価へ defer**: Kiro powers ×2、AWS toolkit skills ~21 個、MCP 系。

---

## Phase 2 — Instruction Atom 分解

ファイル単位ではなく「agent のどの行動を変えようとしているか」で分解。複数指示が不可分な場合は workflow 単位でまとめる。

### G-* : `home/ai/AGENTS.md`（global, always, 4 agent 系統）

| ID | Instruction | Intended behavior |
|---|---|---|
| G-001 | 主環境は macOS/NixOS、レガシー WSL2、パッケージ管理は Nix 主軸、Homebrew は GUI cask のみ | 環境認識・ツール選択の固定（project knowledge）|
| G-002 | `sudo darwin-rebuild switch --flake ~/.config/nix-darwin#macbook` を使う（plain は失敗）| 適用コマンドの固定 + 失敗回避 |
| G-003 | 再起動後 CLI が消えたら `nix-store-repair.sh`（再インストール禁止）| 特定障害への対処手順（過去の実障害由来）|
| G-004 | NixOS は `/etc/nixos` が system、dotfiles は user env のみ。二重管理しない | 管理境界の固定 |
| G-005 | NixOS 更新は `nixos-rebuild switch/build/test --flake /etc/nixos#nixos`。`nix-channel`/`--upgrade` は使わない | 更新コマンド固定 + 旧式コマンド禁止 |
| G-006 | WSL2 では `apt` を使い `apt-get` は使わない | 微細なコマンド偏好 |
| G-007 | Python は `uv` のみ。`pip`/`pip3`/`python -m pip` 禁止、venv は `uv venv` | package manager 固定（禁止列挙つき）|
| G-008 | JS は `pnpm` のみ。`npm`/`npx` 禁止、`pnpm-lock.yaml` を使う | package manager 固定（禁止列挙つき）|
| G-009 | ツールバージョンは Nix 主軸、mise は移行期間のみ | バージョン管理方針 |
| G-010 | GHA は `pnpm install --frozen-lockfile`、既存 mise CI は維持可 | CI 固有の運用ルール |
| G-011 | JS/TS は Vite+・oxlint・oxfmt。Biome/ESLint/Prettier 新規導入禁止 | toolchain 固定（〜60行、コマンド表つき）|
| G-012 | NG パターン一覧表（pip/npm/npx/package-lock/Biome 等）| G-007/008/011 の再掲 |
| G-013 | dotfiles は Nix/home-manager（chezmoi 不採用）、`~/.config/nix-darwin`、除外シークレット、gitleaks | dotfiles 運用 knowledge |
| G-014 | dotfiles 更新後は確認せず commit/push する | コミット運用の自動化許可 |
| G-015 | 5 agent ツールのクラスA/B/C 管理方式の詳細（merge 対象、runtime state 除外、agents-diff、skills-push、mkLink 等、~70行）| dotfiles 内部構造の知識 |
| G-016 | Windows パスは `/mnt/c/...` に変換する | 環境変換 micro-rule |

### D-* : dotfiles `AGENTS.md`（repo, always when editing dotfiles）

| ID | Instruction | Intended behavior |
|---|---|---|
| D-001 | このファイルは dotfiles repo 編集者向け、共通ルールは home/ai/AGENTS.md | 責務分離の案内 |
| D-002 | Public repo: 個人パス・第三者名・APIキー・runtime 状態をコミットしない | 情報漏洩防止 |
| D-003 | `sudo darwin-rebuild switch --flake ...#macbook` で適用（G-002 と同一）| 適用コマンド固定 |
| D-004 | App Management プロンプト対策は Terminal.app から実行 | TCC 失敗の workaround |
| D-005 | `/nix` 未マウント時は `nix-store-repair.sh`（G-003 と同一）| 障害対処 |
| D-006 | 検証は `nix build ... --no-link` / lint / gitleaks / agents-diff | 検証コマンド固定 |
| D-007 | ソースマップ表（nix/*.nix → 生成物）| repo 構造 knowledge |
| D-008 | クラスA/B/C モデル: 生成先を直接編集しない、クラスB は mkLink 必須、配列は全置換、等 | 管理方式の制約（G-015 と重複）|
| D-009 | `~/agent-skills` 編集後は `nix flake update agent-skills`（NAR hash mismatch 回避）、`skills-push` | 実障害由来の手順 |
| D-010 | コミット前にシークレット系パスを確認 | 情報漏洩防止（D-002 重複）|
| D-011 | 更新後は確認せず commit・push、git 履歴は書き換えない（G-014 と同一）| コミット運用 |

### C-* : cdk-starter `AGENTS.md`（repo, always）

| ID | Instruction | Intended behavior |
|---|---|---|
| C-001 | repo の目的: AI-agent-driven CDK TS harness、Codex/Cursor/Kiro が安全に作業 | 文脈設定 |
| C-002 | TypeScript-only CDK v2、pnpm、VitePlus、cdk-nag、Nix devShell | toolchain 固定 |
| C-003 | Setup: `nix develop` → `pnpm install --frozen-lockfile` → `pnpm agent:check` | 初期手順 |
| C-004 | Validation: `vp check` `vp test` `pnpm synth` `pnpm agent:check` | 検証コマンド固定 |
| C-005 | AWS mutation 前は `pnpm agent:predeploy`（認証済み sandbox のみ）| predeploy ゲート |
| C-006 | テスト方針: `Template.fromStack` 細粒度、snapshot は意図的 drift、construct 変更時は test 更新、`createCdkApp()` | テスト作法 |
| C-007 | セキュリティ方針: public S3 禁止、encryption、IAM `*` 回避、RemovalPolicy 記述、cdk-nag 必須、`acknowledgeRule` のみ | セキュリティ制約 |
| C-008 | `cdk deploy`/`cloudformation deploy`/`cdkd`/`delstack`/破壊的 aws コマンド禁止、`$aws-sandbox-run` 経由 | 破壊的操作の抑止（instruction 層）|
| C-009 | CDK LSP は experimental、agent:check 外 | ツール案内 |
| C-010 | `$aws-sandbox-run` は外部 skill を参照、repo は呼び出し規約のみ | 責務分離 |
| C-011 | Required rules 7項目（TS only / test 更新 / agent:check / no direct deploy / sandbox-run / review:evidence / reviewer は advisory）| C-002〜C-008 の再掲 |
| C-012 | `pnpm review:evidence` → `.review/` Evidence Bundle、manifest が routing source of truth、reviewer 出力は merge gate ではない | レビュー workflow |
| C-013 | Agent handoff format（変更点/コマンド結果/残リスク/AWS mutation 有無）| 引き継ぎ出力形式 |

### CS-* : cdk-starter その他（rules / steering / agents / skills / hooks）

薄い pointer ファイルは個別 atom 化せず、Phase 4 で挙動へ集約する。固有の atom を持つのみ列挙:

| ID | Source | Instruction | Intended behavior |
|---|---|---|---|
| CS-001 | `.cursor/rules/cdk-typescript.mdc` | Construct ID に `Stack` suffix を付けない（awscdk-lint）| lint 由来の命名制約（AGENTS.md 未記載の固有 atom）|
| CS-002 | `.cursor/rules/testing-vitest-cdk.mdc` | import は `vite-plus/test`（Jest ではない）| 実装詳細の固定 |
| CS-003 | `.agents/skills/cdk-change-review` + `reviewer-contract.md` | deterministic evidence 先行 → reviewer は `.review/` のみ見る → schema-valid JSON、advisory、hypothesis は blocker 不可 | レビューの evidence 境界と出力契約（C-012 の詳細実装）|
| CS-004 | `.codex/hooks/inject_repo_context.py` | SessionStart で AGENTS.md 先頭4000文字 + agent:check/no-deploy を注入 | AGENTS.md の重複配信（hook 経由）|
| CS-005 | `.codex/hooks/subagent_context.py` | Subagent へ5行の policy 注入 | 同上（subagent 向け）|
| CS-006 | `.kiro/agents/*.json` | 各 agent に `resources:` で AGENTS.md/steering/docs/skill を束ねる | Kiro agent の context 構成 |
| CS-007 | `.agents/skills/aws-sandbox-run`（local thin）| README → 外部 `~/agent-skills/aws-sandbox-run/SKILL.md` の3-way を読め | 外部 skill への誘導（runner 選択は外部が owner）|
| CS-008 | `.agents/skills/agent-quality-gate` | `pnpm agent:check` を明示実行、husky は代替にしない、predeploy は optional | 完了ゲートの強調 |

### S-* : `~/agent-skills`（global, conditional）

各 skill は workflow 単位で atom 化（行単位分解はしない）。

| ID | Source | Intended behavior |
|---|---|---|
| S-001 | `aws-sandbox-run` | AWS 実行境界: 3-way runner 選択（PoC→aws-sandbox-run / app→aws-app-run / 自律 agent→aws-agent-lease）、account class 判定、AUTO_DELETE/expires_at タグ、Management 禁止、障害モード |
| S-002 | `dotfiles-nix-maintenance` | dotfiles 保守 runbook: クラスA/B/C、NAR hash/PAT/path-input 落とし穴、skills-push workflow、commit+push |
| S-003 | `skill-creator` | skill 作成・eval workflow（with_skill vs baseline 同時 spawn、assertions、timing 記録、viewer）|
| S-004 | `herdr` | HERDR_ENV=1 確認 → `herdr` CLI で pane/agent 制御（CLI discovery 手順）|
| S-005 | `browser-use` | agent-browser 既定、playwright-cli は診断系のみ、の使い分け表 |
| S-006 | `yomiyasu` | AI 臭い日本語の書き換えルール集（文末・論理・比喩等の詳細規則）|
| S-007 | `natural-japanese` | 日本語執筆 workflow: quick/full モード、lint+レビュー工程、doctype references |
| S-008 | `drawio` | drawio XML 生成 → export → open の手順、CLI 検出 |
| S-009 | `wezterm-config-sync` | WezTerm の編集対象決定表（Nix source vs mirror）、sudo rebuild |
| S-010 | `bws-secrets` | Keychain→BWS 認証、出力フィルタ必須、read-only scope |
| S-011 | `best-practices` | claude-code-best-practice を pull → 参照しながらレビュー（everything-claude-code は使わない）|
| S-012 | `grilling`/`grill-me` | 設計ツリー frontier 式インタビュー（grill-me は 7 行のエイリアス）|

---

## Phase 3 — Intent reconstruction

git history / docs / 実験データから分類。

| Atom群 | 分類 | 根拠 |
|---|---|---|
| G-001, G-004, G-013, G-015, D-002, D-007, D-008 | **Project knowledge** | 外部から知り得ない環境・管理方式の事実 |
| G-002, D-003 | **Model weakness workaround** | `darwin-rebuild` が root 必須という機種固有の失敗を回避 |
| G-003, D-005, D-009 | **Model weakness workaround（実障害由来）** | `/nix` 未マウント・NAR hash mismatch は実際に発生した障害の codify（commit `cedd24f`, `91eb2f6`, `9e6de3d`）|
| G-005, G-007, G-008, G-011 | **Workflow guidance / preference** | ツール固定のユーザー偏好（agent が自力では選べない選好）|
| G-006, G-016 | **Preference（微細）** | 効果の機会が稀 |
| G-012 | **Redundancy** | G-007/008/011 の再掲表 |
| G-010 | **Project knowledge** | CI 方針 |
| G-014, D-011 | **Workflow guidance** | コミット自動化の許可（ユーザー明示の運用）|
| D-004 | **Model weakness workaround** | TCC 再プロンプトの実観測（commit `90943e8`）|
| C-001〜C-004 | **Project knowledge + Redundancy 混在** | repo 目的・技術スタックは package.json/flake.nix/README から取得可能な部分が大きい |
| C-005〜C-008, C-012 | **Project knowledge（非標準 workflow）** | repo 独自の安全 workflow |
| C-011 | **Redundancy** | C-002〜C-008 の再掲 |
| C-013 | **Quality improvement** | 引き継ぎ形式の統一 |
| CS-001, CS-002 | **Project knowledge** | lint/テストの実装詳細（repo 探索で部分的に発見可能）|
| CS-004, CS-005 | **Redundancy（配信経路の重複）** | AGENTS.md を hook で再注入しているだけ |
| CS-006 | **Workflow guidance** | Kiro agent の context 束ね |
| CS-007 | **Workflow guidance** | 外部 skill への誘導 |
| CS-008 | **Quality improvement（実測では効果なし）** | darwin dim8: with_skill=baseline=6 |
| S-001 | **Project knowledge + Model weakness workaround** | アカウント構成・runner・落とし穴は外部から知り得ない |
| S-002 | **Project knowledge（実障害由来）** | git log: NAR hash / PAT / path input は全て実障害の codify |
| S-003 | **Workflow guidance** | skill 作成・eval の方法論 |
| S-004, S-005, S-008, S-009 | **Project knowledge / tool usage** | 各ツールの正しい使い方（docs で代替可能な部分もあるが conditional load で安い）|
| S-006, S-007 | **Quality improvement** | 日本語品質のドメイン知識（agent 標準を超える品質狙い）|
| S-010 | **Project knowledge + safety** | Keychain 名・フィルタ必須は環境固有 |
| S-011 | **Workflow guidance** | 参照 repo の使い方 |
| S-012 | **Quality improvement** | インタビュー手法 |
| `~/agent-skills` の CHECKPOINT/Failure modes/Do not 定型 | **Quality improvement（一括自動付与）** | PR #1 `auto-optimize` で機械的に追加。`skill-creator` への適用は一度 revert 済み（`fe1164b`）→ 画一的追加が常に有効とは限らない実績あり |

---

## Phase 4 — Behavior Map

同一挙動を狙う atom を統合。**1 行 = 1 挙動、列 = その挙動を指示している mechanism**。

### B-01: AWS 変更系コマンドを直接実行せず runner 経由にする

| Mechanism | Source | 内容の重複度 |
|---|---|---|
| AGENTS.md | cdk-starter `AGENTS.md` C-008, C-010, C-011 | canonical |
| Cursor Rule | `.cursor/rules/no-direct-deploy.mdc`（alwaysApply）| AGENTS.md の再掲 |
| Kiro Steering | `.kiro/steering/deployment.md` | 同上 |
| Skill（local）| `.agents/skills/aws-sandbox-run/SKILL.md` | 外部 skill への pointer |
| Skill（external）| `~/agent-skills/aws-sandbox-run` | runner 選択の本体（唯一の正本）|
| Custom Agent | `.cursor/agents/*` `.kiro/agents/*` の各 prompt | 「never cdk deploy」を各所で再掲 |
| Hook（enforcement）| `.cursor/hooks/`, `.kiro/hooks/`, `.codex/hooks/block_direct_deploy.py` | **対象外だが実効の担保** |
| Hook（注入）| `.codex/hooks/inject_repo_context.py`, `subagent_context.py` | AGENTS.md + policy の再注入 |

→ **instruction 層は AGENTS.md + 外部 skill の2箇所で足りる**。残りは再掲。enforcement（hooks）が別途存在するため instruction を削っても抑止力は残る。

### B-02: 完了前に `pnpm agent:check` を実行する

| Mechanism | Source |
|---|---|
| AGENTS.md | C-004, C-011, C-013 |
| Cursor Rule | `lint-format-oxc.mdc`, `no-direct-deploy.mdc` |
| Kiro Steering | `agent-workflow.md` |
| Skill | `agent-quality-gate/SKILL.md`（darwin dim8: with=baseline=6 → **lift 実測ゼロ**）|
| Hook（enforcement）| `.kiro/hooks/post-task-quality-gate`, `.cursor/hooks/remind-agent-check.sh`, `.codex/hooks/validate_stop.py` |
| Hook（注入）| `.codex/hooks/*`（agent:check を再掲）|

→ 最も重複が激しい挙動。enforcement hook が 3 系統あり、skill の実測 lift はゼロ。

### B-03: CDK テスト作法（Vitest 系 / fine-grained / snapshot / negative assertions）

| Mechanism | Source |
|---|---|
| AGENTS.md | C-006 |
| Cursor Rule | `testing-vitest-cdk.mdc`（`vite-plus/test` import は固有情報 CS-002）|
| Kiro Steering | `testing.md` |
| Skill | `cdk-unit-test/SKILL.md`（dim8: 6.5, A=7/B=6 → 小幅 lift）|
| Custom Agent | `cdk-test-engineer`（cursor/kiro）|

### B-04: CDK セキュリティ制約（public S3/IAM/RemovalPolicy/cdk-nag/acknowledgeRule）

| Mechanism | Source |
|---|---|
| AGENTS.md | C-007 |
| Cursor Rule | `security-cdk.mdc` |
| Kiro Steering | `security.md` |
| Skill | `cdk-security-review/SKILL.md`（dim8: 8.5, A=9/B=8 → **最大の実測 lift**）|
| Custom Agent | `cdk-security-reviewer` |
| docs | `docs/security.md`（3層ゲートの正本）|

### B-05: CDK 変更レビューは deterministic evidence 先行・reviewer は advisory

| Mechanism | Source |
|---|---|
| AGENTS.md | C-012 |
| Skill | `cdk-change-review/SKILL.md` + `reviewer-contract.md` |
| Custom Agent | `cdk-change-reviewer`（cursor/kiro、契約の再掲）|
| docs | `docs/review-evidence.md` |

### B-06: dotfiles のクラスA/B/C 管理モデル（merge/link、生成先を直接編集しない）

| Mechanism | Source | 重複度 |
|---|---|---|
| Global AGENTS | G-015（~70行、全 repo で常時 load）| 詳細版 |
| Repo AGENTS | D-008 | 要約版 |
| docs | `docs/management-policy.md` | 正本 |
| Skill | `dotfiles-nix-maintenance`（S-002）| 詳細版 + 落とし穴 |

→ 同一知識が 4 箇所。正本は `management-policy.md`、dotfiles repo 作業時は `AGENTS.md` D-008、他 repo 作業時は skill が conditional で拾う → **G-015 は global 常時 load から外せる**。

### B-07: このマシンは `sudo darwin-rebuild switch` が必要

G-002 / D-003 / S-002 / S-009（wezterm-config-sync 内でも再掲）。事実は 1 つ。

### B-08: ツール固定（uv / pnpm / Vite+-oxlint-oxfmt / Nix 主軸 / mise 移行期間）

G-005, G-007〜G-011 + G-012 NG 表（再掲）。global AGENTS.md のみ。

### B-09: agent-skills flake input の落とし穴（NAR hash / path input / skills-push）

D-009 / S-002。git history 由来の障害記録。

### B-10: `/nix` 未マウント復旧

G-003 / D-005 / S-002。

### B-11: 日本語文章品質

S-006（yomiyasu）と S-007（natural-japanese）が**重複する 2 skill**。natural-japanese が「正規」（lint ツール・doctype 体系あり）、yomiyasu は後発（`5d59dac`, nanaism/yomiyasu 由来）でルール集のみ。

### B-12: dotfiles 更新後は確認せず commit/push

G-014 / D-011 / S-002 Completion 節。

### B-13: シークレットをコミット・露出しない

D-002 / D-010 / G-013 / S-010（bws の出力フィルタ）。

### B-14: cdk-starter repo の構造・技術スタック

C-001, C-002 / `.kiro/steering/{product,tech,structure}.md` / docs。→ **package.json, flake.nix, README, ディレクトリ構造から発見可能**な部分が大半。

### B-15: synth/typecheck の debug 手順

`cdk-synth-debug/SKILL.md`（dim8: 7.0, A=8/B=6 → lift あり）。

### B-16: diff の説明（pasted vs live）

`cdk-diff-explain/SKILL.md` + C-005。dim8: 5.5, A=6/B=5 → **parity**（skill が AGENTS.md を超える差分ほぼなし、results.tsv `stop_dim8_parity_with_AGENTS`）。

### B-17: 単発ドメイン skill（重複なし、conditional load）

S-003〜S-005, S-008〜S-012: skill-creator / herdr / browser-use / drawio / wezterm / bws / best-practices / grilling。各々独立した挙動、他 mechanism と非重複。

---

## Phase 5–6 — Necessity Matrix & 分類

判断手順: Q1 project 固有? → Q2 repo 探索で取得可能? → Q3 標準能力? → Q4 重複? → Q5 失敗モードを説明できるか。
既存実測（darwin dim8 = with_skill vs baseline の judge 評価）を優先し、新規実験は VERIFY 分のみ。

### 分類結果

| Behavior / Atom | 分類 | 理由 |
|---|---|---|
| B-01 instruction 層の再掲群（`.cursor/rules/no-direct-deploy.mdc`, `.kiro/steering/deployment.md`, agents prompt 内の再掲, codex 注入 hook CS-004/005 の no-deploy 行）| **VERIFY→DELETE** | AGENTS.md が canonical、外部 skill が本体、hook が enforcement。instruction 削っても抑止力は hook が担保。失敗モード: なし（AGENTS.md 残存）。ただし Cursor/Kiro が AGENTS.md を常時読むかは要確認 |
| B-02 `agent-quality-gate` skill + 再掲群 | **DELETE（skill）/ VERIFY** | dim8 lift ゼロ実測済み + enforcement hook 3 系統。AGENTS.md C-004 に集約 |
| B-03 `cdk-unit-test` skill | **KEEP（SIMPLIFY 検討）** | dim8 小幅 lift。`vite-plus/test` import（CS-002）は repo 固有。AGENTS.md との境界線上だが conditional load で安い |
| B-04 `cdk-security-review` skill | **KEEP** | 最大の実測 lift。checklist が agent の見落としを減らす |
| B-05 `cdk-change-review` + contract | **KEEP** | `.review/` pipeline は repo 独自で非発見可能 |
| B-06 G-015（global AGENTS.md の管理方式 ~70行）| **MOVE** | dotfiles 固有知識が全 repo の context を占有。正本 `management-policy.md` + repo `AGENTS.md` D-008 + skill S-002 に集約。global 側は 2〜3 行の pointer で十分 |
| B-07 sudo rebuild | **KEEP（集約）** | 機種固有の失敗モードが明確。global は G-002 の1行のみ残す |
| B-08 ツール固定セクション | **KEEP（SIMPLIFY）** | 選好は agent が推論不可能 → 方針文は残す。コマンド表・詳細手順（`vp` の全サブコマンド列挙等）は `--help`/docs で取得可能 → 削減。NG 表 G-012 は本文と重複 → **DELETE** |
| B-09 NAR hash 落とし穴 | **KEEP** | 実障害由来。global からは外し D-009 + S-002 に集約（MOVE）|
| B-10 /nix 復旧 | **KEEP** | 失敗モード明確（再起動後全 CLI 喪失）。G-003 は 2 行で十分 |
| B-11 yomiyasu ↔ natural-japanese | **VERIFY** | 機能重複の 2 skill。統合するか役割分離（yomiyasu=ルール集, natural-japanese=workflow+lint）を決める必要あり |
| B-12 commit+push 自動化 | **KEEP** | ユーザー明示の運用。失敗モード: なければ毎回確認待ちで停滞 |
| B-13 シークレット防御 | **KEEP（SIMPLIFY）** | D-002 と D-010 が重複 → 統合 |
| B-14 steering `product/tech/structure.md` | **DELETE** | README/package.json/flake.nix/ディレクトリ構造から発見可能。steering の存在意義が薄い |
| B-15 `cdk-synth-debug` | **KEEP** | lift 実測あり、安い |
| B-16 `cdk-diff-explain` | **VERIFY** | dim8 parity 実測済み。「削除しても差が出ない」が既実測だが、確認実験を残すなら対象 |
| B-17 単発 skills | **KEEP** | conditional load、不使用時のコストは description のみ |
| CS-001 Stack suffix 禁止 | **KEEP（AGENTS.md へ集約可）** | oxlint-plugin-awscdk 設定から発見可能だが明示で安い。AGENTS.md に1行あれば rule ファイルは不要 |
| CS-002 `vite-plus/test` import | **KEEP（集約）** | 同上 |
| CS-006 `.kiro/agents/*.json` + `.cursor/agents/*.md`（薄い prompt）| **SIMPLIFY / VERIFY** | prompt がほぼ AGENTS.md 再掲。resources 束ねは Kiro 固有の価値。`cdk-change-reviewer` のみ contract 上の意味あり、他5個は削減候補 |
| G-006 apt micro-rule, G-016 WSL パス変換 | **DELETE / VERIFY** | 発動機会が稀、Q5 の失敗説明が弱い（apt-get が動作する点で実害は小さい。パス変換は間違うと file not found → VERIFY 寄り）|
| `.codex/hooks` の context 注入（CS-004, CS-005）| **DELETE / VERIFY** | Codex は repo AGENTS.md を native で読む。注入は重複配信。hook 本体は enforcement 扱いで対象外だが「注入する自然言語」は対象内 → 注入自体の削除を VERIFY |
| `home/ai/AGENTS.md` 全体 | **SIMPLIFY** | 193 行 → 目標 ~60 行。方針文のみ残し、詳細手順・管理知識・NG 表を削減 |
| dotfiles `AGENTS.md` | **KEEP（微 SIMPLIFY）** | repo 作業ガイドとして妥当。D-010 → D-002 統合程度 |
| cdk-starter `AGENTS.md` | **KEEP（SIMPLIFY）** | canonical の1点集約先。C-011 Required rules は前文との再掲 → 削減検討 |
| `grill-me` | **DELETE or KEEP** | 7 行のエイリアス。`grilling` の trigger 語を広げれば不要。コストほぼゼロ → 優先度低 |
| `~/agent-skills` 内の CHECKPOINT/Failure-modes 定型表 | **VERIFY（部分削減）** | auto-optimize で機械付与された層。dim8 を上げた実績はあるが、skill-creator への適用 revert 例もあり一括の正当性は未検証 |
| Kiro powers（cloud-architect, stripe）/ AWS toolkit skills ~21 | **別 Issue** | vendor plugin。K-210 本文の通り独立評価へ defer |
| `.kiro/steering/*.md`（deployment 以外の6ファイルも含む）| **DELETE** | B-14 と同じく再掲/発見可能情報のみ |
| `.cursor/rules/*.mdc`（no-direct-deploy 以外の4本）| **DELETE / VERIFY** | glob/description 起動の conditional rule。内容は AGENTS.md + skill に存在。CS-001/002 の固有 atom だけ AGENTS.md へ移せば削除可能 |

### Deletion proposal（まとめ）

**即削除候補（既存証拠で判断可能）**

1. `.kiro/steering/*.md` ×7 — 全て AGENTS.md/docs の再掲か repo 発見可能情報
2. `.cursor/rules/*.mdc` ×5 — 同上。CS-001/CS-002 の2行だけ `AGENTS.md` へ移す
3. `agent-quality-gate` skill — dim8 lift ゼロ実測 + hook 3 系統が enforcement
4. `home/ai/AGENTS.md` G-012 NG 表 — 本文と重複
5. `home/ai/AGENTS.md` G-015 管理方式詳細 — `management-policy.md` + repo AGENTS.md + skill に集約し、global は pointer 化（実質 MOVE→global 側は削除）
6. `.codex/hooks/` の context 注入（inject_repo_context / subagent_context）— Codex が AGENTS.md を native 読込するため重複配信
7. `.cursor/agents/*.md` `.kiro/agents/*.json` 各5個（cdk-change-reviewer 以外）— prompt が再掲のみ
8. `cdk-diff-explain` skill — dim8 parity 実測
9. `.cursor/skills`, `.kiro/skills` の symlink 群は skill 本体削除に伴い整理
10. `grill-me` — alias（任意）

**残すもの（KEEP）**

- cdk-starter `AGENTS.md`（canonical 化、軽い SIMPLIFY）
- `cdk-change-review` + `reviewer-contract` / `cdk-security-review` / `cdk-synth-debug` / `cdk-unit-test`（実測 lift または repo 独自 workflow）
- `~/agent-skills` 全般（aws-sandbox-run 本体, dotfiles-nix-maintenance, ドメイン skill 群）— conditional load で不使用時コストが description のみ
- dotfiles `AGENTS.md`、`home/ai/AGENTS.md` の環境・選好・障害対応コア（SIMPLIFY 後）
- `.kiro/agents/cdk-change-reviewer.json`（contract 上の単一 reviewer 指定に意味あり）+ 対応する Cursor 側は optional

**削減量の見込み**

- global 常時 load: `home/ai/AGENTS.md` 193 → ~60 行（-65%）
- cdk-starter 常時 load: `AGENTS.md` + `no-direct-deploy.mdc` ~130 行 → ~100 行（rules 5 本・steering 7 本・agents 10 個・skill 2 個・注入 hook 2 個の削除で、conditional 層は 7 skill → 4〜5 skill、薄い wrapper はほぼ消滅）
- 削減後の instruction 正本: AGENTS.md（repo ごと 1 点）+ 外部 skill（conditional）+ enforcement hook（対象外として温存）の 3 層に整理

---

## Phase 7 — Verification backlog（VERIFY 分のみ実験仮説）

共通 baseline: Devin SWE-2、user harness 最小の一時環境、3〜5 run、主指標は「自律的に正しい行動を取る率」。

| Behavior | Baseline expectation | Harness（最小 instruction）| Task / fixture | Metric | Decision rule |
|---|---|---|---|---|---|
| V-1: thin pointer 層（cursor rules / kiro steering / agents）を全削除しても repo ルール遵守が維持されるか | AGENTS.md のみで TS-only・test 更新・agent:check 実行・no direct deploy を行う（Devin は AGENTS.md を常時読む）| なし（削除後状態）| cdk-starter で「SQS queue construct を追加して」| 5項目中の遵守数（TS-only / test 追加 / `pnpm agent:check` / deploy 未実行 / vite-plus/test import）| 4/5 以上なら削除確定。import 間違いが出たら CS-002 のみ残す |
| V-2: `agent-quality-gate` skill 削除 | AGENTS.md の「run pnpm agent:check」+ hook だけで完了前実行率は変わらない（dim8 parity 実測を再確認）| なし | 「README に1行追記して」のような雑務 | agent:check を自発実行する率 | ≥80% なら削除確定 |
| V-3: `cdk-diff-explain` skill 削除 | pasted-diff の説明品質は AGENTS.md+docs で同等（dim8 parity の再確認）| なし | 固定の cdk diff テキストを貼り「リスクを説明して」| judge: security impact の言及・deploy 拒否 | baseline と差≤10% なら削除確定 |
| V-4: codex context 注入 hook 削除 | SessionStart 注入なしでも AGENTS.md 読込で同等 | なし | Codex で fixture タスク | no-deploy/agent:check 遵守 | 差なしなら hook 簡素化 |
| V-5: global AGENTS.md のツール固定（uv/pnpm）削除の是非 | 「新規 Python スクリプトを作って」で venv+pip を選ぶ | 「Python は uv、JS は pnpm」の1行 | 空 dir で「簡単な JSON 整形スクリプトを書いて」| uv/pnpm 選択率 | baseline が誤選択なら instruction 維持（=KEEP 確定で実験は削除判断には不要、SIMPLIFY 境界の確認用）|
| V-6: yomiyasu vs natural-japanese 重複 | 片方のみで同等品質 | 各 skill 単体 | 同一の AI 臭い日本語文書を脱臭 | 出力品質 judge + 所要時間 | 差がなければ natural-japanese に統合（yomiyasu はルール reference 化）|
| V-7: CHECKPOINT/Failure-modes 定型の効果 | 定型表なしの skill でも同等の失敗回避 | 定型表を削った版 | 失敗を誘発する fixture（runner 不在等）| 失敗時の適切な挙動率 | 差がなければ定型表を部分削減可 |

**実験しないもの**: S-001/S-002 のような project knowledge skill（失敗モードが自明かつ実障害由来）、B-06 の MOVE（配置の問題で効果の問題ではない）、vendor plugin（別 Issue）。

---

## 所見サマリ

1. **最大の構造的問題は「canonical 1点 + 再掲 N 点」**: cdk-starter では B-01/B-02 が 6〜10 mechanism に分散。enforcement hook が残るため instruction 層の再掲はほぼ全て削れる。
2. **global AGENTS.md は dotfiles 内部知識の漏出が大きい**: G-015（~70行）は全 repo session の context を占有。`management-policy.md` 正本化が済んでいる今、global 側は数行の pointer でよい。
3. **実測データ（darwin dim8）が既に回答している削除判断が多い**: agent-quality-gate（lift 0）、cdk-diff-explain（parity）は追加実験なしで削除可能。
4. **KEEP の中核は「発見不可能な project knowledge」と「実測 lift のある checklist」**: aws-sandbox-run、cdk-security-review、review evidence pipeline、障害対応 runbook。
5. **vendor plugin 層（AWS toolkit skills ~21, Kiro powers ×2, MCP）は本 Issue では未着手**: 別 Issue で同じ分解手順を適用する価値あり。

