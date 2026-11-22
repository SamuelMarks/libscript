# Jupyterhub

## Usage

This document describes the `JupyterHub` component located in the `third_party` folder within the
LibScript ecosystem. It provides the installation and configuration scripts required to provision
JupyterHub.

It works both as a local version manager (similar to rvm, nvm, pyenv, uv) and can be invoked from
the global version manager `libscript`. Furthermore, JupyterHub can be used by libscript to build
bigger stacks (like WordPress, Open edX, nextcloud, etc.) when combined with databases and web
servers.

You can manage JupyterHub using the global `libscript` CLI or the local scripts.

- **Install:** `libscript install jupyterhub`
- **Uninstall:** `libscript uninstall jupyterhub`
- **Start:** `libscript start jupyterhub`
- **Stop:** `libscript stop jupyterhub`
- **Package:** `libscript package-as docker jupyterhub` (or `msi`, `docker_compose`, etc.)

**Unix (Linux/macOS) Local Invocation:**

```sh
./cli.sh install jupyterhub
```

**Windows Local Invocation:**

```cmd
cli.cmd install jupyterhub
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                   | Description                                                                           | Default | Aliases/Examples |
| -------------------------- | ------------------------------------------------------------------------------------- | ------- | ---------------- |
| `JUPYTERHUB_SERVICE_USER`  | System user account running the JupyterHub daemon (created if nonexistent).           | `none`  |                  |
| `JUPYTERHUB_SERVICE_GROUP` | Primary system group assigned to the JupyterHub daemon user.                          | `none`  |                  |
| `JUPYTERHUB_IP`            | Bind IP address on which JupyterHub listens for incoming HTTP connections.            | `none`  |                  |
| `JUPYTERHUB_PORT`          | TCP port on which JupyterHub listens for incoming HTTP connections.                   | `none`  |                  |
| `JUPYTERHUB_NOTEBOOK_DIR`  | Default working directory for spawned user notebook servers (created if nonexistent). | `none`  |                  |
| `JUPYTERHUB_VENV`          | Filesystem path to the isolated Python virtual environment hosting JupyterHub.        | `none`  |                  |
| `JUPYTERHUB_USERNAME`      | Initial administrative JupyterHub login username.                                     | `none`  |                  |
| `JUPYTERHUB_PASSWORD`      | Initial administrative password or salted Argon2 password hash for JupyterHub.        | `none`  |                  |
| `GROUP`                    | Fallback system group name used when creating the JupyterHub service account.         | `none`  |                  |
| `PYTHON_VERSION`           | Python interpreter version provisioned for the JupyterHub virtual environment.        | `none`  |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic using the package manager mapper.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning
  correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->

## Orchestrated Components

This stack orchestrates the following LibScript components:

- `_lib/languages/python`: Python runtime and Jupyter kernel environment
- `_lib/languages/nodejs`: Node.js runtime for configurable HTTP proxy (`configurable-http-proxy`)
- `_lib/web-servers/nginx` (or `caddy`, `httpd`): Reverse proxy for notebook routing
