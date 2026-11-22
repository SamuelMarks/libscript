# Woocommerce

WooCommerce is a customizable, open-source eCommerce platform built on WordPress.

This component extends the `wordpress` component by automatically downloading and provisioning
WooCommerce alongside a WordPress installation. It supports all underlying web servers (`nginx`,
`caddy`, `httpd`, `iis`), databases (`mariadb`, `postgres`, `sqlite`), and operating systems
(Windows, macOS, Linux, FreeBSD) that the LibScript `wordpress` component supports.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                  | Description                                                                        | Default | Aliases/Examples |
| ------------------------- | ---------------------------------------------------------------------------------- | ------- | ---------------- |
| `WOOCOMMERCE_SERVER_NAME` | Public virtual host domain name configured for the WooCommerce storefront.         | `none`  |                  |
| `WOOCOMMERCE_LISTEN`      | HTTP bind address:port or UNIX socket exposed for the WooCommerce site.            | `none`  |                  |
| `WOOCOMMERCE_VERSION`     | Target WooCommerce plugin release version or alias (e.g., latest) to install.      | `none`  |                  |
| `WOOCOMMERCE_WWWROOT`     | Filesystem WordPress document root into which the WooCommerce plugin is installed. | `none`  |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Usage

You can deploy a full WooCommerce stack by simply installing this component:

```sh
export WOOCOMMERCE_VERSION="latest"
export WORDPRESS_DB_ENGINE="sqlite"
export WORDPRESS_WEBSERVER="caddy"
./libscript.sh install workloads/apps/woocommerce
```

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->

## Orchestrated Components

This stack orchestrates the following LibScript components:

- `workloads/apps/wordpress`: Foundational WordPress CMS runtime
- `_lib/languages/php`: PHP runtime and WooCommerce extensions
- `_lib/databases/mariadb`: MySQL/MariaDB database storage
- `_lib/web-servers/nginx` (or `caddy`, `httpd`, `iis`): Web server and ingress
