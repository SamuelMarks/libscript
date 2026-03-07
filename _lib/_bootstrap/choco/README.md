# choco

## Overview
This document describes **Chocolatey (choco)**, a machine-level, command-line package manager and installer for Windows software. 

Chocolatey works both as a local version manager (similar to rvm, nvm, pyenv, uv) and can be invoked from the global version manager `libscript`. Furthermore, it can be used by libscript as a foundational tool to build and provision bigger stacks (like WordPress, Open edX, Nextcloud, etc.).

## Lifecycle Commands

You can seamlessly manage Chocolatey with `libscript` using the following lifecycle commands:

* **Install:**
  ```bash
  libscript install choco
  ```
* **Uninstall:**
  ```bash
  libscript uninstall choco
  ```
* **Start:**
  ```bash
  libscript start choco
  ```
* **Stop:**
  ```bash
  libscript stop choco
  ```
* **Package:**
  ```bash
  libscript package choco
  ```

## Configuration

*(There are currently no component-specific configuration tables or variables defined for this module.)*

## Variables

See `vars.schema.json` for details on available variables.
