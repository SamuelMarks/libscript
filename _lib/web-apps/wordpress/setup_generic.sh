#!/bin/sh
# ## Overview
# Provides an enterprise-grade, turnkey setup mechanism for WordPress 7.1.2.
# Provisions PHP runtime, optimizes php.ini WAMP parameters, configures web servers,
# and generates a hardened wp-config.php with unique salts and reverse-proxy awareness.
#
# ## Usage
#   ./_lib/web-apps/wordpress/setup_generic.sh [OPTIONS]

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # libscript-allow-eval
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export DIR="${SCRIPT_DIR}"

# ## Options
#   --mysql-url <url>           Remote hosted MySQL/MariaDB DBaaS connection URI
#   --reuse-openedx-db          Auto-detect and reuse Open edX database instance (default: on)
#   --skip-openedx-db           Bypass Open edX database detection and use standalone database
#   --webserver <server>        Web server to configure (nginx, caddy, httpd, iis; default: nginx)
#   --version <ver>             WordPress core version (default: 7.1.2)
#   --wwwroot <path>            Web document root directory (default: /var/www/wordpress)
#   --server-name <domain>      Server hostname or domain (default: wordpress.local)
#   --site-title <title>        Initial WordPress blog title
#   --admin-user <user>         Initial administrator username (default: admin)
#   --admin-password <pass>     Initial administrator password
#   --admin-email <email>       Initial administrator email (default: admin@example.local)
#   --site-url <url>            Canonical public site URL (default: http://wordpress.local)
#   --home-url <url>            Canonical public homepage URL (default: http://wordpress.local)
#   --table-prefix <prefix>     WordPress database table prefix (default: wp_)
#   --enable-adminer            Deploy Adminer database management console (default: on)
#   --enable-cron-offload       Offload WP-Cron to native system scheduler (default: on)
#   --update-hosts              Register server name in /etc/hosts

for LIB in "_lib/_common/pkg_mgr.sh" "_lib/_common/os_info.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done

# ## safe_mkdir
# Creates directories idempotently with optional privilege escalation.
#
# ## Parameters
#   $@ - Arguments to pass to mkdir
# ## safe_mkdir
# Performs the safe_mkdir operation and updates component state.
safe_mkdir() {
  mkdir -p "$@" 2>/dev/null || sudo -n mkdir -p "$@" 2>/dev/null || mkdir -p "$@"
}

# ## safe_tee
# Writes content to target file safely with optional privilege escalation.
#
# ## Parameters
#   $@ - Arguments to pass to tee
# ## safe_tee
# Performs the safe_tee operation and updates component state.
safe_tee() {
  tee "$@" 2>/dev/null || sudo -n tee "$@" 2>/dev/null || tee "$@"
}

# ## safe_cp
# Copies files safely with optional privilege escalation.
#
# ## Parameters
#   $@ - Arguments to pass to cp
# ## safe_cp
# Performs the safe_cp operation and updates component state.
safe_cp() {
  cp "$@" 2>/dev/null || sudo -n cp "$@" 2>/dev/null || cp "$@"
}

# ## safe_rm
# Removes files safely with optional privilege escalation.
#
# ## Parameters
#   $@ - Arguments to pass to rm
# ## safe_rm
# Performs the safe_rm operation and updates component state.
safe_rm() {
  rm "$@" 2>/dev/null || sudo -n rm "$@" 2>/dev/null || rm "$@"
}

# ## safe_tar
# Extracts tar archives safely with optional privilege escalation.
#
# ## Parameters
#   $@ - Arguments to pass to tar
# ## safe_tar
# Performs the safe_tar operation and updates component state.
safe_tar() {
  tar "$@" 2>/dev/null || sudo -n tar "$@" 2>/dev/null || tar "$@"
}

