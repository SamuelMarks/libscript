#!/bin/sh
# ## Overview
# Internal script for service_install. Registers, overrides environment for, or removes a
# service using the OS-native init system (systemd, openrc, sysvinit, bsd_rc, launchd, smf,
# runit, s6, Windows sc.exe) or fallback runner.
#
# ## Usage
# . "$LIBSCRIPT_ROOT_DIR/_lib/_common/service_install.sh"
# libscript_install_service <service_name> <exec_start> [working_dir] [description] [env] [user] [env_files]
# libscript_uninstall_service <service_name>
# libscript_service_override_env <service_name> <KEY=VALUE...>

set -feu
_si_outer_this="${THIS_FILE:-}"; _si_outer_dir="${SCRIPT_DIR:-}"
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
    [ -n "$_si_outer_this" ] && THIS_FILE="$_si_outer_this"
    [ -n "$_si_outer_dir" ] && SCRIPT_DIR="$_si_outer_dir"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'

SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
_si_caller_this="${THIS_FILE}"
_si_caller_dir="${SCRIPT_DIR}"
for LIB in "_lib/_common/os_info.sh" "_lib/_common/priv.sh" "_lib/_common/log.sh" "_lib/_common/python_env.sh"; do
  if [ -f "${LIBSCRIPT_ROOT_DIR}/${LIB}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${LIB}"
    export SCRIPT_NAME
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
done
THIS_FILE="${_si_caller_this}"
SCRIPT_DIR="${_si_caller_dir}"
unset SCRIPT_NAME _si_caller_this _si_caller_dir || true
unset SCRIPT_NAME _si_caller_this || true

# ## libscript_detect_init_system
# Detects the active or requested init system based on LIBSCRIPT_INIT_SYSTEM, INIT_SYSTEM,
# LIBSCRIPT_FORCE_FALLBACK_DAEMON, and runtime capabilities.
libscript_detect_init_system() {
  if [ "${LIBSCRIPT_FORCE_FALLBACK_DAEMON:-0}" = "1" ]; then
    printf '%s\n' 'fallback'
    return 0
  fi
  _req_init="${LIBSCRIPT_INIT_SYSTEM:-${INIT_SYSTEM:-auto}}"
  case "$_req_init" in
    fallback|none|pid)
      printf '%s\n' 'fallback'
      return 0
      ;;
    systemd|openrc|sysvinit|bsd_rc|launchd|smf|runit|s6|sc)
      printf '%s\n' "$_req_init"
      return 0
      ;;
  esac

  _uname_l="${UNAME_LOWER:-$(uname -s 2>/dev/null | tr '[:upper:]' '[:lower:]' || printf 'linux')}"
  if command -v systemctl >/dev/null 2>&1 && { [ -d /run/systemd/system ] || [ "${LIBSCRIPT_MOCK_SYSTEMD:-0}" = "1" ]; }; then
    printf '%s\n' 'systemd'
  elif command -v rc-service >/dev/null 2>&1; then
    printf '%s\n' 'openrc'
  elif command -v svccfg >/dev/null 2>&1 && command -v svcadm >/dev/null 2>&1; then
    printf '%s\n' 'smf'
  elif [ "$_uname_l" = "freebsd" ] || [ "$_uname_l" = "openbsd" ] || [ "$_uname_l" = "netbsd" ] || command -v sysrc >/dev/null 2>&1; then
    printf '%s\n' 'bsd_rc'
  elif [ "$_uname_l" = "darwin" ] && command -v launchctl >/dev/null 2>&1 && [ "${LIBSCRIPT_USE_LAUNCHD:-0}" = "1" ]; then
    printf '%s\n' 'launchd'
  elif command -v sv >/dev/null 2>&1 && [ -d /etc/service ]; then
    printf '%s\n' 'runit'
  elif command -v s6-svc >/dev/null 2>&1 && { [ -d /run/service ] || [ -d /etc/s6/sv ]; }; then
    printf '%s\n' 's6'
  elif [ -d /etc/init.d ] && command -v service >/dev/null 2>&1 && { [ "$(id -u 2>/dev/null || printf '1000')" -eq 0 ] || sudo -n true 2>/dev/null; }; then
    printf '%s\n' 'sysvinit'
  elif command -v sc.exe >/dev/null 2>&1; then
    printf '%s\n' 'sc'
  else
    printf '%s\n' 'fallback'
  fi
}

