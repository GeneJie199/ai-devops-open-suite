# M6 Unified Product UX Checkpoint

Date: 2026-08-23  
Decision: GO  
Scope: DevCycle, InfraScout, FleetScope, ReleaseGuard

## Delivered

- Published and applied the shared suite token, typography, radius, focus, module-switcher, responsive, state, dialog, and accessibility baseline.
- Standardized the module switcher on all four products with Lucide icons, consistent names and descriptions, current-page semantics, outside-click close, and `Escape` close with focus return.
- Added skip links, focusable main targets, active-view level-one headings, route titles, dialog title bindings, and regression assertions.
- Preserved domain-appropriate product structure: DevCycle workflow, InfraScout fact/drift tabs, FleetScope dense monitoring shell, and ReleaseGuard release decision flow.
- Kept all mobile feature entry points. FleetScope credentials remain available at 390px, and ReleaseGuard command icons retain accessible names without wrapping labels vertically.
- Added non-color series numbers and line patterns to FleetScope charts, plus non-color topology stroke patterns.
- Prevented InfraScout and FleetScope background polling from replacing a focused control. InfraScout also restores input focus, selection, expansion, and scroll state after meaningful data changes.
- Limited live-region output to meaningful state transitions. ReleaseGuard decision, release stages, and observation progress are exposed to assistive technology without announcing every timestamp tick.

## Review evidence

Kimi K3 review session: `session_3d981a28-7f5b-433f-ac13-76037c84207d`

The review used four product-specific audits plus one cross-product comparison. It found no P0 issue. All identified M6 P1 issues were addressed, including missing headings and skip links, dialog names, inaccessible dynamic release status, polling focus loss, hidden mobile credentials, focus contrast, placeholder-only search naming, and color-only chart differentiation.

The accepted cross-product baseline is documented in [design-system.md](design-system.md). Domain differences that improve operational use were retained instead of forcing all screens into one layout.

## Browser acceptance

All four embedded services were rebuilt and tested through their real local HTTP endpoints.

| Viewport | DevCycle | InfraScout | FleetScope | ReleaseGuard |
|---|---|---|---|---|
| 1440 x 1000 | Pass | Pass | Pass | Pass |
| 768 x 900 | Pass | Pass | Pass | Pass |
| 390 x 844 | Pass | Pass | Pass | Pass |

Across all 12 product/viewport combinations:

- no whole-page horizontal overflow;
- no visible unnamed control;
- no unlabeled dialog;
- skip link and focusable main target present;
- one active level-one heading present;
- four icon-backed suite destinations present;
- no unexpected visible error state.

Additional interaction checks passed:

- Suite switcher closes with `Escape` and returns focus to its summary.
- InfraScout asset search retained focus and value across a complete 10-second polling interval.
- FleetScope node search retained focus and value across a complete 30-second polling interval.
- FleetScope credential management remains a 40 x 40px accessible control at 390px.
- ReleaseGuard exposes the final decision as a polite status, includes text status for all five release stages, and announces observation transitions.

## Automated acceptance

- `node --check` passed for every changed `app.js` and the byte-identical shared `suite.js` copies.
- `go test ./...` and `go vet ./...` passed in all four product repositories.
- Product web tests now assert the M6 accessibility contract so later UI work cannot silently remove the required semantics.
- `git diff --check` passed in all changed repositories.

## Delivered commits

| Repository | Commit |
|---|---|
| DevCycle | `5a41f5f` |
| InfraScout | `bfa6886` |
| FleetScope | `b50a7bd` |
| ReleaseGuard | `64a3294` |

All four commits were pushed to `origin/main`. GitHub CI completed successfully for runs `32599841783`, `32599840981`, `32599841161`, and `32599840816`.
