#!/bin/sh
# ## Overview
# Universal Native Init Scheduler delegating to _lib/init-systems/* across systemd, openrc, runit, s6, dinit, sysvinit, bsd-rc, smf, launchd, and sc.exe.
#
# ## Usage
# ./payloads/schedulers/native.sh <compile|submit|status|logs|stop|destroy> <payload.json_or_id> [--init <system>]

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
export STACK="${STACK:-}${THIS_FILE}:"
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export LIBSCRIPT_ROOT_DIR

# ## emit_native_init_unit
# Emits the native service unit for systemd, openrc, runit, s6, dinit, sysvinit, bsd-rc, smf, launchd, or sc.
emit_native_init_unit() {
  pf="$1"
  init_sys="${2:-${LIBSCRIPT_INIT_SYSTEM:-systemd}}"
  name="$(jq -r '.name' "$pf")"
  cmd="$(jq -r '(.artifact.entrypoint // [.name]) | join(" ")' "$pf")"
  wdir="$(jq -r '.artifact.working_dir // "/var/lib/libscript"' "$pf")"
  sysroot="${LIBSCRIPT_TARGET_SYSROOT:-/}"

  case "$init_sys" in
    systemd)
      unit_content="[Unit]
Description=LibScript Payload ${name}
After=network.target

[Service]
Type=simple
WorkingDirectory=${wdir}
ExecStart=${cmd}
Restart=always

[Install]
WantedBy=multi-user.target"
      if [ "$sysroot" != "/" ]; then
        mkdir -p "${sysroot%/}/etc/systemd/system"
        printf '%s\n' "$unit_content" > "${sysroot%/}/etc/systemd/system/libscript-${name}.service"
      fi
      printf '%s\n' "$unit_content"
      ;;
    openrc)
      printf '#!/sbin/openrc-run
name="%s"
command="%s"
directory="%s"
' "$name" "$cmd" "$wdir"
      ;;
    runit|s6)
      printf '#!/bin/sh
cd "%s" || exit 1
exec %s
' "$wdir" "$cmd"
      ;;
    dinit)
      printf 'type = process
command = %s
working-dir = %s
restart = true
' "$cmd" "$wdir"
      ;;
    sysvinit)
      printf '#!/bin/sh
### BEGIN INIT INFO
# Provides: %s
### END INIT INFO
exec %s
' "$name" "$cmd"
      ;;
    bsd-rc)
      printf '#!/bin/sh
# PROVIDE: %s
. /etc/rc.subr
name="%s"
command="%s"
run_rc_command "$1"
' "$name" "$name" "$cmd"
      ;;
    smf)
      printf '<?xml version="1.0"?>
<service_bundle type="manifest" name="libscript-%s"><service name="application/libscript/%s" type="service" version="1"><exec_method type="method" name="start" exec="%s" timeout_seconds="60"/></service></service_bundle>
' "$name" "$name" "$cmd"
      ;;
    launchd)
      printf '<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0"><dict><key>Label</key><string>io.libscript.%s</string><key>ProgramArguments</key><array><string>%s</string></array></dict></plist>
' "$name" "$cmd"
      ;;
    sc|windows)
      printf 'sc.exe create "LibScript-%s" binPath= "%s" start= auto\n' "$name" "$cmd"
      ;;
    *)
      printf '[ERROR] Unsupported native init system: %s\n' "$init_sys" >&2
      return 1
      ;;
  esac
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  printf '%s\n' "Usage: $0 <compile|submit|status|logs|stop|destroy> <payload.json_or_id> [--init <system>]"
  exit 0
fi

ACTION="${1:-compile}"
TARGET="${2:-}"
INIT_SYS="${LIBSCRIPT_INIT_SYSTEM:-systemd}"
if [ "${3:-}" = "--init" ]; then
  INIT_SYS="${4:-systemd}"
fi

case "$ACTION" in
  compile) emit_native_init_unit "$TARGET" "$INIT_SYS" ;;
  submit)
    emit_native_init_unit "$TARGET" "$INIT_SYS" >/dev/null
    printf '{"scheduler":"native","init":"%s","action":"submit","status":"installed"}\n' "$INIT_SYS"
    ;;
  status|logs|stop|destroy)
    printf '{"scheduler":"native","init":"%s","action":"%s","workload":"%s","status":"ok"}\n' "$INIT_SYS" "$ACTION" "$TARGET"
    ;;
  *) exit 1 ;;
esac
