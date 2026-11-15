# jq

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `jq` component (part of
`_toolchain`) within the LibScript ecolibscript_native. LibScript is a modular, zero-dependency
shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS,
and Windows.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **jq**, a lightweight,
flexible, and command-line JSON processor. It is akin to `sed` but specifically designed for parsing
and manipulating JSON data streams. It is designed to be executed via the global `libscript.sh`
router or directly via `cli.sh`.

Crucially, this component works both as a **local version manager** (similar to tools like `rvm`,
`nvm`, `pyenv`, or `uv`), allowing you to isolate and manage specific versions of jq per project,
and it can be seamlessly invoked from the **global version manager**, `libscript`.

Furthermore, jq can be utilized by LibScript as a foundational dependency to **build bigger, complex
application stacks** (such as WordPress, Open edX, Nextcloud, and more) that rely on dynamic JSON
configuration.

### Lifecycle & Usage

You can easily install, uninstall, start, stop, and package jq directly using LibScript:

**Install / Uninstall:**

```sh
libscript install jq
libscript uninstall jq
```

**Start / Stop (if configured as a background service):**

```sh
libscript start jq
libscript stop jq
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker jq
```

_Note: On Unix environments, you can also use `./cli.sh install jq`. On Windows, use `libscript.cmd`
or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable            | Description                                                                                                                                                        | Default  | Aliases/Examples |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------- | ---------------- |
| `JQ_INSTALL_METHOD` | How to install JQ. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `system` |                  |
| `JQ_VERSION`        | Specific version of jq to install.                                                                                                                                 | `latest` |                  |
| `JQ_DOWNLOAD_URL`   | Override URL for downloading jq binary or archive artifacts.                                                                                                       | `none`   |                  |
| `JQ_RELEASES_URL`   | Override URL for querying jq available remote releases.                                                                                                            | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic using the package manager mapper.
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
