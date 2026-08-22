#!/usr/bin/env bash
set -Eeuo pipefail

archive=${1:-}
work=${2:-}
[[ -f "$archive" ]] || { printf 'Usage: accept-offline-network-namespace.sh ARCHIVE [WORK_DIR]\n' >&2; exit 2; }
if [[ -z "$work" ]]; then work=$(mktemp -d /tmp/ai-devops-v1-netns.XXXXXX); fi
case "$work" in /tmp/ai-devops-v1-netns.*) ;; *) printf 'Work directory must use /tmp/ai-devops-v1-netns.*\n' >&2; exit 2 ;; esac
[[ ! -L "$work" ]] || { printf 'Work directory must not be a symbolic link.\n' >&2; exit 2; }
cleanup() { case "$work" in /tmp/ai-devops-v1-netns.*) rm -rf -- "$work" ;; esac; }
trap cleanup EXIT

command -v unshare >/dev/null || { printf 'unshare is required for this acceptance.\n' >&2; exit 1; }
mkdir -p "$work/extract"
tar -xzf "$archive" -C "$work/extract"
bundle="$work/extract/ai-devops-open-suite"
prefix="$work/install"

# Only the installer and controller init run in this namespace. Product services
# are deliberately not started, so this acceptance reads no host workload state.
unshare -n "$bundle/scripts/install-suite.sh" --prefix "$prefix"
python3 - "$prefix/config/install-state.json" <<'PY'
import json, sys
state=json.load(open(sys.argv[1], encoding="utf-8"))
assert state["schemaVersion"] == "ai-devops.install-state/v1"
assert state["platform"] == "linux-amd64"
assert state["source"] == "offline"
assert len(state["components"]) == 5
print(json.dumps({
    "platform": state["platform"],
    "network_namespace": "passed",
    "source": state["source"],
    "components": len(state["components"]),
    "services_started": False,
}))
PY
