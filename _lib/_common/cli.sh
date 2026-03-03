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
  run|which|exec)
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
  ls|ls-remote)
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

if [ "$ACTION" = "run" ] || [ "$ACTION" = "which" ] || [ "$ACTION" = "exec" ] || [ "$ACTION" = "ls" ] || [ "$ACTION" = "ls-remote" ]; then
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
    ls)
      if [ -d "$INSTALLED_DIR" ]; then
        echo "Installed at $INSTALLED_DIR:"
        /bin/ls -1 "$INSTALLED_DIR"
      else
        echo "No installed versions found at $INSTALLED_DIR"
      fi
      ;;
    ls-remote)
      echo "Remote listing not natively supported for generic packages yet."
      ;;
  esac
  exit 0
fi

# Run setup
if [ -x "$SCRIPT_DIR/setup.sh" ]; then
  exec "$SCRIPT_DIR/setup.sh"
elif [ -f "$SCRIPT_DIR/setup.sh" ]; then
  exec sh "$SCRIPT_DIR/setup.sh"
else
  echo "Error: setup.sh not found in $SCRIPT_DIR"
  exit 1
fi
