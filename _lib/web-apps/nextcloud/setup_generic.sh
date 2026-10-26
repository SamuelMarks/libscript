#!/bin/sh
# ## Overview
# Provides a generic, cross-platform setup mechanism for the Nextcloud collaboration platform stack.
# 
# ## Usage
# Execute this script to perform generic initialization steps for nextcloud.


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

for LIB in "_lib/_common/pkg_mgr.sh" "_lib/_common/os_info.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  # shellcheck source=/dev/null
# shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done

NEXTCLOUD_WEBSERVER="${NEXTCLOUD_WEBSERVER:-nginx}"
export NEXTCLOUD_WEBSERVER

NEXTCLOUD_DB_TYPE="${NEXTCLOUD_DB_TYPE:-sqlite}"
export NEXTCLOUD_DB_TYPE

if [ "${LIBSCRIPT_SKIP_SYSTEM_DEPS:-0}" != "1" ]; then
  libscript_depends 'php' || true
  if [ "${NEXTCLOUD_WEBSERVER}" = "nginx" ] || [ "${NEXTCLOUD_WEBSERVER}" = "caddy" ]; then
    libscript_depends 'php-fpm' || true
  fi
  if [ "${NEXTCLOUD_DB_TYPE}" = "mariadb" ] || [ "${NEXTCLOUD_DB_TYPE}" = "mysql" ]; then
    libscript_depends 'mariadb' || true
  elif [ "${NEXTCLOUD_DB_TYPE}" = "postgres" ] || [ "${NEXTCLOUD_DB_TYPE}" = "postgresql" ]; then
    libscript_depends 'postgres' || true
  elif [ "${NEXTCLOUD_DB_TYPE}" = "sqlite" ]; then
    libscript_depends 'sqlite' || true
  fi
  libscript_depends "${NEXTCLOUD_WEBSERVER}" || true
fi

NEXTCLOUD_VERSION="${NEXTCLOUD_VERSION:-latest}"
export NEXTCLOUD_VERSION

NEXTCLOUD_WWWROOT="${NEXTCLOUD_WWWROOT:-/var/www/nextcloud}"
export NEXTCLOUD_WWWROOT

if [ ! -d "${NEXTCLOUD_WWWROOT}/core" ]; then
  printf '%s\n' "Downloading Nextcloud (${NEXTCLOUD_VERSION}) to ${NEXTCLOUD_WWWROOT}..."
  priv mkdir -p "${NEXTCLOUD_WWWROOT}"
  if [ "${NEXTCLOUD_VERSION}" = "latest" ]; then
    dl_url="https://download.nextcloud.com/server/releases/latest.tar.bz2"
  else
    dl_url="https://download.nextcloud.com/server/releases/nextcloud-${NEXTCLOUD_VERSION}.tar.bz2"
  fi

  tmp_nc=$(mktemp)
  libscript_download "${dl_url:-}" "${tmp_nc}"
  priv tar xjf "${tmp_nc}" --strip-components=1 -C "${NEXTCLOUD_WWWROOT}"
  rm -f "${tmp_nc}"
fi

DB_NAME="${NEXTCLOUD_DB_NAME:-nextcloud}"
DB_USER="${NEXTCLOUD_DB_USER:-nextcloud}"
DB_PASS="${NEXTCLOUD_DB_PASS:-nextcloud}"

printf '%s\n' "Configuring Database (${NEXTCLOUD_DB_TYPE})..."
if [ "${NEXTCLOUD_DB_TYPE}" = "mariadb" ] || [ "${NEXTCLOUD_DB_TYPE}" = "mysql" ]; then
  if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/databases/provision_schema.sh" ]; then
    "${LIBSCRIPT_ROOT_DIR}/_lib/databases/provision_schema.sh" \
      --engine mysql --host "127.0.0.1" --port "3306" \
      --schema "${DB_NAME}" --user "${DB_USER}" --password "${DB_PASS}" >/dev/null 2>&1 || \
      printf '%s\n' "Warning: MariaDB is not running or root login failed."
  fi
elif [ "${NEXTCLOUD_DB_TYPE}" = "postgres" ] || [ "${NEXTCLOUD_DB_TYPE}" = "postgresql" ]; then
  if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/databases/provision_schema.sh" ]; then
    "${LIBSCRIPT_ROOT_DIR}/_lib/databases/provision_schema.sh" \
      --engine postgres --host "127.0.0.1" --port "5432" \
      --schema "${DB_NAME}" --user "${DB_USER}" --password "${DB_PASS}" >/dev/null 2>&1 || \
      printf '%s\n' "Warning: Postgres is not running or postgres login failed."
  fi
fi

# Autoconfig for Nextcloud database
NC_DBTYPE="${NEXTCLOUD_DB_TYPE}"
if [ "${NC_DBTYPE}" = "mariadb" ]; then NC_DBTYPE="mysql"; fi
if [ "${NC_DBTYPE}" = "postgres" ] || [ "${NC_DBTYPE}" = "postgresql" ]; then NC_DBTYPE="pgsql"; fi
if [ "${NC_DBTYPE}" = "sqlite" ]; then NC_DBTYPE="sqlite3"; fi

