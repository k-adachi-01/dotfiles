#!/bin/sh
# Shared commit-boundary guard for Devin, Codex, Kiro and Pi.
# UserPromptSubmit calls "begin" to record HEAD. Stop requests one review
# only when new commits were added during the turn. State is runtime-only.
set -eu

input=$(cat || true)
session=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null || true)
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)
[ -n "$session" ] && [ -n "$cwd" ] || exit 0
cd "$cwd" 2>/dev/null || exit 0
root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
head=$(git rev-parse --verify HEAD 2>/dev/null || printf 'unborn')
key=$(printf '%s\n%s\n' "$session" "$root" | cksum | cut -d' ' -f1)
state_dir="${TMPDIR:-/tmp}/agent-task-finish-guard-$(id -u)"
umask 077
mkdir -p "$state_dir" 2>/dev/null || exit 0
marker="$state_dir/$key"

case "${1:-}" in
  begin|clear)
    # "clear" supports Kiro sessions that still loaded the old hook file.
    printf '%s\n' "$head" > "$marker"
    exit 0
    ;;
esac

printf '%s' "$input" | jq -e '.stop_hook_active == true' >/dev/null 2>&1 && exit 0
[ -f "$marker" ] || exit 0
before=$(cat "$marker")
# Consume before continuing: documentation follow-up commits cannot loop.
rm -f "$marker"
[ "$head" != unborn ] && [ "$before" != "$head" ] || exit 0
if [ "$before" != unborn ]; then
  git merge-base --is-ancestor "$before" "$head" 2>/dev/null || exit 0
fi

jq -n '{
  decision: "block",
  reason: "commitの節目なので、共有すべき変更がある場合だけ反映してください。ドキュメントは、仕様・使い方・運用手順が変わり、既存の説明が古くなる箇所だけ更新してください。作業ログや軽微な修正の記録は追加しないでください。Linearは、この作業に直接対応するissueがあり、完了・ブロック・重要な方針変更など共有すべき変化がある場合だけ更新してください。issue IDが会話やブランチ名にあるだけでは更新せず、細かな進捗や既出の内容を重複してコメントしないでください。必要な更新が済んでいる場合や該当する変更がない場合は、そのまま終了してください。"
}'
