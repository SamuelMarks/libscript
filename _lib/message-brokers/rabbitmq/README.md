RabbitMQ
========

## Purpose & Current State
**Purpose**: This document provides context and technical details for the `rabbitmq` component (part of `_storage`) within the LibScript ecosystem. LibScript is a modular, zero-dependency shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

## Usage
This directory contains the installation, configuration, and lifecycle management scripts for **RabbitMQ**. 

Crucially, this component works both as a **local version manager** (similar to tools like `rvm`, `nvm`, `pyenv`, or `uv`) for managing isolated instances of RabbitMQ, and it can be invoked seamlessly from the **global version manager**, `libscript`. 

Furthermore, `libscript` can utilize this RabbitMQ component as a foundational building block to provision and build **bigger stacks** (such as WordPress, Open edX, Nextcloud, and more).

## Usage
You can install, start, stop, package, and uninstall rabbitmq using the global `libscript` command or the local CLI.

**Unix (Linux/macOS):**
```sh

libscript install rabbitmq 

libscript start rabbitmq
libscript stop rabbitmq

libscript package_as docker rabbitmq

libscript uninstall rabbitmq
```

**Windows:**
```cmd
:: Install
libscript.cmd install rabbitmq 

:: Start and Stop
libscript.cmd start rabbitmq
libscript.cmd stop rabbitmq

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi rabbitmq

:: Uninstall
libscript.cmd uninstall rabbitmq
```

*Alternatively, you can execute these locally from within this directory using `./cli.sh install rabbitmq` or `cli.cmd install rabbitmq`.*

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
