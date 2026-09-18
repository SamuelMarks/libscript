# Open edX Stack

Full turnkey deployment for the Open edX LMS (Learning Management System) and Studio/CMS course
authoring environment.

## Overview

The `openedx` stack orchestrates the end-to-end topology for Open edX, provisioning and managing:

- **Application Services**: Open edX LMS & Studio/CMS via Python 3.12, Django 5.2, and Gunicorn /
  uWSGI
- **Background Workers**: Celery async workers (`lms-worker`, `cms-worker`) and Celery Beat
  scheduler
- **Relational Storage**: MySQL 8.x (InnoDB utf8mb4 collation)
- **Document Storage**: MongoDB 7.x
- **Cache & Message Broker**: Redis 7.x (or Valkey)
- **Full-Text Search**: Meilisearch v1.36.0 (or Elasticsearch)
- **Mail Relay**: Exim local SMTP relay
- **Reverse Proxy / Ingress**: Caddy or Nginx with automated routing via `netctl`

## Usage

```sh
./libscript.sh install stacks/cms/openedx
```

## Configuration Options

<!-- BEGIN_VARS -->

| Variable                          | Description                                                                    | Default                                           | Aliases/Examples |
| --------------------------------- | ------------------------------------------------------------------------------ | ------------------------------------------------- | ---------------- |
| `OPENEDX_VERSION`                 | Open edX release or git branch (e.g., 'master', 'open-release/quince.master'). | `master`                                          |                  |
| `OPENEDX_EDX_PLATFORM_REPOSITORY` | Git repository URL for openedx-platform.                                       | `https://github.com/openedx/openedx-platform.git` |                  |
| `LMS_HOST`                        | Public domain/host for LMS web interface.                                      | `openedx.local`                                   |                  |
| `CMS_HOST`                        | Public domain/host for Studio / CMS authoring interface.                       | `studio.openedx.local`                            |                  |
| `LMS_PORT`                        | Internal HTTP port for LMS WSGI server.                                        | `8000`                                            |                  |
| `CMS_PORT`                        | Internal HTTP port for CMS WSGI server.                                        | `8001`                                            |                  |
| `OPENEDX_ADMIN_EMAIL`             | Administrator email address.                                                   | `admin@openedx.local`                             |                  |
| `OPENEDX_ADMIN_USERNAME`          | Administrator username.                                                        | `admin`                                           |                  |
| `OPENEDX_ADMIN_PASSWORD`          | Administrator initial password.                                                | `admin`                                           |                  |
| `OPENEDX_SECRET_KEY`              | Secret key for Django sessions and token encryption.                           | `insecure-secret-key-replace-in-production`       |                  |
| `OPENEDX_WSGI_WORKERS`            | Number of WSGI worker processes.                                               | `2`                                               |                  |
| `OPENEDX_INSTALL_DIR`             | Directory where openedx-platform is checked out and deployed.                  | `none`                                            |                  |

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
[cc0-screenshots](https://github.com/SamuelMarks/cc0-assets) repository:

| Wizard Step        | Description                                                | Preview                                                                                                                                                                                                                                                                       |
| :----------------- | :--------------------------------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Welcome**        | Open edX branded welcome and prerequisite summary          | [![Welcome](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/01_simple_welcome.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/01_simple_welcome.png)                        |
| **License**        | EULA terms acceptance                                      | [![License](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/02_simple_license.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/02_simple_license.png)                        |
| **Setup Type**     | Simple Mode (express install) vs Advanced Mode             | [![Setup Type](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/03_simple_setup_type.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/03_simple_setup_type.png)               |
| **Source Repo**    | Build-time configured repository source and release branch | [![Source Repo](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/06b_advanced_source_repo.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/06b_advanced_source_repo.png)      |
| **Relational DB**  | MySQL port or external DBaaS (RDS / Azure / PlanetScale)   | [![Database](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/07_advanced_db.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/07_advanced_db.png)                             |
| **Cache & Search** | Redis, MongoDB Atlas, and Meilisearch endpoints            | [![Cache Search](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/08_advanced_cache_search.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/08_advanced_cache_search.png)     |
| **Verify Ready**   | Summary review of components prior to deployment           | [![Verify Ready](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/09_advanced_verify_ready.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/09_advanced_verify_ready.png)     |
| **LMS Portal**     | Open edX LMS Web Application (`:8000/login`)               | [![LMS Focused](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/11_browser_lms_focused.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/11_browser_lms_focused.png)          |
| **Studio CMS**     | Open edX Studio Course Authoring (`:8001/signin`)          | [![Studio Focused](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/12_browser_studio_focused.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/openedx/screenshots/12_browser_studio_focused.png) |