if [ ! -f "${NEXTCLOUD_WWWROOT}/config/autoconfig.php" ]; then
  priv mkdir -p "${NEXTCLOUD_WWWROOT}/config"
  tmp_ac=$(mktemp)
  cat <<EOF > "${tmp_ac}"
<?php
\$AUTOCONFIG = array(
  "dbtype"        => "${NC_DBTYPE}",
  "dbname"        => "${DB_NAME}",
  "dbuser"        => "${DB_USER}",
  "dbpass"        => "${DB_PASS}",
  "dbhost"        => "localhost",
  "dbtableprefix" => "",
);
EOF
  priv cp "${tmp_ac}" "${NEXTCLOUD_WWWROOT}/config/autoconfig.php"
  rm -f "${tmp_ac}"
fi

priv chown -R www-data:www-data "${NEXTCLOUD_WWWROOT}" 2>/dev/null || priv chown -R nginx:nginx "${NEXTCLOUD_WWWROOT}" 2>/dev/null || true

if [ -z "${NEXTCLOUD_PHP_FPM_LISTEN:-}" ]; then
  if [ -e /run/php/php-fpm.sock ]; then
    export NEXTCLOUD_PHP_FPM_LISTEN="unix:/run/php/php-fpm.sock"
  elif [ -e /var/run/php-fpm/php-fpm.sock ]; then
    export NEXTCLOUD_PHP_FPM_LISTEN="unix:/var/run/php-fpm/php-fpm.sock"
  elif [ -e /var/run/php-fpm.sock ]; then
    export NEXTCLOUD_PHP_FPM_LISTEN="unix:/var/run/php-fpm/php-fpm.sock"
  else
    export NEXTCLOUD_PHP_FPM_LISTEN="127.0.0.1:9000"
    for sock in /run/php/php*.sock; do
      if [ -e "$sock" ]; then
        export NEXTCLOUD_PHP_FPM_LISTEN="unix:$sock"
        break
      fi
    done
  fi
fi

NEXTCLOUD_SERVER_NAME="${NEXTCLOUD_SERVER_NAME:-localhost}"
export NEXTCLOUD_SERVER_NAME

printf '%s\n' "Configuring webserver: ${NEXTCLOUD_WEBSERVER}"

ENV_SCRIPT_FILE=$(mktemp)
cat <<EOF > "${ENV_SCRIPT_FILE}"
export NEXTCLOUD_SERVER_NAME="${NEXTCLOUD_SERVER_NAME}"
export SERVER_NAME="${NEXTCLOUD_SERVER_NAME}"
export WWWROOT="${NEXTCLOUD_WWWROOT}"
export PHP_FPM_LISTEN="${NEXTCLOUD_PHP_FPM_LISTEN}"
export NEXTCLOUD_WWWROOT="${NEXTCLOUD_WWWROOT}"
export NEXTCLOUD_PHP_FPM_LISTEN="${NEXTCLOUD_PHP_FPM_LISTEN}"
export LISTEN="${NEXTCLOUD_LISTEN:-80}"
export NGINX_LISTEN="${NEXTCLOUD_LISTEN:-80}"
export HTTPD_LISTEN="${NEXTCLOUD_LISTEN:-80}"
export CADDY_LISTEN="${NEXTCLOUD_LISTEN:-80}"
export LOCATION_EXPR="/"
export NGINX_LOCATION_EXPR="/"
export NGINX_SERVER_NAME="${NEXTCLOUD_SERVER_NAME}"
export NGINX_WWWROOT="${NEXTCLOUD_WWWROOT}"
export NGINX_PHP_FPM_LISTEN="${NEXTCLOUD_PHP_FPM_LISTEN}"
export HTTPD_SERVER_NAME="${NEXTCLOUD_SERVER_NAME}"
export HTTPD_WWWROOT="${NEXTCLOUD_WWWROOT}"
export HTTPD_PHP_FPM_LISTEN="${NEXTCLOUD_PHP_FPM_LISTEN}"
export CADDY_SERVER_NAME="${NEXTCLOUD_SERVER_NAME}"
export CADDY_WWWROOT="${NEXTCLOUD_WWWROOT}"
export CADDY_PHP_FPM_LISTEN="${NEXTCLOUD_PHP_FPM_LISTEN}"
EOF
export ENV_SCRIPT_FILE

