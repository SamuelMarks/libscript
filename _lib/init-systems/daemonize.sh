#!/bin/sh
# ## Overview
# Cross-platform daemonization wrapper supporting object-map and array service schemas,
# per-service working directories, environment variables, multi-init lifecycle, and PID fallback.
#
# ## Usage
# Run `daemonize.sh <action> <json_file> [--remove] [--verify-ingress] [--public-url=<url>]`
# where action is `start`, `stop`, `up`, `down`, `status`, `health`, `logs`, or `uninstall`.

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

LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(cd "${SCRIPT_DIR}/../../.." && pwd)}"
for _dm_lib in "_lib/_common/log.sh" "_lib/_common/python_env.sh" "_lib/_common/service.sh" "_lib/_common/service_install.sh"; do
  if [ -f "${LIBSCRIPT_ROOT_DIR}/${_dm_lib}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_dm_lib}"
    export SCRIPT_NAME
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
done
unset SCRIPT_NAME || true

ACTION=""
JSON_FILE=""
REMOVE_UNITS=0
VERIFY_INGRESS=0
PUBLIC_URL="${LIBSCRIPT_PUBLIC_URL:-}"

while [ $# -gt 0 ]; do
  case "$1" in
    --remove|--uninstall)
      REMOVE_UNITS=1
      shift
      ;;
    --verify-ingress)
      VERIFY_INGRESS=1
      shift
      ;;
    --public-url=*)
      PUBLIC_URL="${1#*=}"
      VERIFY_INGRESS=1
      shift
      ;;
    --public-url)
      shift
      PUBLIC_URL="${1:-}"
      VERIFY_INGRESS=1
      [ $# -gt 0 ] && shift || true
      ;;
    --remediate)
      shift
      ;;
    *)
      if [ -z "$ACTION" ]; then
        ACTION="$1"
      elif [ -z "$JSON_FILE" ]; then
        JSON_FILE="$1"
      fi
      shift
      ;;
  esac
done

case "$ACTION" in
  remove|uninstall-service) ACTION="uninstall" ;;
  stop|down)
    if [ "$REMOVE_UNITS" -eq 1 ]; then
      ACTION="uninstall"
    fi
    ;;
esac

if [ -z "$ACTION" ] || [ -z "$JSON_FILE" ] || [ ! -f "$JSON_FILE" ]; then
  exit 0
fi

MANIFEST_DIR=$(cd -- "$(dirname -- "$JSON_FILE")" && pwd)
DATA_BASE="${LIBSCRIPT_DATA_DIR:-/tmp/data}"

if [ -f "$LIBSCRIPT_ROOT_DIR/_lib/_common/env_printer.sh" ]; then
  SCRIPT_NAME="$LIBSCRIPT_ROOT_DIR/_lib/_common/env_printer.sh"
  # shellcheck disable=SC1090
  . "$SCRIPT_NAME"
  unset SCRIPT_NAME || true
  libscript_hydrate_manifest_env "$JSON_FILE" || true
else
  for _dm_ef in "${MANIFEST_DIR}/.env" "${MANIFEST_DIR}/.env.secrets" "${MANIFEST_DIR}/.env.libscript"; do
    if [ -f "$_dm_ef" ]; then
      set -a
      set +u
      # shellcheck disable=SC1090,SC1091
      . "$_dm_ef" 2>/dev/null || true
      set -u
      set +a
    fi
  done
fi

if [ -z "${UV_BIN:-}" ] || { [ "${UV_BIN#/}" != "${UV_BIN:-}" ] && [ ! -x "${UV_BIN}" ]; }; then
  if command -v uv >/dev/null 2>&1; then
    UV_BIN=$(command -v uv)
    export UV_BIN
  elif [ -n "${REMOTE_HOME:-}" ] && [ -x "${REMOTE_HOME}/.local/bin/uv" ]; then
    export UV_BIN="${REMOTE_HOME}/.local/bin/uv"
  else
    export UV_BIN="uv"
  fi
fi
if [ -z "${NPX_BIN:-}" ] || { [ "${NPX_BIN#/}" != "${NPX_BIN:-}" ] && [ ! -x "${NPX_BIN}" ]; }; then
  if command -v npx >/dev/null 2>&1; then
    NPX_BIN=$(command -v npx)
    export NPX_BIN
  else
    export NPX_BIN="npx"
  fi
fi

