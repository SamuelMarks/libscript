# Ansible Galaxy

**Tier**: `T1` (`_lib/package-managers/ansible-galaxy/`) | **Capabilities**: `userland-package`

Bootstrap module for the `ansible-galaxy` package manager.

## Usage

Ensures the `ansible-galaxy` executable is available. This relies on the core language toolchain
appropriate for the tool.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                        | Description                                                                                                                                                      | Default            | Aliases/Examples |
| ------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `ANSIBLE_GALAXY_VERSION`        | Specific version of ansible-galaxy to install.                                                                                                                   | `latest`           |                  |
| `ANSIBLE_GALAXY_INSTALL_METHOD` | Installation strategy for ansible-galaxy: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `ANSIBLE_GALAXY_DOWNLOAD_URL`   | Override URL for downloading ansible-galaxy binary or archive artifacts.                                                                                         | `none`             |                  |
| `ANSIBLE_GALAXY_RELEASES_URL`   | Override URL for querying ansible-galaxy available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
