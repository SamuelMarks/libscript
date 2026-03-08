#!/bin/sh
# shellcheck disable=SC3054,SC3040,SC2296,SC2128,SC2039,SC2016,SC1090,SC1091,SC2034,SC2018,SC2019,SC2221,SC2222,SC2129,SC2209,SC2089,SC2090,SC2086,SC2154,SC2044,SC2181,SC2038,SC2155,SC2046,SC2002,SC1003,SC2295,SC2145



set -feu
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE}"

elif [ "${ZSH_VERSION-}" ]; then
  this_file="${0}"

else
  this_file="${0}"
fi

case "${STACK+x}" in
  *':'"${this_file}"':'*)
    printf '[STOP]     processing "%s"\n' "${this_file}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${this_file}" ;;
esac
export STACK="${STACK:-}${this_file}"':'

DIR=$(CDPATH='' cd -- "$(dirname -- "${this_file}")" && pwd)
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(d="${DIR}"; while [ ! -f "${d}"'/ROOT' ]; do d="$(dirname -- "${d}")"; done; printf '%s' "${d}")}"

for lib in '_lib/_common/pkg_mgr.sh' '_lib/_common/os_info.sh'; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  # shellcheck source=/dev/null
# shellcheck disable=SC1090,SC1091,SC2034
  . "${SCRIPT_NAME}"
done

# Check if required tools are available
WORDPRESS_WEBSERVER="${WORDPRESS_WEBSERVER:-nginx}"
export WORDPRESS_WEBSERVER

depends 'php'
if [ "${WORDPRESS_WEBSERVER}" = "nginx" ] || [ "${WORDPRESS_WEBSERVER}" = "caddy" ]; then
  depends 'php-fpm' || true # Some package managers include FPM in 'php'
fi
WORDPRESS_DB_ENGINE="${WORDPRESS_DB_ENGINE:-mariadb}"
export WORDPRESS_DB_ENGINE

if [ "${WORDPRESS_DB_ENGINE}" = "sqlite" ]; then
  depends 'sqlite' || depends 'sqlite3'
elif [ "${WORDPRESS_DB_ENGINE}" = "postgres" ] || [ "${WORDPRESS_DB_ENGINE}" = "postgresql" ]; then
  depends 'postgres' || depends 'postgresql'
else
  depends 'mariadb' || depends 'mysql'
fi
depends "${WORDPRESS_WEBSERVER}"

# Download and extract WordPress
WORDPRESS_VERSION="${WORDPRESS_VERSION:-latest}"
export WORDPRESS_VERSION

WWWROOT="${WWWROOT:-/var/www/wordpress}"
export WWWROOT

if [ ! -d "${WWWROOT}/wp-admin" ]; then
  echo "Downloading WordPress (${WORDPRESS_VERSION}) to ${WWWROOT}..."
  priv mkdir -p "${WWWROOT}"
  if [ "${WORDPRESS_VERSION}" = "latest" ]; then
    dl_url="https://wordpress.org/latest.tar.gz"
  else
    dl_url="https://wordpress.org/wordpress-${WORDPRESS_VERSION}.tar.gz"
  fi
  
  if command -v libscript_download >/dev/null 2>&1; then
    tmp_wp=$(mktemp)
    libscript_download "${dl_url}" "${tmp_wp}"
    priv tar xzf "${tmp_wp}" --strip-components=1 -C "${WWWROOT}"
    rm -f "${tmp_wp}"
  else
    wget -qO- "${dl_url}" | priv tar xz --strip-components=1 -C "${WWWROOT}"
  fi
fi

# Setup Database
DB_NAME="${WORDPRESS_DB_NAME:-wordpress}"
DB_USER="${WORDPRESS_DB_USER:-wordpress}"
DB_PASS="${WORDPRESS_DB_PASS:-wordpress}"

