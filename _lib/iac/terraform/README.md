# HashiCorp Terraform (`_lib/iac/terraform/`)

## Overview

HashiCorp Terraform declarative Infrastructure-as-Code CLI for provisioning and managing cloud and
on-prem resources.

- **Tier**: `T1` (`_lib/iac/terraform/`)
- **Capabilities**: `userland-package`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/terraform/<version>)
./libscript.sh ls-remote terraform
./libscript.sh install terraform latest
./libscript.sh use terraform latest
./libscript.sh which terraform
./_lib/iac/terraform/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote terraform
.\libscript.cmd install terraform latest
.\libscript.cmd use terraform latest
.\libscript.cmd which terraform
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/terraform/<version>`
  (default `~/.libscript/terraform/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `TERRAFORM_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                   | Description                                                                                                                                        | Default            | Aliases/Examples |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `TERRAFORM_INSTALL_METHOD` | How to install terraform. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `TERRAFORM_VERSION`        | Specific version of terraform to install.                                                                                                          | `latest`           | latest, stable   |
| `TERRAFORM_DOWNLOAD_URL`   | Override URL for downloading terraform binary or archive artifacts.                                                                                | `none`             |                  |
| `TERRAFORM_RELEASES_URL`   | Override URL for querying terraform available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
