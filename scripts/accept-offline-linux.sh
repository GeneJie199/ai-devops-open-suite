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
for _ in $(seq 1 50); do
  [[ -s "$prefix/data/fleetscope/agent-identity.json" && -s "$prefix/data/fleetscope/agents.json" ]] && break
  sleep .2
done
"$controller" stop
"$prefix/bin/devcycle" requirement create --title 'Upgrade preservation acceptance' --desc 'State must survive install lifecycle operations.' --db "$prefix/data/devcycle/devcycle.db" >"$work/requirement.json"
"$prefix/bin/releaseguard" confirm --report "$prefix/data/releaseguard/release-report.json" --decision GO --by acceptance --note 'Upgrade preservation acceptance' --out "$prefix/data/releaseguard/acceptance-approval.json" >"$work/approval.json"
for required in \
  "$prefix/data/devcycle/devcycle.db" \
  "$prefix/data/infrascout/baseline.json" \
  "$prefix/data/infrascout/inventory.json" \
  "$prefix/data/fleetscope/agent-identity.json" \
  "$prefix/data/fleetscope/agents.json" \
  "$prefix/data/releaseguard/release-report.json" \
  "$prefix/data/releaseguard/acceptance-approval.json"; do
  [[ -s "$required" ]] || { printf 'Runtime did not create required preservation evidence: %s\n' "$required" >&2; exit 1; }
done
data_fingerprint() {
  (
    cd "$prefix/data"
    while IFS= read -r file; do printf '%s|' "$file"; sha256sum "$file"; done < <(LC_ALL=C find . -type f -print | LC_ALL=C sort)
  ) | sha256sum | awk '{print $1}'
}
printf preserve-me >"$prefix/data/user-preserved.marker"

printf interrupted-upgrade-marker >>"$prefix/bin/devcycle"
interrupted_previous_hash=$(sha256sum "$prefix/bin/devcycle" | awk '{print $1}')
"$controller" start >"$work/restarted-before-interrupt.log"
if AI_DEVOPS_ACCEPTANCE_ABORT_AFTER_PAYLOAD=1 "$installer" --prefix "$prefix" >"$work/interrupted-upgrade.log" 2>&1; then
  printf 'Acceptance interrupt did not terminate the installer.\n' >&2
  exit 1
fi
[[ -f "$prefix/config/install-transaction.txt" && -f "$prefix/config/install-transaction.json" ]] || { printf 'Interrupted upgrade did not leave a recovery journal.\n' >&2; exit 1; }
[[ $(sha256sum "$prefix/bin/devcycle" | awk '{print $1}') != "$interrupted_previous_hash" ]] || { printf 'Acceptance interrupt did not occur after payload replacement.\n' >&2; exit 1; }
recovery_source="$work/recovery-empty-source"
mkdir -p "$recovery_source/assets/linux-amd64"
if "$installer" --prefix "$prefix" --source-root "$recovery_source" >"$work/recovery.log" 2>&1; then
  printf 'Recovery probe unexpectedly completed an install with missing assets.\n' >&2
  exit 1
fi
grep -q 'Recovering the previous installation after an interrupted upgrade' "$work/recovery.log" || { printf 'Interrupted upgrade recovery was not reported.\n' >&2; exit 1; }
[[ $(sha256sum "$prefix/bin/devcycle" | awk '{print $1}') == "$interrupted_previous_hash" ]] || { printf 'Interrupted upgrade did not restore the previous binary.\n' >&2; exit 1; }
[[ -f "$prefix/config/last-install-recovery.json" && ! -e "$prefix/config/install-transaction.txt" && ! -e "$prefix/config/install-transaction.json" ]] || { printf 'Interrupted upgrade recovery metadata is incomplete.\n' >&2; exit 1; }
python3 - "$prefix/config/last-install-recovery.json" <<'PY'
import json, sys
value = json.load(open(sys.argv[1], encoding="utf-8"))
assert value["schemaVersion"] == "ai-devops.install-recovery/v1"
assert value["interruptedTargetVersion"] == "0.4.0-dev"
assert value["wasRunning"] is True
PY
recovered_status=$("$controller" status)
grep -q 'DevCycle.*ready' <<<"$recovered_status" || { printf 'Interrupted upgrade recovery did not restart the previously running suite.\n' >&2; exit 1; }
"$controller" stop
cp "$bundle/assets/linux-amd64/devcycle-linux-amd64" "$prefix/bin/devcycle"
chmod 0755 "$prefix/bin/devcycle"
data_before=$(data_fingerprint)

printf transaction-marker >>"$prefix/bin/devcycle"
transaction_hash=$(sha256sum "$prefix/bin/devcycle" | awk '{print $1}')
if AI_DEVOPS_ACCEPTANCE_FAIL_AFTER_PAYLOAD=1 "$controller" upgrade "$bundle" "$bundle/install-assets.txt" >"$work/transaction-failure.log" 2>&1; then
  printf 'Forced commit failure was unexpectedly accepted.\n' >&2
  exit 1
fi
[[ $(sha256sum "$prefix/bin/devcycle" | awk '{print $1}') == "$transaction_hash" ]] || { printf 'Failed upgrade did not restore the previous binary.\n' >&2; exit 1; }
grep -q 'restoring the previous installation' "$work/transaction-failure.log" || { printf 'Failed upgrade did not report transaction restoration.\n' >&2; exit 1; }
cp "$bundle/assets/linux-amd64/devcycle-linux-amd64" "$prefix/bin/devcycle"
chmod 0755 "$prefix/bin/devcycle"

"$controller" upgrade "$bundle" "$bundle/install-assets.txt"
[[ $(data_fingerprint) == "$data_before" ]] || { printf 'Upgrade changed persisted product state.\n' >&2; exit 1; }
upgrade_backup=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["previousBackup"])' "$prefix/config/install-state.json")
printf tamper >>"$prefix/backups/$upgrade_backup/bin/devcycle"
if "$controller" rollback "$upgrade_backup" >"$work/tampered-backup.log" 2>&1; then
  printf 'Tampered rollback backup was unexpectedly accepted.\n' >&2
  exit 1
fi
grep -q 'integrity check failed' "$work/tampered-backup.log" || { printf 'Tampered backup failure was not actionable.\n' >&2; exit 1; }
cp -p "$prefix/bin/devcycle" "$prefix/backups/$upgrade_backup/bin/devcycle"
"$controller" rollback "$upgrade_backup"
[[ $(data_fingerprint) == "$data_before" ]] || { printf 'Rollback changed persisted product state.\n' >&2; exit 1; }
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

printf '{"platform":"linux-amd64","offline_install":"passed","network_namespace":"%s","runtime":"passed","doctor":"passed","interrupted_upgrade_recovery":"passed","failed_commit_restore":"passed","product_state_preserved":["requirement-db","infrastructure-baseline","infrastructure-inventory","fleet-identity","fleet-registration","release-report","digest-bound-approval"],"upgrade_backup":"%s","tampered_backup":"blocked","rollback_backups":%s,"uninstall_preserved_data":true,"purge":"passed","missing_asset_network_fallback":"blocked","ports":[%s,%s,%s,%s]}\n' \
  "$netns" "$upgrade_backup" "$rollback_backups" "${ports[0]}" "${ports[1]}" "${ports[2]}" "${ports[3]}"
