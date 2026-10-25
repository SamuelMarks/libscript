#!/bin/sh
# ## Overview
# Internal script for service_install. Registers, overrides environment for, or removes a
# service using the OS-native init system or fallback runner.
#
# ## Usage
# . "$LIBSCRIPT_ROOT_DIR/_lib/_common/service_install.sh"
# libscript_install_service <service_name> <exec_start> [working_dir] [description] [env]
# libscript_uninstall_service <service_name>
# libscript_service_override_env <service_name> <KEY=VALUE...>

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
for LIB in "_lib/_common/os_info.sh" "_lib/_common/priv.sh" "_lib/_common/log.sh"; do
  if [ -f "${LIBSCRIPT_ROOT_DIR}/${LIB}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${LIB}"
    export SCRIPT_NAME
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
done
unset SCRIPT_NAME || true

# ## libscript_install_service
# Performs the libscript_install_service operation and updates component state.
libscript_install_service() {
  _service_name="$1"
  _exec_start="$2"
  _working_dir="${3:-/}"
  _description="${4:-$_service_name service}"
  _env="${5:-}"
  _rc_name=$(printf '%s\n' "$_service_name" | tr '-' '_')

  if [ "${LIBSCRIPT_FORCE_FALLBACK_DAEMON:-0}" != "1" ] && command -v systemctl >/dev/null 2>&1 && { [ -d /run/systemd/system ] || [ "${LIBSCRIPT_MOCK_SYSTEMD:-0}" = "1" ]; }; then
    log_info "Installing systemd service: $_service_name"
    _tmp_file=$(mktemp)

    export DESCRIPTION="$_description"
    export EXEC_START="$_exec_start"
    export WORKING_DIR="$_working_dir"
    export ENV="$_env"

    if command -v envsubst >/dev/null 2>&1; then
      envsubst < "${LIBSCRIPT_ROOT_DIR}/_lib/init-systems/systemd/simple.service" > "$_tmp_file"
    else
      sed "s|\${DESCRIPTION}|${DESCRIPTION}|g" "${LIBSCRIPT_ROOT_DIR}/_lib/init-systems/systemd/simple.service" | \
        sed "s|\${EXEC_START}|${EXEC_START}|g" | \
        sed "s|\${WORKING_DIR}|${WORKING_DIR}|g" | \
        sed "s|\${ENV}|${ENV}|g" > "$_tmp_file"
    fi

    priv install -m 0644 -o 'root' -- "$_tmp_file" "/etc/systemd/system/${_service_name}.service"
    priv systemctl daemon-reload
    priv systemctl enable "$_service_name"
    rm -f "$_tmp_file"
  elif [ "${LIBSCRIPT_FORCE_FALLBACK_DAEMON:-0}" != "1" ] && command -v rc-service >/dev/null 2>&1; then
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

# ## depend
# Performs the depend operation and updates component state.
depend() {
    need net
}
EOF
    priv install -m 0755 -o 'root' -- "$_tmp_file" "/etc/init.d/$_service_name"
    priv rc-update add "$_service_name" default
    rm -f "$_tmp_file"
  elif [ "${LIBSCRIPT_FORCE_FALLBACK_DAEMON:-0}" != "1" ] && command -v svccfg >/dev/null 2>&1; then
    log_info "Installing SMF manifest: $_service_name"
    _tmp_file=$(mktemp)
    _xml_exec=$(printf '%s' "$_exec_start" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
    cat > "$_tmp_file" <<EOF
<?xml version="1.0"?>
<!DOCTYPE service_bundle SYSTEM "/usr/share/lib/xml/dtd/service_bundle.dtd.1">
<service_bundle type='manifest' name='libscript:$_service_name'>
  <service name='application/libscript/$_service_name' type='service' version='1'>
    <create_default_instance enabled='true' />
    <single_instance />
    <exec_method type='method' name='start' exec='$_xml_exec' timeout_seconds='60'>
      <method_context working_directory='$_working_dir' />
    </exec_method>
    <exec_method type='method' name='stop' exec=':kill' timeout_seconds='60' />
    <property_group name='startd' type='framework'>
      <propval name='duration' type='astring' value='child' />
    </property_group>
  </service>
</service_bundle>
EOF
    priv svccfg import "$_tmp_file"
    priv svcadm enable -s "application/libscript/$_service_name"
    rm -f "$_tmp_file"
  elif [ "${LIBSCRIPT_FORCE_FALLBACK_DAEMON:-0}" != "1" ] && [ "${UNAME_LOWER:-$(uname -s | tr '[:upper:]' '[:lower:]')}" = "freebsd" ]; then
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
: \${${_rc_name}_enable:="NO"}

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
    log_info "Registering fallback daemon runner for service: $_service_name"
    _fb_dir="${LIBSCRIPT_DATA_DIR:-/tmp/data}/${_service_name}"
    mkdir -p "$_fb_dir"
    {
      printf '#!/bin/sh\n'
      printf 'if [ -f "/etc/libscript/%s/service.env" ]; then set -a; . "/etc/libscript/%s/service.env"; set +a; fi\n' "$_service_name" "$_service_name"
      printf 'if [ -f "%s/service.env" ]; then set -a; . "%s/service.env"; set +a; fi\n' "$_fb_dir" "$_fb_dir"
      printf 'cd "%s" || exit 1\n' "$_working_dir"
      printf 'exec %s\n' "$_exec_start"
    } > "${_fb_dir}/run_${_service_name}.sh"
    chmod +x "${_fb_dir}/run_${_service_name}.sh"
  fi
}

# ## libscript_service_override_env
# Configures persistent environment variable overrides for a service across init systems.
libscript_service_override_env() {
  _ovr_service="${1:-}"
  shift || true
  if [ -z "$_ovr_service" ] || [ $# -eq 0 ]; then
    log_error "Usage: libscript_service_override_env <service_name> <KEY=VALUE...>"
    return 1
  fi
  _ovr_rc_name=$(printf '%s\n' "$_ovr_service" | tr '-' '_')

  # 1. Generic / fallback env file
  _ovr_fb_dir="${LIBSCRIPT_DATA_DIR:-/tmp/data}/${_ovr_service}"
  mkdir -p "$_ovr_fb_dir" 2>/dev/null || true
  if [ -w "$_ovr_fb_dir" ]; then
    : > "${_ovr_fb_dir}/service.env"
    for _kv in "$@"; do
      printf 'export %s\n' "$_kv" >> "${_ovr_fb_dir}/service.env"
    done
  fi
  if [ "$(id -u 2>/dev/null || printf '1000')" -eq 0 ] || sudo -n true 2>/dev/null; then
    priv mkdir -p "/etc/libscript/${_ovr_service}" 2>/dev/null || true
    _tmp_gen=$(mktemp)
    for _kv in "$@"; do
      printf 'export %s\n' "$_kv" >> "$_tmp_gen"
    done
    priv install -m 0644 -- "$_tmp_gen" "/etc/libscript/${_ovr_service}/service.env" 2>/dev/null || true
    rm -f "$_tmp_gen"
  fi

  # 2. Systemd drop-in override
  if [ "${LIBSCRIPT_FORCE_FALLBACK_DAEMON:-0}" != "1" ] && command -v systemctl >/dev/null 2>&1 && { [ -d /run/systemd/system ] || [ "${LIBSCRIPT_MOCK_SYSTEMD:-0}" = "1" ]; }; then
    _ovr_dir="/etc/systemd/system/${_ovr_service}.service.d"
    priv mkdir -p "$_ovr_dir"
    _tmp_ovr=$(mktemp)
    printf '[Service]\n' > "$_tmp_ovr"
    for _kv in "$@"; do
      printf 'Environment="%s"\n' "$_kv" >> "$_tmp_ovr"
    done
    priv install -m 0644 -- "$_tmp_ovr" "${_ovr_dir}/override.conf"
    rm -f "$_tmp_ovr"
    priv systemctl daemon-reload 2>/dev/null || true
    return 0
  fi

  # 3. OpenRC /etc/conf.d/<service>
  if [ "${LIBSCRIPT_FORCE_FALLBACK_DAEMON:-0}" != "1" ] && command -v rc-service >/dev/null 2>&1; then
    priv mkdir -p /etc/conf.d
    _tmp_ovr=$(mktemp)
    [ -f "/etc/conf.d/${_ovr_service}" ] && cat "/etc/conf.d/${_ovr_service}" > "$_tmp_ovr" || true
    for _kv in "$@"; do
      _k="${_kv%%=*}"
      grep -v "^export ${_k}=" "$_tmp_ovr" > "${_tmp_ovr}.new" 2>/dev/null || true
      mv "${_tmp_ovr}.new" "$_tmp_ovr"
      printf 'export %s\n' "$_kv" >> "$_tmp_ovr"
    done
    priv install -m 0644 -- "$_tmp_ovr" "/etc/conf.d/${_ovr_service}"
    rm -f "$_tmp_ovr"
    return 0
  fi

  # 4. FreeBSD / BSD /etc/rc.conf.d/<service>
  if [ "${LIBSCRIPT_FORCE_FALLBACK_DAEMON:-0}" != "1" ] && { [ "${UNAME_LOWER:-}" = "freebsd" ] || command -v sysrc >/dev/null 2>&1; }; then
    priv mkdir -p /etc/rc.conf.d
    _tmp_ovr=$(mktemp)
    [ -f "/etc/rc.conf.d/${_ovr_rc_name}" ] && cat "/etc/rc.conf.d/${_ovr_rc_name}" > "$_tmp_ovr" || true
    for _kv in "$@"; do
      _k="${_kv%%=*}"
      grep -v "^export ${_k}=" "$_tmp_ovr" > "${_tmp_ovr}.new" 2>/dev/null || true
      mv "${_tmp_ovr}.new" "$_tmp_ovr"
      printf 'export %s\n' "$_kv" >> "$_tmp_ovr"
    done
    priv install -m 0644 -- "$_tmp_ovr" "/etc/rc.conf.d/${_ovr_rc_name}"
    rm -f "$_tmp_ovr"
    return 0
  fi

  # 5. macOS launchd EnvironmentVariables
  if [ "${LIBSCRIPT_FORCE_FALLBACK_DAEMON:-0}" != "1" ] && [ "${UNAME_LOWER:-}" = "darwin" ] && command -v launchctl >/dev/null 2>&1; then
    for _kv in "$@"; do
      _k="${_kv%%=*}"
      _v="${_kv#*=}"
      launchctl setenv "$_k" "$_v" 2>/dev/null || true
    done
    return 0
  fi

  return 0
}

# ## libscript_uninstall_service
# Performs the libscript_uninstall_service operation across supported init systems and updates component state.
libscript_uninstall_service() {
  _service_name="$1"
  _rc_name=$(printf '%s\n' "$_service_name" | tr '-' '_')
  _fb_dir="${LIBSCRIPT_DATA_DIR:-/tmp/data}/${_service_name}"

  if [ -f "${_fb_dir}/service.pid" ]; then
    _fb_pid=$(cat "${_fb_dir}/service.pid" 2>/dev/null || true)
    if [ -n "$_fb_pid" ] && kill -0 "$_fb_pid" 2>/dev/null; then
      kill "$_fb_pid" 2>/dev/null || priv kill "$_fb_pid" 2>/dev/null || true
    fi
    rm -f "${_fb_dir}/service.pid" 2>/dev/null || true
  fi
  rm -f "${_fb_dir}/run_${_service_name}.sh" "${_fb_dir}/systemd_run_${_service_name}.sh" 2>/dev/null || true

  if command -v systemctl >/dev/null 2>&1 && { [ -d /run/systemd/system ] || [ "${LIBSCRIPT_MOCK_SYSTEMD:-0}" = "1" ]; }; then
    log_info "Uninstalling systemd service: $_service_name"
    priv systemctl stop "$_service_name" 2>/dev/null || true
    priv systemctl disable "$_service_name" 2>/dev/null || true
    priv rm -f "/etc/systemd/system/${_service_name}.service"
    priv rm -rf "/etc/systemd/system/${_service_name}.service.d"
    if [ -f "${HOME:-/tmp}/.config/systemd/user/${_service_name}.service" ]; then
      systemctl --user stop "$_service_name" 2>/dev/null || true
      systemctl --user disable "$_service_name" 2>/dev/null || true
      rm -f "${HOME:-/tmp}/.config/systemd/user/${_service_name}.service"
      systemctl --user daemon-reload 2>/dev/null || true
    fi
    priv systemctl daemon-reload 2>/dev/null || true
  elif command -v rc-service >/dev/null 2>&1; then
    log_info "Uninstalling OpenRC service: $_service_name"
    priv rc-service "$_service_name" stop 2>/dev/null || true
    priv rc-update del "$_service_name" default 2>/dev/null || true
    priv rm -f "/etc/init.d/$_service_name" "/etc/conf.d/$_service_name"
  elif command -v svccfg >/dev/null 2>&1; then
    log_info "Uninstalling SMF service: $_service_name"
    priv svcadm disable -s "application/libscript/$_service_name" 2>/dev/null || true
    priv svccfg delete "application/libscript/$_service_name" 2>/dev/null || true
  elif [ "${UNAME_LOWER:-$(uname -s | tr '[:upper:]' '[:lower:]')}" = "freebsd" ] || command -v sysrc >/dev/null 2>&1; then
    log_info "Uninstalling FreeBSD rc.d service: $_service_name"
    priv service "$_rc_name" stop 2>/dev/null || true
    command -v sysrc >/dev/null 2>&1 && priv sysrc "${_rc_name}_enable=NO" 2>/dev/null || true
    priv rm -f "/usr/local/etc/rc.d/$_rc_name" "/etc/rc.conf.d/$_rc_name"
  elif [ "${UNAME_LOWER:-$(uname -s | tr '[:upper:]' '[:lower:]')}" = "darwin" ] && command -v launchctl >/dev/null 2>&1; then
    log_info "Uninstalling launchd service: $_service_name"
    if [ -f "${HOME:-/tmp}/Library/LaunchAgents/com.libscript.${_service_name}.plist" ]; then
      launchctl stop "com.libscript.${_service_name}" 2>/dev/null || true
      launchctl unload -w "${HOME:-/tmp}/Library/LaunchAgents/com.libscript.${_service_name}.plist" 2>/dev/null || true
      rm -f "${HOME:-/tmp}/Library/LaunchAgents/com.libscript.${_service_name}.plist"
    fi
    if [ -f "/Library/LaunchDaemons/com.libscript.${_service_name}.plist" ]; then
      priv launchctl stop "com.libscript.${_service_name}" 2>/dev/null || true
      priv launchctl unload -w "/Library/LaunchDaemons/com.libscript.${_service_name}.plist" 2>/dev/null || true
      priv rm -f "/Library/LaunchDaemons/com.libscript.${_service_name}.plist"
    fi
  elif [ -x "/etc/init.d/${_service_name}" ]; then
    log_info "Uninstalling SysVinit service: $_service_name"
    priv service "$_service_name" stop 2>/dev/null || true
    command -v update-rc.d >/dev/null 2>&1 && priv update-rc.d -f "$_service_name" remove 2>/dev/null || true
    command -v chkconfig >/dev/null 2>&1 && priv chkconfig "$_service_name" off 2>/dev/null || true
    priv rm -f "/etc/init.d/${_service_name}"
  elif command -v sc.exe >/dev/null 2>&1; then
    log_info "Uninstalling Windows service: $_service_name"
    sc.exe stop "$_service_name" 2>/dev/null || true
    sc.exe delete "$_service_name" 2>/dev/null || true
  fi
}

if [ "${THIS_FILE}" = "${0}" ] && [ $# -gt 0 ]; then
  _si_cmd="$1"
  shift
  case "$_si_cmd" in
    install|--install) libscript_install_service "$@" ;;
    uninstall|--uninstall) libscript_uninstall_service "$@" ;;
    override-env|--override-env) libscript_service_override_env "$@" ;;
    *) libscript_install_service "$_si_cmd" "$@" ;;
  esac
fi
