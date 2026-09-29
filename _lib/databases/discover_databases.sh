#!/bin/sh
# ## Overview
# Universal multi-platform database discovery engine.
# Inspects running system services (Windows, systemd, rc.d, SMF), active TCP listeners,
# UNIX domain sockets, and configuration files across MySQL, MariaDB, PostgreSQL,
# MongoDB, Redis, and SQLite.
#
# ## Usage
#   ./_lib/databases/discover_databases.sh [OPTIONS]
#
# ## Options
#   --json               Output full JSON inventory conforming to database_inventory.schema.json
#   --eval               Export shell variables for first discovered active database
#   --check              Exit 0 if any database is found, 1 otherwise
#   --engine <type>      Filter check or discovery by engine (mysql, mariadb, postgres, mongodb, redis, sqlite)
#
# ## Exit Codes
#   0 - Target database(s) detected / inspection succeeded
#   1 - No compatible database detected

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"
' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"
' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"
export DIR="${SCRIPT_DIR}"

MODE="--check"
FILTER_ENGINE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --json)
      MODE="--json"
      shift
      ;;
    --eval)
      MODE="--eval"
      shift
      ;;
    --check)
      MODE="--check"
      shift
      ;;
    --engine)
      if [ $# -lt 2 ]; then
        printf '[ERROR] --engine requires an argument
' >&2
        exit 1
      fi
      FILTER_ENGINE="$2"
      shift 2
      ;;
    *)
      printf '[ERROR] Unknown argument: %s
' "$1" >&2
      exit 1
      ;;
  esac
done

# ## check_tcp_port
# Non-destructive test to check if a TCP port is accepting connections on a given host.
check_tcp_port() {
  _host="$1"
  _port="$2"
  if command -v nc >/dev/null 2>&1; then
    nc -z -w 1 "$_host" "$_port" >/dev/null 2>&1 && return 0
  fi
  # Fallback to python if available
  if command -v python3 >/dev/null 2>&1; then
    python3 -c "import socket; s = socket.socket(); s.settimeout(0.5); exit(0 if s.connect_ex(('$_host', int('$_port'))) == 0 else 1)" >/dev/null 2>&1 && return 0
  elif command -v python >/dev/null 2>&1; then
    python -c "import socket; s = socket.socket(); s.settimeout(0.5); exit(0 if s.connect_ex(('$_host', int('$_port'))) == 0 else 1)" >/dev/null 2>&1 && return 0
  fi
  return 1
}

# Temporary accumulator file for discovered instances in TSV format:
# engine | version | host | port | socket | service_name | is_active | source | existing_schemas
INVENTORY_TMP="$(mktemp "${TMPDIR:-/tmp}/db_inv.XXXXXX")"
trap 'rm -f "$INVENTORY_TMP"' EXIT INT TERM

# ## record_db
# Records a detected database service instance into temporary inventory.
record_db() {
  _eng="$1"
  _ver="${2:-unknown}"
  _h="${3:-127.0.0.1}"
  _p="${4:-0}"
  _s="${5:-}"
  _svc="${6:-}"
  _act="${7:-true}"
  _src="${8:-tcp_probe}"
  _sch="${9:-}"

  if [ -n "$FILTER_ENGINE" ] && [ "$FILTER_ENGINE" != "$_eng" ]; then
    return 0
  fi

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$_eng" "$_ver" "$_h" "$_p" "$_s" "$_svc" "$_act" "$_src" "$_sch" >> "$INVENTORY_TMP"
}

# 1. Probing Windows Services (when running on Windows, MSYS, Cygwin)
if command -v sc.exe >/dev/null 2>&1 || command -v sc >/dev/null 2>&1; then
  SC_BIN="sc"
  command -v sc.exe >/dev/null 2>&1 && SC_BIN="sc.exe"
  # MySQL / MariaDB
  for svc in MySQL MariaDB MySQL57 MySQL80 OpenEdXMySQL; do
    if "$SC_BIN" query "$svc" 2>/dev/null | grep -q "RUNNING"; then
      record_db "mysql" "auto" "127.0.0.1" 3306 "" "$svc" "true" "windows_service" ""
      break
    fi
  done
  # PostgreSQL
  for svc in postgresql postgresql-x64-14 postgresql-x64-15 postgresql-x64-16; do
    if "$SC_BIN" query "$svc" 2>/dev/null | grep -q "RUNNING"; then
      record_db "postgres" "auto" "127.0.0.1" 5432 "" "$svc" "true" "windows_service" ""
      break
    fi
  done
  # MongoDB
  if "$SC_BIN" query MongoDB 2>/dev/null | grep -q "RUNNING"; then
    record_db "mongodb" "auto" "127.0.0.1" 27017 "" "MongoDB" "true" "windows_service" ""
  fi
  # Redis
  if "$SC_BIN" query Redis 2>/dev/null | grep -q "RUNNING"; then
    record_db "redis" "auto" "127.0.0.1" 6379 "" "Redis" "true" "windows_service" ""
  fi
