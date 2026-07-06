# cli Component

## Overview

This component manages the installation and execution of `cli` within the libscript ecosystem.

## Usage

Refer to the component's setup and cli scripts for specific operations.

## Environment Variables

This component honors standard `libscript` variables. Refer to `_common/base_vars.schema.json`.

## Install Method

By default, `libscript` will install this component natively using the `libscript_native` method.
You can override this behavior by setting `<COMPONENT>_INSTALL_METHOD` to `system`, `mise`, `asdf`,
etc.

## Version Management

As outlined in the core philosophy, `libscript` manages the versions natively. Installations are
isolated by default in `~/.libscript/<component>/<version>` and do not pollute global system paths.
