#!/usr/bin/env bash
set -euo pipefail

data=$(cat)
last_msg=$(echo "$data" | jq -r '.last_assistant_message // ""' 2>/dev/null)

if [[ -n "$last_msg" && "$last_msg" != "null" ]]; then
  msg=$(echo "$last_msg" | tr '\n' ' ' | cut -c1-80)
else
  msg="Claude Code: response completed"
fi

if command -v powershell.exe >/dev/null 2>&1; then
  msg_safe=$(echo "$msg" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
  ps_cmd=$(cat <<'EOF'
$null = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
$null = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]
$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
$xml.LoadXml("<toast><visual><binding template='ToastText01'><text id='1'>MSG_PLACEHOLDER</text></binding></visual></toast>")
$toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("Claude Code").Show($toast)
EOF
)
  ps_cmd="${ps_cmd/MSG_PLACEHOLDER/$msg_safe}"
  encoded=$(echo -n "$ps_cmd" | iconv -t UTF-16LE | base64 -w 0)
  powershell.exe -EncodedCommand "$encoded" 2>/dev/null || true
elif command -v osascript >/dev/null 2>&1; then
  osascript -e "display notification \"$msg\" with title \"Claude Code\""
else
  printf 'Claude Code: %s\n' "$msg"
fi
