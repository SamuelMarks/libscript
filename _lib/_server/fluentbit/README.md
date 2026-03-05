# Fluent Bit

**Fluent Bit** is a super fast, lightweight, and highly scalable logging and metrics processor and forwarder. It allows you to collect data/logs from different sources, unify and send them to multiple destinations.

It's fully compatible with Docker and Kubernetes environments.

## Integration in `libscript`

This module provides basic setup, test, and uninstall capabilities for `fluent-bit`.

### Windows Details
On Windows, it installs via Chocolatey or falls back to natively downloading and extracting the official `.zip` archive from `packages.fluentbit.io`.

### POSIX Details
On Linux and macOS, it delegates to the system package manager (e.g., `apt-get`, `brew`, `apk`) to install `fluent-bit`.

## Variables

For full configuration variables, please refer to the `vars.schema.json`.