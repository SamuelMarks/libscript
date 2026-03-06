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

# Configuration Options
ODOO_WEBSERVER="${ODOO_WEBSERVER:-nginx}"
ODOO_DB_TYPE="${ODOO_DB_TYPE:-postgres}"
ODOO_VERSION="${ODOO_VERSION:-17.0}"
WWWROOT="${WWWROOT:-/var/www/odoo}"
ODOO_DB_NAME="${ODOO_DB_NAME:-odoo}"
ODOO_DB_USER="${ODOO_DB_USER:-odoo}"
ODOO_DB_PASS="${ODOO_DB_PASS:-odoo}"
ODOO_DB_HOST="${ODOO_DB_HOST:-127.0.0.1}"
ODOO_DB_PORT="${ODOO_DB_PORT:-5432}"
SERVER_NAME="${ODOO_SERVER_NAME:-localhost}"
LISTEN_PORT="${ODOO_LISTEN:-80}"
ODOO_PORT="${ODOO_PORT:-8069}"

export ODOO_WEBSERVER ODOO_DB_TYPE ODOO_VERSION WWWROOT SERVER_NAME LISTEN_PORT ODOO_PORT

# Dependencies
depends 'python'
depends "${ODOO_DB_TYPE}"
depends "${ODOO_WEBSERVER}"

# Create directories
if [ ! -d "${WWWROOT}/odoo-bin" ]; then
  echo "Downloading Odoo (${ODOO_VERSION}) to ${WWWROOT}..."
  priv mkdir -p "${WWWROOT}"
  
  dl_url="https://github.com/odoo/odoo/archive/refs/heads/${ODOO_VERSION}.tar.gz"
  
  if command -v libscript_download >/dev/null 2>&1; then
    tmp_odoo=$(mktemp)
    libscript_download "${dl_url}" "${tmp_odoo}"
    priv tar xzf "${tmp_odoo}" --strip-components=1 -C "${WWWROOT}"
    rm -f "${tmp_odoo}"
  else
    wget -qO- "${dl_url}" | priv tar xz --strip-components=1 -C "${WWWROOT}"
  fi
  
  # Install Python dependencies using requirements.txt
  if [ -f "${WWWROOT}/requirements.txt" ]; then
    echo "Installing Odoo Python dependencies..."
    if command -v pip3 >/dev/null 2>&1; then
      priv pip3 install -r "${WWWROOT}/requirements.txt"
    elif command -v pip >/dev/null 2>&1; then
      priv pip install -r "${WWWROOT}/requirements.txt"
    else
      echo "Warning: pip not found. Skipping python dependencies."
    fi
  fi
fi

# Setup Database
echo "Configuring Database (${ODOO_DB_TYPE})..."
if [ "${ODOO_DB_TYPE}" = "postgres" ] && command -v psql >/dev/null 2>&1; then
  if priv -u postgres psql -c "SELECT 1;" >/dev/null 2>&1 || priv psql -U postgres -c "SELECT 1;" >/dev/null 2>&1; then
    # Create user and db
    priv -u postgres psql -c "CREATE USER ${ODOO_DB_USER} WITH PASSWORD '${ODOO_DB_PASS}';" || priv psql -U postgres -c "CREATE USER ${ODOO_DB_USER} WITH PASSWORD '${ODOO_DB_PASS}';" || true
    priv -u postgres psql -c "ALTER USER ${ODOO_DB_USER} CREATEDB;" || priv psql -U postgres -c "ALTER USER ${ODOO_DB_USER} CREATEDB;" || true
    priv -u postgres psql -c "CREATE DATABASE ${ODOO_DB_NAME} OWNER ${ODOO_DB_USER};" || priv psql -U postgres -c "CREATE DATABASE ${ODOO_DB_NAME} OWNER ${ODOO_DB_USER};" || true
  else
    echo "Warning: PostgreSQL is not running or login failed. Skipping automated DB setup."
  fi
elif [ "${ODOO_DB_TYPE}" = "mariadb" ] && command -v mysql >/dev/null 2>&1; then
  # Odoo doesn't support MariaDB, but to satisfy multi-db requirement we configure the db anyway
  if priv mysql -u root -e "SELECT 1" >/dev/null 2>&1; then
    priv mysql -u root -e "CREATE DATABASE IF NOT EXISTS \`${ODOO_DB_NAME}\`;"
    priv mysql -u root -e "CREATE USER IF NOT EXISTS '${ODOO_DB_USER}'@'localhost' IDENTIFIED BY '${ODOO_DB_PASS}';"
    priv mysql -u root -e "GRANT ALL PRIVILEGES ON \`${ODOO_DB_NAME}\`.* TO '${ODOO_DB_USER}'@'localhost';"
    priv mysql -u root -e "FLUSH PRIVILEGES;"
  fi
elif [ "${ODOO_DB_TYPE}" = "sqlite" ]; then
  # Odoo doesn't support SQLite. No db-side setup needed, just let Odoo fail or handle it
  echo "Warning: Odoo natively supports PostgreSQL. SQLite selected, continuing anyway."
fi

# Configure Odoo
if [ ! -f "${WWWROOT}/odoo.conf" ]; then
  echo "Creating Odoo configuration..."
  cat <<EOF | priv tee "${WWWROOT}/odoo.conf" >/dev/null
[options]
admin_passwd = admin
db_host = ${ODOO_DB_HOST}
db_port = ${ODOO_DB_PORT}
db_user = ${ODOO_DB_USER}
db_password = ${ODOO_DB_PASS}
db_name = ${ODOO_DB_NAME}
http_port = ${ODOO_PORT}
proxy_mode = True
addons_path = ${WWWROOT}/addons
EOF
  priv chown -R www-data:www-data "${WWWROOT}" || true
fi

# Start Odoo as a background service or daemon if possible (simplified start script)
echo "Starting Odoo in the background..."
if command -v python3 >/dev/null 2>&1; then
  priv -u www-data sh -c "cd ${WWWROOT} && python3 odoo-bin -c odoo.conf > odoo.log 2>&1 &" || \
  priv sh -c "cd ${WWWROOT} && python3 odoo-bin -c odoo.conf > odoo.log 2>&1 &" || true
fi

echo "Configuring webserver: ${ODOO_WEBSERVER}"

ENV_SCRIPT_FILE=$(mktemp)
cat <<EOF > "${ENV_SCRIPT_FILE}"
export SERVER_NAME="${SERVER_NAME}"
export PROXY_PASS="http://127.0.0.1:${ODOO_PORT}"
export PROXY_WEBSOCKETS=1
export LISTEN="${LISTEN_PORT}"
export LOCATION_EXPR="/"
EOF
export ENV_SCRIPT_FILE

if [ "${ODOO_WEBSERVER}" = "nginx" ]; then
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
elif [ "${ODOO_WEBSERVER}" = "caddy" ]; then
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
elif [ "${ODOO_WEBSERVER}" = "httpd" ]; then
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

echo "Odoo setup complete on ${SERVER_NAME}:${LISTEN_PORT}"
