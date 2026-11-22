# Go

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `go` component (part of
`_toolchain`) within the LibScript ecosystem. LibScript is a modular, zero-dependency shell-script
framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

**What is Go?**: Go (or Golang) is an open-source, statically typed, compiled programming language
designed by Google to produce concurrent, garbage-collected, and highly scalable software.

## Usage

This directory contains the installation and configuration scripts for `go`.

### Local and Global Version Management

The `go` component works both as a **local version manager** (similar to tools like `rvm`, `nvm`,
`pyenv`, or `uv`) and can be seamlessly invoked from the global version manager via `libscript`.
This dual capability allows developers to manage specific versions per project locally or enforce
system-wide global configurations.

### Building Bigger Stacks

Beyond isolated provisioning, this component can be deeply integrated by `libscript` to build,
deploy, and manage larger stacks and complex applications. Whether you are scaffolding a CMS like
WordPress, a learning platform like Open edX, or a collaboration suite like Nextcloud, LibScript can
orchestrate `go` alongside databases, web servers, and other services to form a cohesive,
reproducible stack.

You can install, start, stop, package, and uninstall go using the global `libscript` command or the
local CLI.

**Unix (Linux/macOS):**

```sh

./libscript.sh install go

./cli.sh install go

./libscript.sh start go
./cli.sh start go

./libscript.sh stop go
./cli.sh stop go

./libscript.sh package-as docker go
./cli.sh package-as docker go

./libscript.sh uninstall go
./cli.sh uninstall go
```

**Windows:**

```cmd
:: Global Orchestrator
libscript.cmd install go

:: Local CLI
cli.cmd install go

:: Start and Stop
libscript.cmd start go
cli.cmd start go

libscript.cmd stop go
cli.cmd stop go

:: Package (e.g., as MSI installer)
libscript.cmd package-as msi go
cli.cmd package-as msi go

:: Uninstall
libscript.cmd uninstall go
cli.cmd uninstall go
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable            | Description                                                                                                                                                        | Default                           | Aliases/Examples |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------- | ---------------- |
| `GO_VERSION`        | Specific version of go to install. Can be a numeric version or an alias.                                                                                           | `latest`                          | latest, stable   |
| `GO_INSTALL_METHOD` | How to install GO. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native`                |                  |
| `GOPROXY`           | Go module proxy URL or 'off' to disable network module fetching.                                                                                                   | `https://proxy.golang.org,direct` |                  |
| `GO_VENDOR`         | Flag (0 or 1) indicating Go should build using local vendor directory (-mod=vendor).                                                                               | `0`                               |                  |
| `GO_DOWNLOAD_URL`   | Override URL for downloading go binary or archive artifacts.                                                                                                       | `none`                            |                  |
| `GO_RELEASES_URL`   | Override URL for querying go available remote releases.                                                                                                            | `none`                            |                  |

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
