Ruby
====

## Purpose & Current State
**Purpose**: This document provides context and technical details for the `ruby` component (part of `_toolchain`) within the LibScript ecosystem. LibScript is a modular, zero-dependency shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

## Usage
This directory contains the installation and configuration scripts for **Ruby**, a dynamic, open-source programming language with a focus on simplicity and productivity, featuring an elegant syntax that is natural to read and easy to write. It is designed to be executed via the global `libscript.sh` router or directly via `cli.sh`.

Crucially, this component works both as a **local version manager** (similar to tools like `rvm`, `nvm`, `pyenv`, or `uv`), allowing you to isolate and manage specific versions of Ruby per project, and it can be seamlessly invoked from the **global version manager**, `libscript`.

Furthermore, Ruby can be utilized by LibScript as a foundational dependency to **build bigger, complex application stacks** (such as WordPress, Open edX, Nextcloud, and more).

### Lifecycle & Usage

You can easily install, uninstall, start, stop, and package Ruby directly using LibScript:

**Install / Uninstall:**
```sh
libscript install ruby 
libscript uninstall ruby
```

**Start / Stop (if configured as a background service):**
```sh
libscript start ruby
libscript stop ruby
```

**Package (e.g., as a Docker container):**
```sh
libscript package_as docker ruby
```

*Note: On Unix environments, you can also use `./cli.sh install ruby `. On Windows, use `libscript.cmd` or `cli.cmd`.*

## Configuration Options
The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before running the setup script.

| Variable | Description | Default | Aliases |
|----------|-------------|---------|---------|
| `RUBY_VERSION` | Specific version of ruby to install. Can be a numeric version or an alias. | `latest` | `latest, stable` |
| `LIBSCRIPT_GLOBAL_INSTALL_METHOD` | Global override for how software should be installed across all systems (e.g. system package manager vs downloaded binaries/from-source). | `system` | `` |
| `LIBSCRIPT_WINDOWS_PKG_MGR` | Global package manager override for Windows targets (e.g. winget, choco). | `winget` | `` |
| `RUBY_INSTALL_METHOD` | How to install RUBY. 'system' uses the native OS package manager, 'source' compiles/downloads binaries. | `system` | `` |

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
