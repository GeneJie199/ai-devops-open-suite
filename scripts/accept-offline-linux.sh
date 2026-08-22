#!/usr/bin/env bash
set -Eeuo pipefail

archive=${1:-}
work=${2:-}
[[ -f "$archive" ]] || { printf 'Usage: accept-offline-linux.sh ARCHIVE [WORK_DIR]\n' >&2; exit 2; }
if [[ -z "$work" ]]; then work=$(mktemp -d /tmp/ai-devops-v1-accept.XXXXXX); fi
case "$work" in /tmp/ai-devops-v1-accept.*) ;; *) printf 'Acceptance work directory must use /tmp/ai-devops-v1-accept.*\n' >&2; exit 2 ;; esac
[[ ! -L "$work" ]] || { printf 'Acceptance work directory must not be a symbolic link.\n' >&2; exit 2; }
mkdir -p "$work/extract"

prefix="$work/install"
controller="$prefix/bin/suitectl"
cleanup() {
  if [[ -x "$controller" ]]; then "$controller" stop >/dev/null 2>&1 || true; fi
  case "$work" in /tmp/ai-devops-v1-accept.*) rm -rf -- "$work" ;; esac
}
trap cleanup EXIT

tar -xzf "$archive" -C "$work/extract"
bundle="$work/extract/ai-devops-open-suite"
installer="$bundle/scripts/install-suite.sh"
[[ -x "$installer" && -f "$bundle/install-assets.txt" ]] || { printf 'Offline bundle layout is invalid.\n' >&2; exit 1; }

readarray -t ports < <(python3 - <<'PY'
import socket
sockets=[]
try:
    for _ in range(4):
        sock=socket.socket()
        sock.bind(("127.0.0.1", 0))
        sockets.append(sock)
    for sock in sockets:
        print(sock.getsockname()[1])
finally:
    for sock in sockets:
        sock.close()
PY
)
export AI_DEVOPS_DEVCYCLE_PORT=${ports[0]}
export AI_DEVOPS_INFRASCOUT_PORT=${ports[1]}
export AI_DEVOPS_FLEETSCOPE_PORT=${ports[2]}
export AI_DEVOPS_RELEASEGUARD_PORT=${ports[3]}

netns=unavailable
if command -v unshare >/dev/null && unshare -Urn true >/dev/null 2>&1; then
  netns_prefix="$work/install-netns"
  unshare -Urn env \
    AI_DEVOPS_DEVCYCLE_PORT="$AI_DEVOPS_DEVCYCLE_PORT" \
    AI_DEVOPS_INFRASCOUT_PORT="$AI_DEVOPS_INFRASCOUT_PORT" \
    AI_DEVOPS_FLEETSCOPE_PORT="$AI_DEVOPS_FLEETSCOPE_PORT" \
    AI_DEVOPS_RELEASEGUARD_PORT="$AI_DEVOPS_RELEASEGUARD_PORT" \
    "$installer" --prefix "$netns_prefix"
  [[ -f "$netns_prefix/config/install-state.json" ]] || { printf 'Network-isolated install did not write state.\n' >&2; exit 1; }
  netns=passed
fi

"$installer" --prefix "$prefix" --start
"$controller" doctor
"$controller" version
"$controller" stop
printf preserve-me >"$prefix/data/user-preserved.marker"

printf transaction-marker >>"$prefix/bin/devcycle"
transaction_hash=$(sha256sum "$prefix/bin/devcycle" | awk '{print $1}')
chmod 0500 "$prefix/protocols"
chmod 0400 "$prefix/protocols/"*
if "$controller" upgrade "$bundle" "$bundle/install-assets.txt" >"$work/transaction-failure.log" 2>&1; then
  printf 'Forced metadata commit failure was unexpectedly accepted.\n' >&2
  exit 1
fi
chmod 0700 "$prefix/protocols"
chmod 0600 "$prefix/protocols/"*
[[ $(sha256sum "$prefix/bin/devcycle" | awk '{print $1}') == "$transaction_hash" ]] || { printf 'Failed upgrade did not restore the previous binary.\n' >&2; exit 1; }
grep -q 'restoring the previous installation' "$work/transaction-failure.log" || { printf 'Failed upgrade did not report transaction restoration.\n' >&2; exit 1; }
cp "$bundle/assets/linux-amd64/devcycle-linux-amd64" "$prefix/bin/devcycle"
chmod 0755 "$prefix/bin/devcycle"

"$controller" upgrade "$bundle" "$bundle/install-assets.txt"
upgrade_backup=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["previousBackup"])' "$prefix/config/install-state.json")
printf tamper >>"$prefix/backups/$upgrade_backup/bin/devcycle"
if "$controller" rollback "$upgrade_backup" >"$work/tampered-backup.log" 2>&1; then
  printf 'Tampered rollback backup was unexpectedly accepted.\n' >&2
  exit 1
fi
grep -q 'integrity check failed' "$work/tampered-backup.log" || { printf 'Tampered backup failure was not actionable.\n' >&2; exit 1; }
cp -p "$prefix/bin/devcycle" "$prefix/backups/$upgrade_backup/bin/devcycle"
"$controller" rollback "$upgrade_backup"
rollback_backups=$(find "$prefix/backups" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
"$controller" uninstall
[[ -f "$prefix/data/user-preserved.marker" && -f "$prefix/config/uninstall-state.json" ]] || { printf 'Uninstall did not preserve user state.\n' >&2; exit 1; }
if find "$prefix/bin" -maxdepth 1 -type f | grep -q .; then printf 'Uninstall left managed binaries behind.\n' >&2; exit 1; fi

"$installer" --prefix "$prefix"
controller="$prefix/bin/suitectl"
"$controller" purge --confirm "$prefix"
[[ ! -e "$prefix" ]] || { printf 'Explicit purge did not remove the suite path.\n' >&2; exit 1; }

empty_source="$work/empty-source"
mkdir -p "$empty_source/assets/linux-amd64"
if "$installer" --prefix "$work/missing-install" --manifest-index "$bundle/install-assets.txt" --source-root "$empty_source" >"$work/missing.log" 2>&1; then
  printf 'Missing offline asset was unexpectedly accepted.\n' >&2
  exit 1
fi
grep -q 'network fallback is disabled' "$work/missing.log" || { printf 'Missing asset failure did not prove network fallback protection.\n' >&2; exit 1; }

printf '{"platform":"linux-amd64","offline_install":"passed","network_namespace":"%s","runtime":"passed","doctor":"passed","failed_commit_restore":"passed","upgrade_backup":"%s","tampered_backup":"blocked","rollback_backups":%s,"uninstall_preserved_data":true,"purge":"passed","missing_asset_network_fallback":"blocked","ports":[%s,%s,%s,%s]}\n' \
  "$netns" "$upgrade_backup" "$rollback_backups" "${ports[0]}" "${ports[1]}" "${ports[2]}" "${ports[3]}"
