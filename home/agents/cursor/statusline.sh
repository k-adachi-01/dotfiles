#!/usr/bin/env bash
set -euo pipefail

payload=$(cat)
model=$(echo "$payload" | jq -r '.model.display_name // "?"')
pct=$(echo "$payload" | jq -r '.context_window.used_percentage // 0' | awk '{ printf "%.0f", $1 }')
dir=$(echo "$payload" | jq -r '.cwd // .workspace.current_dir // ""')

wt=""
wt_name=$(echo "$payload" | jq -r '.worktree.name // empty')
if [[ -n "$wt_name" ]]; then
  printf -v wt '\033[33m[wt:%s]\033[0m ' "$wt_name"
fi

short="${dir##*/}"
branch_sfx=""
if [[ -n "$dir" ]] && git -C "$dir" rev-parse --git-dir >/dev/null 2>&1; then
  b=$(git -C "$dir" branch --show-current 2>/dev/null || true)
  if [[ -n "$b" ]]; then
    branch_sfx=$(printf ' | \033[35m%s\033[0m' "$b")
  fi
fi

printf '\033[36m%s\033[0m %s\033[90m📁 %s\033[0m  ctx \033[33m%s%%\033[0m%s' \
  "$model" "$wt" "$short" "$pct" "$branch_sfx"
