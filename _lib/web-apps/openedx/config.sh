#!/bin/sh
# ## Overview
# Configuration management engine for Open edX with Tutor `config` CLI parity.
#
# ## Usage
# ./config.sh [get|set|list|generate|validate|save|printvalue|printroot|patches|help] [options]

set -feu
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
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export DIR="${SCRIPT_DIR}"

if [ -f "${LIBSCRIPT_ROOT_DIR}/env.sh" ]; then
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/env.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
fi

for LIB in "_lib/_common/log.sh" ${_LIBSCRIPT_DUMMY_NO_RUN:-}; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done

OPENEDX_INSTALL_DIR="${OPENEDX_INSTALL_DIR:-${LIBSCRIPT_HOME:-$HOME/.libscript}/openedx}"
CONF_DIR="${OPENEDX_INSTALL_DIR}/config"
LMS_CONF="${CONF_DIR}/lms.env.json"
CMS_CONF="${CONF_DIR}/cms.env.json"
SCHEMA_FILE="${DIR}/vars.schema.json"
CONFIG_HELPER="${DIR}/config_helper.sh"

PATCH_SLOTS="openedx-common-settings openedx-lms-production-settings openedx-cms-production-settings openedx-lms-development-settings openedx-cms-development-settings lms-env cms-env openedx-auth caddyfile"

# ## ensure_conf_dir
# Creates config directory and initializes baseline JSON if absent.
ensure_conf_dir() {
  mkdir -p "${CONF_DIR}"
  if [ ! -f "${LMS_CONF}" ]; then
    config_generate >/dev/null 2>&1 || true
  fi
}

# ## config_get
# Reads a dot-separated key from lms.env.json.
#
# Inputs:
#   $1 - dot-separated key (e.g. DATABASES.default.HOST)
config_get() {
  _key="${1:-}"
  if [ -z "${_key}" ]; then
    log_err "Key parameter is required."
    exit 1
  fi
  ensure_conf_dir

  if ! "${CONFIG_HELPER}" get "${LMS_CONF}" "${_key}"; then
    log_err "Failed to read key '${_key}'."
    exit 1
  fi
}

# ## config_set
# Sets a dot-separated key across LMS and Studio configurations.
#
# Inputs:
#   $1 - dot-separated key
#   $2 - value
config_set() {
  _key="${1:-}"
  _val="${2:-}"
  if [ -z "${_key}" ]; then
    log_err "Key parameter is required."
    exit 1
  fi
  ensure_conf_dir

  if "${CONFIG_HELPER}" set "${LMS_CONF}" "${CMS_CONF}" "${_key}" "${_val}" >/dev/null; then
    log_success "Configuration key '${_key}' updated to '${_val}'."
  else
    log_err "Failed to set key '${_key}'."
    exit 1
  fi
}

# ## config_list
# Outputs the full active configuration.
config_list() {
  ensure_conf_dir
  if [ -f "${LMS_CONF}" ]; then
    cat "${LMS_CONF}"
    printf '
'
  else
    log_warn "No configuration file found at ${LMS_CONF}."
  fi
}

# ## config_generate
# Generates default LMS and Studio JSON configuration files.
config_generate() {
  mkdir -p "${CONF_DIR}"
  if "${CONFIG_HELPER}" generate "${LMS_CONF}" "${CMS_CONF}" >/dev/null; then
    log_success "Default configurations ensured at ${CONF_DIR}."
  else
    log_err "Failed to generate configurations."
    exit 1
  fi
}

# ## config_validate
# Validates configuration syntax and schema compliance.
config_validate() {
  ensure_conf_dir
  log_info "Validating ${LMS_CONF} against ${SCHEMA_FILE}..."
  if "${CONFIG_HELPER}" validate "${LMS_CONF}" "${SCHEMA_FILE}" >/dev/null; then
    log_success "Configuration validation PASSED."
  else
    log_err "Configuration validation FAILED."
    exit 1
  fi
}

# ## config_patches
# Lists or displays Tutor-compatible patch slots.
config_patches() {
  _sub="${1:-list}"
  shift || true
  case "${_sub}" in
    list|ls)
      for _slot in ${PATCH_SLOTS}; do
        printf '%s
' "${_slot}"
      done
      ;;
    show)
      _name="${1:-}"
      if [ -z "${_name}" ]; then
        log_err "Patch slot name is required."
        exit 1
      fi
      ensure_conf_dir
      "${CONFIG_HELPER}" get "${LMS_CONF}" "PATCHES.${_name}" || true
      ;;
    *)
      log_err "Unknown patches subcommand: ${_sub}"
      exit 1
      ;;
  esac
}

# ## show_help
# Displays usage instructions.
show_help() {
  cat <<EOF
Open edX Configuration Management Engine

Usage:
  $0 get <key>
  $0 set <key> <value>
  $0 list
  $0 generate
  $0 save
  $0 printvalue <key>
  $0 printroot
  $0 patches [list|show <name>]
  $0 validate
  $0 help

Commands:
  get          Get a configuration parameter (dot notation supported)
  set          Set a configuration parameter across LMS & CMS
  list         Print full current configuration
  generate     Generate default configuration files
  save         Save and synthesize environment configurations (Tutor parity)
  printvalue   Print a configuration parameter value (Tutor parity)
  printroot    Print the root Open edX installation directory (Tutor parity)
  patches      List or inspect Tutor-compatible patch slots
  validate     Validate configuration syntax and schema
  help         Show this help message
EOF
}

COMMAND="${1:-help}"
shift || true

case "${COMMAND}" in
  get|printvalue)
    config_get "$@"
    ;;
  set)
    config_set "$@"
    ;;
  list)
    config_list
    ;;
  generate|save)
    while [ $# -gt 0 ]; do
      case "$1" in
        --set)
          if [ $# -ge 2 ]; then
            _kv="$2"
            _k="${_kv%%=*}"
            _v="${_kv#*=}"
            config_set "${_k}" "${_v}"
            shift 2
          else
            shift
          fi
          ;;
        *)
          shift
          ;;
      esac
    done
    config_generate
    ;;
  printroot)
    printf '%s
' "${OPENEDX_INSTALL_DIR}"
    ;;
  patches)
    config_patches "$@"
    ;;
  validate)
    config_validate
    ;;
  help|--help|-h)
    show_help
    exit 0
    ;;
  *)
    log_err "Unknown config command: ${COMMAND}"
    show_help
    exit 1
    ;;
esac
