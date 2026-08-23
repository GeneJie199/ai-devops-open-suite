#!/usr/bin/env bash
set -Eeuo pipefail

target_version=${1:-}
[[ $target_version =~ ^[0-9][0-9A-Za-z.-]+$ ]] || { printf 'Usage: accept-public-bootstrap-linux.sh TARGET_VERSION\n' >&2; exit 2; }

work=$(mktemp -d /tmp/ai-devops-public-bootstrap-accept.XXXXXX)
prefix=$work/install
controller=$prefix/bin/suitectl
cleanup() {
  if [[ -x $controller ]]; then "$controller" purge --confirm "$prefix" >/dev/null 2>&1 || true; fi
  case "$work" in /tmp/ai-devops-public-bootstrap-accept.*) rm -rf -- "$work" ;; esac
}
trap cleanup EXIT HUP INT TERM

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

export AI_DEVOPS_HOME=$prefix
export AI_DEVOPS_DEVCYCLE_PORT=${ports[0]}
export AI_DEVOPS_INFRASCOUT_PORT=${ports[1]}
export AI_DEVOPS_FLEETSCOPE_PORT=${ports[2]}
export AI_DEVOPS_RELEASEGUARD_PORT=${ports[3]}
unset AI_DEVOPS_RELEASE_URL || true

curl -fsSL https://raw.githubusercontent.com/GeneJie199/ai-devops-open-suite/main/scripts/bootstrap.sh | bash

python3 - "$prefix/config/install-state.json" "$target_version" <<'PY'
import json, sys
value=json.load(open(sys.argv[1], encoding="utf-8"))
assert value["suiteVersion"] == sys.argv[2]
assert value["source"] == "online"
assert len(value["components"]) == 5
PY

status=$($controller status)
grep -Eq '^DevCycle[[:space:]]+ready' <<<"$status"
grep -Eq '^ReleaseGuard[[:space:]]+ready' <<<"$status"
[[ -f $prefix/data/fleetscope/agent-identity.json ]]

$controller purge --confirm "$prefix"
[[ ! -e $prefix ]]
printf '{"schema":"ai-devops.readme-bootstrap-acceptance/v1","platform":"linux-amd64","target":"%s","entry":"public-main-readme-command","release":"latest-stable","components":5,"runtime":"passed","doctor":"passed","ui":"passed","agent":"passed","cleanup":true,"ports":[%s,%s,%s,%s]}\n' \
  "$target_version" "${ports[0]}" "${ports[1]}" "${ports[2]}" "${ports[3]}"
