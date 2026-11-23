# Ansible Automation Engine (`_lib/iac/ansible/`)

## Overview

Agentless IT automation, configuration management, and application deployment engine (ansible,
ansible-playbook, ansible-vault).

- **Tier**: `T1` (`_lib/iac/ansible/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `ansible`, `ansible-playbook`, `ansible-core`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/ansible/<version>)
./libscript.sh ls-remote ansible
./libscript.sh install ansible latest
./libscript.sh use ansible latest
./libscript.sh which ansible
./_lib/iac/ansible/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote ansible
.\libscript.cmd install ansible latest
.\libscript.cmd use ansible latest
.\libscript.cmd which ansible
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/ansible/<version>`
  (default `~/.libscript/ansible/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `ANSIBLE_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                                                                      | Default            | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `ANSIBLE_INSTALL_METHOD` | How to install ansible. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `ANSIBLE_VERSION`        | Specific version of ansible to install.                                                                                                          | `latest`           | latest, stable   |
| `ANSIBLE_DOWNLOAD_URL`   | Override URL for downloading ansible binary or archive artifacts.                                                                                | `none`             |                  |
| `ANSIBLE_RELEASES_URL`   | Override URL for querying ansible available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
