# Netctl

**Tier**: `T2` (`_lib/networking/netctl/`) | **Capabilities**: `sysroot-package`

## Purpose & Current State

This document describes the `netctl` routing and reverse proxy configuration component within the
LibScript ecosystem. `netctl` is a universal abstraction layer for defining routes, static file
maps, and proxies that can emit configurations for Nginx, Caddy, Apache, or IIS.

LibScript functions as both a comprehensive global version manager (invoked via the `libscript`
command) and a local version manager (similar to `rvm`, `nvm`, `pyenv`, or `uv`) for `netctl`. You
can manage `netctl` directly in an isolated, local context, or orchestrate it globally.

Furthermore, `netctl` is heavily utilized by LibScript to build and provision larger, complex stacks
(like WordPress, Open edX, Nextcloud, custom microservices, etc.) by automatically wiring up their
networking and web server routing rules.

## Usage

You can easily install, uninstall, start, stop, and package `netctl` using the LibScript CLI:

### Installation

**Unix (Linux/macOS):**

```sh
./netctl.sh install

libscript install netctl
```

### Start & Stop

```sh
libscript start netctl
libscript stop netctl
```

### Uninstallation

```sh
libscript uninstall netctl
```

### Packaging

```sh
libscript package-as docker netctl
```

## Features

- **Universal Abstraction**: Write your routing rules once, and emit configurations for Nginx,
  Caddy, Apache, or IIS.
- **Idempotent**: Adding the same route twice simply overwrites the previous definition
  (last-write-wins).
- **Two Execution Modes**:
- **Singular Mode**: Define all your listen ports, static files, and proxies in a single command.
  The configuration is output directly to `stdout` without leaving any state files behind.
- **Additive Mode**: Build your configuration step-by-step across multiple commands. State is
  securely managed in a local `.netctl.json` file.
- **Cross-Platform**:
- Unix/Linux/macOS: Handled via `netctl.sh` (POSIX `sh` + `jq`).
- Windows: Handled via `netctl.cmd` (Windows Batch + `jq`).

## Prerequisites

- `jq` must be installed and available in your system's `PATH`.

### Singular Mode (One-Liner)

Pass configuration options as flags. The final configuration is emitted immediately to standard
output.

```sh
netctl.sh --listen 80 \
 --listen 443 \
 --static / /var/www \
 --proxy /api http://localhost:8080 \
 --rewrite /php \.php$ \
 --emit nginx
```

### Additive Mode (Stateful)

Use subcommands to build your configuration incrementally. State is saved to `.netctl.json` in the
current working directory.

```sh

netctl.sh init

netctl.sh listen 80
netctl.sh listen 443

netctl.sh static / /var/www
netctl.sh proxy /api http://localhost:8080
netctl.sh proxy /api http://10.0.0.1:9090 # Overwrites the previous /api route
netctl.sh rewrite /php \.php$

netctl.sh emit caddy > Caddyfile
```

## Supported Directives

| Command/Flag            | Arguments          | Description                                                              |
| :---------------------- | :----------------- | :----------------------------------------------------------------------- |
| `listen` / `--listen`   | `<port>`           | Adds a listening port to the server block.                               |
| `static` / `--static`   | `<path> <target>`  | Maps a URL path prefix to a static file directory.                       |
| `proxy` / `--proxy`     | `<path> <target>`  | Maps a URL path prefix to an upstream reverse proxy target.              |
| `rewrite` / `--rewrite` | `<path> <pattern>` | Adds a URL rewriting rule.                                               |
| `emit` / `--emit`       | `<format>`         | Outputs the generated configuration (`nginx`, `caddy`, `apache`, `iis`). |

## Architecture & Implementation

State is normalized into a simple JSON schema (`.netctl.json`), which eliminates the complexity of
shell text parsing.

