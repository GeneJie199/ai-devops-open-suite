# Maintainer workstation transfer

Updated: 2026-10-17

This document is the durable recovery path for moving AI DevOps Open Suite development to another computer. The source of truth remains the six public GitHub repositories; local databases, credentials, generated binaries, `.qa` evidence, and editor caches are intentionally excluded.

## Repository layout

Clone these repositories as sibling directories under one parent folder:

| Local directory | Repository | Branch | Stable release |
|---|---|---|---|
| `project-docs` | `https://github.com/GeneJie199/ai-devops-open-suite.git` | `main` | `v1.0.0` |
| `lifecycle-spec` | `https://github.com/GeneJie199/lifecycle-spec.git` | `main` | `v1.0.0` |
| `ai-dev-cycle-manager` | `https://github.com/GeneJie199/ai-dev-cycle-manager.git` | `main` | `v1.0.0` |
| `infrastructure-discovery` | `https://github.com/GeneJie199/infrastructure-discovery.git` | `main` | `v1.0.0` |
| `fleet-observability` | `https://github.com/GeneJie199/fleet-observability.git` | `main` | `v1.0.0` |
| `release-validation` | `https://github.com/GeneJie199/release-validation.git` | `main` | `v1.0.0` |

Keep one editor workspace per repository. This preserves clear Git status, commit, and push boundaries.

## Restore and verify

1. Install Git and Go using versions supported by each repository's `go.mod` and CI workflow.
2. Clone all six repositories into one parent directory using the layout above.
3. Confirm each checkout is on `main`, has `origin` set to the listed URL, and is clean.
4. Run the suite acceptance gate from the parent directory:

   ```powershell
   .\project-docs\scripts\verify-suite.ps1
   ```

   or:

   ```bash
   ./project-docs/scripts/verify-suite.sh
   ```

5. For a product trial, use the public one-command installer from the main README rather than carrying local binaries between computers.

The machine-transfer archive produced by the maintainer additionally contains one-workspace-per-repository editor definitions, a repository snapshot with exact commit IDs, and local control documents. Validate its adjacent SHA-256 file before extracting it.

## Security boundary

Do not copy local tokens, `.env` files, SQLite databases, host inventories, private reports, approvals, SSH material, browser profiles, `.qa` directories, or generated build caches into the transfer archive. Recreate credentials on the new computer and revoke any credential that is no longer needed on the old one.

The public `v1.0.0` release remains immutable. Future fixes use a new patch version; published tags are never moved or reused.
