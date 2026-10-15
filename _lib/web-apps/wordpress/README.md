# WordPress 7.1.2 Enterprise Platform

## Overview

This module provides an enterprise-grade, turnkey deployment and management suite for **WordPress
7.1.2** within the LibScript ecosystem. It delivers full parity with production WAMP/LAMP
environments (Bitnami, XAMPP, WampServer) and modern container platforms, optimized for bare-metal,
virtualized (Vagrant), and Windows Installer (`.msi`) deployments powered by `SamuelMarks/msi-rs`.

### Key Capabilities

- **WordPress 7.1.2 Targeted Deployment**: Automated staging and lifecycle orchestration of
  WordPress 7.1.2 core.
- **Open edX MySQL/MariaDB Coexistence**: Non-destructive auto-detection and reuse of an existing
  Open edX MySQL/MariaDB instance on port 3306, provisioning an isolated `wordpress` schema without
  disturbing Open edX tables.
- **Hosted DBaaS & Remote Cloud Database**: Universal connection URI parser supporting
  `mysql://[user[:pass]@]host[:port]/dbname[?params]` with native TLS/SSL CA verification
  (`MYSQLI_CLIENT_SSL`).
- **WAMP-Class Production Tuning**: Pre-configured `php.ini` memory limits (`256M`/`512M`), upload
  caps (`128M`), execution timeouts (`300s`), input variable ceilings (`5000`), and Zend OPcache
  acceleration.
- **Multi-Webserver Virtualization**: Automated virtual host configuration for Nginx, Apache HTTPD
  (`mod_rewrite`, `.htaccess`), Caddy (`php_fastcgi`), and Microsoft IIS (`web.config`, URL Rewrite
  2.0).
- **Reverse-Proxy Ingress Awareness**: Native header evaluation (`HTTP_X_FORWARDED_PROTO`,
  `HTTP_X_FORWARDED_HOST`) preventing redirect loops behind reverse proxies, CDNs, or `netctl`
  routing.
- **WP-CLI Parity Host-Native CLI**: Full suite of POSIX `/bin/sh` and Windows `.cmd` administrative
  utilities: `user`, `config`, `dbshell`, `healthcheck`, `backup`, `restore`, `service`, `cron`, and
  `upgrade`.
- **Pure WiX Windows Installer**: Zero-external-bootstrapper `.msi` packaging supporting silent
  enterprise deployment and interactive setup dialogs.

---

## Architectural Topologies

```
  +-----------------------------------------------------------------------------------------------+
  |                        WORDPRESS 7.1.2 ARCHITECTURAL TOPOLOGY                                 |
  +-----------------------------------------------------------------------------------------------+
  |                                                                                               |
  |   [ Browser / Client ]                                                                        |
  |            │                                                                                  |
  |            ▼                                                                                  |
  |   [ Reverse Proxy / Ingress ]  <─── netctl routing & TLS termination                          |
  |   (Caddy / Nginx / IIS / Apache)     Handles X-Forwarded-Proto, X-Forwarded-Host              |
  |            │                                                                                  |
  |            ▼                                                                                  |
  |   [ Web Server + PHP-FPM / FastCGI ]                                                          |
  |   (Nginx / Apache / IIS / Caddy) + PHP 8.2/8.3 (OPcache, 256M limit, 128M upload)            |
  |            │                                                                                  |
  |            ▼                                                                                  |
  |   [ WordPress 7.1.2 Webroot ] ─── wp-config.php (Dynamic salts, DBaaS SSL, reverse-proxy)     |
  |            │                                                                                  |
  |   ┌────────┴──────────────────────────┬───────────────────────────────┐                       |
  |   ▼                                   ▼                               ▼                       |
  | [ Database: Mode 1 ]               [ Database: Mode 2 ]            [ Database: Mode 3 ]       |
  | Reuse Open edX MySQL/MariaDB       Standalone Local MariaDB/MySQL  Hosted Remote DBaaS        |
  | (Shared 3306, DB: wordpress)       (Fresh local instance)          (AWS RDS / Cloud SQL)      |
  |                                                                                               |
  +-----------------------------------------------------------------------------------------------+
```

