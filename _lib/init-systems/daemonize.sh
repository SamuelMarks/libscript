#!/bin/sh
# ## Overview
# Cross-platform daemonization wrapper supporting object-map and array service schemas,
# per-service working directories, environment variables, systemd, launchd, and PID fallback.
#
# ## Usage
# Run `daemonize.sh <action> <json_file>` to manage background services via systemd, launchd, or basic backgrounding.

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
# @description Automatically handles daemonize for the daemonize.sh (init-systems) component.
# @file daemonize.sh

LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(cd "${SCRIPT_DIR}/../../.." && pwd)}"
. "${LIBSCRIPT_ROOT_DIR}/_lib/_common/log.sh"

ACTION="${1:-}"
JSON_FILE="${2:-}"

if [ -z "$ACTION" ] || [ -z "$JSON_FILE" ] || [ ! -f "$JSON_FILE" ]; then
  exit 0
fi

MANIFEST_DIR=$(cd -- "$(dirname -- "$JSON_FILE")" && pwd)
DATA_BASE="${LIBSCRIPT_DATA_DIR:-/tmp/data}"

if [ -f "$LIBSCRIPT_ROOT_DIR/_lib/_common/env_printer.sh" ]; then
  SCRIPT_NAME="$LIBSCRIPT_ROOT_DIR/_lib/_common/env_printer.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "$SCRIPT_NAME"
  libscript_hydrate_manifest_env "$JSON_FILE"
fi

SERVICES=$(jq -c '(.services | if type == "object" then to_entries | map(.value + {name: (.value.name // .key)}) elif type == "array" then map(. + {name: (.name // .id)}) else [] end)[]?' "$JSON_FILE" 2>/dev/null || true)
if [ -z "$SERVICES" ]; then
  exit 0
fi

OS_NAME=$(uname -s | tr '[:upper:]' '[:lower:]')

# ## resolve_workdir
# Resolves a relative or absolute service working directory against the manifest directory.
resolve_workdir() {
  _raw_wd="$1"
  if [ -z "$_raw_wd" ] || [ "$_raw_wd" = "." ]; then
    printf '%s
' "$MANIFEST_DIR"
  elif [ "${_raw_wd#/}" != "$_raw_wd" ]; then
    printf '%s
' "$_raw_wd"
  else
    printf '%s
' "${MANIFEST_DIR}/${_raw_wd}"
  fi
}

# ## resolve_env_file
# Resolves a relative or absolute env_file path against the service working directory or manifest directory.
resolve_env_file() {
  _ef="$1"
  _wd="$2"
  if [ "${_ef#/}" != "$_ef" ]; then
    printf '%s
' "$_ef"
  elif [ -f "${_wd}/${_ef}" ]; then
    printf '%s
' "${_wd}/${_ef}"
  else
    printf '%s
' "${MANIFEST_DIR}/${_ef}"
  fi
}

