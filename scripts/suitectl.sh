#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_PATH=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
if [[ $(basename "$SCRIPT_PATH") == scripts ]]; then
  DEFAULT_HOME=$(cd "$SCRIPT_PATH/.." && pwd)
else
  DEFAULT_HOME=$(cd "$SCRIPT_PATH/.." && pwd)
fi
HOME_DIR=${AI_DEVOPS_HOME:-$DEFAULT_HOME}
BIN="$HOME_DIR/bin"
DATA="$HOME_DIR/data"
LOGS="$HOME_DIR/logs"
RUN="$HOME_DIR/run"
EXAMPLES="$HOME_DIR/examples"
CONFIG="$HOME_DIR/config"
TOKEN_PATH="$CONFIG/fleet-token"
VERSION_PATH="$CONFIG/suite-version"
PORT_CONFIG="$CONFIG/ports.env"
SUITE_VERSION=$(if [[ -f "$VERSION_PATH" ]]; then cat "$VERSION_PATH"; else printf '0.3.2'; fi)
saved_devcycle_port=''
saved_infrascout_port=''
saved_fleetscope_port=''
saved_releaseguard_port=''
if [[ -f "$PORT_CONFIG" ]]; then
  while IFS='=' read -r key value; do
    [[ "$value" =~ ^[0-9]+$ ]] || continue
    case "$key" in
      AI_DEVOPS_DEVCYCLE_PORT) saved_devcycle_port=$value ;;
      AI_DEVOPS_INFRASCOUT_PORT) saved_infrascout_port=$value ;;
      AI_DEVOPS_FLEETSCOPE_PORT) saved_fleetscope_port=$value ;;
      AI_DEVOPS_RELEASEGUARD_PORT) saved_releaseguard_port=$value ;;
    esac
  done <"$PORT_CONFIG"
fi
DEVCYCLE_PORT=${AI_DEVOPS_DEVCYCLE_PORT:-${saved_devcycle_port:-8766}}
INFRASCOUT_PORT=${AI_DEVOPS_INFRASCOUT_PORT:-${saved_infrascout_port:-8765}}
FLEETSCOPE_PORT=${AI_DEVOPS_FLEETSCOPE_PORT:-${saved_fleetscope_port:-8770}}
RELEASEGUARD_PORT=${AI_DEVOPS_RELEASEGUARD_PORT:-${saved_releaseguard_port:-8771}}
for port in "$DEVCYCLE_PORT" "$INFRASCOUT_PORT" "$FLEETSCOPE_PORT" "$RELEASEGUARD_PORT"; do
  [[ "$port" =~ ^[0-9]+$ ]] && (( port >= 1 && port <= 65535 )) || { printf 'Invalid suite port: %s\n' "$port" >&2; exit 2; }
done
SYSTEMD_UNIT_NAME=ai-devops-open-suite.service
SYSTEMD_UNIT="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/$SYSTEMD_UNIT_NAME"
LAUNCH_AGENT="$HOME/Library/LaunchAgents/io.aidevops.opensuite.plist"

url_devcycle="http://127.0.0.1:$DEVCYCLE_PORT/"
url_infrascout="http://127.0.0.1:$INFRASCOUT_PORT/"
url_fleetscope="http://127.0.0.1:$FLEETSCOPE_PORT/"
url_releaseguard="http://127.0.0.1:$RELEASEGUARD_PORT/"

