#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
SUITE_VERSION=${SUITE_VERSION:-0.3.3}
WORK=$(mktemp -d "${TMPDIR:-/tmp}/ai-devops-suite-e2e.XXXXXX")
pick_port() { python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1",0)); print(s.getsockname()[1]); s.close()'; }
DEV_PORT=${DEV_PORT:-$(pick_port)}
FLEET_PORT=${FLEET_PORT:-$(pick_port)}
PIDS=()
cleanup() {
	for pid in "${PIDS[@]:-}"; do
		if [[ ${OSTYPE:-} == msys* ]]; then taskkill //PID "$pid" //T //F >/dev/null 2>&1 || true; else kill "$pid" 2>/dev/null || true; fi
	done
  for pid in "${PIDS[@]:-}"; do wait "$pid" 2>/dev/null || true; done
  case "$WORK" in "${TMPDIR:-/tmp}"/ai-devops-suite-e2e.*) rm -rf "$WORK" ;; esac
}
trap cleanup EXIT

if [[ ${SKIP_TESTS:-0} == 1 ]]; then
  echo "[1/7] Unit tests skipped by environment"
else
  echo "[1/7] Test every module"
  for module in lifecycle-spec ai-dev-cycle-manager infrastructure-discovery fleet-observability release-validation; do
    (cd "$ROOT/$module" && go test ./... && go vet ./...)
  done
fi

echo "[2/7] Build product binaries"
(cd "$ROOT/lifecycle-spec" && go build -trimpath -o "$WORK/lifecycle-validate" ./cmd/lifecycle-validate)
(cd "$ROOT/ai-dev-cycle-manager" && go build -trimpath -o "$WORK/devcycle" ./cmd/devcycle)
(cd "$ROOT/infrastructure-discovery" && go build -trimpath -o "$WORK/infrascout" ./cmd/infrascout)
(cd "$ROOT/fleet-observability" && go build -trimpath -o "$WORK/fleetctl" ./cmd/fleetctl)
(cd "$ROOT/release-validation" && go build -trimpath -o "$WORK/releaseguard" ./cmd/releaseguard)

echo "[3/7] Create a source-pinned release candidate through DevCycle"
mkdir "$WORK/source-repo"
printf '# Suite E2E source\n' > "$WORK/source-repo/README.md"
git -C "$WORK/source-repo" init -q
git -C "$WORK/source-repo" config user.email suite-e2e@example.invalid
git -C "$WORK/source-repo" config user.name 'Suite E2E'
git -C "$WORK/source-repo" add README.md
git -C "$WORK/source-repo" commit -q -m 'initial source'
"$WORK/devcycle" serve --db "$WORK/devcycle.db" --addr "127.0.0.1:$DEV_PORT" >"$WORK/devcycle.log" 2>&1 & PIDS+=("$!")
python3 - "$DEV_PORT" "$WORK/source-repo" "$WORK/source-worktree" "$WORK/candidate.json" <<'PY'
import json, sys, time, urllib.request
base = "http://127.0.0.1:" + sys.argv[1]
for _ in range(80):
    try:
        urllib.request.urlopen(base + "/api/requirements", timeout=.2)
        break
    except Exception:
        time.sleep(.1)
else:
    raise RuntimeError("DevCycle did not become ready")
def call(method, path, data=None):
    body = json.dumps(data).encode() if data is not None else None
    request = urllib.request.Request(base + path, data=body, method=method, headers={"Content-Type":"application/json"})
    return json.load(urllib.request.urlopen(request))
requirement = call("POST", "/api/requirements", {"title":"Suite delivery", "description":"Cross-module verification"})
criterion = call("POST", f"/api/requirements/{requirement['id']}/criteria", {"description":"All suite checks pass with evidence"})
call("PATCH", f"/api/criteria/{criterion['id']}", {"satisfied":True,"evidenceTitle":"suite E2E verification","evidenceNote":"automated cross-module acceptance"})
task = call("POST", "/api/tasks", {"requirementId":requirement["id"],"title":"Verify suite source and runtime"})
call("POST", f"/api/tasks/{task['id']}/worktree", {"repositoryPath":sys.argv[2],"branch":"suite/e2e","worktreePath":sys.argv[3]})
call("PATCH", f"/api/tasks/{task['id']}", {"status":"done"})
candidate = call("GET", f"/api/requirements/{requirement['id']}/release-candidate")
assert candidate["readiness"]["ready"] and len(candidate["sources"]) == 1 and candidate["sources"][0]["clean"]
with open(sys.argv[4], "w") as output:
    json.dump(candidate, output, indent=2)