# ## expand_manifest_vars
# Expands ${VAR:-default}, ${VAR}, and $VAR environment references inside a manifest string value.
expand_manifest_vars() {
  if type libscript_expand_manifest_vars >/dev/null 2>&1; then
    libscript_expand_manifest_vars "${1:-}"
  else
    printf '%s\n' "${1:-}"
  fi
}

# Respect manifest-level init_system or capabilities if LIBSCRIPT_INIT_SYSTEM is not already overridden
if [ -z "${LIBSCRIPT_INIT_SYSTEM:-}" ] && [ -z "${INIT_SYSTEM:-}" ]; then
  _mf_init=$(jq -r '.init_system // (.infrastructure.node.capabilities // [] | map(select(. == "systemd" or . == "openrc" or . == "sysvinit" or . == "bsd_rc" or . == "launchd" or . == "smf" or . == "runit" or . == "s6" or . == "fallback" or . == "none")) | .[0]) // empty' "$JSON_FILE" 2>/dev/null || true)
  _mf_init=$(expand_manifest_vars "$_mf_init")
  if [ -n "$_mf_init" ] && [ "$_mf_init" != "null" ] && [ "$_mf_init" != "auto" ]; then
    if [ "$_mf_init" != "systemd" ] || [ -d /run/systemd/system ]; then
      LIBSCRIPT_INIT_SYSTEM="$_mf_init"
      export LIBSCRIPT_INIT_SYSTEM
    fi
  fi
fi

# ## evaluate_json_expr
# Evaluates a jq boolean expression against a JSON string.
evaluate_json_expr() {
  _eje_payload="$1"
  _eje_expr="$2"
  if command -v jq >/dev/null 2>&1; then
    printf '%s\n' "$_eje_payload" | jq -e "$_eje_expr" >/dev/null 2>&1
    return $?
  fi
  return 1
}

LEGACY_SERVICES=$(jq -r '((.legacy_service_names // []) + (.infrastructure.legacy_service_names // [])) | unique | .[]?' "$JSON_FILE" 2>/dev/null || true)

# ## cleanup_legacy_services
# Stops and uninstalls any legacy service names declared in the manifest.
cleanup_legacy_services() {
  if [ -n "$LEGACY_SERVICES" ]; then
    while IFS= read -r _leg_svc; do
      [ -n "$_leg_svc" ] || continue
      libscript_uninstall_service "$_leg_svc" >/dev/null 2>&1 || true
    done << EOF_LEGACY
$LEGACY_SERVICES
EOF_LEGACY
  fi
}

if [ "$ACTION" = "start" ] || [ "$ACTION" = "up" ] || [ "$ACTION" = "uninstall" ]; then
  cleanup_legacy_services
fi

SERVICES=$(jq -c '((.services // .infrastructure.services) | if type == "object" then to_entries | map(.value + {name: (.value.name // .key)}) elif type == "array" then map(. + {name: (.name // .id)}) else [] end)[]?' "$JSON_FILE" 2>/dev/null || true)
if [ -z "$SERVICES" ]; then
  exit 0
fi

OS_NAME=$(uname -s | tr '[:upper:]' '[:lower:]')

# ## resolve_workdir
# Resolves a relative or absolute service working directory against the manifest directory.
resolve_workdir() {
  _raw_wd="$1"
  if [ -z "$_raw_wd" ] || [ "$_raw_wd" = "." ]; then
    printf '%s\n' "$MANIFEST_DIR"
  elif [ "${_raw_wd#/}" != "$_raw_wd" ]; then
    printf '%s\n' "$_raw_wd"
  else
    printf '%s\n' "${MANIFEST_DIR}/${_raw_wd}"
  fi
}

# ## resolve_env_file
# Resolves a relative or absolute env_file path against the service working directory or manifest directory and normalizes '../' segments.
resolve_env_file() {
  _ef="$1"
  _wd="$2"
  _ef_cand=""
  if [ "${_ef#/}" != "$_ef" ]; then
    _ef_cand="$_ef"
  elif [ -f "${_wd}/${_ef}" ]; then
    _ef_cand="${_wd}/${_ef}"
  else
    _ef_cand="${MANIFEST_DIR}/${_ef}"
  fi
  _ef_dir=$(dirname -- "$_ef_cand")
  _ef_base=$(basename -- "$_ef_cand")
  if [ -d "$_ef_dir" ]; then
    _ef_dir=$(cd -- "$_ef_dir" && pwd)
    printf '%s/%s\n' "$_ef_dir" "$_ef_base"
  else
    printf '%s\n' "$_ef_cand"
  fi
}

