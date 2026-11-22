#!/bin/sh
# ## Overview
# Unified CLI routing and lifecycle management logic for LibScript components.
# ## Usage
# Source this file from your component's `cli.sh`: `. "${LIBSCRIPT_ROOT_DIR}/engine/common/component_core.sh"`
set -feu
_component_core_caller_this="${THIS_FILE:-}"; _component_core_caller_dir="${SCRIPT_DIR:-}"
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
    if [ "${LIBSCRIPT_DEBUG:-0}" = '1' ]; then printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2; fi
    [ -n "$_component_core_caller_this" ] && THIS_FILE="$_component_core_caller_this"
    [ -n "$_component_core_caller_dir" ] && SCRIPT_DIR="$_component_core_caller_dir"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) if [ "${LIBSCRIPT_DEBUG:-0}" = '1' ]; then printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2; fi ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
COMP_DIR="${_component_core_caller_dir:-${SCRIPT_DIR}}"
SCRIPT_DIR="${COMP_DIR}"
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export LIBSCRIPT_ROOT_DIR
_component_core_this="${THIS_FILE}"

# Source common libraries
for LIB in "engine/common/log.sh" "engine/common/service.sh" "engine/common/env_printer.sh" ${_LIBSCRIPT_DUMMY_NO_RUN:-}; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done
unset SCRIPT_NAME || true
THIS_FILE="${_component_core_this}"
SCRIPT_DIR="${COMP_DIR}"

SCHEMA_FILE="$COMP_DIR/vars.schema.json"
MANIFEST_FILE="$COMP_DIR/manifest.json"
BASE_SCHEMA_FILE="$LIBSCRIPT_ROOT_DIR/engine/schemas/base_vars.schema.json"
VARS_PACK_DIR="$LIBSCRIPT_ROOT_DIR/schemas/vars"

# ## get_component_help_properties
# Resolves component-specific and opted-in domain pack properties without merging global base_vars.schema.json.
get_component_help_properties() {
  if [ -f "$SCHEMA_FILE" ]; then
    _pack_files=""
    _packs=$(jq -r '."x-libscript-var-packs"[]? // empty' "$SCHEMA_FILE" 2>/dev/null || true)
    for _p in $_packs; do
      if [ -f "${VARS_PACK_DIR}/${_p}.schema.json" ]; then
        _pack_files="${_pack_files} ${VARS_PACK_DIR}/${_p}.schema.json"
      fi
    done
    # shellcheck disable=SC2086
    jq -s 'reduce .[] as $item ({}; . * ($item.properties // {}))' $_pack_files "$SCHEMA_FILE"
  else
    printf '{}\n'
  fi
}

# ## get_merged_properties
# Resolves merged schema properties across base_vars.schema.json, opted-in variable packs, and component vars.schema.json via file-based jq -s.
get_merged_properties() {
  _merge_files=""
  [ -f "$BASE_SCHEMA_FILE" ] && _merge_files="$BASE_SCHEMA_FILE"
  if [ -f "$SCHEMA_FILE" ]; then
    _packs=$(jq -r '."x-libscript-var-packs"[]? // empty' "$SCHEMA_FILE" 2>/dev/null || true)
    for _p in $_packs; do
      if [ -f "${VARS_PACK_DIR}/${_p}.schema.json" ]; then
        _merge_files="${_merge_files} ${VARS_PACK_DIR}/${_p}.schema.json"
      fi
    done
    _merge_files="${_merge_files} ${SCHEMA_FILE}"
  fi
  if [ -n "$_merge_files" ]; then
    # shellcheck disable=SC2086
    jq -s 'reduce .[] as $item ({}; . * ($item.properties // {}))' $_merge_files
  else
    log_info '{}'
  fi
}

# ## libscript_Synchronize_Ingress
# Delegates declarative .ingress proxy synchronization to _lib/networking/netctl/lib/ingress_sync.sh.
libscript_Synchronize_Ingress() {
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/networking/netctl/lib/ingress_sync.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
  unset SCRIPT_NAME || true
  netctl_synchronize_ingress "$@"
}

# ## libscript_Warmup_Ollama
# Delegates Ollama model pre-warming to _lib/app-servers/ollama/warmup.sh.
libscript_Warmup_Ollama() {
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/app-servers/ollama/warmup.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
  unset SCRIPT_NAME || true
  ollama_warmup_model "$@"
}