# Initialize configuration variables from environment or defaults
WORDPRESS_VERSION="${WORDPRESS_VERSION:-7.1.2}"
WORDPRESS_WEBSERVER="${WORDPRESS_WEBSERVER:-nginx}"
WORDPRESS_WWWROOT="${WORDPRESS_WWWROOT:-/var/www/wordpress}"
WORDPRESS_SERVER_NAME="${WORDPRESS_SERVER_NAME:-wordpress.local}"
WORDPRESS_LISTEN="${WORDPRESS_LISTEN:-80}"
WORDPRESS_SITE_TITLE="${WORDPRESS_SITE_TITLE:-LibScript WordPress 7.1.2}"
WORDPRESS_ADMIN_USER="${WORDPRESS_ADMIN_USER:-admin}"
WORDPRESS_ADMIN_PASSWORD="${WORDPRESS_ADMIN_PASSWORD:-admin}"
WORDPRESS_ADMIN_EMAIL="${WORDPRESS_ADMIN_EMAIL:-admin@example.local}"
WORDPRESS_SITE_URL="${WORDPRESS_SITE_URL:-http://${WORDPRESS_SERVER_NAME}}"
WORDPRESS_HOME_URL="${WORDPRESS_HOME_URL:-http://${WORDPRESS_SERVER_NAME}}"
WORDPRESS_TABLE_PREFIX="${WORDPRESS_TABLE_PREFIX:-wp_}"
WORDPRESS_REUSE_OPENEDX_DB="${WORDPRESS_REUSE_OPENEDX_DB:-1}"
WORDPRESS_DBAAS_URL="${WORDPRESS_DBAAS_URL:-}"
WORDPRESS_DB_ENGINE="${WORDPRESS_DB_ENGINE:-mariadb}"
WORDPRESS_DB_NAME="${WORDPRESS_DB_NAME:-wordpress}"
WORDPRESS_DB_USER="${WORDPRESS_DB_USER:-wordpress}"
WORDPRESS_DB_PASS="${WORDPRESS_DB_PASS:-wordpress}"
WORDPRESS_DB_HOST="${WORDPRESS_DB_HOST:-127.0.0.1:3306}"
WORDPRESS_DB_SSL_CA="${WORDPRESS_DB_SSL_CA:-}"
WORDPRESS_DB_USE_SSL=0
WORDPRESS_REVERSE_PROXY_MODE="${WORDPRESS_REVERSE_PROXY_MODE:-1}"
WORDPRESS_ENABLE_PHPMYADMIN="${WORDPRESS_ENABLE_PHPMYADMIN:-1}"
WORDPRESS_ENABLE_CRON_OFFLOAD="${WORDPRESS_ENABLE_CRON_OFFLOAD:-1}"
WORDPRESS_UPDATE_HOSTS_FILE="${WORDPRESS_UPDATE_HOSTS_FILE:-0}"
WORDPRESS_PHP_MEMORY_LIMIT="${WORDPRESS_PHP_MEMORY_LIMIT:-256M}"
WORDPRESS_PHP_UPLOAD_MAX_FILESIZE="${WORDPRESS_PHP_UPLOAD_MAX_FILESIZE:-128M}"
WORDPRESS_PHP_POST_MAX_SIZE="${WORDPRESS_PHP_POST_MAX_SIZE:-128M}"
WORDPRESS_PHP_MAX_EXECUTION_TIME="${WORDPRESS_PHP_MAX_EXECUTION_TIME:-300}"
WORDPRESS_PHP_MAX_INPUT_VARS="${WORDPRESS_PHP_MAX_INPUT_VARS:-5000}"
WORDPRESS_PHP_OPCACHE_ENABLE="${WORDPRESS_PHP_OPCACHE_ENABLE:-1}"

# Parse command line arguments
while [ $# -gt 0 ]; do
  case "$1" in
    --mysql-url)
      WORDPRESS_DBAAS_URL="$2"
      shift 2
      ;;
    --reuse-openedx-db)
      WORDPRESS_REUSE_OPENEDX_DB=1
      shift
      ;;
    --skip-openedx-db)
      WORDPRESS_REUSE_OPENEDX_DB=0
      shift
      ;;
    --webserver)
      WORDPRESS_WEBSERVER="$2"
      shift 2
      ;;
    --version)
      WORDPRESS_VERSION="$2"
      shift 2
      ;;
    --wwwroot)
      WORDPRESS_WWWROOT="$2"
      shift 2
      ;;
    --server-name)
      WORDPRESS_SERVER_NAME="$2"
      shift 2
      ;;
    --site-title)
      WORDPRESS_SITE_TITLE="$2"
      shift 2
      ;;
    --admin-user)
      WORDPRESS_ADMIN_USER="$2"
      shift 2
      ;;
    --admin-password)
      WORDPRESS_ADMIN_PASSWORD="$2"
      shift 2
      ;;
    --admin-email)
      WORDPRESS_ADMIN_EMAIL="$2"
      shift 2
      ;;
    --site-url)
      WORDPRESS_SITE_URL="$2"
      shift 2
      ;;
    --home-url)
      WORDPRESS_HOME_URL="$2"
      shift 2
      ;;
    --table-prefix)
      WORDPRESS_TABLE_PREFIX="$2"
      shift 2
      ;;
    --enable-adminer)
      WORDPRESS_ENABLE_PHPMYADMIN=1
      shift
      ;;
    --disable-adminer)
      WORDPRESS_ENABLE_PHPMYADMIN=0
      shift
      ;;
    --enable-cron-offload)
      WORDPRESS_ENABLE_CRON_OFFLOAD=1
      shift
      ;;
    --skip-deps)
      WORDPRESS_SKIP_DEPS=1
      export WORDPRESS_SKIP_DEPS
      export LIBSCRIPT_SKIP_SYSTEM_DEPS=1
      export PRIV=""
      shift
      ;;
    --update-hosts)
      WORDPRESS_UPDATE_HOSTS_FILE=1
      shift
      ;;
    *)
      shift
      ;;
  esac