# ## start_fallback_daemon
# Launches a service in a background subshell with isolated env, working_dir, log file, and PID tracking.
start_fallback_daemon() {
  _name="$1"
  _cmd="$2"
  _workdir="$3"
  _svc_json="$4"
  _svc_data="${DATA_BASE}/${_name}"
  mkdir -p "$_svc_data"
  _pid_file="${_svc_data}/service.pid"
  _log_file="${_svc_data}/service.log"

  if [ -f "$_pid_file" ]; then
    _old_pid=$(cat "$_pid_file" 2>/dev/null || true)
    if [ -n "$_old_pid" ] && kill -0 "$_old_pid" 2>/dev/null; then
      log_info "Service '$_name' is already running (PID $_old_pid)."
      return 0
    fi
  fi

  _runner="${_svc_data}/run_${_name}.sh"
  {
    printf '#!/bin/sh
'
    printf 'export PATH="%s"
' "$PATH"
    printf 'if [ -f "%s/env.sh" ]; then . "%s/env.sh" >/dev/null 2>&1 || true; fi
' "$LIBSCRIPT_ROOT_DIR" "$LIBSCRIPT_ROOT_DIR"
    if [ -f "${MANIFEST_DIR}/.env.libscript" ]; then
      printf 'set -a; . "%s/.env.libscript" 2>/dev/null || true; set +a
' "$MANIFEST_DIR"
    fi
    _ef_list=$(printf '%s
' "$_svc_json" | jq -r '.env_files[]?' 2>/dev/null || true)
    if [ -n "$_ef_list" ]; then
      printf '%s
' "$_ef_list" | while IFS= read -r _ef_item; do
        [ -n "$_ef_item" ] || continue
        _ef_resolved=$(resolve_env_file "$_ef_item" "$_workdir")
        printf 'if [ -f "%s" ]; then set -a; . "%s" 2>/dev/null || true; set +a; fi
' "$_ef_resolved" "$_ef_resolved"
      done
    fi
    _env_pairs=$(printf '%s
' "$_svc_json" | jq -r '(.env // .environment // {}) | to_entries[]? | "export \(.key)=\(.value | @sh)"' 2>/dev/null || true)
    if [ -n "$_env_pairs" ]; then
      printf '%s
' "$_env_pairs"
    fi
    printf 'cd "%s" || exit 1
' "$_workdir"
    printf 'exec %s
' "$_cmd"
  } > "$_runner"
  chmod +x "$_runner"

  nohup sh "$_runner" >> "$_log_file" 2>&1 &
  _new_pid=$!
  printf '%s
' "$_new_pid" > "$_pid_file"
  log_info "Started service '$_name' in background (PID $_new_pid, log: $_log_file)"
}

printf '%s
' "$SERVICES" | while IFS= read -r svc; do
  [ -n "$svc" ] || continue
  NAME=$(printf '%s
' "$svc" | jq -r '.name // empty')
  CMD=$(printf '%s
' "$svc" | jq -r '.command // empty')
  if [ -z "$NAME" ] || [ -z "$CMD" ]; then continue; fi

  RAW_WORKDIR=$(printf '%s
' "$svc" | jq -r '.working_dir // .working_directory // .cwd // "."')
  SVC_WORKDIR=$(resolve_workdir "$RAW_WORKDIR")
  SVC_DATA="${DATA_BASE}/${NAME}"
  mkdir -p "$SVC_DATA" 2>/dev/null || true

  if [ "$ACTION" = "start" ] || [ "$ACTION" = "up" ]; then
    log_info "Configuring service '$NAME' (workdir: $SVC_WORKDIR)..."
    if [ "$OS_NAME" = "linux" ] && command -v systemctl >/dev/null 2>&1 && [ "${LIBSCRIPT_FORCE_FALLBACK_DAEMON:-0}" != "1" ] && [ -d /run/systemd/system ]; then
      PRE_ENV=""
      if [ -f "${LIBSCRIPT_ROOT_DIR}/env.sh" ]; then
        PRE_ENV=". \"${LIBSCRIPT_ROOT_DIR}/env.sh\" >/dev/null 2>&1 || true; "
      fi
      if [ "$(id -u)" -eq 0 ] || sudo -n true 2>/dev/null; then
        SERVICE_FILE="/etc/systemd/system/${NAME}.service"
        sudo sh -c "cat << SYSTEMD > \"$SERVICE_FILE\"
[Unit]
Description=$NAME service managed by libscript
After=network.target

[Service]
WorkingDirectory=$SVC_WORKDIR
Environment=\"PATH=$PATH\"
ExecStart=/bin/sh -c '${PRE_ENV}${CMD}'
StandardOutput=journal
StandardError=journal
Restart=always
SYSTEMD
"
        ENVS=$(printf '%s\n' "$svc" | jq -r '(.env // .environment // {}) | to_entries[]? | "\(.key)=\(.value)"' 2>/dev/null || true)
        if [ -n "$ENVS" ]; then
          printf '%s\n' "$ENVS" | while IFS= read -r e; do
            [ -n "$e" ] && sudo sh -c "printf 'Environment=\"%s\"\n' \"$e\" >> \"$SERVICE_FILE\""
          done
        fi
        if [ -f "${MANIFEST_DIR}/.env.libscript" ]; then
          sudo sh -c "printf 'EnvironmentFile=-%s/.env.libscript\n' \"$MANIFEST_DIR\" >> \"$SERVICE_FILE\""
        fi
        ENV_FILES=$(printf '%s\n' "$svc" | jq -r '.env_files[]?' 2>/dev/null || true)
        if [ -n "$ENV_FILES" ]; then
          printf '%s\n' "$ENV_FILES" | while IFS= read -r ef; do
            EF_FULL=$(resolve_env_file "$ef" "$SVC_WORKDIR")
            if [ -f "$EF_FULL" ]; then
              sudo sh -c "printf 'EnvironmentFile=%s\n' \"$EF_FULL\" >> \"$SERVICE_FILE\""
            fi
          done
        fi
        sudo sh -c "cat << 'SYSTEMD' >> \"$SERVICE_FILE\"

[Install]
WantedBy=multi-user.target
SYSTEMD
"
        sudo systemctl daemon-reload
        sudo systemctl enable "$NAME" && sudo systemctl restart "$NAME"
      elif systemctl --user status >/dev/null 2>&1; then
        USER_UNIT_DIR="${HOME}/.config/systemd/user"
        mkdir -p "$USER_UNIT_DIR"
        SERVICE_FILE="${USER_UNIT_DIR}/${NAME}.service"
        cat << SYSTEMD > "$SERVICE_FILE"
[Unit]
Description=$NAME service managed by libscript
After=network.target

[Service]
WorkingDirectory=$SVC_WORKDIR
Environment="PATH=$PATH"
ExecStart=/bin/sh -c '${PRE_ENV}${CMD}'
StandardOutput=append:${SVC_DATA}/stdout.log
StandardError=append:${SVC_DATA}/stderr.log
Restart=always
SYSTEMD
        ENVS=$(printf '%s\n' "$svc" | jq -r '(.env // .environment // {}) | to_entries[]? | "\(.key)=\(.value)"' 2>/dev/null || true)
        if [ -n "$ENVS" ]; then
          printf '%s\n' "$ENVS" | while IFS= read -r e; do
            [ -n "$e" ] && printf 'Environment="%s"\n' "$e" >> "$SERVICE_FILE"
          done
        fi
        if [ -f "${MANIFEST_DIR}/.env.libscript" ]; then
          printf 'EnvironmentFile=-%s/.env.libscript\n' "$MANIFEST_DIR" >> "$SERVICE_FILE"
        fi
        ENV_FILES=$(printf '%s\n' "$svc" | jq -r '.env_files[]?' 2>/dev/null || true)
        if [ -n "$ENV_FILES" ]; then
          printf '%s\n' "$ENV_FILES" | while IFS= read -r ef; do
            EF_FULL=$(resolve_env_file "$ef" "$SVC_WORKDIR")
            if [ -f "$EF_FULL" ]; then
              printf 'EnvironmentFile=%s\n' "$EF_FULL" >> "$SERVICE_FILE"
            fi
          done
        fi
        cat << 'SYSTEMD' >> "$SERVICE_FILE"

[Install]
WantedBy=default.target
SYSTEMD
        systemctl --user daemon-reload
        systemctl --user enable "$NAME" && systemctl --user restart "$NAME"
      else
        start_fallback_daemon "$NAME" "$CMD" "$SVC_WORKDIR" "$svc"
      fi
    elif printf '%s\n' "$OS_NAME" | grep -q "darwin" && [ "${LIBSCRIPT_FORCE_FALLBACK_DAEMON:-0}" != "1" ] && [ "${LIBSCRIPT_USE_LAUNCHD:-0}" = "1" ]; then
      PLIST_FILE="$HOME/Library/LaunchAgents/com.libscript.${NAME}.plist"
      mkdir -p "$HOME/Library/LaunchAgents"
      ENV_DICT="<key>PATH</key><string>${PATH}</string>"
      ENVS=$(printf '%s\n' "$svc" | jq -r '(.env // .environment // {}) | to_entries[]? | "<key>\(.key)</key><string>\(.value)</string>"' 2>/dev/null || true)
      if [ -n "$ENVS" ]; then
        ENV_DICT="${ENV_DICT}${ENVS}"
      fi
      ENV_FILES=$(printf '%s\n' "$svc" | jq -r '.env_files[]?' 2>/dev/null || true)
      if [ -n "$ENV_FILES" ]; then
        while IFS= read -r ef; do
          [ -n "$ef" ] || continue
          EF_FULL=$(resolve_env_file "$ef" "$SVC_WORKDIR")
          if [ -f "$EF_FULL" ]; then
            while IFS='=' read -r k v; do
              case "$k" in ''|\#*) continue ;; esac
              v=$(printf '%s' "$v" | sed -e 's/^"//;s/"$//')
              ENV_DICT="${ENV_DICT}<key>${k}</key><string>${v}</string>"
            done < "$EF_FULL"
          fi
        done << EOF_EF
$ENV_FILES
EOF_EF
      fi
      cat << PLIST > "$PLIST_FILE"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.libscript.${NAME}</string>
    <key>WorkingDirectory</key>
    <string>${SVC_WORKDIR}</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/sh</string>
        <string>-c</string>
        <string>$CMD</string>
    </array>
    <key>EnvironmentVariables</key>
    <dict>
        ${ENV_DICT}
    </dict>
    <key>StandardOutPath</key>
    <string>${SVC_DATA}/stdout.log</string>
    <key>StandardErrorPath</key>
    <string>${SVC_DATA}/stderr.log</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
PLIST
      launchctl load -w "$PLIST_FILE" 2>/dev/null || true
      launchctl start "com.libscript.${NAME}" 2>/dev/null || true
      start_fallback_daemon "$NAME" "$CMD" "$SVC_WORKDIR" "$svc"
    else
      start_fallback_daemon "$NAME" "$CMD" "$SVC_WORKDIR" "$svc"
    fi
  elif [ "$ACTION" = "stop" ] || [ "$ACTION" = "down" ]; then
    PID_FILE="${SVC_DATA}/service.pid"
    if [ -f "$PID_FILE" ]; then
      SVC_PID=$(cat "$PID_FILE" 2>/dev/null || true)
      if [ -n "$SVC_PID" ] && kill -0 "$SVC_PID" 2>/dev/null; then
        kill "$SVC_PID" 2>/dev/null || true
        sleep 1
        kill -9 "$SVC_PID" 2>/dev/null || true
      fi
      rm -f "$PID_FILE"
    fi
    if [ "$OS_NAME" = "linux" ] && command -v systemctl >/dev/null 2>&1 && [ -d /run/systemd/system ]; then
      if [ "$(id -u)" -eq 0 ] || sudo -n true 2>/dev/null; then
        sudo systemctl stop "$NAME" 2>/dev/null || true
        sudo systemctl disable "$NAME" 2>/dev/null || true
      elif systemctl --user status >/dev/null 2>&1; then
        systemctl --user stop "$NAME" 2>/dev/null || true
        systemctl --user disable "$NAME" 2>/dev/null || true
      fi
    elif printf '%s
' "$OS_NAME" | grep -q "darwin"; then
      if [ -f "$HOME/Library/LaunchAgents/com.libscript.${NAME}.plist" ]; then
        launchctl stop "com.libscript.${NAME}" 2>/dev/null || true
        launchctl unload -w "$HOME/Library/LaunchAgents/com.libscript.${NAME}.plist" 2>/dev/null || true
      fi
    fi
    pkill -f "$CMD" 2>/dev/null || true
    log_info "Stopped service '$NAME'."
  elif [ "$ACTION" = "status" ] || [ "$ACTION" = "health" ]; then
    PID_FILE="${SVC_DATA}/service.pid"
    if [ -f "$PID_FILE" ]; then
      SVC_PID=$(cat "$PID_FILE" 2>/dev/null || true)
      if [ -n "$SVC_PID" ] && kill -0 "$SVC_PID" 2>/dev/null; then
        printf '[RUNNING] %s (PID %s)
' "$NAME" "$SVC_PID"
      else
        printf '[STOPPED] %s (stale PID %s)
' "$NAME" "${SVC_PID:-unknown}"
      fi
    elif [ "$OS_NAME" = "linux" ] && command -v systemctl >/dev/null 2>&1 && [ -d /run/systemd/system ]; then
      systemctl status "$NAME" --no-pager 2>/dev/null || systemctl --user status "$NAME" --no-pager 2>/dev/null || printf '[STOPPED] %s
' "$NAME"
    elif printf '%s
' "$OS_NAME" | grep -q "darwin" && launchctl list 2>/dev/null | grep -q "com.libscript.${NAME}"; then
      launchctl list | grep "com.libscript.${NAME}" || true
    else
      printf '[STOPPED] %s
' "$NAME"
    fi
  elif [ "$ACTION" = "logs" ]; then
    if [ -f "${SVC_DATA}/service.log" ]; then
      printf '=== %s (%s/service.log) ===
' "$NAME" "$SVC_DATA"
      tail -n 50 "${SVC_DATA}/service.log"
    elif [ -f "${SVC_DATA}/stdout.log" ]; then
      printf '=== %s (%s/stdout.log) ===
' "$NAME" "$SVC_DATA"
      tail -n 50 "${SVC_DATA}/stdout.log"
    else
      printf '=== %s (no logs found) ===
' "$NAME"
    fi
  fi
done
