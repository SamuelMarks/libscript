#!/bin/sh
# ## Overview
# Scans the host system to discover installed toolchains and runtimes (e.g., Python).
# Checks standard system locations, PATH, and previous libscript installation paths.
#
# ## Usage
#   ./discover_runtimes.sh [--json | --eval]

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
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export DIR="${SCRIPT_DIR}"

# ## discover_python
# Probes for Python in standard PATH, common installation prefixes, and legacy libscript bundles.
discover_python() {
  local py_path=""
  if command -v python3 >/dev/null 2>&1; then
    py_path=$(command -v python3)
  elif command -v python >/dev/null 2>&1; then
    py_path=$(command -v python)
  fi

  if [ -z "$py_path" ]; then
    for p in /usr/bin/python3 /usr/local/bin/python3 /opt/homebrew/bin/python3 /opt/local/bin/python3; do
      if [ -x "$p" ]; then
        py_path="$p"
        break
      fi
    done
  fi

  if [ -z "$py_path" ]; then
    for p in "/opt/libscript/python/bin/python3" "/usr/local/libscript/python/bin/python3"; do
      if [ -x "$p" ]; then
        py_path="$p"
        break
      fi
    done
  fi

  if [ -n "$py_path" ]; then
    printf 'python_path="%s"\n' "$py_path"
    return 0
  fi
  return 1
}

MODE="${1:-}"

if [ "$MODE" = "--json" ]; then
  py_path=$(discover_python | awk -F'="' '{print $2}' | sed 's/"//g')
  printf '{\n'
  printf '  "python": {\n'
  if [ -n "$py_path" ]; then
    printf '    "path": "%s",\n' "$py_path"
    printf '    "found": true\n'
  else
    printf '    "found": false\n'
  fi
  printf '  }\n'
  printf '}\n'
elif [ "$MODE" = "--eval" ]; then
  discover_python || true
else
  printf 'Usage: %s [--json | --eval]\n' "$0" >&2
  exit 1
fi
