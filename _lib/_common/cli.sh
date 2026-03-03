#!/bin/sh
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
  else
    echo "  (jq is required to parse vars.schema.json for dynamic options)"
    echo "  See $SCHEMA_FILE for available variables."
  fi
  echo ""
  echo "  --prefix=<dir>                      Set local installation prefix"
  echo "  --service-name=<name>               Set a custom service/daemon name"
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
  remove|uninstall|status|test)
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
  pkg_upper=$(echo "$PACKAGE_NAME" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
  var_name="${pkg_upper}_VERSION"
  export "$var_name"="$VERSION"
fi

# Parse remaining args
while [ $# -gt 0 ]; do
  if [ "$ACTION" = "run" ] || [ "$ACTION" = "exec" ]; then
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

if [ "$ACTION" = "run" ] || [ "$ACTION" = "which" ] || [ "$ACTION" = "exec" ] || [ "$ACTION" = "env" ] || [ "$ACTION" = "serve" ] || [ "$ACTION" = "route" ] || [ "$ACTION" = "ls" ] || [ "$ACTION" = "ls-remote" ] || [ "$ACTION" = "download" ] || [ "$ACTION" = "uninstall" ] || [ "$ACTION" = "remove" ] || [ "$ACTION" = "uninstall_daemon" ] || [ "$ACTION" = "uninstall_service" ] || [ "$ACTION" = "remove_daemon" ] || [ "$ACTION" = "remove_service" ]; then
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
        echo "Starting $service_name in background..."
        nohup "$BIN_PATH" "$@" > "$log_file" 2>&1 &
        echo "PID: $!"
        echo "Logs: $log_file"
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
