FreeBSD 14 vagrant image
========================

## Usage

    vagrant up

## Libscript usage

Then you can use it like any other ssh host, e.g., to install PostgreSQL:

    vagrant ssh <<< '"${LIBSCRIPT_ROOT_DIR}"/_lib/_storage/postgres/setup.sh'

### Test

…and to test PostgreSQL:

    vagrant ssh <<< '. "${LIBSCRIPT_ROOT_DIR}"/env.sh && "${LIBSCRIPT_ROOT_DIR}"/_lib/_storage/postgres/test.sh'

### FreeBSD specific notes

For some reason the -c syntax doesn't work so you have to use `<<<` which limits what host shell you are using.

Also, you need to manually copy files over as the vagrant/hypervisor folder sync feature doesn't work.
For example—assuming you've exported `vagrant ssh-config` and named it `freebsd_14`—run:

    rsync -avz --exclude='**/.vagrant' /path/to/libscript freebsd_14:/opt/repos/



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
