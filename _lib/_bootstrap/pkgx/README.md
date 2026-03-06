# pkgx

## Overview
This document describes **pkgx**, a blazing-fast, standalone, and cross-platform package manager that runs anything.

pkgx works both as a local version manager (similar to rvm, nvm, pyenv, uv) and can be invoked from the global version manager `libscript`. Additionally, it can be used by libscript to securely and reliably build bigger stacks (like WordPress, Open edX, Nextcloud, etc.).

## Lifecycle Commands

You can efficiently manage pkgx with `libscript` using the standard lifecycle commands:

* **Install:**
  ```bash
  libscript install pkgx
  ```
* **Uninstall:**
  ```bash
  libscript uninstall pkgx
  ```
* **Start:**
  ```bash
  libscript start pkgx
  ```
* **Stop:**
  ```bash
  libscript stop pkgx
  ```
* **Package:**
  ```bash
  libscript package pkgx
  ```

## Configuration

*(There are currently no component-specific configuration tables or variables defined for this module.)*