# ## libscript_write_service_runner
# Writes an isolated, init-agnostic POSIX /bin/sh runner script for a service at
# ${LIBSCRIPT_DATA_DIR}/<service>/run_<service>.sh.
libscript_write_service_runner() {
  _wsr_name="$1"
  _wsr_exec="$2"
  _wsr_wd="${3:-/}"
  _wsr_env="${4:-}"
  _wsr_user="${5:-${LIBSCRIPT_SERVICE_USER:-}}"
  _wsr_env_files="${6:-${LIBSCRIPT_SERVICE_ENV_FILES:-}}"
  _wsr_manifest_dir="${LIBSCRIPT_SERVICE_MANIFEST_DIR:-$_wsr_wd}"

  _wsr_data="${LIBSCRIPT_DATA_DIR:-/tmp/data}/${_wsr_name}"
  mkdir -p "$_wsr_data" 2>/dev/null || priv mkdir -p "$_wsr_data" 2>/dev/null || true

  _wsr_home="${REMOTE_HOME:-${HOME:-/root}}"
  if type libscript_resolve_user_home >/dev/null 2>&1 && [ -n "$_wsr_user" ]; then
    _wsr_home=$(libscript_resolve_user_home "$_wsr_user")
  elif [ -n "$_wsr_user" ] && [ -d "/home/${_wsr_user}" ]; then
    _wsr_home="/home/${_wsr_user}"
  fi

  _wsr_path="$PATH"
  for _wsr_local_bin in "${_wsr_wd}/.venv/bin" "${_wsr_wd}/node_modules/.bin" "${_wsr_manifest_dir}/.venv/bin" "${_wsr_manifest_dir}/node_modules/.bin"; do
    if [ -d "$_wsr_local_bin" ]; then
      case ":${_wsr_path}:" in
        *":${_wsr_local_bin}:"*) ;;
        *) _wsr_path="${_wsr_local_bin}:${_wsr_path}" ;;
      esac
    fi
  done

  _wsr_runner="${_wsr_data}/run_${_wsr_name}.sh"
  {
    printf '#!/bin/sh\n'
    printf 'export HOME="%s"\n' "$_wsr_home"
    printf 'export UV_PYTHON_INSTALL_DIR="%s/.local/share/uv/python"\n' "$_wsr_home"
    printf 'export UV_CACHE_DIR="%s/.cache/uv"\n' "$_wsr_home"
    printf 'export PATH="%s"\n' "$_wsr_path"
    printf 'export REMOTE_USER="%s" REMOTE_GROUP="%s" REMOTE_HOME="%s" REMOTE_APP_DIR="%s"\n' "${REMOTE_USER:-$_wsr_user}" "${REMOTE_GROUP:-$_wsr_user}" "${REMOTE_HOME:-$_wsr_home}" "${REMOTE_APP_DIR:-$_wsr_manifest_dir}"
    printf 'if [ -f "%s/env.sh" ]; then SCRIPT_NAME="%s/env.sh"; export SCRIPT_NAME; . "$SCRIPT_NAME" >/dev/null 2>&1 || true; unset SCRIPT_NAME || true; fi\n' "$LIBSCRIPT_ROOT_DIR" "$LIBSCRIPT_ROOT_DIR"
    printf 'if [ -f "/etc/libscript/%s/service.env" ]; then set -a; . "/etc/libscript/%s/service.env" 2>/dev/null || true; set +a; fi\n' "$_wsr_name" "$_wsr_name"
    printf 'if [ -f "%s/service.env" ]; then set -a; . "%s/service.env" 2>/dev/null || true; set +a; fi\n' "$_wsr_data" "$_wsr_data"
    if [ -f "${_wsr_manifest_dir}/.env.libscript" ]; then
      printf 'if [ -f "%s/.env.libscript" ]; then set -a; . "%s/.env.libscript" 2>/dev/null || true; set +a; fi\n' "$_wsr_manifest_dir" "$_wsr_manifest_dir"
    fi
    printf 'if [ -n "${SERVICE_PATH:-}" ]; then export PATH="${SERVICE_PATH}:${PATH}"; fi\n'
    printf 'if [ -n "${SERVICE_EXTRA_PATH:-}" ]; then export PATH="${SERVICE_EXTRA_PATH}:${PATH}"; fi\n'
    if [ -n "$_wsr_env_files" ]; then
      printf '%s\n' "$_wsr_env_files" | while IFS= read -r _ef_item; do
        [ -n "$_ef_item" ] || continue
        printf 'if [ -f "%s" ]; then set -a; . "%s" 2>/dev/null || true; set +a; fi\n' "$_ef_item" "$_ef_item"
      done
    fi
    if [ -n "$_wsr_env" ]; then
      printf '%s\n' "$_wsr_env" | while IFS= read -r _kv_item; do
        [ -n "$_kv_item" ] || continue
        case "$_kv_item" in
          export\ *) printf '%s\n' "$_kv_item" ;;
          *=*)
            _k_part="${_kv_item%%=*}"
            _v_part="${_kv_item#*=}"
            case "$_k_part" in
              PATH)
                case "$_v_part" in
                  *:*) _v_part="${_v_part}:${PATH}" ;;
                esac
                ;;
            esac
            _v_esc=$(printf '%s' "$_v_part" | sed "s/'/'\\\\''/g")
            printf "export %s='%s'\n" "$_k_part" "$_v_esc"
            ;;
        esac
      done
    fi
    for _wsr_re_bin in "${_wsr_manifest_dir}/node_modules/.bin" "${_wsr_manifest_dir}/.venv/bin" "${_wsr_wd}/node_modules/.bin" "${_wsr_wd}/.venv/bin"; do
      if [ -d "$_wsr_re_bin" ]; then
        printf 'case ":${PATH}:" in *":%s:"*) ;; *) export PATH="%s:${PATH}" ;; esac\n' "$_wsr_re_bin" "$_wsr_re_bin"
      fi
    done
    printf 'cd "%s" || exit 1\n' "$_wsr_wd"
    case "$_wsr_exec" in
      *";"*|*"&&"*|*"||"*|*"|"*|"set "*|"for "*|"if "*)
        printf '%s\n' "$_wsr_exec"
        ;;
      *)
        printf 'exec %s\n' "$_wsr_exec"
        ;;
    esac
  } > "$_wsr_runner"
  chmod 0755 "$_wsr_data" "$_wsr_runner" 2>/dev/null || true
  if [ -n "$_wsr_user" ] && id "$_wsr_user" >/dev/null 2>&1; then
    chown "${_wsr_user}:${_wsr_user}" "$_wsr_data" "$_wsr_runner" 2>/dev/null || priv chown "${_wsr_user}:${_wsr_user}" "$_wsr_data" "$_wsr_runner" 2>/dev/null || true
  fi
  printf '%s\n' "$_wsr_runner"
}

