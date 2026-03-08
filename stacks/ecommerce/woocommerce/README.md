# WooCommerce

WooCommerce is a customizable, open-source eCommerce platform built on WordPress.

This component extends the `wordpress` component by automatically downloading and provisioning WooCommerce alongside a WordPress installation. It supports all underlying web servers (`nginx`, `caddy`, `httpd`, `iis`), databases (`mariadb`, `postgres`, `sqlite`), and operating systems (Windows, macOS, Linux, FreeBSD) that the LibScript `wordpress` component supports.

## Variables

- `WOOCOMMERCE_VERSION`: The version of WooCommerce to install (default: `latest`).
- `WORDPRESS_VERSION`: The version of WordPress to install (default: `latest`).
- `WORDPRESS_DB_ENGINE`: The database backend to use (`mariadb` [default], `postgres`, or `sqlite`).
- `WORDPRESS_WEBSERVER`: The web server to configure (`nginx` [default], `caddy`, `httpd`, `iis`).
- `WORDPRESS_DB_NAME`, `WORDPRESS_DB_USER`, `WORDPRESS_DB_PASS`: Database credentials.
- `WORDPRESS_SERVER_NAME`: The domain or server name (default: `localhost`).
- `WORDPRESS_LISTEN`: The port or address to listen on (default: `80`).

## Usage

You can deploy a full WooCommerce stack by simply installing this component:

```sh
export WOOCOMMERCE_VERSION="latest"
export WORDPRESS_DB_ENGINE="sqlite"
export WORDPRESS_WEBSERVER="caddy"
./libscript.sh install stacks/ecommerce/woocommerce
```
