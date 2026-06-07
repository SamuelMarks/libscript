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
DIR=$(cd "$(dirname -- "${THIS_FILE}")" && pwd)
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(D="${DIR}"; while [ ! -f "${D}/ROOT" ] && [ "${D}" != "/" ]; do D="$(dirname -- "${D}")"; done; [ "${D}" = "/" ] && D="${DIR}"; printf '%s' "${D}")}"

for LIB in "_lib/_common/pkg_mgr.sh' '_lib/_common/os_info.sh'; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck source=/dev/null
# shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done

PHPBB_WEBSERVER="${PHPBB_WEBSERVER:-nginx}"
export PHPBB_WEBSERVER

PHPBB_DB_TYPE="${PHPBB_DB_TYPE:-sqlite}"
export PHPBB_DB_TYPE

libscript_depends 'php'
if [ "${PHPBB_WEBSERVER}" = "nginx" ] || [ "${PHPBB_WEBSERVER}" = "caddy" ]; then
  if ! libscript_depends 'php-fpm' ; then
    true
  fi
fi

case "${PHPBB_DB_TYPE}" in
  mysql|mariadb) libscript_depends 'mariadb' ;;
  pgsql|postgres|postgresql) libscript_depends 'postgres' ;;
  sqlite) libscript_depends 'sqlite' ;;
  *) echo "Unsupported DB type: ${PHPBB_DB_TYPE}"; exit 1 ;;
esac

libscript_depends "${PHPBB_WEBSERVER}"

PHPBB_VERSION="${PHPBB_VERSION:-3.3.11}"
export PHPBB_VERSION

PHPBB_MAJOR_VERSION=$(echo "${PHPBB_VERSION}" | cut -d. -f1,2)

PHPBB_WWWROOT="${PHPBB_WWWROOT:-/var/www/phpbb}"
export PHPBB_WWWROOT

if [ ! -d "${PHPBB_WWWROOT}/phpbb" ] && [ ! -d "${PHPBB_WWWROOT}/install" ]; then
  echo "Downloading phpBB (${PHPBB_VERSION}) to ${PHPBB_WWWROOT}..."
  priv mkdir -p "${PHPBB_WWWROOT}"
  dl_url="https://download.phpbb.com/pub/release/${PHPBB_MAJOR_VERSION}/${PHPBB_VERSION}/phpBB-${PHPBB_VERSION}.tar.bz2"

  if ! libscript_depends 'bzip2' ; then
    true
  fi
  if command -v libscript_download >/dev/null 2>&1; then
    tmp_dp=$(mktemp)
    libscript_download "${dl_url}" "${tmp_dp}"
    priv tar xjf "${tmp_dp}" --strip-components=1 -C "${PHPBB_WWWROOT}"
    rm -f "${tmp_dp}"
  else
    wget -qO- "${dl_url}" | priv tar xj --strip-components=1 -C "${PHPBB_WWWROOT}"
  fi
fi

DB_NAME="${PHPBB_DB_NAME:-phpbb}"
DB_USER="${PHPBB_DB_USER:-phpbb}"
DB_PASS="${PHPBB_DB_PASS:-phpbb}"

echo "Configuring Database..."
if [ "${PHPBB_DB_TYPE}" = "mariadb" ] || [ "${PHPBB_DB_TYPE}" = "mysql" ]; then
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
elif [ "${PHPBB_DB_TYPE}" = "postgres" ] || [ "${PHPBB_DB_TYPE}" = "postgresql" ] || [ "${PHPBB_DB_TYPE}" = "pgsql" ]; then
  if command -v psql >/dev/null 2>&1; then
    if priv su - postgres -c "psql -c 'SELECT 1'" >/dev/null 2>&1; then
      priv su - postgres -c "psql -tc \"SELECT 1 FROM pg_database WHERE datname = '${DB_NAME}'\"" | grep -q 1 || priv su - postgres -c "createdb ${DB_NAME}"
      priv su - postgres -c "psql -tc \"SELECT 1 FROM pg_roles WHERE rolname = '${DB_USER}'\"" | grep -q 1 || priv su - postgres -c "psql -c \"CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASS}'\""
      priv su - postgres -c "psql -c \"GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER}\""
    else
      echo "Warning: PostgreSQL is not running or root login failed. Skipping automated DB setup."
    fi
  fi
elif [ "${PHPBB_DB_TYPE}" = "sqlite" ]; then
  priv mkdir -p "${PHPBB_WWWROOT}/store"
fi

if ! priv chown -R www-data:www-data "${PHPBB_WWWROOT}" ; then
  true
fi
if ! priv chmod 666 "${PHPBB_WWWROOT}/config.php" ; then
  true
fi
if ! priv chmod -R 777 "${PHPBB_WWWROOT}/store/" "${PHPBB_WWWROOT}/cache/" "${PHPBB_WWWROOT}/files/" "${PHPBB_WWWROOT}/images/avatars/upload/" ; then
  true
fi

