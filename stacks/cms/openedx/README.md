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

| Variable                          | Description                                                                       | Default                                           | Aliases/Examples |
| --------------------------------- | --------------------------------------------------------------------------------- | ------------------------------------------------- | ---------------- |
| `OPENEDX_VERSION`                 | Open edX release or git branch (e.g., 'master', 'open-release/quince.master').    | `master`                                          |                  |
| `OPENEDX_EDX_PLATFORM_REPOSITORY` | Git repository URL for openedx-platform.                                          | `https://github.com/openedx/openedx-platform.git` |                  |
| `LMS_HOST`                        | Public domain/host for LMS web interface.                                         | `openedx.local`                                   |                  |
| `CMS_HOST`                        | Public domain/host for Studio / CMS authoring interface.                          | `studio.openedx.local`                            |                  |
| `LMS_PORT`                        | Internal HTTP port for LMS WSGI server.                                           | `8000`                                            |                  |
| `CMS_PORT`                        | Internal HTTP port for CMS WSGI server.                                           | `8001`                                            |                  |
| `OPENEDX_ADMIN_EMAIL`             | Administrator email address.                                                      | `admin@openedx.local`                             |                  |
| `OPENEDX_ADMIN_USERNAME`          | Administrator username.                                                           | `admin`                                           |                  |
| `OPENEDX_ADMIN_PASSWORD`          | Administrator initial password.                                                   | `admin`                                           |                  |
| `OPENEDX_SECRET_KEY`              | Secret key for Django sessions and token encryption.                              | `insecure-secret-key-replace-in-production`       |                  |
| `OPENEDX_WSGI_WORKERS`            | Number of WSGI worker processes.                                                  | `2`                                               |                  |
| `OPENEDX_BACKUP_DIR`              | Directory where backup archives are generated.                                    | `C:\ProgramData\OpenEdX\backups`                  |                  |
| `OPENEDX_THEME`                   | Active Comprehensive Theme name for LMS and Studio.                               | `none`                                            |                  |
| `OPENEDX_THEME_REPO_URL`          | Git repository URL of custom Comprehensive Theme.                                 | `none`                                            |                  |
| `OPENEDX_INSTALL_DIR`             | Directory where openedx-platform is checked out and deployed.                     | `none`                                            |                  |
| `OPENEDX_IMPORT_DEMO_COURSE`      | Whether to import the edX demo course during setup.                               | `none`                                            |                  |
| `OPENEDX_IMPORT_DEMO_LIBRARIES`   | Whether to import demo content libraries during setup.                            | `none`                                            |                  |
| `OPENEDX_ENABLE_WORKERS`          | Whether to enable and launch Celery background workers.                           | `true`                                            |                  |
| `OPENEDX_ENABLE_CELERY_BEAT`      | Whether to enable Celery Beat periodic task scheduler.                            | `true`                                            |                  |
| `OPENEDX_ENABLE_MFES`             | Whether to build and route Micro-Frontends (Learning, Authn, Account, Authoring). | `none`                                            |                  |
| `OPENEDX_MFE_LEARNING_PORT`       | HTTP port for Learning Micro-Frontend.                                            | `2000`                                            |                  |
| `OPENEDX_MFE_AUTHN_PORT`          | HTTP port for Authentication Micro-Frontend.                                      | `2001`                                            |                  |
| `OPENEDX_MFE_ACCOUNT_PORT`        | HTTP port for Account Micro-Frontend.                                             | `2002`                                            |                  |
| `OPENEDX_MFE_AUTHORING_PORT`      | HTTP port for Course Authoring Micro-Frontend.                                    | `2003`                                            |                  |

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

Visual artifacts and gallery screenshots are centralized in the
[cc0-assets](https://github.com/SamuelMarks/cc0-assets) repository:

| Wizard Step        | Description                                                | Preview                                                                                                                                                                                                                                                                                  |
| :----------------- | :--------------------------------------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Welcome**        | Open edX branded welcome and prerequisite summary          | [![Welcome](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/01_simple_welcome.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/01_simple_welcome.png)                                   |
| **License**        | GNU AGPLv3 EULA terms acceptance                           | [![License](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/02_simple_license.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/02_simple_license.png)                                   |
| **Setup Type**     | Simple Mode (express install) vs Advanced Mode             | [![Setup Type](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/03_simple_setup_type.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/03_simple_setup_type.png)                          |
| **Verify Ready**   | Simple Mode pre-installation component summary             | [![Verify Ready](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/04_simple_verify_ready.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/04_simple_verify_ready.png)                    |
| **Setup Complete** | Simple Mode completion and browser launch triggers         | [![Setup Complete](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/05_simple_exit.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/05_simple_exit.png)                                  |
| **Advanced Mode**  | Advanced Mode radio selection with topology customization  | [![Advanced Mode](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/06_advanced_setup_type_selected.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/06_advanced_setup_type_selected.png) |
| **Components**     | Custom component selection (LMS, CMS, MySQL, Redis, MFEs)  | [![Components](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/06a_advanced_features.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/06a_advanced_features.png)                        |
| **Destinations**   | Custom paths for binaries, datastores, logs, and backups   | [![Destinations](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/06b_advanced_install_location.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/06b_advanced_install_location.png)      |
| **Runtimes**       | Runtime environment selection (host vs isolated LibScript) | [![Runtimes](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/06c_advanced_runtime_selection.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/06c_advanced_runtime_selection.png)        |
| **Source Repo**    | Build-time configured repository source and release branch | [![Source Repo](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/06d_advanced_source_repo.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/06d_advanced_source_repo.png)                 |
| **Network Config** | Service ports (8000/8001), superuser credentials, theme    | [![Network Config](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/06e_advanced_config.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/06e_advanced_config.png)                        |
| **Relational DB**  | MySQL port or external DBaaS (RDS / Azure / PlanetScale)   | [![Database](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/07_advanced_db.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/07_advanced_db.png)                                        |
| **Cache & Search** | Redis, MongoDB Atlas, and Meilisearch endpoints            | [![Cache Search](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/08_advanced_cache_search.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/08_advanced_cache_search.png)                |
| **Verify Ready**   | Advanced pre-installation summary review                   | [![Verify Ready](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/09_advanced_verify_ready.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/09_advanced_verify_ready.png)                |
| **Setup Complete** | Advanced Mode installation completion screen               | [![Setup Complete](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/10_advanced_exit.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/10_advanced_exit.png)                              |
| **Desktop Icons**  | Branded desktop shortcuts for LMS, Studio, and Console     | [![Desktop Icons](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/10b_desktop_icons.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/10b_desktop_icons.png)                             |
| **LMS Portal**     | Open edX LMS Web Application (`:8000/login`)               | [![LMS Focused](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/11_browser_lms_focused.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/11_browser_lms_focused.png)                     |
| **Studio CMS**     | Open edX Studio Course Authoring (`:8001/signin`)          | [![Studio Focused](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/12_browser_studio_focused.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/12_browser_studio_focused.png)            |
