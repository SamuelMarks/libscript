# GitHub Workflows

This directory contains GitHub Actions workflow definitions for continuous integration, automated
testing, and installer release packaging across supported platforms.

## Workflows

### 1. `ci.yml` (CI Tests)

Automated pre-commit checks running across `ubuntu-latest`, `macos-latest`, and `windows-latest`.

- **Triggers**: Push or pull requests targeting the `master` branch.
- **Tasks**: Line ending enforcement, code formatting (Prettier), spellchecking (cspell), shell
  linting (ShellCheck), and documentation generation.

### 2. `release.yml` (Release Packages)

Builds native installers and publishes compiled packages and cryptographic checksums to GitHub
Releases.

- **Triggers**:
  - Pushing a Git release tag (`v*`).
  - Publishing a GitHub Release.
  - Manual trigger via `workflow_dispatch` (with optional `tag_name`, `draft`, and `prerelease`
    parameters).
- **Architecture**:
  - **`hydrate-cache`**: Centralized offline artifact cache hydration step running first. Downloads
    and cryptographically verifies runtimes, datastores, wheels, and codebase archives into
    `cache/`, prunes debug symbols, caches via `actions/cache`, and uploads the hydrated cache
    artifact.
  - **`build-msi`**: Runs in parallel across the package matrix after `hydrate-cache` completes.
    Restores the hydrated cache, builds WiX Windows Installer (`.msi`) packages on `windows-latest`
    for online and offline variants, and uploads MSI artifacts.
  - **Future Builders**: Scaffolding and architecture ready for `.exe` (Inno Setup / NSIS), macOS
    (`.pkg` / `.dmg`), and Linux (`.deb` / `.rpm`) builders, all chained downstream of
    `hydrate-cache`.
  - **`publish-release`**: Consolidates all built installer artifacts, generates a unified
    `SHA256SUMS.txt`, and publishes them directly to GitHub Releases via the GitHub CLI.
