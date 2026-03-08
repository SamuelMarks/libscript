Alpine 3.21 Vagrant Image
=========================

## Overview

**Purpose**: This document describes the `alpine_3_21` Vagrant folder and environment within the LibScript ecosystem. LibScript is a modular, zero-dependency shell-script framework designed for cross-platform software provisioning.

**Capabilities**: 
- It works both as a local version manager (similar to rvm, nvm, pyenv, uv) and can be invoked from the global version manager `libscript`.
- It can be used by libscript to build bigger stacks (like WordPress, Open edX, nextcloud, etc.).

**Current State**: LibScript functions as a comprehensive global and per-component package manager. It supports deep installer customization, automated parallel dependency downloading, and robust lifecycle hooks for cleanly managing environments.

## Lifecycle Management with Libscript

You can natively manage this Vagrant environment using `libscript`:

- **Install**: `libscript install vagrant/alpine_3_21`
- **Start**: `libscript start vagrant/alpine_3_21`
- **Stop**: `libscript stop vagrant/alpine_3_21`
- **Uninstall**: `libscript uninstall vagrant/alpine_3_21`
- **Package**: `libscript package vagrant/alpine_3_21`

## Build .box File

    $ cd /some_dir
    $ git clone --depth=1 --branch='3.21' --single-branch https://github.com/SamuelMarks/alpine-packer
    $ cd alpine-packer
    $ packer build -var-file=alpine-standard/alpine-standard-3.21.3-aarch64.pkrvars.hcl vmware-iso-aarch64.pkr.hcl
    $ vagrant box add alpine-standard-3.21.3 --provider vmware_fusion file:////some_dir/alpine-packer/output-alpine-standard-3.21.3-aarch64.box

## Vagrant Usage

`cd` to same folder as this `README.md`, then run:

    $ vagrant up

## Copy Files Over (Shared Folders Aren't Working)

    $ vagrant ssh-config > ssh_config
    $ rsync -avH -e "ssh -F ./ssh_config" default:/opt/repos/libscript ../../gen

## Libscript Usage over SSH

Then you can use it like any other SSH host, e.g., to install PostgreSQL:

    $ vagrant ssh -c '"${LIBSCRIPT_ROOT_DIR}"/_lib/databases/postgres/setup.sh'

### Test

…and to test PostgreSQL:

    $ vagrant ssh -c '. "${LIBSCRIPT_ROOT_DIR}"/env.sh && "${LIBSCRIPT_ROOT_DIR}"/_lib/databases/postgres/test.sh'

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

You can override the global setting for specific dependencies by setting their respective `[TOOL]_INSTALL_METHOD` variable. The local override takes highest precedence. 

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
