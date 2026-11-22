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
./libscript.sh install workloads/apps/openedx
```

### Windows (`cmd.exe`)

```cmd
call libscript.cmd install workloads\apps\openedx
```

---

## Tutor Parity CLI Command Reference

LibScript provides host-native commands achieving full functional parity with
[Tutor](https://github.com/overhangio/tutor), adapted to native host execution, bare-metal runtime
provisioning, and Windows MSI architecture.

Commands can be invoked through the unified stack router (`workloads/apps/openedx/cli.sh` /
`cli.cmd`), or via individual submodules.

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
./workloads/apps/openedx/cli.sh user create alice alice@example.com --password "SecretPass123"

# Create staff user or superuser
./workloads/apps/openedx/cli.sh user create admin admin@example.com --password "AdminPass123" --superuser

# Interactive password prompt (when --password omitted in interactive TTY)
./workloads/apps/openedx/cli.sh user create bob bob@example.com --staff

# Update existing user's password
./workloads/apps/openedx/cli.sh user set_password alice "NewSecurePass456"

# List all registered accounts and permission roles
./workloads/apps/openedx/cli.sh user list
```

#### Windows

```cmd
:: Create standard user
call workloads\apps\openedx\cli.cmd user create alice alice@example.com --password "SecretPass123"

:: Create superuser
call workloads\apps\openedx\cli.cmd user create admin admin@example.com --password "AdminPass123" --superuser

:: Reset user password
call workloads\apps\openedx\cli.cmd user set_password alice "NewSecurePass456"

:: List accounts
call workloads\apps\openedx\cli.cmd user list
```

---

### 2. Demo Course & Content Library Ingestion (`demo`)

_Tutor Equivalent: `tutor do importdemocourse`, `tutor do importdemolibraries`_

Idempotently downloads and imports demonstration courses and component libraries into the Studio
course store and LMS database. If a course ID is already present, the import is cleanly skipped.

#### POSIX

```sh
# Ingest official edX Demo Course (course-v1:edX+DemoX+Demo_Course)
./workloads/apps/openedx/cli.sh demo course

# Ingest custom course from repository
./workloads/apps/openedx/cli.sh demo course --course-id "course-v1:MyOrg+CS101+2026" --repo "https://github.com/my-org/cs101-course.git"

# Ingest demonstration component libraries into Studio
./workloads/apps/openedx/cli.sh demo libraries --owner admin
```

#### Windows

```cmd
:: Ingest standard demo course
call workloads\apps\openedx\cli.cmd demo course

:: Ingest demo libraries
call workloads\apps\openedx\cli.cmd demo libraries --owner admin
```

---

### 3. Database Shell Wrappers (`dbshell`)

_Tutor Equivalent: `tutor do sqlshell`, `tutor do mongosh`_

Provides direct interactive and non-interactive access to all Open edX storage backends using
configured stack credentials and endpoints.

#### POSIX

```sh
# Launch interactive MySQL client
./workloads/apps/openedx/cli.sh dbshell mysql

# Execute a single SQL query non-interactively
./workloads/apps/openedx/cli.sh dbshell query "SELECT id, username, email, is_staff FROM auth_user LIMIT 10;"

# Connect to MongoDB database
./workloads/apps/openedx/cli.sh dbshell mongo
# Or using the direct alias:
./workloads/apps/openedx/cli.sh mongosh

# Connect to Redis CLI
./workloads/apps/openedx/cli.sh dbshell redis
# Or using the direct alias:
./workloads/apps/openedx/cli.sh redis-cli
```

#### Windows

```cmd
:: Interactive MySQL
call workloads\apps\openedx\cli.cmd dbshell mysql

:: Non-interactive SQL query
call workloads\apps\openedx\cli.cmd dbshell query "SELECT COUNT(*) FROM auth_user;"

:: Interactive Mongo & Redis
call workloads\apps\openedx\cli.cmd mongosh
call workloads\apps\openedx\cli.cmd redis-cli
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
./workloads/apps/openedx/cli.sh healthcheck

# Machine-readable JSON output (ideal for monitoring & CI probes)
./workloads/apps/openedx/cli.sh healthcheck --json
```

