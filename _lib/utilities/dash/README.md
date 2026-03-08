# dash

## Overview
This document describes **Dash**, a POSIX-compliant implementation of `/bin/sh` that aims to be as small and efficient as possible.

Dash works both as a local version manager (similar to rvm, nvm, pyenv, uv) and can be invoked from the global version manager `libscript`. It can also be seamlessly used by libscript as an underlying dependency to build bigger stacks (like WordPress, Open edX, Nextcloud, etc.).

## Lifecycle Commands

You can easily control Dash with `libscript` using the following core commands:

* **Install:**
  ```bash
  libscript install dash
  ```
* **Uninstall:**
  ```bash
  libscript uninstall dash
  ```
* **Start:**
  ```bash
  libscript start dash
  ```
* **Stop:**
  ```bash
  libscript stop dash
  ```
* **Package:**
  ```bash
  libscript package dash
  ```

## Configuration

*(There are currently no component-specific configuration tables or variables defined for this module.)*

## Variables

See `vars.schema.json` for details on available variables.