---

## Command Line Interface (CLI)

The WordPress platform includes a unified command router:

```sh
# POSIX / Linux / macOS
./stacks/cms/wordpress/cli.sh <subcommand> [args...]

# Windows Command Prompt
call stacks\cms\wordpress\cli.cmd <subcommand> [args...]
```

### Subcommands

| Subcommand    | Description                                          | Example Usage                                                                           |
| :------------ | :--------------------------------------------------- | :-------------------------------------------------------------------------------------- |
| `user`        | User account administration                          | `./cli.sh user create admin admin@example.com --password "secret" --role administrator` |
| `config`      | Inspect and mutate `wp-config.php` constants         | `./cli.sh config get DB_NAME` / `./cli.sh config set WP_DEBUG true`                     |
| `dbshell`     | Interactive MySQL shell and query runner             | `./cli.sh dbshell query "SELECT user_login FROM wp_users;"`                             |
| `healthcheck` | Comprehensive system diagnostic probe                | `./cli.sh healthcheck --json`                                                           |
| `backup`      | Create full snapshot archive (DB + uploads + config) | `./cli.sh backup create --out /backups/`                                                |
| `restore`     | Restore stack from backup archive                    | `./cli.sh restore /backups/wordpress_backup_20260929.tar.gz`                            |
| `service`     | Manage web server and PHP-FPM daemons                | `./cli.sh service restart`                                                              |
| `cron`        | Run or schedule background WP-Cron tasks             | `./cli.sh cron run` / `./cli.sh cron install`                                           |
| `upgrade`     | Safe release upgrade with pre-upgrade backup         | `./cli.sh upgrade --version 7.1.2`                                                      |
| `wp`          | Direct passthrough to WP-CLI binary                  | `./cli.sh wp plugin list`                                                               |

---

## Database Configuration Strategies

### 1. Reusing Open edX MySQL/MariaDB

When Open edX is installed on the host, WordPress automatically detects the running MySQL service
(`OpenEdXMySQL` on Windows, or port 3306 on Linux) and non-destructively provisions an isolated
schema:

```sh
./stacks/cms/wordpress/setup_generic.sh --reuse-openedx-db
```

This creates a dedicated database `wordpress` and user `wordpress` with least-privilege grants
scoped strictly to `wordpress.*`, guaranteeing zero collision with Open edX relational tables
(`openedx`, `edxapp`).

### 2. Hosted DBaaS (AWS RDS, Azure, Cloud SQL, PlanetScale)

To connect to a managed cloud database:

```sh
./stacks/cms/wordpress/setup_generic.sh
  --mysql-url "mysql://wpuser:p%40ssword@db.cluster.rds.amazonaws.com:3306/wordpress_db?ssl-ca=/etc/ssl/rds-ca.pem&ssl-mode=REQUIRED"
```

The setup engine automatically extracts credentials, decodes percent-encoded passwords, enables
`MYSQLI_CLIENT_SSL`, and configures certificate validation in `wp-config.php`.

### 3. Standalone Local MariaDB / MySQL

If Open edX is not present and no remote DBaaS is specified, WordPress provisions a dedicated local
MariaDB/MySQL instance:

```sh
./stacks/cms/wordpress/setup_generic.sh --skip-openedx-db
```

---

## WAMP-Class PHP Runtime Optimization

The deployment automatically provisions a **dedicated PHP-FPM pool** specifically for WordPress.
This isolates the WordPress process lifecycle, ensuring it runs under the `www-data` user with a
dedicated UNIX socket (`/run/php/php-fpm-wordpress.sock`). The pool is configured with dynamic
process management:

