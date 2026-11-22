# shellcheck

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `shellcheck` component
(part of `_toolchains`) within the LibScript ecosystem. A static analysis tool and linter for POSIX
sh and shell scripts.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **ShellCheck**. It is
designed to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install shellcheck
libscript uninstall shellcheck
```

**Start / Stop (if configured as a background service):**

```sh
libscript start shellcheck
libscript stop shellcheck
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker shellcheck
```

_Note: On Unix environments, you can also use `./cli.sh install shellcheck`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                     | Description                                                                                                                                         | Default                                                     | Aliases/Examples               |
| ---------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------- | ------------------------------ |
| `SHELLCHECK_INSTALL_METHOD`  | How to install ShellCheck. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native`                                          |                                |
| `SHELLCHECK_VERSION`         | Specific version or alias of ShellCheck to install.                                                                                                 | `latest`                                                    | latest, stable, 0.11.0, 0.10.0 |
| `SHELLCHECK_DOWNLOAD_URL`    | Override URL for downloading ShellCheck binary or archive artifacts.                                                                                | `none`                                                      |                                |
| `SHELLCHECK_RELEASES_URL`    | Override URL for querying available remote ShellCheck releases.                                                                                     | `https://api.github.com/repos/koalaman/shellcheck/releases` |                                |
| `SHELLCHECK_GIT_REPO`        | Upstream Git repository URL for ShellCheck tag resolution and source builds.                                                                        | `https://github.com/koalaman/shellcheck.git`                |                                |
| `SHELLCHECK_FORMAT`          | Default output format passed to ShellCheck when invoked in lint helpers (tty, gcc, checkstyle, diff, json1, quiet).                                 | `tty`                                                       |                                |
| `SHELLCHECK_SHELL`           | Default target shell dialect enforced by ShellCheck (sh, dash, ash, bash, ksh).                                                                     | `sh`                                                        |                                |
| `SHELLCHECK_OPTIONAL_CHECKS` | Comma-separated optional ShellCheck checks enabled via -o when supported.                                                                           | `useless-use-of-cat`                                        |                                |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
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
