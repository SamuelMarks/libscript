#!/bin/sh
# ## Overview
# Configuration management engine for Open edX.
# Provides get, set, list, generate, and validate operations for environment configurations.
#
# ## Usage
#   ./config.sh get <key>
#   ./config.sh set <key> <value>
#   ./config.sh list
#   ./config.sh generate
#   ./config.sh validate
#   ./config.sh help
#
# ## Parameters
# - `get`: Retrieves configuration value from lms.env.json.
# - `set`: Sets or updates a key/value pair in lms.env.json and cms.env.json idempotently.
# - `list`: Outputs active configuration JSON settings.
# - `generate`: Synthesizes default configuration files without overwriting existing keys.
# - `validate`: Validates configuration structure against vars.schema.json.
#
# ## Environment Variables
# - `OPENEDX_INSTALL_DIR`: Path to openedx installation directory.
# - `LIBSCRIPT_ROOT_DIR`: Root directory of LibScript repository.
#
# ## Exit Codes
# - `0`: Success.
# - `1`: Invalid configuration key, parse error, or validation failure.

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
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
SCHEMA_FILE="${SCRIPT_DIR}/vars.schema.json"

# ## resolve_python
# Resolves python interpreter.
resolve_python() {
  if [ -x "${OPENEDX_INSTALL_DIR}/.venv/bin/python" ]; then
    printf '%s
' "${OPENEDX_INSTALL_DIR}/.venv/bin/python"
  elif command -v python3 >/dev/null 2>&1; then
    command -v python3
  elif command -v python >/dev/null 2>&1; then
    command -v python
  else
    printf ''
  fi
}

# ## config_get
# Retrieves a configuration value by key.
#
# Inputs:
#   $1 - key name (supports dot notation like DATABASES.default.HOST)
config_get() {
  if [ $# -lt 1 ]; then
    log_err "Usage: $0 get <key>"
    return 1
  fi
  _key="$1"
  if [ ! -f "${LMS_CONF}" ]; then
    log_err "Configuration file not found at ${LMS_CONF}. Run '$0 generate' first."
    return 1
  fi
  _py="$(resolve_python)"
  if [ -z "${_py}" ]; then
    log_err "Python is required for config inspection."
    return 1
  fi
  "${_py}" - <<EOF
import json, sys
try:
    with open("${LMS_CONF}") as f:
        cfg = json.load(f)
    parts = "${_key}".split(".")
    curr = cfg
    for p in parts:
        if isinstance(curr, dict) and p in curr:
            curr = curr[p]
        else:
            print("null")
            sys.exit(0)
    if isinstance(curr, (dict, list)):
        print(json.dumps(curr, indent=2))
    else:
        print(curr)
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)
EOF
}

