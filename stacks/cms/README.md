# Cms Stacks

This directory contains pre-configured application stack definitions and orchestration workflows for
cms solutions in LibScript.

## Available Stacks

- **[drupal](drupal/)**: Installs Drupal natively via release tarball with webserver and DB
  configuration.
- **[joomla](joomla/)**: A generic setup script to deploy the [Joomla! CMS](https://www.joomla.org/)
  using LibScript.
- **[wordpress](wordpress/)**: This document describes the `WordPress` component within the
  LibScript ecosystem. This module

## Usage

To provision and run any stack in this category:

```sh
./libscript.sh run <stack-name> latest
```
