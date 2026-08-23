#!/usr/bin/env bash
set -euo pipefail

base_url=${AI_DEVOPS_RELEASE_URL:-https://github.com/GeneJie199/ai-devops-open-suite/releases/latest/download}
archive=ai-devops-open-suite-online.tar.gz
stage=$(mktemp -d "${TMPDIR:-/tmp}/ai-devops-bootstrap.XXXXXX")
cleanup() {
  case "$stage" in "${TMPDIR:-/tmp}"/ai-devops-bootstrap.*) rm -rf -- "$stage" ;; esac
}
trap cleanup EXIT HUP INT TERM

command -v curl >/dev/null 2>&1 || { echo "curl is required" >&2; exit 1; }
curl --fail --show-error --silent --location "$base_url/$archive" --output "$stage/$archive"
curl --fail --show-error --silent --location "$base_url/checksums.txt" --output "$stage/checksums.txt"
expected=$(awk -v name="$archive" '$2 == name || $2 == "*" name { print tolower($1); exit }' "$stage/checksums.txt")
[ -n "$expected" ] || { echo "checksum entry not found for $archive" >&2; exit 1; }
if command -v sha256sum >/dev/null 2>&1; then
  actual=$(sha256sum "$stage/$archive" | awk '{print tolower($1)}')
else
  actual=$(shasum -a 256 "$stage/$archive" | awk '{print tolower($1)}')
fi
[ "$actual" = "$expected" ] || { echo "SHA-256 verification failed for $archive" >&2; exit 1; }
tar -xzf "$stage/$archive" -C "$stage"
installer="$stage/ai-devops-open-suite/scripts/install-suite.sh"
[ -f "$installer" ] || { echo "verified archive does not contain the suite installer" >&2; exit 1; }
prefix=${AI_DEVOPS_HOME:-$HOME/.local/share/ai-devops-suite}
requested_start=false
if [ "$#" -eq 0 ]; then
  set -- --start
  requested_start=true
fi
arguments=("$@")
for ((index=0; index<${#arguments[@]}; index++)); do
  case "${arguments[$index]}" in
    --start) requested_start=true ;;
    --prefix)
      index=$((index + 1))
      [ "$index" -lt "${#arguments[@]}" ] || { echo "--prefix requires a value" >&2; exit 2; }
      prefix=${arguments[$index]}
      ;;
  esac
done
bash "$installer" "$@"
if [ "$requested_start" = true ]; then
  "$prefix/bin/suitectl" doctor
fi