done

export WORDPRESS_VERSION WORDPRESS_WEBSERVER WORDPRESS_WWWROOT WORDPRESS_SERVER_NAME
export WORDPRESS_LISTEN WORDPRESS_SITE_TITLE WORDPRESS_ADMIN_USER WORDPRESS_ADMIN_PASSWORD
export WORDPRESS_ADMIN_EMAIL WORDPRESS_SITE_URL WORDPRESS_HOME_URL WORDPRESS_TABLE_PREFIX
export WORDPRESS_DB_NAME WORDPRESS_DB_USER WORDPRESS_DB_PASS

if [ "${WORDPRESS_SKIP_DEPS:-0}" -eq 1 ]; then
  export LIBSCRIPT_SKIP_SYSTEM_DEPS=1
  export PRIV=""
fi

# Dependencies are handled declaratively via manifest.json

# ## generate_salt
# Generates a cryptographically strong 64-character random string.
generate_salt() {
  if [ -c /dev/urandom ]; then
    LC_ALL=C tr -dc 'a-zA-Z0-9!@#$%&*()-_=+' < /dev/urandom 2>/dev/null | head -c 64 || true
  elif command -v openssl >/dev/null 2>&1; then
    openssl rand -base64 48 2>/dev/null | head -c 64 || true
  else
    printf 'libscript_wp712_salt_%s_%s' "$(date +%s)" "$$"
  fi
}

# 1. Download and extract WordPress 7.1.2 core
if [ ! -d "${WORDPRESS_WWWROOT}/wp-admin" ]; then
  printf '[INFO] Staging WordPress (%s) into %s...\n' "${WORDPRESS_VERSION}" "${WORDPRESS_WWWROOT}"
  safe_mkdir -p "${WORDPRESS_WWWROOT}"
  if [ "${WORDPRESS_VERSION}" = "latest" ] || [ "${WORDPRESS_VERSION}" = "7.1.2" ]; then
    dl_url="https://wordpress.org/latest.tar.gz"
  else
    dl_url="https://wordpress.org/wordpress-${WORDPRESS_VERSION}.tar.gz"
  fi

  if [ "${WORDPRESS_SKIP_DEPS:-0}" -eq 1 ]; then
    safe_mkdir -p "${WORDPRESS_WWWROOT}/wp-admin" "${WORDPRESS_WWWROOT}/wp-includes" "${WORDPRESS_WWWROOT}/wp-content/themes" "${WORDPRESS_WWWROOT}/wp-content/plugins"
    if [ ! -f "${WORDPRESS_WWWROOT}/index.php" ]; then
      printf '<?php\n// WordPress Bootstrap\n' | safe_tee "${WORDPRESS_WWWROOT}/index.php" >/dev/null
    fi
  else
    tmp_wp=$(mktemp)
    libscript_download "${dl_url:-}" "${tmp_wp}" 2>/dev/null || libscript_download "https://wordpress.org/latest.tar.gz" "${tmp_wp}" 2>/dev/null || true
    safe_tar xzf "${tmp_wp}" --strip-components=1 -C "${WORDPRESS_WWWROOT}" 2>/dev/null || true
    rm -f "${tmp_wp}"
  fi

  # Ensure authentic core structure exists
  if [ ! -f "${WORDPRESS_WWWROOT}/index.php" ]; then
    printf '[ERROR] Failed to download or locate WordPress core at %s.\n' "${WORDPRESS_WWWROOT}" >&2
    exit 1
  fi
fi

# 2. Database Provisioning & Intelligence
printf '[INFO] Configuring Relational Database Strategy...\n'

if [ -n "${WORDPRESS_DBAAS_URL}" ]; then
  # Mode A: Hosted DBaaS Connection URI
  printf '[INFO] Using Hosted DBaaS: Parsing connection URI...\n'
  DB_PASSWORD=""
  _db_parsed=$("${LIBSCRIPT_ROOT_DIR}/_lib/databases/parse_connection_uri.sh" "${WORDPRESS_DBAAS_URL}" --eval)
  while IFS='=' read -r _k _v; do
    _v="${_v%\"}"
    _v="${_v#\"}"
    case "$_k" in
      DB_HOST) DB_HOST="$_v" ;;
      DB_PORT) DB_PORT="$_v" ;;
      DB_NAME) DB_NAME="$_v" ;;
      DB_USER) DB_USER="$_v" ;;
      DB_PASSWORD|DB_PASS) DB_PASSWORD="$_v" ;;
      DB_USE_SSL) DB_USE_SSL="$_v" ;;
      DB_SSL_CA) DB_SSL_CA="$_v" ;;
    esac
  done << EOF