# ## libscript_install_service
# Registers a service across the active init system (systemd, openrc, sysvinit, bsd_rc, launchd,
# smf, runit, s6, sc.exe, or fallback PID runner) and generates a shared runner script.
libscript_install_service() {
  _service_name="$1"
  _exec_start="$2"
  _working_dir="${3:-/}"
  _description="${4:-$_service_name service}"
  _env="${5:-${LIBSCRIPT_SERVICE_ENV:-}}"
  _svc_user="${6:-${LIBSCRIPT_SERVICE_USER:-}}"
  _env_files="${7:-${LIBSCRIPT_SERVICE_ENV_FILES:-}}"
  _manifest_dir="${LIBSCRIPT_SERVICE_MANIFEST_DIR:-$_working_dir}"
  _rc_name=$(printf '%s\n' "$_service_name" | tr '-' '_')

  _svc_home="${REMOTE_HOME:-${HOME:-/root}}"
  if type libscript_resolve_user_home >/dev/null 2>&1 && [ -n "$_svc_user" ]; then
    _svc_home=$(libscript_resolve_user_home "$_svc_user")
  elif [ -n "$_svc_user" ] && [ -d "/home/${_svc_user}" ]; then
    _svc_home="/home/${_svc_user}"
  fi

  if [ -n "$_svc_user" ] && type libscript_python_ensure_venv_owner >/dev/null 2>&1; then
    libscript_python_ensure_venv_owner "$_working_dir" "${PYTHON_VERSION:-3.12}" "$_svc_user" "$_svc_home"
  fi

  _runner_script=$(libscript_write_service_runner "$_service_name" "$_exec_start" "$_working_dir" "$_env" "$_svc_user" "$_env_files")
  _init_sys=$(libscript_detect_init_system)
  _svc_data="${LIBSCRIPT_DATA_DIR:-/tmp/data}/${_service_name}"

  case "$_init_sys" in
    systemd)
      log_info "Installing systemd service: $_service_name"
      _tmp_file=$(mktemp)
      _user_directive=""
      if [ -n "$_svc_user" ] && id "$_svc_user" >/dev/null 2>&1; then
        _user_directive="User=${_svc_user}"
      fi
      if [ "$(id -u 2>/dev/null || printf '1000')" -eq 0 ] || sudo -n true 2>/dev/null || [ "${LIBSCRIPT_MOCK_SYSTEMD:-0}" = "1" ]; then
        cat << SYSTEMD > "$_tmp_file"
