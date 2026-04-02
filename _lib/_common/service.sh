#!/bin/sh
# # LibScript Unified Service Management Utility
#
# ## Overview
# This module provides a cross-platform abstraction for managing services 
# (daemons) across different init systems (systemd, openrc, sc.exe, etc.).
#
# ## Usage
# . "$LIBSCRIPT_ROOT_DIR/_lib/_common/service.sh"
# libscript_service [ACTION] [SERVICE_NAME] [OPTIONS]
#
# Actions: start, stop, restart, status, health, logs, enable, disable

set -feu

# Boilerplate for finding this file and root
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  this_file="${0}"
else
  this_file="${0}"
fi

# Resolve LibScript root if not set
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(d="$(cd "$(dirname -- "${this_file}")" && pwd)"; while [ ! -f "${d}"'/ROOT' ]; do d="$(dirname -- "${d}")"; done; printf '%s' "${d}")}"

# Source dependencies
. "${LIBSCRIPT_ROOT_DIR}/_lib/_common/os_info.sh"
. "${LIBSCRIPT_ROOT_DIR}/_lib/_common/priv.sh"
. "${LIBSCRIPT_ROOT_DIR}/_lib/_common/log.sh"

libscript_service() {
  _action="${1:-}"
  _service="${2:-}"
  shift 2 || true
  
  if [ -z "$_action" ] || [ -z "$_service" ]; then
    log_error "Usage: libscript_service [ACTION] [SERVICE_NAME] [OPTIONS]"
    return 1
  fi

  # Support action aliases
  case "$_action" in
    up) _action="start" ;;
    down) _action="stop" ;;
    query) _action="status" ;;
  esac

  # 1. Windows (sc.exe)
  if command -v sc.exe >/dev/null 2>&1; then
    case "$_action" in
      start)   sc.exe start "$_service" ;;
      stop)    sc.exe stop "$_service" ;;
      restart) sc.exe stop "$_service" || true; sleep 2; sc.exe start "$_service" ;;
      status)  sc.exe query "$_service" ;;
      enable)  sc.exe config "$_service" start= auto ;;
      disable) sc.exe config "$_service" start= disabled ;;
      logs)    log_warn "Logs not natively supported via sc.exe for $_service" ;;
      health)  libscript_check_health "$_service" "$@" ;;
      *) log_error "Unknown action: $_action"; return 1 ;;
    esac
    return 0
  fi

  # 2. Systemd
  if command -v systemctl >/dev/null 2>&1; then
    # Check if it is a user service or system service
    _systemctl_cmd="priv systemctl"
    if systemctl --user --quiet is-enabled "$_service" 2>/dev/null || systemctl --user --quiet is-active "$_service" 2>/dev/null; then
      _systemctl_cmd="systemctl --user"
    fi

    case "$_action" in
      start)   $_systemctl_cmd start "$_service" ;;
      stop)    $_systemctl_cmd stop "$_service" ;;
      restart) $_systemctl_cmd restart "$_service" ;;
      status)  $_systemctl_cmd status "$_service" --no-pager ;;
      enable)  $_systemctl_cmd enable "$_service" ;;
      disable) $_systemctl_cmd disable "$_service" ;;
      logs)    priv journalctl -u "$_service" "$@" ;;
      health)  libscript_check_health "$_service" "$@" ;;
      *) log_error "Unknown action: $_action"; return 1 ;;
    esac
    return 0
  fi

  # 3. OpenRC
  if command -v rc-service >/dev/null 2>&1; then
    case "$_action" in
      start|stop|restart|status) priv rc-service "$_service" "$_action" ;;
      enable)  priv rc-update add "$_service" default ;;
      disable) priv rc-update del "$_service" default ;;
      logs)    
        # OpenRC usually logs to /var/log/messages or a service-specific file
        if [ -f "/var/log/$_service.log" ]; then
          tail "$@" "/var/log/$_service.log"
        else
          log_warn "Log file /var/log/$_service.log not found."
        fi
        ;;
      health)  libscript_check_health "$_service" "$@" ;;
      *) log_error "Unknown action: $_action"; return 1 ;;
    esac
    return 0
  fi

  # 4. Fallback: POSIX-compatible background process management (PID files)
  # This is a very basic fallback for systems without a real init system
  _pid_file="/var/run/${_service}.pid"
  [ -w "/var/run" ] || _pid_file="/tmp/${_service}.pid"

  case "$_action" in
    status|health)
      if [ "$_action" = "health" ]; then
        libscript_check_health "$_service" "$@" && return 0 || return 1
      fi
      if [ -f "$_pid_file" ]; then
        _pid=$(cat "$_pid_file")
        if kill -0 "$_pid" 2>/dev/null; then
          log_info "$_service is running (PID: $_pid)"
          return 0
        fi
      fi
      log_error "$_service is NOT running"
      return 1
      ;;
    stop)
      if [ -f "$_pid_file" ]; then
        _pid=$(cat "$_pid_file")
        priv kill "$_pid" && rm -f "$_pid_file"
      fi
      ;;
    *)
      log_error "Init system not detected and action '$_action' not supported via fallback."
      return 1
      ;;
  esac
}

libscript_check_health() {
  _service="${1:-}"
  shift || true
  
  # 1. Check for component-specific health.sh
  if [ -x "$SCRIPT_DIR/health.sh" ]; then
    "$SCRIPT_DIR/health.sh" "$@" && return 0 || return 1
  fi
  
  # 2. Check for healthcheck command in vars.schema.json
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
  
  # 3. Default: Check if service is active/running
  log_info "No custom healthcheck found for $_service, checking service status..."
  if command -v systemctl >/dev/null 2>&1; then
    _systemctl_cmd="priv systemctl"
    if systemctl --user --quiet is-enabled "$_service" 2>/dev/null || systemctl --user --quiet is-active "$_service" 2>/dev/null; then
      _systemctl_cmd="systemctl --user"
    fi
    if $_systemctl_cmd is-active --quiet "$_service"; then
      log_info "$_service is active"
      return 0
    fi
  elif command -v rc-service >/dev/null 2>&1; then
    if priv rc-service "$_service" status | grep -q "started"; then
      log_info "$_service is started"
      return 0
    fi
  elif command -v sc.exe >/dev/null 2>&1; then
    if sc.exe query "$_service" | grep -q "RUNNING"; then
      log_info "$_service is healthy"
      return 0
    fi
  fi
  
  log_error "$_service is NOT healthy"
  return 1
}
