# LibScript CLI Engine

## Overview

The LibScript CLI engine (`cli/`) powers the modular command-line interface of LibScript. Commands
are routed through discrete subcommand handlers located in `cli/commands/`.

## Structure

- `commands/core/`: Core CLI operations (discovery, search, versioning, semver comparison).
- `commands/cloud/`: Cloud provisioning, deployment, and deprovisioning commands.
- `commands/deps/`: Dependency resolution and batch download processing.
- `commands/packaging/`: Artifact packaging formats (Docker, deb, rpm, apk, DMG, etc.).
- `commands/registry/`: Component registry updates and indexing.
- `commands/services/`: Daemon and service lifecycle operations (start, stop, logs, status).
