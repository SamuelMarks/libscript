# Tier 5 (`T5`) Multi-Service Application Stacks (`workloads/apps/`)

## Overview

`workloads/apps/` houses turnkey multi-service web, e-commerce, collaboration, LMS, data-science,
and worker application stacks. Unlike atomic `T1` components in `_lib/` (which enforce zero lateral
cross-sourcing), `T5` application stacks compose multiple `T1` runtimes, databases, caches, search
engines, and reverse proxies via `T0` integration hooks (`engine/hooks/`) and `T3` `packaging.json`
/ `offline_bundle.json` installer manifests.

## Application Catalog

- [`openedx/`](./openedx/README.md): Full Open edX learning platform (LMS, CMS/Studio, MFEs, Celery,
  MariaDB/MySQL, MongoDB, Redis, Meilisearch, Caddy/Nginx/IIS).
- [`wordpress/`](./wordpress/README.md) & [`woocommerce/`](./woocommerce/README.md): WordPress CMS
  and WooCommerce e-commerce stack (PHP-FPM, MariaDB/MySQL/PostgreSQL/SQLite, WP-CLI,
  Nginx/Caddy/IIS).
- [`nextcloud/`](./nextcloud/README.md): Self-hosted file sync, collaboration, and office suite.
- [`odoo/`](./odoo/README.md): Enterprise ERP and CRM platform backed by Python and PostgreSQL.
- [`drupal/`](./drupal/README.md) & [`joomla/`](./joomla/README.md): Enterprise PHP CMS stacks.
- [`magento/`](./magento/README.md) & [`prestashop/`](./prestashop/README.md): Full-featured
  e-commerce platforms with search and cache integration.
- [`phpbb/`](./phpbb/README.md): Bulletin board and community forum stack.
- [`jupyterhub/`](./jupyterhub/README.md): Multi-user Jupyter notebook server and spawner stack.
- [`celery/`](./celery/README.md): Distributed Python task queue and beat scheduler worker stack.
- [`firecrawl/`](./firecrawl/README.md): Web crawling, scraping, and Markdown extraction service
  stack.
- [`serve-actix-diesel-auth-scaffold/`](./serve-actix-diesel-auth-scaffold/README.md): Rust
  Actix-Web
  - Diesel ORM authenticated REST API application stack.

## Usage

```sh
./libscript.sh install wordpress latest
./libscript.sh package-as msi --stack workloads/apps/openedx/packaging.json --offline
```

```cmd
.\libscript.cmd install wordpress latest
.\libscript.cmd package-as msi --stack workloads\apps\openedx\packaging.json --offline
```
