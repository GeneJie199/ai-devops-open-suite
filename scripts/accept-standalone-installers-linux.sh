#!/usr/bin/env bash
set -euo pipefail

stage=${1:-}
port=${2:-}
[[ -d "$stage" && "$stage" == /tmp/ai-devops-m7-install.* ]] || {
  printf 'Usage: accept-standalone-installers-linux.sh /tmp/ai-devops-m7-install.ID PORT\n' >&2
  exit 2
}
[[ "$port" =~ ^[0-9]+$ && "$port" -ge 1024 && "$port" -le 65535 ]] || {
  printf 'A valid unprivileged loopback port is required.\n' >&2
  exit 2
}
[[ $(id -u) -eq 0 ]] || { printf 'Run this isolated acceptance as root.\n' >&2; exit 2; }

fleet_pid=
cleanup() {
  if [[ -n "$fleet_pid" ]]; then kill "$fleet_pid" >/dev/null 2>&1 || true; wait "$fleet_pid" >/dev/null 2>&1 || true; fi
  case "$stage" in /tmp/ai-devops-m7-install.*) rm -rf -- "$stage" ;; esac
}
trap cleanup EXIT

dev_prefix="$stage/accept/dev/local"
dev_data="$stage/accept/dev/data/devcycle"
dev_systemd="$stage/accept/dev/systemd"
PREFIX="$dev_prefix" DEVCYCLE_DATA_DIR="$dev_data" SYSTEMD_DIR="$dev_systemd" \
  sh "$stage/devcycle/scripts/install.sh" install "$stage/devcycle/devcycle" "$stage/devcycle/checksums.txt"
PREFIX="$dev_prefix" DEVCYCLE_DATA_DIR="$dev_data" SYSTEMD_DIR="$dev_systemd" \
  sh "$stage/devcycle/scripts/install.sh" doctor
printf preserve >"$dev_data/preserve.marker"
PREFIX="$dev_prefix" DEVCYCLE_DATA_DIR="$dev_data" SYSTEMD_DIR="$dev_systemd" \
  sh "$stage/devcycle/scripts/install.sh" uninstall
[[ ! -e "$dev_prefix/bin/devcycle" && -f "$dev_data/preserve.marker" ]]
if PREFIX="$dev_prefix" DEVCYCLE_DATA_DIR="$dev_data" SYSTEMD_DIR="$dev_systemd" \
  sh "$stage/devcycle/scripts/install.sh" purge >/dev/null 2>&1; then
  printf 'DevCycle purge succeeded without confirmation.\n' >&2
  exit 1
fi
PREFIX="$dev_prefix" DEVCYCLE_DATA_DIR="$dev_data" SYSTEMD_DIR="$dev_systemd" DEVCYCLE_CONFIRM_PURGE="$dev_data" \
  sh "$stage/devcycle/scripts/install.sh" purge
[[ ! -e "$dev_data" ]]

infra_prefix="$stage/accept/infra/local"
infra_state="$stage/accept/infra/state/infrascout"
infra_systemd="$stage/accept/infra/systemd"
PREFIX="$infra_prefix" STATE_DIR="$infra_state" SYSTEMD_DIR="$infra_systemd" \
  sh "$stage/infrascout/scripts/install.sh" install "$stage/infrascout/infrascout" "$stage/infrascout/checksums.txt"
PREFIX="$infra_prefix" STATE_DIR="$infra_state" SYSTEMD_DIR="$infra_systemd" \
  sh "$stage/infrascout/scripts/install.sh" doctor
printf preserve >"$infra_state/preserve.marker"
PREFIX="$infra_prefix" STATE_DIR="$infra_state" SYSTEMD_DIR="$infra_systemd" \
  sh "$stage/infrascout/scripts/install.sh" uninstall
[[ ! -e "$infra_prefix/bin/infrascout" && -f "$infra_state/preserve.marker" ]]
if PREFIX="$infra_prefix" STATE_DIR="$infra_state" SYSTEMD_DIR="$infra_systemd" \
  sh "$stage/infrascout/scripts/install.sh" purge >/dev/null 2>&1; then
  printf 'InfraScout purge succeeded without confirmation.\n' >&2
  exit 1
fi
PREFIX="$infra_prefix" STATE_DIR="$infra_state" SYSTEMD_DIR="$infra_systemd" INFRASCOUT_CONFIRM_PURGE="$infra_state" \
  sh "$stage/infrascout/scripts/install.sh" purge
[[ ! -e "$infra_state" ]]

fleet_prefix="$stage/accept/fleet/local"
fleet_config="$stage/accept/fleet/config/fleetscope"
fleet_center="$stage/accept/fleet/data/fleetscope"
fleet_agent="$stage/accept/fleet/data/fleetscope-agent"
fleet_systemd="$stage/accept/fleet/systemd"
shared_infra="$stage/accept/shared/state/infrascout"
install -d -m 0700 "$shared_infra"
printf owned-by-infrascout >"$shared_infra/ownership.marker"
fleet_env=(PREFIX="$fleet_prefix" CONFIG_DIR="$fleet_config" CENTER_DATA="$fleet_center" AGENT_DATA="$fleet_agent" INFRASCOUT_DATA="$shared_infra" SYSTEMD_DIR="$fleet_systemd" INSTALL_SERVICE=0 FLEET_SERVICE_USER=root FLEET_URL="http://127.0.0.1:$port")
env "${fleet_env[@]}" sh "$stage/fleetscope/scripts/install.sh" install "$stage/fleetscope/fleetctl" "$stage/fleetscope/checksums.txt"
"$fleet_prefix/bin/fleetctl" up --addr "127.0.0.1:$port" --data "$fleet_center" --open=false --infrascout=off >"$stage/fleet-up.log" 2>&1 &
fleet_pid=$!
ready=false
for _ in {1..40}; do
  if curl --fail --silent --max-time 1 "http://127.0.0.1:$port/api/v1/health" >/dev/null; then ready=true; break; fi
  sleep 0.25
done
[[ "$ready" == true ]] || { cat "$stage/fleet-up.log" >&2; exit 1; }
env "${fleet_env[@]}" sh "$stage/fleetscope/scripts/install.sh" doctor
printf preserve >"$fleet_center/preserve.marker"
env "${fleet_env[@]}" sh "$stage/fleetscope/scripts/install.sh" uninstall
kill "$fleet_pid" >/dev/null 2>&1 || true
wait "$fleet_pid" >/dev/null 2>&1 || true
fleet_pid=
[[ ! -e "$fleet_prefix/bin/fleetctl" && -f "$fleet_center/preserve.marker" && -f "$shared_infra/ownership.marker" ]]
if env "${fleet_env[@]}" sh "$stage/fleetscope/scripts/install.sh" uninstall --purge-data >/dev/null 2>&1; then
  printf 'FleetScope purge succeeded without confirmation.\n' >&2
  exit 1
fi
confirm="$fleet_config:$fleet_center:$fleet_agent"
env "${fleet_env[@]}" FLEETSCOPE_CONFIRM_PURGE="$confirm" sh "$stage/fleetscope/scripts/install.sh" uninstall --purge-data
[[ ! -e "$fleet_config" && ! -e "$fleet_center" && ! -e "$fleet_agent" && -f "$shared_infra/ownership.marker" ]]

printf '{"schema":"ai-devops.standalone-install-acceptance/v1","platform":"linux-amd64","checksum":true,"doctor":true,"start":true,"uninstall_preserved_data":true,"purge_guard":true,"module_ownership":true,"cleanup":true}\n'
