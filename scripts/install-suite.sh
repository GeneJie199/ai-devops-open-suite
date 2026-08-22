#!/usr/bin/env bash
set -euo pipefail

PREFIX=${AI_DEVOPS_HOME:-"$HOME/.local/share/ai-devops-suite"}
SOURCE_ROOT=
MANIFEST_INDEX=
START=false
ENABLE_AUTOSTART=false
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BUNDLE_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

usage() {
  printf '%s\n' 'Usage: install-suite.sh [--prefix DIR] [--manifest-index FILE] [--source-root DIR] [--start] [--enable-autostart]'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prefix) PREFIX=$2; shift 2 ;;
    --manifest-index) MANIFEST_INDEX=$2; shift 2 ;;
    --source-root) SOURCE_ROOT=$2; shift 2 ;;
    --version|--suite-version|--spec-version) printf '%s now requires a versioned manifest; use --manifest-index.\n' "$1" >&2; exit 2 ;;
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
PLATFORM="$OS-$ARCH"

if [[ -z "$MANIFEST_INDEX" ]]; then
  if [[ -f "$BUNDLE_ROOT/install-assets.txt" ]]; then MANIFEST_INDEX="$BUNDLE_ROOT/install-assets.txt"; else MANIFEST_INDEX="$BUNDLE_ROOT/manifests/install-$PLATFORM.txt"; fi
fi
[[ -f "$MANIFEST_INDEX" ]] || { printf 'Suite install index not found: %s\n' "$MANIFEST_INDEX" >&2; exit 1; }