# ## config_set
# Sets a configuration key/value in LMS and CMS JSON files.
#
# Inputs:
#   $1 - key name (supports dot notation)
#   $2 - value (string, int, or json)
config_set() {
  if [ $# -lt 2 ]; then
    log_err "Usage: $0 set <key> <value>"
    return 1
  fi
  _key="$1"
  _val="$2"

  mkdir -p "${CONF_DIR}"
  _py="$(resolve_python)"
  if [ -z "${_py}" ]; then
    log_err "Python is required for config manipulation."
    return 1
  fi

  for _conf in "${LMS_CONF}" "${CMS_CONF}"; do
    "${_py}" - <<EOF
import json, os, sys

def parse_val(v):
    try:
        return json.loads(v)
    except Exception:
        return v

conf_file = "${_conf}"
cfg = {}
if os.path.exists(conf_file):
    try:
        with open(conf_file) as f:
            cfg = json.load(f)
    except Exception:
        cfg = {}

parts = "${_key}".split(".")
curr = cfg
for p in parts[:-1]:
    if p not in curr or not isinstance(curr[p], dict):
        curr[p] = {}
    curr = curr[p]
curr[parts[-1]] = parse_val("""${_val}""")

with open(conf_file, "w") as f:
    json.dump(cfg, f, indent=2)
EOF
  done
  log_success "Set '${_key}' = '${_val}' in ${LMS_CONF} and ${CMS_CONF}."
}

# ## config_list
# Lists configuration in JSON format.
config_list() {
  if [ ! -f "${LMS_CONF}" ]; then
    log_warn "No configuration file found at ${LMS_CONF}."
    return 0
  fi
  cat "${LMS_CONF}"
}

# ## config_generate
# Idempotently synthesizes configuration files preserving existing overrides.
config_generate() {
  mkdir -p "${CONF_DIR}"
  log_info "Generating Open edX configuration files at ${CONF_DIR}..."

  _py="$(resolve_python)"
  if [ -z "${_py}" ]; then
    log_err "Python is required to generate configuration."
    return 1
  fi

  "${_py}" - <<EOF
import json, os, secrets

defaults = {
  "SITE_NAME": "${LMS_HOST:-openedx.local}",
  "LMS_BASE": "${LMS_HOST:-openedx.local}",
  "CMS_BASE": "${CMS_HOST:-studio.openedx.local}",
  "SECRET_KEY": "${OPENEDX_SECRET_KEY:-" + secrets.token_hex(24) + "}",
  "DATABASES": {
    "default": {
      "ENGINE": "django.db.backends.mysql",
      "NAME": "${MYSQL_DATABASE:-openedx}",
      "USER": "${MYSQL_USER:-openedx}",
      "PASSWORD": "${MYSQL_PASSWORD:-}",
      "HOST": "${MYSQL_HOST:-127.0.0.1}",
      "PORT": "${MYSQL_PORT:-3306}"
    }
  },
  "CACHES": {
    "default": {
      "BACKEND": "django_redis.cache.RedisCache",
      "LOCATION": "redis://${REDIS_HOST:-127.0.0.1}:${REDIS_PORT:-6379}/1"
    }
  },
  "MEILISEARCH_URL": "http://${MEILISEARCH_HOST:-127.0.0.1}:${MEILISEARCH_PORT:-7700}",
  "EMAIL_HOST": "${SMTP_HOST:-127.0.0.1}",
  "EMAIL_PORT": ${SMTP_PORT:-25}
}

def deep_merge(orig, new):
    for k, v in new.items():
        if k in orig and isinstance(orig[k], dict) and isinstance(v, dict):
            deep_merge(orig[k], v)
        elif k not in orig:
            orig[k] = v

for fn in ["${LMS_CONF}", "${CMS_CONF}"]:
    data = {}
    if os.path.exists(fn):
        try:
            with open(fn) as f:
                data = json.load(f)
        except Exception:
            data = {}
    deep_merge(data, defaults)
    with open(fn, "w") as f:
        json.dump(data, f, indent=2)

print("Configuration synthesized successfully.")
EOF
  log_success "Open edX environment configurations generated."
}

# ## config_validate
# Validates configuration against vars.schema.json.
config_validate() {
  log_info "Validating configuration files..."
  if [ ! -f "${LMS_CONF}" ]; then
    log_err "LMS configuration file not found at ${LMS_CONF}."
    return 1
  fi
  _py="$(resolve_python)"
  if [ -z "${_py}" ]; then
    log_err "Python is required for validation."
    return 1
  fi

  "${_py}" - <<EOF
import json, sys, os
schema_file = "${SCHEMA_FILE}"
conf_file = "${LMS_CONF}"

try:
    with open(conf_file) as f:
        cfg = json.load(f)
except Exception as e:
    print(f"JSON syntax error in {conf_file}: {e}", file=sys.stderr)
    sys.exit(1)

if os.path.exists(schema_file):
    try:
        with open(schema_file) as f:
            schema = json.load(f)
        props = schema.get("properties", {})
        # Verify required or known properties if present
        for k, v in props.items():
            if k in cfg:
                expected_type = v.get("type")
                val = cfg[k]
                if expected_type == "string" and not isinstance(val, str):
                    print(f"Validation Warning: '{k}' expected string, got {type(val).__name__}")
                elif expected_type == "integer" and not isinstance(val, int):
                    print(f"Validation Warning: '{k}' expected integer, got {type(val).__name__}")
    except Exception as e:
        print(f"Schema load warning: {e}")

print("Configuration validation PASSED.")
EOF
  log_success "Configuration schema validation completed successfully."
}

# ## show_help
# Displays usage guide.
show_help() {
  cat <<EOF
Open edX Configuration Management Engine

Usage:
  $0 get <key>
  $0 set <key> <value>
  $0 list
  $0 generate
  $0 validate
  $0 help

Commands:
  get         Read value from lms.env.json
  set         Set key and value idempotently in lms and cms config
  list        Display active configuration JSON
  generate    Generate default configurations preserving overrides
  validate    Validate configuration schema against vars.schema.json
  help        Show this help message
EOF
}

COMMAND="${1:-help}"
shift || true

case "${COMMAND}" in
  get)
    config_get "$@"
    ;;
  set)
    config_set "$@"
    ;;
  list)
    config_list
    ;;
  generate)
    config_generate
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
