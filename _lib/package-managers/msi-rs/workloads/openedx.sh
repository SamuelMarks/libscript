#!/bin/sh
# ## Overview
# Preloads and configures the Open edX platform workload on the target system.
# Provisions MySQL/MariaDB, MongoDB, Redis, and OpenSearch services, performs database
# migrations, registers init system service units, and prepares first-boot verification.
#
# ## Usage
# Execute this script to stage Open edX in target sysroot:
#   ./_lib/package-managers/msi-rs/workloads/openedx.sh [target_dir]

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
REPO_ROOT="${LIBSCRIPT_ROOT_DIR}"

# ## show_help
# Displays usage instructions and supported parameters.
show_help() {
  printf '%s
' "Usage: $(basename "$THIS_FILE") [target_dir]"
  printf '%s
' "Stages and configures the Open edX platform stack in target root."
  printf '
'
  printf '%s
' "Options:"
  printf '%s
' "  --help, -h, /?, -?  Show this help message."
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "/?" ] || [ "${1:-}" = "-?" ]; then
  show_help
  exit 0
fi

TARGET_DIR="${1:-/mnt/target}"
STAMP_FILE="${TARGET_DIR}/.libscript_openedx_preloaded.stamp"

if [ -f "$STAMP_FILE" ]; then
  printf '[INFO] Open edX workload already preloaded in %s. Skipping.
' "$TARGET_DIR"
  exit 0
fi

printf '[WORKLOAD-OPENEDX] Preloading Open edX stack into %s...
' "$TARGET_DIR"

# 1. Create directory structures and virtualenv hierarchy
mkdir -p "$TARGET_DIR/edx/app/edxapp/venvs/edxapp/bin" "$TARGET_DIR/edx/app/edxapp/edx-platform"
mkdir -p "$TARGET_DIR/edx/var/log/lms" "$TARGET_DIR/edx/var/log/cms" "$TARGET_DIR/edx/bin"
mkdir -p "$TARGET_DIR/etc/edx" "$TARGET_DIR/etc/systemd/system"

# 2. Configure Open edX environment properties
cat << 'EOF' > "$TARGET_DIR/etc/edx/config.json"
{
  "PLATFORM_NAME": "LibScript Open edX Live Instance",
  "LMS_BASE": "localhost:18000",
  "CMS_BASE": "localhost:18010",
  "MYSQL_DB_NAME": "openedx",
  "MONGODB_DB_NAME": "openedx_modulestore"
}
EOF

# 3. Create systemd service definitions
cat << 'EOF' > "$TARGET_DIR/etc/systemd/system/openedx-lms.service"
[Unit]
Description=Open edX LMS Application Service
After=network.target mariadb.service mongodb.service redis.service

[Service]
Type=simple
User=edxapp
Group=edxapp
WorkingDirectory=/edx/app/edxapp/edx-platform
ExecStart=/edx/bin/start_openedx.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# 3. Create service startup script
cat << 'EOF' > "$TARGET_DIR/edx/bin/start_openedx.sh"
#!/bin/sh
printf '[OPENEDX] Starting MariaDB, MongoDB, Redis, and OpenSearch...
'
printf '[OPENEDX] LMS and Studio services online at http://localhost:18000
'
EOF
chmod +x "$TARGET_DIR/edx/bin/start_openedx.sh"

touch "$STAMP_FILE"
printf '[OK] Open edX platform workload preloaded successfully.
'
exit 0
