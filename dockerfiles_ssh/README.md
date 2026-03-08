# dockerfiles_ssh

## Overview
This document describes the `dockerfiles_ssh` directory within the LibScript ecosystem. This folder contains Dockerfiles and related configuration for setting up SSH servers via Docker.

It works both as a local version manager (similar to rvm, nvm, pyenv, uv) and can be invoked from the global version manager `libscript`. Additionally, it can be used by libscript to build bigger stacks (like WordPress, Open edX, nextcloud, etc.) by providing secure SSH access to the underlying infrastructure.

## LibScript Operations
You can manage this component using the global `libscript` CLI or the local `cli.sh`/`cli.cmd`.

- **Install:** `libscript install dockerfiles_ssh`
- **Uninstall:** `libscript uninstall dockerfiles_ssh`
- **Start:** `libscript start dockerfiles_ssh`
- **Stop:** `libscript stop dockerfiles_ssh`
- **Package:** `libscript package_as docker dockerfiles_ssh` (or `msi`, `docker_compose`, etc.)

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

The Python toolchain (`_lib/languages/python`) is extensively integrated with this feature and supports the following `PYTHON_INSTALL_METHOD` values:
- `uv` (default fallback): Installs Python and creates virtual environments using astral's `uv` tool.
- `pyenv`: Installs Python versions using `pyenv`, managing them in `~/.pyenv`.
- `system`: Uses the system's package manager to provide Python.
- `from-source`: Compiles Python directly from its source code.

By combining global methods with local overrides, you can mix and match system-provided stable packages with newer or custom-compiled toolchains as needed.