init_suite() {
  mkdir -p "$BIN" "$DATA/devcycle" "$DATA/infrascout" "$DATA/fleetscope" "$DATA/releaseguard" "$LOGS" "$RUN" "$CONFIG"
  if [[ ! -f "$TOKEN_PATH" ]]; then
    umask 077
    if command -v openssl >/dev/null; then openssl rand -base64 32 >"$TOKEN_PATH"; else head -c 32 /dev/urandom | base64 >"$TOKEN_PATH"; fi
  fi
  chmod 0600 "$TOKEN_PATH"
  printf 'AI_DEVOPS_DEVCYCLE_PORT=%s\nAI_DEVOPS_INFRASCOUT_PORT=%s\nAI_DEVOPS_FLEETSCOPE_PORT=%s\nAI_DEVOPS_RELEASEGUARD_PORT=%s\n' \
    "$DEVCYCLE_PORT" "$INFRASCOUT_PORT" "$FLEETSCOPE_PORT" "$RELEASEGUARD_PORT" >"$PORT_CONFIG"
  chmod 0600 "$PORT_CONFIG"
  if [[ ! -f "$DATA/releaseguard/release-report.json" && -f "$EXAMPLES/release-report.demo.json" ]]; then
    cp "$EXAMPLES/release-report.demo.json" "$DATA/releaseguard/release-report.json"
  fi
  printf 'Suite home: %s\n' "$HOME_DIR"
}

running_pid() {
  local name=$1
  local pid_file="$RUN/$name.pid"
  local pid binary_name expected actual command_line
  [[ -f "$pid_file" ]] || return 1
  pid=$(cat "$pid_file")
  [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null || return 1
  case "$name" in
    devcycle|infrascout|releaseguard) binary_name=$name ;;
    fleetscope|fleet-agent) binary_name=fleetctl ;;
    *) return 1 ;;
  esac
  expected=$(cd "$(dirname "$BIN/$binary_name")" && pwd -P)/$(basename "$BIN/$binary_name")
  if [[ -e "/proc/$pid/exe" ]]; then
    actual=$(readlink -f "/proc/$pid/exe" 2>/dev/null || true)
    [[ "$actual" == "$expected" ]] || return 1
  elif [[ $(uname -s) == Darwin ]]; then
    command_line=$(ps -p "$pid" -o command= 2>/dev/null || true)
    [[ "$command_line" == "$expected" || "$command_line" == "$expected "* ]] || return 1
  else
    return 1
  fi
  printf '%s' "$pid"
}

start_managed() {
  local name=$1; shift
  if running_pid "$name" >/dev/null; then return; fi
  [[ -x "$1" ]] || { printf 'Missing binary: %s. Run install-suite first.\n' "$1" >&2; exit 1; }
  nohup "$@" >>"$LOGS/$name.log" 2>>"$LOGS/$name.error.log" &
  local pid=$!
  printf '%s' "$pid" >"$RUN/$name.pid"
  sleep .25
  kill -0 "$pid" 2>/dev/null || { printf '%s failed to start. See %s\n' "$name" "$LOGS/$name.error.log" >&2; exit 1; }
}

wait_endpoint() {
  local name=$1 url=$2
  command -v curl >/dev/null || { printf 'Missing dependency: curl\n' >&2; exit 1; }
  for _ in $(seq 1 80); do curl --fail --silent --max-time 1 "$url" >/dev/null 2>&1 && return; sleep .1; done
  printf '%s did not become ready: %s\n' "$name" "$url" >&2
  exit 1
}