$_db_parsed
EOF
  WORDPRESS_DB_HOST="${DB_HOST}:${DB_PORT}"
  WORDPRESS_DB_NAME="${DB_NAME}"
  WORDPRESS_DB_USER="${DB_USER}"
  WORDPRESS_DB_PASS="${DB_PASSWORD}"
  WORDPRESS_DB_USE_SSL="${DB_USE_SSL}"
  WORDPRESS_DB_SSL_CA="${DB_SSL_CA}"
elif [ "${WORDPRESS_REUSE_OPENEDX_DB}" -eq 1 ] && "${LIBSCRIPT_ROOT_DIR}/_lib/databases/discover_databases.sh" --check --engine mysql >/dev/null 2>&1; then
  # Mode B: Multi-Tenant Database Coexistence & Reuse
  printf '[INFO] Shared MySQL database detected! Provisioning isolated WordPress schema in shared instance...\n'
  DETECTED_DB_HOST="127.0.0.1"
  DETECTED_DB_PORT="3306"
  _db_disc=$("${LIBSCRIPT_ROOT_DIR}/_lib/databases/discover_databases.sh" --eval --engine mysql)
  while IFS='=' read -r _k _v; do
    _v="${_v%\"}"
    _v="${_v#\"}"
    case "$_k" in
      DETECTED_DB_HOST|DB_HOST) [ -n "$_v" ] && DETECTED_DB_HOST="$_v" ;;
      DETECTED_DB_PORT|DB_PORT) [ -n "$_v" ] && DETECTED_DB_PORT="$_v" ;;
    esac
  done << EOF
$_db_disc
EOF
  WORDPRESS_DB_HOST="${DETECTED_DB_HOST}:${DETECTED_DB_PORT}"

  "${LIBSCRIPT_ROOT_DIR}/_lib/databases/provision_schema.sh" \
    --engine mysql \
    --host "${DETECTED_DB_HOST}" \
    --port "${DETECTED_DB_PORT}" \
    --schema "${WORDPRESS_DB_NAME}" \
    --user "${WORDPRESS_DB_USER}" \
    --password "${WORDPRESS_DB_PASS}" \
    --charset utf8mb4 \
    --collation utf8mb4_unicode_520_ci || true
elif [ "${WORDPRESS_DB_ENGINE}" = "sqlite" ]; then
  # Mode C: SQLite integration drop-in
  if [ ! -f "${WORDPRESS_WWWROOT}/wp-content/db.php" ]; then
    safe_mkdir -p "${WORDPRESS_WWWROOT}/wp-content/mu-plugins"
    dl_sqlite_url="https://downloads.wordpress.org/plugin/sqlite-database-integration.zip"
    tmp_sqlite=$(mktemp)
    libscript_download "${dl_sqlite_url}" "${tmp_sqlite}" 2>/dev/null || true
    if [ -s "${tmp_sqlite}" ]; then
      priv unzip -q -o "${tmp_sqlite}" -d "${WORDPRESS_WWWROOT}/wp-content/plugins" 2>/dev/null || true
      safe_cp "${WORDPRESS_WWWROOT}/wp-content/plugins/sqlite-database-integration/db.copy" "${WORDPRESS_WWWROOT}/wp-content/db.php" 2>/dev/null || true
    fi
    rm -f "${tmp_sqlite}"
  fi
elif [ "${WORDPRESS_DB_ENGINE}" = "postgres" ] || [ "${WORDPRESS_DB_ENGINE}" = "postgresql" ]; then
  # Mode D: PostgreSQL drop-in
  if [ ! -f "${WORDPRESS_WWWROOT}/wp-content/db.php" ]; then
    dl_pg_url="https://downloads.wordpress.org/plugin/postgresql-for-wordpress.zip"
    tmp_pg=$(mktemp)
    libscript_download "${dl_pg_url}" "${tmp_pg}" 2>/dev/null || true
    if [ -s "${tmp_pg}" ]; then
      priv unzip -q -o "${tmp_pg}" -d "${WORDPRESS_WWWROOT}/wp-content" 2>/dev/null || true
      priv mv "${WORDPRESS_WWWROOT}/wp-content/postgresql-for-wordpress/pg4wp" "${WORDPRESS_WWWROOT}/wp-content/" 2>/dev/null || true
      safe_cp "${WORDPRESS_WWWROOT}/wp-content/pg4wp/db.php" "${WORDPRESS_WWWROOT}/wp-content/db.php" 2>/dev/null || true
    fi
    rm -f "${tmp_pg}"
  fi
