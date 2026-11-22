# Java

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `java` component (part of
`_toolchain`) within the LibScript ecosystem. This component manages the installation of the Java
Development Kit (JDK) and runtime environment, providing the necessary tools to compile, run, and
manage Java-based applications.

Crucially, this module allows `java` to function both as a **local version manager** (similar to
tools like `rvm`, `nvm`, `pyenv`, or `uv`) and as a component invoked seamlessly by the global
version manager, `libscript`. Furthermore, `libscript` can utilize this `java` toolchain as a
foundational building block to provision and orchestrate much larger, complex software stacks (such
as WordPress, Open edX, Nextcloud, and more).

## Usage with LibScript

This directory contains the installation and configuration scripts for `java`. It is designed to be
executed via the global `libscript.sh` router or directly via `cli.sh`.

You can install, start, stop, package, and uninstall java using the global `libscript` command or
the local CLI.

**Unix (Linux/macOS):**

```sh

./libscript.sh install java

./cli.sh install java

./libscript.sh start java
./cli.sh start java

./libscript.sh stop java
./cli.sh stop java

./libscript.sh package-as docker java
./cli.sh package-as docker java

./libscript.sh uninstall java
./cli.sh uninstall java
```

**Windows:**

```cmd
:: Global Orchestrator
libscript.cmd install java

:: Local CLI
cli.cmd install java

:: Start and Stop
libscript.cmd start java
cli.cmd start java

libscript.cmd stop java
cli.cmd stop java

:: Package (e.g., as MSI installer)
libscript.cmd package-as msi java
cli.cmd package-as msi java

:: Uninstall
libscript.cmd uninstall java
cli.cmd uninstall java
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                                          | Default            | Aliases/Examples |
| --------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `JAVA_INSTALL_METHOD` | How to install JAVA. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `JAVA_VERSION`        | Version of Java Toolchain to install                                                                                                                                 | `latest`           |                  |
| `JAVA_DOWNLOAD_URL`   | Override URL for downloading java binary or archive artifacts.                                                                                                       | `none`             |                  |
| `JAVA_HOME`           | Filesystem directory or path configuration for java (JAVA_HOME).                                                                                                     | `none`             |                  |
| `JAVA_RELEASES_URL`   | Override URL for querying java available remote releases.                                                                                                            | `none`             |                  |

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
