# 7zip

## Overview
This document describes **7zip (7-Zip)**, a highly efficient, open-source file archiver known for its high compression ratio and wide format support.

7zip works both as a local version manager (similar to rvm, nvm, pyenv, uv) and can be invoked from the global version manager `libscript`. It acts as an essential foundational tool and can be used by libscript to build bigger stacks (like WordPress, Open edX, Nextcloud, etc.) that require archive extraction or compression.

## Lifecycle Commands

You can manage the 7zip integration with `libscript` using the following commands:

* **Install:**
  ```bash
  libscript install 7zip
  ```
* **Uninstall:**
  ```bash
  libscript uninstall 7zip
  ```
* **Start:**
  ```bash
  libscript start 7zip
  ```
* **Stop:**
  ```bash
  libscript stop 7zip
  ```
* **Package:**
  ```bash
  libscript package 7zip
  ```

## Configuration

*(There are currently no component-specific configuration tables or variables defined for this module.)*