#### Windows

```cmd
:: Health diagnostics report
call workloads\apps\openedx\cli.cmd healthcheck

:: JSON diagnostics
call workloads\apps\openedx\cli.cmd healthcheck --json
```

---

### 5. Configuration Engine (`config`)

_Tutor Equivalent: `tutor config save`, `tutor config printvalue`_

Manages `config/lms.env.json` and `config/cms.env.json` idempotently. Supports nested dot-notation
paths, deep merging, and schema validation against `vars.schema.json`.

#### POSIX

```sh
# Synthesize default configuration files (preserving existing overrides)
./workloads/apps/openedx/cli.sh config generate

# Read configuration setting (supports nested keys)
./workloads/apps/openedx/cli.sh config get LMS_HOST
./workloads/apps/openedx/cli.sh config get DATABASES.default.HOST

# Update configuration key
./workloads/apps/openedx/cli.sh config set SITE_NAME "My University Open edX"
./workloads/apps/openedx/cli.sh config set LMS_HOST "courses.myuni.edu"

# View complete JSON configuration
./workloads/apps/openedx/cli.sh config list

# Validate configuration against schema
./workloads/apps/openedx/cli.sh config validate
```

#### Windows

```cmd
:: Generate configurations
call workloads\apps\openedx\cli.cmd config generate

:: Read / write keys
call workloads\apps\openedx\cli.cmd config get LMS_HOST
call workloads\apps\openedx\cli.cmd config set SITE_NAME "My University Open edX"

:: Schema validation
call workloads\apps\openedx\cli.cmd config validate
```

---

### 6. Backup & Disaster Recovery (`backup`, `restore`)

_Tutor Equivalent: `tutor backup`, `tutor restore`_

Produces consolidated state snapshots containing relational SQL dumps, MongoDB collections, user
media uploads (`media/`), and configuration files, verified by SHA-256 checksums.

#### POSIX

```sh
# Create full timestamped snapshot
./workloads/apps/openedx/cli.sh backup create

# Create snapshot with custom target archive path
./workloads/apps/openedx/cli.sh backup create --out "/var/backups/openedx-weekly.tar.gz"

# List available backup archives
./workloads/apps/openedx/cli.sh backup list

# Restore system state from backup archive
./workloads/apps/openedx/cli.sh restore apply "/var/backups/openedx-weekly.tar.gz" --yes
```

#### Windows

```cmd
:: Create backup snapshot (.zip format on Windows)
call workloads\apps\openedx\cli.cmd backup create

:: List backups
call workloads\apps\openedx\cli.cmd backup list

:: Restore from backup
call workloads\apps\openedx\cli.cmd restore apply "%USERPROFILE%\.libscript\openedx\backups\openedx_backup_20260920_125652.zip" --yes
```

---

### 7. Background Workers & Beat Scheduler (`workers`)

_Tutor Equivalent: Compose worker & beat service containers_

Controls Celery asynchronous worker processes (`lms-worker`, `cms-worker`) and the Celery Beat
periodic task scheduler, maintaining PID files in `run/` and daemon logs in `logs/`.

#### POSIX

```sh
# Launch background workers
./workloads/apps/openedx/cli.sh workers start

# Inspect worker status and active PIDs
./workloads/apps/openedx/cli.sh workers status

# Restart workers
./workloads/apps/openedx/cli.sh workers restart

# Stop all background workers
./workloads/apps/openedx/cli.sh workers stop
```

#### Windows

```cmd
:: Start background worker processes
call workloads\apps\openedx\cli.cmd workers start

:: Check status
call workloads\apps\openedx\cli.cmd workers status

:: Stop workers
call workloads\apps\openedx\cli.cmd workers stop
```

---

### 8. Theming & Branding Engine (`theme`)

