# Unified product UI

All existing and new product pages share the same visual system, including setup,
Provider management, task execution, delivery, empty/error states and dialogs.
Each product remains independently usable and embeds its own assets.

The maintained sources are [suite-design.css](../assets/ui/suite-design.css) and
[suite-ui.js](../assets/ui/suite-ui.js). Product distributions copy these files
byte for byte. Product-specific layouts and chart code stay in each product's
own stylesheet and scripts; do not fork the shared theme implementation.

## Design

- Light: `#F7F9FD` canvas, white surfaces and `#141B2B` text.
- Dark: `#0C1220` canvas, `#151D2D` surfaces and `#F2F6FF` text.
- Blue and purple actions, distinct colorful chart series, green/amber/red
  semantics accompanied by text or symbols.
- Compact top bar, product sidebar, 8 px spacing rhythm, 14 px cards, restrained
  borders/shadows and readable Chinese/English typography.
- Desktop uses a 12-column grid. At 760 px and below the sidebar becomes a
  keyboard-operable disclosure; content remains usable at 390 px.

Reference concepts inform style only. Their metrics, Provider statuses, model
names, charts and release decisions are not product facts. Display actual API
data, explicit source labels and meaningful no-data states. Do not synthesize
healthy services, successful tests, progress or a release approval.

## Page integration

Load the product stylesheet first, followed by `suite-design.css`. Load
`suite-ui.js` as a normal external deferred script. All assets must be available
offline from the product's embedded static filesystem.

Set `data-suite-product` and `data-suite-nav="#existing-navigation-id"` on
`body`. Mark the existing top bar with `data-ui-header` and main content with
`data-ui-main`. Keep existing IDs, event handlers and permission checks. Shared
code adds `.suite-topbar`, `.suite-side-nav`, `.suite-main` and the theme/menu
controls; it does not load product data or grant execution rights.

Use `--ui-*` variables for all surfaces, text, borders and chart colors. Existing
`--suite-*` tokens map to the same variables. Available primitives include
`.ui-card`, `.ui-hero`, `.ui-grid`, `.ui-col-4/6/8/12`, `.ui-kpis`, `.ui-kpi`,
`.ui-primary`, `.ui-secondary`, `.ui-empty`, `.ui-error` and `.ui-badge` with a
textual status. Native charts use `--ui-chart-1` through `--ui-chart-6`; retain
units, labels and accessible descriptions in both themes.

## Theme and navigation

The user selects Light, Dark or System. Preference is stored per origin under
`ai-devops.ui.theme.v2` and carried between Suite modules in the `suite-theme`
query parameter. Storage denial must not break the page. The resolved mode is
`html[data-suite-theme="light|dark"]`; the selected mode is
`data-suite-theme-mode`. Charts needing a redraw can listen for
`suite:themechange` with `{mode, resolved}`.

`window.SuiteUI` exposes `setTheme`, `getTheme` and `refreshNavigation`.
Existing module discovery owns ports and Suite context. Shared presentation
decorates resolved `data-suite` / `data-module-port` links without changing
their host, port or sibling context. Add `data-ui-link` to local page links.
For a link to the DevCycle listener, `data-suite-page="suite|team|providers|delivery"`
selects an explicit destination page while retaining the discovered instance.

## Acceptance

Verify actual product behavior and screenshots in Light/Dark at desktop,
tablet and mobile widths. Exercise navigation, theme persistence, keyboard
focus, reduced motion, loading, empty/error recovery and critical forms.
Color must not be the only indication of status. Shared JavaScript unit tests
cover theme and cross-instance navigation behavior; these tests do not replace
real browser acceptance. Keep standalone exported reports self-contained.

UI appearance does not establish GA readiness, release permission or support
for untrusted multi-user execution.
