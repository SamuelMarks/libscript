# Firecrawl (Third-Party Application)

firecrawl third-party vars that can be set

## Overview

This directory contains the installation and configuration scripts for `firecrawl`. It is designed to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Installation

**Unix (Linux/macOS):**
```sh
./cli.sh <COMMAND> <PACKAGE_NAME> [VERSION] [OPTIONS]
```

**Windows:**
```cmd
cli.cmd <COMMAND> <PACKAGE_NAME> [VERSION] [OPTIONS]
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before running the setup script.

| Variable | Description | Default | Aliases |
|----------|-------------|---------|---------|
| `FIRECRAWL_BUILD_DIR` | Build dir | `none` | `` |
| `FIRECRAWL_DEST` | Dest to clone|pull firecrawl into | `none` | `` |
| `PYTHON_VENV` | Python virtualenv to install & then start the celery daemon from | `none` | `` |


## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic using the package manager mapper.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.

