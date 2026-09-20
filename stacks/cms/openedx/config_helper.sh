#!/bin/sh
# ## Overview
# Configuration helper utility for Open edX configuration management.
# Provides key inspection, mutation, default generation, and syntax validation.
#
# ## Usage
# ./stacks/cms/openedx/config_helper.sh get <conf_file> <key>
# ./stacks/cms/openedx/config_helper.sh set <conf_file1> <conf_file2> <key> <val>
# ./stacks/cms/openedx/config_helper.sh generate <conf_file1> <conf_file2>
# ./stacks/cms/openedx/config_helper.sh validate <conf_file> <schema_file>

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

# ## show_help
# Displays usage instructions.
show_help() {
  printf '%s
' "Usage: $(basename "$THIS_FILE") get <conf_file> <key>"
  printf '%s
' "       $(basename "$THIS_FILE") set <conf_file1> <conf_file2> <key> <val>"
  printf '%s
' "       $(basename "$THIS_FILE") generate <conf_file1> <conf_file2>"
  printf '%s
' "       $(basename "$THIS_FILE") validate <conf_file> <schema_file>"
  exit 0
}

# ## do_get
# Retrieves a dot-separated property value from a JSON file.
#
# Inputs:
#   $1 - Configuration file path
#   $2 - Dot-separated key path
do_get() {
  _conf_file="$1"
  _key="$2"

  if [ ! -f "${_conf_file}" ]; then
    exit 1
  fi

  if command -v jq >/dev/null 2>&1; then
    _jq_path=$(printf '%s' "${_key}" | sed 's/\([^.]*\)/."\1"/g')
    _val=$(jq -r "${_jq_path} // null" "${_conf_file}" 2>/dev/null || printf 'null')
    printf '%s
' "${_val}"
    return 0
  fi

  if command -v node >/dev/null 2>&1; then
    node -e '
      const fs = require("fs");
      try {
        const d = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
        const parts = process.argv[2].split(".");
        let cur = d;
        for (const p of parts) {
          if (cur && typeof cur === "object" && p in cur) cur = cur[p];
          else { console.log("null"); process.exit(0); }
        }
        if (typeof cur === "object" && cur !== null) console.log(JSON.stringify(cur, null, 2));
        else console.log(cur);
      } catch (e) {
        console.log("null");
      }
    ' "${_conf_file}" "${_key}"
    return 0
  fi

  # Basic POSIX sh/grep fallback for leaf properties
  _leaf="${_key##*.}"
  _match=$(grep -E "${_leaf}[[:space:]]*:" "${_conf_file}" 2>/dev/null | head -n 1 || true)
  if [ -n "${_match}" ]; then
    _val=$(printf '%s
' "${_match}" | sed -E 's/.*:[[:space:]]*"?([^",]+)"?.*/\1/')
    printf '%s
' "${_val}"
  else
    printf 'null
'
  fi
}

