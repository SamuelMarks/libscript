dockerfiles for ssh
===================

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `dockerfiles_ssh` directory within the LibScript ecosystem. LibScript is a modular, zero-dependency shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

**Current State**: LibScript functions as a comprehensive global and per-component package manager, featuring a robust core CLI (`libscript.sh`, `libscript.cmd`, `libscript.bat`). It includes multi-platform toolchain support (Rust, Python, Node, Go, Java, C/C++), servers (Postgres, Nginx, Valkey), and advanced environment querying (`env` subcommand). It natively supports generating deployment configurations (`package_as docker`, `package_as docker_compose`, `package_as msi`, `package_as innosetup`, `package_as nsis`, `package_as TUI`) with deep installer customization, automated parallel dependency downloading and resolution via `libscript.json`, and robust uninstall lifecycle hooks (`uninstall.sh`/`uninstall.cmd`) for cleanly removing binaries, configs, and services. It natively handles deep semantic versioning, global `--secrets` extraction, caching, OpenBao/Vault generation, local caching via SQLite (`db-search`, `update-db`), explicit error handling for unsupported actions, and background process serving. Ongoing development targets extended registry integrations and dynamic web server routing.

## Usage

### Setup public and private keys just for this

```sh
mkdir -- '.ssh'
ssh-keygen -t 'rsa' -b '4096' -C 'libscript ssh keys' -f '.ssh/id_rsa'
```

(this local ".ssh" directory is in both `.gitignore` and `.dockerignore`)

### Build Dockerfiles

```sh
docker build -f 'ssh.alpine.Dockerfile' --tag 'ssh-alpine':'latest' --build-arg SSH_PUBKEY="$(cat -- .ssh/id_rsa.pub)" .
```

### Run Dockerfiles and external images

```sh
docker run -d \
  --name='openssh-server' \
  --hostname='openssh-server' \
  -e PUID='1000' \
  -e PGID='1000' \
  -e TZ='Etc/UTC' \
  -e PUBLIC_KEY="$(cat -- .ssh/id_rsa.pub)" \
  -e SUDO_ACCESS=1 \
  -e USER_NAME='root' \
  -p 2222:2223 \
  --restart 'unless-stopped' \
  lscr.io/linuxserver/openssh-server:latest
sudo docker run --name ssh-alpine-run -t -d -p 22:222 ssh-alpine
```

Also found this one:
```sh
docker run -d --name debian-openssh-server -p 2222:22 -e USER_PASSWORD=654321 devdotnetorg/openssh-server:debian
```

That you can ssh to with password `654321`



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

You can override the global setting for specific dependencies by setting their respective `[TOOL]_INSTALL_METHOD` variable. The local override takes highest precedence. 

For example, to globally use the system package manager but strictly install Python via `uv`:
```sh
export LIBSCRIPT_GLOBAL_INSTALL_METHOD="system"
export PYTHON_INSTALL_METHOD="uv"
```

### Python-Specific Support

The Python toolchain (`_lib/_toolchain/python`) is extensively integrated with this feature and supports the following `PYTHON_INSTALL_METHOD` values:
- `uv` (default fallback): Installs Python and creates virtual environments using astral's `uv` tool.
- `pyenv`: Installs Python versions using `pyenv`, managing them in `~/.pyenv`.
- `system`: Uses the system's package manager to provide Python.
- `from-source`: Compiles Python directly from its source code.

By combining global methods with local overrides, you can mix and match system-provided stable packages with newer or custom-compiled toolchains as needed.
