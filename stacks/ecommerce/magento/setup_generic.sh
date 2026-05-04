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

MAGENTO_VERSION="${MAGENTO_VERSION:-2.4.6}"
export MAGENTO_VERSION
MAGENTO_WEBSERVER="${MAGENTO_WEBSERVER:-nginx}"
export MAGENTO_WEBSERVER
MAGENTO_DB_DRIVER="${MAGENTO_DB_DRIVER:-mariadb}"
export MAGENTO_DB_DRIVER

# Check if required tools are available
libscript_depends 'php'
if [ "${MAGENTO_WEBSERVER}" = "nginx" ] || [ "${MAGENTO_WEBSERVER}" = "caddy" ]; then
  if ! libscript_depends 'php-fpm' ; then
    true
  fi
fi
if ! libscript_depends 'composer' ; then
  true
fi
if ! libscript_depends "${MAGENTO_DB_DRIVER}" ; then
  true
fi
libscript_depends "${MAGENTO_WEBSERVER}"

MAGENTO_WWWROOT="${MAGENTO_WWWROOT:-/var/www/magento}"
export MAGENTO_WWWROOT

if [ ! -d "${MAGENTO_WWWROOT}/app" ]; then
  echo "Downloading Magento (${MAGENTO_VERSION}) to ${MAGENTO_WWWROOT}..."
  priv mkdir -p "${MAGENTO_WWWROOT}"

  # For a full install without auth.json typically use a pre-packaged tarball, but we use github releases for simplicity
  dl_url="https://github.com/magento/magento2/archive/refs/tags/${MAGENTO_VERSION}.tar.gz"

  if command -v libscript_download >/dev/null 2>&1; then
    tmp_magento=$(mktemp)
    libscript_download "${dl_url}" "${tmp_magento}"
    priv tar xzf "${tmp_magento}" --strip-components=1 -C "${MAGENTO_WWWROOT}"
    rm -f "${tmp_magento}"
  else
    wget -qO- "${dl_url}" | priv tar xz --strip-components=1 -C "${MAGENTO_WWWROOT}"
  fi

  if command -v composer >/dev/null 2>&1; then
    cd "${MAGENTO_WWWROOT}"
    composer install --no-interaction || true
    cd - >/dev/null
  fi
fi

# Setup Database
DB_NAME="${MAGENTO_DB_NAME:-magento}"
DB_USER="${MAGENTO_DB_USER:-magento}"
DB_PASS="${MAGENTO_DB_PASS:-magento}"
DB_HOST="${MAGENTO_DB_HOST:-127.0.0.1}"

echo "Configuring Database (${MAGENTO_DB_DRIVER})..."
if [ "${MAGENTO_DB_DRIVER}" = "mariadb" ] || [ "${MAGENTO_DB_DRIVER}" = "mysql" ]; then
  if command -v mysql >/dev/null 2>&1 && priv mysql -u root -e "SELECT 1" >/dev/null 2>&1; then
    priv mysql -u root -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;"
    priv mysql -u root -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'${DB_HOST}' IDENTIFIED BY '${DB_PASS}';"
    priv mysql -u root -e "GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'${DB_HOST}';"
    priv mysql -u root -e "FLUSH PRIVILEGES;"
  fi
elif [ "${MAGENTO_DB_DRIVER}" = "postgres" ] || [ "${MAGENTO_DB_DRIVER}" = "postgresql" ]; then
  if command -v psql >/dev/null 2>&1 && priv sudo -u postgres psql -c "SELECT 1" >/dev/null 2>&1; then
    priv sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname = '${DB_NAME}'" | grep -q 1 || priv sudo -u postgres psql -c "CREATE DATABASE ${DB_NAME};"
    priv sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname = '${DB_USER}'" | grep -q 1 || priv sudo -u postgres psql -c "CREATE USER ${DB_USER} WITH ENCRYPTED PASSWORD '${DB_PASS}';"
    priv sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};"
  fi
elif [ "${MAGENTO_DB_DRIVER}" = "sqlite" ]; then
  if command -v sqlite3 >/dev/null 2>&1; then
    priv sqlite3 "${MAGENTO_WWWROOT}/magento.sqlite" "VACUUM;" || true
  fi
fi

if ! priv chown -R www-data:www-data "${MAGENTO_WWWROOT}" ; then
  true
fi

if [ -z "${MAGENTO_PHP_FPM_LISTEN:-}" ]; then
  if [ -e /run/php/php-fpm.sock ]; then
    export MAGENTO_PHP_FPM_LISTEN="unix:/run/php/php-fpm.sock"
  elif [ -e /var/run/php-fpm/php-fpm.sock ]; then
    export MAGENTO_PHP_FPM_LISTEN="unix:/var/run/php-fpm/php-fpm.sock"
  elif [ -e /var/run/php-fpm.sock ]; then
    export MAGENTO_PHP_FPM_LISTEN="unix:/var/run/php-fpm.sock"
  else
    export MAGENTO_PHP_FPM_LISTEN="127.0.0.1:9000"
    for sock in /run/php/php*.sock; do
      if [ -e "$sock" ]; then
        export MAGENTO_PHP_FPM_LISTEN="unix:$sock"
        break
      fi
    done
  fi
