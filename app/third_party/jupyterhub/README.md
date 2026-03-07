# JupyterHub (Third-Party Application)

## Overview
This document describes the `JupyterHub` component located in the `third_party` folder within the LibScript ecosystem. It provides the installation and configuration scripts required to provision JupyterHub.

It works both as a local version manager (similar to rvm, nvm, pyenv, uv) and can be invoked from the global version manager `libscript`. Furthermore, JupyterHub can be used by libscript to build bigger stacks (like WordPress, Open edX, nextcloud, etc.) when combined with databases and web servers.

## LibScript Operations
You can manage JupyterHub using the global `libscript` CLI or the local scripts.

- **Install:** `libscript install jupyterhub`
- **Uninstall:** `libscript uninstall jupyterhub`
- **Start:** `libscript start jupyterhub`
- **Stop:** `libscript stop jupyterhub`
- **Package:** `libscript package_as docker jupyterhub` (or `msi`, `docker_compose`, etc.)

**Unix (Linux/macOS) Local Invocation:**
```sh
./cli.sh <COMMAND> jupyterhub [VERSION] [OPTIONS]
```

**Windows Local Invocation:**
```cmd
cli.cmd <COMMAND> jupyterhub [VERSION] [OPTIONS]
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

## Variables

See `vars.schema.json` for details on available variables.
