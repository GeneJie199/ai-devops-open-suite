#!/usr/bin/env bash
set -Eeuo pipefail

offline_archive=${1:-}
work=${2:-}
[[ -f "$offline_archive" ]] || { printf 'Usage: accept-upgrade-from-v033-linux.sh FULL_OFFLINE_ARCHIVE [WORK_DIR]\n' >&2; exit 2; }
if [[ -z "$work" ]]; then work=$(mktemp -d /tmp/ai-devops-v033-upgrade.XXXXXX); fi
case "$work" in /tmp/ai-devops-v033-upgrade.*) ;; *) printf 'Work directory must use /tmp/ai-devops-v033-upgrade.*\n' >&2; exit 2 ;; esac
[[ ! -L "$work" ]] || { printf 'Work directory must not be a symbolic link.\n' >&2; exit 2; }
prefix="$work/install"
cleanup() {
  if [[ -x "$prefix/bin/suitectl" ]]; then "$prefix/bin/suitectl" stop >/dev/null 2>&1 || true; fi
  case "$work" in /tmp/ai-devops-v033-upgrade.*) rm -rf -- "$work" ;; esac
}
trap cleanup EXIT

mkdir -p "$work/new" "$work/old" "$work/legacy-source"
tar -xzf "$offline_archive" -C "$work/new"
new_bundle="$work/new/ai-devops-open-suite"
curl --fail --location --retry 3 \
  --output "$work/old-suite.tar.gz" \
  https://github.com/GeneJie199/ai-devops-open-suite/releases/download/v0.3.3/ai-devops-open-suite-v0.3.3.tar.gz
[[ $(sha256sum "$work/old-suite.tar.gz" | awk '{print $1}') == b38dc35d535c0974a62e035933d4053a4adedc039e8c02c2ab83c8d47b05e8d7 ]] || { printf 'Public v0.3.3 launcher digest mismatch.\n' >&2; exit 1; }
tar -xzf "$work/old-suite.tar.gz" -C "$work/old"
old_bundle="$work/old/ai-devops-open-suite"

while IFS='|' read -r kind _id repo _tag _version asset _target digest; do
  [[ "$kind" == component ]] || continue
  mkdir -p "$work/legacy-source/$repo"
  cp "$new_bundle/assets/linux-amd64/$asset" "$work/legacy-source/$repo/$asset"
  printf '%s  %s\n' "$digest" "$asset" >"$work/legacy-source/$repo/checksums.txt"
done <"$new_bundle/install-assets.txt"

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

"$old_bundle/scripts/install-suite.sh" --prefix "$prefix" --source-root "$work/legacy-source"
for product in devcycle infrascout fleetscope releaseguard; do printf preserve-v033 >"$prefix/data/$product/user-v033.marker"; done
token_before=$(sha256sum "$prefix/config/fleet-token" | awk '{print $1}')
ports_before=$(sha256sum "$prefix/config/ports.env" | awk '{print $1}')

"$new_bundle/scripts/install-suite.sh" --prefix "$prefix" --source-root "$new_bundle" --manifest-index "$new_bundle/install-assets.txt"
state="$prefix/config/install-state.json"
backup_id=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["previousBackup"])' "$state")
[[ -n "$backup_id" && -s "$prefix/backups/$backup_id/backup-files.txt" ]] || { printf 'Upgrade did not create an integrity-checked backup.\n' >&2; exit 1; }
for product in devcycle infrascout fleetscope releaseguard; do [[ -f "$prefix/data/$product/user-v033.marker" ]] || { printf 'Upgrade lost %s data.\n' "$product" >&2; exit 1; }; done
[[ $(sha256sum "$prefix/config/fleet-token" | awk '{print $1}') == "$token_before" ]] || { printf 'Upgrade changed Fleet token.\n' >&2; exit 1; }
[[ $(sha256sum "$prefix/config/ports.env" | awk '{print $1}') == "$ports_before" ]] || { printf 'Upgrade changed ports.\n' >&2; exit 1; }

"$prefix/bin/suitectl" rollback "$backup_id"
[[ $(cat "$prefix/config/suite-version") == 0.3.3 ]] || { printf 'Rollback did not restore suite v0.3.3.\n' >&2; exit 1; }
for product in devcycle infrascout fleetscope releaseguard; do [[ -f "$prefix/data/$product/user-v033.marker" ]] || { printf 'Rollback lost %s data.\n' "$product" >&2; exit 1; }; done
[[ $(sha256sum "$prefix/config/fleet-token" | awk '{print $1}') == "$token_before" ]] || { printf 'Rollback changed Fleet token.\n' >&2; exit 1; }
[[ $(sha256sum "$prefix/config/ports.env" | awk '{print $1}') == "$ports_before" ]] || { printf 'Rollback changed ports.\n' >&2; exit 1; }

"$new_bundle/scripts/install-suite.sh" --prefix "$prefix" --source-root "$new_bundle" --manifest-index "$new_bundle/install-assets.txt"
"$prefix/bin/suitectl" purge --confirm "$prefix"
[[ ! -e "$prefix" ]] || { printf 'Acceptance cleanup failed.\n' >&2; exit 1; }

printf '{"platform":"linux-amd64","source":"public-v0.3.3-launcher","target":"0.4.0-dev","data_markers_preserved":4,"fleet_token_preserved":true,"ports_preserved":true,"rollback_version":"0.3.3","backup_integrity_manifest":true,"cleanup":true}\n'