# ## collect_service_env_files
# Collects and resolves all env_files declared on a service entry into a newline-separated list.
collect_service_env_files() {
  _env_file_json="$1"
  _env_file_wd="$2"
  _env_file_raw=$(printf '%s\n' "$_env_file_json" | jq -r '.env_files[]?' 2>/dev/null || true)
  if [ -n "$_env_file_raw" ]; then
    printf '%s\n' "$_env_file_raw" | while IFS= read -r _ef_item; do
      [ -n "$_ef_item" ] || continue
      resolve_env_file "$_ef_item" "$_env_file_wd"
    done
  fi
}

# ## collect_service_env_vars
# Collects and expands all env key=value pairs declared on a service entry into a newline-separated list.
collect_service_env_vars() {
  _env_var_json="$1"
  _env_var_raw=$(printf '%s\n' "$_env_var_json" | jq -r '(.env // .environment // {}) | to_entries[]? | "\(.key)=\(.value)"' 2>/dev/null || true)
  if [ -n "$_env_var_raw" ]; then
    printf '%s\n' "$_env_var_raw" | while IFS= read -r _kv_item; do
      [ -n "$_kv_item" ] || continue
      expand_manifest_vars "$_kv_item"
    done
  fi
}

# ## run_service_health_cmd
# Executes a custom health check command within the service working directory and isolated environment.
run_service_health_cmd() {
  _hc_cmd="$1"
  _hc_wd="$2"
  _hc_svc_json="$3"
  (
    if [ -f "${LIBSCRIPT_ROOT_DIR}/env.sh" ]; then
      # shellcheck disable=SC1091
      . "${LIBSCRIPT_ROOT_DIR}/env.sh" >/dev/null 2>&1 || true
    fi
    if [ -f "${MANIFEST_DIR}/.env.libscript" ]; then
      set -a
      # shellcheck disable=SC1091
      . "${MANIFEST_DIR}/.env.libscript" 2>/dev/null || true
      set +a
    fi
    _hc_ef_list=$(collect_service_env_files "$_hc_svc_json" "$_hc_wd")
    if [ -n "$_hc_ef_list" ]; then
      while IFS= read -r _hc_ef_res; do
        [ -n "$_hc_ef_res" ] && [ -f "$_hc_ef_res" ] || continue
        set -a
        # shellcheck disable=SC1090
        . "$_hc_ef_res" 2>/dev/null || true
        set +a
      done << EOF_HC_ENV_FILE
$_hc_ef_list
EOF_HC_ENV_FILE
    fi
    _hc_env_pairs=$(collect_service_env_vars "$_hc_svc_json")
    if [ -n "$_hc_env_pairs" ]; then
      while IFS= read -r _hc_kv_exp; do
        [ -n "$_hc_kv_exp" ] || continue
        export "${_hc_kv_exp%%=*}=${_hc_kv_exp#*=}"
      done << EOF_HC_ENV_KV
$_hc_env_pairs
EOF_HC_ENV_KV
    fi
    for _hc_bin in "${_hc_wd}/.venv/bin" "${_hc_wd}/node_modules/.bin" "${MANIFEST_DIR}/.venv/bin" "${MANIFEST_DIR}/node_modules/.bin"; do
      if [ -d "$_hc_bin" ]; then
        case ":${PATH:-}:" in
          *":${_hc_bin}:"*) ;;
          *) export PATH="${_hc_bin}:${PATH:-/usr/bin:/bin}" ;;
        esac
      fi
    done
    cd "$_hc_wd" && sh -c "$_hc_cmd"
  )
}

# ## dump_service_failure_logs
# Prints recent service logs from the active init system or fallback log file when health verification fails.
dump_service_failure_logs() {
  _dsf_name="$1"
  _dsf_data="${DATA_BASE}/${_dsf_name}"
  if [ -f "${_dsf_data}/service.log" ]; then
    log_error "Recent fallback logs for '${_dsf_name}' (${_dsf_data}/service.log):"
    tail -n 25 "${_dsf_data}/service.log" >&2 2>/dev/null || true
  elif [ -f "${_dsf_data}/stdout.log" ]; then
    log_error "Recent logs for '${_dsf_name}' (${_dsf_data}/stdout.log):"
    tail -n 25 "${_dsf_data}/stdout.log" >&2 2>/dev/null || true
  elif [ -f "/var/log/${_dsf_name}.log" ]; then
    log_error "Recent init logs for '${_dsf_name}' (/var/log/${_dsf_name}.log):"
    tail -n 25 "/var/log/${_dsf_name}.log" >&2 2>/dev/null || true
  else
    log_error "Recent service logs for '${_dsf_name}':"
    libscript_service logs "$_dsf_name" -n 25 >&2 2>/dev/null || true
  fi
}