COMPONENT_ROWS=()
PROTOCOL_ROW=
line_number=0
while IFS= read -r line || [[ -n "$line" ]]; do
  line=${line%$'\r'}
  ((line_number+=1))
  IFS='|' read -r -a fields <<<"$line"
  if (( line_number == 1 )); then
    [[ ${#fields[@]} == 4 && ${fields[0]} == suite && ${fields[1]} == ai-devops.suite-manifest/v1 && ${fields[3]} == "$PLATFORM" ]] || { printf 'Invalid suite install index header for %s\n' "$PLATFORM" >&2; exit 1; }
    SUITE_VERSION=${fields[2]}
    [[ "$SUITE_VERSION" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]] || { printf 'Invalid suite version in install index.\n' >&2; exit 1; }
  elif [[ ${fields[0]:-} == component ]]; then
    [[ ${#fields[@]} == 8 ]] || { printf 'Invalid component row at line %d.\n' "$line_number" >&2; exit 1; }
    for value in "${fields[@]:1:5}" "${fields[6]}"; do [[ "$value" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]] || { printf 'Unsafe component token at line %d.\n' "$line_number" >&2; exit 1; }; done
    [[ ${fields[5]} == "$(basename "${fields[5]}")" && ${fields[7]} =~ ^[0-9a-f]{64}$ ]] || { printf 'Invalid component asset at line %d.\n' "$line_number" >&2; exit 1; }
    COMPONENT_ROWS+=("${fields[*]}")
  elif [[ ${fields[0]:-} == protocol ]]; then
    [[ ${#fields[@]} == 6 && ${fields[4]} == "$(basename "${fields[4]}")" && ${fields[5]} =~ ^[0-9a-f]{64}$ ]] || { printf 'Invalid protocol row at line %d.\n' "$line_number" >&2; exit 1; }
    PROTOCOL_ROW="${fields[*]}"
  else
    printf 'Unknown install index row at line %d.\n' "$line_number" >&2; exit 1
  fi
done <"$MANIFEST_INDEX"
(( ${#COMPONENT_ROWS[@]} > 0 )) && [[ -n "$PROTOCOL_ROW" ]] || { printf 'Install index is incomplete.\n' >&2; exit 1; }

if [[ -n "$SOURCE_ROOT" ]]; then
  SOURCE_ROOT=$(cd "$SOURCE_ROOT" && pwd)
elif [[ -d "$BUNDLE_ROOT/assets/$PLATFORM" ]]; then
  SOURCE_ROOT=$BUNDLE_ROOT
fi
OFFLINE_MODE=false
if [[ -n "$SOURCE_ROOT" ]]; then OFFLINE_MODE=true; else command -v curl >/dev/null || { printf 'Missing dependency: curl\n' >&2; exit 1; }; fi

PREFIX=$(mkdir -p "$PREFIX" && cd "$PREFIX" && pwd)
BIN="$PREFIX/bin"
EXAMPLES="$PREFIX/examples"
CONFIG="$PREFIX/config"
PROTOCOLS="$PREFIX/protocols"
BACKUPS="$PREFIX/backups"
STAGE=$(mktemp -d "${TMPDIR:-/tmp}/ai-devops-install.XXXXXX")
STAGED_BIN="$STAGE/bin"
PREVIOUS_VERSION=$(if [[ -f "$CONFIG/suite-version" ]]; then cat "$CONFIG/suite-version"; else printf unversioned; fi)
BACKUP_ID="$(date -u +%Y%m%dT%H%M%SZ)-$$-${PREVIOUS_VERSION//[^a-zA-Z0-9._-]/_}"
BACKUP_ROOT="$BACKUPS/$BACKUP_ID"
BACKUP_BIN="$BACKUP_ROOT/bin"
BACKUP_CONFIG="$BACKUP_ROOT/config"
cleanup() {
  case "$STAGE" in "${TMPDIR:-/tmp}"/ai-devops-install.*) rm -rf "$STAGE" ;; esac
}
trap cleanup EXIT
mkdir -p "$BIN" "$EXAMPLES" "$STAGED_BIN" "$BACKUP_BIN" "$BACKUP_CONFIG" "$CONFIG" "$PROTOCOLS" "$BACKUPS"

receive() {
  local repo=$1 tag=$2 name=$3 destination=$4
  if [[ "$OFFLINE_MODE" == true ]]; then
    local source
    for source in "$SOURCE_ROOT/assets/$PLATFORM/$name" "$SOURCE_ROOT/protocols/$name" "$SOURCE_ROOT/$repo/$name" "$SOURCE_ROOT/$name"; do
      if [[ -f "$source" ]]; then cp "$source" "$destination"; return; fi
    done
    printf 'Offline asset not found: %s. Checked only %s; network fallback is disabled.\n' "$name" "$SOURCE_ROOT" >&2
    exit 1
  else
    curl --fail --location --retry 3 --output "$destination" "https://github.com/GeneJie199/$repo/releases/download/$tag/$name"
  fi
}

install_product() {
  local repo=$1 tag=$2 asset=$3 target=$4 expected=$5
  local repo_stage="$STAGE/$repo"
  mkdir -p "$repo_stage"
  receive "$repo" "$tag" "$asset" "$repo_stage/$asset"
  local actual
  actual=$(hash_file "$repo_stage/$asset")
  [[ "$actual" == "$expected" ]] || { printf 'SHA-256 mismatch for %s\n' "$asset" >&2; exit 1; }
  install -m 0755 "$repo_stage/$asset" "$STAGED_BIN/$target"
  printf 'Verified %s\n' "$target"
}

targets=()
component_versions=()
for row in "${COMPONENT_ROWS[@]}"; do
  read -r _component id repo tag version asset target digest <<<"$row"
  install_product "$repo" "$tag" "$asset" "$target" "$digest"
  targets+=("$target")
  component_versions+=("$id=$version")
done
read -r _protocol protocol_repo protocol_tag protocol_version protocol_asset protocol_digest <<<"$PROTOCOL_ROW"
receive "$protocol_repo" "$protocol_tag" "$protocol_asset" "$STAGE/$protocol_asset"
[[ $(hash_file "$STAGE/$protocol_asset") == "$protocol_digest" ]] || { printf 'SHA-256 mismatch for %s\n' "$protocol_asset" >&2; exit 1; }
printf 'Verified %s\n' "$protocol_asset"
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

had_previous=false
[[ -x "$BIN/suitectl" ]] && had_previous=true
for target in "${targets[@]}"; do [[ -f "$BIN/$target" ]] && cp -p "$BIN/$target" "$BACKUP_BIN/$target"; done
[[ -f "$BIN/suitectl" ]] && cp -p "$BIN/suitectl" "$BACKUP_BIN/suitectl"
[[ -f "$BIN/install-suite" ]] && cp -p "$BIN/install-suite" "$BACKUP_BIN/install-suite"
if [[ "$had_previous" == true && ! -f "$BACKUP_BIN/install-suite" ]]; then install -m 0755 "$SCRIPT_DIR/install-suite.sh" "$BACKUP_BIN/install-suite"; fi
for name in suite-version suite-manifest.json install-assets.txt install-state.json; do [[ -f "$CONFIG/$name" ]] && cp -p "$CONFIG/$name" "$BACKUP_CONFIG/$name"; done
printf '{"schemaVersion":"ai-devops.install-backup/v1","backupId":"%s","previousVersion":"%s","targetVersion":"%s","createdAt":"%s","wasRunning":%s,"hadPreviousInstallation":%s}\n' \
  "$BACKUP_ID" "$PREVIOUS_VERSION" "$SUITE_VERSION" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$was_running" "$had_previous" >"$BACKUP_ROOT/backup-state.json"
chmod 0600 "$BACKUP_ROOT/backup-state.json"
write_backup_manifest() {
  local root=$1 file relative size digest
  : >"$root/backup-files.txt"
  for file in "$root/bin"/* "$root/config"/* "$root/backup-state.json"; do
    [[ -f "$file" ]] || continue
    relative=${file#"$root/"}
    size=$(wc -c <"$file" | tr -d ' ')
    digest=$(hash_file "$file")
    printf '%s|%s|%s\n' "$digest" "$size" "$relative" >>"$root/backup-files.txt"
  done
  chmod 0600 "$root/backup-files.txt"
}
write_backup_manifest "$BACKUP_ROOT"

install_payload() {
  local target
  for target in "${targets[@]}"; do
    install -m 0755 "$STAGED_BIN/$target" "$BIN/$target.new" || return 1
    mv -f "$BIN/$target.new" "$BIN/$target" || return 1
  done
  install -m 0755 "$SCRIPT_DIR/suitectl.sh" "$BIN/suitectl.new" || return 1
  mv -f "$BIN/suitectl.new" "$BIN/suitectl" || return 1
  install -m 0755 "$SCRIPT_DIR/install-suite.sh" "$BIN/install-suite.new" || return 1
  mv -f "$BIN/install-suite.new" "$BIN/install-suite" || return 1
}

restore_previous_install() {
  printf 'Install commit failed; restoring the previous installation.\n' >&2
  for target in "${targets[@]}"; do
    if [[ -f "$BACKUP_BIN/$target" ]]; then cp -p "$BACKUP_BIN/$target" "$BIN/$target"; else rm -f "$BIN/$target"; fi
    rm -f "$BIN/$target.new"
  done
  if [[ -f "$BACKUP_BIN/suitectl" ]]; then cp -p "$BACKUP_BIN/suitectl" "$BIN/suitectl"; else rm -f "$BIN/suitectl"; fi
  if [[ -f "$BACKUP_BIN/install-suite" ]]; then cp -p "$BACKUP_BIN/install-suite" "$BIN/install-suite"; else rm -f "$BIN/install-suite"; fi
  rm -f "$BIN/suitectl.new"
  rm -f "$BIN/install-suite.new"
  for name in suite-version suite-manifest.json install-assets.txt install-state.json; do
    if [[ -f "$BACKUP_CONFIG/$name" ]]; then cp -p "$BACKUP_CONFIG/$name" "$CONFIG/$name"; else rm -f "$CONFIG/$name"; fi
    rm -f "$CONFIG/$name.new"
  done
  if [[ "$was_running" == true && -x "$BIN/suitectl" ]]; then "$BIN/suitectl" start || true; fi
}

finalize_install() {
  install -m 0644 "$SCRIPT_DIR/../examples/release-report.demo.json" "$EXAMPLES/release-report.demo.json" || return 1
  install -m 0644 "$STAGE/$protocol_asset" "$PROTOCOLS/$protocol_asset" || return 1
  if [[ -f "$BUNDLE_ROOT/suite-manifest.json" ]]; then
    install -m 0644 "$BUNDLE_ROOT/suite-manifest.json" "$CONFIG/suite-manifest.json.new" || return 1
    mv -f "$CONFIG/suite-manifest.json.new" "$CONFIG/suite-manifest.json" || return 1
  fi
  install -m 0644 "$MANIFEST_INDEX" "$CONFIG/install-assets.txt.new" || return 1
  mv -f "$CONFIG/install-assets.txt.new" "$CONFIG/install-assets.txt" || return 1
  printf '%s' "$SUITE_VERSION" >"$CONFIG/suite-version" || return 1

  install_state="$CONFIG/install-state.json.new"
  printf '{\n  "schemaVersion": "ai-devops.install-state/v1",\n  "suiteVersion": "%s",\n  "platform": "%s",\n  "installedAt": "%s",\n  "source": "%s",\n  "components": [' \
    "$SUITE_VERSION" "$PLATFORM" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$(if [[ "$OFFLINE_MODE" == true ]]; then printf offline; else printf online; fi)" >"$install_state" || return 1
  separator=''
  for row in "${COMPONENT_ROWS[@]}"; do
    read -r _component id repo tag version asset target digest <<<"$row"
    printf '%s\n    {"id":"%s","repository":"%s","version":"%s","tag":"%s","target":"%s","asset":"%s","sha256":"%s"}' \
      "$separator" "$id" "$repo" "$version" "$tag" "$target" "$asset" "$digest" >>"$install_state" || return 1
    separator=,
  done
  printf '\n  ],\n  "protocol": {"repository":"%s","version":"%s","tag":"%s","asset":"%s","sha256":"%s"},\n  "previousBackup": %s,\n  "dataPreserved": true\n}\n' \
    "$protocol_repo" "$protocol_version" "$protocol_tag" "$protocol_asset" "$protocol_digest" \
    "$(if [[ "$had_previous" == true ]]; then printf '"%s"' "$BACKUP_ID"; else printf null; fi)" >>"$install_state" || return 1
  chmod 0600 "$install_state" || return 1
  mv -f "$install_state" "$CONFIG/install-state.json" || return 1
  if [[ "$had_previous" == false ]]; then rm -rf "$BACKUP_ROOT" || return 1; fi
  "$BIN/suitectl" init || return 1
}

if ! install_payload || ! finalize_install; then
  restore_previous_install
  exit 1
fi

printf '\nAI DevOps Open Suite %s installed in %s (%d verified components, %s)\n' "$SUITE_VERSION" "$PREFIX" "${#targets[@]}" "$(if [[ "$OFFLINE_MODE" == true ]]; then printf offline; else printf online; fi)"
if [[ "$had_previous" == true ]]; then printf 'Rollback backup: %s\n' "$BACKUP_ID"; fi
if [[ "$ENABLE_AUTOSTART" == true ]]; then
  "$BIN/suitectl" enable
elif [[ "$START" == true || "$was_running" == true ]]; then
  "$BIN/suitectl" start
else
  printf 'Start:  %s start\n' "$BIN/suitectl"
  printf 'Status: %s status\n' "$BIN/suitectl"
fi