fi

# Configure Webserver
MAGENTO_SERVER_NAME="${MAGENTO_SERVER_NAME:-localhost}"
export MAGENTO_SERVER_NAME

echo "Configuring webserver: ${MAGENTO_WEBSERVER}"

ENV_SCRIPT_FILE=$(mktemp)
cat <<EOF > "${ENV_SCRIPT_FILE}"
export MAGENTO_SERVER_NAME="${MAGENTO_SERVER_NAME}"
export MAGENTO_WWWROOT="${MAGENTO_WWWROOT}/pub"
export MAGENTO_PHP_FPM_LISTEN="${MAGENTO_PHP_FPM_LISTEN}"
export LISTEN="${MAGENTO_LISTEN:-80}"
export NGINX_LISTEN="${MAGENTO_LISTEN:-80}"
export HTTPD_LISTEN="${MAGENTO_LISTEN:-80}"
export CADDY_LISTEN="${MAGENTO_LISTEN:-80}"
export LOCATION_EXPR="/"
export NGINX_LOCATION_EXPR="/"
export NGINX_SERVER_NAME="${MAGENTO_SERVER_NAME}"
export NGINX_WWWROOT="${MAGENTO_WWWROOT}"
export NGINX_PHP_FPM_LISTEN="${MAGENTO_PHP_FPM_LISTEN}"
export HTTPD_SERVER_NAME="${MAGENTO_SERVER_NAME}"
export HTTPD_WWWROOT="${MAGENTO_WWWROOT}"
export HTTPD_PHP_FPM_LISTEN="${MAGENTO_PHP_FPM_LISTEN}"
export CADDY_SERVER_NAME="${MAGENTO_SERVER_NAME}"
export CADDY_WWWROOT="${MAGENTO_WWWROOT}"
export CADDY_PHP_FPM_LISTEN="${MAGENTO_PHP_FPM_LISTEN}"
EOF
export ENV_SCRIPT_FILE

if [ "${MAGENTO_WEBSERVER}" = "nginx" ]; then
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

  priv cp "${SERVER_BLOCK_TMP}" "${NGINX_CONF_DIR}/sites-available/${MAGENTO_SERVER_NAME}.conf"
  priv ln -sf "${NGINX_CONF_DIR}/sites-available/${MAGENTO_SERVER_NAME}.conf" "${NGINX_CONF_DIR}/sites-enabled/${MAGENTO_SERVER_NAME}.conf"
  if ! priv systemctl reload nginx ; then
    true
  fi
  rm -f "${LOC_BLOCK_TMP}" "${SERVER_BLOCK_TMP}"
elif [ "${MAGENTO_WEBSERVER}" = "caddy" ]; then
  CADDY_BLOCK_TMP=$(mktemp)
  env SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/web-servers/caddy/create_server_block.sh" "${LIBSCRIPT_ROOT_DIR}/_lib/web-servers/caddy/create_server_block.sh" > "${CADDY_BLOCK_TMP}"
  if [ -d /etc/caddy/conf.d ] || [ -d /etc/caddy/caddy.d ]; then
    conf_dir="/etc/caddy/conf.d"
    [ -d /etc/caddy/caddy.d ] && conf_dir="/etc/caddy/caddy.d"
    priv cp "${CADDY_BLOCK_TMP}" "${conf_dir}/${MAGENTO_SERVER_NAME}.caddy"
  else
    priv tee -a /etc/caddy/Caddyfile < "${CADDY_BLOCK_TMP}" >/dev/null
  fi
  if ! priv systemctl reload caddy ; then
    true
  fi
  rm -f "${CADDY_BLOCK_TMP}"
elif [ "${MAGENTO_WEBSERVER}" = "httpd" ]; then
  HTTPD_BLOCK_TMP=$(mktemp)
  env SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/web-servers/httpd/create_server_block.sh" "${LIBSCRIPT_ROOT_DIR}/_lib/web-servers/httpd/create_server_block.sh" > "${HTTPD_BLOCK_TMP}"
  if [ -d /etc/httpd/conf.d ]; then
    priv cp "${HTTPD_BLOCK_TMP}" "/etc/httpd/conf.d/${MAGENTO_SERVER_NAME}.conf"
    if ! priv systemctl reload httpd ; then
      true
    fi
  elif [ -d /etc/apache2/sites-available ]; then
    priv cp "${HTTPD_BLOCK_TMP}" "/etc/apache2/sites-available/${MAGENTO_SERVER_NAME}.conf"
    priv ln -sf "/etc/apache2/sites-available/${MAGENTO_SERVER_NAME}.conf" "/etc/apache2/sites-enabled/${MAGENTO_SERVER_NAME}.conf"
    if ! priv systemctl reload apache2 ; then
      true
    fi
  else
    priv tee -a /etc/httpd/conf/httpd.conf < "${HTTPD_BLOCK_TMP}" >/dev/null
  fi
  rm -f "${HTTPD_BLOCK_TMP}"
fi

rm -f "${ENV_SCRIPT_FILE}"

echo "Magento setup complete on ${MAGENTO_SERVER_NAME}"
