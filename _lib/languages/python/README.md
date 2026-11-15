# Python

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `python` component (part
of `_toolchain`) within the LibScript ecosystem. Python is a high-level, interpreted programming
language known for its readability, dynamic typing, and comprehensive standard library, widely used
in web development, data science, and scripting. LibScript is a modular, zero-dependency
shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS,
and Windows.

## Usage

This directory contains the installation and configuration scripts for `python`. It works both as a
local version manager (similar to rvm, nvm, pyenv, uv) for Python and can be invoked from the global
version manager `libscript`. Furthermore, it can be used by libscript as a building block to
assemble bigger stacks (like WordPress, Open edX, Nextcloud, etc.).

You can install, start, stop, package, and uninstall python using the global `libscript` command or
the local CLI.

**Unix (Linux/macOS):**

```sh

./libscript.sh install python

./cli.sh install python

./libscript.sh start python
./cli.sh start python

./libscript.sh stop python
./cli.sh stop python

./libscript.sh package-as docker python
./cli.sh package-as docker python

./libscript.sh uninstall python
./cli.sh uninstall python
```

**Windows:**

```cmd
:: Global Orchestrator
libscript.cmd install python

:: Local CLI
cli.cmd install python

:: Start and Stop
libscript.cmd start python
cli.cmd start python

libscript.cmd stop python
cli.cmd stop python

:: Package (e.g., as MSI installer)
libscript.cmd package-as msi python
cli.cmd package-as msi python

:: Uninstall
libscript.cmd uninstall python
cli.cmd uninstall python
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                        | Description                                                                                                                                                                                                                                                         | Default            | Aliases/Examples |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `LIBSCRIPT_BUILD_TOOLCHAIN`     | Toolchain selector used when building components from source ('default' uses the platform default C/C++ compiler via _lib/languages/c, whereas 'gcc', 'clang', 'tcc', 'custom-cc', or an explicit binary path compiles the component with that specific toolchain). | `default`          |                  |
| `LIBSCRIPT_CUSTOM_CC_BIN`       | Optional filesystem path to a custom C compiler binary when LIBSCRIPT_BUILD_TOOLCHAIN='custom-cc'.                                                                                                                                                                  | `none`             |                  |
| `LIBSCRIPT_BUILD_CFLAGS`        | Extra CFLAGS passed to source builds for components compiling native C/C++ sources.                                                                                                                                                                                 | `none`             |                  |
| `LIBSCRIPT_BUILD_LDFLAGS`       | Extra LDFLAGS passed to source builds for components compiling native C/C++ sources.                                                                                                                                                                                | `none`             |                  |
| `LIBSCRIPT_SOURCE_WORKDIR`      | Working directory used for extracting and compiling source tarballs.                                                                                                                                                                                                | `none`             |                  |
| `LIBSCRIPT_HW_CORES`            | Detected or overridden CPU core count for auto-tuning services and parallel builds.                                                                                                                                                                                 | `none`             |                  |
| `LIBSCRIPT_HW_MEM_MB`           | Detected or overridden system memory in MiB for auto-tuning service buffer pools.                                                                                                                                                                                   | `none`             |                  |
| `LIBSCRIPT_HW_NVME`             | Detected or overridden NVMe storage presence flag for I/O scheduler and database tuning.                                                                                                                                                                            | `none`             |                  |
| `LIBSCRIPT_HW_SIMD`             | Detected or overridden CPU SIMD instruction set capabilities (e.g., avx2, avx512, neon).                                                                                                                                                                            | `none`             |                  |
| `PYTHON_VERSION`                | Version of Python demanded. Can be a specific numeric version number or an alias                                                                                                                                                                                    | `3.11`             | latest, cpython  |
| `PYTHON_VENV`                   | Path to a Python virtualenv (will create if nonexistent)                                                                                                                                                                                                            | `none`             |                  |
| `PYTHON_CUSTOM_EXECUTABLE_PATH` | Path to existing host python3.exe executable. If specified, skips downloading or bootstrapping a new Python runtime.                                                                                                                                                | `none`             |                  |
| `PYTHON_USE_SYSTEM`             | Reuse host or existing Python runtime located at PYTHON_CUSTOM_EXECUTABLE_PATH rather than installing bundled Python.                                                                                                                                               | `none`             |                  |
| `PYTHON_INSTALL_METHOD`         | How to install PYTHON. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools.                                                                                              | `libscript_native` |                  |
| `PIP_FIND_LINKS`                | Directory or URL containing pre-downloaded Python wheels for offline installation.                                                                                                                                                                                  | `none`             |                  |
| `PIP_NO_INDEX`                  | When set to 1 or true, pip completely disables querying remote PyPI indexes.                                                                                                                                                                                        | `0`                |                  |
| `PIP_WHEEL_DIR`                 | Directory location of pre-downloaded .whl packages for offline pip installs.                                                                                                                                                                                        | `none`             |                  |
| `PYTHON_DOWNLOAD_URL`           | Override URL for downloading python binary or archive artifacts.                                                                                                                                                                                                    | `none`             |                  |
| `PYTHON_RELEASES_URL`           | Override URL for querying python available remote releases.                                                                                                                                                                                                         | `none`             |                  |
| `LIBSCRIPT_FORCE_PYTHONHOME`    | When set to 1, exports PYTHONHOME to the base LibScript Python installation directory if no virtualenv is active.                                                                                                                                                   | `0`                |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic using the package manager mapper.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning
  correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.

## Variables

See `vars.schema.json` for details on available variables.

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
