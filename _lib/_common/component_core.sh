#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  THIS_FILE="${(%):-%x}"
  set -o pipefail
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
# # LibScript Component Core Module
#
# ## Overview
# This module provides the unified CLI routing and lifecycle management logic
# for LibScript components. It eliminates redundancy by centralizing the
# 600+ lines of boilerplate previously duplicated in every component's `cli.sh`.
#
# ## Usage
# In your component's `cli.sh`, source this file:
#
# ```sh
# #!/bin/sh
# # PACKAGE_NAME is inferred from directory name
# # (Optional: set PACKAGE_NAME="my-component" to override)
# for LIB in "_lib/_common/component_core.sh" ${_LIBSCRIPT_DUMMY_NO_RUN:-}; do
#   SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
#   export SCRIPT_NAME
#   # shellcheck disable=SC1090
#   . "${SCRIPT_NAME}"
# done
# ```
#
# ## Requirements
# - A `vars.schema.json` in the component directory for dynamic argument parsing.
# - A `setup.sh` in the component directory for installation logic.


# Identify directories
COMP_DIR="${SCRIPT_DIR:-$(cd "$(dirname -- "${THIS_FILE}")" && pwd)}"
SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname -- "${THIS_FILE}")" && pwd)}"
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export LIBSCRIPT_ROOT_DIR

# Source logging
. "$LIBSCRIPT_ROOT_DIR/_lib/_common/log.sh"

# Source service management
. "$LIBSCRIPT_ROOT_DIR/_lib/_common/service.sh"

# Source environment printer
. "$LIBSCRIPT_ROOT_DIR/_lib/_common/env_printer.sh"

SCHEMA_FILE="$COMP_DIR/vars.schema.json"
MANIFEST_FILE="$COMP_DIR/manifest.json"
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
    log_info "{}"
  fi
}

# ## show_help
# Executes show_help functionality.
show_help() {
  log_info "Usage: $0 [COMMAND] [PACKAGE_NAME] [VERSION] [OPTIONS]"
  log_info ""
  log_info "Commands:"
  log_info "  install <package_name> <version>"
  log_info "  use <package_name> <version>"
  log_info "  remove <package_name> [version]"
  log_info "  uninstall <package_name> [version]"
  log_info "  install-service <package_name> <version>"
  log_info "  uninstall-service <package_name> <version>"
  log_info "  status <package_name> [version]"
  log_info "  health <package_name> [version]"
  log_info "  start <package_name> [version]"
  log_info "  stop <package_name> [version]"
  log_info "  restart <package_name> [version]"
  log_info "  logs <package_name> [version] [-f|--follow]"
  log_info "  up <package_name> [version]"
  log_info "  down <package_name> [version]"
  log_info "  test <package_name> [version]"
  log_info "  run <package_name> <version> [args...]"
  log_info "  which <package_name> <version>"
  log_info "  exec <package_name> <version> <cmd> [args...]"
  log_info "  ls <package_name>"
  log_info "  download <package_name> <version>"
  log_info "  ls-remote <package_name> [version]"
  log_info ""
  log_info "Description:"
  if command -v jq >/dev/null 2>&1 && [ -f "$MANIFEST_FILE" ]; then
    DESC=$(jq -r 'if .description then .description else "" end' "$MANIFEST_FILE")
    TITLE=$(jq -r 'if .title then .title else "" end' "$MANIFEST_FILE")
    if [ -n "$TITLE" ] && [ -n "$DESC" ]; then
      log_info "  $TITLE: $DESC"
    elif [ -n "$TITLE" ]; then
      log_info "  $TITLE"
    elif [ -n "$DESC" ]; then
      log_info "  $DESC"
    fi

    VERSIONS=$(jq -r 'if .versions then .versions | join(", ") else "" end' "$MANIFEST_FILE")
    [ -n "$VERSIONS" ] && printf '%s\n' "  Supported Versions: $VERSIONS"
  fi
  log_info ""
  log_info "Available Options:"
  if command -v jq >/dev/null 2>&1; then
    _props=$(get_merged_properties)
    printf '%s\n' "$_props" | jq -r '
      to_entries[] |
      def aliases: if .value.version_aliases then " [aliases: " + (.value.version_aliases | join(", ")) + "]" else "" end;
      "--\(.key)=VALUE|\(.value.description // "")\(aliases) [default: \(.value.default // "none")]"
    ' | awk -F'|' '{printf "  %-35s %s\n", $1, $2}'

    printf '%s\n' "$_props" | jq -r '
      to_entries[] | select(.value.is_libscript_dependency == true) |
      "--\(.key)_STRATEGY=VALUE|Strategy for \(.key) (reuse, install-alongside, upgrade, downgrade, overwrite) [default: reuse]"
    ' | awk -F'|' '{printf "  %-35s %s\n", $1, $2}'
  else
    log_info "  (jq is required to parse vars.schema.json for dynamic options)"
    log_info "  See $SCHEMA_FILE for available variables."
  fi
  log_info ""
  log_info "  --help, -h, /?                      Show this help message"
  log_info "  --version, -v                       Show version"
  log_info ""
}

