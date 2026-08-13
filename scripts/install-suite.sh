#!/usr/bin/env bash
set -euo pipefail

VERSION=0.3.2
SUITE_VERSION=0.3.3
SPEC_VERSION=0.1.1
PREFIX=${AI_DEVOPS_HOME:-"$HOME/.local/share/ai-devops-suite"}
SOURCE_ROOT=
START=false
ENABLE_AUTOSTART=false
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

usage() {
  printf '%s\n' 'Usage: install-suite.sh [--prefix DIR] [--version VERSION] [--suite-version VERSION] [--spec-version VERSION] [--source-root DIR] [--start] [--enable-autostart]'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prefix) PREFIX=$2; shift 2 ;;
    --version) VERSION=$2; shift 2 ;;
    --suite-version) SUITE_VERSION=$2; shift 2 ;;
    --spec-version) SPEC_VERSION=$2; shift 2 ;;
    --source-root) SOURCE_ROOT=$2; shift 2 ;;
    --start) START=true; shift ;;
    --enable-autostart) ENABLE_AUTOSTART=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

command -v mktemp >/dev/null || { printf 'Missing dependency: mktemp\n' >&2; exit 1; }
if command -v sha256sum >/dev/null; then
  hash_file() { sha256sum "$1" | awk '{print tolower($1)}'; }
elif command -v shasum >/dev/null; then
  hash_file() { shasum -a 256 "$1" | awk '{print tolower($1)}'; }
else
  printf 'Missing dependency: sha256sum or shasum\n' >&2
  exit 1
fi
if [[ -z "$SOURCE_ROOT" ]]; then
  command -v curl >/dev/null || { printf 'Missing dependency: curl\n' >&2; exit 1; }
fi

case "$(uname -s)" in
  Linux) OS=linux ;;
  Darwin) OS=darwin ;;
  *) printf 'Unsupported operating system: %s\n' "$(uname -s)" >&2; exit 1 ;;
esac
case "$(uname -m)" in
  x86_64|amd64) ARCH=amd64 ;;
  arm64|aarch64) ARCH=arm64 ;;
  *) printf 'Unsupported architecture: %s\n' "$(uname -m)" >&2; exit 1 ;;
esac

PREFIX=$(mkdir -p "$PREFIX" && cd "$PREFIX" && pwd)
BIN="$PREFIX/bin"
EXAMPLES="$PREFIX/examples"
STAGE=$(mktemp -d "${TMPDIR:-/tmp}/ai-devops-install.XXXXXX")
STAGED_BIN="$STAGE/bin"
BACKUP_BIN="$STAGE/backup"
cleanup() {
  case "$STAGE" in "${TMPDIR:-/tmp}"/ai-devops-install.*) rm -rf "$STAGE" ;; esac
}
trap cleanup EXIT
mkdir -p "$BIN" "$EXAMPLES" "$STAGED_BIN" "$BACKUP_BIN"
mkdir -p "$PREFIX/config"

receive() {
  local repo=$1 tag=$2 name=$3 destination=$4
  if [[ -n "$SOURCE_ROOT" ]]; then
    local source="$SOURCE_ROOT/$repo/$name"
    [[ -f "$source" ]] || { printf 'Offline asset not found: %s\n' "$source" >&2; exit 1; }
    cp "$source" "$destination"
  else
    curl --fail --location --retry 3 --output "$destination" "https://github.com/GeneJie199/$repo/releases/download/$tag/$name"
  fi
}

install_product() {
  local repo=$1 tag=$2 asset=$3 target=$4
  local repo_stage="$STAGE/$repo"
  mkdir -p "$repo_stage"
  receive "$repo" "$tag" "$asset" "$repo_stage/$asset"
  receive "$repo" "$tag" checksums.txt "$repo_stage/checksums.txt"
  (
    cd "$repo_stage"
    local expected
    expected=$(tr -d '\r' <checksums.txt | awk -v name="$asset" '$2 == name || $2 == "*" name { print tolower($1); exit }')
    [[ "$expected" =~ ^[0-9a-f]{64}$ ]] || { printf 'Checksum entry missing for %s\n' "$asset" >&2; exit 1; }
    local actual
    actual=$(hash_file "$asset")
    [[ "$actual" == "$expected" ]] || { printf 'SHA-256 mismatch for %s\n' "$asset" >&2; exit 1; }
  )
  install -m 0755 "$repo_stage/$asset" "$STAGED_BIN/$target"
  printf 'Verified %s\n' "$target"
}

