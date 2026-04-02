PHP
===

## Purpose & Current State
**Purpose**: This document provides context and technical details for the `php` component (part of `_toolchain`) within the LibScript ecosystem. LibScript is a modular, zero-dependency shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

**What is PHP?**: PHP (Hypertext Preprocessor) is a widely-used open-source general-purpose scripting language that is especially suited for web development and can be embedded into HTML.

## Usage
This directory contains the installation and configuration scripts for `php`. 

### Local and Global Version Management

The `php` component works both as a **local version manager** (similar to tools like `rvm`, `nvm`, `pyenv`, or `uv`) and can be seamlessly invoked from the global version manager via `libscript`. This dual capability allows developers to manage specific versions per project locally or enforce system-wide global configurations.

### Building Bigger Stacks

Beyond isolated provisioning, this component can be deeply integrated by `libscript` to build, deploy, and manage larger stacks and complex applications. Whether you are scaffolding a CMS like WordPress, a learning platform like Open edX, or a collaboration suite like Nextcloud, LibScript can orchestrate `php` alongside databases, web servers, and other services to form a cohesive, reproducible stack.

## Usage
You can install, start, stop, package, and uninstall php using the global `libscript` command or the local CLI.

**Unix (Linux/macOS):**
```sh

./libscript.sh install php

./cli.sh install php

./libscript.sh start php
./cli.sh start php

./libscript.sh stop php
./cli.sh stop php

./libscript.sh package_as docker php
./cli.sh package_as docker php

./libscript.sh uninstall php
./cli.sh uninstall php
```

**Windows:**
```cmd
:: Global Orchestrator
libscript.cmd install php

:: Local CLI
cli.cmd install php

:: Start and Stop
libscript.cmd start php
cli.cmd start php

libscript.cmd stop php
cli.cmd stop php

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi php
cli.cmd package_as msi php

:: Uninstall
libscript.cmd uninstall php
cli.cmd uninstall php
```

## Configuration Options
The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before running the setup script.

| Variable | Description | Default | Aliases |
|----------|-------------|---------|---------|
| `LIBSCRIPT_GLOBAL_INSTALL_METHOD` | Global override for how software should be installed across all systems (e.g. system package manager vs downloaded binaries/from-source). | `system` | `` |
| `LIBSCRIPT_WINDOWS_PKG_MGR` | Global package manager override for Windows targets (e.g. winget, choco). | `winget` | `` |
| `PHP_INSTALL_METHOD` | How to install PHP. 'system' uses the native OS package manager, 'source' compiles/downloads binaries. | `system` | `` |

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