if [ "${1:-}" = "--synchronize-ingress" ] || [ "${1:-}" = "synchronize-ingress" ]; then
  shift
  libscript_Synchronize_Ingress "$@"
  STACK="${STACK%"${THIS_FILE}":}"
  export STACK
  [ -n "${_component_core_caller_dir:-}" ] && SCRIPT_DIR="$_component_core_caller_dir"
  [ -n "${_component_core_caller_this:-}" ] && THIS_FILE="$_component_core_caller_this"
  if (return 0 2>/dev/null); then return 0; else exit 0; fi
elif [ "${1:-}" = "--warmup-ollama" ] || [ "${1:-}" = "warmup-ollama" ]; then
  shift
  libscript_Warmup_Ollama "$@"
  STACK="${STACK%"${THIS_FILE}":}"
  export STACK
  [ -n "${_component_core_caller_dir:-}" ] && SCRIPT_DIR="$_component_core_caller_dir"
  [ -n "${_component_core_caller_this:-}" ] && THIS_FILE="$_component_core_caller_this"
  if (return 0 2>/dev/null); then return 0; else exit 0; fi
elif [ "${LIBSCRIPT_COMPONENT_CORE_LIB_ONLY:-0}" = "1" ]; then
  STACK="${STACK%"${THIS_FILE}":}"
  export STACK
  [ -n "${_component_core_caller_dir:-}" ] && SCRIPT_DIR="$_component_core_caller_dir"
  [ -n "${_component_core_caller_this:-}" ] && THIS_FILE="$_component_core_caller_this"
  if (return 0 2>/dev/null); then return 0; else exit 0; fi
fi

# ## show_help
# Displays command-line usage instructions and available options.
show_help() {
  log_info "Usage: ${THIS_FILE##*/} [COMMAND] [PACKAGE_NAME] [VERSION] [OPTIONS]"
  log_info ""
  log_info 'Commands:'
  log_info '  install <package_name> <version>'
  log_info '  use <package_name> <version>'
  log_info '  remove <package_name> [version]'
  log_info '  uninstall <package_name> [version]'
  log_info '  install-service <package_name> <version>'
  log_info '  uninstall-service <package_name> <version>'
  log_info '  status <package_name> [version]'
  log_info '  health <package_name> [version]'
  log_info '  start <package_name> [version]'
  log_info '  stop <package_name> [version]'
  log_info '  restart <package_name> [version]'
  log_info '  logs <package_name> [version] [-f|--follow]'
  log_info '  up <package_name> [version]'
  log_info '  down <package_name> [version]'
  log_info '  test <package_name> [version]'
  log_info '  run <package_name> <version> [args...]'
  log_info '  which <package_name> <version>'
  log_info '  exec <package_name> <version> <cmd> [args...]'
  log_info '  ls <package_name>'
  log_info '  download <package_name> <version>'
  log_info '  ls-remote <package_name> [version]'
  log_info ""
  log_info 'Description:'
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
  log_info 'Component Options:'
  if command -v jq >/dev/null 2>&1; then
    _props=$(get_component_help_properties)
    printf '%s\n' "$_props" | jq -r '
      to_entries[] |
      def aliases: if .value.version_aliases then " [aliases: " + (.value.version_aliases | join(", ")) + "]" else "" end;
      "--\(.key)=VALUE|\(.value.description // "")\(aliases) [default: \(.value.default // "none")]"
    ' | awk -F'|' '{printf "  %-35s %s\n", $1, $2}'

    printf '%s\n' "$_props" | jq -r '
      to_entries[] | select(.value.is_libscript_dependency == true) |
      "--\(.key)_STRATEGY=VALUE|Strategy for \(.key) (reuse, install-alongside, upgrade, downgrade, overwrite) [default: reuse]"
    ' | awk -F'|' '{printf "  %-35s %s\n", $1, $2}'
    log_info ""
    log_info 'Global Framework Flags:'
    log_info '  --offline, -o                       Use local cache only without network requests'
    log_info '  --cache-dir=DIR                     Override LIBSCRIPT_CACHE_DIR'
    log_info '  --prefix=DIR                        Override installation prefix'
    log_info '  --service-name=NAME                 Override service unit name'
    log_info '  (See engine/schemas/base_vars.schema.json for all core LIBSCRIPT_* variables)'
  else
    log_info '  (jq is required to parse vars.schema.json for dynamic options)'
    log_info "  See $SCHEMA_FILE for available variables."
  fi
  log_info ""
  log_info '  --help, -h, /?                      Show this help message'
  log_info '  --version, -v                       Show version'
  log_info ""
}