_Tutor Equivalent: `tutor do settheme`_

Manages comprehensive themes for LMS and Studio interfaces, handling Git checkout, SCSS compilation,
asset bundling, and Django site configuration binding.

#### POSIX

```sh
# Install theme from Git repository
./workloads/apps/openedx/cli.sh theme install indigo https://github.com/openedx/openedx-theme-indigo.git --branch master

# Compile SCSS and static assets for theme
./workloads/apps/openedx/cli.sh theme build indigo

# Bind theme to Open edX site domain
./workloads/apps/openedx/cli.sh theme apply indigo --site "openedx.local"

# List installed themes and active status
./workloads/apps/openedx/cli.sh theme list

# Remove an installed theme
./workloads/apps/openedx/cli.sh theme remove indigo
```

#### Windows

```cmd
:: Install and build theme
call workloads\apps\openedx\cli.cmd theme install indigo https://github.com/openedx/openedx-theme-indigo.git
call workloads\apps\openedx\cli.cmd theme build indigo

:: Apply theme to site
call workloads\apps\openedx\cli.cmd theme apply indigo --site "openedx.local"

:: List themes
call workloads\apps\openedx\cli.cmd theme list
```

---

### 9. XBlock & Stack Plugin Extensibility (`xblock`)

_Tutor Equivalent: `tutor plugins install`_

Extends Open edX with custom XBlocks and plugins. Automatically handles virtualenv package
installation, database migrations, and static asset collection.

#### POSIX

```sh
# Install XBlock from PyPI or Git repository
./workloads/apps/openedx/cli.sh xblock install xblock-drag-and-drop-v2
./workloads/apps/openedx/cli.sh xblock install git+https://github.com/edx/xblock-google-drive.git

# List discovered XBlocks via entry point metadata
./workloads/apps/openedx/cli.sh xblock list

# Uninstall XBlock
./workloads/apps/openedx/cli.sh xblock uninstall xblock-drag-and-drop-v2
```

#### Windows

```cmd
:: Install XBlock
call workloads\apps\openedx\cli.cmd xblock install xblock-drag-and-drop-v2

:: List XBlocks
call workloads\apps\openedx\cli.cmd xblock list

:: Uninstall XBlock
call workloads\apps\openedx\cli.cmd xblock uninstall xblock-drag-and-drop-v2
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
./workloads/apps/openedx/cli.sh upgrade run --to open-release/quince.master
```

#### Windows

```cmd
:: Run upgrade pipeline
call workloads\apps\openedx\cli.cmd upgrade run --to open-release/quince.master
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
./workloads/apps/openedx/cli.sh mfe build learning --version master

# Deploy MFE dist and generate runtime env.config.js
./workloads/apps/openedx/cli.sh mfe deploy learning

# List managed MFEs and build/deployment status
./workloads/apps/openedx/cli.sh mfe list
```

#### Windows

```cmd
:: Build and deploy MFE
call workloads\apps\openedx\cli.cmd mfe build learning
call workloads\apps\openedx\cli.cmd mfe deploy learning

:: List MFEs
call workloads\apps\openedx\cli.cmd mfe list
```

---

## Configuration Options

<!-- BEGIN_VARS -->