echo "Configuring Database..."
if [ "${WORDPRESS_DB_ENGINE}" = "sqlite" ]; then
  depends 'unzip'
  # No DB service needed for SQLite
  # We just need to download the sqlite-database-integration drop-in
  if [ ! -f "${WWWROOT}/wp-content/db.php" ]; then
    priv mkdir -p "${WWWROOT}/wp-content/mu-plugins"
    dl_sqlite_url="https://downloads.wordpress.org/plugin/sqlite-database-integration.zip"
    tmp_sqlite=$(mktemp)
    if command -v libscript_download >/dev/null 2>&1; then
      libscript_download "${dl_sqlite_url}" "${tmp_sqlite}"
    else
      wget -qO "${tmp_sqlite}" "${dl_sqlite_url}"
    fi
    priv unzip -q -o "${tmp_sqlite}" -d "${WWWROOT}/wp-content/plugins"
    priv cp "${WWWROOT}/wp-content/plugins/sqlite-database-integration/db.copy" "${WWWROOT}/wp-content/db.php"
    rm -f "${tmp_sqlite}"
    priv sed -i "s|{SQLITE_DB_DROPIN_VERSION}|1.0.0|" "${WWWROOT}/wp-content/db.php" || true
    priv sed -i "s|{SQLITE_PLUGIN}|sqlite-database-integration/load.php|" "${WWWROOT}/wp-content/db.php" || true
    echo "SQLite database integration plugin installed."
  fi
elif [ "${WORDPRESS_DB_ENGINE}" = "postgres" ] || [ "${WORDPRESS_DB_ENGINE}" = "postgresql" ]; then
  depends 'unzip'
  # Install PG4WP drop-in
  if [ ! -f "${WWWROOT}/wp-content/db.php" ]; then
    dl_pg_url="https://downloads.wordpress.org/plugin/postgresql-for-wordpress.zip"
    tmp_pg=$(mktemp)
    if command -v libscript_download >/dev/null 2>&1; then
      libscript_download "${dl_pg_url}" "${tmp_pg}"
    else
      wget -qO "${tmp_pg}" "${dl_pg_url}"
    fi
    priv unzip -q -o "${tmp_pg}" -d "${WWWROOT}/wp-content"
    priv mv "${WWWROOT}/wp-content/postgresql-for-wordpress/pg4wp" "${WWWROOT}/wp-content/"
    priv cp "${WWWROOT}/wp-content/pg4wp/db.php" "${WWWROOT}/wp-content/db.php"
    rm -f "${tmp_pg}"
    echo "PostgreSQL drop-in installed."
  fi
  # Attempt to create PG database
  if command -v psql >/dev/null 2>&1; then
    if priv -u postgres psql -c '\q' >/dev/null 2>&1 || priv psql -U postgres -c '\q' >/dev/null 2>&1; then
      priv -u postgres psql -c "CREATE DATABASE \"${DB_NAME}\";" || true
      priv -u postgres psql -c "CREATE USER \"${DB_USER}\" WITH ENCRYPTED PASSWORD '${DB_PASS}';" || true
      priv -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE \"${DB_NAME}\" TO \"${DB_USER}\";" || true
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

if [ ! -f "${WWWROOT}/wp-config.php" ]; then
  priv cp "${WWWROOT}/wp-config-sample.php" "${WWWROOT}/wp-config.php"
  priv sed -i "s/database_name_here/${DB_NAME}/" "${WWWROOT}/wp-config.php"
  priv sed -i "s/username_here/${DB_USER}/" "${WWWROOT}/wp-config.php"
  priv sed -i "s/password_here/${DB_PASS}/" "${WWWROOT}/wp-config.php"
fi
priv chown -R www-data:www-data "${WWWROOT}" || true # fallback for distros without www-data