start_suite() {
  init_suite
  trap 'stop_suite >/dev/null 2>&1 || true' ERR
  for name in devcycle infrascout fleetctl releaseguard lifecycle-validate; do [[ -x "$BIN/$name" ]] || { printf 'Missing binary: %s\n' "$BIN/$name" >&2; exit 1; }; done
  start_managed devcycle "$BIN/devcycle" serve --db "$DATA/devcycle/devcycle.db" --addr "127.0.0.1:$DEVCYCLE_PORT"
  if [[ $(uname -s) == Linux ]]; then
    if [[ ! -f "$DATA/infrascout/baseline.json" ]]; then "$BIN/infrascout" baseline --state-dir "$DATA/infrascout" >/dev/null; fi
    start_managed infrascout "$BIN/infrascout" watch --state-dir "$DATA/infrascout" --interval 1m --addr "127.0.0.1:$INFRASCOUT_PORT"
  else
    start_managed infrascout "$BIN/infrascout" serve --demo --addr "127.0.0.1:$INFRASCOUT_PORT"
  fi
  export FLEET_TOKEN
  FLEET_TOKEN=$(cat "$TOKEN_PATH")
  start_managed fleetscope "$BIN/fleetctl" serve --data "$DATA/fleetscope" --addr "127.0.0.1:$FLEETSCOPE_PORT"
  wait_endpoint FleetScope "${url_fleetscope}api/v1/health"
  agent_args=(agent --center "${url_fleetscope%/}" --node "$(hostname | tr '[:upper:]' '[:lower:]')" --interval 15s --report-interval 1m --spool-dir "$DATA/fleetscope/agent-spool" --credential-file "$DATA/fleetscope/agent-identity.json" --label "version=$SUITE_VERSION")
  if [[ $(uname -s) == Linux ]]; then agent_args+=(--inventory "$DATA/infrascout/inventory.json" --drift "$DATA/infrascout/drift.json"); fi
  start_managed fleet-agent "$BIN/fleetctl" "${agent_args[@]}"
  release_state=''
  [[ -f "$DATA/releaseguard/releaseguard-runs.db" ]] && release_state="$DATA/releaseguard/releaseguard-runs.db"
  start_managed releaseguard "$BIN/releaseguard" serve --report "$DATA/releaseguard/release-report.json" --state "$release_state" --addr "127.0.0.1:$RELEASEGUARD_PORT"
  wait_endpoint DevCycle "${url_devcycle}api/requirements"
  wait_endpoint InfraScout "${url_infrascout}api/data"
  wait_endpoint ReleaseGuard "${url_releaseguard}api/v1/health"
  status_suite
  trap - ERR
}

stop_suite() {
  for name in fleet-agent releaseguard fleetscope infrascout devcycle; do
    if pid=$(running_pid "$name"); then kill "$pid" 2>/dev/null || true; for _ in $(seq 1 30); do kill -0 "$pid" 2>/dev/null || break; sleep .1; done; kill -9 "$pid" 2>/dev/null || true; fi
    rm -f "$RUN/$name.pid"
  done
  printf 'AI DevOps Open Suite stopped.\n'
}

state() { curl --fail --silent --max-time 1 "$1" >/dev/null 2>&1 && printf ready || printf offline; }
autostart_state() {
  case "$(uname -s)" in
    Linux) [[ -f "$SYSTEMD_UNIT" ]] && printf enabled || printf disabled ;;
    Darwin) [[ -f "$LAUNCH_AGENT" ]] && printf enabled || printf disabled ;;
    *) printf unsupported ;;
  esac
}
status_suite() {
  printf '%-14s %-8s %s\n' MODULE STATE URL
  printf '%-14s %-8s %s\n' DevCycle "$(state "${url_devcycle}api/requirements")" "$url_devcycle"
  printf '%-14s %-8s %s\n' InfraScout "$(state "${url_infrascout}api/data")" "$url_infrascout"
  printf '%-14s %-8s %s\n' FleetScope "$(state "${url_fleetscope}api/v1/health")" "$url_fleetscope"
  if running_pid fleet-agent >/dev/null; then printf '%-14s %-8s %s\n' 'Fleet Agent' running 'local collector'; else printf '%-14s %-8s %s\n' 'Fleet Agent' offline 'local collector'; fi
  printf '%-14s %-8s %s\n' ReleaseGuard "$(state "${url_releaseguard}api/v1/health")" "$url_releaseguard"
  printf '%-14s %-8s %s\n' Autostart "$(autostart_state)" 'current user session'
}

port_available() {
  local port=$1
  ! (exec 3<>"/dev/tcp/127.0.0.1/$port") >/dev/null 2>&1
}

