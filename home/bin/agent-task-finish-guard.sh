#!/bin/sh
# Shared turn-end guard used by the Stop hooks of Devin, Codex and Kiro.
#
# Reads the hook event JSON on stdin and prints
#   {"decision":"block","reason":"<instruction>"}
# at most once per user turn. The harness turns `reason` into a new user
# prompt, so the agent gets one extra pass to update related docs / Linear
# issues before it is allowed to finish.
#
# Modes:
#   agent-task-finish-guard         stop-hook mode (default)
#   agent-task-finish-guard clear   clears the per-session marker (Kiro
#                                   UserPromptSubmit companion hook)
set -eu

input=$(cat || true)

session=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null || true)
cwdkey=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null | cksum | cut -d' ' -f1)
marker="${TMPDIR:-/tmp}/agent-task-finish-guard-${session:-anon}-${cwdkey}"

if [ "${1:-}" = "clear" ]; then
  rm -f "$marker"
  exit 0
fi

if printf '%s' "$input" | jq -e 'has("stop_hook_active")' >/dev/null 2>&1; then
  # Devin / Codex: the harness sets stop_hook_active=true when a stop hook
  # already continued this turn; let the agent stop then.
  printf '%s' "$input" | jq -e '.stop_hook_active' >/dev/null 2>&1 && exit 0
else
  # Kiro does not send stop_hook_active; allow one continuation per user
  # prompt via a marker cleared by the UserPromptSubmit companion hook.
  [ -e "$marker" ] && exit 0
  touch "$marker"
fi

jq -n '{
  decision: "block",
  reason: "終了する前に確認してください: このタスクの作業内容に関連するドキュメント(repo 内の docs/, README, AGENTS.md など)があれば最新の状態に更新してください。また、ブランチ名や会話中に登場した issue ID(K-123 など)に対応する Linear issue があれば、Linear MCP ツールでステータスやコメントを更新してください。どちらも該当しない場合は、そのまま終了して構いません。"
}'
