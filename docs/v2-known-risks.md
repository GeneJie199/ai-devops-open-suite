# v2 boundaries and known risks

## Current C2 candidate scope

Browser onboarding, the Provider Center and Delivery view replace the earlier
Expert-only first-run setup below. Users can select or create a local Git project
and configure connections through forms. Official CLI installation/login still
belongs to the CLI vendor. Kimi without a supported credential remains blocked;
no three-model acceptance is claimed. Candidate synthetic GPT and DeepSeek
Missions have separate source and transport evidence, and do not establish final
published-binary acceptance.

API usage reservations persist across configuration changes and credential
revocation. Unknown usage stops execution until an explicit acknowledgement and
re-verification; acknowledgement does not reset charges. Limits are local to an
installation, not a Provider-wide account meter. Linux private-file secrets are
owner-only but unencrypted. Prefer dedicated development credentials and approved
synthetic source. The API edit protocol and configured machine checks continue
to require a trusted single-user execution host.

Final public re-download, physical 136/168 functional and lifecycle acceptance,
and a continuous actual 24-hour stability cohort must be reported separately.
Earlier rc.1 runs and a shorter candidate observation cannot satisfy that gate.
The C1 aggregate memory-limit events lack enough contemporaneous data to prove a
leak or identify a single responsible process; C2 adds per-unit event counters,
memory attribution and runtime diagnostics. Absence of OOM alone is insufficient.

Two local Windows ReleaseGuard default cold builds failed inside the Go compiler;
a clean bounded offline build passed, as did the hosted native/build gates. The
cause remains undetermined. This is retained as a build observation, not presented
as a repaired default compiler path.

## Historical C0 audit state

The following table records the original C0 scope. Statements about first-run
setup, live vendor coverage and native acceptance are historical, not the current
C2 capability or final C2 result.

No known P0 remains after the recorded tests and independent review. The five concrete
audit findings are fixed; see [review](v2-review.md).

| Priority | Boundary / treatment |
|---|---|
| P1 historical release | Immutable public v1 bundles do not receive this branch's Go/x-text security fixes. The stable manifest still identifies those historical binaries. A separate supported security update is needed before recommending them for production |
| P1 capability boundary | Generic local CLIs are trusted with their OS user's privileges. Worktree/path checks protect integration, not arbitrary OS access. Restrictive enforcement requests are refused; a true enforcing executor is future work |
| P1 capability boundary | CLI token/cost usage remains unknown when unreported. Strict monetary/token budgets refuse unmetered execution rather than invent usage or overspend |
| P1 operational boundary | After a crash, inspect/stop any surviving external worker before explicit retry. Ambiguous executions escalate and do not replay automatically |
| P2 | Keyword/path risk assessment is conservative and can over-classify documentation discussing sensitive operations |
| P2 | First-run team configuration uses an Expert registry/adapter setup; the browser remembers it, but a guided provider onboarding experience is future work |
| P2 | Navigation/status is a public API foundation with default local product links; it is not a federated dashboard or HA control plane |
| P2 | Live model acceptance used the configured Codex service. Kimi/Claude/Gemini/OpenCode adapters are retained, and DeepSeek/local-compatible provider configuration remains available; no unperformed live-vendor acceptance is claimed |
| P2 legal | Policies are drafts/explanations, not signed commercial/CLA contracts or a warranty of undisclosed ownership obligations. Legal review is recommended before broad commercial/OEM operation |

The scheduler is local and serial; every role still receives an isolated worktree.
No ML routing, vector database, distributed scheduler, plugin market, billing, DRM,
forced activation, Enterprise UI, Kubernetes control plane, production auto-deployment,
or automatic main merge was added. Existing Community features remain available.

Runtime/install acceptance in this delivery is native Windows amd64. Other binaries
are build-tested; remote CI also exercises its configured Linux/macOS unit gates.
No unexecuted native Linux/macOS v2 installer acceptance is claimed. Historical v1
Linux install evidence remains historical rather than being relabeled as a v2 test.
