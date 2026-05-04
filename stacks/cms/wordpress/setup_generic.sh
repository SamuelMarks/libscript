#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  THIS_FILE="${(%):-%x}"
  set -o pipefail
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
DIR=$(CDPATH='' cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(D="${DIR}"; while [ ! -f "${D}"'/ROOT' ]; do D="$(dirname -- "${D}")"; done; printf '%s' "${D}")}"

for LIB in "_lib/_common/pkg_mgr.sh' '_lib/_common/os_info.sh'; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  # shellcheck source=/dev/null
# shellcheck disable=SC1090,SC1091,SC2034
  . "${SCRIPT_NAME}"
done

# Check if required tools are available
WORDPRESS_WEBSERVER="${WORDPRESS_WEBSERVER:-nginx}"
export WORDPRESS_WEBSERVER

libscript_depends 'php'
if [ "${WORDPRESS_WEBSERVER}" = "nginx" ] || [ "${WORDPRESS_WEBSERVER}" = "caddy" ]; then
  libscript_depends 'php-fpm' || true # Some package managers include FPM in 'php'
fi
WORDPRESS_DB_ENGINE="${WORDPRESS_DB_ENGINE:-mariadb}"
export WORDPRESS_DB_ENGINE

if [ "${WORDPRESS_DB_ENGINE}" = "sqlite" ]; then
  libscript_depends 'sqlite' || libscript_depends 'sqlite3'
elif [ "${WORDPRESS_DB_ENGINE}" = "postgres" ] || [ "${WORDPRESS_DB_ENGINE}" = "postgresql" ]; then
  libscript_depends 'postgres' || libscript_depends 'postgresql'
else
  libscript_depends 'mariadb' || libscript_depends 'mysql'
fi
libscript_depends "${WORDPRESS_WEBSERVER}"

# Download and extract WordPress
WORDPRESS_VERSION="${WORDPRESS_VERSION:-latest}"
export WORDPRESS_VERSION

WORDPRESS_WWWROOT="${WORDPRESS_WWWROOT:-/var/www/wordpress}"
export WORDPRESS_WWWROOT

if [ ! -d "${WORDPRESS_WWWROOT}/wp-admin" ]; then
  echo "Downloading WordPress (${WORDPRESS_VERSION}) to ${WORDPRESS_WWWROOT}..."
  priv mkdir -p "${WORDPRESS_WWWROOT}"
  if [ "${WORDPRESS_VERSION}" = "latest" ]; then
    dl_url="https://wordpress.org/latest.tar.gz"
  else
    dl_url="https://wordpress.org/wordpress-${WORDPRESS_VERSION}.tar.gz"
  fi

  if command -v libscript_download >/dev/null 2>&1; then
    tmp_wp=$(mktemp)
    libscript_download "${dl_url}" "${tmp_wp}"
    priv tar xzf "${tmp_wp}" --strip-components=1 -C "${WORDPRESS_WWWROOT}"
    rm -f "${tmp_wp}"
  else
    wget -qO- "${dl_url}" | priv tar xz --strip-components=1 -C "${WORDPRESS_WWWROOT}"
  fi
fi

# Setup Database
DB_NAME="${WORDPRESS_DB_NAME:-wordpress}"
DB_USER="${WORDPRESS_DB_USER:-wordpress}"
DB_PASS="${WORDPRESS_DB_PASS:-wordpress}"

echo "Configuring Database..."
if [ "${WORDPRESS_DB_ENGINE}" = "sqlite" ]; then
  libscript_depends 'unzip'
  # No DB service needed for SQLite
  # We just need to download the sqlite-database-integration drop-in
  if [ ! -f "${WORDPRESS_WWWROOT}/wp-content/db.php" ]; then
    priv mkdir -p "${WORDPRESS_WWWROOT}/wp-content/mu-plugins"
    dl_sqlite_url="https://downloads.wordpress.org/plugin/sqlite-database-integration.zip"
    tmp_sqlite=$(mktemp)
    if command -v libscript_download >/dev/null 2>&1; then
      libscript_download "${dl_sqlite_url}" "${tmp_sqlite}"
    else
      wget -qO "${tmp_sqlite}" "${dl_sqlite_url}"
    fi
    priv unzip -q -o "${tmp_sqlite}" -d "${WORDPRESS_WWWROOT}/wp-content/plugins"
    priv cp "${WORDPRESS_WWWROOT}/wp-content/plugins/sqlite-database-integration/db.copy" "${WORDPRESS_WWWROOT}/wp-content/db.php"
    rm -f "${tmp_sqlite}"
    priv sed -i "s|{SQLITE_DB_DROPIN_VERSION}|1.0.0|" "${WORDPRESS_WWWROOT}/wp-content/db.php" || true
    priv sed -i "s|{SQLITE_PLUGIN}|sqlite-database-integration/load.php|" "${WORDPRESS_WWWROOT}/wp-content/db.php" || true
    echo "SQLite database integration plugin installed."
  fi