fi

# 2. Probing systemd (Linux)
if command -v systemctl >/dev/null 2>&1; then
  if systemctl is-active --quiet mysql.service 2>/dev/null || systemctl is-active --quiet mariadb.service 2>/dev/null; then
    record_db "mysql" "auto" "127.0.0.1" 3306 "" "mysql.service" "true" "systemd" ""
  fi
  if systemctl is-active --quiet postgresql.service 2>/dev/null; then
    record_db "postgres" "auto" "127.0.0.1" 5432 "" "postgresql.service" "true" "systemd" ""
  fi
  if systemctl is-active --quiet mongod.service 2>/dev/null || systemctl is-active --quiet mongodb.service 2>/dev/null; then
    record_db "mongodb" "auto" "127.0.0.1" 27017 "" "mongod.service" "true" "systemd" ""
  fi
  if systemctl is-active --quiet redis.service 2>/dev/null || systemctl is-active --quiet redis-server.service 2>/dev/null; then
    record_db "redis" "auto" "127.0.0.1" 6379 "" "redis.service" "true" "systemd" ""
  fi
fi

# 3. Probing FreeBSD / BSD rc.d
if command -v service >/dev/null 2>&1; then
  if service mysql-server onestatus >/dev/null 2>&1; then
    record_db "mysql" "auto" "127.0.0.1" 3306 "" "mysql-server" "true" "rc_d" ""
  fi
  if service postgresql onestatus >/dev/null 2>&1; then
    record_db "postgres" "auto" "127.0.0.1" 5432 "" "postgresql" "true" "rc_d" ""
  fi
  if service redis onestatus >/dev/null 2>&1; then
    record_db "redis" "auto" "127.0.0.1" 6379 "" "redis" "true" "rc_d" ""
  fi
fi

# 4. Probing illumos / Solaris SMF
if command -v svcs >/dev/null 2>&1; then
  if svcs -H -o state "pkg:/database/mariadb*" 2>/dev/null | grep -q "online" || svcs -H -o state "svc:/database/mysql*" 2>/dev/null | grep -q "online"; then
    record_db "mysql" "auto" "127.0.0.1" 3306 "" "svc:/database/mysql" "true" "smf" ""
  fi
  if svcs -H -o state "svc:/database/postgres*" 2>/dev/null | grep -q "online"; then
    record_db "postgres" "auto" "127.0.0.1" 5432 "" "svc:/database/postgres" "true" "smf" ""
  fi
fi

# 5. Probing Local UNIX Sockets
for sock in /tmp/mysql.sock /run/mysqld/mysqld.sock /var/run/mysqld/mysqld.sock /var/lib/mysql/mysql.sock; do
  if [ -S "$sock" ]; then
    record_db "mysql" "auto" "localhost" 3306 "$sock" "" "true" "socket" ""
    break
  fi
done
for sock in /tmp/.s.PGSQL.5432 /var/run/postgresql/.s.PGSQL.5432 /run/postgresql/.s.PGSQL.5432; do
  if [ -S "$sock" ]; then
    record_db "postgres" "auto" "localhost" 5432 "$sock" "" "true" "socket" ""
    break
  fi
done

# 6. Probing Active TCP Ports (if not already recorded or as verification)
if check_tcp_port "127.0.0.1" 3306; then
  record_db "mysql" "auto" "127.0.0.1" 3306 "" "" "true" "tcp_probe" ""
fi
if check_tcp_port "127.0.0.1" 5432; then
  record_db "postgres" "auto" "127.0.0.1" 5432 "" "" "true" "tcp_probe" ""
fi
if check_tcp_port "127.0.0.1" 27017; then
  record_db "mongodb" "auto" "127.0.0.1" 27017 "" "" "true" "tcp_probe" ""
fi
if check_tcp_port "127.0.0.1" 6379; then
  record_db "redis" "auto" "127.0.0.1" 6379 "" "" "true" "tcp_probe" ""
fi

# 7. Deduplicate temporary inventory entries by engine + port
DEDUP_TMP="$(mktemp "${TMPDIR:-/tmp}/db_dedup.XXXXXX")"
trap 'rm -f "$INVENTORY_TMP" "$DEDUP_TMP"' EXIT INT TERM