| Variable                          | Description                                                                                                              | Default                                                                  | Aliases/Examples |
| --------------------------------- | ------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------ | ---------------- |
| `OPENEDX_INSTALL_MODE`            | Deployment mode for the Open edX installation (minimal, production, dev, or offline).                                    | `minimal`                                                                |                  |
| `OPENEDX_ROLE`                    | Single-process workload role staged into a Tier 2 unikernel or appliance sysroot (all, lms, cms, celery, or mfe-static). | `all`                                                                    |                  |
| `OPENEDX_RELEASE`                 | Open edX release branch or tag to install (e.g., release/verawood.1, release/verawood, master).                          | `release/verawood.1`                                                     |                  |
| `OPENEDX_GIT_REPO`                | Git repository URL for cloning or updating the openedx-platform source code.                                             | `https://github.com/openedx/openedx-platform.git`                        |                  |
| `PLATFORM_NAME`                   | Public display name of the Open edX learning platform.                                                                   | `My Open edX`                                                            |                  |
| `CONTACT_EMAIL`                   | Public contact and support email address for the Open edX platform.                                                      | `contact@openedx.local`                                                  |                  |
| `LANGUAGE_CODE`                   | Default ISO 639-1 language code for the Open edX platform.                                                               | `en`                                                                     |                  |
| `LMS_HOST`                        | Domain name or hostname for the LMS (Learning Management System).                                                        | `openedx.local`                                                          |                  |
| `CMS_HOST`                        | Domain name or hostname for Studio/CMS.                                                                                  | `studio.openedx.local`                                                   |                  |
| `PREVIEW_LMS_HOST`                | Domain name or hostname for course preview mode in the LMS.                                                              | `preview.openedx.local`                                                  |                  |
| `MFE_HOST`                        | Domain name or hostname serving Micro-Frontend (MFE) single-page applications.                                           | `apps.openedx.local`                                                     |                  |
| `LMS_PORT`                        | HTTP port for the LMS application server.                                                                                | `8000`                                                                   |                  |
| `CMS_PORT`                        | HTTP port for the Studio/CMS application server.                                                                         | `8001`                                                                   |                  |
| `CADDY_HTTP_PORT`                 | HTTP port bound by the Caddy reverse proxy.                                                                              | `80`                                                                     |                  |
| `ENABLE_HTTPS`                    | Whether to enable HTTPS / TLS termination on public Open edX URLs.                                                       | `none`                                                                   |                  |
| `ENABLE_WEB_PROXY`                | Whether Caddy should act as the primary reverse proxy and TLS terminator.                                                | `true`                                                                   |                  |
| `ENABLE_CORS_CREDENTIALS`         | Whether cross-origin requests with credentials are permitted across LMS, Studio, and MFE domains.                        | `true`                                                                   |                  |
| `CORS_ORIGIN_WHITELIST`           | List of additional origin URLs allowed to perform cross-origin requests against LMS and CMS.                             | `none`                                                                   |                  |
| `RUN_LMS`                         | Whether to run the LMS web application service locally.                                                                  | `true`                                                                   |                  |
| `RUN_CMS`                         | Whether to run the Studio/CMS web application service locally.                                                           | `true`                                                                   |                  |
| `RUN_LMS_WORKER`                  | Whether to run the LMS Celery background worker locally.                                                                 | `true`                                                                   |                  |
| `RUN_CMS_WORKER`                  | Whether to run the Studio/CMS Celery background worker locally.                                                          | `true`                                                                   |                  |
| `RUN_CADDY`                       | Whether to run the local Caddy web proxy service.                                                                        | `true`                                                                   |                  |
| `RUN_MYSQL`                       | Whether to provision and run a local MySQL database instance.                                                            | `true`                                                                   |                  |
| `RUN_MONGODB`                     | Whether to provision and run a local MongoDB database instance.                                                          | `true`                                                                   |                  |
| `RUN_REDIS`                       | Whether to provision and run a local Redis cache and message broker instance.                                            | `true`                                                                   |                  |
| `RUN_MEILISEARCH`                 | Whether to provision and run a local Meilisearch search engine instance.                                                 | `true`                                                                   |                  |
| `RUN_SMTP`                        | Whether to provision and run a local SMTP mail transfer agent.                                                           | `true`                                                                   |                  |
| `RUN_MINIO`                       | Whether to provision and run a local MinIO S3-compatible object storage service.                                         | `none`                                                                   |                  |
| `RUN_MFE`                         | Whether to build and serve Micro-Frontend (MFE) applications.                                                            | `true`                                                                   |                  |
| `MYSQL_HOST`                      | Hostname or IP address of the MySQL database server.                                                                     | `127.0.0.1`                                                              |                  |
| `MYSQL_PORT`                      | TCP port of the MySQL database server.                                                                                   | `3306`                                                                   |                  |
| `MYSQL_ROOT_USERNAME`             | Administrative root username for MySQL database provisioning.                                                            | `root`                                                                   |                  |
| `MYSQL_ROOT_PASSWORD`             | Administrative root password for MySQL database provisioning.                                                            | ``                                                                       |                  |
| `OPENEDX_MYSQL_DATABASE`          | Name of the MySQL database schema used by Open edX.                                                                      | `openedx`                                                                |                  |
| `OPENEDX_MYSQL_USERNAME`          | MySQL application username for Open edX.                                                                                 | `openedx`                                                                |                  |
| `OPENEDX_MYSQL_PASSWORD`          | MySQL application password for Open edX.                                                                                 | ``                                                                       |                  |
| `MONGODB_HOST`                    | Hostname or SRV connection string of the MongoDB server.                                                                 | `127.0.0.1`                                                              |                  |
| `MONGODB_PORT`                    | TCP port of the MongoDB server.                                                                                          | `27017`                                                                  |                  |
| `MONGODB_USERNAME`                | MongoDB authentication username for Open edX modulestore.                                                                | ``                                                                       |                  |
| `MONGODB_PASSWORD`                | MongoDB authentication password for Open edX modulestore.                                                                | ``                                                                       |                  |
| `MONGODB_DATABASE`                | Name of the MongoDB database used for course modulestore.                                                                | `openedx`                                                                |                  |
| `MONGODB_AUTH_SOURCE`             | MongoDB authentication database source.                                                                                  | `admin`                                                                  |                  |
| `REDIS_HOST`                      | Hostname or IP address of the Redis server.                                                                              | `127.0.0.1`                                                              |                  |
| `REDIS_PORT`                      | TCP port of the Redis server.                                                                                            | `6379`                                                                   |                  |
| `REDIS_USERNAME`                  | Optional ACL username for authenticating with Redis.                                                                     | ``                                                                       |                  |
| `REDIS_PASSWORD`                  | Optional password for authenticating with Redis.                                                                         | ``                                                                       |                  |
| `REDIS_DATABASE`                  | Redis logical database index used by Open edX cache and Celery.                                                          | `0`                                                                      |                  |
| `MEILISEARCH_HOST`                | Public hostname for the Meilisearch search service.                                                                      | `meilisearch.openedx.local`                                              |                  |
| `MEILISEARCH_PORT`                | TCP port for the Meilisearch search service.                                                                             | `7700`                                                                   |                  |
| `MEILISEARCH_API_KEY`             | Master API key used to authenticate against Meilisearch.                                                                 | ``                                                                       |                  |
| `MEILISEARCH_URL`                 | Internal URL used by LMS and Studio to connect to Meilisearch.                                                           | `http://127.0.0.1:7700`                                                  |                  |
| `MEILISEARCH_PUBLIC_URL`          | Publicly accessible URL for Meilisearch queries from browser clients.                                                    | `http://meilisearch.openedx.local`                                       |                  |
| `MINIO_HOST`                      | Hostname for MinIO S3-compatible object storage.                                                                         | `files.openedx.local`                                                    |                  |
| `MINIO_PORT`                      | TCP port for MinIO S3 API.                                                                                               | `9000`                                                                   |                  |
| `MINIO_ACCESS_KEY`                | Access key ID for MinIO or S3 storage.                                                                                   | `openedx`                                                                |                  |
| `MINIO_SECRET_KEY`                | Secret access key for MinIO or S3 storage.                                                                               | ``                                                                       |                  |
| `OPENEDX_AWS_S3_STORAGE`          | Whether to store media, staticgrades, and course exports on S3/MinIO object storage.                                     | `none`                                                                   |                  |
| `SMTP_HOST`                       | SMTP server hostname for outbound transactional emails.                                                                  | `127.0.0.1`                                                              |                  |
| `SMTP_PORT`                       | SMTP server port for outbound transactional emails.                                                                      | `25`                                                                     |                  |
| `SMTP_USERNAME`                   | Username for authenticating with the outbound SMTP server.                                                               | ``                                                                       |                  |
| `SMTP_PASSWORD`                   | Password for authenticating with the outbound SMTP server.                                                               | ``                                                                       |                  |
| `SMTP_USE_TLS`                    | Whether to use STARTTLS when connecting to the SMTP server.                                                              | `none`                                                                   |                  |
| `SMTP_USE_SSL`                    | Whether to use implicit SSL/TLS when connecting to the SMTP server.                                                      | `none`                                                                   |                  |
| `OPENEDX_ADMIN_USERNAME`          | Default superuser username created during platform initialization.                                                       | `admin`                                                                  |                  |
| `OPENEDX_ADMIN_EMAIL`             | Default superuser email address created during platform initialization.                                                  | `admin@example.com`                                                      |                  |
| `OPENEDX_ADMIN_PASSWORD`          | Default superuser password created during platform initialization.                                                       | `admin`                                                                  |                  |
| `OPENEDX_SECRET_KEY`              | Cryptographic secret key used by Django for signing sessions and tokens.                                                 | `openedx-default-secret-key-change-in-prod`                              |                  |
| `JWT_RSA_PRIVATE_KEY`             | PEM-encoded RSA private key used to sign Open edX JWT authentication tokens.                                             | ``                                                                       |                  |
| `CMS_OAUTH2_KEY`                  | Internal OAuth2 client key used by Studio to communicate with LMS.                                                       | `cms`                                                                    |                  |
| `CMS_OAUTH2_SECRET`               | OAuth2 client secret shared between LMS and Studio.                                                                      | `openedx-cms-oauth2-secret`                                              |                  |
| `CMS_OAUTH2_KEY_SSO`              | Production OAuth2 client key for browser single sign-on (SSO) into Studio.                                               | `cms-sso`                                                                |                  |
| `CMS_OAUTH2_KEY_DEV`              | Development OAuth2 client key for Studio.                                                                                | `cms-dev`                                                                |                  |
| `CMS_OAUTH2_KEY_SSO_DEV`          | Development OAuth2 client key for browser single sign-on (SSO) into Studio.                                              | `cms-sso-dev`                                                            |                  |
| `OPENEDX_LMS_UWSGI_WORKERS`       | Number of Gunicorn / WSGI worker processes for the LMS service.                                                          | `2`                                                                      |                  |
| `OPENEDX_CMS_UWSGI_WORKERS`       | Number of Gunicorn / WSGI worker processes for the Studio/CMS service.                                                   | `2`                                                                      |                  |
| `LMS_CELERY_WORKERS`              | Concurrency level for LMS Celery background workers.                                                                     | `1`                                                                      |                  |
| `CMS_CELERY_WORKERS`              | Concurrency level for Studio/CMS Celery background workers.                                                              | `1`                                                                      |                  |
| `CELERY_BROKER_KIND`              | Message broker backend used for Celery asynchronous task queues.                                                         | `redis`                                                                  |                  |
| `OPENEDX_THEME`                   | Active comprehensive theme applied to LMS and Studio (e.g., indigo, default).                                            | `indigo`                                                                 |                  |
| `OPENEDX_EXTRA_PIP_REQUIREMENTS`  | Additional Python packages and XBlocks to install into the Open edX virtual environment.                                 | `none`                                                                   |                  |
| `PLUGINS`                         | Enabled Tutor-compatible Open edX plugins.                                                                               | `["mfe","indigo"]`                                                       |                  |
| `PLUGIN_INDEXES`                  | Remote plugin index URLs for discovering and installing Open edX plugins.                                                | `["https://overhang.io/tutor/main","https://overhang.io/tutor/contrib"]` |                  |
| `MOUNTS`                          | Local host directory bind mounts linked into the Open edX application and MFE paths.                                     | `none`                                                                   |                  |
| `PATCHES`                         | Dictionary mapping Tutor patch slot names (e.g., openedx-common-settings, lms-env, caddyfile) to custom snippet strings. | `{}`                                                                     |                  |
| `OPENEDX_BACKUP_DIR`              | Filesystem directory or path configuration for openedx (OPENEDX_BACKUP_DIR).                                             | `none`                                                                   |                  |
| `OPENEDX_CMS_PORT`                | TCP port on which openedx listens.                                                                                       | `none`                                                                   |                  |
| `OPENEDX_DATABASE_PASSWORD`       | Configuration variable OPENEDX_DATABASE_PASSWORD for openedx.                                                            | `none`                                                                   |                  |
| `OPENEDX_EDX_PLATFORM_REPOSITORY` | Configuration variable OPENEDX_EDX_PLATFORM_REPOSITORY for openedx.                                                      | `none`                                                                   |                  |
| `OPENEDX_INSTALL_DIR`             | Filesystem directory or path configuration for openedx (OPENEDX_INSTALL_DIR).                                            | `none`                                                                   |                  |
| `OPENEDX_DATA_DIR`                | Filesystem directory where Open edX databases, courseware, and mutable state are stored.                                 | `none`                                                                   |                  |
| `OPENEDX_LOG_DIR`                 | Filesystem directory where Open edX service and installation logs are written.                                           | `none`                                                                   |                  |
| `OPENEDX_LMS_DOMAIN`              | Public domain and optional port for the Open edX LMS.                                                                    | `none`                                                                   |                  |
| `OPENEDX_CMS_DOMAIN`              | Public domain and optional port for Open edX Studio CMS.                                                                 | `none`                                                                   |                  |
| `OPENEDX_LMS_PORT`                | TCP port on which openedx listens.                                                                                       | `none`                                                                   |                  |
| `OPENEDX_OFFLINE`                 | Configuration variable OPENEDX_OFFLINE for openedx.                                                                      | `none`                                                                   |                  |
| `OPENEDX_VERSION`                 | Specific version of openedx to install (e.g., latest, lts, or exact version).                                            | `none`                                                                   |                  |
| `LIBSCRIPT_FOLDER`                | Filesystem directory where the bundled LibScript engine and offline cache are installed by the Windows MSI.              | `none`                                                                   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
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
./synthesis/msi/build_msi.sh workloads/apps/openedx \
  --online \
  --out dist/msi/OpenEdX-Setup \
  --version 22.1.0

