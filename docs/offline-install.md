# Full Offline Installation

The full offline archive is platform-specific and already contains every executable, protocol artifact, checksum, installer, controller, and document needed by that platform.

## Windows amd64

1. On a connected machine, download `ai-devops-open-suite-full-offline-v<version>-windows-amd64.zip` and its published checksum.
2. Move the archive to the offline Windows machine and extract it.
3. From the extracted `ai-devops-open-suite` directory, run:

```powershell
.\scripts\install-suite.ps1 -Start
```

## Linux or macOS

1. On a connected machine, download the archive whose OS and architecture match the offline machine and its published checksum.
2. Move the archive to the offline machine and extract it.
3. From the extracted `ai-devops-open-suite` directory, run:

```bash
./scripts/install-suite.sh --start
```

The installer detects the bundled `assets/<platform>` directory, verifies every SHA-256 digest from the suite manifest, and stays in offline mode. A missing or mismatched file is a hard failure; it does not silently download a replacement.

Upgrade writes an integrity-checked backup and a durable transaction journal before stopping a running suite or replacing files. If the installer process or machine stops after mutation begins, run the same installer command again. It verifies the saved backup, restores the prior working installation, records recovery metadata in `config/last-install-recovery.json`, and then retries the install. Do not delete `config/install-transaction.*` or the referenced backup manually.

Run `suitectl doctor` after installation. The full v1.0 acceptance report will identify which platforms completed a native runtime test and which are build-tested only.