elif [ "${WORDPRESS_DB_ENGINE}" = "postgres" ] || [ "${WORDPRESS_DB_ENGINE}" = "postgresql" ]; then
  libscript_depends 'unzip'
  # Install PG4WP drop-in
  if [ ! -f "${WORDPRESS_WWWROOT}/wp-content/db.php" ]; then
    dl_pg_url="https://downloads.wordpress.org/plugin/postgresql-for-wordpress.zip"
    tmp_pg=$(mktemp)
    if command -v libscript_download >/dev/null 2>&1; then
      libscript_download "${dl_pg_url}" "${tmp_pg}"
    else
      wget -qO "${tmp_pg}" "${dl_pg_url}"
    fi
    priv unzip -q -o "${tmp_pg}" -d "${WORDPRESS_WWWROOT}/wp-content"
    priv mv "${WORDPRESS_WWWROOT}/wp-content/postgresql-for-wordpress/pg4wp" "${WORDPRESS_WWWROOT}/wp-content/"
    priv cp "${WORDPRESS_WWWROOT}/wp-content/pg4wp/db.php" "${WORDPRESS_WWWROOT}/wp-content/db.php"
    rm -f "${tmp_pg}"
    echo "PostgreSQL drop-in installed."
  fi
  # Attempt to create PG database
  if command -v psql >/dev/null 2>&1; then
    if priv -u postgres psql -c '\q' >/dev/null 2>&1 || priv psql -U postgres -c '\q' >/dev/null 2>&1; then
      priv -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname = '${DB_NAME}'" | grep -q 1 || priv -u postgres psql -c "CREATE DATABASE \"${DB_NAME}\";"
      priv -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname = '${DB_USER}'" | grep -q 1 || priv -u postgres psql -c "CREATE USER \"${DB_USER}\" WITH ENCRYPTED PASSWORD '${DB_PASS}';"
      priv -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE \"${DB_NAME}\" TO \"${DB_USER}\";"
    else
      echo "Warning: PostgreSQL is not running or root login failed. Skipping automated DB setup."
    fi
  fi
else
  # Default MariaDB / MySQL
  if command -v mysql >/dev/null 2>&1; then
    if priv mysql -u root -e "SELECT 1" >/dev/null 2>&1; then
      priv mysql -u root -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;"
      priv mysql -u root -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
      priv mysql -u root -e "GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';"
      priv mysql -u root -e "FLUSH PRIVILEGES;"
    else
      echo "Warning: MariaDB/MySQL is not running or root login failed. Skipping automated DB setup."
    fi
  fi
fi

if [ ! -f "${WORDPRESS_WWWROOT}/wp-config.php" ]; then
  priv cp "${WORDPRESS_WWWROOT}/wp-config-sample.php" "${WORDPRESS_WWWROOT}/wp-config.php"
  priv sed -i "s/database_name_here/${DB_NAME}/" "${WORDPRESS_WWWROOT}/wp-config.php"
  priv sed -i "s/username_here/${DB_USER}/" "${WORDPRESS_WWWROOT}/wp-config.php"
  priv sed -i "s/password_here/${DB_PASS}/" "${WORDPRESS_WWWROOT}/wp-config.php"
fi
priv chown -R www-data:www-data "${WORDPRESS_WWWROOT}" || true # fallback for distros without www-data

# Determine PHP_FPM Socket (OS specific usually)
if [ -z "${WORDPRESS_PHP_FPM_LISTEN:-}" ]; then
  if [ -e /run/php/php-fpm.sock ]; then
    export WORDPRESS_PHP_FPM_LISTEN="unix:/run/php/php-fpm.sock"
  elif [ -e /var/run/php-fpm/php-fpm.sock ]; then
    export WORDPRESS_PHP_FPM_LISTEN="unix:/var/run/php-fpm/php-fpm.sock"
  elif [ -e /var/run/php-fpm.sock ]; then
    export WORDPRESS_PHP_FPM_LISTEN="unix:/var/run/php-fpm.sock"
  else
    # Let's try to find it dynamically or fallback to localhost port
    export WORDPRESS_PHP_FPM_LISTEN="127.0.0.1:9000"
    for sock in /run/php/php*.sock; do
      if [ -e "$sock" ]; then
        export WORDPRESS_PHP_FPM_LISTEN="unix:$sock"
        break
      fi
    done
  fi
fi

# Configure Webserver
WORDPRESS_SERVER_NAME="${WORDPRESS_SERVER_NAME:-localhost}"
export WORDPRESS_SERVER_NAME

echo "Configuring webserver: ${WORDPRESS_WEBSERVER}"

