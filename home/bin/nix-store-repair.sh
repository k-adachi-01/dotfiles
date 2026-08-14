#!/bin/bash
# Repair a macOS Nix store that is missing after reboot.
#
# /nix is an APFS volume. After reboot it can stay unmounted (or land on
# /Volumes/Nix Store) when launchd/BTM does not start the Determinate or
# nix-darwin store daemon. CLI tools then vanish because they live in
# /nix/store. This script uses only OS paths so it still runs in that state.
#
# Do not delete the "Nix Store" volume and do not reinstall Nix first.
# The store is almost always intact.
set -euo pipefail

PATH="/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin"
export PATH

VOLUME_NAME="Nix Store"
ALT_MOUNT="/Volumes/Nix Store"

usage() {
  cat <<'EOF'
Usage: nix-store-repair [--status]

  (default)  Mount /nix if needed and start Nix/Determinate launch daemons.
  --status   Print diagnostics only; do not change anything.

Must be run on macOS. Re-executes with sudo when not root.
EOF
}

log() {
  printf '%s\n' "$*"
}

section() {
  printf '\n== %s ==\n' "$*"
}

store_readable() {
  [[ -d /nix/store ]] && ls /nix/store >/dev/null 2>&1
}

plist_label() {
  local plist="$1"
  /usr/bin/defaults read "$plist" Label 2>/dev/null || basename "$plist" .plist
}

existing_plists() {
  local plist
  shopt -s nullglob
  for plist in /Library/LaunchDaemons/systems.determinate*.plist /Library/LaunchDaemons/org.nixos.*.plist; do
    [[ -f "$plist" ]] && printf '%s\n' "$plist"
  done
  shopt -u nullglob
}

volume_field() {
  local key="$1"
  diskutil info -plist "$VOLUME_NAME" 2>/dev/null \
    | plutil -extract "$key" raw -o - - 2>/dev/null || true
}

fstab_uuid() {
  [[ -r /etc/fstab ]] || return 0
  awk '$1 !~ /^#/ && $2 == "/nix" { print $1; exit }' /etc/fstab \
    | sed -n 's/^UUID="\{0,1\}\([^"]*\)"\{0,1\}$/\1/p'
}

print_status() {
  section "Nix store"
  if store_readable; then
    log "/nix/store is readable"
  else
    log "/nix/store is NOT readable"
  fi
  if [[ -e /nix ]]; then
    ls -ld /nix 2>/dev/null || true
  else
    log "/nix does not exist (synthetic.conf may be missing; reboot required after adding it)"
  fi
  if [[ -d "$ALT_MOUNT" ]]; then
    log "WARNING: volume is mounted at $ALT_MOUNT instead of /nix"
    ls -ld "$ALT_MOUNT" 2>/dev/null || true
  fi

  section "APFS volume"
  if diskutil info "$VOLUME_NAME" >/dev/null 2>&1; then
    diskutil info "$VOLUME_NAME" | grep -E 'Device Node|Volume UUID|Disk / Partition UUID|Mount Point|FileVault|Volume Name|Disk Size' || true
  else
    log "No APFS volume named \"$VOLUME_NAME\" found"
    diskutil apfs list 2>/dev/null | grep -A4 -i nix || true
  fi

  section "/etc/synthetic.conf"
  if [[ -r /etc/synthetic.conf ]]; then
    cat /etc/synthetic.conf
  else
    log "(missing)"
  fi

  section "/etc/fstab"
  if [[ -r /etc/fstab ]]; then
    cat /etc/fstab
  else
    log "(missing)"
  fi

  section "Launch daemons"
  local plist label
  if [[ -z "$(existing_plists)" ]]; then
    log "No Determinate/nix-darwin LaunchDaemons found under /Library/LaunchDaemons"
  fi
  while IFS= read -r plist; do
    [[ -n "$plist" ]] || continue
    label="$(plist_label "$plist")"
    log "$plist  (Label=$label)"
    if launchctl print "system/$label" >/dev/null 2>&1; then
      log "  loaded"
    else
      log "  NOT loaded in the system domain"
    fi
  done < <(existing_plists)

  section "determinate-nixd"
  if [[ -x /usr/local/bin/determinate-nixd ]]; then
    log "present: /usr/local/bin/determinate-nixd"
  else
    log "not found at /usr/local/bin/determinate-nixd"
  fi

  section "BTM (background items)"
  if sfltool dumpbtm >/dev/null 2>&1; then
    sfltool dumpbtm | grep -B2 -A10 -iE 'nixos|determinate|darwin-store|nix-daemon|nix-store' || log "(no nix-related BTM entries matched)"
  else
    log "sfltool dumpbtm failed (needs root on some macOS versions)"
  fi
}

