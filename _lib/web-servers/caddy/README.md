# Caddy

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `caddy` server component
within the LibScript ecolibscript_native. LibScript is a modular, zero-dependency shell-script
framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the scripts for managing the Caddy component. It works both as a local
version manager (similar to rvm, nvm, pyenv, uv) for precise Caddy version control, and can be
invoked seamlessly from the global version manager `libscript`.

Furthermore, this component can be used by libscript to build bigger stacks (like WordPress, Open
edX, nextcloud, etc.), easily providing automatic HTTPS and web server functionality.

You can manage the lifecycle of this component using the global `libscript` command or the local
CLI.

**Unix (Linux/macOS):**

```sh

./libscript.sh install caddy

./cli.sh install caddy

./libscript.sh start caddy
./cli.sh start caddy

./libscript.sh stop caddy
./cli.sh stop caddy

./libscript.sh package-as docker caddy
./cli.sh package-as docker caddy

./libscript.sh uninstall caddy
./cli.sh uninstall caddy
```

**Windows:**

```cmd
:: Global Orchestrator
libscript.cmd install caddy

:: Local CLI
cli.cmd install caddy

:: Start and Stop
libscript.cmd start caddy
cli.cmd start caddy

libscript.cmd stop caddy
cli.cmd stop caddy

:: Package (e.g., as MSI installer)
libscript.cmd package-as msi caddy
cli.cmd package-as msi caddy

:: Uninstall
libscript.cmd uninstall caddy
cli.cmd uninstall caddy
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                        | Description                                                                                                                                                           | Default           | Aliases/Examples        |
| ------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------- | ----------------------- |
| `LIBSCRIPT_TARGET_SYSROOT`      | Target root filesystem staging path when provisioning chroots or OS images.                                                                                           | `none`            | LIBSCRIPT_TARGET_ROOTFS |
| `LIBSCRIPT_TARGET_ARCH`         | Target CPU architecture when cross-compiling or building OS images.                                                                                                   | `none`            |                         |
| `LIBSCRIPT_TARGET_LIBC`         | Target C standard library implementation (glibc, musl, uclibc, picolibc, nolibc, msvcrt).                                                                             | `none`            |                         |
| `LIBSCRIPT_TARGET_OS`           | Target operating system identifier when provisioning or cross-compiling.                                                                                              | `none`            |                         |
| `LIBSCRIPT_HOST_ROOT`           | Isolated cross-toolchain host directory prefix when bootstrapping or executing inside a container/chroot.                                                             | `none`            |                         |
| `LIBSCRIPT_STAGE`               | Active multi-stage Tier 2 execution plan stage identifier (e.g., stage0, stage1, stage2, stage3).                                                                     | `none`            |                         |
| `LIBSCRIPT_IMAGE_BUILD`         | Flag (0 or 1) indicating offline sysroot/image synthesis mode so service installers stage unit files without starting host daemons.                                   | `0`               |                         |
| `LIBSCRIPT_STRICT_IMAGE_BUILD`  | Flag (0 or 1) enforcing strict native image synthesis and rejecting missing-tool stub fallbacks without writing completion stamps.                                    | `0`               |                         |
| `LIBSCRIPT_ALLOW_STUB`          | Flag (0 or 1) explicitly permitting structural stub artifacts during unit and dry-run testing when hypervisor or mkfs tools are absent.                               | `0`               |                         |
| `LIBSCRIPT_VM_WORKER`           | Virtualization worker backend override (docker, wsl2, qemu, bhyve, omnios-vm) for cross-OS disk and filesystem synthesis.                                             | `none`            |                         |
| `LIBSCRIPT_UNIKERNEL_FRAMEWORK` | Target unikernel build framework (unikraft, nanos, osv, rumprun, mirageos) when synthesizing unikernel appliances.                                                    | `none`            |                         |
| `LIBSCRIPT_RELEASEVER`          | Target Enterprise Linux major release version passed to dnf --releasever when staging into LIBSCRIPT_TARGET_SYSROOT.                                                  | `9`               |                         |
| `LIBSCRIPT_SYSTEMD_DIR`         | Override directory for systemd unit and drop-in override files (defaults to /etc/systemd/system).                                                                     | `none`            |                         |
| `LIBSCRIPT_LIB_SYSTEMD_DIR`     | Override directory for vendor systemd unit files (defaults to /lib/systemd/system).                                                                                   | `none`            |                         |
| `LIBSCRIPT_ETC_DIR`             | Override root configuration directory for system service config files (defaults to /etc).                                                                             | `none`            |                         |
| `LIBSCRIPT_INITD_DIR`           | Override directory for SysV/OpenRC init.d scripts (defaults to /etc/init.d).                                                                                          | `none`            |                         |
| `LIBSCRIPT_FREEBSD_RCD_DIR`     | Override directory for FreeBSD rc.d service scripts (defaults to /usr/local/etc/rc.d).                                                                                | `none`            |                         |
| `LIBSCRIPT_RUN_DIR`             | Override runtime PID/socket directory (defaults to /var/run).                                                                                                         | `none`            |                         |
| `LIBSCRIPT_USR_LOCAL_BIN`       | Override directory for locally installed system binaries (defaults to /usr/local/bin).                                                                                | `none`            |                         |
| `LIBSCRIPT_USR_LOCAL_ETC`       | Override directory for locally installed system configuration files (defaults to /usr/local/etc).                                                                     | `none`            |                         |
| `LIBSCRIPT_HOME_BASE`           | Base parent directory for user home directories (defaults to /home).                                                                                                  | `none`            |                         |
| `LIBSCRIPT_ROOT_HOME`           | Root user home directory override (defaults to /root).                                                                                                                | `none`            |                         |
| `CADDY_INSTALL_METHOD`          | How to install CADDY. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `system`          |                         |
| `CADDY_VERSION`                 | Specific version of caddy to install. Can be a numeric version or an alias.                                                                                           | `latest`          | latest, stable          |
| `LIBSCRIPT_LISTEN_PORT`         | Global port to listen on                                                                                                                                              | `none`            |                         |
| `LIBSCRIPT_LISTEN_ADDRESS`      | Global address to listen on                                                                                                                                           | `none`            |                         |
| `LIBSCRIPT_LISTEN_SOCKET`       | Global unix socket to listen on                                                                                                                                       | `none`            |                         |
| `CADDY_LISTEN_PORT`             | Port for CADDY to listen on                                                                                                                                           | `none`            |                         |
| `CADDY_LISTEN_ADDRESS`          | Address for CADDY to listen on                                                                                                                                        | `none`            |                         |
| `CADDY_LISTEN_SOCKET`           | Unix socket for CADDY to listen on                                                                                                                                    | `none`            |                         |
| `CADDY_WWWROOT_NAME`            | The primary domain or server name (e.g., example.com) to bind the web server to.                                                                                      | `none`            |                         |
| `CADDY_WWWROOT_PATH`            | The absolute path to the static site document root (where index.html resides).                                                                                        | `none`            |                         |
| `CADDY_WWWROOT_LISTEN`          | The HTTP port Caddy should listen on (defaults to 80, but 443 is used automatically for HTTPS).                                                                       | `80`              |                         |
| `CADDY_WWWROOT_HTTPS_PROVIDER`  | The HTTPS provider for automatic certificates. Usually 'letsencrypt' or 'zerossl' (Caddy uses both by default if not set).                                            | `none`            |                         |
| `CADDY_SERVICE_RUN_AS_USER`     | Windows local user account to run the service under (leave empty for Network Service).                                                                                | `none`            |                         |
| `CADDY_SERVICE_RUN_AS_PASSWORD` | Password for the Windows local user account (if applicable).                                                                                                          | `none`            |                         |
| `CADDY_SERVICE_NAME`            | Custom name for the Windows Service (allows side-by-side installations).                                                                                              | `libscript_caddy` |                         |
| `CADDY_LISTEN`                  | Address/port to listen on.                                                                                                                                            | `none`            |                         |
| `CADDY_WWWROOT`                 | Web server root directory.                                                                                                                                            | `none`            |                         |
| `CADDY_PHP_FPM_LISTEN`          | Listen address/socket for PHP-FPM.                                                                                                                                    | `none`            |                         |
| `CADDY_SERVER_NAME`             | Name of the server (e.g., example.com).                                                                                                                               | `none`            |                         |
| `CADDY_DOWNLOAD_URL`            | Override URL for downloading caddy binary or archive artifacts.                                                                                                       | `none`            |                         |
| `CADDY_RELEASES_URL`            | Override URL for querying caddy available remote releases.                                                                                                            | `none`            |                         |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
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