install_product lifecycle-spec "v$SPEC_VERSION" "lifecycle-validate-$OS-$ARCH" lifecycle-validate
install_product ai-dev-cycle-manager "v$VERSION" "devcycle-$OS-$ARCH" devcycle
install_product infrastructure-discovery "v$VERSION" "infrascout-$OS-$ARCH" infrascout
install_product fleet-observability "v$VERSION" "fleetctl-$OS-$ARCH" fleetctl
install_product release-validation "v$VERSION" "releaseguard-$OS-$ARCH" releaseguard

targets=(lifecycle-validate devcycle infrascout fleetctl releaseguard)
was_running=false
for pid_file in "$PREFIX/run"/*.pid; do
  [[ -f "$pid_file" ]] || continue
  managed_name=$(basename "$pid_file" .pid)
  case "$managed_name" in
    devcycle|infrascout|releaseguard) managed_binary=$managed_name ;;
    fleetscope|fleet-agent) managed_binary=fleetctl ;;
    *) continue ;;
  esac
  pid=$(cat "$pid_file")
  [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null || continue
  expected_path=$(cd "$BIN" && pwd -P)/$managed_binary
  actual_path=''
  if [[ -e "/proc/$pid/exe" ]]; then
    actual_path=$(readlink -f "/proc/$pid/exe" 2>/dev/null || true)
  elif [[ $(uname -s) == Darwin ]]; then
    command_line=$(ps -p "$pid" -o command= 2>/dev/null || true)
    if [[ "$command_line" == "$expected_path" || "$command_line" == "$expected_path "* ]]; then actual_path=$expected_path; fi
  fi
  if [[ "$actual_path" == "$expected_path" ]]; then was_running=true; break; fi
done
if [[ "$was_running" == true && -x "$BIN/suitectl" ]]; then
  printf 'Stopping the running suite for an atomic upgrade...\n'
  "$BIN/suitectl" stop
fi

for target in "${targets[@]}"; do [[ -f "$BIN/$target" ]] && cp -p "$BIN/$target" "$BACKUP_BIN/$target"; done
[[ -f "$BIN/suitectl" ]] && cp -p "$BIN/suitectl" "$BACKUP_BIN/suitectl"

install_payload() {
  local target
  for target in "${targets[@]}"; do
    install -m 0755 "$STAGED_BIN/$target" "$BIN/$target.new" || return 1
    mv -f "$BIN/$target.new" "$BIN/$target" || return 1
  done
  install -m 0755 "$SCRIPT_DIR/suitectl.sh" "$BIN/suitectl.new" || return 1
  mv -f "$BIN/suitectl.new" "$BIN/suitectl" || return 1
}

if ! install_payload; then
  printf 'Install failed; restoring the previous binaries.\n' >&2
  for target in "${targets[@]}"; do
    if [[ -f "$BACKUP_BIN/$target" ]]; then cp -p "$BACKUP_BIN/$target" "$BIN/$target"; else rm -f "$BIN/$target"; fi
    rm -f "$BIN/$target.new"
  done
  if [[ -f "$BACKUP_BIN/suitectl" ]]; then cp -p "$BACKUP_BIN/suitectl" "$BIN/suitectl"; else rm -f "$BIN/suitectl"; fi
  rm -f "$BIN/suitectl.new"
  if [[ "$was_running" == true && -x "$BIN/suitectl" ]]; then "$BIN/suitectl" start || true; fi
  exit 1
fi

install -m 0644 "$SCRIPT_DIR/../examples/release-report.demo.json" "$EXAMPLES/release-report.demo.json"
printf '%s' "$SUITE_VERSION" >"$PREFIX/config/suite-version"
"$BIN/suitectl" init
printf '\nAI DevOps Open Suite %s installed in %s (components %s)\n' "$SUITE_VERSION" "$PREFIX" "$VERSION"
if [[ "$ENABLE_AUTOSTART" == true ]]; then
  "$BIN/suitectl" enable
elif [[ "$START" == true || "$was_running" == true ]]; then
  "$BIN/suitectl" start
else
  printf 'Start:  %s start\n' "$BIN/suitectl"
  printf 'Status: %s status\n' "$BIN/suitectl"
fi
