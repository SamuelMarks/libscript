# Pulumi Infrastructure as Code CLI (`_lib/iac/pulumi/`)

## Overview

Pulumi open-source Infrastructure-as-Code SDK and CLI supporting TypeScript, Python, Go, C#, Java,
and YAML.

- **Tier**: `T1` (`_lib/iac/pulumi/`)
- **Capabilities**: `userland-package`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/pulumi/<version>)
./libscript.sh ls-remote pulumi
./libscript.sh install pulumi latest
./libscript.sh use pulumi latest
./libscript.sh which pulumi
./_lib/iac/pulumi/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote pulumi
.\libscript.cmd install pulumi latest
.\libscript.cmd use pulumi latest
.\libscript.cmd which pulumi
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/pulumi/<version>`
  (default `~/.libscript/pulumi/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `PULUMI_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                     | Default            | Aliases/Examples |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `PULUMI_INSTALL_METHOD` | How to install pulumi. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `PULUMI_VERSION`        | Specific version of pulumi to install.                                                                                                          | `latest`           | latest, stable   |
| `PULUMI_DOWNLOAD_URL`   | Override URL for downloading pulumi binary or archive artifacts.                                                                                | `none`             |                  |
| `PULUMI_RELEASES_URL`   | Override URL for querying pulumi available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