[Unit]
Description=${_description}
After=network.target

[Service]
WorkingDirectory=${_working_dir}
${_user_directive}
Environment="HOME=${_svc_home}"
Environment="UV_PYTHON_INSTALL_DIR=${_svc_home}/.local/share/uv/python"
Environment="UV_CACHE_DIR=${_svc_home}/.cache/uv"
Environment="PATH=${PATH}"
Environment="REMOTE_USER=${REMOTE_USER:-$_svc_user}"
Environment="REMOTE_GROUP=${REMOTE_GROUP:-$_svc_user}"
Environment="REMOTE_HOME=${REMOTE_HOME:-$_svc_home}"
Environment="REMOTE_APP_DIR=${REMOTE_APP_DIR:-$_manifest_dir}"
ExecStart=/bin/sh "${_runner_script}"
StandardOutput=journal
StandardError=journal
Restart=always
RestartSec=2
SYSTEMD
        if [ -f "${_manifest_dir}/.env.libscript" ]; then
          printf 'EnvironmentFile=-%s/.env.libscript\n' "$_manifest_dir" >> "$_tmp_file"
        fi
        if [ -n "$_env_files" ]; then
          printf '%s\n' "$_env_files" | while IFS= read -r _ef; do
            if [ -n "$_ef" ] && [ -f "$_ef" ]; then
              printf 'EnvironmentFile=-%s\n' "$_ef" >> "$_tmp_file"
            fi
          done
        fi
        if [ -n "$_env" ]; then
          printf '%s\n' "$_env" | while IFS= read -r _e_line; do
            [ -n "$_e_line" ] || continue
            _e_clean="${_e_line#export }"
            case "$_e_clean" in
              PATH=*:*) _e_clean="${_e_clean}:${PATH}" ;;
            esac
            printf 'Environment="%s"\n' "$_e_clean" >> "$_tmp_file"
          done
        fi
        cat << 'SYSTEMD_INST' >> "$_tmp_file"

[Install]
WantedBy=multi-user.target
SYSTEMD_INST
        if [ "${FORCE_REINSTALL:-0}" != "1" ] && [ "${FORCE_REBUILD:-0}" != "1" ] && [ -f "/etc/systemd/system/${_service_name}.service" ] && cmp -s "$_tmp_file" "/etc/systemd/system/${_service_name}.service" 2>/dev/null; then
          log_info "[DAEMON] [CONFIRM] systemd unit for '${_service_name}' (/etc/systemd/system/${_service_name}.service) is up-to-date."
          export LIBSCRIPT_SERVICE_UNIT_UNCHANGED=1
        elif [ -f "/etc/systemd/system/${_service_name}.service" ]; then
          priv install -m 0644 -o 'root' -- "$_tmp_file" "/etc/systemd/system/${_service_name}.service"
          priv systemctl daemon-reload
          priv systemctl enable "$_service_name"
          log_info "[DAEMON] [UPDATE] Updated systemd unit for '${_service_name}' (/etc/systemd/system/${_service_name}.service), ran daemon-reload, and marked for restart."
          export LIBSCRIPT_SERVICE_UNIT_UNCHANGED=0
        else
          priv install -m 0644 -o 'root' -- "$_tmp_file" "/etc/systemd/system/${_service_name}.service"
          priv systemctl daemon-reload
          priv systemctl enable "$_service_name"
          log_info "[DAEMON] [CREATE] Installed systemd unit for '${_service_name}' (/etc/systemd/system/${_service_name}.service) and reloaded daemon manager."
          export LIBSCRIPT_SERVICE_UNIT_UNCHANGED=0
        fi
        rm -f "$_tmp_file"
      elif systemctl --user status >/dev/null 2>&1; then
        _user_unit_dir="${HOME:-/tmp}/.config/systemd/user"
        mkdir -p "$_user_unit_dir"
        cat << SYSTEMD_USR > "${_user_unit_dir}/${_service_name}.service"
[Unit]
Description=${_description}
After=network.target

