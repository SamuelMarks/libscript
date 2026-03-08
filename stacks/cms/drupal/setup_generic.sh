#!/bin/sh
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
  # shellcheck source=/dev/null
# shellcheck disable=SC1090,SC1091,SC2034
  . "${SCRIPT_NAME}"
done

DRUPAL_WEBSERVER="${DRUPAL_WEBSERVER:-nginx}"
export DRUPAL_WEBSERVER

DRUPAL_DB_TYPE="${DRUPAL_DB_TYPE:-sqlite}"
export DRUPAL_DB_TYPE

depends 'php'
if [ "${DRUPAL_WEBSERVER}" = "nginx" ] || [ "${DRUPAL_WEBSERVER}" = "caddy" ]; then
  depends 'php-fpm' || true
fi

case "${DRUPAL_DB_TYPE}" in
  mysql|mariadb) depends 'mariadb' ;;
  pgsql|postgres|postgresql) depends 'postgres' ;;
  sqlite) depends 'sqlite' ;;
  *) echo "Unsupported DB type: ${DRUPAL_DB_TYPE}"; exit 1 ;;
esac

depends "${DRUPAL_WEBSERVER}"

DRUPAL_VERSION="${DRUPAL_VERSION:-10.2.6}"
export DRUPAL_VERSION

WWWROOT="${WWWROOT:-/var/www/drupal}"
export WWWROOT

if [ ! -d "${WWWROOT}/core" ]; then
  echo "Downloading Drupal (${DRUPAL_VERSION}) to ${WWWROOT}..."
  priv mkdir -p "${WWWROOT}"
  dl_url="https://ftp.drupal.org/files/projects/drupal-${DRUPAL_VERSION}.tar.gz"
  
  if command -v libscript_download >/dev/null 2>&1; then
    tmp_dp=$(mktemp)
    libscript_download "${dl_url}" "${tmp_dp}"
    priv tar xzf "${tmp_dp}" --strip-components=1 -C "${WWWROOT}"
    rm -f "${tmp_dp}"
  else
    wget -qO- "${dl_url}" | priv tar xz --strip-components=1 -C "${WWWROOT}"
  fi
fi

DB_NAME="${DRUPAL_DB_NAME:-drupal}"
DB_USER="${DRUPAL_DB_USER:-drupal}"
DB_PASS="${DRUPAL_DB_PASS:-drupal}"

echo "Configuring Database..."
if [ "${DRUPAL_DB_TYPE}" = "mariadb" ] || [ "${DRUPAL_DB_TYPE}" = "mysql" ]; then
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
elif [ "${DRUPAL_DB_TYPE}" = "postgres" ] || [ "${DRUPAL_DB_TYPE}" = "postgresql" ] || [ "${DRUPAL_DB_TYPE}" = "pgsql" ]; then
  if command -v psql >/dev/null 2>&1; then
    if priv su - postgres -c "psql -c 'SELECT 1'" >/dev/null 2>&1; then
      priv su - postgres -c "psql -tc \"SELECT 1 FROM pg_database WHERE datname = '${DB_NAME}'\"" | grep -q 1 || priv su - postgres -c "createdb ${DB_NAME}"
      priv su - postgres -c "psql -tc \"SELECT 1 FROM pg_roles WHERE rolname = '${DB_USER}'\"" | grep -q 1 || priv su - postgres -c "psql -c \"CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASS}'\""
      priv su - postgres -c "psql -c \"GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER}\""
    else
      echo "Warning: PostgreSQL is not running or root login failed. Skipping automated DB setup."
    fi
  fi
elif [ "${DRUPAL_DB_TYPE}" = "sqlite" ]; then
  # For sqlite we just need to make sure directory is writable
  priv mkdir -p "${WWWROOT}/sites/default/files"
fi

priv chown -R www-data:www-data "${WWWROOT}" || true

if [ -z "${PHP_FPM_LISTEN:-}" ]; then
  if [ -e /run/php/php-fpm.sock ]; then
    export PHP_FPM_LISTEN="unix:/run/php/php-fpm.sock"
  elif [ -e /var/run/php-fpm/php-fpm.sock ]; then
    export PHP_FPM_LISTEN="unix:/var/run/php-fpm/php-fpm.sock"
  elif [ -e /var/run/php-fpm.sock ]; then
    export PHP_FPM_LISTEN="unix:/var/run/php-fpm.sock"
  else
    export PHP_FPM_LISTEN="127.0.0.1:9000"
    for sock in /run/php/php*.sock; do
      if [ -e "$sock" ]; then
        export PHP_FPM_LISTEN="unix:$sock"
        break
      fi
    done
  fi
fi

SERVER_NAME="${DRUPAL_SERVER_NAME:-localhost}"
export SERVER_NAME

echo "Configuring webserver: ${DRUPAL_WEBSERVER}"

ENV_SCRIPT_FILE=$(mktemp)
cat <<ENV_EOF > "${ENV_SCRIPT_FILE}"
export SERVER_NAME="${SERVER_NAME}"
export WWWROOT="${WWWROOT}"
export PHP_FPM_LISTEN="${PHP_FPM_LISTEN}"
export LISTEN="${DRUPAL_LISTEN:-80}"
export LOCATION_EXPR="/"
ENV_EOF
export ENV_SCRIPT_FILE

if [ "${DRUPAL_WEBSERVER}" = "nginx" ]; then
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
elif [ "${DRUPAL_WEBSERVER}" = "caddy" ]; then
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
elif [ "${DRUPAL_WEBSERVER}" = "httpd" ]; then
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
echo "Drupal setup complete on ${SERVER_NAME}"
