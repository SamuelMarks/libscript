# _Noop (Core Library)

Core shared shell script library for _noop.

## Overview

This directory contains the installation and configuration scripts for `_noop`. It is designed to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Installation

**Unix (Linux/macOS):**
```sh
./cli.sh <COMMAND> <PACKAGE_NAME> [VERSION] [OPTIONS]
```

**Windows:**
```cmd
cli.cmd <COMMAND> <PACKAGE_NAME> [VERSION] [OPTIONS]
```



## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic using the package manager mapper.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.