bootstrap_plist() {
  local plist="$1"
  local label
  label="$(plist_label "$plist")"
  log "bootstrap $label ($plist)"
  launchctl enable "system/$label" 2>/dev/null || true
  if launchctl print "system/$label" >/dev/null 2>&1; then
    launchctl kickstart -k "system/$label" 2>/dev/null || true
  else
    if ! launchctl bootstrap system "$plist" 2>/dev/null; then
      launchctl load "$plist" 2>/dev/null || true
    fi
    launchctl kickstart -k "system/$label" 2>/dev/null || true
  fi
}

print_btm_fix() {
  cat <<'EOF'

Persistent fix (required if this happens again after reboot):
  System Settings → General → Login Items & Extensions → Allow in the Background
  Enable entries named "sh", "Nix", or "Determinate" (often "Item from unidentified developer").
  If a toggle looks already ON, turn it OFF and ON again.

  launchctl bootstrap only lasts for this boot. BTM can block the same
  daemons on the next reboot until those background items are allowed.

Do NOT:
  - diskutil apfs deleteVolume "Nix Store"
  - reinstall Nix as the first step
  The volume is almost always intact; only the mount/daemon is missing.
EOF
}

repair() {
  local uuid plist

  if [[ ! -e /nix ]]; then
    log "ERROR: /nix does not exist. Add a line containing only \"nix\" to /etc/synthetic.conf, then reboot."
    print_btm_fix
    return 1
  fi

  section "Starting launch daemons"
  while IFS= read -r plist; do
    [[ -n "$plist" ]] || continue
    bootstrap_plist "$plist"
  done < <(existing_plists)

  if [[ -x /usr/local/bin/determinate-nixd ]]; then
    section "determinate-nixd init"
    /usr/local/bin/determinate-nixd init || log "determinate-nixd init exited $?"
  fi

  if [[ -d "$ALT_MOUNT" ]] && ! store_readable; then
    section "Remounting $ALT_MOUNT -> /nix"
    diskutil unmount force "$ALT_MOUNT" || true
  fi

  if ! store_readable; then
    section "Mounting \"$VOLUME_NAME\" at /nix"
    if ! diskutil mount -mountPoint /nix "$VOLUME_NAME"; then
      uuid="$(volume_field VolumeUUID)"
      if [[ -z "$uuid" ]]; then
        uuid="$(fstab_uuid)"
      fi
      if [[ -n "$uuid" ]]; then
        log "Retrying with UUID $uuid"
        diskutil mount -mountPoint /nix "$uuid" || true
      fi
    fi
  fi

  # Give launchd a moment after bootstrap/init.
  if ! store_readable; then
    sleep 2
  fi

  section "Result"
  if store_readable; then
    log "/nix/store is readable again."
    log "Open a new login shell (exec \"\$SHELL\" -l) so PATH picks up Nix CLIs."
    print_btm_fix
    return 0
  fi

  log "FAILED: /nix/store is still unreadable."
  log "If /etc/fstab's UUID no longer matches diskutil info \"$VOLUME_NAME\", edit it with sudo vifs."
  print_btm_fix
  return 1
}

main() {
  local mode="repair"

  case "${1:-}" in
    -h | --help)
      usage
      return 0
      ;;
    --status)
      mode="status"
      ;;
    "")
      mode="repair"
      ;;
    *)
      usage >&2
      return 2
      ;;
  esac

  if [[ "$(uname -s)" != "Darwin" ]]; then
    log "This script is for macOS only." >&2
    return 1
  fi

  if [[ $EUID -ne 0 ]]; then
    if [[ -f "$0" ]]; then
      log "Re-running with sudo..."
      exec sudo /bin/bash "$0" "$@"
    fi
    log "This script must run as root. Use sudo, or: curl ... | sudo /bin/bash" >&2
    return 1
  fi

  print_status
  if [[ "$mode" == "status" ]]; then
    return 0
  fi
  repair
}

main "$@"