```text
+-----------------------+--------------------+---------------------------------------------------------+
| Target / Component | Language / Tooling | Implementation Strategy |
+-----------------------+--------------------+---------------------------------------------------------+
| Core State Engine | POSIX sh + jq | CLI arguments translate into `jq` merge operations |
| (Singular & Additive) | Windows Batch + jq | (e.g., `.routes[$path] = $config`). State is held in |
| | | a `.netctl.json` file. `mktemp` creates temporary ones |
| | | for single-shot (singular) outputs. |
+-----------------------+--------------------+---------------------------------------------------------+
| Nginx Generator | POSIX sh / Batch | Extract state via `jq -r`; generate standard `server{}` |
| | | blocks. Use `location {}` for routes, `proxy_pass` for |
| | | proxies, `alias` for static, `rewrite` for PHP. |
+-----------------------+--------------------+---------------------------------------------------------+
| Apache HTTPD Gen. | POSIX sh / Batch | Extract state; output `httpd.conf` using `<VirtualHost>`|
| | | Listen directives, `<Location>`, `ProxyPass`, `Alias`, |
| | | and `RewriteRule` mappings. |
+-----------------------+--------------------+---------------------------------------------------------+
| Caddy Generator | POSIX sh / Batch | Extract state; map to standard `Caddyfile` syntax. Use |
| | | `:PORT` blocks, `reverse_proxy`, `file_server`, and |
| | | `rewrite` directives matching the JSON mappings. |
+-----------------------+--------------------+---------------------------------------------------------+
| IIS Generator | Windows Batch + jq | Script translates CLI args to manipulate JSON state. |
| | | Generates standard IIS `web.config` with `<rewrite>` |
| | | XML elements. Outputs setup commands for static roots. |
+-----------------------+--------------------+---------------------------------------------------------+
```

## IIS Specifics

When generating IIS configurations (`netctl.cmd emit iis`), the tool outputs a standard `web.config`
file containing the necessary XML `<rewrite>` rules for proxies and URL rewriting. Because IIS
requires system-level registry/metabase changes to bind ports and map virtual directories, `netctl`
also emits the required `appcmd` setup strings as XML comments inside the generated configuration.

## Testing

A comprehensive unit test suite is provided in POSIX shell:

```sh
./tests/test_netctl.sh
```

