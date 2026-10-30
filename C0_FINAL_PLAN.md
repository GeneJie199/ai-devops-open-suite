# C0 final execution plan

Version decision: v2.0.0-rc.1 Community; no GA claim. Generic local CLIs are trusted host execution, strict isolation/metering rejects unsupported adapters.

1. Capture six exact PR/base SHAs and platform rules in C0_FINAL_BASELINE.json. Do not overwrite prior evidence.
2. Three independent agents review runtime/security, contracts/ReleaseGuard, Infra/Fleet and packaging. Fix P1 risk/check secrets and forged candidate GO; regression and independent re-review required.
3. Complete release notes/version metadata/full notices and exact committed source+vendor archives. Verify source offline rebuild and bundle integrity.
4. Run exact-head CI, actual cross-product integration, AI mission, provider negatives and v1.0 upgrade/restart/rollback, schema3/sidecar.
5. Dependency order: lifecycle-spec → DevCycle / Infra / Fleet / ReleaseGuard → Suite. Normal merge with exact-head match, no bypass. Verify each main before continuing.
6. Component release assets must exist before final Suite manifest can pin real asset hashes. Merge all six original PRs (Suite last) and verify their main CI before publishing any tag. Publish verified component RCs, then pin the real downloaded hashes through a normal Suite follow-up PR and verify that final main before the Suite tag. Never reuse a published tag or mutate assets.
7. Verify all final main SHAs, tagged source bindings, download every asset and hashes, install offline, doctor/health and minimal real AI mission. Package requested final evidence and stop before C1.

GitHub baseline: all six PRs draft, clean and mergeable; all six main branches report Branch not protected (HTTP404) and no active rules. This does not waive later live gate checks.
