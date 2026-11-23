# Apk

**Tier**: `T1` (`_lib/package-managers/apk/`) | **Capabilities**: `userland-package`

## Usage

This document describes the **apk** (Alpine Package Keeper) bootstrap component for the LibScript
ecosystem. It handles the integration and management of the Alpine Linux package manager.

Designed for flexibility, it works both as a **local version manager** (similar to rvm, nvm, pyenv,
uv) for `apk` environments and can be effortlessly invoked from the **global version manager**,
`libscript`. As a foundational tool, `apk` is frequently used by `libscript` to provision system
dependencies and build bigger stacks (like WordPress, Open edX, Nextcloud, etc.) on Alpine-based
systems or containers.

You can install, start, stop, package, and uninstall apk using the global `libscript` command or the
local CLI.

**Unix (Linux/macOS):**

```sh

./libscript.sh install apk

./cli.sh install apk



./libscript.sh package-as docker apk
./cli.sh package-as docker apk

./libscript.sh uninstall apk
./cli.sh uninstall apk
```

**Windows:**

```cmd
:: Global Orchestrator
libscript.cmd install apk

:: Local CLI
cli.cmd install apk

:: Start and Stop


:: Package (e.g., as MSI installer)
libscript.cmd package-as msi apk
cli.cmd package-as msi apk

:: Uninstall
libscript.cmd uninstall apk
cli.cmd uninstall apk
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                           | Default            | Aliases/Examples |
| -------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `APK_VERSION`        | Specific version of apk to install.                                                                                                                   | `latest`           |                  |
| `APK_INSTALL_METHOD` | Installation strategy for apk: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `APK_DOWNLOAD_URL`   | Override URL for downloading apk binary or archive artifacts.                                                                                         | `none`             |                  |
| `APK_RELEASES_URL`   | Override URL for querying apk available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
