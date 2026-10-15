# Open edX Stack

Full turnkey deployment for the Open edX LMS (Learning Management System) and Studio/CMS course
authoring environment.

## Overview

The `openedx` stack orchestrates the end-to-end topology for Open edX, provisioning and managing:

- **Application Services**: Open edX LMS & Studio/CMS via Python 3.12, Django 5.2, and Gunicorn /
  uWSGI / Waitress
- **Background Workers**: Celery async workers (`lms-worker`, `cms-worker`) and Celery Beat
  scheduler
- **Relational Storage**: MySQL 8.x (InnoDB utf8mb4 collation)
- **Document Storage**: MongoDB 7.x
- **Cache & Message Broker**: Redis 7.x (or Valkey)
- **Full-Text Search**: Meilisearch v1.36.0 (or Elasticsearch)
- **Mail Relay**: Exim local SMTP relay or hMailServer on Windows
- **Reverse Proxy / Ingress**: Caddy or Nginx with automated routing via `netctl`

---

## Installation & Deployment

### POSIX (`/bin/sh`)

```sh
./libscript.sh install stacks/cms/openedx
```

### Windows (`cmd.exe`)

```cmd
call libscript.cmd install stacks\cms\openedx
```

---

## Tutor Parity CLI Command Reference

LibScript provides host-native commands achieving full functional parity with
[Tutor](https://github.com/overhangio/tutor), adapted to native host execution, bare-metal runtime
provisioning, and Windows MSI architecture.

Commands can be invoked through the unified stack router (`stacks/cms/openedx/cli.sh` / `cli.cmd`),
or via individual submodules.

```
  +-----------------------------------------------------------------------+
  |              OPEN EDX ARCHITECTURAL PARITY COMPARISON                 |
  +-----------------------------------------------------------------------+
  |     TUTOR (Container-Centric)             LIBSCRIPT (Native/Host)     |
  |   +--------------------------+          +--------------------------+  |
  |   | Docker Compose / K8s     |          | Native POSIX / Windows   |  |
  |   | Dockerfile Image Builds  |   VS     | Bare-metal Runtimes      |  |
  |   | Container Bindmounts     |          | Portable Venvs & Daemons |  |
  |   | Ephemeral Job Containers |          | Native Service / MSI     |  |
  |   +--------------------------+          +--------------------------+  |
  +-----------------------------------------------------------------------+
```

### Quick Subcommand Summary

| Subcommand    | Description                                                | Tutor Equivalent                                   |
| :------------ | :--------------------------------------------------------- | :------------------------------------------------- |
| `user`        | User account administration (create, set-password, list)   | `tutor do createuser`, `setpassword`               |
| `demo`        | Demo course and content library ingestion                  | `tutor do importdemocourse`, `importdemolibraries` |
| `dbshell`     | Unified database client console (MySQL, MongoDB, Redis)    | `tutor do sqlshell`, `mongosh`                     |
| `healthcheck` | Diagnostics probe validating all services & HTTP endpoints | `tutor local status`                               |
| `config`      | Environment JSON configuration engine (get, set, generate) | `tutor config printvalue`, `save`                  |
| `backup`      | Consolidated full-state backup archive creation            | `tutor backup`                                     |
| `restore`     | Automated disaster recovery and state restoration          | `tutor restore`                                    |
| `workers`     | Celery async workers and Beat scheduler lifecycle          | compose worker services                            |
| `theme`       | Comprehensive theme checkout, building, and binding        | `tutor do settheme`                                |
| `xblock`      | XBlock plugin installation and discovery                   | `tutor plugins install`                            |
| `upgrade`     | Automated release upgrade migration pipeline               | `tutor local upgrade`                              |
| `mfe`         | Micro-Frontend (MFE) build, deploy, and routing pipeline   | `tutor-mfe`                                        |

---

### 1. User Management (`user`)

_Tutor Equivalent: `tutor do createuser`, `tutor do setpassword`_

Provides idempotent creation and administration of Django users, staff members, and superusers. If
an account already exists, permissions and passwords are updated without error.

#### POSIX

```sh
# Create standard user
./stacks/cms/openedx/cli.sh user create alice alice@example.com --password "SecretPass123"

# Create staff user or superuser
./stacks/cms/openedx/cli.sh user create admin admin@example.com --password "AdminPass123" --superuser

# Interactive password prompt (when --password omitted in interactive TTY)
./stacks/cms/openedx/cli.sh user create bob bob@example.com --staff

# Update existing user's password
./stacks/cms/openedx/cli.sh user set_password alice "NewSecurePass456"

# List all registered accounts and permission roles
./stacks/cms/openedx/cli.sh user list
```

#### Windows

```cmd
:: Create standard user
call stacks\cms\openedx\cli.cmd user create alice alice@example.com --password "SecretPass123"

:: Create superuser
call stacks\cms\openedx\cli.cmd user create admin admin@example.com --password "AdminPass123" --superuser

:: Reset user password
call stacks\cms\openedx\cli.cmd user set_password alice "NewSecurePass456"

:: List accounts
call stacks\cms\openedx\cli.cmd user list
```

---

### 2. Demo Course & Content Library Ingestion (`demo`)

_Tutor Equivalent: `tutor do importdemocourse`, `tutor do importdemolibraries`_

Idempotently downloads and imports demonstration courses and component libraries into the Studio
course store and LMS database. If a course ID is already present, the import is cleanly skipped.

#### POSIX

```sh
# Ingest official edX Demo Course (course-v1:edX+DemoX+Demo_Course)
./stacks/cms/openedx/cli.sh demo course

# Ingest custom course from repository
./stacks/cms/openedx/cli.sh demo course --course-id "course-v1:MyOrg+CS101+2026" --repo "https://github.com/my-org/cs101-course.git"

# Ingest demonstration component libraries into Studio
./stacks/cms/openedx/cli.sh demo libraries --owner admin
```

#### Windows

```cmd
:: Ingest standard demo course
call stacks\cms\openedx\cli.cmd demo course

:: Ingest demo libraries
call stacks\cms\openedx\cli.cmd demo libraries --owner admin
```

---

### 3. Database Shell Wrappers (`dbshell`)

_Tutor Equivalent: `tutor do sqlshell`, `tutor do mongosh`_

Provides direct interactive and non-interactive access to all Open edX storage backends using
configured stack credentials and endpoints.

#### POSIX

```sh
# Launch interactive MySQL client
./stacks/cms/openedx/cli.sh dbshell mysql

# Execute a single SQL query non-interactively
./stacks/cms/openedx/cli.sh dbshell query "SELECT id, username, email, is_staff FROM auth_user LIMIT 10;"

# Connect to MongoDB database
./stacks/cms/openedx/cli.sh dbshell mongo
# Or using the direct alias:
./stacks/cms/openedx/cli.sh mongosh

# Connect to Redis CLI
./stacks/cms/openedx/cli.sh dbshell redis
# Or using the direct alias:
./stacks/cms/openedx/cli.sh redis-cli
```

#### Windows

```cmd
:: Interactive MySQL
call stacks\cms\openedx\cli.cmd dbshell mysql

:: Non-interactive SQL query
call stacks\cms\openedx\cli.cmd dbshell query "SELECT COUNT(*) FROM auth_user;"

:: Interactive Mongo & Redis
call stacks\cms\openedx\cli.cmd mongosh
call stacks\cms\openedx\cli.cmd redis-cli
```

---

### 4. Full-Stack Health Diagnostics (`healthcheck`)

_Tutor Equivalent: `tutor local status`_

Audits system uptime and connectivity across all Open edX subsystem layers: MySQL, MongoDB, Redis,
Meilisearch, LMS Web (`:8000`), Studio Web (`:8001`), Celery worker daemons, and local SMTP mail
relay.

#### POSIX

```sh
# Human-readable ANSI status report table
./stacks/cms/openedx/cli.sh healthcheck

# Machine-readable JSON output (ideal for monitoring & CI probes)
./stacks/cms/openedx/cli.sh healthcheck --json
```

#### Windows

```cmd
:: Health diagnostics report
call stacks\cms\openedx\cli.cmd healthcheck

:: JSON diagnostics
call stacks\cms\openedx\cli.cmd healthcheck --json
```

---

### 5. Configuration Engine (`config`)

_Tutor Equivalent: `tutor config save`, `tutor config printvalue`_

Manages `config/lms.env.json` and `config/cms.env.json` idempotently. Supports nested dot-notation
paths, deep merging, and schema validation against `vars.schema.json`.

#### POSIX

```sh
# Synthesize default configuration files (preserving existing overrides)
./stacks/cms/openedx/cli.sh config generate

# Read configuration setting (supports nested keys)
./stacks/cms/openedx/cli.sh config get LMS_HOST
./stacks/cms/openedx/cli.sh config get DATABASES.default.HOST

# Update configuration key
./stacks/cms/openedx/cli.sh config set SITE_NAME "My University Open edX"
./stacks/cms/openedx/cli.sh config set LMS_HOST "courses.myuni.edu"

# View complete JSON configuration
./stacks/cms/openedx/cli.sh config list

# Validate configuration against schema
./stacks/cms/openedx/cli.sh config validate
```

#### Windows

```cmd
:: Generate configurations
call stacks\cms\openedx\cli.cmd config generate

:: Read / write keys
call stacks\cms\openedx\cli.cmd config get LMS_HOST
call stacks\cms\openedx\cli.cmd config set SITE_NAME "My University Open edX"

:: Schema validation
call stacks\cms\openedx\cli.cmd config validate
```

---

### 6. Backup & Disaster Recovery (`backup`, `restore`)

_Tutor Equivalent: `tutor backup`, `tutor restore`_

Produces consolidated state snapshots containing relational SQL dumps, MongoDB collections, user
media uploads (`media/`), and configuration files, verified by SHA-256 checksums.

#### POSIX

```sh
# Create full timestamped snapshot
./stacks/cms/openedx/cli.sh backup create

# Create snapshot with custom target archive path
./stacks/cms/openedx/cli.sh backup create --out "/var/backups/openedx-weekly.tar.gz"

# List available backup archives
./stacks/cms/openedx/cli.sh backup list

# Restore system state from backup archive
./stacks/cms/openedx/cli.sh restore apply "/var/backups/openedx-weekly.tar.gz" --yes
```

#### Windows

```cmd
:: Create backup snapshot (.zip format on Windows)
call stacks\cms\openedx\cli.cmd backup create

:: List backups
call stacks\cms\openedx\cli.cmd backup list

:: Restore from backup
call stacks\cms\openedx\cli.cmd restore apply "%USERPROFILE%\.libscript\openedx\backups\openedx_backup_20260920_125652.zip" --yes
```

---

### 7. Background Workers & Beat Scheduler (`workers`)

_Tutor Equivalent: Compose worker & beat service containers_

Controls Celery asynchronous worker processes (`lms-worker`, `cms-worker`) and the Celery Beat
periodic task scheduler, maintaining PID files in `run/` and daemon logs in `logs/`.

#### POSIX

```sh
# Launch background workers
./stacks/cms/openedx/cli.sh workers start

# Inspect worker status and active PIDs
./stacks/cms/openedx/cli.sh workers status

# Restart workers
./stacks/cms/openedx/cli.sh workers restart

# Stop all background workers
./stacks/cms/openedx/cli.sh workers stop
```

#### Windows

```cmd
:: Start background worker processes
call stacks\cms\openedx\cli.cmd workers start

:: Check status
call stacks\cms\openedx\cli.cmd workers status

:: Stop workers
call stacks\cms\openedx\cli.cmd workers stop
```

---

### 8. Theming & Branding Engine (`theme`)

_Tutor Equivalent: `tutor do settheme`_

Manages comprehensive themes for LMS and Studio interfaces, handling Git checkout, SCSS compilation,
asset bundling, and Django site configuration binding.

#### POSIX

```sh
# Install theme from Git repository
./stacks/cms/openedx/cli.sh theme install indigo https://github.com/openedx/openedx-theme-indigo.git --branch master

# Compile SCSS and static assets for theme
./stacks/cms/openedx/cli.sh theme build indigo

# Bind theme to Open edX site domain
./stacks/cms/openedx/cli.sh theme apply indigo --site "openedx.local"

# List installed themes and active status
./stacks/cms/openedx/cli.sh theme list

# Remove an installed theme
./stacks/cms/openedx/cli.sh theme remove indigo
```

#### Windows

```cmd
:: Install and build theme
call stacks\cms\openedx\cli.cmd theme install indigo https://github.com/openedx/openedx-theme-indigo.git
call stacks\cms\openedx\cli.cmd theme build indigo

:: Apply theme to site
call stacks\cms\openedx\cli.cmd theme apply indigo --site "openedx.local"

:: List themes
call stacks\cms\openedx\cli.cmd theme list
```

---

### 9. XBlock & Stack Plugin Extensibility (`xblock`)

_Tutor Equivalent: `tutor plugins install`_

Extends Open edX with custom XBlocks and plugins. Automatically handles virtualenv package
installation, database migrations, and static asset collection.

#### POSIX

```sh
# Install XBlock from PyPI or Git repository
./stacks/cms/openedx/cli.sh xblock install xblock-drag-and-drop-v2
./stacks/cms/openedx/cli.sh xblock install git+https://github.com/edx/xblock-google-drive.git

# List discovered XBlocks via entry point metadata
./stacks/cms/openedx/cli.sh xblock list

# Uninstall XBlock
./stacks/cms/openedx/cli.sh xblock uninstall xblock-drag-and-drop-v2
```

#### Windows

```cmd
:: Install XBlock
call stacks\cms\openedx\cli.cmd xblock install xblock-drag-and-drop-v2

:: List XBlocks
call stacks\cms\openedx\cli.cmd xblock list

:: Uninstall XBlock
call stacks\cms\openedx\cli.cmd xblock uninstall xblock-drag-and-drop-v2
```

---

### 10. Release Upgrades & Migrations (`upgrade`)

_Tutor Equivalent: `tutor local upgrade`_

Performs coordinated zero-data-loss upgrades between Open edX releases: automated pre-upgrade
backup, git branch switching, dependency updates, database schema migrations, asset compilation,
cache invalidation, and search reindexing.

#### POSIX

```sh
# Run upgrade pipeline to target release
./stacks/cms/openedx/cli.sh upgrade run --to open-release/quince.master
```

#### Windows

```cmd
:: Run upgrade pipeline
call stacks\cms\openedx\cli.cmd upgrade run --to open-release/quince.master
```

---

### 11. Micro-Frontend (MFE) Build & Delivery (`mfe`)

_Tutor Equivalent: `tutor-mfe` plugin_

Builds, configures, and serves production React Micro-Frontends:

- **`learning`**: Courseware experience (`frontend-app-learning`)
- **`authn`**: Authentication and registration experience (`frontend-app-authn`)
- **`account`**: User account profile and settings (`frontend-app-account`)
- **`course-authoring`**: Studio course outline and authoring (`frontend-app-course-authoring`)

#### POSIX

```sh
# Build production bundle for learning MFE
./stacks/cms/openedx/cli.sh mfe build learning --version master

# Deploy MFE dist and generate runtime env.config.js
./stacks/cms/openedx/cli.sh mfe deploy learning

# List managed MFEs and build/deployment status
./stacks/cms/openedx/cli.sh mfe list
```

#### Windows

```cmd
:: Build and deploy MFE
call stacks\cms\openedx\cli.cmd mfe build learning
call stacks\cms\openedx\cli.cmd mfe deploy learning

:: List MFEs
call stacks\cms\openedx\cli.cmd mfe list
```

---

## Configuration Options

<!-- BEGIN_VARS -->

| Variable                           | Description                                                                                                                                                                                                                                                                                                                     | Default                                                                  | Aliases/Examples |
| ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------ | ---------------- |
| `LIBSCRIPT_DEFAULT_INSTALL_METHOD` | Global override for how software should be installed ('libscript_native' prebuilt binary, 'from-source' compiled from source code, 'system' via OS/selected package manager, or third-party version managers).                                                                                                                  | `libscript_native`                                                       |                  |
| `LIBSCRIPT_PKG_MGR`                | Explicit package manager override for 'system' or package-manager-driven installations (e.g., 'apt-get', 'apk', 'dnf', 'yum', 'zypper', 'pacman', 'brew', 'port', 'pkg', 'xbps', 'emerge', 'winget', 'choco', 'scoop', 'nix', 'guix', 'spack', 'vcpkg', 'conan', 'pkgx'). When set, overrides auto-detection in detect_pkg_mgr. | `none`                                                                   |                  |
| `LIBSCRIPT_BUILD_TOOLCHAIN`        | Toolchain selector used when building components from source ('default' uses the platform default C/C++ compiler via _lib/languages/c, whereas 'gcc', 'clang', 'tcc', 'custom-cc', or an explicit binary path compiles the component with that specific toolchain).                                                             | `default`                                                                |                  |
| `LIBSCRIPT_CUSTOM_CC_BIN`          | Optional filesystem path to a custom C compiler binary when LIBSCRIPT_BUILD_TOOLCHAIN='custom-cc'.                                                                                                                                                                                                                              | `none`                                                                   |                  |
| `LIBSCRIPT_BUILD_CFLAGS`           | Global extra CFLAGS passed to source builds across components.                                                                                                                                                                                                                                                                  | `none`                                                                   |                  |
| `LIBSCRIPT_BUILD_LDFLAGS`          | Global extra LDFLAGS passed to source builds across components.                                                                                                                                                                                                                                                                 | `none`                                                                   |                  |
| `LIBSCRIPT_WINDOWS_PKG_MGR`        | Global package manager override for Windows (winget, choco, scoop, vcpkg).                                                                                                                                                                                                                                                      | `winget`                                                                 |                  |
| `LIBSCRIPT_LOG_LEVEL`              | Minimum logging level (0=DEBUG, 1=INFO, 2=SUCCESS, 3=WARN, 4=ERROR).                                                                                                                                                                                                                                                            | `1`                                                                      |                  |
| `LIBSCRIPT_LOG_FORMAT`             | Output format for logs (text, json).                                                                                                                                                                                                                                                                                            | `text`                                                                   |                  |
| `LIBSCRIPT_LOG_FILE`               | File to write logs to (in addition to standard output).                                                                                                                                                                                                                                                                         | `none`                                                                   |                  |
| `LIBSCRIPT_SERVICE_NAME`           | Overrides the default service name.                                                                                                                                                                                                                                                                                             | `none`                                                                   |                  |
| `DOWNLOAD_DIR`                     | Directory where downloads are stored.                                                                                                                                                                                                                                                                                           | `none`                                                                   |                  |
| `FORMAT`                           | Output format (e.g., json, text).                                                                                                                                                                                                                                                                                               | `none`                                                                   |                  |
| `LIBSCRIPT_CACHE_DIR`              | Directory where cached files are stored.                                                                                                                                                                                                                                                                                        | `none`                                                                   |                  |
| `LIBSCRIPT_OFFLINE`                | Flag (0 or 1) indicating whether offline mode is active, prohibiting outgoing network calls.                                                                                                                                                                                                                                    | `0`                                                                      |                  |
| `LIBSCRIPT_FORCE_OFFLINE`          | Strict offline flag (0 or 1) that immediately aborts execution if network calls are attempted.                                                                                                                                                                                                                                  | `0`                                                                      |                  |
| `LIBSCRIPT_DOWNLOAD_DIR`           | Staging directory for temporary download artifacts.                                                                                                                                                                                                                                                                             | `none`                                                                   |                  |
| `LIBSCRIPT_LOG_DRIVER`             | Logging driver to use (e.g., fluentd).                                                                                                                                                                                                                                                                                          | `none`                                                                   |                  |
| `LOGS_DIR`                         | Directory where logs should be stored.                                                                                                                                                                                                                                                                                          | `none`                                                                   |                  |
| `VAULT_TOKEN`                      | Token for HashiCorp Vault authentication.                                                                                                                                                                                                                                                                                       | `none`                                                                   |                  |
| `PREFIX`                           | Installation prefix.                                                                                                                                                                                                                                                                                                            | `none`                                                                   |                  |
| `SERVE_FROM`                       | Base directory or context path for the service.                                                                                                                                                                                                                                                                                 | `none`                                                                   |                  |
| `LIBSCRIPT_LOG_HOST`               | Host for remote logging.                                                                                                                                                                                                                                                                                                        | `none`                                                                   |                  |
| `LIBSCRIPT_VERSION`                | Specifies the version of the package to use.                                                                                                                                                                                                                                                                                    | `none`                                                                   |                  |
| `LIBSCRIPT_LOG_PORT`               | Port for remote logging.                                                                                                                                                                                                                                                                                                        | `none`                                                                   |                  |
| `TPU_ZONE`                         | GCP Zone for TPU provisioning                                                                                                                                                                                                                                                                                                   | `us-central2-b`                                                          |                  |
| `TPU_ACCELERATOR_TYPE`             | Type of TPU accelerator (e.g. v4-8)                                                                                                                                                                                                                                                                                             | `v4-8`                                                                   |                  |
| `TPU_VERSION`                      | TPU VM OS version                                                                                                                                                                                                                                                                                                               | `tpu-ubuntu2204-base`                                                    |                  |
| `GCP_PROJECT_ID`                   | GCP Project ID                                                                                                                                                                                                                                                                                                                  | `none`                                                                   |                  |
| `XPK_CLUSTER_NAME`                 | Name for the XPK GKE cluster                                                                                                                                                                                                                                                                                                    | `none`                                                                   |                  |
| `TPU_TENSOR_PARALLEL_SIZE`         | Tensor parallel size for TPU serving                                                                                                                                                                                                                                                                                            | `1`                                                                      |                  |
| `MODEL_NAME`                       | HuggingFace model string to serve                                                                                                                                                                                                                                                                                               | `your-org/your-model-name`                                               |                  |
| `WORKLOAD_NAME`                    | Name of the XPK workload                                                                                                                                                                                                                                                                                                        | `none`                                                                   |                  |
| `JETSTREAM_IMAGE`                  | Docker image for JetStream TPU inference                                                                                                                                                                                                                                                                                        | `none`                                                                   |                  |
| `OPENEDX_VERSION`                  | Open edX release or git branch (e.g., 'master', 'open-release/quince.master').                                                                                                                                                                                                                                                  | `master`                                                                 |                  |
| `OPENEDX_EDX_PLATFORM_REPOSITORY`  | Git repository URL for openedx-platform.                                                                                                                                                                                                                                                                                        | `https://github.com/openedx/openedx-platform.git`                        |                  |
| `LMS_HOST`                         | Public domain/host for LMS web interface.                                                                                                                                                                                                                                                                                       | `openedx.local`                                                          |                  |
| `CMS_HOST`                         | Public domain/host for Studio / CMS authoring interface.                                                                                                                                                                                                                                                                        | `studio.openedx.local`                                                   |                  |
| `LMS_PORT`                         | Internal HTTP port for LMS WSGI server.                                                                                                                                                                                                                                                                                         | `8000`                                                                   |                  |
| `CMS_PORT`                         | Internal HTTP port for CMS WSGI server.                                                                                                                                                                                                                                                                                         | `8001`                                                                   |                  |
| `OPENEDX_ADMIN_EMAIL`              | Administrator email address.                                                                                                                                                                                                                                                                                                    | `admin@openedx.local`                                                    |                  |
| `OPENEDX_ADMIN_USERNAME`           | Administrator username.                                                                                                                                                                                                                                                                                                         | `admin`                                                                  |                  |
| `OPENEDX_ADMIN_PASSWORD`           | Administrator initial password.                                                                                                                                                                                                                                                                                                 | `admin`                                                                  |                  |
| `OPENEDX_SECRET_KEY`               | Secret key for Django sessions and token encryption.                                                                                                                                                                                                                                                                            | `insecure-secret-key-replace-in-production`                              |                  |
| `OPENEDX_WSGI_WORKERS`             | Number of WSGI worker processes.                                                                                                                                                                                                                                                                                                | `2`                                                                      |                  |
| `OPENEDX_BACKUP_DIR`               | Directory where backup archives are generated.                                                                                                                                                                                                                                                                                  | `[CommonAppDataFolder]OpenEdX\backups`                                   |                  |
| `OPENEDX_THEME`                    | Active Comprehensive Theme name for LMS and Studio.                                                                                                                                                                                                                                                                             | `none`                                                                   |                  |
| `OPENEDX_THEME_REPO_URL`           | Git repository URL of custom Comprehensive Theme.                                                                                                                                                                                                                                                                               | `none`                                                                   |                  |
| `OPENEDX_INSTALL_DIR`              | Directory where openedx-platform is checked out and deployed.                                                                                                                                                                                                                                                                   | `none`                                                                   |                  |
| `OPENEDX_IMPORT_DEMO_COURSE`       | Whether to import the edX demo course during setup.                                                                                                                                                                                                                                                                             | `none`                                                                   |                  |
| `OPENEDX_IMPORT_DEMO_LIBRARIES`    | Whether to import demo content libraries during setup.                                                                                                                                                                                                                                                                          | `none`                                                                   |                  |
| `OPENEDX_ENABLE_WORKERS`           | Whether to enable and launch Celery background workers.                                                                                                                                                                                                                                                                         | `true`                                                                   |                  |
| `OPENEDX_ENABLE_CELERY_BEAT`       | Whether to enable Celery Beat periodic task scheduler.                                                                                                                                                                                                                                                                          | `true`                                                                   |                  |
| `OPENEDX_ENABLE_MFES`              | Whether to build and route Micro-Frontends (Learning, Authn, Account, Authoring).                                                                                                                                                                                                                                               | `none`                                                                   |                  |
| `OPENEDX_MFE_LEARNING_PORT`        | HTTP port for Learning Micro-Frontend.                                                                                                                                                                                                                                                                                          | `2000`                                                                   |                  |
| `OPENEDX_MFE_AUTHN_PORT`           | HTTP port for Authentication Micro-Frontend.                                                                                                                                                                                                                                                                                    | `2001`                                                                   |                  |
| `OPENEDX_MFE_ACCOUNT_PORT`         | HTTP port for Account Micro-Frontend.                                                                                                                                                                                                                                                                                           | `2002`                                                                   |                  |
| `OPENEDX_MFE_AUTHORING_PORT`       | HTTP port for Course Authoring Micro-Frontend.                                                                                                                                                                                                                                                                                  | `2003`                                                                   |                  |
| `db_strategy`                      | Database provisioning strategy (e.g. relational vs nosql).                                                                                                                                                                                                                                                                      | `local`                                                                  |                  |
| `db_host`                          | Database connection host.                                                                                                                                                                                                                                                                                                       | `127.0.0.1`                                                              |                  |
| `db_name`                          | Database name.                                                                                                                                                                                                                                                                                                                  | `openedx`                                                                |                  |
| `db_url`                           | Full database connection string or URL.                                                                                                                                                                                                                                                                                         | `none`                                                                   |                  |
| `PLATFORM_NAME`                    | The public name of this Open edX instance.                                                                                                                                                                                                                                                                                      | `My Open edX`                                                            |                  |
| `CONTACT_EMAIL`                    | Public contact email displayed across LMS.                                                                                                                                                                                                                                                                                      | `contact@openedx.local`                                                  |                  |
| `LANGUAGE_CODE`                    | Default language code for Open edX UI.                                                                                                                                                                                                                                                                                          | `en`                                                                     |                  |
| `ENABLE_HTTPS`                     | Whether TLS/HTTPS is terminated for public web traffic.                                                                                                                                                                                                                                                                         | `none`                                                                   |                  |
| `ENABLE_WEB_PROXY`                 | Whether local reverse proxy (Caddy/Nginx) is enabled.                                                                                                                                                                                                                                                                           | `true`                                                                   |                  |
| `CADDY_HTTP_PORT`                  | HTTP listening port for reverse proxy ingress.                                                                                                                                                                                                                                                                                  | `80`                                                                     |                  |
| `NPM_REGISTRY`                     | Custom or standard NPM registry URL.                                                                                                                                                                                                                                                                                            | `https://registry.npmjs.org/`                                            |                  |
| `EDX_PLATFORM_REPOSITORY`          | Git repository URL for edx-platform.                                                                                                                                                                                                                                                                                            | `https://github.com/openedx/openedx-platform.git`                        |                  |
| `EDX_PLATFORM_VERSION`             | Git branch, tag, or commit for edx-platform.                                                                                                                                                                                                                                                                                    | `master`                                                                 |                  |
| `OPENEDX_COMMON_VERSION`           | Canonical Open edX release version identifier.                                                                                                                                                                                                                                                                                  | `master`                                                                 |                  |
| `ATLAS_REPOSITORY`                 | Repository for Open edX internationalization strings.                                                                                                                                                                                                                                                                           | `openedx/openedx-translations`                                           |                  |
| `ATLAS_REVISION`                   | Git revision for translations repository.                                                                                                                                                                                                                                                                                       | `main`                                                                   |                  |
| `ATLAS_OPTIONS`                    | Additional flags passed to the Atlas translation tool.                                                                                                                                                                                                                                                                          | ``                                                                       |                  |
| `OPENEDX_EXTRA_PIP_REQUIREMENTS`   | Additional Python requirements installed in LMS/CMS.                                                                                                                                                                                                                                                                            | `[]`                                                                     |                  |
| `JWT_COMMON_AUDIENCE`              | Audience claim (aud) for JWT tokens.                                                                                                                                                                                                                                                                                            | `openedx`                                                                |                  |
| `JWT_COMMON_ISSUER`                | Issuer claim (iss) for JWT tokens.                                                                                                                                                                                                                                                                                              | `http://openedx.local/oauth2`                                            |                  |
| `JWT_COMMON_SECRET_KEY`            | Secret key for signing symmetric JWT tokens.                                                                                                                                                                                                                                                                                    | `none`                                                                   |                  |
| `JWT_RSA_PRIVATE_KEY`              | 2048-bit RSA private key (PEM format) for asymmetric token signing.                                                                                                                                                                                                                                                             | `none`                                                                   |                  |
| `CMS_OAUTH2_KEY_SSO`               | OAuth2 client ID for Studio SSO authentication.                                                                                                                                                                                                                                                                                 | `cms-sso`                                                                |                  |
| `CMS_OAUTH2_KEY_SSO_DEV`           | OAuth2 client ID for Studio SSO dev mode.                                                                                                                                                                                                                                                                                       | `cms-sso-dev`                                                            |                  |
| `CMS_OAUTH2_SECRET`                | OAuth2 client secret for Studio SSO authentication.                                                                                                                                                                                                                                                                             | `none`                                                                   |                  |
| `RUN_MYSQL`                        | Whether to manage and launch MySQL locally.                                                                                                                                                                                                                                                                                     | `true`                                                                   |                  |
| `MYSQL_HOST`                       | MySQL server hostname or IP address.                                                                                                                                                                                                                                                                                            | `127.0.0.1`                                                              |                  |
| `MYSQL_PORT`                       | MySQL server connection port.                                                                                                                                                                                                                                                                                                   | `3306`                                                                   |                  |
| `MYSQL_ROOT_USERNAME`              | MySQL administrator username.                                                                                                                                                                                                                                                                                                   | `root`                                                                   |                  |
| `MYSQL_ROOT_PASSWORD`              | MySQL administrator password.                                                                                                                                                                                                                                                                                                   | `none`                                                                   |                  |
| `OPENEDX_MYSQL_DATABASE`           | MySQL database name for Open edX.                                                                                                                                                                                                                                                                                               | `openedx`                                                                |                  |
| `OPENEDX_MYSQL_USERNAME`           | MySQL username for Open edX tables.                                                                                                                                                                                                                                                                                             | `openedx`                                                                |                  |
| `OPENEDX_MYSQL_PASSWORD`           | MySQL password for Open edX tables.                                                                                                                                                                                                                                                                                             | `none`                                                                   |                  |
| `RUN_MONGODB`                      | Whether to manage and launch MongoDB locally.                                                                                                                                                                                                                                                                                   | `true`                                                                   |                  |
| `MONGODB_HOST`                     | MongoDB server hostname or IP address.                                                                                                                                                                                                                                                                                          | `127.0.0.1`                                                              |                  |
| `MONGODB_PORT`                     | MongoDB server connection port.                                                                                                                                                                                                                                                                                                 | `27017`                                                                  |                  |
| `MONGODB_DATABASE`                 | MongoDB database name for course structures.                                                                                                                                                                                                                                                                                    | `openedx`                                                                |                  |
| `MONGODB_USERNAME`                 | MongoDB authentication username.                                                                                                                                                                                                                                                                                                | ``                                                                       |                  |
| `MONGODB_PASSWORD`                 | MongoDB authentication password.                                                                                                                                                                                                                                                                                                | ``                                                                       |                  |
| `MONGODB_AUTH_SOURCE`              | MongoDB database against which credentials are authenticated.                                                                                                                                                                                                                                                                   | `admin`                                                                  |                  |
| `MONGODB_AUTH_MECHANISM`           | MongoDB authentication mechanism.                                                                                                                                                                                                                                                                                               | ``                                                                       |                  |
| `MONGODB_REPLICA_SET`              | MongoDB replica set name if clustering is enabled.                                                                                                                                                                                                                                                                              | ``                                                                       |                  |
| `MONGODB_USE_SSL`                  | Whether TLS/SSL is required for MongoDB connections.                                                                                                                                                                                                                                                                            | `none`                                                                   |                  |
| `RUN_REDIS`                        | Whether to manage and launch Redis locally.                                                                                                                                                                                                                                                                                     | `true`                                                                   |                  |
| `REDIS_HOST`                       | Redis server hostname or IP address.                                                                                                                                                                                                                                                                                            | `127.0.0.1`                                                              |                  |
| `REDIS_PORT`                       | Redis server connection port.                                                                                                                                                                                                                                                                                                   | `6379`                                                                   |                  |
| `REDIS_USERNAME`                   | Redis authentication username.                                                                                                                                                                                                                                                                                                  | ``                                                                       |                  |
| `REDIS_PASSWORD`                   | Redis authentication password.                                                                                                                                                                                                                                                                                                  | ``                                                                       |                  |
| `OPENEDX_CACHE_REDIS_DB`           | Redis database index allocated for application caching.                                                                                                                                                                                                                                                                         | `1`                                                                      |                  |
| `OPENEDX_CELERY_REDIS_DB`          | Redis database index allocated for Celery task queuing.                                                                                                                                                                                                                                                                         | `0`                                                                      |                  |
| `RUN_MEILISEARCH`                  | Whether to manage and launch Meilisearch locally.                                                                                                                                                                                                                                                                               | `true`                                                                   |                  |
| `MEILISEARCH_HOST`                 | Meilisearch daemon hostname.                                                                                                                                                                                                                                                                                                    | `127.0.0.1`                                                              |                  |
| `MEILISEARCH_PORT`                 | Meilisearch daemon connection port.                                                                                                                                                                                                                                                                                             | `7700`                                                                   |                  |
| `MEILISEARCH_URL`                  | Meilisearch internal URL endpoint.                                                                                                                                                                                                                                                                                              | `http://127.0.0.1:7700`                                                  |                  |
| `MEILISEARCH_PUBLIC_URL`           | Meilisearch public URL endpoint.                                                                                                                                                                                                                                                                                                | `http://meilisearch.openedx.local`                                       |                  |
| `MEILISEARCH_INDEX_PREFIX`         | Prefix applied to all Meilisearch indexes.                                                                                                                                                                                                                                                                                      | `tutor_`                                                                 |                  |
| `MEILISEARCH_MASTER_KEY`           | Master authentication secret for Meilisearch daemon.                                                                                                                                                                                                                                                                            | `none`                                                                   |                  |
| `MEILISEARCH_API_KEY_UID`          | UUID identifying the default generated Meilisearch search API key.                                                                                                                                                                                                                                                              | `none`                                                                   |                  |
| `MEILISEARCH_API_KEY`              | API key for search queries against Meilisearch.                                                                                                                                                                                                                                                                                 | `none`                                                                   |                  |
| `RUN_SMTP`                         | Whether to run a local SMTP mail relay (Exim/hMailServer).                                                                                                                                                                                                                                                                      | `true`                                                                   |                  |
| `SMTP_HOST`                        | SMTP server hostname or IP address.                                                                                                                                                                                                                                                                                             | `127.0.0.1`                                                              |                  |
| `SMTP_PORT`                        | SMTP server connection port.                                                                                                                                                                                                                                                                                                    | `8025`                                                                   |                  |
| `SMTP_USERNAME`                    | SMTP server authentication username.                                                                                                                                                                                                                                                                                            | ``                                                                       |                  |
| `SMTP_PASSWORD`                    | SMTP server authentication password.                                                                                                                                                                                                                                                                                            | ``                                                                       |                  |
| `SMTP_USE_TLS`                     | Whether STARTTLS is enabled for outbound email.                                                                                                                                                                                                                                                                                 | `none`                                                                   |                  |
| `SMTP_USE_SSL`                     | Whether implicit SSL is enabled for outbound email.                                                                                                                                                                                                                                                                             | `none`                                                                   |                  |
| `OPENEDX_LMS_UWSGI_WORKERS`        | Number of worker processes for LMS WSGI service.                                                                                                                                                                                                                                                                                | `2`                                                                      |                  |
| `OPENEDX_CMS_UWSGI_WORKERS`        | Number of worker processes for CMS WSGI service.                                                                                                                                                                                                                                                                                | `2`                                                                      |                  |
| `PLUGINS`                          | Enabled Open edX and Tutor-compatible plugins.                                                                                                                                                                                                                                                                                  | `["mfe","indigo"]`                                                       |                  |
| `PLUGIN_INDEXES`                   | Plugin repository index URLs.                                                                                                                                                                                                                                                                                                   | `["https://overhang.io/tutor/main","https://overhang.io/tutor/contrib"]` |                  |
| `MOUNTS`                           | Local directory mounts bound to the application path.                                                                                                                                                                                                                                                                           | `[]`                                                                     |                  |

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->

## Windows Installer (.msi) & Visual Gallery

Open edX packages into a turnkey native Windows Installer (`.msi`) featuring express Simple Mode,
advanced DBaaS offloading, directory selection, runtime auto-detection, and multi-tab browser
verification.

### Building Open edX MSI via Pure-Rust `msi-rs`

LibScript compiles Windows Installers cross-platform (on macOS, Linux, and Windows) using the
pure-Rust `msi-rs` toolchain (`candle` and `light` drop-ins):

```sh
# 1. Source msi-rs environment
. _lib/package-managers/msi-rs/env.sh

# 2. Build lightweight online installer (< 10 MB)
./packaging/build_msi.sh stacks/cms/openedx \
  --online \
  --out dist/msi/OpenEdX-Setup \
  --version 22.1.0

# 3. Build air-gapped 100% offline installer with multi-cabinet caching
./packaging/build_msi.sh stacks/cms/openedx \
  --offline \
  --cache-dir cache/ \
  --out dist/msi/OpenEdX-Setup-Offline \
  --version 22.1.0
```

On Windows (`cmd.exe`):

```cmd
:: Load msi-rs environment
call _lib\package-managers\msi-rs\env.cmd

:: Build online installer
call packaging\build_msi.cmd stacks\cms\openedx --online --out dist\msi\OpenEdX-Setup --version 22.1.0

:: Build offline air-gapped installer
call packaging\build_msi.cmd stacks\cms\openedx --offline --cache-dir cache\ --out dist\msi\OpenEdX-Setup-Offline --version 22.1.0
```

Visual artifacts and gallery screenshots are centralized in the
[cc0-assets](https://github.com/SamuelMarks/cc0-assets) repository:

| Wizard Step          | Description                                                   | Preview                                                                                                                                                                                                                                                                                         |
| :------------------- | :------------------------------------------------------------ | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Welcome**          | Open edX branded welcome and prerequisite summary             | [![Welcome](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/01_simple_welcome.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/01_simple_welcome.png)                                          |
| **License**          | GNU AGPLv3 EULA terms acceptance                              | [![License](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/02_simple_license.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/02_simple_license.png)                                          |
| **Setup Type**       | Simple Mode (express install) vs Advanced Mode                | [![Setup Type](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/03_simple_setup_type.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/03_simple_setup_type.png)                                 |
| **Verify Ready**     | Simple Mode pre-installation component summary                | [![Verify Ready](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/04_simple_verify_ready.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/04_simple_verify_ready.png)                           |
| **Setup Complete**   | Simple Mode completion and browser launch triggers            | [![Setup Complete](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/05_simple_exit.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/05_simple_exit.png)                                         |
| **Advanced Mode**    | Advanced Mode radio selection with topology customization     | [![Advanced Mode](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/06_advanced_setup_type_selected.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/06_advanced_setup_type_selected.png)        |
| **Components**       | Custom component selection (LMS, CMS, MySQL, Redis, MFEs)     | [![Components](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/06a_advanced_features.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/06a_advanced_features.png)                               |
| **Destinations**     | Custom paths for binaries, datastores, logs, and backups      | [![Destinations](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/06b_advanced_install_location.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/06b_advanced_install_location.png)             |
| **Runtimes**         | Runtime environment selection (host vs isolated LibScript)    | [![Runtimes](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/06c_advanced_runtime_selection.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/06c_advanced_runtime_selection.png)               |
| **Source Repo**      | Build-time configured repository source and release branch    | [![Source Repo](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/06d_advanced_source_repo.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/06d_advanced_source_repo.png)                        |
| **Network Config**   | Service ports (8000/8001), superuser credentials, theme       | [![Network Config](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/06e_advanced_config.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/06e_advanced_config.png)                               |
| **Relational DB**    | MySQL port or external DBaaS (RDS / Azure / PlanetScale)      | [![Database](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/07_advanced_db.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/07_advanced_db.png)                                               |
| **Cache & Search**   | Redis, MongoDB Atlas, and Meilisearch endpoints               | [![Cache Search](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/08_advanced_cache_search.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/08_advanced_cache_search.png)                       |
| **Verify Ready**     | Advanced pre-installation summary review                      | [![Verify Ready](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/09_advanced_verify_ready.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/09_advanced_verify_ready.png)                       |
| **Setup Complete**   | Advanced Mode installation completion screen                  | [![Setup Complete](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/10_advanced_exit.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/10_advanced_exit.png)                                     |
| **Desktop Icons**    | Branded desktop shortcuts for LMS, Studio, and Console        | [![Desktop Icons](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/10b_desktop_icons.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/10b_desktop_icons.png)                                    |
| **LMS Portal**       | Open edX LMS Web Application (`:8000/login`)                  | [![LMS Focused](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/11_browser_lms_focused.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/11_browser_lms_focused.png)                            |
| **Studio CMS**       | Open edX Studio Course Authoring (`:8001/signin`)             | [![Studio Focused](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/12_browser_studio_focused.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/12_browser_studio_focused.png)                   |
| **LMS Dashboard**    | Authenticated Learner / Instructor Portal (`:8000/dashboard`) | [![LMS Authenticated](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/13_browser_lms_authenticated.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/13_browser_lms_authenticated.png)          |
| **Studio Dashboard** | Authenticated Authoring & Course Catalog (`:8001/home`)       | [![Studio Authenticated](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/14_browser_studio_authenticated.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/14_browser_studio_authenticated.png) |