awk -F'	' '!seen[$1, $4]++' "$INVENTORY_TMP" > "$DEDUP_TMP"

COUNT=$(wc -l < "$DEDUP_TMP" | tr -d ' ')

# Inspect schemas if clients are available
if command -v mysql >/dev/null 2>&1; then
  _dbs=$(mysql -h 127.0.0.1 -P 3306 -u root -e "SHOW DATABASES;" 2>/dev/null | grep -v Database | tr '
' ',' | sed 's/,$//' || true)
  if [ -n "$_dbs" ]; then
    # update mysql schema list in DEDUP_TMP
    awk -F'	' -v dbs="$_dbs" 'BEGIN{OFS="	"} $1=="mysql"{$9=dbs} {print}' "$DEDUP_TMP" > "${DEDUP_TMP}.2" && mv "${DEDUP_TMP}.2" "$DEDUP_TMP"
  fi
fi

case "$MODE" in
  --check)
    if [ "$COUNT" -gt 0 ]; then
      printf '[INFO] Discovered %s active database instance(s).
' "$COUNT"
      exit 0
    else
      printf '[INFO] No matching database instances discovered.
'
      exit 1
    fi
    ;;
  --eval)
    if [ "$COUNT" -gt 0 ]; then
      first_line=$(head -n 1 "$DEDUP_TMP")
      _eng=$(printf '%s' "$first_line" | cut -f1)
      _ver=$(printf '%s' "$first_line" | cut -f2)
      _host=$(printf '%s' "$first_line" | cut -f3)
      _port=$(printf '%s' "$first_line" | cut -f4)
      _sock=$(printf '%s' "$first_line" | cut -f5)
      _svc=$(printf '%s' "$first_line" | cut -f6)
      _act=$(printf '%s' "$first_line" | cut -f7)
      _src=$(printf '%s' "$first_line" | cut -f8)
      _sch=$(printf '%s' "$first_line" | cut -f9)

      printf 'DETECTED_DB_COUNT=%s
' "$COUNT"
      printf 'DETECTED_DB_ENGINE="%s"
' "$_eng"
      printf 'DETECTED_DB_VERSION="%s"
' "$_ver"
      printf 'DETECTED_DB_HOST="%s"
' "$_host"
      printf 'DETECTED_DB_PORT=%s
' "$_port"
      printf 'DETECTED_DB_SOCKET="%s"
' "$_sock"
      printf 'DETECTED_DB_SERVICE="%s"
' "$_svc"
      printf 'DETECTED_DB_IS_ACTIVE=%s
' "$_act"
      printf 'DETECTED_DB_SOURCE="%s"
' "$_src"
      printf 'DETECTED_DB_SCHEMAS="%s"
' "$_sch"
      exit 0
    else
      printf 'DETECTED_DB_COUNT=0
'
      exit 1
    fi
    ;;
  --json)
    printf '[\n'
    first=1
    while IFS= read -r line || [ -n "$line" ]; do
      [ -z "$line" ] && continue
      _eng=$(printf '%s' "$line" | cut -f1)
      _ver=$(printf '%s' "$line" | cut -f2)
      _host=$(printf '%s' "$line" | cut -f3)
      _port=$(printf '%s' "$line" | cut -f4)
      _sock=$(printf '%s' "$line" | cut -f5)
      _svc=$(printf '%s' "$line" | cut -f6)
      _act=$(printf '%s' "$line" | cut -f7)
      _src=$(printf '%s' "$line" | cut -f8)
      _sch=$(printf '%s' "$line" | cut -f9)

      [ "$first" -eq 0 ] && printf ',\n'
      first=0
      
      # Convert schema comma list to json array
      _sch_json="[]"
      if [ -n "$_sch" ]; then
        _sch_json="[$(printf '%s' "$_sch" | awk -F',' '{for(i=1;i<=NF;i++) printf (i>1?",":"") "\"" $i "\"";}')]"
      fi

      printf '  {\n'
      printf '    "engine": "%s",\n' "$_eng"
      printf '    "version": "%s",\n' "$_ver"
      printf '    "host": "%s",\n' "$_host"
      printf '    "port": %s,\n' "$_port"
      [ -n "$_sock" ] && printf '    "socket": "%s",\n' "$_sock"
      [ -n "$_svc" ] && printf '    "service_name": "%s",\n' "$_svc"
      printf '    "is_active": %s,\n' "$_act"
      printf '    "source": "%s",\n' "$_src"
      printf '    "existing_schemas": %s\n' "$_sch_json"
      printf '  }'
    done < "$DEDUP_TMP"
    printf '\n]\n'
    ;;
esac
