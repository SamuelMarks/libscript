#!/bin/sh
# # LibScript Component Core Module
#
# ## Overview
# This module provides the unified CLI routing and lifecycle management logic 
# for LibScript components. It eliminates redundancy by centralizing the 
# 600+ lines of boilerplate previously duplicated in every component's `cli.sh`.
#
# ## Usage
# In your component's `cli.sh`, set the `PACKAGE_NAME` and source this file:
#
# ```sh
# #!/bin/sh
# PACKAGE_NAME="my-component"
# . "$(dirname "$0")/../../_common/component_core.sh"
# ```
#
# ## Requirements
# - A `vars.schema.json` in the component directory for dynamic argument parsing.
# - A `setup.sh` in the component directory for installation logic.

set -e

# Identify directories
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(d="${SCRIPT_DIR}"; while [ ! -f "${d}"'/ROOT' ]; do d="$(dirname -- "${d}")"; done; printf '%s' "${d}")}"

# Source logging
. "$LIBSCRIPT_ROOT_DIR/_lib/_common/log.sh"

# Source service management
. "$LIBSCRIPT_ROOT_DIR/_lib/_common/service.sh"

# Source environment printer
. "$LIBSCRIPT_ROOT_DIR/_lib/_common/env_printer.sh"

SCHEMA_FILE="$SCRIPT_DIR/vars.schema.json"
MANIFEST_FILE="$SCRIPT_DIR/manifest.json"
BASE_SCHEMA_FILE="$LIBSCRIPT_ROOT_DIR/_lib/_common/base_vars.schema.json"

# Utility function to get the merged schema properties
get_merged_properties() {
  if [ -f "$SCHEMA_FILE" ] && [ -f "$BASE_SCHEMA_FILE" ]; then
    jq -n --argjson base "$(cat "$BASE_SCHEMA_FILE")" --argjson comp "$(cat "$SCHEMA_FILE")" '
      $base.properties * $comp.properties
    '
  elif [ -f "$SCHEMA_FILE" ]; then
    jq -r '.properties' "$SCHEMA_FILE"
  elif [ -f "$BASE_SCHEMA_FILE" ]; then
    jq -r '.properties' "$BASE_SCHEMA_FILE"
  else
    echo "{}"
  fi
}

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
  if command -v jq >/dev/null 2>&1 && [ -f "$MANIFEST_FILE" ]; then
    DESC=$(jq -r 'if .description then .description else "" end' "$MANIFEST_FILE")
    TITLE=$(jq -r 'if .title then .title else "" end' "$MANIFEST_FILE")
    if [ -n "$TITLE" ] && [ -n "$DESC" ]; then
      echo "  $TITLE: $DESC"
    elif [ -n "$TITLE" ]; then
      echo "  $TITLE"
    elif [ -n "$DESC" ]; then
      echo "  $DESC"
    fi
    
    VERSIONS=$(jq -r 'if .versions then .versions | join(", ") else "" end' "$MANIFEST_FILE")
    [ -n "$VERSIONS" ] && echo "  Supported Versions: $VERSIONS"
  fi
  echo ""
  echo "Available Options:"
  if command -v jq >/dev/null 2>&1; then
    _props=$(get_merged_properties)
    echo "$_props" | jq -r '
      to_entries[] | 
      def aliases: if .value.versionAliases then " [aliases: " + (.value.versionAliases | join(", ")) + "]" else "" end;
      "--\(.key)=VALUE|\(.value.description // "")\(aliases) [default: \(.value.default // "none")]"
    ' | awk -F'|' '{printf "  %-35s %s\n", $1, $2}'
    
    echo "$_props" | jq -r '
      to_entries[] | select(.value.is_libscript_dependency == true) |
      "--\(.key)_STRATEGY=VALUE|Strategy for \(.key) (reuse, install-alongside, upgrade, downgrade, overwrite) [default: reuse]"
    ' | awk -F'|' '{printf "  %-35s %s\n", $1, $2}'
  else
    echo "  (jq is required to parse vars.schema.json for dynamic options)"
    echo "  See $SCHEMA_FILE for available variables."
  fi
  echo ""
  echo "  --help, -h, /?                      Show this help message"
  echo "  --version, -v                       Show version"
  echo ""
}

ACTION=""
VERSION=""

