# Scoop (`_bootstrap/scoop`)

## Overview

This document describes the **Scoop** bootstrap component within the LibScript ecosystem. Scoop is a command-line installer for Windows that eliminates permission popup windows and hides GUI wizard dialogs.

The Scoop component functions as a **local version manager** (similar to rvm, nvm, pyenv, uv) for managing Windows tools, while also being capable of being invoked directly from the **global version manager**, `libscript`. Through this capability, Scoop is heavily used by `libscript` on Windows platforms to resolve dependencies and build bigger stacks (like WordPress, Open edX, Nextcloud, etc.).

## Usage with LibScript

You can manage Scoop and its lifecycle using standard `libscript` commands:

- **Install**: `libscript install scoop`
- **Uninstall**: `libscript uninstall scoop`
- **Start**: `libscript start scoop`
- **Stop**: `libscript stop scoop`
- **Package**: `libscript package scoop` (e.g., `libscript package_as innosetup scoop`)

## Variables

See `vars.schema.json` for details on available variables.
