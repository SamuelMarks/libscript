#!/bin/sh
# shellcheck disable=SC2016,SC1090,SC1091,SC2034,SC2018,SC2019,SC2221,SC2222,SC2129,SC2209,SC2089,SC2090,SC2086,SC2154,SC2044,SC2181,SC2038,SC2155,SC2046,SC2002,SC1003,SC2295,SC2145

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
  . "${SCRIPT_NAME}"
done

MAGENTO_VERSION="${MAGENTO_VERSION:-2.4.6}"
export MAGENTO_VERSION
MAGENTO_WEBSERVER="${MAGENTO_WEBSERVER:-nginx}"
export MAGENTO_WEBSERVER
MAGENTO_DB_DRIVER="${MAGENTO_DB_DRIVER:-mariadb}"
export MAGENTO_DB_DRIVER

# Check if required tools are available
depends 'php'
if [ "${MAGENTO_WEBSERVER}" = "nginx" ] || [ "${MAGENTO_WEBSERVER}" = "caddy" ]; then
  depends 'php-fpm' || true
fi
depends 'composer' || true
depends "${MAGENTO_DB_DRIVER}" || true
depends "${MAGENTO_WEBSERVER}"

WWWROOT="${WWWROOT:-/var/www/magento}"
export WWWROOT

if [ ! -d "${WWWROOT}/app" ]; then
  echo "Downloading Magento (${MAGENTO_VERSION}) to ${WWWROOT}..."
  priv mkdir -p "${WWWROOT}"
  
  # For a full install without auth.json typically use a pre-packaged tarball, but we use github releases for simplicity
  dl_url="https://github.com/magento/magento2/archive/refs/tags/${MAGENTO_VERSION}.tar.gz"
  
  if command -v libscript_download >/dev/null 2>&1; then
    tmp_magento=$(mktemp)
    libscript_download "${dl_url}" "${tmp_magento}"
    priv tar xzf "${tmp_magento}" --strip-components=1 -C "${WWWROOT}"
    rm -f "${tmp_magento}"
  else
    wget -qO- "${dl_url}" | priv tar xz --strip-components=1 -C "${WWWROOT}"
  fi
  
  if command -v composer >/dev/null 2>&1; then
    cd "${WWWROOT}"
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
    priv sudo -u postgres psql -c "CREATE DATABASE ${DB_NAME};" || true
    priv sudo -u postgres psql -c "CREATE USER ${DB_USER} WITH ENCRYPTED PASSWORD '${DB_PASS}';" || true
    priv sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};" || true
  fi
elif [ "${MAGENTO_DB_DRIVER}" = "sqlite" ]; then
  if command -v sqlite3 >/dev/null 2>&1; then
    priv sqlite3 "${WWWROOT}/magento.sqlite" "VACUUM;" || true
  fi
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

# Configure Webserver
SERVER_NAME="${MAGENTO_SERVER_NAME:-localhost}"
export SERVER_NAME

echo "Configuring webserver: ${MAGENTO_WEBSERVER}"

ENV_SCRIPT_FILE=$(mktemp)
cat <<EOF > "${ENV_SCRIPT_FILE}"
export SERVER_NAME="${SERVER_NAME}"
export WWWROOT="${WWWROOT}/pub"
export PHP_FPM_LISTEN="${PHP_FPM_LISTEN}"
export LISTEN="${MAGENTO_LISTEN:-80}"
export LOCATION_EXPR="/"
EOF
export ENV_SCRIPT_FILE

if [ "${MAGENTO_WEBSERVER}" = "nginx" ]; then
  LOC_BLOCK_TMP=$(mktemp)
  env SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_server/nginx/create_location_block.sh" "${LIBSCRIPT_ROOT_DIR}/_lib/_server/nginx/create_location_block.sh" > "${LOC_BLOCK_TMP}"
  
  LOCATIONS="$(cat "${LOC_BLOCK_TMP}")"
  export LOCATIONS
  SERVER_BLOCK_TMP=$(mktemp)
  env SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_server/nginx/create_server_block.sh" "${LIBSCRIPT_ROOT_DIR}/_lib/_server/nginx/create_server_block.sh" > "${SERVER_BLOCK_TMP}"
  
  NGINX_CONF_DIR="${LIBSCRIPT_ROOT_DIR}/installed/nginx/conf"
  if [ -d /etc/nginx/sites-available ]; then
    NGINX_CONF_DIR="/etc/nginx"
  fi
  
  priv cp "${SERVER_BLOCK_TMP}" "${NGINX_CONF_DIR}/sites-available/${SERVER_NAME}.conf"
  priv ln -sf "${NGINX_CONF_DIR}/sites-available/${SERVER_NAME}.conf" "${NGINX_CONF_DIR}/sites-enabled/${SERVER_NAME}.conf"
  priv systemctl reload nginx || true
  rm -f "${LOC_BLOCK_TMP}" "${SERVER_BLOCK_TMP}"
elif [ "${MAGENTO_WEBSERVER}" = "caddy" ]; then
  CADDY_BLOCK_TMP=$(mktemp)
  env SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_server/caddy/create_server_block.sh" "${LIBSCRIPT_ROOT_DIR}/_lib/_server/caddy/create_server_block.sh" > "${CADDY_BLOCK_TMP}"
  if [ -d /etc/caddy/conf.d ] || [ -d /etc/caddy/caddy.d ]; then
    conf_dir="/etc/caddy/conf.d"
    [ -d /etc/caddy/caddy.d ] && conf_dir="/etc/caddy/caddy.d"
    priv cp "${CADDY_BLOCK_TMP}" "${conf_dir}/${SERVER_NAME}.caddy"
  else
    priv tee -a /etc/caddy/Caddyfile < "${CADDY_BLOCK_TMP}" >/dev/null
  fi
  priv systemctl reload caddy || true
  rm -f "${CADDY_BLOCK_TMP}"
elif [ "${MAGENTO_WEBSERVER}" = "httpd" ]; then
  HTTPD_BLOCK_TMP=$(mktemp)
  env SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_server/httpd/create_server_block.sh" "${LIBSCRIPT_ROOT_DIR}/_lib/_server/httpd/create_server_block.sh" > "${HTTPD_BLOCK_TMP}"
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

echo "Magento setup complete on ${SERVER_NAME}"
