#!/bin/sh
# LibScript Service Installer
# Registers a service using the OS-native init system.

set -feu
SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
. "${LIBSCRIPT_ROOT_DIR}/_lib/_common/os_info.sh"
. "${LIBSCRIPT_ROOT_DIR}/_lib/_common/priv.sh"
. "${LIBSCRIPT_ROOT_DIR}/_lib/_common/log.sh"

libscript_install_service() {
  _service_name="$1"
  _exec_start="$2"
  _working_dir="${3:-/}"
  _description="${4:-$_service_name service}"
  _env="${5:-}"

  if command -v systemctl >/dev/null 2>&1; then
    log_info "Installing systemd service: $_service_name"
    _tmp_file=$(mktemp)
    
    export DESCRIPTION="$_description"
    export EXEC_START="$_exec_start"
    export WORKING_DIR="$_working_dir"
    export ENV="$_env"
    
    if command -v envsubst >/dev/null 2>&1; then
      envsubst < "${LIBSCRIPT_ROOT_DIR}/_lib/init-systems/systemd/simple.service" > "$_tmp_file"
    else
      # basic fallback
      cat "${LIBSCRIPT_ROOT_DIR}/_lib/init-systems/systemd/simple.service" | \
        sed "s|\${DESCRIPTION}|${DESCRIPTION}|g" | \
        sed "s|\${EXEC_START}|${EXEC_START}|g" | \
        sed "s|\${WORKING_DIR}|${WORKING_DIR}|g" | \
        sed "s|\${ENV}|${ENV}|g" > "$_tmp_file"
    fi
    
    priv install -m 0644 -o 'root' -- "$_tmp_file" "/etc/systemd/system/${_service_name}.service"
    priv systemctl daemon-reload
    priv systemctl enable "$_service_name"
    rm -f "$_tmp_file"
  elif command -v rc-service >/dev/null 2>&1; then
    log_warn "OpenRC service installation not yet implemented in service_install.sh"
  elif command -v sc.exe >/dev/null 2>&1; then
    log_info "Installing Windows service: $_service_name"
    sc.exe create "$_service_name" binPath= "$_exec_start" start= auto obj= LocalSystem
    sc.exe description "$_service_name" "$_description"
  else
    log_warn "No supported init system found to install service: $_service_name"
  fi
}

libscript_uninstall_service() {
  _service_name="$1"
  
  if command -v systemctl >/dev/null 2>&1; then
    log_info "Uninstalling systemd service: $_service_name"
    priv systemctl stop "$_service_name" || true
    priv systemctl disable "$_service_name" || true
    priv rm -f "/etc/systemd/system/${_service_name}.service"
    priv systemctl daemon-reload
  elif command -v rc-service >/dev/null 2>&1; then
    log_warn "OpenRC service uninstallation not yet implemented in service_install.sh"
  elif command -v sc.exe >/dev/null 2>&1; then
    log_info "Uninstalling Windows service: $_service_name"
    sc.exe stop "$_service_name" || true
    sc.exe delete "$_service_name"
  else
    log_warn "No supported init system found to uninstall service: $_service_name"
  fi
}