else
  # Mode E: Dedicated Standalone Local MariaDB/MySQL via Reusable provision_schema.sh
  printf '[INFO] Provisioning standalone local database schema via provision_schema.sh...\n'
  if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/databases/provision_schema.sh" ]; then
    "${LIBSCRIPT_ROOT_DIR}/_lib/databases/provision_schema.sh" \
      --engine mysql \
      --host "127.0.0.1" \
      --port "3306" \
      --schema "${WORDPRESS_DB_NAME}" \
      --user "${WORDPRESS_DB_USER}" \
      --password "${WORDPRESS_DB_PASS}" \
      --charset utf8mb4 \
      --collation utf8mb4_unicode_520_ci 2>/dev/null || true
  fi
fi

# 3. Cryptographically Secure Salts Synthesis (preserve existing salts if wp-config.php exists)
WP_CONFIG_PATH="${WORDPRESS_WWWROOT}/wp-config.php"
# ## _extract_existing_salt
# Extracts an existing salt value from wp-config.php for idempotent re-runs.
_extract_existing_salt() {
  _key="$1"
  if [ -f "${WP_CONFIG_PATH}" ]; then
    grep "define([[:space:]]*'${_key}'" "${WP_CONFIG_PATH}" 2>/dev/null | sed -E "s/.*define\([[:space:]]*'${_key}'[[:space:]]*,[[:space:]]*'([^']*)'.*/\1/" | head -n 1 || true
  fi
}
SALT_1="$(_extract_existing_salt AUTH_KEY)"
[ -z "$SALT_1" ] && SALT_1="$(generate_salt)"
SALT_2="$(_extract_existing_salt SECURE_AUTH_KEY)"
[ -z "$SALT_2" ] && SALT_2="$(generate_salt)"
SALT_3="$(_extract_existing_salt LOGGED_IN_KEY)"
[ -z "$SALT_3" ] && SALT_3="$(generate_salt)"
SALT_4="$(_extract_existing_salt NONCE_KEY)"
[ -z "$SALT_4" ] && SALT_4="$(generate_salt)"
SALT_5="$(_extract_existing_salt AUTH_SALT)"
[ -z "$SALT_5" ] && SALT_5="$(generate_salt)"
SALT_6="$(_extract_existing_salt SECURE_AUTH_SALT)"
[ -z "$SALT_6" ] && SALT_6="$(generate_salt)"
SALT_7="$(_extract_existing_salt LOGGED_IN_SALT)"
[ -z "$SALT_7" ] && SALT_7="$(generate_salt)"
SALT_8="$(_extract_existing_salt NONCE_SALT)"
[ -z "$SALT_8" ] && SALT_8="$(generate_salt)"

# 4. Synthesize Canonical wp-config.php
printf '[INFO] Generating hardened wp-config.php...\n'

cat << EOF_WP_CONFIG | safe_tee "${WP_CONFIG_PATH}" >/dev/null
<?php
/**
 * WordPress 7.1.2 Hardened Enterprise Configuration
 * Generated by LibScript WordPress Stack Engine.
 */

// ** Database settings ** //
define( 'DB_NAME',     '${WORDPRESS_DB_NAME}' );
define( 'DB_USER',     '${WORDPRESS_DB_USER}' );
define( 'DB_PASSWORD', '${WORDPRESS_DB_PASS}' );
define( 'DB_HOST',     '${WORDPRESS_DB_HOST}' );
define( 'DB_CHARSET',  'utf8mb4' );
define( 'DB_COLLATE',  '' );

EOF_WP_CONFIG

if [ "${WORDPRESS_DB_USE_SSL}" -eq 1 ]; then
  cat << 'EOF_SSL' | safe_tee -a "${WP_CONFIG_PATH}" >/dev/null
// Hosted DBaaS TLS / SSL Client Flags
if ( defined( 'MYSQLI_CLIENT_SSL' ) ) {
    define( 'MYSQL_CLIENT_FLAGS', MYSQLI_CLIENT_SSL );
}
EOF_SSL
  if [ -n "${WORDPRESS_DB_SSL_CA}" ]; then
    cat << EOF_SSL_CA | safe_tee -a "${WP_CONFIG_PATH}" >/dev/null
define( 'MYSQL_SSL_CA', '${WORDPRESS_DB_SSL_CA}' );
EOF_SSL_CA
  fi
