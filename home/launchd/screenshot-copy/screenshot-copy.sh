#!/bin/bash
set -euo pipefail

PATH="/usr/bin:/bin:/usr/sbin:/sbin"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WATCH_DIR="${HOME}/Pictures/Screenshot"
STATE_FILE="${SCRIPT_DIR}/.last-copied"

latest_file() {
  local best_path=""
  local best_mtime=-1
  local path mtime

  while IFS= read -r -d '' path; do
    mtime=$(stat -f %m "$path" 2>/dev/null || echo 0)
    if (( mtime > best_mtime )); then
      best_mtime=$mtime
      best_path=$path
    fi
  done < <(find "$WATCH_DIR" -maxdepth 1 -type f ! -name '.*' -print0)

  printf '%s' "$best_path"
}

wait_until_stable() {
  local candidate="$1"
  local prev_size=-1
  local size

  for _ in {1..50}; do
    if [[ ! -f "$candidate" ]]; then
      sleep 0.1
      continue
    fi

    size=$(stat -f %z "$candidate" 2>/dev/null || echo 0)
    if [[ "$size" == "$prev_size" && "$size" -gt 0 ]]; then
      return 0
    fi

    prev_size="$size"
    sleep 0.1
  done

  return 1
}

main() {
  local latest last_copied

  latest="$(latest_file)"
  [[ -n "$latest" ]] || exit 0

  if [[ -f "$STATE_FILE" ]]; then
    last_copied="$(<"$STATE_FILE")"
    if [[ "$latest" == "$last_copied" ]]; then
      exit 0
    fi
  fi

  wait_until_stable "$latest" || exit 0

  printf '%s' "$latest" | /usr/bin/pbcopy
  printf '%s' "$latest" >"$STATE_FILE"
}

main "$@"
