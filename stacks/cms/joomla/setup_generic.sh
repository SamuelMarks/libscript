#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  this_file="${(%):-%x}"
  set -o pipefail
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
JOOMLA_WEBSERVER="${JOOMLA_WEBSERVER:-nginx}"
export JOOMLA_WEBSERVER

JOOMLA_DB_TYPE="${JOOMLA_DB_TYPE:-mariadb}"
export JOOMLA_DB_TYPE

depends 'php'
if [ "${JOOMLA_WEBSERVER}" = "nginx" ] || [ "${JOOMLA_WEBSERVER}" = "caddy" ]; then
  depends 'php-fpm' || true # Some package managers include FPM in 'php'
fi

# SQLite is not strictly supported in Joomla 4+, so we map "sqlite" to warning
if [ "${JOOMLA_DB_TYPE}" = "sqlite" ]; then
  echo "Warning: SQLite is not natively supported by Joomla 4+. Defaulting to mariadb installation."
  JOOMLA_DB_TYPE="mariadb"
fi

depends "${JOOMLA_DB_TYPE}"
depends "${JOOMLA_WEBSERVER}"

# Download and extract Joomla
JOOMLA_VERSION="${JOOMLA_VERSION:-latest}"
export JOOMLA_VERSION

WWWROOT="${WWWROOT:-/var/www/joomla}"
export WWWROOT

if [ ! -d "${WWWROOT}/administrator" ]; then
  echo "Downloading Joomla (${JOOMLA_VERSION}) to ${WWWROOT}..."
  priv mkdir -p "${WWWROOT}"
  
  if [ "${JOOMLA_VERSION}" = "latest" ]; then
    if command -v curl >/dev/null 2>&1; then
      JOOMLA_VERSION=$(curl -s "https://api.github.com/repos/joomla/joomla-cms/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    else
      JOOMLA_VERSION="5.2.0" # Fallback if curl unavailable
    fi
  fi
  
  dl_url="https://github.com/joomla/joomla-cms/releases/download/${JOOMLA_VERSION}/Joomla_${JOOMLA_VERSION}-Stable-Full_Package.tar.gz"
  
  tmp_j=$(mktemp)
  if command -v libscript_download >/dev/null 2>&1; then
    libscript_download "${dl_url}" "${tmp_j}"
    priv tar xzf "${tmp_j}" -C "${WWWROOT}"
  else
    if command -v wget >/dev/null 2>&1; then
        wget -qO "${tmp_j}" "${dl_url}"
    else
        curl -sL -o "${tmp_j}" "${dl_url}"
    fi
    priv tar xzf "${tmp_j}" -C "${WWWROOT}"
  fi
  rm -f "${tmp_j}"
fi

# Setup Database
DB_NAME="${JOOMLA_DB_NAME:-joomla}"
DB_USER="${JOOMLA_DB_USER:-joomla}"
DB_PASS="${JOOMLA_DB_PASS:-joomla}"

echo "Configuring Database..."
if [ "${JOOMLA_DB_TYPE}" = "mariadb" ] || [ "${JOOMLA_DB_TYPE}" = "mysql" ]; then
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
elif [ "${JOOMLA_DB_TYPE}" = "postgres" ] || [ "${JOOMLA_DB_TYPE}" = "postgresql" ]; then
  if command -v psql >/dev/null 2>&1; then
    if priv -u postgres psql -c "SELECT 1" >/dev/null 2>&1; then
      priv -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname = '${DB_USER}'" | grep -q 1 || priv -u postgres psql -c "CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASS}';"
      priv -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname = '${DB_NAME}'" | grep -q 1 || priv -u postgres psql -c "CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};"
      priv -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};"
    else
      echo "Warning: PostgreSQL is not running or login failed. Skipping automated DB setup."
    fi
  fi
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
SERVER_NAME="${JOOMLA_SERVER_NAME:-localhost}"
export SERVER_NAME

echo "Configuring webserver: ${JOOMLA_WEBSERVER}"

# Create a temporary env file for webserver scripts
ENV_SCRIPT_FILE=$(mktemp)
cat <<EOF > "${ENV_SCRIPT_FILE}"
export SERVER_NAME="${SERVER_NAME}"
export WWWROOT="${WWWROOT}"
export PHP_FPM_LISTEN="${PHP_FPM_LISTEN}"
export LISTEN="${JOOMLA_LISTEN:-80}"
export LOCATION_EXPR="/"
EOF
export ENV_SCRIPT_FILE

if [ "${JOOMLA_WEBSERVER}" = "nginx" ]; then
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
  if ! priv systemctl reload nginx ; then
    true
  fi
  rm -f "${LOC_BLOCK_TMP}" "${SERVER_BLOCK_TMP}"
elif [ "${JOOMLA_WEBSERVER}" = "caddy" ]; then
  CADDY_BLOCK_TMP=$(mktemp)
  env SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/web-servers/caddy/create_server_block.sh" "${LIBSCRIPT_ROOT_DIR}/_lib/web-servers/caddy/create_server_block.sh" > "${CADDY_BLOCK_TMP}"
  if [ -d /etc/caddy/conf.d ] || [ -d /etc/caddy/caddy.d ]; then
    conf_dir="/etc/caddy/conf.d"
    [ -d /etc/caddy/caddy.d ] && conf_dir="/etc/caddy/caddy.d"
    priv cp "${CADDY_BLOCK_TMP}" "${conf_dir}/${SERVER_NAME}.caddy"
  else
    priv tee -a /etc/caddy/Caddyfile < "${CADDY_BLOCK_TMP}" >/dev/null
  fi
  if ! priv systemctl reload caddy ; then
    true
  fi
  rm -f "${CADDY_BLOCK_TMP}"
elif [ "${JOOMLA_WEBSERVER}" = "httpd" ]; then
  HTTPD_BLOCK_TMP=$(mktemp)
  env SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/web-servers/httpd/create_server_block.sh" "${LIBSCRIPT_ROOT_DIR}/_lib/web-servers/httpd/create_server_block.sh" > "${HTTPD_BLOCK_TMP}"
  if [ -d /etc/httpd/conf.d ]; then
    priv cp "${HTTPD_BLOCK_TMP}" "/etc/httpd/conf.d/${SERVER_NAME}.conf"
    if ! priv systemctl reload httpd ; then
      true
    fi
  elif [ -d /etc/apache2/sites-available ]; then
    priv cp "${HTTPD_BLOCK_TMP}" "/etc/apache2/sites-available/${SERVER_NAME}.conf"
    priv ln -sf "/etc/apache2/sites-available/${SERVER_NAME}.conf" "/etc/apache2/sites-enabled/${SERVER_NAME}.conf"
    if ! priv systemctl reload apache2 ; then
      true
    fi
  else
    priv tee -a /etc/httpd/conf/httpd.conf < "${HTTPD_BLOCK_TMP}" >/dev/null
  fi
  rm -f "${HTTPD_BLOCK_TMP}"
fi

rm -f "${ENV_SCRIPT_FILE}"

echo "Joomla setup complete on ${SERVER_NAME}"