HEALTH_FAILED=0

while IFS= read -r svc <&3; do
  [ -n "$svc" ] || continue
  NAME=$(printf '%s\n' "$svc" | jq -r '.name // empty')
  CMD=$(printf '%s\n' "$svc" | jq -r '.command // empty')
  case "$CMD" in
    *\$\{*) CMD=$(expand_manifest_vars "$CMD") ;;
  esac
  if [ -z "$NAME" ]; then continue; fi

  if [ "$ACTION" = "uninstall" ]; then
    libscript_uninstall_service "$NAME"
    [ -n "$CMD" ] && pkill -f "$CMD" 2>/dev/null || true
    log_info "Uninstalled service '$NAME'."
    continue
  fi

  if [ -z "$CMD" ]; then continue; fi

  RAW_WORKDIR=$(printf '%s\n' "$svc" | jq -r '.working_dir // .working_directory // .cwd // "."')
  RAW_WORKDIR=$(expand_manifest_vars "$RAW_WORKDIR")
  SVC_WORKDIR=$(resolve_workdir "$RAW_WORKDIR")
  SVC_USER=$(printf '%s\n' "$svc" | jq -r '.user // empty')
  SVC_USER=$(expand_manifest_vars "$SVC_USER")
  SVC_DATA="${DATA_BASE}/${NAME}"
  mkdir -p "$SVC_DATA" 2>/dev/null || true

  if [ "$ACTION" = "start" ] || [ "$ACTION" = "up" ]; then
    log_info "Configuring service '$NAME' (workdir: $SVC_WORKDIR)..."
    SVC_ENV_FILES=$(collect_service_env_files "$svc" "$SVC_WORKDIR")
    SVC_ENV_VARS=$(collect_service_env_vars "$svc")
    LIBSCRIPT_SERVICE_MANIFEST_DIR="$MANIFEST_DIR" \
    LIBSCRIPT_SERVICE_USER="$SVC_USER" \
    LIBSCRIPT_SERVICE_ENV="$SVC_ENV_VARS" \
    LIBSCRIPT_SERVICE_ENV_FILES="$SVC_ENV_FILES" \
      libscript_install_service "$NAME" "$CMD" "$SVC_WORKDIR" "$NAME service managed by libscript" "$SVC_ENV_VARS" "$SVC_USER" "$SVC_ENV_FILES"
    _dm_hc_url=$(printf '%s\n' "$svc" | jq -r '(.health_check // .healthcheck) as $hc | if ($hc | type) == "object" then ($hc.url // empty) else empty end' 2>/dev/null || true)
    _dm_hc_url=$(expand_manifest_vars "$_dm_hc_url")
    if [ "${FORCE_REINSTALL:-0}" != "1" ] && [ "${FORCE_REBUILD:-0}" != "1" ] && [ "${LIBSCRIPT_SERVICE_UNIT_UNCHANGED:-0}" = "1" ] && [ "$(libscript_detect_init_system)" = "systemd" ] && systemctl is-active --quiet "$NAME" 2>/dev/null && { [ -z "$_dm_hc_url" ] || curl -sf -m 3 "$_dm_hc_url" >/dev/null 2>&1; }; then
      log_info "[REUSE] Daemon '$NAME' is already running and healthy."
    elif ! libscript_service restart "$NAME" 2>/dev/null; then
      libscript_service start "$NAME" 2>/dev/null || libscript_service_fallback start "$NAME"
    fi
  elif [ "$ACTION" = "stop" ] || [ "$ACTION" = "down" ]; then
    libscript_service stop "$NAME" >/dev/null 2>&1 || true
    libscript_service disable "$NAME" >/dev/null 2>&1 || true
    libscript_service_fallback stop "$NAME" >/dev/null 2>&1 || true
    pkill -f "$CMD" 2>/dev/null || true
    log_info "Stopped service '$NAME'."
  elif [ "$ACTION" = "status" ]; then
    PID_FILE="${SVC_DATA}/service.pid"
    if [ -f "$PID_FILE" ]; then
      SVC_PID=$(cat "$PID_FILE" 2>/dev/null || true)
      if [ -n "$SVC_PID" ] && kill -0 "$SVC_PID" 2>/dev/null; then
        printf '[RUNNING] %s (PID %s)\n' "$NAME" "$SVC_PID"
      else
        printf '[STOPPED] %s (stale PID %s)\n' "$NAME" "${SVC_PID:-unknown}"
      fi
    else
      libscript_service status "$NAME" 2>/dev/null || printf '[STOPPED] %s\n' "$NAME"
    fi
  elif [ "$ACTION" = "health" ]; then
    SVC_RUNNING=0
    PID_FILE="${SVC_DATA}/service.pid"
    if [ -f "$PID_FILE" ]; then
      SVC_PID=$(cat "$PID_FILE" 2>/dev/null || true)
      if [ -n "$SVC_PID" ] && kill -0 "$SVC_PID" 2>/dev/null; then
        printf '[RUNNING] %s (PID %s)\n' "$NAME" "$SVC_PID"
        SVC_RUNNING=1
      else
        printf '[STOPPED] %s (stale PID %s)\n' "$NAME" "${SVC_PID:-unknown}"
      fi
    elif [ "$(libscript_detect_init_system)" = "systemd" ]; then
      if systemctl is-active --quiet "$NAME" 2>/dev/null || systemctl --user is-active --quiet "$NAME" 2>/dev/null; then
        _sub_state=$(systemctl show -p SubState --value "$NAME" 2>/dev/null || systemctl --user show -p SubState --value "$NAME" 2>/dev/null || printf 'running')
        if [ "$_sub_state" = "auto-restart" ] || [ "$_sub_state" = "failed" ] || [ "$_sub_state" = "dead" ]; then
          sleep 2
          _sub_state=$(systemctl show -p SubState --value "$NAME" 2>/dev/null || systemctl --user show -p SubState --value "$NAME" 2>/dev/null || printf 'running')
        fi
        if [ "$_sub_state" = "auto-restart" ] || [ "$_sub_state" = "failed" ] || [ "$_sub_state" = "dead" ]; then
          printf '[STOPPED] %s (systemd SubState=%s)\n' "$NAME" "$_sub_state"
          dump_service_failure_logs "$NAME"
        else
          printf '[RUNNING] %s (systemd active)\n' "$NAME"
          SVC_RUNNING=1
        fi
      else
        printf '[STOPPED] %s\n' "$NAME"
        dump_service_failure_logs "$NAME"
      fi
    elif printf '%s\n' "$OS_NAME" | grep -q "darwin" && launchctl list 2>/dev/null | grep -q "com.libscript.${NAME}"; then
      printf '[RUNNING] %s (launchd active)\n' "$NAME"
      SVC_RUNNING=1
    elif libscript_service status "$NAME" >/dev/null 2>&1; then
      printf '[RUNNING] %s (init active)\n' "$NAME"
      SVC_RUNNING=1
    else
      printf '[STOPPED] %s\n' "$NAME"
      dump_service_failure_logs "$NAME"
    fi

    if [ "$SVC_RUNNING" -eq 0 ]; then
      HEALTH_FAILED=1
    else
      HC_CMD=$(printf '%s\n' "$svc" | jq -r '(.health_check // .healthcheck) as $hc | if ($hc | type) == "string" then $hc elif ($hc | type) == "object" then ($hc.command // empty) else empty end' 2>/dev/null || true)
      HC_CMD=$(expand_manifest_vars "$HC_CMD")
      HC_URL=$(printf '%s\n' "$svc" | jq -r '(.health_check // .healthcheck) as $hc | if ($hc | type) == "object" then ($hc.url // empty) else empty end' 2>/dev/null || true)
      HC_URL=$(expand_manifest_vars "$HC_URL")
      HC_EXPECT_STATUS=$(printf '%s\n' "$svc" | jq -r '(.health_check // .healthcheck) as $hc | if ($hc | type) == "object" then ($hc.expect_status // empty) else empty end' 2>/dev/null || true)
      HC_EXPECT_JSON=$(printf '%s\n' "$svc" | jq -r '(.health_check // .healthcheck) as $hc | if ($hc | type) == "object" then ($hc.expect_json // empty) else empty end' 2>/dev/null || true)
      HC_RETRIES=$(printf '%s\n' "$svc" | jq -r '(.health_check // .healthcheck) as $hc | if ($hc | type) == "object" then ($hc.retries // 15) else 15 end' 2>/dev/null || printf '15')
      HC_INTERVAL=$(printf '%s\n' "$svc" | jq -r '(.health_check // .healthcheck) as $hc | if ($hc | type) == "object" then ($hc.interval // 2) else 2 end' 2>/dev/null || printf '2')
      HC_TIMEOUT=$(printf '%s\n' "$svc" | jq -r '(.health_check // .healthcheck) as $hc | if ($hc | type) == "object" then ($hc.timeout // 5) else 5 end' 2>/dev/null || printf '5')
      SVC_PORT=$(printf '%s\n' "$svc" | jq -r '.port // empty' 2>/dev/null || true)
      SVC_PORT=$(expand_manifest_vars "$SVC_PORT")

      if [ -n "$HC_CMD" ]; then
        log_info "Running health check command for service '$NAME'..."
        if ! run_service_health_cmd "$HC_CMD" "$SVC_WORKDIR" "$svc"; then
          log_error "Health check command failed for service '$NAME': $HC_CMD"
          dump_service_failure_logs "$NAME"
          HEALTH_FAILED=1
        fi
      fi

      if [ -n "$HC_URL" ]; then
        log_info "Polling health check URL for service '$NAME': $HC_URL"
        _hc_attempt=1
        _hc_url_ok=0
        _hc_body=""
        while [ "$_hc_attempt" -le "$HC_RETRIES" ]; do
          if [ -n "$HC_EXPECT_STATUS" ]; then
            _hc_tmp_body=$(mktemp "${TMPDIR:-/tmp}/libscript_hc.XXXXXX")
            _hc_code=$(curl -s -m "$HC_TIMEOUT" -o "$_hc_tmp_body" -w "%{http_code}" "$HC_URL" 2>/dev/null || printf '000')
            if [ "$_hc_code" = "$HC_EXPECT_STATUS" ]; then
              _hc_body=$(cat "$_hc_tmp_body" 2>/dev/null || true)
              rm -f "$_hc_tmp_body"
              _hc_url_ok=1
              break
            fi
            rm -f "$_hc_tmp_body"
          else
            if _hc_body=$(curl -sf -m "$HC_TIMEOUT" "$HC_URL" 2>/dev/null); then
              _hc_url_ok=1
              break
            fi
          fi
          if [ "$_hc_attempt" -lt "$HC_RETRIES" ]; then
            sleep "$HC_INTERVAL"
          fi
          _hc_attempt=$((_hc_attempt + 1))
        done
        if [ "$_hc_url_ok" -eq 0 ]; then
          log_error "Health check URL failed for service '$NAME': $HC_URL"
          dump_service_failure_logs "$NAME"
          HEALTH_FAILED=1
        elif [ -n "$HC_EXPECT_JSON" ]; then
          if ! evaluate_json_expr "$_hc_body" "$HC_EXPECT_JSON"; then
            log_error "Health check expect_json failed for service '$NAME': $HC_EXPECT_JSON (response: $_hc_body)"
            dump_service_failure_logs "$NAME"
            HEALTH_FAILED=1
          fi
        fi
      elif [ -z "$HC_CMD" ] && [ -n "$SVC_PORT" ]; then
        _port_attempt=1
        _port_ok=0
        while [ "$_port_attempt" -le "$HC_RETRIES" ]; do
          if command -v curl >/dev/null 2>&1 && curl -s -m "$HC_TIMEOUT" -o /dev/null "http://127.0.0.1:${SVC_PORT}" 2>/dev/null; then
            _port_ok=1
            break
          elif command -v nc >/dev/null 2>&1 && nc -z 127.0.0.1 "$SVC_PORT" >/dev/null 2>&1; then
            _port_ok=1
            break
          fi
          if [ "$_port_attempt" -lt "$HC_RETRIES" ]; then
            sleep "$HC_INTERVAL"
          fi
          _port_attempt=$((_port_attempt + 1))
        done
        if [ "$_port_ok" -eq 0 ]; then
          log_error "Port check failed for service '$NAME' on 127.0.0.1:${SVC_PORT}"
          dump_service_failure_logs "$NAME"
          HEALTH_FAILED=1
        fi
      fi
    fi
  elif [ "$ACTION" = "logs" ]; then
    if [ -f "${SVC_DATA}/service.log" ]; then
      printf '=== %s (%s/service.log) ===\n' "$NAME" "$SVC_DATA"
      tail -n 50 "${SVC_DATA}/service.log"
    elif [ -f "${SVC_DATA}/stdout.log" ]; then
      printf '=== %s (%s/stdout.log) ===\n' "$NAME" "$SVC_DATA"
      tail -n 50 "${SVC_DATA}/stdout.log"
    elif [ -f "/var/log/${NAME}.log" ]; then
      printf '=== %s (/var/log/%s.log) ===\n' "$NAME" "$NAME"
      tail -n 50 "/var/log/${NAME}.log"
    else
      printf '=== %s (init logs) ===\n' "$NAME"
      libscript_service logs "$NAME" -n 50 2>/dev/null || printf '=== %s (no logs found) ===\n' "$NAME"
    fi
  fi