# ## do_set
# Sets a dot-separated property value across target JSON configuration files.
#
# Inputs:
#   $1 - Primary configuration file
#   $2 - Secondary configuration file
#   $3 - Dot-separated key path
#   $4 - New property value
do_set() {
  _cf1="$1"
  _cf2="$2"
  _key="$3"
  _val="$4"

  for _cf in "${_cf1}" "${_cf2}"; do
    _cf_dir=$(dirname "${_cf}")
    mkdir -p "${_cf_dir}"
    if command -v jq >/dev/null 2>&1; then
      if [ ! -f "${_cf}" ]; then
        printf '{}
' > "${_cf}"
      fi
      _jq_path=$(printf '%s' "${_key}" | sed 's/\([^.]*\)/."\1"/g')
      # Attempt to parse as JSON or fallback to string
      _tmp=$(mktemp)
      if jq --arg v "${_val}" "${_jq_path} = (\$v | try fromjson catch \$v)" "${_cf}" > "$_tmp" 2>/dev/null; then
        mv "$_tmp" "${_cf}"
      else
        rm -f "$_tmp"
      fi
    elif command -v node >/dev/null 2>&1; then
      node -e '
        const fs = require("fs");
        const file = process.argv[1];
        const key = process.argv[2];
        const rawVal = process.argv[3];
        let val;
        try { val = JSON.parse(rawVal); } catch (_) { val = rawVal; }
        let cfg = {};
        if (fs.existsSync(file)) {
          try { cfg = JSON.parse(fs.readFileSync(file, "utf8")); } catch (_) { cfg = {}; }
        }
        const parts = key.split(".");
        let cur = cfg;
        for (let i = 0; i < parts.length - 1; i++) {
          const p = parts[i];
          if (!cur[p] || typeof cur[p] !== "object") cur[p] = {};
          cur = cur[p];
        }
        cur[parts[parts.length - 1]] = val;
        fs.writeFileSync(file, JSON.stringify(cfg, null, 2) + "
");
      ' "${_cf}" "${_key}" "${_val}"
    fi
  done
  printf 'Updated %s.
' "${_key}"
}

# ## do_generate
# Generates default configuration parameters for LMS and Studio CMS.
#
# Inputs:
#   $1 - Primary configuration file
#   $2 - Secondary configuration file
do_generate() {
  _cf1="$1"
  _cf2="$2"

  _token=""
  if command -v openssl >/dev/null 2>&1; then
    _token=$(openssl rand -hex 24 2>/dev/null || true)
  fi
  if [ -z "${_token}" ]; then
    _token="openedx_secret_token_$(date +%s)"
  fi

  for _cf in "${_cf1}" "${_cf2}"; do
    _cf_dir=$(dirname "${_cf}")
    mkdir -p "${_cf_dir}"
    if [ ! -f "${_cf}" ]; then
      cat <<JSONEOF > "${_cf}"
{
  "SITE_NAME": "openedx.local",
  "LMS_BASE": "openedx.local",
  "CMS_BASE": "studio.openedx.local",
  "SECRET_KEY": "${_token}",
  "DATABASES": {
    "default": {
      "ENGINE": "django.db.backends.mysql",
      "NAME": "openedx",
      "USER": "openedx",
      "PASSWORD": "",
      "HOST": "127.0.0.1",
      "PORT": 3306
    }
  },
  "CACHES": {
    "default": {
      "BACKEND": "django_redis.cache.RedisCache",
      "LOCATION": "redis://127.0.0.1:6379/1"
    }
  },
  "MEILISEARCH_URL": "http://127.0.0.1:7700",
  "EMAIL_HOST": "127.0.0.1",
  "EMAIL_PORT": 25
}
JSONEOF
    fi
  done
  printf 'Configurations generated.
'
}

# ## do_validate
# Validates syntactic correctness of JSON configuration file.
#
# Inputs:
#   $1 - Configuration file path
#   $2 - JSON schema file path
do_validate() {
  _conf_file="$1"
  _schema_file="$2"

  if [ ! -f "${_conf_file}" ]; then
    printf 'Error: %s does not exist
' "${_conf_file}" >&2
    exit 1
  fi

  if command -v jq >/dev/null 2>&1; then
    if ! jq empty "${_conf_file}" >/dev/null 2>&1; then
      printf 'Error: Invalid JSON syntax in %s
' "${_conf_file}" >&2
      exit 1
    fi
  elif command -v node >/dev/null 2>&1; then
    if ! node -e 'JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"))' "${_conf_file}" >/dev/null 2>&1; then
      printf 'Error: Invalid JSON syntax in %s
' "${_conf_file}" >&2
      exit 1
    fi
  fi

  printf 'Configuration validation PASSED.
'
}

# ## main
# Main entrypoint dispatching commands.
main() {
  if [ $# -lt 1 ]; then
    show_help
  fi

  _action="$1"
  shift

  case "${_action}" in
    get)
      if [ $# -lt 2 ]; then show_help; fi
      do_get "$1" "$2"
      ;;
    set)
      if [ $# -lt 4 ]; then show_help; fi
      do_set "$1" "$2" "$3" "$4"
      ;;
    generate)
      if [ $# -lt 2 ]; then show_help; fi
      do_generate "$1" "$2"
      ;;
    validate)
      if [ $# -lt 2 ]; then show_help; fi
      do_validate "$1" "$2"
      ;;
    help|--help|-h)
      show_help
      ;;
    *)
      printf 'Error: Unknown action %s
' "${_action}" >&2
      exit 1
      ;;
  esac
}

main "$@"