[Service]
WorkingDirectory=${_working_dir}
Environment="HOME=${_svc_home}"
Environment="PATH=${PATH}"
Environment="REMOTE_USER=${REMOTE_USER:-$_svc_user}"
Environment="REMOTE_GROUP=${REMOTE_GROUP:-$_svc_user}"
Environment="REMOTE_HOME=${REMOTE_HOME:-$_svc_home}"
Environment="REMOTE_APP_DIR=${REMOTE_APP_DIR:-$_manifest_dir}"
ExecStart=/bin/sh "${_runner_script}"
StandardOutput=append:${_svc_data}/stdout.log
StandardError=append:${_svc_data}/stderr.log
Restart=always
RestartSec=2

[Install]
WantedBy=default.target
SYSTEMD_USR
        rm -f "$_tmp_file"
        systemctl --user daemon-reload
        systemctl --user enable "$_service_name"
      else
        rm -f "$_tmp_file"
        log_info "Systemd requires root or active user bus; registered fallback runner for $_service_name"
      fi
      ;;
    openrc)
      log_info "Installing OpenRC service: $_service_name"
      _tmp_file=$(mktemp)
      _openrc_user_line=""
      if [ -n "$_svc_user" ] && id "$_svc_user" >/dev/null 2>&1; then
        _openrc_user_line="command_user=\"${_svc_user}\""
      fi
      cat > "$_tmp_file" <<EOF_OPENRC
#!/sbin/openrc-run
# $_description

name="$_service_name"
description="$_description"
command="/bin/sh"
command_args="${_runner_script}"
${_openrc_user_line}
command_background="yes"
pidfile="/run/$_service_name.pid"
directory="$_working_dir"
output_log="/var/log/${_service_name}.log"
error_log="/var/log/${_service_name}_err.log"

# ## start_pre
# Hydrates .env.libscript and SERVICE_PATH prior to starting the OpenRC daemon.
start_pre() {
    if [ -f "${_manifest_dir}/.env.libscript" ]; then
        set -a
        . "${_manifest_dir}/.env.libscript" 2>/dev/null || true
        set +a
    fi
    export PATH="\${SERVICE_PATH:-${PATH}}"
}

# ## depend
# Declares OpenRC network dependency for the service.
depend() {
    need net
}
EOF_OPENRC
      priv install -m 0755 -o 'root' -- "$_tmp_file" "/etc/init.d/$_service_name"
      priv rc-update add "$_service_name" default
      rm -f "$_tmp_file"
      ;;
    smf)
      log_info "Installing SMF manifest: $_service_name"
      _tmp_file=$(mktemp)
      _xml_exec=$(printf '/bin/sh %s' "$_runner_script" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
      _xml_path=$(printf '%s' "${SERVICE_PATH:-$PATH}" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
      cat > "$_tmp_file" <<EOF_SMF
<?xml version="1.0"?>
<!DOCTYPE service_bundle SYSTEM "/usr/share/lib/xml/dtd/service_bundle.dtd.1">
<service_bundle type='manifest' name='libscript:$_service_name'>
  <service name='application/libscript/$_service_name' type='service' version='1'>
    <create_default_instance enabled='true' />
    <single_instance />
    <exec_method type='method' name='start' exec='$_xml_exec' timeout_seconds='60'>
      <method_context working_directory='$_working_dir'>
        <method_environment>
          <envvar name='PATH' value='$_xml_path' />
          <envvar name='SERVICE_PATH' value='$_xml_path' />
          <envvar name='HOME' value='$_svc_home' />
        </method_environment>
      </method_context>
    </exec_method>
    <exec_method type='method' name='stop' exec=':kill' timeout_seconds='60' />
    <property_group name='startd' type='framework'>
      <propval name='duration' type='astring' value='child' />
    </property_group>
  </service>
</service_bundle>
EOF_SMF
      priv svccfg import "$_tmp_file"
      priv svcadm enable -s "application/libscript/$_service_name"
      rm -f "$_tmp_file"
      ;;
    bsd_rc)
      log_info "Installing FreeBSD/BSD rc.d service: $_service_name"
      _tmp_file=$(mktemp)
      _bsd_user_arg=""
      if [ -n "$_svc_user" ] && id "$_svc_user" >/dev/null 2>&1; then
        _bsd_user_arg="-u ${_svc_user} "
      fi
      cat > "$_tmp_file" <<EOF_BSD
#!/bin/sh
#
# PROVIDE: $_rc_name
# REQUIRE: networking
# KEYWORD: shutdown

. /etc/rc.subr

name="$_rc_name"
rcvar="\${name}_enable"
pidfile="/var/run/\${name}.pid"
if [ -f "${_manifest_dir}/.env.libscript" ]; then
  set -a
  . "${_manifest_dir}/.env.libscript" 2>/dev/null || true
  set +a
fi
export PATH="\${SERVICE_PATH:-${PATH}}"
export HOME="${_svc_home}"
command="/usr/sbin/daemon"
command_args="-P \${pidfile} -r -f ${_bsd_user_arg}-o /var/log/\${name}.log /bin/sh ${_runner_script}"

load_rc_config \$name
: \${${_rc_name}_enable:="NO"}

run_rc_command "\$1"
EOF_BSD
      priv install -m 0755 -o 'root' -- "$_tmp_file" "/usr/local/etc/rc.d/$_rc_name"
      if command -v sysrc >/dev/null 2>&1; then
        priv sysrc "${_rc_name}_enable=YES" || true
      fi
      rm -f "$_tmp_file"
      ;;
    launchd)
      log_info "Installing macOS launchd service: $_service_name"
      _plist_dir="${HOME:-/tmp}/Library/LaunchAgents"
      mkdir -p "$_plist_dir"
      _plist_file="${_plist_dir}/com.libscript.${_service_name}.plist"
      cat << PLIST > "$_plist_file"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.libscript.${_service_name}</string>
    <key>WorkingDirectory</key>
    <string>${_working_dir}</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>${SERVICE_PATH:-$PATH}</string>
        <key>SERVICE_PATH</key>
        <string>${SERVICE_PATH:-$PATH}</string>
        <key>HOME</key>
        <string>${_svc_home}</string>
