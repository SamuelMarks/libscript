# Jupyterhub (Third-Party Application)

jupyterhub third-party vars that can be set

## Overview

This directory contains the installation and configuration scripts for `jupyterhub`. It is designed to be executed via the global `libscript.sh` router or directly via `cli.sh`.

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
| `JUPYTERHUB_SERVICE_USER` | Username to use for the install + daemon serve (creates user if nonexistent) | `none` | `` |
| `JUPYTERHUB_IP` | IP address to server from | `none` | `` |
| `JUPYTERHUB_PORT` | IP port to server from | `none` | `` |
| `JUPYTERHUB_NOTEBOOK_DIR` | Notebook directory (creates if nonexistent) | `none` | `` |
| `JUPYTERHUB_VENV` | Python virtualenv to use (creates if nonexistent) | `none` | `` |
| `JUPYTERHUB_PASSWORD` | Preferably (hashed+salted argon2) password to use | `none` | `` |


## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic using the package manager mapper.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.