PY
"$WORK/lifecycle-validate" release-candidate.json "$WORK/candidate.json"

echo "[4/7] Capture InfraScout baseline and zero-drift evidence"
"$WORK/infrascout" baseline --fixture "$ROOT/infrastructure-discovery/testdata/host-sample" --state-dir "$WORK/infra" >/dev/null
"$WORK/infrascout" check --fixture "$ROOT/infrastructure-discovery/testdata/host-sample" --state-dir "$WORK/infra" --fail-on never >/dev/null

echo "[5/7] Run the FleetScope native Agent and persist metric samples"
export FLEET_TOKEN=suite-e2e-bootstrap-token
"$WORK/fleetctl" serve --addr "127.0.0.1:$FLEET_PORT" --data "$WORK/fleet" >"$WORK/fleet.log" 2>&1 & PIDS+=("$!")
for _ in $(seq 1 80); do curl -fsS "http://127.0.0.1:$FLEET_PORT/api/v1/health" >/dev/null && break; sleep .1; done
"$WORK/fleetctl" agent --center "http://127.0.0.1:$FLEET_PORT" --node suite-e2e --interval 1s --report-interval 1s --collector-jitter 0s --inventory "$WORK/infra/inventory.json" --drift "$WORK/infra/drift.json" --label version="$SUITE_VERSION" --spool-dir "$WORK/agent-spool" --credential-file "$WORK/agent-credential.json" >"$WORK/agent.log" 2>&1 & PIDS+=("$!")
node_ready=0
for _ in $(seq 1 80); do
  if curl -fsS "http://127.0.0.1:$FLEET_PORT/api/v1/nodes/suite-e2e" >/dev/null 2>&1; then node_ready=1; break; fi
  sleep .1
done
if [[ $node_ready != 1 ]]; then
  echo "FleetScope Agent did not publish a node report" >&2
  echo "--- agent.log ---" >&2
  cat "$WORK/agent.log" >&2 || true
  echo "--- fleet.log ---" >&2
  cat "$WORK/fleet.log" >&2 || true
  exit 1
fi
sleep 3
"$WORK/lifecycle-validate" fleet-node-report.json "$WORK/fleet/nodes/suite-e2e.json"

echo "[6/7] Gate candidate, drift, native metrics, fleet state, and observation"
python3 - "$WORK" "$FLEET_PORT" "$SUITE_VERSION" <<'PY'
import json, os, sys
work, port, version = sys.argv[1], sys.argv[2], sys.argv[3]
plan = {
    "release_id":"suite-e2e",
    "version":version,
    "candidate_file":os.path.join(work,"candidate.json"),
    "recovery_checks":[{"name":"previous binary retained","type":"file","path":os.path.join(work,"releaseguard")}],
    "checks":[{"name":"InfraScout inventory","type":"file","path":os.path.join(work,"infra","inventory.json")}],
    "drift_file":os.path.join(work,"infra","drift.json"),
    "fleet":{"center_url":"http://127.0.0.1:"+port,"nodes":["suite-e2e"],"version_label":"version","max_age_seconds":120},
    "metrics":[{"name":"Agent memory regression","metric":"agent_memory_bytes","node":"suite-e2e","aggregate":"avg","series_reduce":"max","baseline_seconds":60,"direction":"lower","max_regression_percent":1000}],
    "observation":{"seconds":3,"poll_seconds":1,"max_critical_alerts":0},
    "rollback":["Stop suite services","Restore the previous binaries","Re-run health checks"]
}
with open(os.path.join(work,"release-plan.json"),"w") as output:
    json.dump(plan, output, indent=2)
PY
"$WORK/releaseguard" check --plan "$WORK/release-plan.json" --state "$WORK/releaseguard-runs.db" --out "$WORK/release-report.json" >/dev/null
"$WORK/lifecycle-validate" release-validation-report.json "$WORK/release-report.json"
python3 - "$WORK/release-report.json" <<'PY'
import json, sys
report = json.load(open(sys.argv[1]))
assert report["decision"] == "GO", report
assert report["manifest"]["candidate"]["ready"]
assert report["manifest"]["fleet_after"]["nodes"][0]["match"]
assert len(report["manifest"]["metrics"]) == 1 and report["manifest"]["metrics"][0]["after"]["samples"] >= 1
print("Suite decision:", report["decision"], "checks:", len(report["results"]), "observation samples:", len(report["observation"]["samples"]))
PY

echo "[7/7] All runtime contracts validated"
echo "AI DevOps Open Suite verification passed"
