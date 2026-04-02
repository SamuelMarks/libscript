Gen
===

## Purpose & Overview
This document describes the `gen` directory and generation utilities within the LibScript ecosystem. It is primarily used to generate deployment artifacts, Dockerfiles, and installer scripts from configuration files.

LibScript functions as both a comprehensive global version manager (invoked via the `libscript` command) and a local version manager (similar to `rvm`, `nvm`, `pyenv`, or `uv`) for the generation toolchain. You can manage generation scripts directly in an isolated, local context, or orchestrate them globally. 

Furthermore, this `gen` component is a core part of how LibScript builds and provisions larger, complex stacks (like WordPress, Open edX, Nextcloud, etc.) by synthesizing the necessary infrastructure-as-code and packaging formats.

## Usage
You can easily install, uninstall, start, stop, and package generation components using the LibScript CLI:

### Installation
```sh
libscript install gen
```

### Start & Stop
```sh
libscript start gen
libscript stop gen
```

### Uninstallation
```sh
libscript uninstall gen
```

### Packaging
```sh
libscript package_as docker gen
```

## Gotchas
Because [symbolic links don't work in Docker](https://docs.docker.com/reference/dockerfile/#incompatibilities-with---linkfalse), you'll have to literally copy the directories over.

Make sure you have the latest folders in place; or delete the folders and `create_installer_from_json.sh` will do the copying for you.

For example, I usually run:
```sh
$ rm -rf gen/{*.csh,*.sh,*.cmd,_lib,app,dockerfiles} ; sh ./create_installer_from_json.sh -f ./install.json -o gen
$ sh ./create_docker_builder.sh -i gen -vvv
$ cd gen && sh ./docker_builder.sh

```

## Dependency Installation Methods
`libscript` provides a flexible dependency management system, allowing you to control how dependencies are installed—either globally across the entire setup or locally on a per-toolchain basis.

### Global Configuration

You can set a global preference for how tools should be installed by defining `LIBSCRIPT_GLOBAL_INSTALL_METHOD` in your environment or global configuration (`install.json`).

Supported global methods typically include:
- `system`: Uses the system's package manager (e.g., `apt`, `apk`, `pacman`).
- `source`: Builds or downloads the tool from source/official binaries (fallback behavior depends on the tool).

Example:
```sh
export LIBSCRIPT_GLOBAL_INSTALL_METHOD="system"
```

### Local Overrides

You can override the global setting for specific dependencies by setting their respective `GEN_INSTALL_METHOD` variable. The local override takes highest precedence. 

For example, to globally use the system package manager but strictly install Python via `uv`:
```sh
export LIBSCRIPT_GLOBAL_INSTALL_METHOD="system"
export PYTHON_INSTALL_METHOD="uv"
```

### Python-Specific Support

The Python toolchain (`_lib/languages/python`) is extensively integrated with this feature and supports the following `PYTHON_INSTALL_METHOD` values:
- `uv` (default fallback): Installs Python and creates virtual environments using astral's `uv` tool.
- `pyenv`: Installs Python versions using `pyenv`, managing them in `~/.pyenv`.
- `system`: Uses the system's package manager to provide Python.
- `from-source`: Compiles Python directly from its source code.

By combining global methods with local overrides, you can mix and match system-provided stable packages with newer or custom-compiled toolchains as needed.

## Platform Support
- Linux
- macOS
- Windows
