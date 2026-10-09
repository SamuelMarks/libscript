#!/bin/sh
# ## Overview
# Internal script for service_install.
#
# ## Usage
# Executes initialization, logic, or testing for service_install.
# LibScript Service Installer
# Registers a service using the OS-native init system.

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
for LIB in "_lib/_common/os_info.sh" "_lib/_common/priv.sh" "_lib/_common/log.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

# ## libscript_install_service
# Executes libscript_install_service functionality.
libscript_install_service() {
  _service_name="$1"
  _exec_start="$2"
  _working_dir="${3:-/}"
  _description="${4:-$_service_name service}"
  _env="${5:-}"
  _rc_name=$(printf '%s\n' "$_service_name" | tr '-' '_')

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
    log_info "Installing OpenRC service: $_service_name"
    _tmp_file=$(mktemp)
    _openrc_cmd="$_exec_start"
    _openrc_args=""
    case "$_exec_start" in
      *" "*)
        _openrc_cmd="${_exec_start%% *}"
        _openrc_args="${_exec_start#* }"
        ;;
    esac
    cat > "$_tmp_file" <<EOF
#!/sbin/openrc-run
# $_description

name="$_service_name"
description="$_description"
command="${_openrc_cmd}"
command_args="${_openrc_args}"
command_background="yes"
pidfile="/run/$_service_name.pid"
directory="$_working_dir"
output_log="/var/log/${_service_name}.log"
error_log="/var/log/${_service_name}_err.log"

depend() {
    need net
}
EOF
    priv install -m 0755 -o 'root' -- "$_tmp_file" "/etc/init.d/$_service_name"
    priv rc-update add "$_service_name" default
    rm -f "$_tmp_file"
  elif command -v svccfg >/dev/null 2>&1; then
    log_info "Installing SMF manifest: $_service_name"
    _tmp_file=$(mktemp)
    cat > "$_tmp_file" <<EOF
<?xml version="1.0"?>
<!DOCTYPE service_bundle SYSTEM "/usr/share/lib/xml/dtd/service_bundle.dtd.1">
<service_bundle type='manifest' name='libscript:$_service_name'>
  <service name='application/libscript/$_service_name' type='service' version='1'>
    <create_default_instance enabled='true' />
    <single_instance />
    <exec_method type='method' name='start' exec='$_exec_start' timeout_seconds='60'>
      <method_context working_directory='$_working_dir' />
    </exec_method>
    <exec_method type='method' name='stop' exec=':kill' timeout_seconds='60' />
    <property_group name='startd' type='framework'>
      <propval name='duration' type='astring' value='contract' />
    </property_group>
  </service>
</service_bundle>
EOF
    priv svccfg import "$_tmp_file"
    priv svcadm enable -s "application/libscript/$_service_name"
    rm -f "$_tmp_file"
  elif [ "${UNAME_LOWER:-$(uname -s | tr '[:upper:]' '[:lower:]')}" = "freebsd" ]; then
    log_info "Installing FreeBSD rc.d service: $_service_name"
    _tmp_file=$(mktemp)
    cat > "$_tmp_file" <<EOF
#!/bin/sh
#
# PROVIDE: $_rc_name
# REQUIRE: networking
# KEYWORD: shutdown

. /etc/rc.subr

name="$_rc_name"
rcvar="\${name}_enable"
pidfile="/var/run/\${name}.pid"
command="/usr/sbin/daemon"
command_args="-P \${pidfile} -r -f -o /var/log/\${name}.log $_exec_start"

load_rc_config \$name
: \${\${name}_enable:="NO"}

run_rc_command "\$1"
EOF
    priv install -m 0755 -o 'root' -- "$_tmp_file" "/usr/local/etc/rc.d/$_rc_name"
    priv sysrc "${_rc_name}_enable=YES"
    rm -f "$_tmp_file"
  elif command -v sc.exe >/dev/null 2>&1; then
    log_info "Installing Windows service: $_service_name"
    if sc.exe query "$_service_name" >/dev/null 2>&1; then
      sc.exe config "$_service_name" binPath= "$_exec_start" start= auto obj= LocalSystem
    else
      sc.exe create "$_service_name" binPath= "$_exec_start" start= auto obj= LocalSystem
    fi
    sc.exe description "$_service_name" "$_description"
  else
    log_warn "No supported init system found to install service: $_service_name"
  fi
}

# ## libscript_uninstall_service
# Executes libscript_uninstall_service functionality.
libscript_uninstall_service() {
  _service_name="$1"
  _rc_name=$(printf '%s\n' "$_service_name" | tr '-' '_')
  
  if command -v systemctl >/dev/null 2>&1; then
    log_info "Uninstalling systemd service: $_service_name"
    priv systemctl stop "$_service_name" || true
    priv systemctl disable "$_service_name" || true
    priv rm -f "/etc/systemd/system/${_service_name}.service"
    priv systemctl daemon-reload
  elif command -v rc-service >/dev/null 2>&1; then
    log_info "Uninstalling OpenRC service: $_service_name"
    priv rc-service "$_service_name" stop || true
    priv rc-update del "$_service_name" default || true
    priv rm -f "/etc/init.d/$_service_name"
  elif command -v svccfg >/dev/null 2>&1; then
    log_info "Uninstalling SMF service: $_service_name"
    priv svcadm disable -s "application/libscript/$_service_name" || true
    priv svccfg delete "application/libscript/$_service_name" || true
  elif [ "${UNAME_LOWER:-$(uname -s | tr '[:upper:]' '[:lower:]')}" = "freebsd" ]; then
    log_info "Uninstalling FreeBSD rc.d service: $_service_name"
    priv service "$_rc_name" stop || true
    priv sysrc "${_rc_name}_enable=NO" || true
    priv rm -f "/usr/local/etc/rc.d/$_rc_name"
  elif command -v sc.exe >/dev/null 2>&1; then
    log_info "Uninstalling Windows service: $_service_name"
    sc.exe stop "$_service_name" || true
    sc.exe delete "$_service_name"
  else
    log_warn "No supported init system found to uninstall service: $_service_name"
  fi
}