doctor_row() { printf '%-24s %-6s %s\n' "$1" "$2" "$3"; }
doctor_suite() {
  local failed=0 probe='' endpoint module port url managed_name path
  doctor_row CHECK STATE DETAIL
  doctor_row Platform OK "$(uname -s) $(uname -m), Bash ${BASH_VERSION%%(*}"
  for module in devcycle infrascout fleetctl releaseguard lifecycle-validate; do
    path="$BIN/$module"
    if [[ -x "$path" ]]; then doctor_row "Binary: $module" OK "$path"; else doctor_row "Binary: $module" FAIL "$path"; failed=1; fi
  done
  if command -v curl >/dev/null; then doctor_row Dependency OK curl; else doctor_row Dependency FAIL 'curl is required'; failed=1; fi
  if command -v openssl >/dev/null || { command -v base64 >/dev/null && [[ -r /dev/urandom ]]; }; then doctor_row Entropy OK 'token generation available'; else doctor_row Entropy FAIL 'openssl or base64 with /dev/urandom is required'; failed=1; fi
  if [[ -d "$HOME_DIR" ]]; then probe=$(mktemp "$HOME_DIR/.doctor.XXXXXX" 2>/dev/null || true); fi
  if [[ -n "$probe" ]]; then rm -f "$probe"; doctor_row 'Suite data' OK "$HOME_DIR writable"; else doctor_row 'Suite data' FAIL "$HOME_DIR is not writable"; failed=1; fi
  if [[ -s "$TOKEN_PATH" ]]; then doctor_row 'Fleet token' OK "$TOKEN_PATH"; else doctor_row 'Fleet token' FAIL "$TOKEN_PATH"; failed=1; fi
  while read -r module port url managed_name; do
    endpoint=$(state "$url")
    if [[ "$endpoint" == ready ]] && running_pid "$managed_name" >/dev/null; then
      doctor_row "Port: $module" OK "port $port, managed endpoint ready"
    elif [[ "$endpoint" == ready ]]; then
      doctor_row "Port: $module" FAIL "port $port responds but is not managed by this installation"
      failed=1
    elif port_available "$port"; then
      doctor_row "Port: $module" OK "port $port available"
    else
      doctor_row "Port: $module" FAIL "port $port occupied by another process"
      failed=1
    fi
  done <<EOF
DevCycle $DEVCYCLE_PORT ${url_devcycle}api/requirements devcycle
InfraScout $INFRASCOUT_PORT ${url_infrascout}api/data infrascout
FleetScope $FLEETSCOPE_PORT ${url_fleetscope}api/v1/health fleetscope
ReleaseGuard $RELEASEGUARD_PORT ${url_releaseguard}api/v1/health releaseguard
EOF
  doctor_row Autostart INFO "$(autostart_state); run suitectl enable to change it"
  if (( failed )); then printf 'Doctor found blocking issues.\n' >&2; return 1; fi
  printf 'Doctor completed: the suite is ready to run.\n'
}

