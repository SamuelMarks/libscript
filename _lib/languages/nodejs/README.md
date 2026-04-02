Node.js
=======

## Purpose & Current State
**Purpose**: This document provides context and technical details for the `nodejs` component (part of `_toolchain`) within the LibScript ecosystem. LibScript is a modular, zero-dependency shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

## Usage
This directory contains the installation and configuration scripts for **Node.js**, a popular, open-source, cross-platform JavaScript runtime environment that executes JavaScript code outside of a web browser. It is designed to be executed via the global `libscript.sh` router or directly via `cli.sh`.

Crucially, this component works both as a **local version manager** (similar to tools like `rvm`, `nvm`, `pyenv`, or `uv`), allowing you to isolate and manage specific versions of Node.js per project, and it can be seamlessly invoked from the **global version manager**, `libscript`.

Furthermore, Node.js can be utilized by LibScript as a foundational dependency to **build bigger, complex application stacks** (such as WordPress, Open edX, Nextcloud, and more).

### Lifecycle & Usage

You can easily install, uninstall, start, stop, and package Node.js directly using LibScript:

**Install / Uninstall:**
```sh
libscript install nodejs 
libscript uninstall nodejs
```

**Start / Stop (if configured as a background service):**
```sh
libscript start nodejs
libscript stop nodejs
```

**Package (e.g., as a Docker container):**
```sh
libscript package_as docker nodejs
```

*Note: On Unix environments, you can also use `./cli.sh install nodejs `. On Windows, use `libscript.cmd` or `cli.cmd`.*

## Configuration Options
The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before running the setup script.

| Variable | Description | Default | Aliases |
|----------|-------------|---------|---------|
| `NODEJS_VERSION` | Version of Node.js demanded. Can be an alias or a specific numeric version number | `lts` | `lts, latest` |
| `LIBSCRIPT_GLOBAL_INSTALL_METHOD` | Global override for how software should be installed across all systems (e.g. system package manager vs downloaded binaries/from-source). | `system` | `` |
| `LIBSCRIPT_WINDOWS_PKG_MGR` | Global package manager override for Windows targets (e.g. winget, choco). | `winget` | `` |
| `NODEJS_INSTALL_METHOD` | How to install NODEJS. 'system' uses the native OS package manager, 'source' compiles/downloads binaries. | `system` | `` |

## Architecture
- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic using the package manager mapper.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.

## Variables
See `vars.schema.json` for details on available variables.

## Platform Support
- Linux
- macOS
- Windows