# 3. Build air-gapped 100% offline installer with multi-cabinet caching
./synthesis/msi/build_msi.sh workloads/apps/openedx \
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
call synthesis\msi\build_msi.cmd workloads\apps\openedx --online --out dist\msi\OpenEdX-Setup --version 22.1.0

:: Build offline air-gapped installer
call synthesis\msi\build_msi.cmd workloads\apps\openedx --offline --cache-dir cache\ --out dist\msi\OpenEdX-Setup-Offline --version 22.1.0
```

Visual artifacts and gallery screenshots are centralized in the
[cc0-assets](https://github.com/SamuelMarks/cc0-assets/tree/master/libscript/openedx/screenshots)
repository (see [`SCREENSHOTS.md`](./SCREENSHOTS.md) for the complete multi-OS walkthrough across
[Windows](https://github.com/SamuelMarks/cc0-assets/tree/master/libscript/openedx/screenshots/windows),
[Linux](https://github.com/SamuelMarks/cc0-assets/tree/master/libscript/openedx/screenshots/linux),
[macOS](https://github.com/SamuelMarks/cc0-assets/tree/master/libscript/openedx/screenshots/macos),
[FreeBSD](https://github.com/SamuelMarks/cc0-assets/tree/master/libscript/openedx/screenshots/freebsd),
and
[illumos / OmniOS](https://github.com/SamuelMarks/cc0-assets/tree/master/libscript/openedx/screenshots/illumos)):

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
