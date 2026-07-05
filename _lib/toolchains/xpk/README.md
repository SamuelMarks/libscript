# xpk Component

## Overview

This component manages the installation and execution of `xpk` within the libscript ecosystem.

## Usage

_Note: libscript manages versions natively for this component._

Refer to the component's setup and cli scripts for specific operations.

## Environment Variables

This component honors standard `libscript` variables. Refer to `_common/base_vars.schema.json`.

## Configuration

| Variable             | Description                                                                                                                                                         | Default            | Required |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | -------- |
| `XPK_INSTALL_METHOD` | How to install XPK. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |          |

Libscript manages xpk versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/xpk/<version>`.
