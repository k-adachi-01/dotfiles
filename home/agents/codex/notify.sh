#!/usr/bin/env bash
set -euo pipefail

payload=${1:-{}}
last_message=$(printf '%s' "$payload" | jq -r '.["last-assistant-message"] // "Codex task completed"')

if command -v powershell.exe >/dev/null 2>&1; then
  powershell.exe -Command "Import-Module BurntToast; New-BurntToastNotification -Text 'Codex', '$last_message'"
elif command -v osascript >/dev/null 2>&1; then
  osascript -e "display notification \"$last_message\" with title \"Codex\""
else
  printf 'Codex: %s\n' "$last_message"
fi
