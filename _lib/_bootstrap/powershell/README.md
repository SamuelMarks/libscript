# PowerShell (`_bootstrap/powershell`)

## Overview

This document describes the **PowerShell** bootstrap component within the LibScript ecosystem. It is responsible for provisioning and managing the PowerShell environment on target systems.

This component operates efficiently as a **local version manager** (similar to rvm, nvm, pyenv, uv) to manage your PowerShell installation. Furthermore, it can be directly invoked from the **global version manager**, `libscript`. This integration ensures that PowerShell can be seamlessly used by `libscript` to orchestrate and build bigger stacks (like WordPress, Open edX, Nextcloud, etc.).

## Usage with LibScript

You can manage the PowerShell component using standard `libscript` lifecycle commands:

- **Install**: `libscript install powershell`
- **Uninstall**: `libscript uninstall powershell`
- **Start**: `libscript start powershell` (Starts a session or background worker if applicable)
- **Stop**: `libscript stop powershell`
- **Package**: `libscript package powershell` (e.g., `libscript package_as msi powershell`)
