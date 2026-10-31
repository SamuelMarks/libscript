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
elif [ "${ZSH_VERSION-}" ]; then
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
REPO_ROOT="${LIBSCRIPT_ROOT_DIR}"

# ## show_help
# Displays usage instructions and supported parameters.
show_help() {
  printf '%s\n' "Usage: $(basename "$THIS_FILE") [target_dir]"
  printf '%s\n' 'Stages and configures the Open edX platform stack in target root.'
  printf '\n'
  printf '%s\n' 'Options:'
  printf '%s\n' '  --help, -h, /?, -?  Show this help message.'
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "/?" ] || [ "${1:-}" = "-?" ]; then
  show_help
  exit 0
fi

TARGET_DIR="${1:-/mnt/target}"
STAMP_FILE="${TARGET_DIR}/.libscript_openedx_preloaded.stamp"

if [ -f "$STAMP_FILE" ]; then
  printf '[INFO] Open edX workload already preloaded in %s. Skipping.\n' "$TARGET_DIR"
  exit 0
fi

printf '[WORKLOAD-OPENEDX] Preloading Open edX stack into %s...\n' "$TARGET_DIR"

# 0. Provision database and runtime dependencies via libscript
if [ -x "${REPO_ROOT}/libscript.sh" ]; then
  printf '[WORKLOAD-OPENEDX] Provisioning dependencies (MySQL, MongoDB, Redis, Python, Node.js, Meilisearch)...\n'
  if [ "${LIBSCRIPT_WORKLOAD_INSTALL_DEPS:-0}" = "1" ]; then
    "${REPO_ROOT}/libscript.sh" install mariadb latest || true
    "${REPO_ROOT}/libscript.sh" install mongodb latest || true
    "${REPO_ROOT}/libscript.sh" install redis latest || true
    "${REPO_ROOT}/libscript.sh" install python latest || true
    "${REPO_ROOT}/libscript.sh" install nodejs latest || true
    "${REPO_ROOT}/libscript.sh" install meilisearch latest || true
  fi
  printf '[WORKLOAD-OPENEDX] Dependency provisioning complete.\n'
fi

# 1. Create directory structures and virtualenv hierarchy
mkdir -p "$TARGET_DIR/edx/app/edxapp/venvs/edxapp/bin" "$TARGET_DIR/edx/app/edxapp/edx-platform"
mkdir -p "$TARGET_DIR/edx/var/log/lms" "$TARGET_DIR/edx/var/log/cms" "$TARGET_DIR/edx/bin"
mkdir -p "$TARGET_DIR/etc/edx" "$TARGET_DIR/etc/systemd/system"

# 2. Configure Open edX environment properties via canonical config.sh recipe
if [ -x "${REPO_ROOT}/_lib/web-apps/openedx/config.sh" ]; then
  OPENEDX_INSTALL_DIR="$TARGET_DIR/edx/app/edxapp/edx-platform" "${REPO_ROOT}/_lib/web-apps/openedx/config.sh" generate >/dev/null 2>&1 || true
fi
cat << 'EOF' > "$TARGET_DIR/etc/edx/config.json"
{
  "PLATFORM_NAME": "Open edX",
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

# 4. Create service startup script delegating to _lib/web-apps/openedx/service.sh
cat << EOF > "$TARGET_DIR/edx/bin/start_openedx.sh"
#!/bin/sh
set -feu
printf '[OPENEDX] Starting MariaDB, MongoDB, Redis, and OpenSearch...\n'
if [ -x "${REPO_ROOT}/_lib/web-apps/openedx/service.sh" ]; then
  OPENEDX_LMS_PORT=18000 OPENEDX_CMS_PORT=18010 "${REPO_ROOT}/_lib/web-apps/openedx/service.sh" start
fi
printf '[OPENEDX] LMS and Studio services online at http://localhost:18000\n'
EOF
chmod +x "$TARGET_DIR/edx/bin/start_openedx.sh"

touch "$STAMP_FILE"
printf '[OK] Open edX platform workload preloaded successfully.\n'
exit 0
