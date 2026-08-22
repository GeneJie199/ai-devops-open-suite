#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
work=$(mktemp -d "${TMPDIR:-/tmp}/ai-devops-bootstrap-accept.XXXXXX")
cleanup() {
  case "$work" in "${TMPDIR:-/tmp}"/ai-devops-bootstrap-accept.*) rm -rf -- "$work" ;; esac
}
trap cleanup EXIT HUP INT TERM

serve="$work/release"
package="$work/stage/ai-devops-open-suite"
prefix="$work/install/ai-devops-suite"
mkdir -p "$serve" "$package/scripts" "$package/examples" "$package/docs"
cp "$repo"/scripts/{install-suite.sh,install-suite.ps1,suitectl.sh,suitectl.ps1} "$package/scripts/"
cp "$repo/examples/release-report.demo.json" "$package/examples/"
cp "$repo"/docs/{quickstart.md,offline-install.md} "$package/docs/"
cp -R "$repo/manifests" "$package/"
cp "$repo"/{README.md,LICENSE,SECURITY.md,COMPATIBILITY.md,SUPPORT_MATRIX.md,RELEASE_POLICY.md,suite-manifest.json} "$package/"
tar -C "$work/stage" -czf "$serve/ai-devops-open-suite-online.tar.gz" ai-devops-open-suite
sha256sum "$serve/ai-devops-open-suite-online.tar.gz" | sed 's#  .*/#  #' >"$serve/checksums.txt"

AI_DEVOPS_RELEASE_URL="file://$serve" bash "$repo/scripts/bootstrap.sh" --prefix "$prefix"
for name in lifecycle-validate devcycle infrascout fleetctl releaseguard; do
  [[ -x "$prefix/bin/$name" ]] || { printf 'Bootstrap installation is missing %s.\n' "$name" >&2; exit 1; }
done
state="$prefix/config/install-state.json"
grep -q '"source": "online"' "$state"
[[ $(grep -c '"id":' "$state") -eq 5 ]]
version=$(tr -d '\r\n' <"$prefix/config/suite-version")
printf '{"schema":"ai-devops.bootstrap-acceptance/v1","platform":"linux-amd64","suiteVersion":"%s","checksum":true,"componentCount":5,"cleanInstall":true,"cleanup":true}\n' "$version"