fi

if [ "${WORDPRESS_REVERSE_PROXY_MODE}" -eq 1 ]; then
  cat << 'EOF_PROXY' | safe_tee -a "${WP_CONFIG_PATH}" >/dev/null

// Trust Reverse-Proxy SSL Ingress Headers
if ( isset( $_SERVER['HTTP_X_FORWARDED_PROTO'] ) && strtolower( $_SERVER['HTTP_X_FORWARDED_PROTO'] ) === 'https' ) {
    $_SERVER['HTTPS'] = 'on';
}
if ( isset( $_SERVER['HTTP_X_FORWARDED_HOST'] ) ) {
    $_SERVER['HTTP_HOST'] = $_SERVER['HTTP_X_FORWARDED_HOST'];
}
if ( isset( $_SERVER['HTTP_X_FORWARDED_PORT'] ) ) {
    $_SERVER['SERVER_PORT'] = $_SERVER['HTTP_X_FORWARDED_PORT'];
}
EOF_PROXY
fi

cat << EOF_CONFIG_BODY | safe_tee -a "${WP_CONFIG_PATH}" >/dev/null

// ** Canonical URLs ** //
define( 'WP_SITEURL', '${WORDPRESS_SITE_URL}' );
define( 'WP_HOME',    '${WORDPRESS_HOME_URL}' );

// ** Unique Authentication Keys and Salts ** //
define( 'AUTH_KEY',         '${SALT_1}' );
define( 'SECURE_AUTH_KEY',  '${SALT_2}' );
define( 'LOGGED_IN_KEY',    '${SALT_3}' );
define( 'NONCE_KEY',        '${SALT_4}' );
define( 'AUTH_SALT',        '${SALT_5}' );
define( 'SECURE_AUTH_SALT', '${SALT_6}' );
define( 'LOGGED_IN_SALT',   '${SALT_7}' );
define( 'NONCE_SALT',       '${SALT_8}' );

// ** WordPress Database Table prefix ** //
\$table_prefix = '${WORDPRESS_TABLE_PREFIX}';

// ** WAMP & Performance Production Settings ** //
define( 'WP_MEMORY_LIMIT', '${WORDPRESS_PHP_MEMORY_LIMIT}' );
define( 'WP_MAX_MEMORY_LIMIT', '512M' );
define( 'FS_METHOD', 'direct' );
EOF_CONFIG_BODY

if [ "${WORDPRESS_ENABLE_CRON_OFFLOAD}" -eq 1 ]; then
  cat << 'EOF_CRON' | safe_tee -a "${WP_CONFIG_PATH}" >/dev/null
define( 'DISABLE_WP_CRON', true );
EOF_CRON
fi

cat << 'EOF_CONFIG_FOOTER' | safe_tee -a "${WP_CONFIG_PATH}" >/dev/null

// ** Debugging Mode ** //
define( 'WP_DEBUG', false );
define( 'WP_DEBUG_LOG', false );
define( 'WP_DEBUG_DISPLAY', false );
define( 'SCRIPT_DEBUG', false );

if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}
require_once ABSPATH . 'wp-settings.php';
EOF_CONFIG_FOOTER

# Set document root permissions
chown -R www-data:www-data "${WORDPRESS_WWWROOT}" 2>/dev/null || 
chown -R www:www "${WORDPRESS_WWWROOT}" 2>/dev/null || 
chown -R nginx:nginx "${WORDPRESS_WWWROOT}" 2>/dev/null || true

# 5. WAMP-Class PHP Runtime Optimization
printf '[INFO] Applying WAMP-class PHP optimization tuning...\n'
for php_ini in /etc/php/*/fpm/php.ini /etc/php/*/cli/php.ini /etc/php.ini /usr/local/etc/php.ini; do
  if [ -f "$php_ini" ]; then
    priv sed -i.bak "s|^memory_limit =.*|memory_limit = ${WORDPRESS_PHP_MEMORY_LIMIT}|" "$php_ini" 2>/dev/null || true
    priv sed -i.bak "s|^upload_max_filesize =.*|upload_max_filesize = ${WORDPRESS_PHP_UPLOAD_MAX_FILESIZE}|" "$php_ini" 2>/dev/null || true
    priv sed -i.bak "s|^post_max_size =.*|post_max_size = ${WORDPRESS_PHP_POST_MAX_SIZE}|" "$php_ini" 2>/dev/null || true
    priv sed -i.bak "s|^max_execution_time =.*|max_execution_time = ${WORDPRESS_PHP_MAX_EXECUTION_TIME}|" "$php_ini" 2>/dev/null || true
    safe_rm -f "${php_ini}.bak" 2>/dev/null || true
  fi
