#!/bin/sh
# shellcheck disable=SC3054,SC3040,SC2296,SC2128,SC2039,SC2016,SC1090,SC1091,SC2034,SC2018,SC2019,SC2221,SC2222,SC2129,SC2209,SC2089,SC2090,SC2086,SC2154,SC2044,SC2181,SC2038,SC2155,SC2046,SC2002,SC1003,SC2295,SC2145


set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
SCHEMA_FILE="$SCRIPT_DIR/vars.schema.json"

show_help() {
  echo "Usage: $0 [COMMAND] [PACKAGE_NAME] [VERSION] [OPTIONS]"
  echo ""
  echo "Commands:"
  echo "  install <package_name> <version>"
  echo "  remove <package_name> [version]"
  echo "  uninstall <package_name> [version]"
  echo "  install_daemon <package_name> <version>"
  echo "  install_service <package_name> <version>"
  echo "  uninstall_daemon <package_name> <version>"
  echo "  uninstall_service <package_name> <version>"
  echo "  remove_daemon <package_name> <version>"
  echo "  remove_service <package_name> <version>"
  echo "  status <package_name> [version]"
  echo "  health <package_name> [version]"
  echo "  start <package_name> [version]"
  echo "  stop <package_name> [version]"
  echo "  restart <package_name> [version]"
  echo "  logs <package_name> [version] [-f|--follow]"
  echo "  up <package_name> [version]"
  echo "  down <package_name> [version]"
  echo "  test <package_name> [version]"
  echo "  run <package_name> <version> [args...]"
  echo "  which <package_name> <version>"
  echo "  exec <package_name> <version> <cmd> [args...]"
  echo "  ls <package_name>"
  echo "  download <package_name> <version>"
  echo "  ls-remote <package_name> [version]"
  echo ""
  echo "Description:"
  if command -v jq >/dev/null 2>&1 && [ -f "$SCHEMA_FILE" ]; then
    DESC=$(jq -r 'if .description then .description else "" end' "$SCHEMA_FILE")
    [ -n "$DESC" ] && echo "  $DESC"
  fi
  echo ""
  echo "Available Options:"
  if command -v jq >/dev/null 2>&1 && [ -f "$SCHEMA_FILE" ]; then
    jq -r '
      .properties | to_entries[] | 
      def aliases: if .value.versionAliases then " [aliases: " + (.value.versionAliases | join(", ")) + "]" else "" end;
      "--\(.key)=VALUE|\(.value.description)\(aliases) [default: \(.value.default // "none")]"
    ' "$SCHEMA_FILE" | awk -F'|' '{printf "  %-35s %s\n", $1, $2}'
    
    jq -r '
      .properties | to_entries[] | select(.value.is_libscript_dependency == true) |
      "--\(.key)_STRATEGY=VALUE|Strategy for \(.key) (reuse, install-alongside, upgrade, downgrade, overwrite) [default: reuse]"
    ' "$SCHEMA_FILE" | awk -F'|' '{printf "  %-35s %s\n", $1, $2}'
  else
    echo "  (jq is required to parse vars.schema.json for dynamic options)"
    echo "  See $SCHEMA_FILE for available variables."
  fi
  echo ""
  echo "  --prefix=<dir>                      Set local installation prefix"
  echo "  --service-name=<name>               Set a custom service/daemon name"
  echo "  --log-driver=<driver>               Set log driver (file, syslog, tcp, json_file, custom) [default: file]"
  echo "  --log-host=<host>                   Set log host for tcp driver"
  echo "  --log-port=<port>                   Set log port for tcp driver"
  echo "  --log-cmd=<cmd>                     Set custom log command (e.g., 'nc localhost 5170')"
  echo "  --secrets=<dir|url>                 Save generated secrets to a directory or OpenBao/Vault URL"
  echo "  --help, -h, /?                      Show this help message"
  echo "  --version, -v                       Show version"
  echo ""
}

ACTION=""
PACKAGE_NAME=""
VERSION=""

