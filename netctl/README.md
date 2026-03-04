# netctl

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `netctl` directory within the LibScript ecosystem. LibScript is a modular, zero-dependency shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

**Current State**: LibScript functions as a comprehensive global and per-component package manager, featuring a robust core CLI (`libscript.sh`, `libscript.cmd`, `libscript.bat`). It includes multi-platform toolchain support (Rust, Python, Node, Go, Java, C/C++), servers (Postgres 18, Nginx, Valkey), and advanced environment querying (`env` subcommand). It natively supports generating deployment configurations (`package_as docker`, `package_as docker_compose`, `package_as msi`, `package_as innosetup`, `package_as nsis`, `package_as TUI`) with deep installer customization, automated parallel dependency downloading and resolution via `libscript.json`, and robust uninstall lifecycle hooks (`uninstall.sh`/`uninstall.cmd`) for cleanly removing binaries, configs, and services. It natively handles deep semantic versioning, global `--secrets` extraction, caching, OpenBao/Vault generation, local caching via SQLite (`db-search`, `update-db`), explicit error handling for unsupported actions, and background process serving. Recent advancements have stabilized major Windows installer generation (MSI, InnoSetup, NSIS) and expanded macOS native service provisioning.

## Features

* **Universal Abstraction**: Write your routing rules once, and emit configurations for Nginx, Caddy, Apache, or IIS.
* **Idempotent**: Adding the same route twice simply overwrites the previous definition (last-write-wins).
* **Two Execution Modes**:
  * **Singular Mode**: Define all your listen ports, static files, and proxies in a single command. The configuration is output directly to `stdout` without leaving any state files behind.
  * **Additive Mode**: Build your configuration step-by-step across multiple commands. State is securely managed in a local `.netctl.json` file.
* **Cross-Platform**: 
  * Unix/Linux/macOS: Handled via `netctl.sh` (POSIX `sh` + `jq`).
  * Windows: Handled via `netctl.cmd` (Windows Batch + `jq`).

## Prerequisites

* `jq` must be installed and available in your system's `PATH`.

## Usage & Syntax

### Singular Mode (One-Liner)

Pass configuration options as flags. The final configuration is emitted immediately to standard output.

```sh
netctl.sh --listen 80 \
          --listen 443 \
          --static / /var/www \
          --proxy /api http://localhost:8080 \
          --rewrite /php \.php$ \
          --emit nginx
```

### Additive Mode (Stateful)

Use subcommands to build your configuration incrementally. State is saved to `.netctl.json` in the current working directory.

```sh
# 1. Initialize empty state
netctl.sh init

# 2. Add Listeners
netctl.sh listen 80
netctl.sh listen 443

# 3. Add Routes (Idempotent - running the same route overrides the previous target)
netctl.sh static / /var/www
netctl.sh proxy /api http://localhost:8080
netctl.sh proxy /api http://10.0.0.1:9090  # Overwrites the previous /api route
netctl.sh rewrite /php \.php$

# 4. Emit the configuration for your chosen server
netctl.sh emit caddy > Caddyfile
```

## Supported Directives

| Command/Flag | Arguments | Description |
| :--- | :--- | :--- |
| `listen` / `--listen` | `<port>` | Adds a listening port to the server block. |
| `static` / `--static` | `<path> <target>` | Maps a URL path prefix to a static file directory. |
| `proxy` / `--proxy` | `<path> <target>` | Maps a URL path prefix to an upstream reverse proxy target. |
| `rewrite` / `--rewrite` | `<path> <pattern>`| Adds a URL rewriting rule. |
| `emit` / `--emit` | `<format>` | Outputs the generated configuration (`nginx`, `caddy`, `apache`, `iis`). |

## Architecture & Implementation

State is normalized into a simple JSON schema (`.netctl.json`), which eliminates the complexity of shell text parsing.

```text
+-----------------------+--------------------+---------------------------------------------------------+
| Target / Component    | Language / Tooling | Implementation Strategy                                 |
+-----------------------+--------------------+---------------------------------------------------------+
| Core State Engine     | POSIX sh + jq      | CLI arguments translate into `jq` merge operations      |
| (Singular & Additive) | Windows Batch + jq | (e.g., `.routes[$path] = $config`). State is held in    |
|                       |                    | a `.netctl.json` file. `mktemp` creates temporary ones  |
|                       |                    | for single-shot (singular) outputs.                     |
+-----------------------+--------------------+---------------------------------------------------------+
| Nginx Generator       | POSIX sh / Batch   | Extract state via `jq -r`; generate standard `server{}` |
|                       |                    | blocks. Use `location {}` for routes, `proxy_pass` for  |
|                       |                    | proxies, `alias` for static, `rewrite` for PHP.         |
+-----------------------+--------------------+---------------------------------------------------------+
| Apache HTTPD Gen.     | POSIX sh / Batch   | Extract state; output `httpd.conf` using `<VirtualHost>`|
|                       |                    | Listen directives, `<Location>`, `ProxyPass`, `Alias`,  |
|                       |                    | and `RewriteRule` mappings.                             |
+-----------------------+--------------------+---------------------------------------------------------+
| Caddy Generator       | POSIX sh / Batch   | Extract state; map to standard `Caddyfile` syntax. Use  |
|                       |                    | `:PORT` blocks, `reverse_proxy`, `file_server`, and     |
|                       |                    | `rewrite` directives matching the JSON mappings.        |
+-----------------------+--------------------+---------------------------------------------------------+
| IIS Generator         | Windows Batch + jq | Script translates CLI args to manipulate JSON state.    |
|                       |                    | Generates standard IIS `web.config` with `<rewrite>`    |
|                       |                    | XML elements. Outputs setup commands for static roots.  |
+-----------------------+--------------------+---------------------------------------------------------+
```

## IIS Specifics

When generating IIS configurations (`netctl.cmd emit iis`), the tool outputs a standard `web.config` file containing the necessary XML `<rewrite>` rules for proxies and URL rewriting. Because IIS requires system-level registry/metabase changes to bind ports and map virtual directories, `netctl` also emits the required `appcmd` setup strings as XML comments inside the generated configuration.

## Testing

A comprehensive unit test suite is provided in POSIX shell:

```sh
./tests/test_netctl.sh
```
This suite verifies singular execution, additive state integrity, idempotency, and syntax assertions for Nginx, Caddy, and Apache HTTPD generators.
