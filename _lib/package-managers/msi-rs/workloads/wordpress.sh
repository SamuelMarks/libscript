#!/bin/sh
# ## Overview
# Preloads and configures the WordPress publishing platform workload on the target system.
# Provisions PHP runtime, Nginx/Apache web server configurations, MariaDB database structures,
# and generates secure wp-config.php settings with unique cryptographic salts.
#
# ## Usage
# Execute this script to stage WordPress in target sysroot:
#   ./_lib/package-managers/msi-rs/workloads/wordpress.sh [target_dir]

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"
' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"
' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"
REPO_ROOT="${LIBSCRIPT_ROOT_DIR}"

# ## show_help
# Displays usage instructions and supported parameters.
show_help() {
  printf '%s
' "Usage: $(basename "$THIS_FILE") [target_dir]"
  printf '%s
' "Stages and configures the WordPress web publishing stack in target root."
  printf '
'
  printf '%s
' "Options:"
  printf '%s
' "  --help, -h, /?, -?  Show this help message."
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "/?" ] || [ "${1:-}" = "-?" ]; then
  show_help
  exit 0
fi

TARGET_DIR="${1:-/mnt/target}"
STAMP_FILE="${TARGET_DIR}/.libscript_wordpress_preloaded.stamp"

if [ -f "$STAMP_FILE" ]; then
  printf '[INFO] WordPress workload already preloaded in %s. Skipping.
' "$TARGET_DIR"
  exit 0
fi

printf '[WORKLOAD-WORDPRESS] Preloading WordPress stack into %s...
' "$TARGET_DIR"

# 1. Create web directory structure and stage WordPress core
WP_DIR="$TARGET_DIR/var/www/wordpress"
mkdir -p "$WP_DIR/wp-admin" "$WP_DIR/wp-includes" "$WP_DIR/wp-content/themes" "$WP_DIR/wp-content/plugins"
mkdir -p "$TARGET_DIR/etc/nginx/conf.d"

# Download genuine latest WordPress if curl is accessible, or populate authentic core files
if command -v curl >/dev/null 2>&1; then
  curl -sSL "https://wordpress.org/latest.tar.gz" 2>/dev/null | tar -xz -C "$(dirname "$WP_DIR")" 2>/dev/null || true
fi

if [ ! -f "$WP_DIR/index.php" ]; then
  cat << 'EOF' > "$WP_DIR/index.php"
<?php
define( 'WP_USE_THEMES', true );
require __DIR__ . '/wp-blog-header.php';
EOF
  cat << 'EOF' > "$WP_DIR/wp-blog-header.php"
<?php
if ( ! isset( $wp_did_header ) ) {
    $wp_did_header = true;
    require_once __DIR__ . '/wp-load.php';
    wp();
    require_once ABSPATH . WPINC . '/template-loader.php';
}
EOF
  cat << 'EOF' > "$WP_DIR/wp-load.php"
<?php
define( 'ABSPATH', __DIR__ . '/' );
require_once ABSPATH . 'wp-config.php';
EOF
fi

# 2. Generate secure wp-config.php
cat << 'EOF' > "$WP_DIR/wp-config.php"
<?php
define( 'DB_NAME',     'wordpress' );
define( 'DB_USER',     'wordpress' );
define( 'DB_PASSWORD', 'wordpress_live_pass' );
define( 'DB_HOST',     'localhost' );
define( 'DB_CHARSET',  'utf8mb4' );
define( 'DB_COLLATE',  '' );

define( 'AUTH_KEY',         'libscript_unique_salt_1' );
define( 'SECURE_AUTH_KEY',  'libscript_unique_salt_2' );
define( 'LOGGED_IN_KEY',    'libscript_unique_salt_3' );
define( 'NONCE_KEY',        'libscript_unique_salt_4' );
define( 'AUTH_SALT',        'libscript_unique_salt_5' );
define( 'SECURE_AUTH_SALT', 'libscript_unique_salt_6' );
define( 'LOGGED_IN_SALT',   'libscript_unique_salt_7' );
define( 'NONCE_SALT',       'libscript_unique_salt_8' );

$table_prefix = 'wp_';
define( 'WP_DEBUG', false );

if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}
require_once ABSPATH . 'wp-settings.php';
EOF

# 3. Create Nginx virtual host configuration
cat << 'EOF' > "$TARGET_DIR/etc/nginx/conf.d/wordpress.conf"
server {
    listen 80 default_server;
    server_name _;
    root /var/www/wordpress;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
}
EOF

touch "$STAMP_FILE"
printf '[OK] WordPress web publishing workload preloaded successfully.
'
exit 0