systemd_quote() {
  local value=${1//%/%%}
  value=${value//\\/\\\\}
  value=${value//\"/\\\"}
  printf '"%s"' "$value"
}

xml_escape() {
  local value=$1
  value=${value//&/&amp;}
  value=${value//</&lt;}
  value=${value//>/&gt;}
  value=${value//\"/&quot;}
  value=${value//\'/&apos;}
  printf '%s' "$value"
}

enable_autostart() {
  local controller="$BIN/suitectl" platform
  [[ -x "$controller" ]] || { printf 'Missing controller: %s. Run install-suite first.\n' "$controller" >&2; return 1; }
  init_suite
  platform=$(uname -s)
  case "$platform" in
    Linux)
      command -v systemctl >/dev/null || { printf 'systemctl is required to enable Linux user autostart.\n' >&2; return 1; }
      mkdir -p "$(dirname "$SYSTEMD_UNIT")"
      cat >"$SYSTEMD_UNIT" <<EOF
[Unit]
Description=AI DevOps Open Suite
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=$(systemd_quote "$controller") start
ExecStop=$(systemd_quote "$controller") stop
Environment=AI_DEVOPS_DEVCYCLE_PORT=$DEVCYCLE_PORT
Environment=AI_DEVOPS_INFRASCOUT_PORT=$INFRASCOUT_PORT
Environment=AI_DEVOPS_FLEETSCOPE_PORT=$FLEETSCOPE_PORT
Environment=AI_DEVOPS_RELEASEGUARD_PORT=$RELEASEGUARD_PORT
TimeoutStartSec=60
TimeoutStopSec=30

[Install]
WantedBy=default.target
EOF
      systemctl --user daemon-reload
      systemctl --user enable "$SYSTEMD_UNIT_NAME"
      systemctl --user restart "$SYSTEMD_UNIT_NAME"
      if command -v loginctl >/dev/null && [[ $(loginctl show-user "$USER" -p Linger --value 2>/dev/null || true) != yes ]]; then
        if ! loginctl enable-linger "$USER" >/dev/null 2>&1; then
          printf 'Autostart is enabled for login sessions. Ask an administrator to run: loginctl enable-linger %s\n' "$USER"
        fi
      fi
      ;;
    Darwin)
      mkdir -p "$(dirname "$LAUNCH_AGENT")"
      cat >"$LAUNCH_AGENT" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>io.aidevops.opensuite</string>
  <key>ProgramArguments</key><array><string>$(xml_escape "$controller")</string><string>start</string></array>
  <key>EnvironmentVariables</key><dict>
    <key>AI_DEVOPS_DEVCYCLE_PORT</key><string>$DEVCYCLE_PORT</string>
    <key>AI_DEVOPS_INFRASCOUT_PORT</key><string>$INFRASCOUT_PORT</string>
    <key>AI_DEVOPS_FLEETSCOPE_PORT</key><string>$FLEETSCOPE_PORT</string>
    <key>AI_DEVOPS_RELEASEGUARD_PORT</key><string>$RELEASEGUARD_PORT</string>
  </dict>
  <key>RunAtLoad</key><true/>
  <key>ProcessType</key><string>Background</string>
</dict></plist>
EOF
      launchctl bootout "gui/$(id -u)/io.aidevops.opensuite" >/dev/null 2>&1 || true
      if ! launchctl bootstrap "gui/$(id -u)" "$LAUNCH_AGENT"; then start_suite; fi
      ;;
    *) printf 'Autostart is not supported on %s.\n' "$platform" >&2; return 1 ;;
  esac
  printf 'Autostart enabled. The configured ports were saved for future sessions.\n'
}

disable_autostart() {
  case "$(uname -s)" in
    Linux)
      systemctl --user disable "$SYSTEMD_UNIT_NAME" >/dev/null 2>&1 || true
      rm -f "$SYSTEMD_UNIT"
      systemctl --user daemon-reload >/dev/null 2>&1 || true
      ;;
    Darwin) rm -f "$LAUNCH_AGENT" ;;
    *) printf 'Autostart is not supported on this platform.\n' >&2; return 1 ;;
  esac
  printf 'Autostart disabled. Running modules were not stopped.\n'
}

open_suite() {
  if command -v open >/dev/null; then open "$url_devcycle"; elif command -v xdg-open >/dev/null; then xdg-open "$url_devcycle"; else printf 'Open %s\n' "$url_devcycle"; fi
}

show_logs() {
  for file in "$LOGS"/*.log; do [[ -f "$file" ]] || continue; printf '\n== %s ==\n' "$(basename "$file")"; tail -n 40 "$file"; done
}

case "${1:-status}" in
  init) init_suite ;;
  start) start_suite ;;
  stop) stop_suite ;;
  restart) stop_suite; start_suite ;;
  status) status_suite ;;
  open) open_suite ;;
  logs) show_logs ;;
  doctor) doctor_suite ;;
  enable) enable_autostart ;;
  disable) disable_autostart ;;
  *) printf 'Usage: suitectl {init|start|stop|restart|status|open|logs|doctor|enable|disable}\n' >&2; exit 2 ;;
esac
