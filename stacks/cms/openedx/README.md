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