This suite verifies singular execution, additive state integrity, idempotency, and syntax assertions
for Nginx, Caddy, and Apache HTTPD generators.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                           | Description                                                                                                                             | Default           | Aliases/Examples        |
| ---------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- | ----------------- | ----------------------- |
| `LIBSCRIPT_TARGET_SYSROOT`         | Target root filesystem staging path when provisioning chroots or OS images.                                                             | `none`            | LIBSCRIPT_TARGET_ROOTFS |
| `LIBSCRIPT_TARGET_ARCH`            | Target CPU architecture when cross-compiling or building OS images.                                                                     | `none`            |                         |
| `LIBSCRIPT_TARGET_LIBC`            | Target C standard library implementation (glibc, musl, uclibc, picolibc, nolibc, msvcrt).                                               | `none`            |                         |
| `LIBSCRIPT_TARGET_OS`              | Target operating system identifier when provisioning or cross-compiling.                                                                | `none`            |                         |
| `LIBSCRIPT_HOST_ROOT`              | Isolated cross-toolchain host directory prefix when bootstrapping or executing inside a container/chroot.                               | `none`            |                         |
| `LIBSCRIPT_STAGE`                  | Active multi-stage T3 execution plan stage identifier (e.g., stage0, stage1, stage2, stage3).                                           | `none`            |                         |
| `LIBSCRIPT_IMAGE_BUILD`            | Flag (0 or 1) indicating offline sysroot/image synthesis mode so service installers stage unit files without starting host daemons.     | `0`               |                         |
| `LIBSCRIPT_STRICT_IMAGE_BUILD`     | Flag (0 or 1) enforcing strict native image synthesis and rejecting missing-tool stub fallbacks without writing completion stamps.      | `0`               |                         |
| `LIBSCRIPT_ALLOW_STUB`             | Flag (0 or 1) explicitly permitting structural stub artifacts during unit and dry-run testing when hypervisor or mkfs tools are absent. | `0`               |                         |
| `LIBSCRIPT_VM_WORKER`              | Virtualization worker backend override (docker, wsl2, qemu, bhyve, omnios-vm) for cross-OS disk and filesystem synthesis.               | `none`            |                         |
| `LIBSCRIPT_UNIKERNEL_FRAMEWORK`    | Target unikernel build framework (unikraft, nanos, osv, rumprun, mirageos) when synthesizing unikernel appliances.                      | `none`            |                         |
| `LIBSCRIPT_RELEASEVER`             | Target Enterprise Linux major release version passed to dnf --releasever when staging into LIBSCRIPT_TARGET_SYSROOT.                    | `9`               |                         |
| `LIBSCRIPT_SYSTEMD_DIR`            | Override directory for systemd unit and drop-in override files (defaults to /etc/systemd/system).                                       | `none`            |                         |
| `LIBSCRIPT_LIB_SYSTEMD_DIR`        | Override directory for vendor systemd unit files (defaults to /lib/systemd/system).                                                     | `none`            |                         |
| `LIBSCRIPT_ETC_DIR`                | Override root configuration directory for system service config files (defaults to /etc).                                               | `none`            |                         |
| `LIBSCRIPT_INITD_DIR`              | Override directory for SysV/OpenRC init.d scripts (defaults to /etc/init.d).                                                            | `none`            |                         |
| `LIBSCRIPT_FREEBSD_RCD_DIR`        | Override directory for FreeBSD rc.d service scripts (defaults to /usr/local/etc/rc.d).                                                  | `none`            |                         |
| `LIBSCRIPT_RUN_DIR`                | Override runtime PID/socket directory (defaults to /var/run).                                                                           | `none`            |                         |
| `LIBSCRIPT_USR_LOCAL_BIN`          | Override directory for locally installed system binaries (defaults to /usr/local/bin).                                                  | `none`            |                         |
| `LIBSCRIPT_USR_LOCAL_ETC`          | Override directory for locally installed system configuration files (defaults to /usr/local/etc).                                       | `none`            |                         |
| `LIBSCRIPT_HOME_BASE`              | Base parent directory for user home directories (defaults to /home).                                                                    | `none`            |                         |
| `LIBSCRIPT_ROOT_HOME`              | Root user home directory override (defaults to /root).                                                                                  | `none`            |                         |
| `NETCTL_DIR`                       | Root directory of the netctl component.                                                                                                 | `none`            |                         |
| `NETCTL_STATE_FILE`                | Path to the active netctl JSON state file.                                                                                              | `none`            |                         |
| `NETCTL_BOOTSTRAP_HTTP_ONLY`       | Internal flag (0 or 1) to emit port 80 HTTP-only Nginx configuration during initial ACME HTTP-01 challenge bootstrap.                   | `none`            |                         |
| `CERT_STORE_DIR`                   | Persistent read-only directory on attached storage for storing Let's Encrypt certificates across VM recreations.                        | `/mnt/data/certs` |                         |
| `LETSENCRYPT_EMAIL`                | Contact email address for Let's Encrypt ACME registration.                                                                              | `none`            |                         |
| `LETSENCRYPT_RENEW_BEFORE_SECONDS` | Remaining validity threshold in seconds passed to openssl x509 -checkend before renewing a certificate (0 = renew only when expired).   | `0`               |                         |
| `NETCTL_PROXY_CONNECT_TIMEOUT`     | Upstream proxy connection timeout (e.g., 60 or '60s').                                                                                  | `60s`             |                         |
| `NETCTL_PROXY_SEND_TIMEOUT`        | Upstream proxy send timeout in seconds (e.g., 300 or '300s').                                                                           | `300s`            |                         |
| `NETCTL_PROXY_READ_TIMEOUT`        | Upstream proxy read timeout in seconds for long-running LLM/SSE endpoints (e.g., 300 or '300s').                                        | `300s`            |                         |
| `NETCTL_PROXY_BUFFERING`           | Whether upstream proxy response buffering is enabled ('on'/'off' or boolean).                                                           | `off`             |                         |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