case "$1" in
  --help|-h|/\?|"-?")
    show_help
    exit 0
    ;;
  --version|-v)
    echo "${LIBSCRIPT_VERSION:-dev}"
    exit 0
    ;;
  install|install_daemon|install_service|uninstall_daemon|uninstall_service|remove_daemon|remove_service)
    ACTION="$1"
    PACKAGE_NAME="$2"
    VERSION="$3"
    if [ -z "$PACKAGE_NAME" ]; then
      echo "Error: package_name is required for $ACTION" >&2
      exit 1
    fi
    if [ -z "$VERSION" ]; then
      echo "Error: version is required for $ACTION" >&2
      exit 1
    fi
    shift 3
    ;;
  run|which|exec|env|serve|route)
    ACTION="$1"
    PACKAGE_NAME="$2"
    VERSION="$3"
    if [ -z "$PACKAGE_NAME" ]; then
      echo "Error: package_name is required for $ACTION" >&2
      exit 1
    fi
    if [ -z "$VERSION" ]; then
      echo "Error: version is required for $ACTION" >&2
      exit 1
    fi
    shift 3
    ;;
  ls|ls-remote|download)
    ACTION="$1"
    PACKAGE_NAME="$2"
    VERSION="$3"
    if [ -z "$PACKAGE_NAME" ]; then
      echo "Error: package_name is required for $ACTION" >&2
      exit 1
    fi
    case "$VERSION" in
      --*) VERSION="" ; shift 2 ;;
      *)
        if [ -n "$VERSION" ]; then
          shift 3
        else
          VERSION=""
          shift 2
        fi
        ;;
    esac
    ;;
  remove|uninstall|status|health|test|start|stop|restart|logs|up|down)
    ACTION="$1"
    PACKAGE_NAME="$2"
    VERSION="$3"
    if [ -z "$PACKAGE_NAME" ]; then
      echo "Error: package_name is required for $ACTION" >&2
      exit 1
    fi
    case "$VERSION" in
      --*) VERSION="" ; shift 2 ;;
      *)
        if [ -n "$VERSION" ]; then
          shift 3
        else
          VERSION=""
          shift 2
        fi
        ;;
    esac
    ;;
  *)
    if [ -n "$1" ]; then
      echo "Unknown command: $1"
      echo "Use --help to see available options."
      exit 1
    else
      show_help
      exit 0
    fi
    ;;
esac

export ACTION
export PACKAGE_NAME
export VERSION