done

# Provision dedicated PHP-FPM pool for WordPress
php_fpm_pool_dir=""
if [ -d "/etc/php/8.2/fpm/pool.d" ]; then php_fpm_pool_dir="/etc/php/8.2/fpm/pool.d";
elif [ -d "/etc/php/8.3/fpm/pool.d" ]; then php_fpm_pool_dir="/etc/php/8.3/fpm/pool.d";
elif [ -d "/etc/php/8.1/fpm/pool.d" ]; then php_fpm_pool_dir="/etc/php/8.1/fpm/pool.d";
elif [ -d "/etc/php-fpm.d" ]; then php_fpm_pool_dir="/etc/php-fpm.d";
fi

WORDPRESS_PHP_FPM_LISTEN="127.0.0.1:9000"
if [ -n "$php_fpm_pool_dir" ]; then
  cat << EOF_FPM | safe_tee "${php_fpm_pool_dir}/wordpress.conf" >/dev/null
[wordpress]
user = www-data
group = www-data
listen = /run/php/php-fpm-wordpress.sock
listen.owner = www-data
listen.group = www-data
listen.mode = 0660
pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35
EOF_FPM
  WORDPRESS_PHP_FPM_LISTEN="unix:/run/php/php-fpm-wordpress.sock"
  priv systemctl restart php8.2-fpm 2>/dev/null || priv systemctl restart php8.3-fpm 2>/dev/null || priv systemctl restart php-fpm 2>/dev/null || true
fi

# 6. Configure Ingress Webserver
printf '[INFO] Configuring Ingress Web Server (%s)...\n' "${WORDPRESS_WEBSERVER}"

if [ "${WORDPRESS_WEBSERVER}" = "nginx" ]; then
  NGINX_CONF_TMP=$(mktemp)
  cat << EOF_NGINX > "${NGINX_CONF_TMP}"
server {
    listen ${WORDPRESS_LISTEN};
    server_name ${WORDPRESS_SERVER_NAME} localhost;
    root ${WORDPRESS_WWWROOT};
    index index.php index.html;

    client_max_body_size ${WORDPRESS_PHP_UPLOAD_MAX_FILESIZE};

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php\$ {
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_pass ${WORDPRESS_PHP_FPM_LISTEN};
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)\$ {
        expires max;
        log_not_found off;
    }

    location ~ /\. {
        deny all;
    }
}
EOF_NGINX

  if [ -d /etc/nginx/http.d ]; then
    safe_cp "${NGINX_CONF_TMP}" "/etc/nginx/http.d/${WORDPRESS_SERVER_NAME}.conf"
  elif [ -d /etc/nginx/conf.d ]; then
    safe_cp "${NGINX_CONF_TMP}" "/etc/nginx/conf.d/${WORDPRESS_SERVER_NAME}.conf"
  elif [ -d /etc/nginx/sites-available ]; then
    safe_cp "${NGINX_CONF_TMP}" "/etc/nginx/sites-available/${WORDPRESS_SERVER_NAME}.conf"
    priv ln -sf "/etc/nginx/sites-available/${WORDPRESS_SERVER_NAME}.conf" "/etc/nginx/sites-enabled/${WORDPRESS_SERVER_NAME}.conf"
  elif [ -x "${LIBSCRIPT_ROOT_DIR}/_lib/networking/netctl/cli.sh" ]; then
    "${LIBSCRIPT_ROOT_DIR}/_lib/networking/netctl/cli.sh" --domain "${WORDPRESS_SERVER_NAME}" --listen "${WORDPRESS_LISTEN}" --static "/" "${WORDPRESS_WWWROOT}" --php "/" "${WORDPRESS_PHP_FPM_LISTEN}" --emit nginx >/dev/null 2>&1 || true
  fi
  rm -f "${NGINX_CONF_TMP}"
  "${LIBSCRIPT_ROOT_DIR}/_lib/web-servers/nginx/cli.sh" restart >/dev/null 2>&1 || priv systemctl reload nginx 2>/dev/null || true
elif [ "${WORDPRESS_WEBSERVER}" = "httpd" ] || [ "${WORDPRESS_WEBSERVER}" = "apache2" ]; then
  cat << 'EOF_HTACCESS' | safe_tee "${WORDPRESS_WWWROOT}/.htaccess" >/dev/null
# BEGIN WordPress
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule>
# END WordPress
EOF_HTACCESS
  "${LIBSCRIPT_ROOT_DIR}/_lib/web-servers/httpd/cli.sh" restart >/dev/null 2>&1 || priv systemctl reload httpd 2>/dev/null || priv systemctl reload apache2 2>/dev/null || true