PLIST
      if [ -f "${_manifest_dir}/.env.libscript" ]; then
        while IFS= read -r _pl_line; do
          case "$_pl_line" in
            ""|"#"*) continue ;;
            *=*)
              _pl_k="${_pl_line%%=*}"
              _pl_v="${_pl_line#*=}"
              case "$_pl_k" in
                PATH|SERVICE_PATH|HOME) continue ;;
              esac
              _pl_v_esc=$(printf '%s' "$_pl_v" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
              printf '        <key>%s</key>\n        <string>%s</string>\n' "$_pl_k" "$_pl_v_esc" >> "$_plist_file"
              ;;
          esac
        done < "${_manifest_dir}/.env.libscript"
      fi
      cat << PLIST_END >> "$_plist_file"
    </dict>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/sh</string>
        <string>${_runner_script}</string>
    </array>
    <key>StandardOutPath</key>
    <string>${_svc_data}/stdout.log</string>
    <key>StandardErrorPath</key>
    <string>${_svc_data}/stderr.log</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
PLIST_END
      launchctl load -w "$_plist_file" 2>/dev/null || true
      ;;
    runit)
      log_info "Installing runit service: $_service_name"
      priv mkdir -p "/etc/service/${_service_name}"
      _tmp_file=$(mktemp)
      cat > "$_tmp_file" <<EOF_RUNIT
#!/bin/sh
export HOME="${_svc_home}"
export PATH="${PATH}"
if [ -f "${_manifest_dir}/.env.libscript" ]; then set -a; . "${_manifest_dir}/.env.libscript" 2>/dev/null || true; set +a; fi
export PATH="\${SERVICE_PATH:-${PATH}}"
exec /bin/sh "${_runner_script}" 2>&1
EOF_RUNIT
      priv install -m 0755 -o 'root' -- "$_tmp_file" "/etc/service/${_service_name}/run"
      rm -f "$_tmp_file"
      ;;
    s6)
      log_info "Installing s6 service: $_service_name"
      _s6_base='/run/service'
      [ -d /etc/s6/sv ] && _s6_base="/etc/s6/sv"
      priv mkdir -p "${_s6_base}/${_service_name}"
      _tmp_file=$(mktemp)
      cat > "$_tmp_file" <<EOF_S6
#!/bin/sh
export HOME="${_svc_home}"
export PATH="${PATH}"
if [ -f "${_manifest_dir}/.env.libscript" ]; then set -a; . "${_manifest_dir}/.env.libscript" 2>/dev/null || true; set +a; fi
export PATH="\${SERVICE_PATH:-${PATH}}"
exec /bin/sh "${_runner_script}" 2>&1
EOF_S6
      priv install -m 0755 -o 'root' -- "$_tmp_file" "${_s6_base}/${_service_name}/run"
      rm -f "$_tmp_file"
      ;;
    sysvinit)
      log_info "Installing SysVinit service: $_service_name"
      _tmp_file=$(mktemp)
      cat > "$_tmp_file" <<EOF_SYSV