if [ -n "$PACKAGE_NAME" ] && [ -n "$VERSION" ]; then
  pkg_upper=$(echo "${PACKAGE_NAME##*/}" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
  var_name="${pkg_upper}_VERSION"
  export "$var_name"="$VERSION"
fi

# Parse remaining args
if [ "$VERSION" = "latest" ] || [ "$VERSION" = "lts" ] || [ "$VERSION" = "stable" ]; then
  export LIBSCRIPT_NEVER_REFRESH_CHECKSUM_DB=1
fi

while [ $# -gt 0 ]; do
  if [ "$ACTION" = "start" ] || [ "$ACTION" = "stop" ] || [ "$ACTION" = "restart" ] || [ "$ACTION" = "status" ] || [ "$ACTION" = "health" ] || [ "$ACTION" = "logs" ] || [ "$ACTION" = "up" ] || [ "$ACTION" = "down" ] || [ "$ACTION" = "run" ] || [ "$ACTION" = "exec" ]; then
    break
  fi
  case "$1" in
    --help|-h|/\?|"-?")
      show_help
      exit 0
      ;;
    --version|-v)
      echo "${LIBSCRIPT_VERSION:-dev}"
      exit 0
      ;;
    --prefix=*)
      export PREFIX="${1#*=}"
      shift
      ;;
    --service-name=*)
      export LIBSCRIPT_SERVICE_NAME="${1#*=}"
      shift
      ;;
    --log-driver=*)
      export LIBSCRIPT_LOG_DRIVER="${1#*=}"
      shift
      ;;
    --log-host=*)
      export LIBSCRIPT_LOG_HOST="${1#*=}"
      shift
      ;;
    --log-port=*)
      export LIBSCRIPT_LOG_PORT="${1#*=}"
      shift
      ;;
    --log-cmd=*)
      export LIBSCRIPT_LOG_CMD="${1#*=}"
      shift
      ;;
      --listen=*)
        listen_str="${1#*=}"
        if echo "$listen_str" | grep -q "^unix:"; then
          export LIBSCRIPT_LISTEN_SOCKET="${listen_str#unix:}"
        elif echo "$listen_str" | grep -q ":"; then
          export LIBSCRIPT_LISTEN_ADDRESS="${listen_str%%:*}"
          export LIBSCRIPT_LISTEN_PORT="${listen_str##*:}"
        else
          export LIBSCRIPT_LISTEN_PORT="$listen_str"
        fi
        shift
        ;;
    --listen-port=*)
      export LIBSCRIPT_LISTEN_PORT="${1#*=}"
      shift
      ;;
    --listen-address=*)
      export LIBSCRIPT_LISTEN_ADDRESS="${1#*=}"
      shift
      ;;
    --listen-socket=*)
      export LIBSCRIPT_LISTEN_SOCKET="${1#*=}"
      shift
      ;;
    --never-refresh-checksum-db)
      export LIBSCRIPT_NEVER_REFRESH_CHECKSUM_DB=1
      shift
      ;;
    --export-aria2-downloads=*)
      export LIBSCRIPT_ARIA2_EXPORT_FILE="${1#*=}"
      shift
      ;;
    --secrets=*)
      export LIBSCRIPT_SECRETS="${1#*=}"
      shift
      ;;
    --*=*)
      key="${1%%=*}"
      key="${key#--}"
      val="${1#*=}"
      export "$key"="$val"
      shift
      ;;
    *)
      echo "Unknown argument: $1"
      echo "Use --help to see available options."
      exit 1
      ;;
  esac
done

if [ "$ACTION" = "start" ] || [ "$ACTION" = "stop" ] || [ "$ACTION" = "restart" ] || [ "$ACTION" = "status" ] || [ "$ACTION" = "health" ] || [ "$ACTION" = "logs" ] || [ "$ACTION" = "up" ] || [ "$ACTION" = "down" ] || [ "$ACTION" = "run" ] || [ "$ACTION" = "which" ] || [ "$ACTION" = "exec" ] || [ "$ACTION" = "env" ] || [ "$ACTION" = "serve" ] || [ "$ACTION" = "route" ] || [ "$ACTION" = "ls" ] || [ "$ACTION" = "ls-remote" ] || [ "$ACTION" = "download" ] || [ "$ACTION" = "uninstall" ] || [ "$ACTION" = "remove" ] || [ "$ACTION" = "uninstall_daemon" ] || [ "$ACTION" = "uninstall_service" ] || [ "$ACTION" = "remove_daemon" ] || [ "$ACTION" = "remove_service" ]; then
  # Action logic
  INSTALLED_DIR="${PREFIX:-$LIBSCRIPT_ROOT_DIR/installed/$PACKAGE_NAME}"
  BIN_PATH="$INSTALLED_DIR/bin/$PACKAGE_NAME"
  
  case "$ACTION" in
    run)
      if [ ! -x "$BIN_PATH" ]; then
        echo "Error: $PACKAGE_NAME version $VERSION not installed at $BIN_PATH"
        exit 1
      fi
      exec "$BIN_PATH" "$@"
      ;;
    which)
      if [ -x "$BIN_PATH" ]; then
        echo "$BIN_PATH"
      else
        echo "Not installed: $BIN_PATH"
        exit 1
      fi
      ;;
    exec)
      if [ ! -d "$INSTALLED_DIR/bin" ]; then
        echo "Error: $PACKAGE_NAME version $VERSION bin directory not found at $INSTALLED_DIR/bin"
        exit 1
      fi
      export PATH="$INSTALLED_DIR/bin:$PATH"
      exec "$@"
      ;;
    env)
      FORMAT="${FORMAT:-${format:-sh}}"
      if [ "$FORMAT" = "docker" ]; then
        echo "ENV PATH=\"$INSTALLED_DIR/bin:\$PATH\""
      elif [ "$FORMAT" = "csh" ]; then
        echo "setenv PATH \"$INSTALLED_DIR/bin:\$PATH\""
      elif [ "$FORMAT" = "powershell" ]; then
        echo "\$env:PATH=\"$INSTALLED_DIR/bin;\" + \$env:PATH"
      elif [ "$FORMAT" = "docker_compose" ]; then
        # docker-compose usually manages PATH differently, but we can emit it
        echo "PATH=$INSTALLED_DIR/bin:\$PATH"
      elif [ "$FORMAT" = "cmd" ]; then
        echo "SET PATH=\"$INSTALLED_DIR/bin;%PATH%\""
      else
        echo "export PATH=\"$INSTALLED_DIR/bin:\$PATH\""
      fi
      if [ -f "$SCRIPT_DIR/env.sh" ]; then
        # Use env to capture exported variables
        env -i PATH="$PATH" FORMAT="$FORMAT" SCRIPT_NAME="$SCRIPT_DIR/env.sh" sh -c "
