# Dependency Management

LibScript uses an abstracted dependency management system to facilitate cross-platform software provisioning. This allows users to define stack components generically without writing OS-specific package manager commands.

## Cross-Platform Package Translation

The system inherently understands the package managers of supported environments (`apt`, `apk`, `dnf`, `brew`, `pacman`, `pkg`, `choco`, `winget`).
When a component declares a generic dependency (e.g., `libssl-dev`), LibScript maps it to the appropriate local package format for Alpine, RHEL, macOS, or Windows at execution time.

## Component Wiring

Components within a stack (such as a database and a web server) can declare dependencies on each other via their `vars.schema.json` files.
LibScript supports different dependency resolution modes:
- `reuse`: Links to an existing service or database.
- `install-alongside`: Installs an isolated instance for the specific stack.
- `overwrite`: Replaces the current installation.

## Automated Network Mapping

When used in generator mode (e.g., outputting a `docker-compose.yml`), the dependency engine maps inter-component dependencies into the correct container network links and environment variables, ensuring consistent communication between services.
