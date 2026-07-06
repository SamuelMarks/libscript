# jetstream Component

## Overview

This component manages the installation and execution of `jetstream` within the libscript ecosystem.
Libscript manages Jetstream versions natively by installing them into isolated virtual environments
under `LIBSCRIPT_HOME/jetstream/<version>`.

## Usage

Refer to the component's setup and cli scripts for specific operations.

## Environment Variables

This component honors standard `libscript` variables. Refer to `_common/base_vars.schema.json`.

_Note: The default install method is `libscript_native`._

## Configuration

| Variable                   | Description                                                                                                                                                               | Default            | Required |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | -------- |
| `JETSTREAM_INSTALL_METHOD` | How to install JETSTREAM. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |          |

## Version Management

As outlined in the core philosophy, `libscript` manages the versions natively. Installations are
isolated by default in `~/.libscript/<component>/<version>` and do not pollute global system paths.