# shellcheck disable=SC1090,SC1091,SC2034
          . '$SCRIPT_DIR/env.sh' >/dev/null 2>&1
          env | grep -vE '^(PWD|SHLVL|_|PATH|FORMAT)=' | while read -r line; do
            key=\"\${line%%=*}\"
            val=\"\${line#*=}\"
            if [ \"\$FORMAT\" = \"docker\" ]; then
              echo \"ENV \$key=\\\"\$val\\\"\"
            elif [ \"\$FORMAT\" = \"csh\" ]; then
              echo \"setenv \$key \\\"\$val\\\"\"
            elif [ \"\$FORMAT\" = \"powershell\" ]; then
              echo \"\\\$env:\$key=\\\"\$val\\\"\"
            elif [ \"\$FORMAT\" = \"docker_compose\" ]; then
              echo \"\$key=\$val\"
            elif [ \"\$FORMAT\" = \"cmd\" ]; then
              echo \"SET \$key=\\\"\$val\\\"\"
            else
              echo \"export \$key=\\\"\$val\\\"\"
            fi
          done
        "
      fi
      ;;
    start|up)
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME}}"
      echo "Starting $service_name..."
      if command -v systemctl >/dev/null 2>&1 && systemctl --quiet is-enabled "$service_name" 2>/dev/null || systemctl --user --quiet is-enabled "$service_name" 2>/dev/null; then
        if systemctl --user --quiet is-enabled "$service_name" 2>/dev/null; then
          systemctl --user start "$service_name"
        else
          sudo systemctl start "$service_name"
        fi
      elif command -v rc-service >/dev/null 2>&1; then
        sudo rc-service "$service_name" start
      elif command -v sc.exe >/dev/null 2>&1; then
        sc.exe start "$service_name"
      else
        echo "Error: Service $service_name is not installed or service manager not found." >&2
        exit 1
      fi
      ;;
    stop|down)
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME}}"
      echo "Stopping $service_name..."
      if command -v systemctl >/dev/null 2>&1 && systemctl --quiet is-enabled "$service_name" 2>/dev/null || systemctl --user --quiet is-enabled "$service_name" 2>/dev/null; then
        if systemctl --user --quiet is-enabled "$service_name" 2>/dev/null; then
          systemctl --user stop "$service_name"
        else
          sudo systemctl stop "$service_name"
        fi
      elif command -v rc-service >/dev/null 2>&1; then
        sudo rc-service "$service_name" stop
      elif command -v sc.exe >/dev/null 2>&1; then
        sc.exe stop "$service_name"
      else
        echo "Error: Service $service_name is not installed or service manager not found." >&2
        exit 1
      fi
      ;;
    restart)
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME}}"
      echo "Restarting $service_name..."
      if command -v systemctl >/dev/null 2>&1 && systemctl --quiet is-enabled "$service_name" 2>/dev/null || systemctl --user --quiet is-enabled "$service_name" 2>/dev/null; then
        if systemctl --user --quiet is-enabled "$service_name" 2>/dev/null; then
          systemctl --user restart "$service_name"
        else
          sudo systemctl restart "$service_name"
        fi
      elif command -v rc-service >/dev/null 2>&1; then
        sudo rc-service "$service_name" restart
      elif command -v sc.exe >/dev/null 2>&1; then
        sc.exe stop "$service_name"
        sleep 2
        sc.exe start "$service_name"
      else
        echo "Error: Service $service_name is not installed or service manager not found." >&2
        exit 1
      fi
      ;;
    health)
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME}}"
      json_file="libscript.json"
      healthcheck=""
      if [ -f "$json_file" ] && command -v jq >/dev/null 2>&1; then
        healthcheck=$(jq -c "if (.deps[\"$PACKAGE_NAME\"] | type) == \"object\" and .deps[\"$PACKAGE_NAME\"].healthcheck != null then .deps[\"$PACKAGE_NAME\"].healthcheck else empty end" "$json_file" 2>/dev/null)
      fi
      if [ -n "$healthcheck" ]; then
        test_cmd=$(echo "$healthcheck" | jq -r 'if type == "string" then . elif type == "object" and .test then (if (.test | type) == "array" then (if .test[0] == "CMD-SHELL" then .test[1] else .test | join(" ") end) else .test end) else empty end' 2>/dev/null)
        if [ -n "$test_cmd" ] && [ "$test_cmd" != "null" ]; then
          if sh -c "$test_cmd"; then
            echo "Status: healthy"
            exit 0
          else
            echo "Status: unhealthy"
            exit 1
          fi
        fi
      fi
      # Fall back to status if no healthcheck is defined
      echo "No healthcheck defined, checking status..."; "$0" "status" "$PACKAGE_NAME" "$VERSION" "$@"
      ;;
    status)
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME}}"
      if command -v systemctl >/dev/null 2>&1 && systemctl --quiet is-enabled "$service_name" 2>/dev/null || systemctl --user --quiet is-enabled "$service_name" 2>/dev/null; then
        if systemctl --user --quiet is-enabled "$service_name" 2>/dev/null; then
          systemctl --user status "$service_name" --no-pager
        else
          sudo systemctl status "$service_name" --no-pager
        fi
      elif command -v rc-service >/dev/null 2>&1; then
        sudo rc-service "$service_name" status
      elif command -v sc.exe >/dev/null 2>&1; then
        sc.exe query "$service_name"
      else
        echo "Error: Service $service_name is not installed or service manager not found." >&2
        exit 1
      fi
      ;;
    logs)
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME}}"
      follow=0
      for arg in "$@"; do
        if [ "$arg" = "-f" ] || [ "$arg" = "--follow" ]; then
          follow=1
        fi
      done

      if command -v journalctl >/dev/null 2>&1; then
        journalctl_args="-n 50 --no-pager"
        if [ "$follow" = "1" ]; then
          journalctl_args="-n 50 -f"
        fi
        if systemctl --user --quiet is-enabled "$service_name" 2>/dev/null; then
          journalctl --user -u "$service_name" "$journalctl_args"
        else
          sudo journalctl -u "$service_name" "$journalctl_args"
        fi
      else
        LOGS_DIR="${LOGS_DIR:-$LIBSCRIPT_ROOT_DIR/logs}"
        log_file="$LOGS_DIR/${service_name}.log"
        if [ -f "$log_file" ]; then
          if [ "$follow" = "1" ]; then
            tail -n 50 -f "$log_file"
          else
            tail -n 50 "$log_file"
          fi
        else
          echo "No logs found at $log_file"
        fi
      fi
      ;;
    serve)
      if [ ! -x "$BIN_PATH" ]; then
        echo "Error: $PACKAGE_NAME version $VERSION not installed at $BIN_PATH"
        exit 1
      fi
      SERVE_FROM="${SERVE_FROM:-${serve_from:-background-process}}"
      LOGS_DIR="${LOGS_DIR:-${logs_dir:-$LIBSCRIPT_ROOT_DIR/logs}}"
      if [ "$SERVE_FROM" = "background-process" ]; then
        mkdir -p "$LOGS_DIR"
        service_name="${LIBSCRIPT_SERVICE_NAME:-${PACKAGE_NAME}_${VERSION}}"
        log_file="$LOGS_DIR/${service_name}.log"
        log_driver="${LIBSCRIPT_LOG_DRIVER:-file}"
        echo "Starting $service_name in background (log driver: $log_driver)..."
        
        if [ "$log_driver" = "file" ]; then
          nohup "$BIN_PATH" "$@" > "$log_file" 2>&1 &
          echo "PID: $!"
          echo "Logs: $log_file"
        elif [ "$log_driver" = "json_file" ]; then
          if command -v jq >/dev/null 2>&1; then
            nohup sh -c 'CMD="$0"; TAG="$1"; OUT="$2"; shift 2; exec "$CMD" "$@" 2>&1 | jq -R -c --unbuffered --arg svc "$TAG" "{service: \$svc, message: .}" >> "$OUT"' "$BIN_PATH" "$service_name" "${log_file}.json" "$@" &
          else
            nohup sh -c 'CMD="$0"; TAG="$1"; OUT="$2"; shift 2; exec "$CMD" "$@" 2>&1 | awk -v svc="$TAG" '\''{ gsub(/\\/, "\\\\"); gsub(/"/, "\\\""); gsub(/\r/, ""); gsub(/\t/, "\\t"); printf "{\"service\":\"%s\",\"message\":\"%s\"}\n", svc, $0; fflush(); }'\'' >> "$OUT"' "$BIN_PATH" "$service_name" "${log_file}.json" "$@" &
          fi
          echo "PID: $!"
          echo "Logs: ${log_file}.json"
        elif [ "$log_driver" = "tcp" ] || [ "$log_driver" = "fluentbit" ]; then
          host="${LIBSCRIPT_LOG_HOST:-127.0.0.1}"
          port="${LIBSCRIPT_LOG_PORT:-5170}"
          if command -v jq >/dev/null 2>&1; then
            nohup sh -c 'CMD="$0"; TAG="$1"; HOST="$2"; PORT="$3"; shift 3; exec "$CMD" "$@" 2>&1 | jq -R -c --unbuffered --arg svc "$TAG" "{service: \$svc, message: .}" | nc "$HOST" "$PORT"' "$BIN_PATH" "$service_name" "$host" "$port" "$@" &
          else
            nohup sh -c 'CMD="$0"; TAG="$1"; HOST="$2"; PORT="$3"; shift 3; exec "$CMD" "$@" 2>&1 | awk -v svc="$TAG" '\''{ gsub(/\\/, "\\\\"); gsub(/"/, "\\\""); gsub(/\r/, ""); gsub(/\t/, "\\t"); printf "{\"service\":\"%s\",\"message\":\"%s\"}\n", svc, $0; fflush(); }'\'' | nc "$HOST" "$PORT"' "$BIN_PATH" "$service_name" "$host" "$port" "$@" &
          fi
          echo "PID: $!"
          echo "Logs streaming to tcp://$host:$port"
        elif [ "$log_driver" = "syslog" ]; then
          nohup sh -c 'CMD="$0"; TAG="$1"; shift 1; exec "$CMD" "$@" 2>&1 | logger -t "$TAG"' "$BIN_PATH" "$service_name" "$@" &
          echo "PID: $!"
          echo "Logs sent to syslog"
        elif [ "$log_driver" = "custom" ]; then
          if [ -z "$LIBSCRIPT_LOG_CMD" ]; then
            echo "Error: LIBSCRIPT_LOG_CMD is required for custom log driver" >&2
            exit 1
          fi
          nohup sh -c 'CMD="$0"; LCMD="$1"; shift 1; eval "exec \"$CMD\" \"$@\" 2>&1 | $LCMD"' "$BIN_PATH" "$LIBSCRIPT_LOG_CMD" "$@" &
          echo "PID: $!"
        else
          echo "Error: Unknown log driver '$log_driver'" >&2
          exit 1
        fi
      else
        echo "Error: serve_from '$SERVE_FROM' is not fully implemented yet." >&2
        exit 1
      fi
      ;;
    route)
      if [ -x "$SCRIPT_DIR/route.sh" ]; then
        exec "$SCRIPT_DIR/route.sh" "$@"
      elif [ -f "$SCRIPT_DIR/route.sh" ]; then
        exec sh "$SCRIPT_DIR/route.sh" "$@"
      else
        echo "Info: Route action is not natively supported for $PACKAGE_NAME yet (no route.sh found)." >&2
        exit 0
      fi
      ;;
    ls)
      if [ -d "$INSTALLED_DIR" ]; then
        echo "Installed at $INSTALLED_DIR:"
        /bin/ls -1 "$INSTALLED_DIR"
      else
        echo "Error: No installed versions found at $INSTALLED_DIR or listing is not natively supported for this package." >&2
        exit 1
      fi
      ;;
    ls-remote)
      echo "Error: Remote listing not natively supported for generic packages yet." >&2
      exit 1
      ;;
    download)
      if [ -x "$SCRIPT_DIR/download.sh" ]; then
        exec "$SCRIPT_DIR/download.sh"
      elif [ -f "$SCRIPT_DIR/download.sh" ]; then
        exec sh "$SCRIPT_DIR/download.sh"
      else
        echo "Info: Download action is not natively supported for $PACKAGE_NAME yet (no download.sh found)." >&2
        exit 0
      fi
      ;;
    uninstall|remove|uninstall_daemon|uninstall_service|remove_daemon|remove_service)
      if [ -x "$SCRIPT_DIR/uninstall.sh" ]; then
        exec "$SCRIPT_DIR/uninstall.sh"
      elif [ -f "$SCRIPT_DIR/uninstall.sh" ]; then
        exec sh "$SCRIPT_DIR/uninstall.sh"
      elif [ -x "$LIBSCRIPT_ROOT_DIR/_lib/_common/uninstall.sh" ]; then
        exec "$LIBSCRIPT_ROOT_DIR/_lib/_common/uninstall.sh"
      elif [ -f "$LIBSCRIPT_ROOT_DIR/_lib/_common/uninstall.sh" ]; then
        exec sh "$LIBSCRIPT_ROOT_DIR/_lib/_common/uninstall.sh"
      else
        echo "Error: Uninstallation is not natively supported for this package yet." >&2
        exit 1
      fi
      ;;
  esac
  exit 0