#!/bin/sh
### BEGIN INIT INFO
# Provides:          ${_service_name}
# Required-Start:    \$remote_fs \$syslog \$network
# Required-Stop:     \$remote_fs \$syslog \$network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: ${_description}
### END INIT INFO

export HOME="${_svc_home}"
export PATH="${PATH}"
[ -f "/etc/default/${_service_name}" ] && . "/etc/default/${_service_name}"
[ -f "${_manifest_dir}/.env.libscript" ] && { set -a; . "${_manifest_dir}/.env.libscript" 2>/dev/null || true; set +a; }
export PATH="\${SERVICE_PATH:-${PATH}}"
PIDFILE="/var/run/${_service_name}.pid"
LOGFILE="/var/log/${_service_name}.log"

case "\$1" in
  start)
    if [ -f "\$PIDFILE" ] && kill -0 "\$(cat "\$PIDFILE")" 2>/dev/null; then
      exit 0
    fi
    nohup /bin/sh "${_runner_script}" >> "\$LOGFILE" 2>&1 &
    printf '%s\n' "\$!" > "\$PIDFILE"
    ;;
  stop)
    if [ -f "\$PIDFILE" ]; then
      kill "\$(cat "\$PIDFILE")" 2>/dev/null || true
      rm -f "\$PIDFILE"
    fi
    ;;
  restart|reload)
    "\$0" stop
    sleep 1
    "\$0" start
    ;;
  status)
    [ -f "\$PIDFILE" ] && kill -0 "\$(cat "\$PIDFILE")" 2>/dev/null
    ;;
  *)
    printf 'Usage: %s {start|stop|restart|reload|status}\n' "\$0" >&2
    exit 1
    ;;
esac
EOF_SYSV
      priv install -m 0755 -o 'root' -- "$_tmp_file" "/etc/init.d/${_service_name}"
      if command -v update-rc.d >/dev/null 2>&1; then
        priv update-rc.d "${_service_name}" defaults 2>/dev/null || true
      elif command -v chkconfig >/dev/null 2>&1; then
        priv chkconfig "${_service_name}" on 2>/dev/null || true
      fi
      rm -f "$_tmp_file"
      ;;
    sc)
      log_info "Installing Windows service: $_service_name"
      if sc.exe query "$_service_name" >/dev/null 2>&1; then
        sc.exe config "$_service_name" binPath= "$_exec_start" start= auto obj= LocalSystem
      else
        sc.exe create "$_service_name" binPath= "$_exec_start" start= auto obj= LocalSystem
      fi
      sc.exe description "$_service_name" "$_description"
      ;;
    *)
      log_info "Registered fallback daemon runner for service: $_service_name (${_runner_script})"
      ;;
  esac
}

