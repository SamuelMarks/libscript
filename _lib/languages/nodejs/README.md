# Node.js

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `nodejs` component (part
of `_toolchain`) within the LibScript ecosystem. LibScript is a modular, zero-dependency
shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS,
and Windows.

## Usage

This directory contains the installation and configuration scripts for **Node.js**, a popular,
open-source, cross-platform JavaScript runtime environment that executes JavaScript code outside of
a web browser. It is designed to be executed via the global `libscript.sh` router or directly via
`cli.sh`.

Crucially, this component works both as a **local version manager** (similar to tools like `rvm`,
`nvm`, `pyenv`, or `uv`), allowing you to isolate and manage specific versions of Node.js per
project, and it can be seamlessly invoked from the **global version manager**, `libscript`.

Furthermore, Node.js can be utilized by LibScript as a foundational dependency to **build bigger,
complex application stacks** (such as WordPress, Open edX, Nextcloud, and more).

### Lifecycle & Usage

You can easily install, uninstall, start, stop, and package Node.js directly using LibScript:

**Install / Uninstall:**

```sh
libscript install nodejs
libscript uninstall nodejs
```

**Start / Stop (if configured as a background service):**

```sh
libscript start nodejs
libscript stop nodejs
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker nodejs
```

_Note: On Unix environments, you can also use `./cli.sh install nodejs`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                        | Description                                                                                                                           | Default            | Aliases/Examples                       |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | -------------------------------------- |
| `NODEJS_VERSION`                | Version of Node.js demanded. Can be an alias or a specific numeric version number                                                     | `lts`              | lts, latest, lts, latest, v22.13.1, 20 |
| `NODEJS_CUSTOM_EXECUTABLE_PATH` | Path to existing host node.exe executable. If provided, bypasses installing a new Node.js runtime.                                    | `none`             |                                        |
| `NODEJS_USE_SYSTEM`             | Reuse existing host Node.js runtime located at NODEJS_CUSTOM_EXECUTABLE_PATH rather than installing bundled Node.js.                  | `none`             |                                        |
| `NODEJS_INSTALL_METHOD`         | How to install NODEJS. 'libscript_native' uses isolated version dirs natively handled by libscript, 'system' uses OS package manager. | `libscript_native` |                                        |
| `NPM_CACHE`                     | Directory of pre-populated offline npm cache tarballs and metadata.                                                                   | `none`             |                                        |
| `YARN_OFFLINE_MIRROR`           | Directory of offline tarball mirror for yarn package installation.                                                                    | `none`             |                                        |
| `NODEJS_DOWNLOAD_URL`           | Override URL for downloading nodejs binary or archive artifacts.                                                                      | `none`             |                                        |
| `NODEJS_RELEASES_URL`           | Override URL for querying nodejs available remote releases.                                                                           | `none`             |                                        |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
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