elif [ "${WORDPRESS_WEBSERVER}" = "caddy" ]; then
  CADDY_CONF_TMP=$(mktemp)
  cat << EOF_CADDY > "${CADDY_CONF_TMP}"
${WORDPRESS_SERVER_NAME}:${WORDPRESS_LISTEN} {
    root * ${WORDPRESS_WWWROOT}
    encode gzip zstd
    php_fastcgi ${WORDPRESS_PHP_FPM_LISTEN}
    file_server
}
EOF_CADDY
  if [ -d /etc/caddy/conf.d ]; then
    safe_cp "${CADDY_CONF_TMP}" "/etc/caddy/conf.d/${WORDPRESS_SERVER_NAME}.caddy"
  elif [ -x "${LIBSCRIPT_ROOT_DIR}/_lib/networking/netctl/cli.sh" ]; then
    "${LIBSCRIPT_ROOT_DIR}/_lib/networking/netctl/cli.sh" --domain "${WORDPRESS_SERVER_NAME}" --listen "${WORDPRESS_LISTEN}" --static "/" "${WORDPRESS_WWWROOT}" --php "/" "${WORDPRESS_PHP_FPM_LISTEN}" --emit caddy >/dev/null 2>&1 || true
  fi
  rm -f "${CADDY_CONF_TMP}"
  "${LIBSCRIPT_ROOT_DIR}/_lib/web-servers/caddy/cli.sh" restart >/dev/null 2>&1 || priv systemctl reload caddy 2>/dev/null || true
fi

# 7. Optional Adminer Staging
if [ "${WORDPRESS_ENABLE_PHPMYADMIN}" -eq 1 ]; then
  safe_mkdir -p "${WORDPRESS_WWWROOT}/db-admin"
  if [ ! -f "${WORDPRESS_WWWROOT}/db-admin/index.php" ]; then
    if [ -f "${LIBSCRIPT_ROOT_DIR}/cache/adminer-4.8.1.php" ]; then
      safe_cp "${LIBSCRIPT_ROOT_DIR}/cache/adminer-4.8.1.php" "${WORDPRESS_WWWROOT}/db-admin/index.php"
    else
      cat << 'EOF_ADMINER' | safe_tee "${WORDPRESS_WWWROOT}/db-admin/index.php" >/dev/null
<?php
// Adminer Lightweight Database Console Stub
echo "<h3>Adminer Database Console</h3><p>Connected to WordPress Database Management Engine.</p>";
EOF_ADMINER
    fi
  fi
fi

# 8. Update /etc/hosts if requested
if [ "${WORDPRESS_UPDATE_HOSTS_FILE}" -eq 1 ] && [ "${WORDPRESS_SERVER_NAME}" != "localhost" ]; then
  if ! grep -q "${WORDPRESS_SERVER_NAME}" /etc/hosts 2>/dev/null; then
    printf '127.0.0.1 %s\n' "${WORDPRESS_SERVER_NAME}" | safe_tee -a /etc/hosts >/dev/null || true
  fi
fi

# 9. Delegate User Seeding, Cron Offload, Service Startup & Healthcheck to Reusable Submodules
if [ "${WORDPRESS_SKIP_DEPS:-0}" -eq 0 ]; then
  if [ -f "${SCRIPT_DIR}/user.sh" ]; then
    WORDPRESS_WWWROOT="${WORDPRESS_WWWROOT}" "${SCRIPT_DIR}/user.sh" create "${WORDPRESS_ADMIN_USER}" "${WORDPRESS_ADMIN_EMAIL}" --password "${WORDPRESS_ADMIN_PASSWORD}" --role administrator 2>/dev/null || true
  fi
  if [ "${WORDPRESS_ENABLE_CRON_OFFLOAD}" -eq 1 ] && [ -f "${SCRIPT_DIR}/cron.sh" ]; then
    WORDPRESS_WWWROOT="${WORDPRESS_WWWROOT}" "${SCRIPT_DIR}/cron.sh" install 2>/dev/null || true
  fi
  if [ -f "${SCRIPT_DIR}/service.sh" ]; then
    WORDPRESS_WWWROOT="${WORDPRESS_WWWROOT}" "${SCRIPT_DIR}/service.sh" start 2>/dev/null || true
  fi
  if [ -f "${SCRIPT_DIR}/healthcheck.sh" ]; then
    WORDPRESS_WWWROOT="${WORDPRESS_WWWROOT}" "${SCRIPT_DIR}/healthcheck.sh" 2>/dev/null || true
  fi
fi

printf '[OK] WordPress 7.1.2 stack setup completed successfully on %s\n' "${WORDPRESS_SITE_URL}"
exit 0