fi

# Run setup
run_setup() {
  if [ -x "$SCRIPT_DIR/setup.sh" ]; then
    "$SCRIPT_DIR/setup.sh"
  elif [ -f "$SCRIPT_DIR/setup.sh" ]; then
    sh "$SCRIPT_DIR/setup.sh"
  else
    echo "Error: setup.sh not found in $SCRIPT_DIR"
    exit 1
  fi
}

if [ "$ACTION" = "install" ] || [ "$ACTION" = "install_daemon" ] || [ "$ACTION" = "install_service" ]; then
  if [ -z "${LIBSCRIPT_ROOT_DIR:-}" ]; then
    _d="$SCRIPT_DIR"
    while [ ! -f "$_d/ROOT" ] && [ "$_d" != "/" ]; do _d="$(dirname "$_d")"; done
    if [ -f "$_d/ROOT" ]; then LIBSCRIPT_ROOT_DIR="$_d"; else LIBSCRIPT_ROOT_DIR="."; fi
    export LIBSCRIPT_ROOT_DIR
  fi

  if [ -f "$SCHEMA_FILE" ] && command -v jq >/dev/null 2>&1; then
    _deps=$(jq -r '.properties | to_entries[] | select(.value.is_libscript_dependency == true) | "\(.key)|\(.value.default // "")|\(if .value.enum then .value.enum | join(",") else "" end)"' "$SCHEMA_FILE" 2>/dev/null)
    if [ -n "$_deps" ]; then
      while IFS='|' read -r dep_key dep_default dep_enum; do
        if [ -z "$dep_key" ]; then continue; fi
        eval "dep_val=\"\${$dep_key:-}\""
        if [ -z "$dep_val" ]; then
          dep_val="$dep_default"
          export "$dep_key"="$dep_val"
        fi
        if [ -n "$dep_val" ]; then
          eval "strategy_val=\"\${${dep_key}_STRATEGY:-}\""
          if [ -z "$strategy_val" ]; then
            strategy_val="reuse"
            export "${dep_key}_STRATEGY"="$strategy_val"
          fi
          echo "Checking dependency $dep_val for $dep_key (strategy: $strategy_val)..."
          is_installed=0
          if command -v "$dep_val" >/dev/null 2>&1 || "$LIBSCRIPT_ROOT_DIR/libscript.sh" which "$dep_val" "latest" >/dev/null 2>&1; then
            is_installed=1
          fi
          if [ "$is_installed" = "1" ]; then
            if [ "$strategy_val" = "overwrite" ] || [ "$strategy_val" = "upgrade" ] || [ "$strategy_val" = "downgrade" ]; then
              echo "Re-installing existing dependency $dep_val..."
              if ! "$LIBSCRIPT_ROOT_DIR/libscript.sh" install "$dep_val" "latest"; then
                echo "Error: Failed to re-install dependency $dep_val" >&2
                exit 1
              fi
            elif [ "$strategy_val" = "install-alongside" ]; then
              echo "Installing $dep_val alongside existing..."
              if ! "$LIBSCRIPT_ROOT_DIR/libscript.sh" install "$dep_val" "latest"; then
                echo "Error: Failed to install dependency $dep_val" >&2
                exit 1
              fi
            else
              echo "Reusing existing dependency $dep_val."
            fi
          else
            echo "Installing missing dependency $dep_val..."
            if ! "$LIBSCRIPT_ROOT_DIR/libscript.sh" install "$dep_val" "latest"; then
              echo "Error: Failed to install dependency $dep_val" >&2
              exit 1
            fi
          fi
        fi
      done <<EOF