ACTION=""
VERSION=""

# Input validation and basic routing
case "${1:-}" in
  --help|-h|/\?|"-?"|help)
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
        VERSION='latest'
      else
        VERSION="${2:-}"
      fi
      shift 2
    else
      printf '%s\n' "Error: version is required for $ACTION" >&2
      exit 1
    fi
    ;;
  auth*|location*|group*|project*|compartment*|network*|node*|dns*|firewall*|ssh*|backup*|restore*|diff*|list-managed*|storage*|dashboard*|cost*|usage*|logs-aggregate*|aws*|azure*|gcp*|hetzner*|proxmox*|digitalocean*|linode*|vultr*|oci*|ovh*|cleanup*)
    ACTION="${1:-}"
    shift
    ;;
  ls|ls-remote|download|remove|uninstall|status|health|test|start|stop|restart|logs|up|down|setup|deploy|target-add|target-rm|target-ls|component-add|component-ls)
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
      log_info 'Use --help to see available options.'
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
  # Prefix with SEVEN if it starts with 7
  if [ "$pkg_upper" = "7ZIP" ]; then pkg_upper="SEVENZIP"; fi
  case "$pkg_upper" in
    [0-9]*) pkg_upper="_${pkg_upper}" ;;
  esac

  var_name="${pkg_upper}_VERSION"
  export "$var_name"="$VERSION"
fi

if [ "$VERSION" = "latest" ] || [ "$VERSION" = "lts" ] || [ "$VERSION" = "stable" ]; then
  export LIBSCRIPT_NEVER_REFRESH_CHECKSUM_DB=1
fi

