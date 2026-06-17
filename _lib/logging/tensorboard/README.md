# TensorBoard Component

## Overview

This component manages the installation and execution of TensorBoard within the libscript ecosystem.
It provides an isolated virtual environment to run the metric visualization server.

## Usage

Refer to the component's setup and cli scripts for specific operations.

```bash
# Start TensorBoard server tracking a specific directory
./_lib/logging/tensorboard/cli.sh start /tmp/my_ml_logs 6006
```

## Environment Variables

This component honors standard `libscript` variables. Refer to `_common/base_vars.schema.json`.
