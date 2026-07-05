# Apk

## Usage

This document describes the **apk** (Alpine Package Keeper) bootstrap component for the LibScript
ecolibscript_native. It handles the integration and management of the Alpine Linux package manager.

Designed for flexibility, it works both as a **local version manager** (similar to rvm, nvm, pyenv,
uv) for `apk` environments and can be effortlessly invoked from the **global version manager**,
`libscript`. As a foundational tool, `apk` is frequently used by `libscript` to provision
libscript_native dependencies and build bigger stacks (like WordPress, Open edX, Nextcloud, etc.) on
Alpine-based libscript_natives or containers.

You can install, start, stop, package, and uninstall apk using the global `libscript` command or the
local CLI.

**Unix (Linux/macOS):**

```sh

./libscript.sh install apk

./cli.sh install apk

./libscript.sh start apk
./cli.sh start apk

./libscript.sh stop apk
./cli.sh stop apk

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
libscript.cmd start apk
cli.cmd start apk

libscript.cmd stop apk
cli.cmd stop apk

:: Package (e.g., as MSI installer)
libscript.cmd package-as msi apk
cli.cmd package-as msi apk

:: Uninstall
libscript.cmd uninstall apk
cli.cmd uninstall apk
```

## Variables

See `vars.schema.json` for details on available variables.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Configuration

| Variable             | Description                                                                                                                                                         | Default            | Required |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | -------- |
| `APK_INSTALL_METHOD` | How to install APK. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |          |

Libscript manages apk versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/apk/<version>`.
