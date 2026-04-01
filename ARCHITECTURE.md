# Architecture

LibScript is a framework for cross-platform software provisioning and packaging, built on zero-dependency shell scripts. Its architecture consists of a routing execution layer that delegates to modular components.

## The Core

The framework uses native shell scripts (`sh` for POSIX systems, `cmd` and `bat` for Windows) to ensure it can run in environments without pre-installed language runtimes. It acts as both a system-wide package manager and a per-user version manager.

## Component Modules

Components are organized within the `_lib` directory. Each component contains:
- `vars.schema.json`: Strictly typed metadata and dependency definitions.
- `cli.sh`: The entry point for component-specific actions.
- `setup.sh`: Installation logic for POSIX systems.
- `setup_win.ps1` or `setup.cmd`: Installation logic for Windows.

## Cloud Orchestration Layer

The `cloud` component (`_lib/cloud`) provides a unified multicloud interface. It delegates to provider-specific modules in `_lib/cloud-providers/`:
- **AWS**: Delegates to `aws-cli`.
- **Azure**: Delegates to `az`.
- **GCP**: Delegates to `gcloud`.

### Resource Management
- **Tagging**: Automatic and custom tagging (e.g., `ManagedBy=LibScript`) for all resources to enable filtered deprovisioning.
- **Node-Groups**: Logical collections of independent nodes that can be bootstrapped in parallel.
- **Bootstrapping**: Direct integration with cloud-native startup mechanisms to inject LibScript commands into new nodes.

## The Generator Engine (`package_as`)

LibScript uses component metadata to translate native definitions into various production artifacts:
- Containers: `Dockerfile`, `docker-compose.yml`.
- Native Installers: MSI (Windows), DEB (Linux), PKG (macOS), etc.

## PaaS Integration

By combining cloud orchestration with native component management, LibScript functions as a PaaS engine. It can provision the underlying hardware, install necessary services (databases, web servers), configure routing, and schedule maintenance tasks (backups via `cron`).