if [ "${NEXTCLOUD_WEBSERVER}" = "nginx" ]; then
  LOC_BLOCK_TMP=$(mktemp)
  env SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/web-servers/nginx/create_location_block.sh" "${LIBSCRIPT_ROOT_DIR}/_lib/web-servers/nginx/create_location_block.sh" > "${LOC_BLOCK_TMP}"
  LOCATIONS="$(cat "${LOC_BLOCK_TMP}")"
  export LOCATIONS
  SERVER_BLOCK_TMP=$(mktemp)
  env SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/web-servers/nginx/create_server_block.sh" "${LIBSCRIPT_ROOT_DIR}/_lib/web-servers/nginx/create_server_block.sh" > "${SERVER_BLOCK_TMP}"
  NGINX_CONF_DIR="${LIBSCRIPT_ROOT_DIR}/installed/nginx/conf"
  if [ -d /etc/nginx/http.d ]; then
    priv cp "${SERVER_BLOCK_TMP}" "/etc/nginx/http.d/${NEXTCLOUD_SERVER_NAME}.conf"
  elif [ -d /etc/nginx/conf.d ]; then
    priv cp "${SERVER_BLOCK_TMP}" "/etc/nginx/conf.d/${NEXTCLOUD_SERVER_NAME}.conf"
  elif [ -d /etc/nginx/sites-available ]; then
    priv cp "${SERVER_BLOCK_TMP}" "/etc/nginx/sites-available/${NEXTCLOUD_SERVER_NAME}.conf"
    priv ln -sf "/etc/nginx/sites-available/${NEXTCLOUD_SERVER_NAME}.conf" "/etc/nginx/sites-enabled/${NEXTCLOUD_SERVER_NAME}.conf"
  else
    priv mkdir -p "${NGINX_CONF_DIR}/sites-available" "${NGINX_CONF_DIR}/sites-enabled"
    priv cp "${SERVER_BLOCK_TMP}" "${NGINX_CONF_DIR}/sites-available/${NEXTCLOUD_SERVER_NAME}.conf"
    priv ln -sf "${NGINX_CONF_DIR}/sites-available/${NEXTCLOUD_SERVER_NAME}.conf" "${NGINX_CONF_DIR}/sites-enabled/${NEXTCLOUD_SERVER_NAME}.conf"
  fi
  if ! priv systemctl reload nginx ; then
    true
  fi
  rm -f "${LOC_BLOCK_TMP}" "${SERVER_BLOCK_TMP}"
elif [ "${NEXTCLOUD_WEBSERVER}" = "caddy" ]; then
  CADDY_BLOCK_TMP=$(mktemp)
  env SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/web-servers/caddy/create_server_block.sh" "${LIBSCRIPT_ROOT_DIR}/_lib/web-servers/caddy/create_server_block.sh" > "${CADDY_BLOCK_TMP}"
  if [ -d /etc/caddy/conf.d ] || [ -d /etc/caddy/caddy.d ]; then
    conf_dir="/etc/caddy/conf.d"
    [ -d /etc/caddy/caddy.d ] && conf_dir="/etc/caddy/caddy.d"
    priv cp "${CADDY_BLOCK_TMP}" "${conf_dir}/${NEXTCLOUD_SERVER_NAME}.caddy"
  else
    grep -q "${NEXTCLOUD_SERVER_NAME}" /etc/caddy/Caddyfile 2>/dev/null || priv tee -a /etc/caddy/Caddyfile < "${CADDY_BLOCK_TMP}" >/dev/null
  fi
  if ! priv systemctl reload caddy ; then
    true
  fi
  rm -f "${CADDY_BLOCK_TMP}"
elif [ "${NEXTCLOUD_WEBSERVER}" = "httpd" ]; then
  HTTPD_BLOCK_TMP=$(mktemp)
  env SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/web-servers/httpd/create_server_block.sh" "${LIBSCRIPT_ROOT_DIR}/_lib/web-servers/httpd/create_server_block.sh" > "${HTTPD_BLOCK_TMP}"
  if [ -d /etc/httpd/conf.d ]; then
    priv cp "${HTTPD_BLOCK_TMP}" "/etc/httpd/conf.d/${NEXTCLOUD_SERVER_NAME}.conf"
    if ! priv systemctl reload httpd ; then
      true
    fi
  elif [ -d /etc/apache2/sites-available ]; then
    priv cp "${HTTPD_BLOCK_TMP}" "/etc/apache2/sites-available/${NEXTCLOUD_SERVER_NAME}.conf"
    priv ln -sf "/etc/apache2/sites-available/${NEXTCLOUD_SERVER_NAME}.conf" "/etc/apache2/sites-enabled/${NEXTCLOUD_SERVER_NAME}.conf"
    if ! priv systemctl reload apache2 ; then
      true
    fi
  else
    grep -q "${NEXTCLOUD_SERVER_NAME}" /etc/httpd/conf/httpd.conf 2>/dev/null || priv tee -a /etc/httpd/conf/httpd.conf < "${HTTPD_BLOCK_TMP}" >/dev/null
  fi
  rm -f "${HTTPD_BLOCK_TMP}"
fi

rm -f "${ENV_SCRIPT_FILE}"

printf '%s\n' "Nextcloud setup complete on ${NEXTCLOUD_SERVER_NAME}"