# Determine PHP_FPM Socket (OS specific usually)
if [ -z "${PHP_FPM_LISTEN:-}" ]; then
  if [ -e /run/php/php-fpm.sock ]; then
    export PHP_FPM_LISTEN="unix:/run/php/php-fpm.sock"
  elif [ -e /var/run/php-fpm/php-fpm.sock ]; then
    export PHP_FPM_LISTEN="unix:/var/run/php-fpm/php-fpm.sock"
  elif [ -e /var/run/php-fpm.sock ]; then
    export PHP_FPM_LISTEN="unix:/var/run/php-fpm.sock"
  else
    # Let's try to find it dynamically or fallback to localhost port
    export PHP_FPM_LISTEN="127.0.0.1:9000"
    for sock in /run/php/php*.sock; do
      if [ -e "$sock" ]; then
        export PHP_FPM_LISTEN="unix:$sock"
        break
      fi
    done
  fi
fi

# Configure Webserver
SERVER_NAME="${WORDPRESS_SERVER_NAME:-localhost}"
export SERVER_NAME

echo "Configuring webserver: ${WORDPRESS_WEBSERVER}"

# Create a temporary env file for webserver scripts
ENV_SCRIPT_FILE=$(mktemp)
cat <<EOF > "${ENV_SCRIPT_FILE}"
export SERVER_NAME="${SERVER_NAME}"
export WWWROOT="${WWWROOT}"
export PHP_FPM_LISTEN="${PHP_FPM_LISTEN}"
export LISTEN="${WORDPRESS_LISTEN:-80}"
export LOCATION_EXPR="/"
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
  
  priv cp "${SERVER_BLOCK_TMP}" "${NGINX_CONF_DIR}/sites-available/${SERVER_NAME}.conf"
  priv ln -sf "${NGINX_CONF_DIR}/sites-available/${SERVER_NAME}.conf" "${NGINX_CONF_DIR}/sites-enabled/${SERVER_NAME}.conf"
  priv systemctl reload nginx || true
  rm -f "${LOC_BLOCK_TMP}" "${SERVER_BLOCK_TMP}"
elif [ "${WORDPRESS_WEBSERVER}" = "caddy" ]; then
  CADDY_BLOCK_TMP=$(mktemp)
  env SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/web-servers/caddy/create_server_block.sh" "${LIBSCRIPT_ROOT_DIR}/_lib/web-servers/caddy/create_server_block.sh" > "${CADDY_BLOCK_TMP}"
  if [ -d /etc/caddy/conf.d ] || [ -d /etc/caddy/caddy.d ]; then
    conf_dir="/etc/caddy/conf.d"
    [ -d /etc/caddy/caddy.d ] && conf_dir="/etc/caddy/caddy.d"
    priv cp "${CADDY_BLOCK_TMP}" "${conf_dir}/${SERVER_NAME}.caddy"
  else
    priv tee -a /etc/caddy/Caddyfile < "${CADDY_BLOCK_TMP}" >/dev/null
  fi
  priv systemctl reload caddy || true
  rm -f "${CADDY_BLOCK_TMP}"
elif [ "${WORDPRESS_WEBSERVER}" = "httpd" ]; then
  HTTPD_BLOCK_TMP=$(mktemp)
  env SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/web-servers/httpd/create_server_block.sh" "${LIBSCRIPT_ROOT_DIR}/_lib/web-servers/httpd/create_server_block.sh" > "${HTTPD_BLOCK_TMP}"
  if [ -d /etc/httpd/conf.d ]; then
    priv cp "${HTTPD_BLOCK_TMP}" "/etc/httpd/conf.d/${SERVER_NAME}.conf"
    priv systemctl reload httpd || true
  elif [ -d /etc/apache2/sites-available ]; then
    priv cp "${HTTPD_BLOCK_TMP}" "/etc/apache2/sites-available/${SERVER_NAME}.conf"
    priv ln -sf "/etc/apache2/sites-available/${SERVER_NAME}.conf" "/etc/apache2/sites-enabled/${SERVER_NAME}.conf"
    priv systemctl reload apache2 || true
  else
    priv tee -a /etc/httpd/conf/httpd.conf < "${HTTPD_BLOCK_TMP}" >/dev/null
  fi
  rm -f "${HTTPD_BLOCK_TMP}"
fi

rm -f "${ENV_SCRIPT_FILE}"

echo "WordPress setup complete on ${SERVER_NAME}"
