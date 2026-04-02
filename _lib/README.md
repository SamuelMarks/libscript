Lib
===

## Purpose & Current State
**Purpose**: This document provides context and technical details for the `_lib` directory within the LibScript ecosystem. This directory is the central repository for all supported components, toolchains, servers, and services that LibScript can manage. It contains the modular definitions required to provision and configure software dynamically.

## Usage
The `_lib` ecosystem is designed so that each included module acts both as a standalone local version manager (similar to `rvm`, `nvm`, `pyenv`, or `uv`), allowing isolated installations, and can be centrally invoked and orchestrated via the global version manager `libscript`.

Most importantly, the components within `_lib` are the building blocks that can be used by LibScript to seamlessly provision and build bigger, complex stacks (such as WordPress, Open edX, Nextcloud, etc.).

## Usage
You can install, start, stop, package, and uninstall _lib using the global `libscript` command or the local CLI.

**Unix (Linux/macOS):**
```sh

./libscript.sh install _lib

./cli.sh install _lib

./libscript.sh start _lib
./cli.sh start _lib

./libscript.sh stop _lib
./cli.sh stop _lib

./libscript.sh package_as docker _lib
./cli.sh package_as docker _lib

./libscript.sh uninstall _lib
./cli.sh uninstall _lib
```

**Windows:**
```cmd
:: Global Orchestrator
libscript.cmd install _lib

:: Local CLI
cli.cmd install _lib

:: Start and Stop
libscript.cmd start _lib
cli.cmd start _lib

libscript.cmd stop _lib
cli.cmd stop _lib

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi _lib
cli.cmd package_as msi _lib

:: Uninstall
libscript.cmd uninstall _lib
cli.cmd uninstall _lib
```

## Dependency Installation Methods
`libscript` provides a flexible dependency management system, allowing you to control how dependencies are installed—either globally across the entire setup or locally on a per-toolchain basis.

### Global Configuration

You can set a global preference for how tools should be installed by defining `LIBSCRIPT_GLOBAL_INSTALL_METHOD` in your environment or global configuration (`install.json`).

Supported global methods typically include:
- `system`: Uses the system's package manager (e.g., `apt`, `apk`, `pacman`).
- `source`: Builds or downloads the tool from source/official binaries (fallback behavior depends on the tool).

Example:
```sh
export LIBSCRIPT_GLOBAL_INSTALL_METHOD="system"
```

### Local Overrides

You can override the global setting for specific dependencies by setting their respective `_LIB_INSTALL_METHOD` variable. The local override takes highest precedence. 

For example, to globally use the system package manager but strictly install Python via `uv`:
```sh
export LIBSCRIPT_GLOBAL_INSTALL_METHOD="system"
export PYTHON_INSTALL_METHOD="uv"
```

### Python-Specific Support

The Python toolchain (`_lib/languages/python`) is extensively integrated with this feature and supports the following `PYTHON_INSTALL_METHOD` values:
- `uv` (default fallback): Installs Python and creates virtual environments using astral's `uv` tool.
- `pyenv`: Installs Python versions using `pyenv`, managing them in `~/.pyenv`.
- `system`: Uses the system's package manager to provide Python.
- `from-source`: Compiles Python directly from its source code.

By combining global methods with local overrides, you can mix and match system-provided stable packages with newer or custom-compiled toolchains as needed.

## Cloud Provisioning
LibScript includes a unified multicloud wrapper (`cloud`) and official provider-specific CLIs (`aws`, `azure`, `gcp`) to manage infrastructure resources across platforms.

### Supported Resources

- **Network**: VPCs, VNETs, Subnets
- **Firewall**: Security Groups, NSGs, Firewall Rules
- **Node**: EC2 instances, Azure VMs, GCE instances
- **IP**: Elastic IPs, Public IPs, Static IPs
- **DNS**: Route53, Azure DNS, Cloud DNS
- **Storage**: S3 buckets, Azure Storage Accounts, GCS buckets

### Example Usage

```sh
./libscript.sh cloud aws network create my-vpc
./libscript.sh cloud gcp storage list
./libscript.sh cloud azure node delete my-vm
```

## Platform Support
- Linux
- macOS
- Windows