ACTION=""
VERSION=""

# Input validation and basic routing
case "${1:-}" in
  --help|-h|/\?|"-?")
    show_help
    exit 0
    ;;
  --version|-v)
    log_info "${LIBSCRIPT_VERSION:-dev}"
    exit 0
    ;;
  info|install|use|install-service|uninstall-service|run|which|exec|env|serve|route)
    ACTION="${1:-}"
    if [ -n "${3:-}" ]; then
      PACKAGE_NAME="${2:-}"
      VERSION="${3:-}"
      shift 3
    elif [ -n "${2:-}" ]; then
      if [ -z "${PACKAGE_NAME:-}" ]; then
        PACKAGE_NAME="$(basename "$COMP_DIR")"
      fi
      if [ "${2:-}" = "${PACKAGE_NAME:-}" ] || [ "${2:-}" = "$(basename "$COMP_DIR")" ]; then
        VERSION="latest"
      else
        VERSION="${2:-}"
      fi
      shift 2
    else
      printf '%s\n' "Error: version is required for $ACTION" >&2
      exit 1
    fi
    ;;
  auth*|location*|network*|node*|dns*|firewall*|ssh*|backup*|restore*|diff*|list-managed*|storage*|aws*|azure*|gcp*|cleanup*)
    ACTION="${1:-}"
    shift
    ;;
  info|ls|ls-remote|download|remove|uninstall|status|health|test|start|stop|restart|logs|up|down)
    ACTION="${1:-}"
    if [ -n "${3:-}" ] && ! printf '%s\n' "${3:-}" | grep -q '^-'; then
      PACKAGE_NAME="${2:-}"
      VERSION="${3:-}"
      shift 3
    elif [ -n "${2:-}" ] && ! printf '%s\n' "${2:-}" | grep -q '^-'; then
      if [ "${2:-}" = "$(basename "$SCRIPT_DIR")" ] || [ "${2:-}" = "${PACKAGE_NAME:-}" ]; then
        PACKAGE_NAME="${2:-}"
        VERSION=""
        shift 2
      else
        if [ -z "${PACKAGE_NAME:-}" ]; then
          PACKAGE_NAME="$(basename "$COMP_DIR")"
        fi
        VERSION="${2:-}"
        shift 2
      fi
    else
      if [ -z "${PACKAGE_NAME:-}" ]; then
        PACKAGE_NAME="$(basename "$COMP_DIR")"
      fi
      VERSION=""
      shift 1
    fi
    ;;
  *)
    if [ -n "${1:-}" ]; then
      log_info "Unknown command: $1"
      log_info "Use --help to see available options."
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
  pkg_upper=$(printf '%s\n' "${PACKAGE_NAME##*/}" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
  var_name="${pkg_upper}_VERSION"
  export "$var_name"="$VERSION"
fi

if [ "$VERSION" = "latest" ] || [ "$VERSION" = "lts" ] || [ "$VERSION" = "stable" ]; then
  export LIBSCRIPT_NEVER_REFRESH_CHECKSUM_DB=1
fi

# Argument parsing loop
while [ $# -gt 0 ]; do
  # These actions stop parsing and pass remaining args to sub-scripts
  if [ "$ACTION" = "start" ] || [ "$ACTION" = "stop" ] || [ "$ACTION" = "restart" ] || [ "$ACTION" = "status" ] || [ "$ACTION" = "health" ] || [ "$ACTION" = "logs" ] || [ "$ACTION" = "up" ] || [ "$ACTION" = "down" ] || [ "$ACTION" = "install-service" ] || [ "$ACTION" = "uninstall-service" ] || [ "$ACTION" = "run" ] || [ "$ACTION" = "exec" ] || [ "$ACTION" = "auth" ] || [ "$ACTION" = "location" ] || [ "$ACTION" = "network" ] || [ "$ACTION" = "firewall" ] || [ "$ACTION" = "node" ] || [ "$ACTION" = "dns" ] || [ "$ACTION" = "ssh" ] || [ "$ACTION" = "cleanup" ] || [ "$ACTION" = "backup" ] || [ "$ACTION" = "restore" ] || [ "$ACTION" = "diff" ] || [ "$ACTION" = "storage" ] || [ "$ACTION" = "aws" ] || [ "$ACTION" = "azure" ] || [ "$ACTION" = "gcp" ]; then
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
      key=$(printf '%s\n' "${1#--}" | cut -d= -f1)
      val=$(printf '%s\n' "${1#--}" | cut -d= -f2-)
      [ "$key" = "$1" ] && key="${1#--}" # Handle case where there is no =
      if [ "$key" = "$val" ]; then val="true"; fi

      # Validate key and value against schema
      if command -v jq >/dev/null 2>&1; then
        _props=$(get_merged_properties)

        # Check if key exists
        if ! printf '%s\n' "$_props" | jq -e ".\"$key\"" >/dev/null 2>&1; then
          # Check for _STRATEGY suffix which is also allowed for dependencies
          if printf '%s\n' "$key" | grep -q "_STRATEGY$" && printf '%s\n' "$_props" | jq -e ".\"${key%_STRATEGY}\"" >/dev/null 2>&1; then
            export "$key"="$val"
          else
            # Pass through unknown flags to setup.sh and subcommands
            # Convert dash to underscore for export
            _safe_key=$(printf '%s\n' "$key" | tr '-' '_')
            export "$_safe_key"="$val"
          fi
        else
          # Validate enum if it exists
          _enum=$(printf '%s\n' "$_props" | jq -c ".\"$key\".enum // empty")
          if [ -n "$_enum" ]; then
            if ! printf '%s\n' "$_enum" | jq -e ". | contains([\"$val\"])" >/dev/null 2>&1; then
              printf '%s\n' "Error: Invalid value '$val' for --$key. Allowed values are: $(printf '%s\n' "$_enum" | jq -r 'join(", ")')" >&2
              exit 1
            fi
          fi
          _safe_key=$(printf '%s\n' "$key" | tr '-' '_')
          export "$_safe_key"="$val"
        fi
      else
        # If jq is not available, we can only warn or just set it.
        # Project policy seems to prefer strictness if possible, but without jq we can't be strict.
        _safe_key=$(printf '%s\n' "$key" | tr '-' '_')
        export "$_safe_key"="$val"
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
      printf '%s\n' "$_deps" | while IFS='|' read -r dep_key dep_default; do
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
  if [ -x "$COMP_DIR/test.sh" ]; then
    exec "$COMP_DIR/test.sh"
  else
    log_info "Error: test.sh not found in $SCRIPT_DIR"
    exit 1
  fi
elif [ "$ACTION" = "uninstall" ] || [ "$ACTION" = "remove" ]; then
  if [ -x "$COMP_DIR/uninstall.sh" ]; then
    exec "$COMP_DIR/uninstall.sh"
  else
    log_info "Error: uninstall.sh not found in $SCRIPT_DIR"
    exit 1
  fi
elif [ "$ACTION" = "env" ]; then
  INSTALLED_DIR="${PREFIX:-${LIBSCRIPT_HOME:-$HOME/.libscript}/$PACKAGE_NAME/$VERSION}"
  libscript_print_env "${FORMAT:-${format:-sh}}" "$INSTALLED_DIR"
  exit 0
elif [ "$ACTION" = "run" ]; then
  INSTALLED_DIR="${PREFIX:-${LIBSCRIPT_HOME:-$HOME/.libscript}/$PACKAGE_NAME/$VERSION}"
  BIN_PATH="$INSTALLED_DIR/bin/$PACKAGE_NAME"
  if [ ! -x "$BIN_PATH" ]; then
    log_error "$PACKAGE_NAME version $VERSION not installed at $BIN_PATH"
    exit 1
  fi
  exec "$BIN_PATH" "$@"
elif [ "$ACTION" = "which" ]; then
  INSTALLED_DIR="${PREFIX:-${LIBSCRIPT_HOME:-$HOME/.libscript}/$PACKAGE_NAME/$VERSION}"
  BIN_PATH="$INSTALLED_DIR/bin/$PACKAGE_NAME"
  if [ -x "$BIN_PATH" ]; then
    log_info "$BIN_PATH"
  else
    log_error "Not installed: $BIN_PATH"
    exit 1
  fi
elif [ "$ACTION" = "info" ]; then
  INSTALLED_DIR="${PREFIX:-${LIBSCRIPT_HOME:-$HOME/.libscript}/$PACKAGE_NAME/$VERSION}"
  printf '%s\n' "Component: $PACKAGE_NAME"
  printf '%s\n' "Version: $VERSION"
  printf '%s\n' "Install Path: $INSTALLED_DIR"
  if [ -d "$INSTALLED_DIR" ]; then
    printf '%s\n' "Status: Installed"
  else
    printf '%s\n' "Status: Not Installed"
  fi
  if [ -f "$SCHEMA_FILE" ] && command -v jq >/dev/null 2>&1; then
    printf '%s\n' "Dynamic Variables:"
    jq -r '.properties | to_entries[] | "  \(.key): \(.value.description // "") [default: \(.value.default // "")]"' "$SCHEMA_FILE" 2>/dev/null || true
  fi
  exit 0
elif [ "$ACTION" = "exec" ]; then
  INSTALLED_DIR="${PREFIX:-${LIBSCRIPT_HOME:-$HOME/.libscript}/$PACKAGE_NAME/$VERSION}"
  if [ ! -d "$INSTALLED_DIR/bin" ]; then
    log_error "$PACKAGE_NAME version $VERSION bin directory not found at $INSTALLED_DIR/bin"
    exit 1
  fi
  export PATH="$INSTALLED_DIR/bin:$PATH"
  exec "$@"
fi

# Default to setup.sh for installation and other actions
if [ -x "$COMP_DIR/setup.sh" ]; then
  unset SCRIPT_NAME || true
  exec "$COMP_DIR/setup.sh" "$@"
elif [ -f "$COMP_DIR/setup.sh" ]; then
  unset SCRIPT_NAME || true
  exec sh "$COMP_DIR/setup.sh" "$@"
else
  log_info "Error: setup.sh not found in $SCRIPT_DIR"
  exit 1
fi
