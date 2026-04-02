Debian12 Multi
==============

## Purpose & Current State
**Purpose**: This document provides context and technical details for the `debian12_multi` component (part of `vagrant`) within the LibScript ecosystem. LibScript is a modular, zero-dependency shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

## Usage & Libscript Integration
This document describes the **Debian 12 Multi Vagrant** environment. It serves as a reliable, reproducible virtual machine designed to test and run libscript components.

Crucially, within this Vagrant environment (and across the libscript ecosystem), `libscript` works both as a **local version manager** (similar to tools like `rvm`, `nvm`, `pyenv`, or `uv`) for managing isolated instances of software, and as a **global version manager** that orchestrates entire environments. 

By leveraging this Debian 12 Vagrant box, `libscript` can reliably provision and build **bigger stacks** (such as WordPress, Open edX, Nextcloud, and more) inside a clean, reproducible OS target.

## Usage
You can spin up the environment and utilize `libscript` to install, uninstall, start, stop, and package various components directly inside the VM.

### 1. Start the Environment
```sh
vagrant up
```

### 2. Managing Software with Libscript (Install, Start, Stop, Package, Uninstall)

Once the VM is running, you can use it like any other SSH host. The global `libscript` command allows you to manage software lifecycles inside the Debian environment:

```sh

vagrant ssh -c 'libscript install postgres '

vagrant ssh -c 'libscript start postgres'
vagrant ssh -c 'libscript stop postgres'

vagrant ssh -c 'libscript package_as docker postgres'

vagrant ssh -c 'libscript uninstall postgres'
```

*(Note: If the global `libscript` is not in your PATH inside the VM, you can invoke the scripts via absolute paths, e.g., `"${LIBSCRIPT_ROOT_DIR}"/_lib/databases/postgres/setup.sh`)*

### 3. Test Components

You can test installed components by sourcing the environment and running the dedicated test script:

```sh
vagrant ssh -c '. "${LIBSCRIPT_ROOT_DIR}"/env.sh && "${LIBSCRIPT_ROOT_DIR}"/_lib/databases/postgres/test.sh'
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

You can override the global setting for specific dependencies by setting their respective `DEBIAN12_MULTI_INSTALL_METHOD` variable. The local override takes highest precedence. 

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

## Platform Support
- Linux
- macOS
- Windows
