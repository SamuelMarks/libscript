# apk (`_bootstrap/apk`)

## Overview

This document describes the **apk** (Alpine Package Keeper) bootstrap component for the LibScript ecosystem. It handles the integration and management of the Alpine Linux package manager.

Designed for flexibility, it works both as a **local version manager** (similar to rvm, nvm, pyenv, uv) for `apk` environments and can be effortlessly invoked from the **global version manager**, `libscript`. As a foundational tool, `apk` is frequently used by `libscript` to provision system dependencies and build bigger stacks (like WordPress, Open edX, Nextcloud, etc.) on Alpine-based systems or containers.

## Usage with LibScript

The `apk` component is fully compatible with standard `libscript` commands:

- **Install**: `libscript install apk`
- **Uninstall**: `libscript uninstall apk`
- **Start**: `libscript start apk`
- **Stop**: `libscript stop apk`
- **Package**: `libscript package apk` (e.g., `libscript package_as docker apk`)

## Variables

See `vars.schema.json` for details on available variables.
