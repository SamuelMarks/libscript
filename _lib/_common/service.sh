#!/bin/sh
# ## Overview
# This module provides a cross-platform abstraction for managing services
# (daemons) across different init systems (systemd, openrc, sysvinit, bsd_rc,
# launchd, smf, runit, s6, fallback PID daemon, and Windows sc.exe).
#
# ## Usage
# . "$LIBSCRIPT_ROOT_DIR/_lib/_common/service.sh"
# libscript_service [ACTION] [SERVICE_NAME] [OPTIONS]
#
# Actions: start, stop, restart, reload, status, health, logs, enable, disable, uninstall

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

for LIB in "_lib/_common/os_info.sh" "_lib/_common/priv.sh" "_lib/_common/log.sh" "_lib/_common/service_install.sh"; do
  if [ -f "${LIBSCRIPT_ROOT_DIR}/${LIB}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${LIB}"
    export SCRIPT_NAME
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
done
unset SCRIPT_NAME || true

# ## libscript_service_fallback
# Manages a background PID-file daemon when no system init supervisor is active.
libscript_service_fallback() {
  _fb_action="$1"
  _fb_service="$2"
  shift 2 || true

  _fb_data_base="${LIBSCRIPT_DATA_DIR:-/tmp/data}"
  _fb_svc_dir="${_fb_data_base}/${_fb_service}"
  _fb_pid_file="${_fb_svc_dir}/service.pid"
  if [ ! -f "$_fb_pid_file" ]; then
    if [ -f "/var/run/${_fb_service}.pid" ]; then
      _fb_pid_file="/var/run/${_fb_service}.pid"
    elif [ -f "/tmp/${_fb_service}.pid" ]; then
      _fb_pid_file="/tmp/${_fb_service}.pid"
    fi
  fi
  _fb_log_file="${_fb_svc_dir}/service.log"
  [ -f "$_fb_log_file" ] || _fb_log_file="/var/log/${_fb_service}.log"

  case "$_fb_action" in
    start)
      if [ -f "$_fb_pid_file" ]; then
        _fb_pid=$(cat "$_fb_pid_file" 2>/dev/null || true)
        if [ -n "$_fb_pid" ] && kill -0 "$_fb_pid" 2>/dev/null; then
          log_info "$_fb_service is already running (PID: $_fb_pid)"
          return 0
        fi
      fi
      if [ -x "${_fb_svc_dir}/run_${_fb_service}.sh" ]; then
        mkdir -p "$_fb_svc_dir"
        nohup sh "${_fb_svc_dir}/run_${_fb_service}.sh" >> "${_fb_svc_dir}/service.log" 2>&1 &
        _fb_new_pid=$!
        printf '%s\n' "$_fb_new_pid" > "${_fb_svc_dir}/service.pid"
        log_info "Started fallback daemon $_fb_service (PID: $_fb_new_pid)"
        return 0
      fi
      log_warn "No fallback runner script found for $_fb_service at ${_fb_svc_dir}/run_${_fb_service}.sh"
      return 0
      ;;
    stop)
      if [ -f "$_fb_pid_file" ]; then
        _fb_pid=$(cat "$_fb_pid_file" 2>/dev/null || true)
        if [ -n "$_fb_pid" ] && kill -0 "$_fb_pid" 2>/dev/null; then
          kill "$_fb_pid" 2>/dev/null || priv kill "$_fb_pid" 2>/dev/null || true
        fi
        rm -f "$_fb_pid_file" 2>/dev/null || priv rm -f "$_fb_pid_file" 2>/dev/null || true
      fi
      return 0
      ;;
    restart|reload)
      libscript_service_fallback stop "$_fb_service" || true
      sleep 1
      libscript_service_fallback start "$_fb_service"
      return $?
      ;;
    enable|disable)
      return 0
      ;;
    uninstall)
      libscript_service_fallback stop "$_fb_service" || true
      rm -f "${_fb_svc_dir}/run_${_fb_service}.sh" "${_fb_svc_dir}/systemd_run_${_fb_service}.sh" 2>/dev/null || true
      return 0
      ;;
    logs)
      if [ -f "${_fb_svc_dir}/service.log" ]; then
        tail "${@:--n 50}" "${_fb_svc_dir}/service.log"
      elif [ -f "${_fb_svc_dir}/stdout.log" ]; then
        tail "${@:--n 50}" "${_fb_svc_dir}/stdout.log"
      elif [ -f "$_fb_log_file" ]; then
        tail "${@:--n 50}" "$_fb_log_file"
      else
        log_warn "No fallback log file found for $_fb_service"
      fi
      return 0
      ;;
    status|health)
      if [ "$_fb_action" = "health" ]; then
        libscript_check_health "$_fb_service" "$@" && return 0 || return 1
      fi
      if [ -f "$_fb_pid_file" ]; then
        _fb_pid=$(cat "$_fb_pid_file" 2>/dev/null || true)
        if [ -n "$_fb_pid" ] && kill -0 "$_fb_pid" 2>/dev/null; then
          log_info "$_fb_service is running (PID: $_fb_pid)"
          return 0
        fi
      fi
      log_error "$_fb_service is NOT running"
      return 1
      ;;
    *)
      log_error "Unknown fallback service action: $_fb_action"
      return 1
      ;;
  esac
}