# Argument parsing loop
while [ $# -gt 0 ]; do
  # These actions stop parsing and pass remaining args to sub-scripts
  if [ "$ACTION" = "start" ] || [ "$ACTION" = "stop" ] || [ "$ACTION" = "restart" ] || [ "$ACTION" = "status" ] || [ "$ACTION" = "health" ] || [ "$ACTION" = "logs" ] || [ "$ACTION" = "up" ] || [ "$ACTION" = "down" ] || [ "$ACTION" = "install-service" ] || [ "$ACTION" = "uninstall-service" ] || [ "$ACTION" = "run" ] || [ "$ACTION" = "exec" ] || [ "$ACTION" = "target-add" ] || [ "$ACTION" = "target-rm" ] || [ "$ACTION" = "target-ls" ] || [ "$ACTION" = "component-add" ] || [ "$ACTION" = "component-ls" ] || [ "$ACTION" = "auth" ] || [ "$ACTION" = "location" ] || [ "$ACTION" = "group" ] || [ "$ACTION" = "project" ] || [ "$ACTION" = "network" ] || [ "$ACTION" = "firewall" ] || [ "$ACTION" = "node" ] || [ "$ACTION" = "dns" ] || [ "$ACTION" = "ssh" ] || [ "$ACTION" = "cleanup" ] || [ "$ACTION" = "backup" ] || [ "$ACTION" = "restore" ] || [ "$ACTION" = "diff" ] || [ "$ACTION" = "storage" ] || [ "$ACTION" = "dashboard" ] || [ "$ACTION" = "cost" ] || [ "$ACTION" = "usage" ] || [ "$ACTION" = "logs-aggregate" ] || [ "$ACTION" = "aws" ] || [ "$ACTION" = "azure" ] || [ "$ACTION" = "gcp" ] || [ "$ACTION" = "hetzner" ] || [ "$ACTION" = "proxmox" ] || [ "$ACTION" = "digitalocean" ] || [ "$ACTION" = "linode" ] || [ "$ACTION" = "vultr" ]; then
    break
  fi
  case "$1" in
    --use)
      export LIBSCRIPT_AUTO_USE=1
      shift
      ;;
    --targets=*)
      export SUB_TARGETS="${1#*=}"
      if [ -n "${pkg_upper:-}" ]; then export "${pkg_upper}_TARGETS=${1#*=}"; fi
      shift
      ;;
    --components=*)
      export SUB_COMPONENTS="${1#*=}"
      if [ -n "${pkg_upper:-}" ]; then export "${pkg_upper}_COMPONENTS=${1#*=}"; fi
      shift
      ;;
    --offline|-o)
      export LIBSCRIPT_OFFLINE=1
      shift
      ;;
    --force-offline)
      export LIBSCRIPT_FORCE_OFFLINE=1
      export LIBSCRIPT_OFFLINE=1
      shift
      ;;
    --online)
      export LIBSCRIPT_OFFLINE=0
      shift
      ;;
    --cache-dir=*)
      export LIBSCRIPT_CACHE_DIR="${1#*=}"
      shift
      ;;
    --cache-dir)
      shift
      export LIBSCRIPT_CACHE_DIR="${1:-}"
      shift
      ;;
    --download-dir=*)
      export DOWNLOAD_DIR="${1#*=}"
      export LIBSCRIPT_DOWNLOAD_DIR="${1#*=}"
      shift
      ;;
    --download-dir)
      shift
      export DOWNLOAD_DIR="${1:-}"
      export LIBSCRIPT_DOWNLOAD_DIR="${DOWNLOAD_DIR}"
      shift
      ;;
    --prefix=*)
      export PREFIX="${1#*=}"
      shift
      ;;
    --install-method=*)
      _im_val="${1#*=}"
      export LIBSCRIPT_DEFAULT_INSTALL_METHOD="${_im_val}"
      if [ -n "${pkg_upper:-}" ]; then
        export "${pkg_upper}_INSTALL_METHOD=${_im_val}"
      fi
      shift
      ;;
    --from-source)
      export LIBSCRIPT_DEFAULT_INSTALL_METHOD='from-source'
      if [ -n "${pkg_upper:-}" ]; then
        export "${pkg_upper}_INSTALL_METHOD=from-source"
      fi
      shift
      ;;
    --pkg-mgr=*)
      _pm_val="${1#*=}"
      export LIBSCRIPT_PKG_MGR="${_pm_val}"
      if [ -n "${pkg_upper:-}" ]; then
        export "${pkg_upper}_PKG_MGR=${_pm_val}"
        _cur_im="$(printenv "${pkg_upper}_INSTALL_METHOD" 2>/dev/null || true)"
        if [ -z "${_cur_im}" ]; then
          export "${pkg_upper}_INSTALL_METHOD=system"
        fi
      fi
      shift
      ;;
    --toolchain=*|--with-compiler=*)
      _tc_val="${1#*=}"
      export LIBSCRIPT_BUILD_TOOLCHAIN="${_tc_val}"
      if [ -n "${pkg_upper:-}" ]; then
        export "${pkg_upper}_BUILD_TOOLCHAIN=${_tc_val}"
        export "${pkg_upper}_COMPILER=${_tc_val}"
      fi
      shift
      ;;
    --custom-cc=*)
      _cc_val="${1#*=}"
      export CUSTOM_CC_BIN="${_cc_val}"
      export LIBSCRIPT_CUSTOM_CC_BIN="${_cc_val}"
      export LIBSCRIPT_BUILD_TOOLCHAIN='custom-cc'
      export LIBSCRIPT_DEFAULT_INSTALL_METHOD='from-source'
      if [ -n "${pkg_upper:-}" ]; then
        export "${pkg_upper}_BUILD_TOOLCHAIN=custom-cc"
        export "${pkg_upper}_COMPILER=custom-cc"
        export "${pkg_upper}_INSTALL_METHOD=from-source"
      fi
      shift
      ;;
    --service-name=*)
      export LIBSCRIPT_SERVICE_NAME="${1#*=}"
      shift
      ;;
    --output-format=*|--format=*)
      export LIBSCRIPT_OUTPUT_FORMAT="${1#*=}"
      export FORMAT="${1#*=}"
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

STACK="${STACK%"${_component_core_this}":}"
if [ -n "${_component_core_caller_this:-}" ]; then
  STACK="${STACK%"${_component_core_caller_this}":}"
fi
if [ "${ACTION:-}" = "ls-remote" ] || [ "${ACTION:-}" = "ls" ] || [ "${ACTION:-}" = "which" ] || [ "${ACTION:-}" = "env" ] || [ "${ACTION:-}" = "info" ]; then
  STACK=''
fi
export STACK

