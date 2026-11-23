# ShellCheck (`_lib/toolchains/shellcheck/`)

## Overview

A static analysis tool and linter for POSIX sh and shell scripts.

- **Tier**: `T1` (`_lib/toolchains/shellcheck/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `shellcheck`, `shell-linter`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/shellcheck/<version>)
./libscript.sh ls-remote shellcheck
./libscript.sh install shellcheck latest
./libscript.sh use shellcheck latest
./libscript.sh which shellcheck
./_lib/toolchains/shellcheck/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote shellcheck
.\libscript.cmd install shellcheck latest
.\libscript.cmd use shellcheck latest
.\libscript.cmd which shellcheck
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/shellcheck/<version>`
  (default `~/.libscript/shellcheck/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `SHELLCHECK_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

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

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
