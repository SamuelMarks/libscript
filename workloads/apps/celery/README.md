# Celery

## Purpose & Current State

This document describes the `celery` task queue and worker component (part of `_storage`) within the
LibScript ecosystem.

LibScript functions as both a comprehensive global version manager (invoked via the `libscript`
command) and a local version manager (similar to `rvm`, `nvm`, `pyenv`, or `uv`) for Celery. You can
manage Celery directly in an isolated, local context, or orchestrate it globally.

Furthermore, this component can be seamlessly utilized by LibScript to build and provision larger,
complex stacks (like WordPress, Open edX, Nextcloud, custom data pipelines, etc.) by defining it as
a dependency in your deployment configurations.

## Usage

You can easily install, uninstall, start, stop, and package Celery using the LibScript CLI:

### Installation

**Unix (Linux/macOS):**

```sh
./cli.sh install celery

libscript install celery
```

**Windows:**

```cmd
cli.cmd install celery
```

### Start & Stop

```sh
./cli.sh start celery
./cli.sh stop celery
```

### Uninstallation

```sh
./cli.sh uninstall celery
```

### Packaging

LibScript can package this component into various deployment formats:

```sh
libscript package-as docker celery
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                        | Description                                                                                                                             | Default            |
| :------------------------------ | :-------------------------------------------------------------------------------------------------------------------------------------- | :----------------- |
| `LIBSCRIPT_TARGET_SYSROOT`      | Target root filesystem staging path when provisioning chroots or OS images.                                                             | `-`                |
| `LIBSCRIPT_TARGET_ARCH`         | Target CPU architecture when cross-compiling or building OS images.                                                                     | `-`                |
| `LIBSCRIPT_TARGET_LIBC`         | Target C standard library implementation (glibc, musl, uclibc, picolibc, nolibc, msvcrt).                                               | `-`                |
| `LIBSCRIPT_TARGET_OS`           | Target operating system identifier when provisioning or cross-compiling.                                                                | `-`                |
| `LIBSCRIPT_HOST_ROOT`           | Isolated cross-toolchain host directory prefix when bootstrapping or executing inside a container/chroot.                               | `-`                |
| `LIBSCRIPT_STAGE`               | Active multi-stage T3 execution plan stage identifier (e.g., stage0, stage1, stage2, stage3).                                           | `-`                |
| `LIBSCRIPT_IMAGE_BUILD`         | Flag (0 or 1) indicating offline sysroot/image synthesis mode so service installers stage unit files without starting host daemons.     | `0`                |
| `LIBSCRIPT_STRICT_IMAGE_BUILD`  | Flag (0 or 1) enforcing strict native image synthesis and rejecting missing-tool stub fallbacks without writing completion stamps.      | `0`                |
| `LIBSCRIPT_ALLOW_STUB`          | Flag (0 or 1) explicitly permitting structural stub artifacts during unit and dry-run testing when hypervisor or mkfs tools are absent. | `0`                |
| `LIBSCRIPT_VM_WORKER`           | Virtualization worker backend override (docker, wsl2, qemu, bhyve, omnios-vm) for cross-OS disk and filesystem synthesis.               | `-`                |
| `LIBSCRIPT_UNIKERNEL_FRAMEWORK` | Target unikernel build framework (unikraft, nanos, osv, rumprun, mirageos) when synthesizing unikernel appliances.                      | `-`                |
| `LIBSCRIPT_RELEASEVER`          | Target Enterprise Linux major release version passed to dnf --releasever when staging into LIBSCRIPT_TARGET_SYSROOT.                    | `9`                |
| `LIBSCRIPT_SYSTEMD_DIR`         | Override directory for systemd unit and drop-in override files (defaults to /etc/systemd/system).                                       | `-`                |
| `LIBSCRIPT_LIB_SYSTEMD_DIR`     | Override directory for vendor systemd unit files (defaults to /lib/systemd/system).                                                     | `-`                |
| `LIBSCRIPT_ETC_DIR`             | Override root configuration directory for system service config files (defaults to /etc).                                               | `-`                |
| `LIBSCRIPT_INITD_DIR`           | Override directory for SysV/OpenRC init.d scripts (defaults to /etc/init.d).                                                            | `-`                |
| `LIBSCRIPT_FREEBSD_RCD_DIR`     | Override directory for FreeBSD rc.d service scripts (defaults to /usr/local/etc/rc.d).                                                  | `-`                |
| `LIBSCRIPT_RUN_DIR`             | Override runtime PID/socket directory (defaults to /var/run).                                                                           | `-`                |
| `LIBSCRIPT_USR_LOCAL_BIN`       | Override directory for locally installed system binaries (defaults to /usr/local/bin).                                                  | `-`                |
| `LIBSCRIPT_USR_LOCAL_ETC`       | Override directory for locally installed system configuration files (defaults to /usr/local/etc).                                       | `-`                |
| `LIBSCRIPT_HOME_BASE`           | Base parent directory for user home directories (defaults to /home).                                                                    | `-`                |
| `LIBSCRIPT_ROOT_HOME`           | Root user home directory override (defaults to /root).                                                                                  | `-`                |
| `CELERY_SERVICE_USER`           | User account used to run the Celery worker daemon.                                                                                      | `celery`           |
| `CELERY_APP`                    | Celery application module import path (e.g., 'lms.envs.tutor.production').                                                              | `-`                |
| `CELERY_QUEUES`                 | Comma-separated list of task queues consumed by the Celery worker.                                                                      | `high,default,low` |
| `CELERY_CONCURRENCY`            | Number of concurrent Celery worker child processes.                                                                                     | `2`                |
| `CELERY_BEAT_ENABLED`           | Whether to run the Celery Beat periodic task scheduler alongside the worker.                                                            | `False`            |
| `CELERY_BROKER_URL`             | Message broker connection URL for Celery (e.g., redis://127.0.0.1:6379/0).                                                              | `-`                |
| `PYTHON_VENV`                   | Python virtual environment path into which Celery is installed and launched.                                                            | `-`                |
| `GROUP`                         | Primary system group assigned to the Celery daemon user account.                                                                        | `-`                |
| `PYTHON_VERSION`                | Python runtime version provisioned for the Celery virtual environment.                                                                  | `-`                |
| `CELERY_LOG_DIR`                | Directory for Celery worker and beat log files.                                                                                         | `-`                |
| `CELERY_RUN_DIR`                | Runtime directory for Celery PID and beat schedule state files.                                                                         | `-`                |
| `CELERY_USER_HOME`              | Home directory path assigned to the Celery service user.                                                                                | `-`                |

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

- `_lib/languages/python`: Python runtime and Celery worker engine
- `_lib/message-brokers/rabbitmq` (or `_lib/caches/redis`): Distributed message broker and results
  backend