# ## libscript_service
# Performs the libscript_service operation across supported init systems and updates component state.
libscript_service() {
  _action="${1:-}"
  _service="${2:-}"
  shift 2 || true

  if [ -z "$_action" ] || [ -z "$_service" ]; then
    log_error "Usage: libscript_service [ACTION] [SERVICE_NAME] [OPTIONS]"
    return 1
  fi

  case "$_action" in
    up) _action="start" ;;
    down) _action="stop" ;;
    query) _action="status" ;;
    remove|uninstall-service) _action="uninstall" ;;
  esac

  if [ "${LIBSCRIPT_FORCE_FALLBACK_DAEMON:-0}" = "1" ]; then
    libscript_service_fallback "$_action" "$_service" "$@"
    return $?
  fi

  # 1. Windows (sc.exe)
  if command -v sc.exe >/dev/null 2>&1; then
    case "$_action" in
      start)     sc.exe start "$_service" ;;
      stop)      sc.exe stop "$_service" ;;
      restart)   sc.exe stop "$_service" || true; sleep 2; sc.exe start "$_service" ;;
      reload)    sc.exe stop "$_service" || true; sleep 1; sc.exe start "$_service" ;;
      status)    sc.exe query "$_service" ;;
      enable)    sc.exe config "$_service" start= auto ;;
      disable)   sc.exe config "$_service" start= disabled ;;
      uninstall) libscript_uninstall_service "$_service" ;;
      logs)
        if [ -f "${LIBSCRIPT_DATA_DIR:-/tmp/data}/${_service}/service.log" ]; then
          tail "${@:--n 50}" "${LIBSCRIPT_DATA_DIR:-/tmp/data}/${_service}/service.log"
        else
          log_warn "Logs not natively supported via sc.exe for $_service"
        fi
        ;;
      health)    libscript_check_health "$_service" "$@" ;;
      *) log_error "Unknown action: $_action"; return 1 ;;
    esac
    return 0
  fi

  # 2. Systemd (when active or unit present)
  if command -v systemctl >/dev/null 2>&1 && { [ -d /run/systemd/system ] || [ "${LIBSCRIPT_MOCK_SYSTEMD:-0}" = "1" ]; }; then
    case "$_service" in
      libscript_*)
        _bare_svc="${_service#libscript_}"
        if ! systemctl is-active --quiet "$_service" 2>/dev/null && [ ! -f "/etc/systemd/system/${_service}.service" ] && [ ! -f "/lib/systemd/system/${_service}.service" ]; then
          if systemctl is-active --quiet "$_bare_svc" 2>/dev/null || [ -f "/etc/systemd/system/${_bare_svc}.service" ] || [ -f "/lib/systemd/system/${_bare_svc}.service" ]; then
            _service="$_bare_svc"
          fi
        fi
        ;;
    esac
    _systemctl_cmd="priv systemctl"
    if systemctl --user --quiet is-enabled "$_service" 2>/dev/null || systemctl --user --quiet is-active "$_service" 2>/dev/null; then
      _systemctl_cmd="systemctl --user"
    fi

    case "$_action" in
      start)     $_systemctl_cmd start "$_service" ;;
      stop)      $_systemctl_cmd stop "$_service" ;;
      restart)   $_systemctl_cmd restart "$_service" ;;
      reload)    $_systemctl_cmd reload "$_service" 2>/dev/null || $_systemctl_cmd restart "$_service" ;;
      status)    $_systemctl_cmd status "$_service" --no-pager ;;
      enable)    $_systemctl_cmd enable "$_service" ;;
      disable)   $_systemctl_cmd disable "$_service" ;;
      uninstall) libscript_uninstall_service "$_service" ;;
      logs)      priv journalctl -u "$_service" --no-pager "${@:--n 50}" 2>/dev/null || journalctl -u "$_service" --no-pager "${@:--n 50}" ;;
      health)    libscript_check_health "$_service" "$@" ;;
      *) log_error "Unknown action: $_action"; return 1 ;;
    esac
    return 0
  fi

  # 3. OpenRC
  if command -v rc-service >/dev/null 2>&1; then
    case "$_action" in
      start|stop|restart|status) priv rc-service "$_service" "$_action" ;;
      reload)    priv rc-service "$_service" reload 2>/dev/null || priv rc-service "$_service" restart ;;
      enable)    priv rc-update add "$_service" default ;;
      disable)   priv rc-update del "$_service" default ;;
      uninstall) libscript_uninstall_service "$_service" ;;
      logs)
        if [ -f "/var/log/$_service.log" ]; then
          tail "${@:--n 50}" "/var/log/$_service.log"
        elif [ -f "${LIBSCRIPT_DATA_DIR:-/tmp/data}/${_service}/service.log" ]; then
          tail "${@:--n 50}" "${LIBSCRIPT_DATA_DIR:-/tmp/data}/${_service}/service.log"
        else
          log_warn "Log file /var/log/$_service.log not found."
        fi
        ;;
      health)    libscript_check_health "$_service" "$@" ;;
      *) log_error "Unknown action: $_action"; return 1 ;;
    esac
    return 0
  fi

  # 4. FreeBSD / BSD rc.d
  if [ "${UNAME_LOWER:-}" = "freebsd" ] || [ "${UNAME_LOWER:-}" = "openbsd" ] || [ "${UNAME_LOWER:-}" = "netbsd" ] || command -v sysrc >/dev/null 2>&1; then
    _rc_svc=$(printf '%s\n' "$_service" | tr '-' '_')
    case "$_action" in
      start|stop|restart|status) priv service "$_rc_svc" "$_action" 2>/dev/null || priv service "$_service" "$_action" ;;
      reload)    priv service "$_rc_svc" reload 2>/dev/null || priv service "$_rc_svc" restart ;;
      enable)    command -v sysrc >/dev/null 2>&1 && priv sysrc "${_rc_svc}_enable=YES" || true ;;
      disable)   command -v sysrc >/dev/null 2>&1 && priv sysrc "${_rc_svc}_enable=NO" || true ;;
      uninstall) libscript_uninstall_service "$_service" ;;
      logs)
        if [ -f "/var/log/$_rc_svc.log" ]; then
          tail "${@:--n 50}" "/var/log/$_rc_svc.log"
        elif [ -f "/var/log/$_service.log" ]; then
          tail "${@:--n 50}" "/var/log/$_service.log"
        elif [ -f "/var/log/messages" ]; then
          grep -i "$_service" /var/log/messages | tail "${@:--n 50}"
        else
          log_warn "Log file for $_service not found."
        fi
        ;;
      health)    libscript_check_health "$_service" "$@" ;;
      *) log_error "Unknown action: $_action"; return 1 ;;
    esac
    return 0
  fi

  # 5. macOS launchd
  if [ "${UNAME_LOWER:-}" = "darwin" ] && command -v launchctl >/dev/null 2>&1; then
    _plist_sys="/Library/LaunchDaemons/com.libscript.${_service}.plist"
    _plist_usr="${HOME:-/tmp}/Library/LaunchAgents/com.libscript.${_service}.plist"
    case "$_action" in
      start)
        if [ -f "$_plist_usr" ]; then
          launchctl load -w "$_plist_usr" 2>/dev/null || true
          launchctl start "com.libscript.${_service}" 2>/dev/null || true
        elif [ -f "$_plist_sys" ]; then
          priv launchctl load -w "$_plist_sys" 2>/dev/null || true
          priv launchctl start "com.libscript.${_service}" 2>/dev/null || true
        elif command -v brew >/dev/null 2>&1 && brew services list 2>/dev/null | grep -q "^${_service} "; then
          brew services start "$_service"
        else
          libscript_service_fallback start "$_service" "$@"
        fi
        ;;
      stop)
        if [ -f "$_plist_usr" ]; then
          launchctl stop "com.libscript.${_service}" 2>/dev/null || true
        elif [ -f "$_plist_sys" ]; then
          priv launchctl stop "com.libscript.${_service}" 2>/dev/null || true
        fi
        libscript_service_fallback stop "$_service" "$@" || true
        ;;
      restart|reload)
        libscript_service stop "$_service" || true
        sleep 1
        libscript_service start "$_service"
        ;;
      enable)
        [ -f "$_plist_usr" ] && launchctl load -w "$_plist_usr" 2>/dev/null || true
        [ -f "$_plist_sys" ] && priv launchctl load -w "$_plist_sys" 2>/dev/null || true
        ;;
      disable)
        [ -f "$_plist_usr" ] && launchctl unload -w "$_plist_usr" 2>/dev/null || true
        [ -f "$_plist_sys" ] && priv launchctl unload -w "$_plist_sys" 2>/dev/null || true
        ;;
      uninstall)
        libscript_uninstall_service "$_service"
        ;;
      status)
        if launchctl list 2>/dev/null | grep -q "com.libscript.${_service}"; then
          launchctl list | grep "com.libscript.${_service}"
        else
          libscript_service_fallback status "$_service" "$@"
        fi
        ;;
      logs)
        if [ -f "${LIBSCRIPT_DATA_DIR:-/tmp/data}/${_service}/stdout.log" ]; then
          tail "${@:--n 50}" "${LIBSCRIPT_DATA_DIR:-/tmp/data}/${_service}/stdout.log"
        else
          libscript_service_fallback logs "$_service" "$@"
        fi
        ;;
      health)
        libscript_check_health "$_service" "$@"
        ;;
      *) log_error "Unknown action: $_action"; return 1 ;;
    esac
    return 0
  fi

  # 6. illumos / Solaris SMF (svcadm / svcs)
  if command -v svcadm >/dev/null 2>&1; then
    _fmri="$_service"
    if ! svcs "$_fmri" >/dev/null 2>&1 && svcs "application/libscript/$_service" >/dev/null 2>&1; then
      _fmri="application/libscript/$_service"
    fi
    case "$_action" in
      start|enable)   priv svcadm enable -s "$_fmri" ;;
      stop|disable)   priv svcadm disable -s "$_fmri" ;;
      restart)        priv svcadm restart "$_fmri" ;;
      reload)         priv svcadm refresh "$_fmri" 2>/dev/null || priv svcadm restart "$_fmri" ;;
      uninstall)      libscript_uninstall_service "$_service" ;;
      status)         svcs -xv "$_fmri" ;;
      logs)
        _smf_log=$(svcs -L "$_fmri" 2>/dev/null || true)
        if [ -n "$_smf_log" ] && [ -f "$_smf_log" ]; then
          tail "${@:--n 50}" "$_smf_log"
        else
          log_warn "SMF log file for $_fmri not found."
        fi
        ;;
      health)         libscript_check_health "$_service" "$@" ;;
      *) log_error "Unknown action: $_action"; return 1 ;;
    esac
    return 0
  fi

  # 7. runit (sv) / s6 (s6-svc)
  if command -v sv >/dev/null 2>&1 && [ -d "/etc/service/${_service}" ]; then
    case "$_action" in
      start|enable)   priv sv up "$_service" ;;
      stop|disable)   priv sv down "$_service" ;;
      restart)        priv sv restart "$_service" ;;
      reload)         priv sv reload "$_service" 2>/dev/null || priv sv restart "$_service" ;;
      status)         priv sv status "$_service" ;;
      uninstall)      libscript_uninstall_service "$_service" ;;
      logs)           libscript_service_fallback logs "$_service" "$@" ;;
      health)         libscript_check_health "$_service" "$@" ;;
      *) log_error "Unknown action: $_action"; return 1 ;;
    esac
    return 0
  fi
  if command -v s6-svc >/dev/null 2>&1 && [ -d "/run/service/${_service}" ]; then
    case "$_action" in
      start|enable)   priv s6-svc -u "/run/service/${_service}" ;;
      stop|disable)   priv s6-svc -d "/run/service/${_service}" ;;
      restart)        priv s6-svc -r "/run/service/${_service}" ;;
      reload)         priv s6-svc -h "/run/service/${_service}" ;;
      status)         priv s6-svstat "/run/service/${_service}" ;;
      uninstall)      libscript_uninstall_service "$_service" ;;
      logs)           libscript_service_fallback logs "$_service" "$@" ;;
      health)         libscript_check_health "$_service" "$@" ;;
      *) log_error "Unknown action: $_action"; return 1 ;;
    esac
    return 0
  fi

  # 8. SysVinit (/etc/init.d/<service> + service / update-rc.d / chkconfig)
  if [ -x "/etc/init.d/${_service}" ] && command -v service >/dev/null 2>&1; then
    case "$_action" in
      start|stop|restart|status) priv service "$_service" "$_action" ;;
      reload)    priv service "$_service" reload 2>/dev/null || priv service "$_service" restart ;;
      enable)
        if command -v update-rc.d >/dev/null 2>&1; then
          priv update-rc.d "$_service" defaults
        elif command -v chkconfig >/dev/null 2>&1; then
          priv chkconfig "$_service" on
        fi
        ;;
      disable)
        if command -v update-rc.d >/dev/null 2>&1; then
          priv update-rc.d -f "$_service" remove
        elif command -v chkconfig >/dev/null 2>&1; then
          priv chkconfig "$_service" off
        fi
        ;;
      uninstall) libscript_uninstall_service "$_service" ;;
      logs)
        if [ -f "/var/log/${_service}.log" ]; then
          tail "${@:--n 50}" "/var/log/${_service}.log"
        else
          libscript_service_fallback logs "$_service" "$@"
        fi
        ;;
      health)    libscript_check_health "$_service" "$@" ;;
      *) log_error "Unknown action: $_action"; return 1 ;;
    esac
    return 0
  fi

  # 9. Fallback: POSIX-compatible background process management (PID files)
  libscript_service_fallback "$_action" "$_service" "$@"
}

