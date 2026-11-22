# Kubernetes Thw

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `kubernetes-thw` component
within the LibScript ecolibscript_native. This component manages **kubernetes-thw**, a custom
Kubernetes cluster setup based on "Kubernetes The Hard Way".

## Usage

This directory contains the scripts to interact with `kubernetes-thw`. It is designed to be executed
via the global `libscript` command or directly via local CLI scripts.

You can install, start, stop, uninstall, and package this component using `libscript`.

**Install:**

```sh
libscript install kubernetes-thw
```

**Start:**

```sh
libscript start kubernetes-thw
```

**Stop:**

```sh
libscript stop kubernetes-thw
```

**Uninstall:**

```sh
libscript uninstall kubernetes-thw
```

**Package:**

```sh
libscript package-as docker kubernetes-thw

```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                        | Description                                                                                                                                                                    | Default            | Aliases/Examples        |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ----------------------- |
| `LIBSCRIPT_TARGET_SYSROOT`      | Target root filesystem staging path when provisioning chroots or OS images.                                                                                                    | `none`             | LIBSCRIPT_TARGET_ROOTFS |
| `LIBSCRIPT_TARGET_ARCH`         | Target CPU architecture when cross-compiling or building OS images.                                                                                                            | `none`             |                         |
| `LIBSCRIPT_TARGET_LIBC`         | Target C standard library implementation (glibc, musl, uclibc, picolibc, nolibc, msvcrt).                                                                                      | `none`             |                         |
| `LIBSCRIPT_TARGET_OS`           | Target operating system identifier when provisioning or cross-compiling.                                                                                                       | `none`             |                         |
| `LIBSCRIPT_HOST_ROOT`           | Isolated cross-toolchain host directory prefix when bootstrapping or executing inside a container/chroot.                                                                      | `none`             |                         |
| `LIBSCRIPT_STAGE`               | Active multi-stage Tier 2 execution plan stage identifier (e.g., stage0, stage1, stage2, stage3).                                                                              | `none`             |                         |
| `LIBSCRIPT_IMAGE_BUILD`         | Flag (0 or 1) indicating offline sysroot/image synthesis mode so service installers stage unit files without starting host daemons.                                            | `0`                |                         |
| `LIBSCRIPT_STRICT_IMAGE_BUILD`  | Flag (0 or 1) enforcing strict native image synthesis and rejecting missing-tool stub fallbacks without writing completion stamps.                                             | `0`                |                         |
| `LIBSCRIPT_ALLOW_STUB`          | Flag (0 or 1) explicitly permitting structural stub artifacts during unit and dry-run testing when hypervisor or mkfs tools are absent.                                        | `0`                |                         |
| `LIBSCRIPT_VM_WORKER`           | Virtualization worker backend override (docker, wsl2, qemu, bhyve, omnios-vm) for cross-OS disk and filesystem synthesis.                                                      | `none`             |                         |
| `LIBSCRIPT_UNIKERNEL_FRAMEWORK` | Target unikernel build framework (unikraft, nanos, osv, rumprun, mirageos) when synthesizing unikernel appliances.                                                             | `none`             |                         |
| `LIBSCRIPT_RELEASEVER`          | Target Enterprise Linux major release version passed to dnf --releasever when staging into LIBSCRIPT_TARGET_SYSROOT.                                                           | `9`                |                         |
| `LIBSCRIPT_SYSTEMD_DIR`         | Override directory for systemd unit and drop-in override files (defaults to /etc/systemd/system).                                                                              | `none`             |                         |
| `LIBSCRIPT_LIB_SYSTEMD_DIR`     | Override directory for vendor systemd unit files (defaults to /lib/systemd/system).                                                                                            | `none`             |                         |
| `LIBSCRIPT_ETC_DIR`             | Override root configuration directory for system service config files (defaults to /etc).                                                                                      | `none`             |                         |
| `LIBSCRIPT_INITD_DIR`           | Override directory for SysV/OpenRC init.d scripts (defaults to /etc/init.d).                                                                                                   | `none`             |                         |
| `LIBSCRIPT_FREEBSD_RCD_DIR`     | Override directory for FreeBSD rc.d service scripts (defaults to /usr/local/etc/rc.d).                                                                                         | `none`             |                         |
| `LIBSCRIPT_RUN_DIR`             | Override runtime PID/socket directory (defaults to /var/run).                                                                                                                  | `none`             |                         |
| `LIBSCRIPT_USR_LOCAL_BIN`       | Override directory for locally installed system binaries (defaults to /usr/local/bin).                                                                                         | `none`             |                         |
| `LIBSCRIPT_USR_LOCAL_ETC`       | Override directory for locally installed system configuration files (defaults to /usr/local/etc).                                                                              | `none`             |                         |
| `LIBSCRIPT_HOME_BASE`           | Base parent directory for user home directories (defaults to /home).                                                                                                           | `none`             |                         |
| `LIBSCRIPT_ROOT_HOME`           | Root user home directory override (defaults to /root).                                                                                                                         | `none`             |                         |
| `KUBERNETES_THW_VERSION`        | Specific version of kubernetes components to install                                                                                                                           | `latest`           |                         |
| `KUBERNETES_THW_DEST`           | Destination (working directory)                                                                                                                                                | `none`             |                         |
| `KUBERNETES_THW_VARS`           | Key/value in JSON format (as an escaped string)                                                                                                                                | `none`             |                         |
| `LIBSCRIPT_LISTEN_PORT`         | Global port to listen on                                                                                                                                                       | `none`             |                         |
| `LIBSCRIPT_LISTEN_ADDRESS`      | Global address to listen on                                                                                                                                                    | `none`             |                         |
| `LIBSCRIPT_LISTEN_SOCKET`       | Global unix socket to listen on                                                                                                                                                | `none`             |                         |
| `KUBERNETES_THW_LISTEN_PORT`    | Port for KUBERNETES_THW to listen on                                                                                                                                           | `none`             |                         |
| `KUBERNETES_THW_LISTEN_ADDRESS` | Address for KUBERNETES_THW to listen on                                                                                                                                        | `none`             |                         |
| `KUBERNETES_THW_LISTEN_SOCKET`  | Unix socket for KUBERNETES_THW to listen on                                                                                                                                    | `none`             |                         |
| `KUBERNETES_THW_INSTALL_METHOD` | How to install KUBERNETES THW. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                         |
| `KUBERNETES_THW_DOWNLOAD_URL`   | Override URL for downloading kubernetes-thw binary or archive artifacts.                                                                                                       | `none`             |                         |
| `KUBERNETES_THW_RELEASES_URL`   | Override URL for querying kubernetes-thw available remote releases.                                                                                                            | `none`             |                         |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic using the package manager mapper.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning
  correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.

## Variables

See `vars.schema.json` for details on available variables.

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