# Input validation and basic routing
case "$1" in
  --help|-h|/\?|"-?")
    show_help
    exit 0
    ;;
  --version|-v)
    echo "${LIBSCRIPT_VERSION:-dev}"
    exit 0
    ;;
  install|install_daemon|install_service|uninstall_daemon|uninstall_service|remove_daemon|remove_service|run|which|exec|env|serve|route)
    ACTION="$1"
    # $2 is PACKAGE_NAME (usually matches our component name)
    VERSION="$3"
    if [ -z "$2" ]; then
      echo "Error: package_name is required for $ACTION" >&2
      exit 1
    fi
    if [ -z "$VERSION" ]; then
      echo "Error: version is required for $ACTION" >&2
      exit 1
    fi
    shift 3
    ;;
  ls|ls-remote|download|remove|uninstall|status|health|test|start|stop|restart|logs|up|down)
    ACTION="$1"
    VERSION="$3"
    if [ -z "$2" ]; then
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

# Auto-set component version variable (e.g. NODEJS_VERSION)
if [ -n "$PACKAGE_NAME" ] && [ -n "$VERSION" ]; then
  pkg_upper=$(echo "${PACKAGE_NAME##*/}" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
  var_name="${pkg_upper}_VERSION"
  export "$var_name"="$VERSION"
fi

if [ "$VERSION" = "latest" ] || [ "$VERSION" = "lts" ] || [ "$VERSION" = "stable" ]; then
  export LIBSCRIPT_NEVER_REFRESH_CHECKSUM_DB=1
fi

# Argument parsing loop
while [ $# -gt 0 ]; do
  # These actions stop parsing and pass remaining args to sub-scripts
  if [ "$ACTION" = "start" ] || [ "$ACTION" = "stop" ] || [ "$ACTION" = "restart" ] || [ "$ACTION" = "status" ] || [ "$ACTION" = "health" ] || [ "$ACTION" = "logs" ] || [ "$ACTION" = "up" ] || [ "$ACTION" = "down" ] || [ "$ACTION" = "run" ] || [ "$ACTION" = "exec" ]; then
    break
  fi
  case "$1" in
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
    --secrets=*)
      export LIBSCRIPT_SECRETS="${1#*=}"
      shift
      ;;
    --*)
      # Dynamic flag parsing from vars.schema.json
      key=$(echo "${1#--}" | cut -d= -f1)
      val=$(echo "${1#--}" | cut -d= -f2-)
      [ "$key" = "$1" ] && key="${1#--}" # Handle case where there is no =
      if [ "$key" = "$val" ]; then val="true"; fi

      # Validate key and value against schema
      if command -v jq >/dev/null 2>&1; then
        _props=$(get_merged_properties)
        
        # Check if key exists
        if ! echo "$_props" | jq -e ".\"$key\"" >/dev/null 2>&1; then
          # Check for _STRATEGY suffix which is also allowed for dependencies
          if echo "$key" | grep -q "_STRATEGY$" && echo "$_props" | jq -e ".\"${key%_STRATEGY}\"" >/dev/null 2>&1; then
            export "$key"="$val"
          else
            echo "Error: Unknown option --$key" >&2
            exit 1
          fi
        else
          # Validate enum if it exists
          _enum=$(echo "$_props" | jq -c ".\"$key\".enum // empty")
          if [ -n "$_enum" ]; then
            if ! echo "$_enum" | jq -e ". | contains([\"$val\"])" >/dev/null 2>&1; then
              echo "Error: Invalid value '$val' for --$key. Allowed values are: $(echo "$_enum" | jq -r 'join(", ")')" >&2
              exit 1
            fi
          fi
          export "$key"="$val"
        fi
      else
        # If jq is not available, we can only warn or just set it. 
        # Project policy seems to prefer strictness if possible, but without jq we can't be strict.
        export "$key"="$val"
      fi
      shift
      ;;
    *)
      shift
      ;;
  esac
done

