# Firecrawl

## Purpose & Current State

This document describes the `firecrawl` web scraping and crawling component within the LibScript
ecosystem.

LibScript functions as both a comprehensive global version manager (invoked via the `libscript`
command) and a local version manager (similar to `rvm`, `nvm`, `pyenv`, or `uv`) for Firecrawl. You
can manage Firecrawl directly in an isolated, local context, or orchestrate it globally.

Furthermore, this component can be seamlessly utilized by LibScript to build and provision larger,
complex stacks (like WordPress, Open edX, Nextcloud, custom data ingestion pipelines, etc.) by
defining it as a dependency in your deployment configurations.

## Usage

You can easily install, uninstall, start, stop, and package Firecrawl using the LibScript CLI:

### Installation

**Unix (Linux/macOS):**

```sh
./cli.sh install firecrawl

libscript install firecrawl
```

**Windows:**

```cmd
cli.cmd install firecrawl
```

### Start & Stop

```sh
./cli.sh start firecrawl
./cli.sh stop firecrawl
```

### Uninstallation

```sh
./cli.sh uninstall firecrawl
```

### Packaging

LibScript can package this component into various deployment formats:

```sh
libscript package-as docker firecrawl
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                     | Default |
| :-------------------- | :------------------------------------------------------------------------------ | :------ |
| `FIRECRAWL_BUILD_DIR` | Scratch build directory used when compiling Firecrawl workspace dependencies.   | `-`     |
| `FIRECRAWL_DEST`      | Destination directory into which the Firecrawl repository is cloned or updated. | `-`     |
| `PYTHON_VENV`         | Python virtual environment path used by Firecrawl auxiliary worker processes.   | `-`     |
| `BUILD_DIR`           | Fallback scratch build directory override when FIRECRAWL_BUILD_DIR is unset.    | `-`     |

> **Global Framework Variables**: Core paths, offline cache controls, and target triplet variables
> are documented in [`engine/common/README.md`](../../../engine/common/README.md).

<!-- END_VARS -->

## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic using the package manager mapper.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning
  correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->

## Orchestrated Components

This stack orchestrates the following LibScript components:

- `_lib/languages/nodejs`: Node.js execution runtime for API and crawler services
- `_lib/languages/python`: Python runtime for extraction pipelines
- `_lib/caches/redis`: Redis queue and task state backend