done 3<< EOF_SERVICES
$SERVICES
EOF_SERVICES

# Public Ingress Verification (--verify-ingress / --public-url)
if [ "$ACTION" = "health" ] && [ "$VERIFY_INGRESS" -eq 1 ]; then
  _ing_domain="$PUBLIC_URL"
  if [ -z "$_ing_domain" ]; then
    _ing_domain=$(jq -r '.ingress.domain // .domain // empty' "$JSON_FILE" 2>/dev/null || true)
    _ing_domain=$(expand_manifest_vars "$_ing_domain")
  fi
  if [ -n "$_ing_domain" ]; then
    case "$_ing_domain" in
      http://*|https://*) _ing_base="${_ing_domain%/}" ;;
      *) _ing_base="https://${_ing_domain%/}" ;;
    esac
    _expect_html=$(jq -r '.ingress.expect_html // empty' "$JSON_FILE" 2>/dev/null || true)
    log_info "Verifying public ingress at ${_ing_base}..."
    _ing_ok=0
    _ing_try=1
    while [ "$_ing_try" -le 10 ]; do
      if _ing_html=$(curl -sfL -m 10 "$_ing_base" 2>/dev/null); then
        if [ -z "$_expect_html" ] || printf '%s\n' "$_ing_html" | grep -Fq "$_expect_html"; then
          _ing_ok=1
          break
        fi
      fi
      sleep 2
      _ing_try=$((_ing_try + 1))
    done
    if [ "$_ing_ok" -eq 0 ]; then
      log_error "Public ingress verification failed for ${_ing_base} (expect_html: ${_expect_html:-any})"
      HEALTH_FAILED=1
    else
      log_info "Public ingress HTML verified at ${_ing_base}"
    fi

    # Verify public health endpoints for services with path-based health URLs
    while IFS= read -r _ing_svc; do
      [ -n "$_ing_svc" ] || continue
      _s_url=$(printf '%s\n' "$_ing_svc" | jq -r '(.health_check // .healthcheck) as $hc | if ($hc | type) == "object" then ($hc.url // empty) else empty end' 2>/dev/null || true)
      _s_url=$(expand_manifest_vars "$_s_url")
      _s_json=$(printf '%s\n' "$_ing_svc" | jq -r '(.health_check // .healthcheck) as $hc | if ($hc | type) == "object" then ($hc.expect_json // empty) else empty end' 2>/dev/null || true)
      case "$_s_url" in
        http://*/*|https://*/*)
          _s_path="/${_s_url#*://*/}"
          if [ "$_s_path" != "/" ] && [ -n "$_s_path" ]; then
            _pub_hc_url="${_ing_base}${_s_path}"
            log_info "Polling public health endpoint: $_pub_hc_url"
            if _pub_body=$(curl -sfL -m 10 "$_pub_hc_url" 2>/dev/null); then
              if [ -n "$_s_json" ] && ! evaluate_json_expr "$_pub_body" "$_s_json"; then
                log_error "Public health JSON assertion failed for $_pub_hc_url: $_s_json"
                HEALTH_FAILED=1
              fi
            else
              log_error "Public health endpoint unreachable: $_pub_hc_url"
              HEALTH_FAILED=1
            fi
          fi
          ;;
      esac
    done << EOF_ING_SERVICES
$SERVICES
EOF_ING_SERVICES
  fi
fi

if [ "$ACTION" = "health" ] && [ "$HEALTH_FAILED" -ne 0 ]; then
  exit 1
fi