# Automated Dependency Resolution
if [ "${LIBSCRIPT_SKIP_DEPENDENCIES:-}" != "1" ] && { [ "$ACTION" = "install" ] || [ "$ACTION" = "setup" ]; }; then
  if command -v jq >/dev/null 2>&1 && [ -f "$SCHEMA_FILE" ]; then
    _deps=$(get_merged_properties | jq -r 'to_entries[] | select(.value.is_libscript_dependency == true) | "\(.key)|\(.value.default // "")"' 2>/dev/null)
    if [ -n "$_deps" ]; then
      echo "$_deps" | while IFS='|' read -r dep_key dep_default; do
        [ -z "$dep_key" ] && continue
        eval "dep_val=\"\${$dep_key:-}\""
        if [ -z "$dep_val" ]; then
          dep_val="$dep_default"
          export "$dep_key"="$dep_val"
        fi
        [ -z "$dep_val" ] && continue
        
        eval "strategy_val=\"\${${dep_key}_STRATEGY:-reuse}\""
        log_info "Resolving dependency: $dep_val (strategy: $strategy_val)"
        
        is_installed=0
        if command -v "$dep_val" >/dev/null 2>&1 || "$LIBSCRIPT_ROOT_DIR/libscript.sh" which "$dep_val" "latest" >/dev/null 2>&1; then
          is_installed=1
        fi
        
        do_install=0
        if [ "$is_installed" = "0" ]; then
          do_install=1
        elif [ "$strategy_val" = "overwrite" ] || [ "$strategy_val" = "upgrade" ] || [ "$strategy_val" = "downgrade" ] || [ "$strategy_val" = "install-alongside" ]; then
          do_install=1
        fi
        
        if [ "$do_install" = "1" ]; then
          log_info "Installing dependency $dep_val..."
          LIBSCRIPT_SKIP_DEPENDENCIES=1 "$LIBSCRIPT_ROOT_DIR/libscript.sh" install "$dep_val" "latest" || {
            log_error "Failed to install dependency $dep_val"
            exit 1
          }
        else
          log_info "Dependency $dep_val already satisfied."
        fi
      done
    fi
  fi
fi

# Lifecycle routing
if [ "$ACTION" = "test" ]; then
  if [ -x "$SCRIPT_DIR/test.sh" ]; then
    exec "$SCRIPT_DIR/test.sh"
  else
    echo "Error: test.sh not found in $SCRIPT_DIR"
    exit 1
  fi
elif [ "$ACTION" = "uninstall" ] || [ "$ACTION" = "remove" ]; then
  if [ -x "$SCRIPT_DIR/uninstall.sh" ]; then
    exec "$SCRIPT_DIR/uninstall.sh"
  else
    echo "Error: uninstall.sh not found in $SCRIPT_DIR"
    exit 1
  fi
elif [ "$ACTION" = "start" ] || [ "$ACTION" = "stop" ] || [ "$ACTION" = "restart" ] || [ "$ACTION" = "status" ] || [ "$ACTION" = "health" ] || [ "$ACTION" = "logs" ] || [ "$ACTION" = "up" ] || [ "$ACTION" = "down" ]; then
  service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME}}"
  libscript_service "$ACTION" "$service_name" "$@"
  exit 0
elif [ "$ACTION" = "env" ]; then
  INSTALLED_DIR="${PREFIX:-$LIBSCRIPT_ROOT_DIR/installed/$PACKAGE_NAME}"
  libscript_print_env "${FORMAT:-${format:-sh}}" "$INSTALLED_DIR"
  exit 0
elif [ "$ACTION" = "run" ]; then
  INSTALLED_DIR="${PREFIX:-$LIBSCRIPT_ROOT_DIR/installed/$PACKAGE_NAME}"
  BIN_PATH="$INSTALLED_DIR/bin/$PACKAGE_NAME"
  if [ ! -x "$BIN_PATH" ]; then
    log_error "$PACKAGE_NAME version $VERSION not installed at $BIN_PATH"
    exit 1
  fi
  exec "$BIN_PATH" "$@"
elif [ "$ACTION" = "which" ]; then
  INSTALLED_DIR="${PREFIX:-$LIBSCRIPT_ROOT_DIR/installed/$PACKAGE_NAME}"
  BIN_PATH="$INSTALLED_DIR/bin/$PACKAGE_NAME"
  if [ -x "$BIN_PATH" ]; then
    echo "$BIN_PATH"
  else
    log_error "Not installed: $BIN_PATH"
    exit 1
  fi
elif [ "$ACTION" = "exec" ]; then
  INSTALLED_DIR="${PREFIX:-$LIBSCRIPT_ROOT_DIR/installed/$PACKAGE_NAME}"
  if [ ! -d "$INSTALLED_DIR/bin" ]; then
    log_error "$PACKAGE_NAME version $VERSION bin directory not found at $INSTALLED_DIR/bin"
    exit 1
  fi
  export PATH="$INSTALLED_DIR/bin:$PATH"
  exec "$@"
fi

# Default to setup.sh for installation and other actions
if [ -x "$SCRIPT_DIR/setup.sh" ]; then
  exec "$SCRIPT_DIR/setup.sh"
elif [ -f "$SCRIPT_DIR/setup.sh" ]; then
  exec sh "$SCRIPT_DIR/setup.sh"
else
  echo "Error: setup.sh not found in $SCRIPT_DIR"
  exit 1
fi