- `pm.max_children = 50`
- `pm.start_servers = 5`
- `pm.min_spare_servers = 5`
- `pm.max_spare_servers = 35`

Additionally, WordPress 7.1.2 applies enterprise WAMP configuration directives:

| Directive                         | Configured Value      | Purpose                                                    |
| :-------------------------------- | :-------------------- | :--------------------------------------------------------- |
| `memory_limit`                    | `256M` (up to `512M`) | Prevents out-of-memory errors during media processing      |
| `upload_max_filesize`             | `128M`                | Accommodates high-resolution media and video uploads       |
| `post_max_size`                   | `128M`                | Matches upload limit for multipart form posts              |
| `max_execution_time`              | `300`                 | Extends timeout for large plugin installations and imports |
| `max_input_vars`                  | `5000`                | Accommodates large custom menus and page builders          |
| `opcache.enable`                  | `1`                   | Pre-compiles PHP bytecode in shared memory                 |
| `opcache.memory_consumption`      | `128`                 | Dedicated memory pool for cached script bytecode           |
| `opcache.interned_strings_buffer` | `8`                   | Optimizes repetitive string allocation                     |
| `opcache.max_accelerated_files`   | `10000`               | Accelerates WordPress core, plugin, and theme files        |

---

## Configuration Variables

<!-- BEGIN_VARS -->

