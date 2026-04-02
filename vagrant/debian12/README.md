Debian12
========

## Usage
**Purpose**: This document describes the `debian12` Vagrant folder and environment within the LibScript ecosystem. LibScript is a modular, zero-dependency shell-script framework designed for cross-platform software provisioning. 

**Capabilities**: 
- It works both as a local version manager (similar to rvm, nvm, pyenv, uv) and can be invoked from the global version manager `libscript`.
- It can be used by libscript to build bigger stacks (like WordPress, Open edX, nextcloud, etc.).

## Usage
You can natively manage this Vagrant environment using `libscript`:

- **Install**: `libscript install vagrant/debian12`
- **Start**: `libscript start vagrant/debian12`
- **Stop**: `libscript stop vagrant/debian12`
- **Uninstall**: `libscript uninstall vagrant/debian12`
- **Package**: `libscript package vagrant/debian12`

## Vagrant Usage
You can also start it directly via Vagrant:

 vagrant up

## Libscript Usage over SSH
Then you can use it like any other SSH host, e.g., to install PostgreSQL:

 vagrant ssh -c '"${LIBSCRIPT_ROOT_DIR}"/_lib/databases/postgres/setup.sh'

### Test

…and to test PostgreSQL:

 vagrant ssh -c '. "${LIBSCRIPT_ROOT_DIR}"/env.sh && "${LIBSCRIPT_ROOT_DIR}"/_lib/databases/postgres/test.sh'

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

You can override the global setting for specific dependencies by setting their respective `DEBIAN12_INSTALL_METHOD` variable. The local override takes highest precedence. 

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
