# vllm Component

## Overview

This component manages the installation and execution of `vllm` within the libscript ecosystem.
Libscript manages vllm versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/vllm/<version>`.

## Usage

Refer to the component's setup and cli scripts for specific operations.

## Environment Variables

This component honors standard `libscript` variables. Refer to `_common/base_vars.schema.json`.

_Note: The default install method is `libscript_native`._

## Configuration

| Variable              | Description                                                                                                                                                          | Default            | Required |
| --------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | -------- |
| `VLLM_INSTALL_METHOD` | How to install VLLM. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |          |
