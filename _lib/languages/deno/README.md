# Deno

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `deno` component (part of
`_toolchain`) within the LibScript ecosystem. LibScript is a modular, zero-dependency shell-script
framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

## Usage

This directory contains the installation and configuration scripts for **Deno**, a modern, secure,
and fast runtime for JavaScript and TypeScript built on V8 and Rust. It is designed to be executed
via the global `libscript.sh` router or directly via `cli.sh`.

Crucially, this component works both as a **local version manager** (similar to tools like `rvm`,
`nvm`, `pyenv`, or `uv`), allowing you to isolate and manage specific versions of Deno per project,
and it can be seamlessly invoked from the **global version manager**, `libscript`.

Furthermore, Deno can be utilized by LibScript as a foundational dependency to **build bigger,
complex application stacks** (such as WordPress, Open edX, Nextcloud, and more).

### Lifecycle & Usage

You can easily install, uninstall, start, stop, and package Deno directly using LibScript:

**Install / Uninstall:**

```sh
libscript install deno
libscript uninstall deno
```

**Start / Stop (if configured as a background service):**

```sh
libscript start deno
libscript stop deno
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker deno
```

_Note: On Unix environments, you can also use `./cli.sh install deno`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                                          | Default            | Aliases/Examples |
| --------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `DENO_INSTALL_METHOD` | How to install DENO. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `DENO_VERSION`        | Version of Deno Runtime to install                                                                                                                                   | `latest`           |                  |
| `DENO_DOWNLOAD_URL`   | Override URL for downloading deno binary or archive artifacts.                                                                                                       | `none`             |                  |
| `DENO_RELEASES_URL`   | Override URL for querying deno available remote releases.                                                                                                            | `none`             |                  |

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
