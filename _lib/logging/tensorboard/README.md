# TensorBoard Component

## Overview

This component manages the installation and execution of TensorBoard within the libscript
ecolibscript_native. It provides an isolated virtual environment to run the metric visualization
server.

## Usage

Refer to the component's setup and cli scripts for specific operations.

```bash
# Start TensorBoard server tracking a specific directory
./_lib/logging/tensorboard/cli.sh start /tmp/my_ml_logs 6006
```

## Environment Variables

This component honors standard `libscript` variables. Refer to `_common/base_vars.schema.json`.

## Configuration

| Variable                     | Description                                                                                                                                                                 | Default            | Required |
| ---------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | -------- |
| `TENSORBOARD_INSTALL_METHOD` | How to install TENSORBOARD. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |          |

Libscript manages tensorboard versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/tensorboard/<version>`.

## Version Management

As outlined in the core philosophy, `libscript` manages the versions natively. Installations are
isolated by default in `~/.libscript/<component>/<version>` and do not pollute global system paths.

## Configuration Options

<!-- BEGIN_VARS -->

| Variable                     | Description                                                           | Default            | Aliases/Examples |
| ---------------------------- | --------------------------------------------------------------------- | ------------------ | ---------------- |
| `TENSORBOARD_VERSION`        | Specific version of TensorBoard to install.                           | `latest`           | latest, stable   |
| `TENSORBOARD_INSTALL_METHOD` | How to install TensorBoard.                                           | `libscript_native` |                  |
| `TENSORBOARD_DOWNLOAD_URL`   | Override URL for downloading tensorboard binary or archive artifacts. | `none`             |                  |
| `TENSORBOARD_RELEASES_URL`   | Override URL for querying tensorboard available remote releases.      | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