| Variable                            | Description                                                                                                                                                                                                                                                                                                                     | Default                     | Aliases/Examples |
| ----------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------- | ---------------- |
| `LIBSCRIPT_DEFAULT_INSTALL_METHOD`  | Global override for how software should be installed ('libscript_native' prebuilt binary, 'from-source' compiled from source code, 'system' via OS/selected package manager, or third-party version managers).                                                                                                                  | `libscript_native`          |                  |
| `LIBSCRIPT_PKG_MGR`                 | Explicit package manager override for 'system' or package-manager-driven installations (e.g., 'apt-get', 'apk', 'dnf', 'yum', 'zypper', 'pacman', 'brew', 'port', 'pkg', 'xbps', 'emerge', 'winget', 'choco', 'scoop', 'nix', 'guix', 'spack', 'vcpkg', 'conan', 'pkgx'). When set, overrides auto-detection in detect_pkg_mgr. | `none`                      |                  |
| `LIBSCRIPT_BUILD_TOOLCHAIN`         | Toolchain selector used when building components from source ('default' uses the platform default C/C++ compiler via _lib/languages/c, whereas 'gcc', 'clang', 'tcc', 'custom-cc', or an explicit binary path compiles the component with that specific toolchain).                                                             | `default`                   |                  |
| `LIBSCRIPT_CUSTOM_CC_BIN`           | Optional filesystem path to a custom C compiler binary when LIBSCRIPT_BUILD_TOOLCHAIN='custom-cc'.                                                                                                                                                                                                                              | `none`                      |                  |
| `LIBSCRIPT_BUILD_CFLAGS`            | Global extra CFLAGS passed to source builds across components.                                                                                                                                                                                                                                                                  | `none`                      |                  |
| `LIBSCRIPT_BUILD_LDFLAGS`           | Global extra LDFLAGS passed to source builds across components.                                                                                                                                                                                                                                                                 | `none`                      |                  |
| `LIBSCRIPT_WINDOWS_PKG_MGR`         | Global package manager override for Windows (winget, choco, scoop, vcpkg).                                                                                                                                                                                                                                                      | `winget`                    |                  |
| `LIBSCRIPT_LOG_LEVEL`               | Minimum logging level (0=DEBUG, 1=INFO, 2=SUCCESS, 3=WARN, 4=ERROR).                                                                                                                                                                                                                                                            | `1`                         |                  |
| `LIBSCRIPT_LOG_FORMAT`              | Output format for logs (text, json).                                                                                                                                                                                                                                                                                            | `text`                      |                  |
| `LIBSCRIPT_LOG_FILE`                | File to write logs to (in addition to standard output).                                                                                                                                                                                                                                                                         | `none`                      |                  |
| `LIBSCRIPT_SERVICE_NAME`            | Overrides the default service name.                                                                                                                                                                                                                                                                                             | `none`                      |                  |
| `DOWNLOAD_DIR`                      | Directory where downloads are stored.                                                                                                                                                                                                                                                                                           | `none`                      |                  |
| `FORMAT`                            | Output format (e.g., json, text).                                                                                                                                                                                                                                                                                               | `none`                      |                  |
| `LIBSCRIPT_CACHE_DIR`               | Directory where cached files are stored.                                                                                                                                                                                                                                                                                        | `none`                      |                  |
| `LIBSCRIPT_OFFLINE`                 | Flag (0 or 1) indicating whether offline mode is active, prohibiting outgoing network calls.                                                                                                                                                                                                                                    | `0`                         |                  |
| `LIBSCRIPT_FORCE_OFFLINE`           | Strict offline flag (0 or 1) that immediately aborts execution if network calls are attempted.                                                                                                                                                                                                                                  | `0`                         |                  |
| `LIBSCRIPT_DOWNLOAD_DIR`            | Staging directory for temporary download artifacts.                                                                                                                                                                                                                                                                             | `none`                      |                  |
| `LIBSCRIPT_LOG_DRIVER`              | Logging driver to use (e.g., fluentd).                                                                                                                                                                                                                                                                                          | `none`                      |                  |
| `LOGS_DIR`                          | Directory where logs should be stored.                                                                                                                                                                                                                                                                                          | `none`                      |                  |
| `VAULT_TOKEN`                       | Token for HashiCorp Vault authentication.                                                                                                                                                                                                                                                                                       | `none`                      |                  |
| `PREFIX`                            | Installation prefix.                                                                                                                                                                                                                                                                                                            | `none`                      |                  |
| `SERVE_FROM`                        | Base directory or context path for the service.                                                                                                                                                                                                                                                                                 | `none`                      |                  |
| `LIBSCRIPT_LOG_HOST`                | Host for remote logging.                                                                                                                                                                                                                                                                                                        | `none`                      |                  |
| `LIBSCRIPT_VERSION`                 | Specifies the version of the package to use.                                                                                                                                                                                                                                                                                    | `none`                      |                  |
| `LIBSCRIPT_LOG_PORT`                | Port for remote logging.                                                                                                                                                                                                                                                                                                        | `none`                      |                  |
| `TPU_ZONE`                          | GCP Zone for TPU provisioning                                                                                                                                                                                                                                                                                                   | `us-central2-b`             |                  |
| `TPU_ACCELERATOR_TYPE`              | Type of TPU accelerator (e.g. v4-8)                                                                                                                                                                                                                                                                                             | `v4-8`                      |                  |
| `TPU_VERSION`                       | TPU VM OS version                                                                                                                                                                                                                                                                                                               | `tpu-ubuntu2204-base`       |                  |
| `GCP_PROJECT_ID`                    | GCP Project ID                                                                                                                                                                                                                                                                                                                  | `none`                      |                  |
| `XPK_CLUSTER_NAME`                  | Name for the XPK GKE cluster                                                                                                                                                                                                                                                                                                    | `none`                      |                  |
| `TPU_TENSOR_PARALLEL_SIZE`          | Tensor parallel size for TPU serving                                                                                                                                                                                                                                                                                            | `1`                         |                  |
| `MODEL_NAME`                        | HuggingFace model string to serve                                                                                                                                                                                                                                                                                               | `your-org/your-model-name`  |                  |
| `WORKLOAD_NAME`                     | Name of the XPK workload                                                                                                                                                                                                                                                                                                        | `none`                      |                  |
| `JETSTREAM_IMAGE`                   | Docker image for JetStream TPU inference                                                                                                                                                                                                                                                                                        | `none`                      |                  |
| `WORDPRESS_VERSION`                 | Target WordPress core version to deploy (e.g. '7.1.2' or 'latest').                                                                                                                                                                                                                                                             | `7.1.2`                     |                  |
| `WORDPRESS_SITE_TITLE`              | Initial website and blog title for the WordPress installation.                                                                                                                                                                                                                                                                  | `LibScript WordPress 7.1.2` |                  |
| `WORDPRESS_ADMIN_USER`              | Initial administrator username for WordPress authentication.                                                                                                                                                                                                                                                                    | `admin`                     |                  |
| `WORDPRESS_ADMIN_PASSWORD`          | Initial administrator password for WordPress authentication.                                                                                                                                                                                                                                                                    | `admin`                     |                  |
| `WORDPRESS_ADMIN_EMAIL`             | Initial administrator email address receiving system notifications.                                                                                                                                                                                                                                                             | `admin@example.local`       |                  |
| `WORDPRESS_SITE_URL`                | Canonical public site URL (WP_SITEURL), including protocol and optional port.                                                                                                                                                                                                                                                   | `http://wordpress.local`    |                  |
| `WORDPRESS_HOME_URL`                | Canonical public homepage URL (WP_HOME), including protocol and optional port.                                                                                                                                                                                                                                                  | `http://wordpress.local`    |                  |
| `WORDPRESS_SERVER_NAME`             | Virtual host domain name or hostname used in web server configuration.                                                                                                                                                                                                                                                          | `wordpress.local`           |                  |
| `WORDPRESS_LISTEN`                  | TCP port on which the web server listens for incoming HTTP requests.                                                                                                                                                                                                                                                            | `80`                        |                  |
| `WORDPRESS_WEBSERVER`               | Ingress web server engine ('nginx', 'caddy', 'httpd', or 'iis').                                                                                                                                                                                                                                                                | `nginx`                     |                  |
| `WORDPRESS_WWWROOT`                 | Filesystem path to the WordPress document root directory.                                                                                                                                                                                                                                                                       | `/var/www/wordpress`        |                  |
| `WORDPRESS_PHP_VERSION`             | Target PHP runtime version required for WordPress execution.                                                                                                                                                                                                                                                                    | `8.2`                       |                  |
| `WORDPRESS_PHP_FPM_LISTEN`          | UNIX domain socket path or TCP host:port where PHP-FPM FastCGI listens.                                                                                                                                                                                                                                                         | `127.0.0.1:9000`            |                  |
| `WORDPRESS_PHP_MEMORY_LIMIT`        | PHP memory limit directive (e.g. '256M' or '512M').                                                                                                                                                                                                                                                                             | `256M`                      |                  |
| `WORDPRESS_PHP_UPLOAD_MAX_FILESIZE` | Maximum upload file size directive (e.g. '128M').                                                                                                                                                                                                                                                                               | `128M`                      |                  |
| `WORDPRESS_PHP_POST_MAX_SIZE`       | Maximum POST request body size directive (e.g. '128M').                                                                                                                                                                                                                                                                         | `128M`                      |                  |
| `WORDPRESS_PHP_MAX_EXECUTION_TIME`  | Maximum script execution timeout in seconds.                                                                                                                                                                                                                                                                                    | `300`                       |                  |
| `WORDPRESS_PHP_MAX_INPUT_VARS`      | Maximum number of input variables accepted via GET/POST/cookies.                                                                                                                                                                                                                                                                | `5000`                      |                  |
| `WORDPRESS_PHP_OPCACHE_ENABLE`      | Whether to enable Zend OPcache bytecode accelerator.                                                                                                                                                                                                                                                                            | `true`                      |                  |
| `WORDPRESS_REUSE_OPENEDX_DB`        | Whether to detect, reuse, and coexist with an existing Open edX MySQL/MariaDB database instance.                                                                                                                                                                                                                                | `true`                      |                  |
| `WORDPRESS_OPENEDX_CONFIG_PATH`     | Custom filesystem path override for Open edX configuration discovery.                                                                                                                                                                                                                                                           | `/etc/edx/config.json`      |                  |
| `WORDPRESS_DB_ENGINE`               | Database management engine ('mariadb', 'mysql', 'sqlite', or 'postgres').                                                                                                                                                                                                                                                       | `mariadb`                   |                  |
| `WORDPRESS_DBAAS_URL`               | Connection URI for remote hosted DBaaS (e.g. 'mysql://user:pass@host:3306/db?ssl-ca=ca.pem').                                                                                                                                                                                                                                   | `none`                      |                  |
| `WORDPRESS_DB_HOST`                 | Relational database server host or TCP host:port.                                                                                                                                                                                                                                                                               | `127.0.0.1:3306`            |                  |
| `WORDPRESS_DB_NAME`                 | Database schema name dedicated to WordPress.                                                                                                                                                                                                                                                                                    | `wordpress`                 |                  |
| `WORDPRESS_DB_USER`                 | Database user account credential for WordPress connections.                                                                                                                                                                                                                                                                     | `wordpress`                 |                  |
| `WORDPRESS_DB_PASS`                 | Database user password credential for WordPress connections.                                                                                                                                                                                                                                                                    | `wordpress`                 |                  |
| `WORDPRESS_DB_SSL_CA`               | Filesystem path to certificate authority (CA) bundle for TLS database connections.                                                                                                                                                                                                                                              | `none`                      |                  |
| `WORDPRESS_DB_SSL_VERIFY`           | Whether to strictly verify the database server TLS certificate.                                                                                                                                                                                                                                                                 | `true`                      |                  |
| `WORDPRESS_TABLE_PREFIX`            | Relational database table prefix for WordPress tables.                                                                                                                                                                                                                                                                          | `wp_`                       |                  |
| `WORDPRESS_REVERSE_PROXY_MODE`      | Whether to trust reverse-proxy SSL headers (HTTP_X_FORWARDED_PROTO/HOST) to avoid redirect loops.                                                                                                                                                                                                                               | `true`                      |                  |
| `WORDPRESS_ENABLE_REDIS`            | Whether to install and activate Redis Object Cache drop-in for WordPress.                                                                                                                                                                                                                                                       | `none`                      |                  |
| `WORDPRESS_REDIS_HOST`              | Redis daemon host for object caching.                                                                                                                                                                                                                                                                                           | `127.0.0.1`                 |                  |
| `WORDPRESS_REDIS_PORT`              | Redis daemon TCP port for object caching.                                                                                                                                                                                                                                                                                       | `6379`                      |                  |
| `WORDPRESS_ENABLE_PHPMYADMIN`       | Whether to deploy Adminer/phpMyAdmin database management web interface.                                                                                                                                                                                                                                                         | `true`                      |                  |
| `WORDPRESS_ENABLE_CRON_OFFLOAD`     | Whether to disable web traffic WP-Cron and offload to native host crontab or Task Scheduler.                                                                                                                                                                                                                                    | `true`                      |                  |
| `WORDPRESS_UPDATE_HOSTS_FILE`       | Whether to automatically register the virtual hostname in the operating system hosts file.                                                                                                                                                                                                                                      | `none`                      |                  |
| `db_strategy`                       | Database provisioning strategy (e.g. relational vs nosql).                                                                                                                                                                                                                                                                      | `local`                     |                  |
| `db_host`                           | Database connection host.                                                                                                                                                                                                                                                                                                       | `127.0.0.1`                 |                  |
| `db_name`                           | Database name.                                                                                                                                                                                                                                                                                                                  | `wordpress`                 |                  |
| `db_url`                            | Full database connection string or URL.                                                                                                                                                                                                                                                                                         | `none`                      |                  |

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
