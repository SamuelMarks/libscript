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

| Variable                  | Description                   | Default | Aliases/Examples |
| ------------------------- | ----------------------------- | ------- | ---------------- |
| `WOOCOMMERCE_SERVER_NAME` | Variable SERVER_NAME.         | `none`  |                  |
| `WOOCOMMERCE_LISTEN`      | Variable WOOCOMMERCE_LISTEN.  | `none`  |                  |
| `WOOCOMMERCE_VERSION`     | Variable WOOCOMMERCE_VERSION. | `none`  |                  |
| `WOOCOMMERCE_WWWROOT`     | Variable WWWROOT.             | `none`  |                  |

<!-- END_VARS -->

## Usage

You can deploy a full WooCommerce stack by simply installing this component:

```sh
export WOOCOMMERCE_VERSION="latest"
export WORDPRESS_DB_ENGINE="sqlite"
export WORDPRESS_WEBSERVER="caddy"
./libscript.sh install stacks/ecommerce/woocommerce
```

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->

## Orchestrated Components

This stack orchestrates the following LibScript components:

- `stacks/cms/wordpress`: Foundational WordPress CMS runtime
- `_lib/languages/php`: PHP runtime and WooCommerce extensions
- `_lib/databases/mariadb`: MySQL/MariaDB database storage
- `_lib/web-servers/nginx` (or `caddy`, `httpd`, `iis`): Web server and ingress
