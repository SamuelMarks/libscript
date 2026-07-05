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