$_deps
EOF
    fi
  fi

  if [ -n "$LIBSCRIPT_SECRETS" ]; then
    run_setup
    
    if echo "$LIBSCRIPT_SECRETS" | grep -q "^http"; then
      if command -v jq >/dev/null; then
         json_data=$(FORMAT=docker_compose "$0" env "$PACKAGE_NAME" "$VERSION" | grep -vE '^(PATH=)' | jq -R 'split("=") | {(.[0]): (.[1:] | join("="))} ' | jq -s 'add | {data: .}')
         curl -s -k -X POST -H "X-Vault-Token: ${VAULT_TOKEN:-}" -H "Content-Type: application/json" -d "$json_data" "$LIBSCRIPT_SECRETS/${PACKAGE_NAME}_${VERSION}" || true
      else
         echo "Warning: jq is required for saving secrets to OpenBao/Vault" >&2
      fi
    else
      mkdir -p "$LIBSCRIPT_SECRETS"
      FORMAT=sh "$0" env "$PACKAGE_NAME" "$VERSION" >> "$LIBSCRIPT_SECRETS/env.sh"
      FORMAT=csh "$0" env "$PACKAGE_NAME" "$VERSION" >> "$LIBSCRIPT_SECRETS/env.csh"
      FORMAT=powershell "$0" env "$PACKAGE_NAME" "$VERSION" >> "$LIBSCRIPT_SECRETS/env.ps1"
      FORMAT=docker "$0" env "$PACKAGE_NAME" "$VERSION" >> "$LIBSCRIPT_SECRETS/env.docker"
      FORMAT=docker_compose "$0" env "$PACKAGE_NAME" "$VERSION" >> "$LIBSCRIPT_SECRETS/env.env"
      FORMAT=cmd "$0" env "$PACKAGE_NAME" "$VERSION" >> "$LIBSCRIPT_SECRETS/env.cmd"
    fi
    exit 0
  fi
fi

if [ -x "$SCRIPT_DIR/setup.sh" ]; then
  exec "$SCRIPT_DIR/setup.sh"
elif [ -f "$SCRIPT_DIR/setup.sh" ]; then
  exec sh "$SCRIPT_DIR/setup.sh"
else
  echo "Error: setup.sh not found in $SCRIPT_DIR"
  exit 1
fi
