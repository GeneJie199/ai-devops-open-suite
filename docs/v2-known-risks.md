# v2 C0 boundaries and known risks

No known P0 remains after the recorded tests and independent review. The five concrete
audit findings are fixed; see [review](v2-review.md).

| Priority | Boundary / treatment |
|---|---|
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
