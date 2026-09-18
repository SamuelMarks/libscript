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
  - **`build-msi`**: Generates WiX Windows Installer (`.msi`) packages on `windows-latest` via an
    extensible matrix strategy (starting with Open edX Platform). Computes SHA256 checksums and
    uploads artifacts.
  - **Future Builders**: Scaffolding and architecture ready for `.exe` (Inno Setup / NSIS), macOS
    (`.pkg` / `.dmg`), and Linux (`.deb` / `.rpm`) builders.
  - **`publish-release`**: Consolidates all built artifacts, generates a unified `SHA256SUMS.txt`,
    and publishes them directly to GitHub Releases via the GitHub CLI.
