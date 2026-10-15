# Netctl

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

| Variable                           | Description                                                                                                                                                                                                                                                                                                                     | Default                    | Aliases/Examples |
| ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------- | ---------------- |
| `LIBSCRIPT_DEFAULT_INSTALL_METHOD` | Global override for how software should be installed ('libscript_native' prebuilt binary, 'from-source' compiled from source code, 'system' via OS/selected package manager, or third-party version managers).                                                                                                                  | `libscript_native`         |                  |
| `LIBSCRIPT_PKG_MGR`                | Explicit package manager override for 'system' or package-manager-driven installations (e.g., 'apt-get', 'apk', 'dnf', 'yum', 'zypper', 'pacman', 'brew', 'port', 'pkg', 'xbps', 'emerge', 'winget', 'choco', 'scoop', 'nix', 'guix', 'spack', 'vcpkg', 'conan', 'pkgx'). When set, overrides auto-detection in detect_pkg_mgr. | `none`                     |                  |
| `LIBSCRIPT_BUILD_TOOLCHAIN`        | Toolchain selector used when building components from source ('default' uses the platform default C/C++ compiler via _lib/languages/c, whereas 'gcc', 'clang', 'tcc', 'custom-cc', or an explicit binary path compiles the component with that specific toolchain).                                                             | `default`                  |                  |
| `LIBSCRIPT_CUSTOM_CC_BIN`          | Optional filesystem path to a custom C compiler binary when LIBSCRIPT_BUILD_TOOLCHAIN='custom-cc'.                                                                                                                                                                                                                              | `none`                     |                  |
| `LIBSCRIPT_BUILD_CFLAGS`           | Global extra CFLAGS passed to source builds across components.                                                                                                                                                                                                                                                                  | `none`                     |                  |
| `LIBSCRIPT_BUILD_LDFLAGS`          | Global extra LDFLAGS passed to source builds across components.                                                                                                                                                                                                                                                                 | `none`                     |                  |
| `LIBSCRIPT_WINDOWS_PKG_MGR`        | Global package manager override for Windows (winget, choco, scoop, vcpkg).                                                                                                                                                                                                                                                      | `winget`                   |                  |
| `LIBSCRIPT_LOG_LEVEL`              | Minimum logging level (0=DEBUG, 1=INFO, 2=SUCCESS, 3=WARN, 4=ERROR).                                                                                                                                                                                                                                                            | `1`                        |                  |
| `LIBSCRIPT_LOG_FORMAT`             | Output format for logs (text, json).                                                                                                                                                                                                                                                                                            | `text`                     |                  |
| `LIBSCRIPT_LOG_FILE`               | File to write logs to (in addition to standard output).                                                                                                                                                                                                                                                                         | `none`                     |                  |
| `LIBSCRIPT_SERVICE_NAME`           | Overrides the default service name.                                                                                                                                                                                                                                                                                             | `none`                     |                  |
| `DOWNLOAD_DIR`                     | Directory where downloads are stored.                                                                                                                                                                                                                                                                                           | `none`                     |                  |
| `FORMAT`                           | Output format (e.g., json, text).                                                                                                                                                                                                                                                                                               | `none`                     |                  |
| `LIBSCRIPT_CACHE_DIR`              | Directory where cached files are stored.                                                                                                                                                                                                                                                                                        | `none`                     |                  |
| `LIBSCRIPT_OFFLINE`                | Flag (0 or 1) indicating whether offline mode is active, prohibiting outgoing network calls.                                                                                                                                                                                                                                    | `0`                        |                  |
| `LIBSCRIPT_FORCE_OFFLINE`          | Strict offline flag (0 or 1) that immediately aborts execution if network calls are attempted.                                                                                                                                                                                                                                  | `0`                        |                  |
| `LIBSCRIPT_DOWNLOAD_DIR`           | Staging directory for temporary download artifacts.                                                                                                                                                                                                                                                                             | `none`                     |                  |
| `LIBSCRIPT_LOG_DRIVER`             | Logging driver to use (e.g., fluentd).                                                                                                                                                                                                                                                                                          | `none`                     |                  |
| `LOGS_DIR`                         | Directory where logs should be stored.                                                                                                                                                                                                                                                                                          | `none`                     |                  |
| `VAULT_TOKEN`                      | Token for HashiCorp Vault authentication.                                                                                                                                                                                                                                                                                       | `none`                     |                  |
| `PREFIX`                           | Installation prefix.                                                                                                                                                                                                                                                                                                            | `none`                     |                  |
| `SERVE_FROM`                       | Base directory or context path for the service.                                                                                                                                                                                                                                                                                 | `none`                     |                  |
| `LIBSCRIPT_LOG_HOST`               | Host for remote logging.                                                                                                                                                                                                                                                                                                        | `none`                     |                  |
| `LIBSCRIPT_VERSION`                | Specifies the version of the package to use.                                                                                                                                                                                                                                                                                    | `none`                     |                  |
| `LIBSCRIPT_LOG_PORT`               | Port for remote logging.                                                                                                                                                                                                                                                                                                        | `none`                     |                  |
| `TPU_ZONE`                         | GCP Zone for TPU provisioning                                                                                                                                                                                                                                                                                                   | `us-central2-b`            |                  |
| `TPU_ACCELERATOR_TYPE`             | Type of TPU accelerator (e.g. v4-8)                                                                                                                                                                                                                                                                                             | `v4-8`                     |                  |
| `TPU_VERSION`                      | TPU VM OS version                                                                                                                                                                                                                                                                                                               | `tpu-ubuntu2204-base`      |                  |
| `GCP_PROJECT_ID`                   | GCP Project ID                                                                                                                                                                                                                                                                                                                  | `none`                     |                  |
| `XPK_CLUSTER_NAME`                 | Name for the XPK GKE cluster                                                                                                                                                                                                                                                                                                    | `none`                     |                  |
| `TPU_TENSOR_PARALLEL_SIZE`         | Tensor parallel size for TPU serving                                                                                                                                                                                                                                                                                            | `1`                        |                  |
| `MODEL_NAME`                       | HuggingFace model string to serve                                                                                                                                                                                                                                                                                               | `your-org/your-model-name` |                  |
| `WORKLOAD_NAME`                    | Name of the XPK workload                                                                                                                                                                                                                                                                                                        | `none`                     |                  |
| `JETSTREAM_IMAGE`                  | Docker image for JetStream TPU inference                                                                                                                                                                                                                                                                                        | `none`                     |                  |

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