if [ -z "${PHPBB_PHP_FPM_LISTEN:-}" ]; then
  if [ -e /run/php/php-fpm.sock ]; then
    export PHPBB_PHP_FPM_LISTEN="unix:/run/php/php-fpm.sock"
  elif [ -e /var/run/php-fpm/php-fpm.sock ]; then
    export PHPBB_PHP_FPM_LISTEN="unix:/var/run/php-fpm/php-fpm.sock"
  elif [ -e /var/run/php-fpm.sock ]; then
    export PHPBB_PHP_FPM_LISTEN="unix:/var/run/php-fpm.sock"
  else
    export PHPBB_PHP_FPM_LISTEN="127.0.0.1:9000"
    for sock in /run/php/php*.sock; do
      if [ -e "$sock" ]; then
        export PHPBB_PHP_FPM_LISTEN="unix:$sock"
        break
      fi
    done
  fi
fi

PHPBB_SERVER_NAME="${PHPBB_SERVER_NAME:-localhost}"
export PHPBB_SERVER_NAME

echo "Configuring webserver: ${PHPBB_WEBSERVER}"

ENV_SCRIPT_FILE=$(mktemp)
cat <<ENV_EOF > "${ENV_SCRIPT_FILE}"
export PHPBB_SERVER_NAME="${PHPBB_SERVER_NAME}"
export PHPBB_WWWROOT="${PHPBB_WWWROOT}"
export PHPBB_PHP_FPM_LISTEN="${PHPBB_PHP_FPM_LISTEN}"
export LISTEN="${PHPBB_LISTEN:-80}"
export NGINX_LISTEN="${PHPBB_LISTEN:-80}"
export HTTPD_LISTEN="${PHPBB_LISTEN:-80}"
export CADDY_LISTEN="${PHPBB_LISTEN:-80}"
export LOCATION_EXPR="/"
export NGINX_LOCATION_EXPR="/"
ENV_EOF
export ENV_SCRIPT_FILE

if [ "${PHPBB_WEBSERVER}" = "nginx" ]; then
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

  priv cp "${SERVER_BLOCK_TMP}" "${NGINX_CONF_DIR}/sites-available/${PHPBB_SERVER_NAME}.conf"
  priv ln -sf "${NGINX_CONF_DIR}/sites-available/${PHPBB_SERVER_NAME}.conf" "${NGINX_CONF_DIR}/sites-enabled/${PHPBB_SERVER_NAME}.conf"
  if ! priv systemctl reload nginx ; then
    true
  fi
  rm -f "${LOC_BLOCK_TMP}" "${SERVER_BLOCK_TMP}"
elif [ "${PHPBB_WEBSERVER}" = "caddy" ]; then
  CADDY_BLOCK_TMP=$(mktemp)
  env SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/web-servers/caddy/create_server_block.sh" "${LIBSCRIPT_ROOT_DIR}/_lib/web-servers/caddy/create_server_block.sh" > "${CADDY_BLOCK_TMP}"
  if [ -d /etc/caddy/conf.d ] || [ -d /etc/caddy/caddy.d ]; then
    conf_dir="/etc/caddy/conf.d"
    [ -d /etc/caddy/caddy.d ] && conf_dir="/etc/caddy/caddy.d"
    priv cp "${CADDY_BLOCK_TMP}" "${conf_dir}/${PHPBB_SERVER_NAME}.caddy"
  else
    priv tee -a /etc/caddy/Caddyfile < "${CADDY_BLOCK_TMP}" >/dev/null
  fi
  if ! priv systemctl reload caddy ; then
    true
  fi
  rm -f "${CADDY_BLOCK_TMP}"
elif [ "${PHPBB_WEBSERVER}" = "httpd" ]; then
  HTTPD_BLOCK_TMP=$(mktemp)
  env SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/web-servers/httpd/create_server_block.sh" "${LIBSCRIPT_ROOT_DIR}/_lib/web-servers/httpd/create_server_block.sh" > "${HTTPD_BLOCK_TMP}"
  if [ -d /etc/httpd/conf.d ]; then
    priv cp "${HTTPD_BLOCK_TMP}" "/etc/httpd/conf.d/${PHPBB_SERVER_NAME}.conf"
    if ! priv systemctl reload httpd ; then
      true
    fi
  elif [ -d /etc/apache2/sites-available ]; then
    priv cp "${HTTPD_BLOCK_TMP}" "/etc/apache2/sites-available/${PHPBB_SERVER_NAME}.conf"
    priv ln -sf "/etc/apache2/sites-available/${PHPBB_SERVER_NAME}.conf" "/etc/apache2/sites-enabled/${PHPBB_SERVER_NAME}.conf"
    if ! priv systemctl reload apache2 ; then
      true
    fi
  else
    priv tee -a /etc/httpd/conf/httpd.conf < "${HTTPD_BLOCK_TMP}" >/dev/null
  fi
  rm -f "${HTTPD_BLOCK_TMP}"
fi

rm -f "${ENV_SCRIPT_FILE}"
echo "phpBB setup complete on ${PHPBB_SERVER_NAME}"
