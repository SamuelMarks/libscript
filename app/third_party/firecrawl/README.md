# Firecrawl (Third-Party Application)

## Purpose & Overview

This document describes the `firecrawl` web scraping and crawling component within the LibScript ecosystem.

LibScript functions as both a comprehensive global version manager (invoked via the `libscript` command) and a local version manager (similar to `rvm`, `nvm`, `pyenv`, or `uv`) for Firecrawl. You can manage Firecrawl directly in an isolated, local context, or orchestrate it globally. 

Furthermore, this component can be seamlessly utilized by LibScript to build and provision larger, complex stacks (like WordPress, Open edX, Nextcloud, custom data ingestion pipelines, etc.) by defining it as a dependency in your deployment configurations.

## Lifecycle Management with LibScript

You can easily install, uninstall, start, stop, and package Firecrawl using the LibScript CLI:

### Installation
**Unix (Linux/macOS):**
```sh
./cli.sh install firecrawl [VERSION] [OPTIONS]
# Or via global manager:
libscript install firecrawl
```
**Windows:**
```cmd
cli.cmd install firecrawl [VERSION] [OPTIONS]
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
libscript package_as docker firecrawl
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before running the setup script.

| Variable | Description | Default | Aliases |
|----------|-------------|---------|---------|
| `FIRECRAWL_BUILD_DIR` | Build dir | `none` | `` |
| `FIRECRAWL_DEST` | Dest to clone/pull firecrawl into | `none` | `` |
| `PYTHON_VENV` | Python virtualenv to install & then start the celery daemon from | `none` | `` |

## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic using the package manager mapper.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.