# Automated Dependency Resolution
if [ "${LIBSCRIPT_SKIP_DEPENDENCIES:-}" != "1" ] && { [ "$ACTION" = "install" ] || [ "$ACTION" = "setup" ]; }; then
  if command -v jq >/dev/null 2>&1 && [ -f "$SCHEMA_FILE" ]; then
    _deps=$(get_merged_properties | jq -r 'to_entries[] | select(.value.is_libscript_dependency == true) | "\(.key)|\(.value.default // "")"' 2>/dev/null)
    if [ -n "$_deps" ]; then
      printf '%s\n' "$_deps" | while IFS='|' read -r dep_key dep_default; do
        [ -z "$dep_key" ] && continue
        dep_val="$(printenv "$dep_key" 2>/dev/null || true)"
        if [ -z "$dep_val" ]; then
          dep_val="$dep_default"
          export "$dep_key"="$dep_val"
        fi
        [ -z "$dep_val" ] && continue

        strategy_val="$(printenv "${dep_key}_STRATEGY" 2>/dev/null || echo "reuse")"
        export strategy_val
        log_info "Resolving dependency: $dep_val (strategy: ${strategy_val:-})"

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

# Enforce capability contract for daemon-only lifecycle verbs
case "$ACTION" in
  start|stop|restart|install-service|uninstall-service)
    if [ -f "$COMP_DIR/manifest.json" ] && command -v jq >/dev/null 2>&1; then
      if ! jq -e '(.capabilities // []) | index("service-daemon") != null' "$COMP_DIR/manifest.json" >/dev/null 2>&1; then
        _cc_caps=$(jq -c '.capabilities // []' "$COMP_DIR/manifest.json" 2>/dev/null || printf '[]')
        log_error "Action '$ACTION' requires capability 'service-daemon' ($PACKAGE_NAME capabilities: ${_cc_caps})."
        exit 1
      fi
    fi
    ;;
esac

# Lifecycle routing
if [ "$ACTION" = "test" ]; then
  if [ -x "$COMP_DIR/test.sh" ]; then
    unset SCRIPT_NAME || true
    exec "$COMP_DIR/test.sh"
  elif [ -f "$COMP_DIR/test.sh" ]; then
    unset SCRIPT_NAME || true
    exec sh "$COMP_DIR/test.sh"
  else
    log_info "Error: test.sh not found in $COMP_DIR"
    exit 1
  fi
elif [ "$ACTION" = "uninstall" ] || [ "$ACTION" = "remove" ]; then
  if [ -x "$COMP_DIR/uninstall.sh" ]; then
    unset SCRIPT_NAME || true
    exec "$COMP_DIR/uninstall.sh"
  elif [ -f "$COMP_DIR/uninstall.sh" ]; then
    unset SCRIPT_NAME || true
    exec sh "$COMP_DIR/uninstall.sh"
  else
    log_info "Error: uninstall.sh not found in $SCRIPT_DIR"
    exit 1
  fi
elif [ "$ACTION" = "env" ]; then
  INSTALLED_DIR="${PREFIX:-${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/$PACKAGE_NAME/$VERSION}"
  libscript_print_env "${LIBSCRIPT_OUTPUT_FORMAT:-${FORMAT:-${format:-sh}}}" "$INSTALLED_DIR"
  exit 0
elif [ "$ACTION" = "run" ]; then
  INSTALLED_DIR="${PREFIX:-${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/$PACKAGE_NAME/$VERSION}"
  BIN_PATH="$INSTALLED_DIR/bin/$PACKAGE_NAME"
  if [ ! -x "$BIN_PATH" ] && [ -d "$INSTALLED_DIR/bin" ]; then
    for _entry in $(ls -1 "$INSTALLED_DIR/bin" 2>/dev/null || true); do
      _cand="$INSTALLED_DIR/bin/$_entry"
      if [ -f "$_cand" ] && [ -x "$_cand" ]; then
        BIN_PATH="$_cand"
        break
      fi
    done
  fi
  if [ ! -x "$BIN_PATH" ]; then
    log_error "$PACKAGE_NAME version $VERSION not installed at $BIN_PATH"
    exit 1
  fi
  exec "$BIN_PATH" "$@"
