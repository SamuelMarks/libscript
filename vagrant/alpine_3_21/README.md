alpine 3.21 vagrant image
=========================

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `alpine_3_21` component (part of `vagrant`) within the LibScript ecosystem. LibScript is a modular, zero-dependency shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

**Current State**: LibScript functions as a comprehensive global and per-component package manager, featuring a robust core CLI (`libscript.sh`, `libscript.cmd`, `libscript.bat`). It includes multi-platform toolchain support (Rust, Python, Node, Go, Java, C/C++), servers (Postgres, Nginx, Valkey), and advanced environment querying (`env` subcommand). It natively supports generating deployment configurations (`package_as docker`, `package_as docker_compose`, `package_as msi`, `package_as innosetup`, `package_as nsis`, `package_as TUI`) with deep installer customization, automated parallel dependency downloading and resolution via `libscript.json`, and robust uninstall lifecycle hooks (`uninstall.sh`/`uninstall.cmd`) for cleanly removing binaries, configs, and services. It natively handles deep semantic versioning, global `--secrets` extraction, caching, OpenBao/Vault generation, local caching via SQLite (`db-search`, `update-db`), explicit error handling for unsupported actions, and background process serving. Ongoing development targets extended registry integrations and dynamic web server routing.

## Build .box file

    $ cd /some_dir
    $ git clone --depth=1 --branch='3.21' --single-branch https://github.com/SamuelMarks/alpine-packer
    $ cd alpine-packer
    $ packer build -var-file=alpine-standard/alpine-standard-3.21.3-aarch64.pkrvars.hcl vmware-iso-aarch64.pkr.hcl
    $ vagrant box add alpine-standard-3.21.3 --provider vmware_fusion file:////some_dir/alpine-packer/output-alpine-standard-3.21.3-aarch64.box

## Usage

`cd` to same folder as this `README.md`, then run:

    $ vagrant up

## Copy files over (shared folders aren't working)

    $ vagrant ssh-config > ssh_config
    $ rsync -avH -e "ssh -F ./ssh_config" default:/opt/repos/libscript ../../gen

## Libscript usage

Then you can use it like any other ssh host, e.g., to install PostgreSQL:

    $ vagrant ssh -c '"${LIBSCRIPT_ROOT_DIR}"/_lib/_storage/postgres/setup.sh'

### Test

…and to test PostgreSQL:

    $ vagrant ssh -c '. "${LIBSCRIPT_ROOT_DIR}"/env.sh && "${LIBSCRIPT_ROOT_DIR}"/_lib/_storage/postgres/test.sh'



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

The Python toolchain (`_lib/_toolchain/python`) is extensively integrated with this feature and supports the following `PYTHON_INSTALL_METHOD` values:
- `uv` (default fallback): Installs Python and creates virtual environments using astral's `uv` tool.
- `pyenv`: Installs Python versions using `pyenv`, managing them in `~/.pyenv`.
- `system`: Uses the system's package manager to provide Python.
- `from-source`: Compiles Python directly from its source code.

By combining global methods with local overrides, you can mix and match system-provided stable packages with newer or custom-compiled toolchains as needed.