# ## libscript_check_health
# Performs the libscript_check_health operation and updates component state.
libscript_check_health() {
  _service="${1:-}"
  shift || true

  if [ -x "$SCRIPT_DIR/health.sh" ]; then
    "$SCRIPT_DIR/health.sh" "$@" && return 0 || return 1
  fi

  if command -v jq >/dev/null 2>&1 && [ -f "$SCRIPT_DIR/vars.schema.json" ]; then
    _hc_cmd=$(jq -r '.healthcheck // empty' "$SCRIPT_DIR/vars.schema.json")
    if [ -n "$_hc_cmd" ] && [ "$_hc_cmd" != "null" ]; then
      log_info "Running custom healthcheck for $_service..."
      if sh -c "$_hc_cmd"; then
        log_info "$_service is healthy"
        return 0
      else
        log_error "$_service is unhealthy"
        return 1
      fi
    fi
  fi

  log_info "No custom healthcheck found for $_service, checking service status..."
  if command -v systemctl >/dev/null 2>&1 && { [ -d /run/systemd/system ] || [ "${LIBSCRIPT_MOCK_SYSTEMD:-0}" = "1" ]; }; then
    _systemctl_cmd="priv systemctl"
    if systemctl --user --quiet is-enabled "$_service" 2>/dev/null || systemctl --user --quiet is-active "$_service" 2>/dev/null; then
      _systemctl_cmd="systemctl --user"
    fi
    if $_systemctl_cmd is-active --quiet "$_service"; then
      log_info "$_service is active"
      return 0
    fi
    case "$_service" in
      libscript_*)
        _bare_hc="${_service#libscript_}"
        if $_systemctl_cmd is-active --quiet "$_bare_hc"; then
          log_info "$_bare_hc is active"
          return 0
        fi
        ;;
    esac
  elif command -v rc-service >/dev/null 2>&1; then
    if priv rc-service "$_service" status | grep -q "started"; then
      log_info "$_service is started"
      return 0
    fi
  elif command -v svcs >/dev/null 2>&1; then
    _fmri="$_service"
    if ! svcs "$_fmri" >/dev/null 2>&1 && svcs "application/libscript/$_service" >/dev/null 2>&1; then
      _fmri="application/libscript/$_service"
    fi
    if [ "$(svcs -H -o state "$_fmri" 2>/dev/null)" = "online" ]; then
      log_info "$_service is online"
      return 0
    fi
  elif [ "${UNAME_LOWER:-}" = "freebsd" ] || command -v sysrc >/dev/null 2>&1; then
    if priv service "$_service" status >/dev/null 2>&1; then
      log_info "$_service is running"
      return 0
    fi
  elif command -v sc.exe >/dev/null 2>&1; then
    if sc.exe query "$_service" | grep -q "RUNNING"; then
      log_info "$_service is healthy"
      return 0
    fi
  else
    if libscript_service_fallback status "$_service" >/dev/null 2>&1; then
      log_info "$_service is running (fallback PID)"
      return 0
    fi
  fi

  log_error "$_service is NOT healthy"
  return 1
}
