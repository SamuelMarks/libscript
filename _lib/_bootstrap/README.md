# Bootstrap Folder (`_bootstrap`)

## Overview

This folder describes the **Bootstrap** components within the LibScript ecosystem. It contains installers and initializers for various fundamental package managers and shell environments. 

The bootstrap components function both as **local version managers** (similar to rvm, nvm, pyenv, uv) for their respective tools and can be invoked seamlessly from the **global version manager**, `libscript`. Because of this flexible architecture, the bootstrap utilities can be used by `libscript` to orchestrate and build bigger stacks (like WordPress, Open edX, Nextcloud, etc.) by ensuring the underlying host environment is correctly provisioned.

## Supported Bootstrap Managers

Currently supported tools in this folder include:
* `apk`: Alpine Linux package manager
* `brew`: Homebrew package manager
* `scoop`: Windows command-line installer
* `winget`: Windows Package Manager

*(Note: Additional components like PowerShell also exist within subdirectories).*

## Usage with LibScript

You can manage bootstrap components (e.g., `brew`, `apk`, `scoop`, `powershell`) using the standard `libscript` CLI commands:

- **Install**: `libscript install <bootstrap-component>`
- **Uninstall**: `libscript uninstall <bootstrap-component>`
- **Start**: `libscript start <bootstrap-component>`
- **Stop**: `libscript stop <bootstrap-component>`
- **Package**: `libscript package <bootstrap-component>` (e.g., `libscript package_as docker <bootstrap-component>`)
