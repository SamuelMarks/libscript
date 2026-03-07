# winget

## Overview
This document describes **Winget**, the official Windows Package Manager CLI that allows users to discover, install, upgrade, remove, and configure applications on Windows 10 and Windows 11 computers.

Winget works both as a local version manager (similar to rvm, nvm, pyenv, uv) and can be invoked from the global version manager `libscript`. It can additionally be used by libscript to build and deploy bigger stacks (like WordPress, Open edX, Nextcloud, etc.).

## Lifecycle Commands

You can manage the lifecycle of Winget with `libscript` using these standard commands:

* **Install:**
  ```bash
  libscript install winget
  ```
* **Uninstall:**
  ```bash
  libscript uninstall winget
  ```
* **Start:**
  ```bash
  libscript start winget
  ```
* **Stop:**
  ```bash
  libscript stop winget
  ```
* **Package:**
  ```bash
  libscript package winget
  ```

## Configuration

*(There are currently no component-specific configuration tables or variables defined for this module.)*

## Variables

See `vars.schema.json` for details on available variables.
