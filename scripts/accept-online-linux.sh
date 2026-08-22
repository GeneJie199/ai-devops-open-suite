#!/usr/bin/env bash
set -Eeuo pipefail

bundle=${1:-}
work=${2:-}
[[ -x "$bundle/scripts/install-suite.sh" && -x "$bundle/scripts/suitectl.sh" ]] || { printf 'Usage: accept-online-linux.sh SUITE_SOURCE_ROOT [WORK_DIR]\n' >&2; exit 2; }
bundle=$(cd "$bundle" && pwd)
if [[ -z "$work" ]]; then work=$(mktemp -d /tmp/ai-devops-online.XXXXXX); fi
case "$work" in /tmp/ai-devops-online.*) ;; *) printf 'Acceptance work directory must use /tmp/ai-devops-online.*\n' >&2; exit 2 ;; esac
[[ ! -L "$work" ]] || { printf 'Acceptance work directory must not be a symbolic link.\n' >&2; exit 2; }
prefix="$work/install"
controller="$prefix/bin/suitectl"
cleanup() {
  if [[ -x "$controller" ]]; then "$controller" stop >/dev/null 2>&1 || true; fi
  case "$work" in /tmp/ai-devops-online.*) rm -rf -- "$work" ;; esac
}
trap cleanup EXIT

readarray -t ports < <(python3 - <<'PY'
import socket
sockets=[]
try:
    for _ in range(4):
        sock=socket.socket(); sock.bind(("127.0.0.1", 0)); sockets.append(sock)
    for sock in sockets: print(sock.getsockname()[1])
finally:
    for sock in sockets: sock.close()
PY
)
export AI_DEVOPS_DEVCYCLE_PORT=${ports[0]}
export AI_DEVOPS_INFRASCOUT_PORT=${ports[1]}
export AI_DEVOPS_FLEETSCOPE_PORT=${ports[2]}
export AI_DEVOPS_RELEASEGUARD_PORT=${ports[3]}
index="$bundle/manifests/install-linux-amd64.txt"
[[ -f "$index" ]] || index="$bundle/install-assets.txt"
"$bundle/scripts/install-suite.sh" --prefix "$prefix" --manifest-index "$index"
python3 - "$prefix/config/install-state.json" <<'PY'
import json, sys
value=json.load(open(sys.argv[1], encoding="utf-8"))
assert value["schemaVersion"] == "ai-devops.install-state/v1"
assert value["source"] == "online"
assert len(value["components"]) == 5
PY
"$controller" doctor
"$controller" purge --confirm "$prefix"
[[ ! -e "$prefix" ]] || { printf 'Online acceptance purge failed.\n' >&2; exit 1; }
printf '{"platform":"linux-amd64","source":"online","components":5,"doctor":"passed","purge":"passed","ports":[%s,%s,%s,%s]}\n' "${ports[0]}" "${ports[1]}" "${ports[2]}" "${ports[3]}"
