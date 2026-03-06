# Fluent Bit (Server)

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `fluentbit` component within the LibScript ecosystem. This component manages **Fluent Bit**, a super fast, lightweight, and highly scalable logging and metrics processor and forwarder. It allows you to collect data/logs from different sources, unify, and send them to multiple destinations. It's fully compatible with Docker and Kubernetes environments.

**Current State**: `fluentbit` can be managed by LibScript, which functions as both a comprehensive global and per-component package manager. It explicitly works both as a local version manager (similar to tools like rvm, nvm, pyenv, and uv) and can be seamlessly invoked from the global version manager `libscript`. 

LibScript can utilize this `fluentbit` component to build bigger, more complex stacks (such as WordPress, Open edX, Nextcloud, etc.) by combining it with other services and toolchains.

## Overview

This directory contains the scripts to interact with `fluentbit`. It is designed to be executed via the global `libscript` command or directly via local CLI scripts.

### Integration in `libscript`

This module provides setup, test, and uninstall capabilities for `fluent-bit`.

- **Windows Details**: On Windows, it installs via Chocolatey or falls back to natively downloading and extracting the official `.zip` archive from `packages.fluentbit.io`.
- **POSIX Details**: On Linux and macOS, it delegates to the system package manager (e.g., `apt-get`, `brew`, `apk`) to install `fluent-bit`.

### Operations

You can install, start, stop, uninstall, and package this component using `libscript`.

**Install:**
```sh
libscript install fluentbit [VERSION] [OPTIONS]
```

**Start:**
```sh
libscript start fluentbit
```

**Stop:**
```sh
libscript stop fluentbit
```

**Uninstall:**
```sh
libscript uninstall fluentbit
```

**Package:**
```sh
libscript package_as docker fluentbit
# Supported formats: docker, docker_compose, msi, innosetup, nsis, TUI
```

## Configuration Options

For full configuration variables, please refer to the `vars.schema.json`.

## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic using the package manager mapper.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.