# Create a temporary env file for webserver scripts
ENV_SCRIPT_FILE=$(mktemp)
cat <<EOF > "${ENV_SCRIPT_FILE}"
export WORDPRESS_SERVER_NAME="${WORDPRESS_SERVER_NAME}"
export WORDPRESS_WWWROOT="${WORDPRESS_WWWROOT}"
export WORDPRESS_PHP_FPM_LISTEN="${WORDPRESS_PHP_FPM_LISTEN}"
export LISTEN="${WORDPRESS_LISTEN:-80}"
export NGINX_LISTEN="${WORDPRESS_LISTEN:-80}"
export HTTPD_LISTEN="${WORDPRESS_LISTEN:-80}"
export CADDY_LISTEN="${WORDPRESS_LISTEN:-80}"
export LOCATION_EXPR="/"
export NGINX_LOCATION_EXPR="/"
export NGINX_SERVER_NAME="${WORDPRESS_SERVER_NAME}"
export NGINX_WWWROOT="${WORDPRESS_WWWROOT}"
export NGINX_PHP_FPM_LISTEN="${WORDPRESS_PHP_FPM_LISTEN}"
export HTTPD_SERVER_NAME="${WORDPRESS_SERVER_NAME}"
export HTTPD_WWWROOT="${WORDPRESS_WWWROOT}"
export HTTPD_PHP_FPM_LISTEN="${WORDPRESS_PHP_FPM_LISTEN}"
export CADDY_SERVER_NAME="${WORDPRESS_SERVER_NAME}"
export CADDY_WWWROOT="${WORDPRESS_WWWROOT}"
export CADDY_PHP_FPM_LISTEN="${WORDPRESS_PHP_FPM_LISTEN}"
EOF
export ENV_SCRIPT_FILE

if [ "${WORDPRESS_WEBSERVER}" = "nginx" ]; then
  LOC_BLOCK_TMP=$(mktemp)
  env SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/web-servers/nginx/create_location_block.sh" "${LIBSCRIPT_ROOT_DIR}/_lib/web-servers/nginx/create_location_block.sh" > "${LOC_BLOCK_TMP}"

  LOCATIONS="$(cat "${LOC_BLOCK_TMP}")"
  export LOCATIONS
  SERVER_BLOCK_TMP=$(mktemp)
  env SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/web-servers/nginx/create_server_block.sh" "${LIBSCRIPT_ROOT_DIR}/_lib/web-servers/nginx/create_server_block.sh" > "${SERVER_BLOCK_TMP}"

  NGINX_CONF_DIR="${LIBSCRIPT_ROOT_DIR}/installed/nginx/conf"
  if [ -d /etc/nginx/sites-available ]; then
    NGINX_CONF_DIR="/etc/nginx"
  fi

  priv cp "${SERVER_BLOCK_TMP}" "${NGINX_CONF_DIR}/sites-available/${WORDPRESS_SERVER_NAME}.conf"
  priv ln -sf "${NGINX_CONF_DIR}/sites-available/${WORDPRESS_SERVER_NAME}.conf" "${NGINX_CONF_DIR}/sites-enabled/${WORDPRESS_SERVER_NAME}.conf"
  if ! priv systemctl reload nginx ; then
    true
  fi
  rm -f "${LOC_BLOCK_TMP}" "${SERVER_BLOCK_TMP}"
elif [ "${WORDPRESS_WEBSERVER}" = "caddy" ]; then
  CADDY_BLOCK_TMP=$(mktemp)
  env SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/web-servers/caddy/create_server_block.sh" "${LIBSCRIPT_ROOT_DIR}/_lib/web-servers/caddy/create_server_block.sh" > "${CADDY_BLOCK_TMP}"
  if [ -d /etc/caddy/conf.d ] || [ -d /etc/caddy/caddy.d ]; then
    conf_dir="/etc/caddy/conf.d"
    [ -d /etc/caddy/caddy.d ] && conf_dir="/etc/caddy/caddy.d"
    priv cp "${CADDY_BLOCK_TMP}" "${conf_dir}/${WORDPRESS_SERVER_NAME}.caddy"
  else
    priv tee -a /etc/caddy/Caddyfile < "${CADDY_BLOCK_TMP}" >/dev/null
  fi
  if ! priv systemctl reload caddy ; then
    true
  fi
  rm -f "${CADDY_BLOCK_TMP}"
elif [ "${WORDPRESS_WEBSERVER}" = "httpd" ]; then
  HTTPD_BLOCK_TMP=$(mktemp)
  env SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/web-servers/httpd/create_server_block.sh" "${LIBSCRIPT_ROOT_DIR}/_lib/web-servers/httpd/create_server_block.sh" > "${HTTPD_BLOCK_TMP}"
  if [ -d /etc/httpd/conf.d ]; then
    priv cp "${HTTPD_BLOCK_TMP}" "/etc/httpd/conf.d/${WORDPRESS_SERVER_NAME}.conf"
    if ! priv systemctl reload httpd ; then
      true
    fi
  elif [ -d /etc/apache2/sites-available ]; then
    priv cp "${HTTPD_BLOCK_TMP}" "/etc/apache2/sites-available/${WORDPRESS_SERVER_NAME}.conf"
    priv ln -sf "/etc/apache2/sites-available/${WORDPRESS_SERVER_NAME}.conf" "/etc/apache2/sites-enabled/${WORDPRESS_SERVER_NAME}.conf"
    if ! priv systemctl reload apache2 ; then
      true
    fi
  else
    priv tee -a /etc/httpd/conf/httpd.conf < "${HTTPD_BLOCK_TMP}" >/dev/null
  fi
  rm -f "${HTTPD_BLOCK_TMP}"
fi

rm -f "${ENV_SCRIPT_FILE}"

echo "WordPress setup complete on ${WORDPRESS_SERVER_NAME}"
