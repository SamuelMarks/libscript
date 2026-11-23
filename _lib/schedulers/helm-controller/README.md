# Helm Controller Operator (`_lib/schedulers/helm-controller/`)

## Overview

Kubernetes HelmChart custom resource operator (helm-controller) for declarative Helm release
lifecycle management.

- **Tier**: `T1` (`_lib/schedulers/helm-controller/`)
- **Capabilities**: `userland-package`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/helm-controller/<version>)
./libscript.sh ls-remote helm-controller
./libscript.sh install helm-controller latest
./libscript.sh use helm-controller latest
./libscript.sh which helm-controller
./_lib/schedulers/helm-controller/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote helm-controller
.\libscript.cmd install helm-controller latest
.\libscript.cmd use helm-controller latest
.\libscript.cmd which helm-controller
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under
  `${LIBSCRIPT_HOME}/helm-controller/<version>` (default `~/.libscript/helm-controller/<version>`)
  and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `HELM_CONTROLLER_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                         | Description                                                                                                                                              | Default            | Aliases/Examples |
| -------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `HELM_CONTROLLER_INSTALL_METHOD` | How to install helm-controller. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `HELM_CONTROLLER_VERSION`        | Specific version of helm-controller to install.                                                                                                          | `latest`           | latest, stable   |
| `HELM_CONTROLLER_DOWNLOAD_URL`   | Override URL for downloading helm-controller binary or archive artifacts.                                                                                | `none`             |                  |
| `HELM_CONTROLLER_RELEASES_URL`   | Override URL for querying helm-controller available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