elif [ "$ACTION" = "which" ]; then
  INSTALLED_DIR="${PREFIX:-${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/$PACKAGE_NAME/$VERSION}"
  BIN_PATH="$INSTALLED_DIR/bin/$PACKAGE_NAME"
  if [ ! -x "$BIN_PATH" ] && [ -d "$INSTALLED_DIR/bin" ]; then
    for _entry in $(ls -1 "$INSTALLED_DIR/bin" 2>/dev/null || true); do
      _cand="$INSTALLED_DIR/bin/$_entry"
      if [ -f "$_cand" ] && [ -x "$_cand" ]; then
        BIN_PATH="$_cand"
        break
      fi
    done
  fi
  if [ -x "$BIN_PATH" ]; then
    log_info "$BIN_PATH"
    exit 0
  else
    log_error "Not installed: $BIN_PATH"
    exit 1
  fi
elif [ "$ACTION" = "info" ]; then
  INSTALLED_DIR="${PREFIX:-${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/$PACKAGE_NAME/$VERSION}"
  printf '%s\n' "Component: $PACKAGE_NAME"
  printf '%s\n' "Version: $VERSION"
  printf '%s\n' "Install Path: $INSTALLED_DIR"
  if [ -d "$INSTALLED_DIR" ]; then
    printf '%s\n' 'Status: Installed'
  else
    printf '%s\n' 'Status: Not Installed'
  fi
  if [ -f "$SCHEMA_FILE" ] && command -v jq >/dev/null 2>&1; then
    printf '%s\n' 'Dynamic Variables:'
    jq -r '.properties | to_entries[] | "  \(.key): \(.value.description // "") [default: \(.value.default // "")]"' "$SCHEMA_FILE" 2>/dev/null || true
  fi
  exit 0
elif [ "$ACTION" = "exec" ]; then
  INSTALLED_DIR="${PREFIX:-${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/$PACKAGE_NAME/$VERSION}"
  if [ ! -d "$INSTALLED_DIR/bin" ]; then
    log_error "$PACKAGE_NAME version $VERSION bin directory not found at $INSTALLED_DIR/bin"
    exit 1
  fi
  export PATH="$INSTALLED_DIR/bin:$PATH"
  exec "$@"
fi

# Execute the requested action script
if [ -n "$ACTION" ] && [ "$ACTION" != "install" ] && [ "$ACTION" != "setup" ] && [ "$ACTION" != "ls" ] && [ "$ACTION" != "ls-remote" ] && [ "$ACTION" != "use" ] && [ "$ACTION" != "download" ] && [ "$ACTION" != "target-add" ] && [ "$ACTION" != "target-rm" ] && [ "$ACTION" != "target-ls" ] && [ "$ACTION" != "component-add" ] && [ "$ACTION" != "component-ls" ] && [ "$ACTION" != "install-service" ] && [ "$ACTION" != "uninstall-service" ] && [ "$ACTION" != "test" ] && [ "$ACTION" != "start" ] && [ "$ACTION" != "stop" ] && [ "$ACTION" != "restart" ] && [ "$ACTION" != "status" ] && [ "$ACTION" != "health" ] && [ "$ACTION" != "logs" ] && [ "$ACTION" != "up" ] && [ "$ACTION" != "down" ]; then
  if [ -x "$COMP_DIR/${ACTION}.sh" ]; then
    unset SCRIPT_NAME || true
    exec "$COMP_DIR/${ACTION}.sh" "$@"
  elif [ -f "$COMP_DIR/${ACTION}.sh" ]; then
    unset SCRIPT_NAME || true
    exec sh "$COMP_DIR/${ACTION}.sh" "$@"
  elif [ -x "$COMP_DIR/setup.sh" ]; then
    export ACTION
    unset SCRIPT_NAME || true
    exec "$COMP_DIR/setup.sh" "$@"
  elif [ -f "$COMP_DIR/setup.sh" ]; then
    export ACTION
    unset SCRIPT_NAME || true
    exec sh "$COMP_DIR/setup.sh" "$@"
  else
    log_error "Action '$ACTION' is not implemented for this component."
    exit 1
  fi
fi

# Fallback to setup.sh for install, setup, and service actions
STACK="${STACK%"${_component_core_this}":}"
export STACK
if [ -x "$COMP_DIR/setup.sh" ]; then
  unset SCRIPT_NAME || true
  exec "$COMP_DIR/setup.sh" "$@"
elif [ -f "$COMP_DIR/setup.sh" ]; then
  unset SCRIPT_NAME || true
  exec sh "$COMP_DIR/setup.sh" "$@"
else
  log_error "Error: setup.sh not found in $COMP_DIR"
  exit 1
fi