# ## libscript_service_override_env
# Configures persistent environment variable overrides for a service across init systems.
libscript_service_override_env() {
  _ovr_service="${1:-}"
  shift || true
  if [ -z "$_ovr_service" ] || [ $# -eq 0 ]; then
    log_error 'Usage: libscript_service_override_env <service_name> <KEY=VALUE...>'
    return 1
  fi
  _ovr_rc_name=$(printf '%s\n' "$_ovr_service" | tr '-' '_')

  # 1. Generic / fallback env file (idempotently merged so runner scripts and fallback daemons keep existing keys)
  _ovr_fb_dir="${LIBSCRIPT_DATA_DIR:-/tmp/data}/${_ovr_service}"
  mkdir -p "$_ovr_fb_dir" 2>/dev/null || true
  if [ -w "$_ovr_fb_dir" ]; then
    touch "${_ovr_fb_dir}/service.env"
    for _kv in "$@"; do
      _k="${_kv%%=*}"
      grep -v "^export ${_k}=" "${_ovr_fb_dir}/service.env" > "${_ovr_fb_dir}/service.env.tmp" 2>/dev/null || true
      mv "${_ovr_fb_dir}/service.env.tmp" "${_ovr_fb_dir}/service.env"
      printf 'export %s\n' "$_kv" >> "${_ovr_fb_dir}/service.env"
    done
  fi
  if [ "$(id -u 2>/dev/null || printf '1000')" -eq 0 ] || sudo -n true 2>/dev/null; then
    priv mkdir -p "/etc/libscript/${_ovr_service}" 2>/dev/null || true
    _tmp_gen=$(mktemp)
    if [ -f "/etc/libscript/${_ovr_service}/service.env" ]; then
      cat "/etc/libscript/${_ovr_service}/service.env" > "$_tmp_gen" || true
    fi
    for _kv in "$@"; do
      _k="${_kv%%=*}"
      grep -v "^export ${_k}=" "$_tmp_gen" > "${_tmp_gen}.new" 2>/dev/null || true
      mv "${_tmp_gen}.new" "$_tmp_gen"
      printf 'export %s\n' "$_kv" >> "$_tmp_gen"
    done
    priv install -m 0644 -- "$_tmp_gen" "/etc/libscript/${_ovr_service}/service.env" 2>/dev/null || true
    rm -f "$_tmp_gen"
  fi

  _init_sys=$(libscript_detect_init_system)

  # 2. Systemd drop-in override (idempotently merged)
  if [ "$_init_sys" = "systemd" ]; then
    _ovr_dir="/etc/systemd/system/${_ovr_service}.service.d"
    priv mkdir -p "$_ovr_dir"
    _tmp_ovr=$(mktemp)
    if [ -f "${_ovr_dir}/override.conf" ]; then
      cat "${_ovr_dir}/override.conf" > "$_tmp_ovr"
    else
      printf '[Service]\n' > "$_tmp_ovr"
    fi
    for _kv in "$@"; do
      _k="${_kv%%=*}"
      grep -v "^Environment=\"${_k}=" "$_tmp_ovr" > "${_tmp_ovr}.new" 2>/dev/null || true
      mv "${_tmp_ovr}.new" "$_tmp_ovr"
      printf 'Environment="%s"\n' "$_kv" >> "$_tmp_ovr"
    done
    priv install -m 0644 -- "$_tmp_ovr" "${_ovr_dir}/override.conf"
    rm -f "$_tmp_ovr"
    priv systemctl daemon-reload 2>/dev/null || true
    log_info "[DAEMON] [OVERRIDE] Configured environment overrides for '${_ovr_service}' ($*) in ${_ovr_dir}/override.conf and reloaded init daemon."
    return 0
  fi

  # 3. OpenRC /etc/conf.d/<service>
  if [ "$_init_sys" = "openrc" ]; then
    priv mkdir -p /etc/conf.d
    _tmp_ovr=$(mktemp)
    if [ -f "/etc/conf.d/${_ovr_service}" ]; then
      cat "/etc/conf.d/${_ovr_service}" > "$_tmp_ovr" || true
    fi
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
  if [ "$_init_sys" = "bsd_rc" ]; then
    priv mkdir -p /etc/rc.conf.d
    _tmp_ovr=$(mktemp)
    if [ -f "/etc/rc.conf.d/${_ovr_rc_name}" ]; then
      cat "/etc/rc.conf.d/${_ovr_rc_name}" > "$_tmp_ovr" || true
    fi
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
  if [ "$_init_sys" = "launchd" ] || { [ "${UNAME_LOWER:-}" = "darwin" ] && command -v launchctl >/dev/null 2>&1; }; then
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
    if command -v sysrc >/dev/null 2>&1; then
      priv sysrc "${_rc_name}_enable=NO" 2>/dev/null || true
    fi
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
  elif [ -d "/etc/service/${_service_name}" ]; then
    log_info "Uninstalling runit service: $_service_name"
    if command -v sv >/dev/null 2>&1; then
      priv sv down "$_service_name" 2>/dev/null || true
    fi
    priv rm -rf "/etc/service/${_service_name}"
  elif [ -d "/run/service/${_service_name}" ] || [ -d "/etc/s6/sv/${_service_name}" ]; then
    log_info "Uninstalling s6 service: $_service_name"
    if command -v s6-svc >/dev/null 2>&1; then
      priv s6-svc -d "/run/service/${_service_name}" 2>/dev/null || true
    fi
    priv rm -rf "/run/service/${_service_name}" "/etc/s6/sv/${_service_name}"
  elif [ -x "/etc/init.d/${_service_name}" ]; then
    log_info "Uninstalling SysVinit service: $_service_name"
    priv service "$_service_name" stop 2>/dev/null || true
    if command -v update-rc.d >/dev/null 2>&1; then
      priv update-rc.d -f "$_service_name" remove 2>/dev/null || true
    fi
    if command -v chkconfig >/dev/null 2>&1; then
      priv chkconfig "$_service_name" off 2>/dev/null || true
    fi
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

STACK="${STACK%"${THIS_FILE}":}"
export STACK
[ -n "${_si_outer_dir:-}" ] && SCRIPT_DIR="$_si_outer_dir"
[ -n "${_si_outer_this:-}" ] && THIS_FILE="$_si_outer_this"
unset _si_outer_this _si_outer_dir || true
