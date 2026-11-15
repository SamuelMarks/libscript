# keycloak

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `keycloak` component (part
of `_security`) within the LibScript ecosystem. Open-source Identity and Access Management server
supporting OpenID Connect, OAuth 2.0, and SAML 2.0.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **Keycloak**. It is designed
to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install keycloak
libscript uninstall keycloak
```

**Start / Stop (if configured as a background service):**

```sh
libscript start keycloak
libscript stop keycloak
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker keycloak
```

_Note: On Unix environments, you can also use `./cli.sh install keycloak`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                  | Description                                                                                                                                       | Default            | Aliases/Examples |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `KEYCLOAK_INSTALL_METHOD` | How to install keycloak. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `KEYCLOAK_VERSION`        | Specific version of keycloak to install.                                                                                                          | `latest`           | latest, lts      |
| `KEYCLOAK_DOWNLOAD_URL`   | Override URL for downloading keycloak binary or archive artifacts.                                                                                | `none`             |                  |
| `KEYCLOAK_RELEASES_URL`   | Override URL for querying keycloak available remote releases.                                                                                     | `none`             |                  |
| `KEYCLOAK_LISTEN_PORT`    | TCP port on which the keycloak service listens.                                                                                                   | `8080`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic and native version manager operations.
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
